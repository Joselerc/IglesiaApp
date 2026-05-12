import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

// Inicializar Firebase Admin
admin.initializeApp();

// Obtener referencias
const db = admin.firestore();
const messaging = admin.messaging();
const secretClient = new SecretManagerServiceClient();

const SECRET_CACHE_TTL_MS = 5 * 60 * 1000;
const secretCache = new Map<string, { value: string; expiresAt: number }>();

interface CreateDonationPaymentRequest {
  amount: number;
  currency: string;
  method: 'pix' | 'card';
  isRecurring: boolean;
  receiverId?: string | null;
  paymentAccountId?: string | null;
  customer: CustomerInput;
}

interface CreateEventPaymentRequest {
  eventId: string;
  ticketId: string;
  amount: number;
  currency: string;
  method: 'pix' | 'card';
  formData: Record<string, unknown>;
  paymentAccountId?: string | null;
  customer: CustomerInput;
}

interface RegisterFreeTicketRequest {
  eventId: string;
  ticketId: string;
  userName: string;
  userEmail: string;
  userPhone: string;
  formData: Record<string, unknown>;
}

interface RespondMembershipInviteRequest {
  requestId: string;
  entityId: string;
  entityType: 'group' | 'ministry';
  accept: boolean;
}

interface CustomerAddressInput {
  zipCode: string;
  street: string;
  number: string;
  district: string;
  cityName: string;
  stateInitials: string;
  countryName: string;
  complement?: string;
}

interface CustomerInput {
  name: string;
  identity: string;
  email?: string;
  phone: string;
  address: CustomerAddressInput;
  cityIbge?: string;
}

const SAFE2PAY_API_BASE = 'https://api.safe2pay.com.br';
const SAFE2PAY_SERVICES_BASE = 'https://services.safe2pay.com.br';
const MAX_PUSH_RECIPIENTS = 500;
const MAX_DONATION_AMOUNT = 100000;
const ALLOWED_CURRENCIES = new Set(['BRL']);
const ALLOWED_PAYMENT_METHODS = new Set(['pix', 'card']);

function normalizeString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeDigits(value: string): string {
  return value.replace(/\D/g, '');
}

function getProjectId(): string | undefined {
  return process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
}

function authUid(request: any): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  }
  const provider = request.auth?.token?.firebase?.sign_in_provider;
  if (provider === 'anonymous') {
    throw new functions.https.HttpsError('permission-denied', 'Usuarios invitados no pueden ejecutar esta operación');
  }
  return uid;
}

function claimHasPermission(request: any, permission: string): boolean {
  const token = request.auth?.token || {};
  if (token.admin === true || token.superUser === true || token.isSuperUser === true) {
    return true;
  }
  const permissions = token.permissions;
  return Array.isArray(permissions) && permissions.includes(permission);
}

async function requirePermission(request: any, permission: string): Promise<string> {
  const uid = authUid(request);
  if (claimHasPermission(request, permission)) {
    return uid;
  }

  const callerDoc = await db.collection('users').doc(uid).get();
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Usuario no encontrado');
  }

  const callerData = callerDoc.data() || {};
  if (callerData.isSuperUser === true) {
    return uid;
  }

  const roleId = normalizeString(callerData.roleId);
  if (!roleId) {
    throw new functions.https.HttpsError('permission-denied', 'No tienes permiso para esta operación');
  }

  const roleDoc = await db.collection('roles').doc(roleId).get();
  const permissions = roleDoc.data()?.permissions || [];
  if (!Array.isArray(permissions) || !permissions.includes(permission)) {
    throw new functions.https.HttpsError('permission-denied', 'No tienes permiso para esta operación');
  }

  return uid;
}

async function enforceRateLimit(uid: string, action: string, maxPerMinute: number): Promise<void> {
  const ref = db.collection('function_rate_limits').doc(`${uid}_${action}`);
  const now = admin.firestore.Timestamp.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() || {};
    const windowStart = data.windowStart as admin.firestore.Timestamp | undefined;
    const sameWindow =
      windowStart != null &&
      now.toMillis() - windowStart.toMillis() < 60 * 1000;
    const count = sameWindow ? Number(data.count || 0) : 0;
    if (count >= maxPerMinute) {
      throw new functions.https.HttpsError('resource-exhausted', 'Demasiadas solicitudes, intenta de nuevo en un minuto');
    }
    tx.set(ref, {
      windowStart: sameWindow ? windowStart : now,
      count: count + 1,
      updatedAt: now,
    }, { merge: true });
  });
}

function assertPaymentBasics(amount: number, currency: string, method: string): void {
  if (!Number.isFinite(amount) || amount <= 0 || amount > MAX_DONATION_AMOUNT) {
    throw new functions.https.HttpsError('invalid-argument', 'amount inválido');
  }
  if (!ALLOWED_CURRENCIES.has(currency)) {
    throw new functions.https.HttpsError('invalid-argument', 'currency inválida');
  }
  if (!ALLOWED_PAYMENT_METHODS.has(method)) {
    throw new functions.https.HttpsError('invalid-argument', 'method inválido');
  }
}

async function assertTicketAccess(uid: string, ticketData: Record<string, any>): Promise<void> {
  const restriction = normalizeString(ticketData.accessRestriction) || 'public';
  if (restriction === 'public') return;

  const userDoc = await db.collection('users').doc(uid).get();
  const userData = userDoc.data() || {};
  if (restriction === 'church' && userData.isChurchMember === true) return;

  if (restriction === 'ministry') {
    const ministries = await db.collection('ministries')
      .where('members', 'array-contains', db.doc(`users/${uid}`))
      .limit(1)
      .get();
    if (!ministries.empty) return;
  }

  if (restriction === 'group') {
    const groups = await db.collection('groups')
      .where('members', 'array-contains', db.doc(`users/${uid}`))
      .limit(1)
      .get();
    if (!groups.empty) return;
  }

  throw new functions.https.HttpsError('permission-denied', 'Usuário sem acesso a este ingresso');
}

function assertTicketDeadline(ticketData: Record<string, any>, eventData: Record<string, any>): void {
  const now = new Date();
  const deadline = ticketData['registrationDeadline'] as admin.firestore.Timestamp | undefined;
  const eventStart = eventData['startDate'] as admin.firestore.Timestamp | undefined;
  if (deadline && now > deadline.toDate()) {
    throw new functions.https.HttpsError('failed-precondition', 'Prazo de inscrição expirado');
  }
  if (ticketData['useEventDateAsDeadline'] !== false && eventStart && now > eventStart.toDate()) {
    throw new functions.https.HttpsError('failed-precondition', 'Evento já iniciado');
  }
}

async function getSafe2PayApiKey(paymentAccountId: string): Promise<string> {
  const secretName = `safe2pay_apiKey_${paymentAccountId}`;
  const cached = secretCache.get(secretName);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.value;
  }

  const projectId = getProjectId();
  if (!projectId) {
    throw new functions.https.HttpsError('failed-precondition', 'Conta de pagamento não configurada');
  }

  try {
    const [version] = await secretClient.accessSecretVersion({
      name: `projects/${projectId}/secrets/${secretName}/versions/latest`,
    });
    const payload = version.payload?.data?.toString().trim();
    if (!payload) {
      console.error('Safe2Pay secret empty', { paymentAccountId, secretName });
      throw new functions.https.HttpsError('failed-precondition', 'Conta de pagamento não configurada');
    }
    secretCache.set(secretName, {
      value: payload,
      expiresAt: Date.now() + SECRET_CACHE_TTL_MS,
    });
    return payload;
  } catch (error) {
    console.error('Safe2Pay secret error', { paymentAccountId, secretName, error });
    throw new functions.https.HttpsError('failed-precondition', 'Conta de pagamento não configurada');
  }
}

function normalizeCustomerInput(input: CustomerInput, requireCityIbge: boolean): CustomerInput {
  const missing: string[] = [];

  const name = normalizeString(input?.name);
  const identityRaw = normalizeString(input?.identity);
  const email = normalizeString(input?.email);
  const phoneRaw = normalizeString(input?.phone);
  const address = input?.address || ({} as CustomerAddressInput);

  const zipCode = normalizeString(address.zipCode);
  const street = normalizeString(address.street);
  const number = normalizeString(address.number);
  const district = normalizeString(address.district);
  const cityName = normalizeString(address.cityName);
  const stateInitials = normalizeString(address.stateInitials).toUpperCase();
  const countryName = normalizeString(address.countryName);
  const complement = normalizeString(address.complement);
  const cityIbge = normalizeString(input?.cityIbge);

  if (!name) missing.push('name');
  if (!identityRaw) missing.push('identity');
  if (!email) missing.push('email');
  if (!phoneRaw) missing.push('phone');
  if (!zipCode) missing.push('zipCode');
  if (!street) missing.push('street');
  if (!number) missing.push('number');
  if (!district) missing.push('district');
  if (!cityName) missing.push('cityName');
  if (!stateInitials) missing.push('stateInitials');
  if (!countryName) missing.push('countryName');
  if (requireCityIbge && !cityIbge) missing.push('cityIbge');

  if (missing.length > 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Dados do pagador incompletos: ${missing.join(', ')}`
    );
  }

  return {
    name,
    identity: normalizeDigits(identityRaw),
    email,
    phone: normalizeDigits(phoneRaw),
    address: {
      zipCode: normalizeDigits(zipCode),
      street,
      number,
      district,
      cityName,
      stateInitials,
      countryName,
      complement: complement || undefined,
    },
    cityIbge: cityIbge || undefined,
  };
}

function buildSingleSaleCustomer(input: CustomerInput) {
  return {
    Name: input.name,
    Identity: input.identity,
    Email: input.email,
    Phone: input.phone,
    Address: {
      ZipCode: input.address.zipCode,
      Street: input.address.street,
      Number: input.address.number,
      Complement: input.address.complement || undefined,
      District: input.address.district,
      CityName: input.address.cityName,
      StateInitials: input.address.stateInitials,
      CountryName: input.address.countryName,
    },
  };
}

function buildRecurrenceCustomer(input: CustomerInput) {
  return {
    Name: input.name,
    Identity: input.identity,
    Phone: input.phone,
    Email: input.email,
    Address: {
      Street: input.address.street,
      Number: input.address.number,
      Complement: input.address.complement || undefined,
      District: input.address.district,
      ZipCode: input.address.zipCode,
      City: {
        CodeIBGE: input.cityIbge,
      },
    },
  };
}

async function safe2payPost(
  url: string,
  apiKey: string,
  payload: unknown
): Promise<any> {
  const response = await (globalThis as any).fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    },
    body: JSON.stringify(payload),
  });

  const text = await response.text();
  let data: any = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch (error) {
      console.error('Safe2Pay invalid JSON response', { url, text });
    }
  }

  if (!response.ok) {
    console.error('Safe2Pay request failed', { url, status: response.status, data });
    throw new functions.https.HttpsError(
      'internal',
      `Safe2Pay request failed (${response.status})`
    );
  }

  if (data?.HasError === true || data?.success === false) {
    console.error('Safe2Pay error response', { url, data });
    throw new functions.https.HttpsError(
      'internal',
      data?.Error || data?.Title || 'Safe2Pay error'
    );
  }

  return data;
}

async function getOrCreateRecurringPlan(params: {
  paymentAccountId: string;
  amount: number;
  apiKey: string;
  webhookUrl?: string;
}): Promise<number> {
  const normalizedAmount = Number(params.amount.toFixed(2));
  const amountKey = normalizedAmount.toFixed(2);
  const accountDocRef = db.collection('recurrence_plan_by_account').doc(params.paymentAccountId);

  const accountDoc = await accountDocRef.get();
  if (accountDoc.exists) {
    const data = accountDoc.data() || {};
    const planMap = data['recurrencePlanIdByAccount'] || {};
    const storedPlanId = Number(planMap[amountKey]);
    if (storedPlanId && !Number.isNaN(storedPlanId)) {
      return storedPlanId;
    }
  }

  const existingPlan = await db
    .collection('recurring_plans')
    .where('paymentAccountId', '==', params.paymentAccountId)
    .where('amount', '==', normalizedAmount)
    .where('frequency', '==', 'monthly')
    .limit(1)
    .get();

  if (!existingPlan.empty) {
    const planData = existingPlan.docs[0].data();
    const existingPlanId = Number(planData['planId']);
    if (!existingPlanId || Number.isNaN(existingPlanId)) {
      throw new functions.https.HttpsError('internal', 'Plano de recorrência inválido');
    }
    await accountDocRef.set(
      {
        recurrencePlanIdByAccount: {
          [amountKey]: existingPlanId,
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    return existingPlanId;
  }

  const today = new Date();
  const planPayload = {
    PlanOption: 1,
    PlanFrequence: 1,
    Name: `Doação Mensal ${normalizedAmount.toFixed(2)}`,
    Amount: normalizedAmount,
    Description: 'Doação recorrente',
    ChargeDay: today.getDate(),
    IsImmediateCharge: true,
    IsProRata: false,
    IsRetryCharge: true,
    CallbackUrl: params.webhookUrl,
  };

  const planResponse = await safe2payPost(
    `${SAFE2PAY_SERVICES_BASE}/recurrence/v1/plans/`,
    params.apiKey,
    planPayload
  );

  const rawPlanId =
    planResponse?.data?.idPlan ||
    planResponse?.data?.IdPlan ||
    planResponse?.data?.planId;
  const planId = Number(rawPlanId);
  if (!planId || Number.isNaN(planId)) {
    console.error('Safe2Pay plan creation missing id', planResponse);
    throw new functions.https.HttpsError('internal', 'Não foi possível criar o plano de recorrência');
  }

  await db.collection('recurring_plans').add({
    paymentAccountId: params.paymentAccountId,
    amount: normalizedAmount,
    frequency: 'monthly',
    planId,
    providerResponse: planResponse,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await accountDocRef.set(
    {
      recurrencePlanIdByAccount: {
        [amountKey]: planId,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return planId;
}

function mapSafe2PayStatus(code?: string | number, name?: string): string {
  const normalized = code != null ? String(code) : '';
  switch (normalized) {
    case '1':
      return 'pending';
    case '2':
      return 'processing';
    case '3':
    case '4':
    case '11':
      return 'authorized';
    case '6':
      return 'refunded';
    case '7':
      return 'canceled';
    case '13':
      return 'chargeback';
    default:
      if (name) {
        const lowered = name.toLowerCase();
        if (lowered.includes('pend')) return 'pending';
        if (lowered.includes('liberado')) return 'authorized';
        if (lowered.includes('autoriz')) return 'authorized';
      }
      return 'unknown';
  }
}

// Interfaz para el request
interface SendPushNotificationRequest {
  userIds: string[];
  notification: {
    title: string;
    body: string;
    imageUrl?: string;
  };
  data?: { [key: string]: string };
}

// Cloud Function para enviar notificaciones push masivas
export const sendPushNotifications = functions.https.onCall(async (request) => {
  const callerUid = await requirePermission(request, 'send_push_notifications');
  await enforceRateLimit(callerUid, 'sendPushNotifications', 5);
  const data = request.data as SendPushNotificationRequest;

  // Validar datos
  if (!data.userIds || !Array.isArray(data.userIds) || data.userIds.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'userIds debe ser un array no vacío');
  }
  const userIds = [...new Set(data.userIds.filter((id) => typeof id === 'string' && id.trim().length > 0))];
  if (userIds.length === 0 || userIds.length > MAX_PUSH_RECIPIENTS) {
    throw new functions.https.HttpsError('invalid-argument', `Máximo ${MAX_PUSH_RECIPIENTS} destinatarios por envío`);
  }

  if (!data.notification || !data.notification.title || !data.notification.body) {
    throw new functions.https.HttpsError('invalid-argument', 'notification.title y notification.body son requeridos');
  }
  if (data.notification.title.length > 120 || data.notification.body.length > 500) {
    throw new functions.https.HttpsError('invalid-argument', 'La notificación es demasiado larga');
  }

  const { notification, data: rawCustomData = {} } = data;
  const customData = Object.fromEntries(
    Object.entries(rawCustomData)
      .filter(([key, value]) => key.length <= 50 && typeof value === 'string' && value.length <= 500)
  );

  console.log(`Enviando notificaciones a ${userIds.length} usuarios`);

  // Obtener tokens FCM de los usuarios
  const tokens: string[] = [];
  const validUserIds: string[] = [];
  
  // Procesar usuarios en lotes para mejorar performance
  const batchSize = 100;
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    const userDocs = await Promise.all(
      batch.map(userId => db.collection('users').doc(userId).get())
    );

    userDocs.forEach((doc, index) => {
      if (doc.exists) {
        const userData = doc.data();
        const fcmToken = userData?.fcmToken;
        
        if (fcmToken && typeof fcmToken === 'string') {
          tokens.push(fcmToken);
          validUserIds.push(batch[index]);
        }
      }
    });
  }

  console.log(`Tokens FCM encontrados: ${tokens.length}`);

  if (tokens.length === 0) {
    return {
      success: true,
      successCount: 0,
      failureCount: userIds.length,
      message: 'No se encontraron tokens FCM válidos'
    };
  }

  // Preparar el mensaje
  const message: admin.messaging.MulticastMessage = {
    tokens,
    notification: {
      title: notification.title,
      body: notification.body,
      ...(notification.imageUrl && { imageUrl: notification.imageUrl })
    },
    data: {
      ...customData,
      type: 'push_notification',
      sentBy: callerUid,
      sentAt: new Date().toISOString()
    },
    android: {
      priority: 'high',
      notification: {
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        sound: 'default',
        channelId: 'church_app_high_importance'
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          contentAvailable: true
        }
      }
    }
  };

  try {
    // Enviar notificaciones en lotes
    const batchResponses = await messaging.sendEachForMulticast(message);
    
    let successCount = 0;
    let failureCount = 0;

    batchResponses.responses.forEach((response, index) => {
      if (response.success) {
        successCount++;
      } else {
        failureCount++;
        console.error(`Error enviando a token ${index}: ${response.error?.message}`);
        
        // Si el token es inválido, eliminarlo
        if (response.error?.code === 'messaging/invalid-registration-token' ||
            response.error?.code === 'messaging/registration-token-not-registered') {
          // Marcar para eliminar token inválido
          const userId = validUserIds[index];
          db.collection('users').doc(userId).update({
            fcmToken: admin.firestore.FieldValue.delete()
          }).catch(err => console.error(`Error eliminando token inválido: ${err}`));
        }
      }
    });

    console.log(`Notificaciones enviadas: ${successCount} exitosas, ${failureCount} fallidas`);

    // Guardar registro de la notificación enviada
    await db.collection('push_notifications_log').add({
      sentBy: callerUid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      title: notification.title,
      body: notification.body,
      totalRecipients: userIds.length,
      successCount,
      failureCount,
      targetUserIds: userIds
    });

    return {
      success: true,
      successCount,
      failureCount,
      totalRecipients: userIds.length,
      message: `Notificaciones enviadas exitosamente`
    };

  } catch (error) {
    console.error('Error enviando notificaciones:', error);
    throw new functions.https.HttpsError('internal', 'Error al enviar notificaciones');
  }
});

export const createDonationPayment = functions.https.onCall(async (request) => {
  const uid = authUid(request);
  await enforceRateLimit(uid, 'createDonationPayment', 10);

  const data = request.data as CreateDonationPaymentRequest;
  assertPaymentBasics(data.amount, data.currency, data.method);
  if (data.isRecurring && data.method !== 'card') {
    throw new functions.https.HttpsError('invalid-argument', 'recorrência apenas com cartão');
  }
  if (!data.receiverId) {
    throw new functions.https.HttpsError('failed-precondition', 'receiverId requerido');
  }

  const receiverDoc = await db.collection('finance_receivers').doc(data.receiverId).get();
  if (!receiverDoc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'receiverId inválido');
  }
  const receiverData = receiverDoc.data() || {};
  if (receiverData['isActive'] === false) {
    throw new functions.https.HttpsError('failed-precondition', 'receiverId inativo');
  }
  const safe2payReceiverId = receiverData['idReceiver'];
  const paymentAccountId = receiverData['paymentAccountId'];
  if (!paymentAccountId) {
    throw new functions.https.HttpsError('failed-precondition', 'Conta de pagamento não configurada');
  }

  const paymentRef = db.collection('payments').doc();
  const normalizedCustomer = normalizeCustomerInput(
    data.customer,
    data.isRecurring
  );

  const paymentDoc = {
    purpose: 'donation',
    amount: data.amount,
    currency: data.currency,
    method: data.method,
    isRecurring: data.isRecurring,
    receiverId: data.receiverId,
    paymentAccountId,
    safe2payReceiverId,
    status: 'pending',
    userId: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    provider: 'safe2pay',
  };

  await paymentRef.set(paymentDoc);

  const safe2payKey = await getSafe2PayApiKey(paymentAccountId);
  const webhookUrl = functions.config().safe2pay?.webhook_url;
  if (!webhookUrl) {
    console.warn('Safe2Pay webhook URL not configured');
  }

  if (data.isRecurring) {
    const customerEmail = normalizedCustomer.email as string;
    const planId = await getOrCreateRecurringPlan({
      paymentAccountId,
      amount: data.amount,
      apiKey: safe2payKey,
      webhookUrl,
    });

    const subscriptionPayload = {
      PaymentMethod: '2',
      Customer: buildRecurrenceCustomer(normalizedCustomer),
      Emails: [customerEmail],
    };

    const subscriptionResponse = await safe2payPost(
      `${SAFE2PAY_SERVICES_BASE}/Recurrence/V1/Plans/${planId}/Subscriptions`,
      safe2payKey,
      subscriptionPayload
    );

    const subscriptionData = subscriptionResponse?.data || {};
    const checkoutUrl = subscriptionData.chargeUrl || null;

    await paymentRef.update({
      checkoutUrl,
      safe2paySubscriptionId: subscriptionData.idSubscription || null,
      safe2payPlanId: planId,
      providerResponse: subscriptionResponse,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      paymentId: paymentRef.id,
      status: 'pending',
      checkoutUrl,
    };
  }

  const singleSalePayload = {
    Customer: buildSingleSaleCustomer(normalizedCustomer),
    Products: [
      {
        Description: 'Doação',
        Quantity: 1,
        UnitPrice: Number(data.amount.toFixed(2)),
      },
    ],
    PaymentMethods: [
      {
        CodePaymentMethod: data.method === 'pix' ? '6' : '2',
      },
    ],
    Reference: paymentRef.id,
    Emails: [normalizedCustomer.email as string],
    CallbackUrl: webhookUrl,
  };

  const singleSaleResponse = await safe2payPost(
    `${SAFE2PAY_API_BASE}/v2/singleSale/add`,
    safe2payKey,
    singleSalePayload
  );

  const responseDetail = singleSaleResponse?.ResponseDetail || {};
  const checkoutUrl = responseDetail.SingleSaleUrl || null;

  await paymentRef.update({
    checkoutUrl,
    safe2paySingleSaleHash: responseDetail.SingleSaleHash || null,
    providerResponse: singleSaleResponse,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    paymentId: paymentRef.id,
    status: 'pending',
    checkoutUrl,
  };
});

export const createEventPayment = functions.https.onCall(async (request) => {
  const uid = authUid(request);
  await enforceRateLimit(uid, 'createEventPayment', 10);

  const data = request.data as CreateEventPaymentRequest;
  if (!data.eventId || !data.ticketId) {
    throw new functions.https.HttpsError('invalid-argument', 'eventId/ticketId inválidos');
  }
  if (!ALLOWED_PAYMENT_METHODS.has(data.method)) {
    throw new functions.https.HttpsError('invalid-argument', 'method inválido');
  }

  const ticketDoc = await db
    .collection('events')
    .doc(data.eventId)
    .collection('tickets')
    .doc(data.ticketId)
    .get();

  if (!ticketDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Ticket no encontrado');
  }

  const ticketData = ticketDoc.data() || {};
  if (ticketData['isPaid'] !== true) {
    throw new functions.https.HttpsError('failed-precondition', 'Este ticket no requiere pago');
  }
  const serverAmount = Number(ticketData['price']);
  const serverCurrency = normalizeString(ticketData['currency']) || 'BRL';
  assertPaymentBasics(serverAmount, serverCurrency, data.method);

  const receiverId = ticketData['receiverId'];
  if (!receiverId) {
    throw new functions.https.HttpsError('failed-precondition', 'receiverId requerido en ticket');
  }
  const receiverDoc = await db.collection('finance_receivers').doc(receiverId).get();
  if (!receiverDoc.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'receiverId inválido');
  }
  const receiverData = receiverDoc.data() || {};
  if (receiverData['isActive'] === false) {
    throw new functions.https.HttpsError('failed-precondition', 'receiverId inativo');
  }
  const safe2payReceiverId = receiverData['idReceiver'];
  const paymentAccountId = ticketData['paymentAccountId'] || receiverData['paymentAccountId'];
  if (!paymentAccountId) {
    throw new functions.https.HttpsError('failed-precondition', 'Conta de pagamento não configurada');
  }

  const eventDoc = await db.collection('events').doc(data.eventId).get();
  if (!eventDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Evento no encontrado');
  }
  const eventData = eventDoc.data() || {};
  const now = new Date();
  const deadline = ticketData['registrationDeadline'] as admin.firestore.Timestamp | undefined;
  const eventStart = eventData['startDate'] as admin.firestore.Timestamp | undefined;
  if (deadline && now > deadline.toDate()) {
    throw new functions.https.HttpsError('failed-precondition', 'Prazo de inscrição expirado');
  }
  if (ticketData['useEventDateAsDeadline'] !== false && eventStart && now > eventStart.toDate()) {
    throw new functions.https.HttpsError('failed-precondition', 'Evento já iniciado');
  }

  const existingRegistration = await db
    .collection('events')
    .doc(data.eventId)
    .collection('registrations')
    .where('userId', '==', uid)
    .where('ticketId', '==', data.ticketId)
    .limit(1)
    .get();
  if (!existingRegistration.empty) {
    throw new functions.https.HttpsError('already-exists', 'Usuário já registrado neste ticket');
  }

  const existingPayment = await db
    .collection('payments')
    .where('userId', '==', uid)
    .where('eventId', '==', data.eventId)
    .where('ticketId', '==', data.ticketId)
    .where('status', 'in', ['pending', 'processing', 'authorized'])
    .limit(1)
    .get();
  if (!existingPayment.empty) {
    throw new functions.https.HttpsError('already-exists', 'Já existe um pagamento em andamento para este ticket');
  }

  const paymentRef = db.collection('payments').doc();
  const normalizedCustomer = normalizeCustomerInput(data.customer, false);
  const paymentDoc = {
    purpose: 'event_ticket',
    amount: serverAmount,
    currency: serverCurrency,
    method: data.method,
    receiverId,
    safe2payReceiverId,
    paymentAccountId,
    status: 'pending',
    userId: uid,
    eventId: data.eventId,
    ticketId: data.ticketId,
    formData: data.formData || {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    provider: 'safe2pay',
  };

  await paymentRef.set(paymentDoc);

  const safe2payKey = await getSafe2PayApiKey(paymentAccountId);
  const webhookUrl = functions.config().safe2pay?.webhook_url;
  if (!webhookUrl) {
    console.warn('Safe2Pay webhook URL not configured');
  }

  const eventTitle = eventData['title'] || 'Evento';
  const ticketType = ticketData['type'] || 'Ingresso';

  const singleSalePayload = {
    Customer: buildSingleSaleCustomer(normalizedCustomer),
    Products: [
      {
        Description: `${eventTitle} - ${ticketType}`,
        Quantity: 1,
        UnitPrice: Number(serverAmount.toFixed(2)),
      },
    ],
    PaymentMethods: [
      {
        CodePaymentMethod: data.method === 'pix' ? '6' : '2',
      },
    ],
    Reference: paymentRef.id,
    Emails: [normalizedCustomer.email as string],
    CallbackUrl: webhookUrl,
  };

  const singleSaleResponse = await safe2payPost(
    `${SAFE2PAY_API_BASE}/v2/singleSale/add`,
    safe2payKey,
    singleSalePayload
  );

  const responseDetail = singleSaleResponse?.ResponseDetail || {};
  const checkoutUrl = responseDetail.SingleSaleUrl || null;

  await paymentRef.update({
    checkoutUrl,
    safe2paySingleSaleHash: responseDetail.SingleSaleHash || null,
    providerResponse: singleSaleResponse,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    paymentId: paymentRef.id,
    status: 'pending',
    checkoutUrl,
  };
});

export const registerFreeEventTicket = functions.https.onCall(async (request) => {
  const uid = authUid(request);
  await enforceRateLimit(uid, 'registerFreeEventTicket', 20);

  const data = request.data as RegisterFreeTicketRequest;
  if (!data.eventId || !data.ticketId) {
    throw new functions.https.HttpsError('invalid-argument', 'eventId/ticketId inválidos');
  }

  const eventRef = db.collection('events').doc(data.eventId);
  const ticketRef = eventRef.collection('tickets').doc(data.ticketId);
  const [eventSnap, ticketSnap] = await Promise.all([eventRef.get(), ticketRef.get()]);
  if (!eventSnap.exists || !ticketSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Evento o ticket no encontrado');
  }

  const eventData = eventSnap.data() || {};
  const ticketData = ticketSnap.data() || {};
  if (ticketData.isPaid === true) {
    throw new functions.https.HttpsError('failed-precondition', 'Este ticket requiere pago');
  }
  assertTicketDeadline(ticketData, eventData);
  await assertTicketAccess(uid, ticketData);

  const registrationRef = eventRef.collection('registrations').doc(`${data.ticketId}_${uid}`);
  await db.runTransaction(async (tx) => {
    const [freshTicketSnap, registrationSnap] = await Promise.all([
      tx.get(ticketRef),
      tx.get(registrationRef),
    ]);
    if (!freshTicketSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Ticket no encontrado');
    }
    if (registrationSnap.exists) {
      throw new functions.https.HttpsError('already-exists', 'Você já está registrado para este ticket');
    }

    const freshTicket = freshTicketSnap.data() || {};
    const quantity = freshTicket.quantity as number | undefined;
    const soldCount = Number(freshTicket.soldCount || 0);
    if (quantity && soldCount >= quantity) {
      throw new functions.https.HttpsError('resource-exhausted', 'Não há mais ingressos disponíveis');
    }

    tx.set(registrationRef, {
      eventId: data.eventId,
      ticketId: data.ticketId,
      userId: uid,
      userName: normalizeString(data.userName),
      userEmail: normalizeString(data.userEmail),
      userPhone: normalizeString(data.userPhone),
      formData: data.formData || {},
      qrCode: `${data.eventId}-${data.ticketId}-${uid}-${crypto.randomUUID()}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isUsed: false,
    });
    tx.update(ticketRef, {
      soldCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { registrationId: registrationRef.id };
});

export const respondToMembershipInvite = functions.https.onCall(async (request) => {
  const uid = authUid(request);
  await enforceRateLimit(uid, 'respondToMembershipInvite', 20);
  const data = request.data as RespondMembershipInviteRequest;

  if (!data?.requestId || !data.entityId || !['group', 'ministry'].includes(data.entityType)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invitación inválida');
  }

  const collection = data.entityType === 'group' ? 'groups' : 'ministries';
  const requestRef = db.collection('membership_requests').doc(data.requestId);
  const entityRef = db.collection(collection).doc(data.entityId);
  const userRef = db.collection('users').doc(uid);

  await db.runTransaction(async (tx) => {
    const [requestSnap, entitySnap] = await Promise.all([
      tx.get(requestRef),
      tx.get(entityRef),
    ]);

    if (!requestSnap.exists || !entitySnap.exists) {
      throw new functions.https.HttpsError('not-found', 'Invitación no encontrada');
    }

    const requestData = requestSnap.data() || {};
    if (
      requestData.userId !== uid ||
      requestData.entityId !== data.entityId ||
      requestData.entityType !== data.entityType ||
      requestData.requestType !== 'invite' ||
      requestData.status !== 'pending'
    ) {
      throw new functions.https.HttpsError('permission-denied', 'No puedes responder esta invitación');
    }

    const entityData = entitySnap.data() || {};
    const memberIds = extractUserIds(entityData.members);
    const status = data.accept ? 'accepted' : 'rejected';

    if (data.accept && !memberIds.includes(uid)) {
      tx.update(entityRef, {
        members: admin.firestore.FieldValue.arrayUnion(userRef),
        [`pendingRequests.${uid}`]: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.set(db.collection('membership_logs').doc(), {
        userId: uid,
        entityId: data.entityId,
        entityType: data.entityType,
        entityName: requestData.entityName || entityData.name || '',
        actionType: 'join',
        initiatedBy: 'user',
        actorId: uid,
        reason: null,
        roleInEntity: 'member',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        additionalData: { requestType: 'invite' },
      });
    } else {
      const updateData: admin.firestore.UpdateData<admin.firestore.DocumentData> = {
        [`pendingRequests.${uid}`]: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (!data.accept) {
        updateData[`rejectedRequests.${uid}`] = {
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          rejectedBy: uid,
          originalRequest: requestData.requestTimestamp || null,
          reason: null,
        };
      }
      tx.update(entityRef, updateData);
    }

    tx.update(requestRef, {
      status,
      responseTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      respondedBy: uid,
    });
  });

  return { success: true };
});

export const safe2payWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const body = req.body || {};
    const payload = body.NotificationWrapper?.NotificationPayload || body;
    const webhookApiKey = normalizeString(req.get('X-API-KEY'));
    if (!webhookApiKey) {
      console.warn('Webhook missing X-API-KEY header');
      res.status(401).send({ ok: false });
      return;
    }
    const reference =
      payload.Reference ||
      payload.reference ||
      payload.PaymentReference ||
      payload.paymentReference;

    const transactionStatus = payload.TransactionStatus || payload.transactionStatus || {};
    const statusCode = transactionStatus.Code || transactionStatus.code || payload.Status || payload.status;
    const statusName = transactionStatus.Name || transactionStatus.name;
    const mappedStatus = mapSafe2PayStatus(statusCode, statusName);

    const subscriptionId =
      payload?.Origin?.Plan?.Subscription?.IdSubscription ||
      payload?.origin?.plan?.subscription?.idSubscription;

    const validateWebhookApiKey = async (
      paymentAccountId: string | null | undefined,
      context: Record<string, unknown>
    ): Promise<{ ok: boolean; status: number }> => {
      if (!paymentAccountId) {
        console.warn('Webhook missing paymentAccountId', context);
        return { ok: false, status: 403 };
      }

      try {
        const expectedApiKey = await getSafe2PayApiKey(paymentAccountId);
        if (webhookApiKey !== expectedApiKey) {
          console.warn('Webhook X-API-KEY mismatch', { ...context, paymentAccountId });
          return { ok: false, status: 403 };
        }
        return { ok: true, status: 200 };
      } catch (error) {
        console.warn('Webhook API key lookup failed', { ...context, paymentAccountId, error });
        return { ok: false, status: 403 };
      }
    };

    if (reference) {
      const paymentRef = db.collection('payments').doc(String(reference));
      const paymentSnap = await paymentRef.get();
      if (!paymentSnap.exists) {
        console.warn('Webhook reference not found', { reference });
        res.status(404).send({ ok: false });
        return;
      } else {
        const currentData = paymentSnap.data() || {};
        const paymentAccountId = currentData['paymentAccountId'];
        const validation = await validateWebhookApiKey(paymentAccountId, { reference });
        if (!validation.ok) {
          res.status(validation.status).send({ ok: false });
          return;
        }

        if (
          currentData['status'] === mappedStatus &&
          String(currentData['providerStatusCode'] ?? '') === String(statusCode ?? '')
        ) {
          res.status(200).send({ ok: true });
          return;
        }

        await paymentRef.set(
          {
            status: mappedStatus,
            providerStatusCode: statusCode ?? null,
            providerStatusName: statusName ?? null,
            providerPayload: payload,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    } else if (subscriptionId) {
      const paymentsSnap = await db
        .collection('payments')
        .where('safe2paySubscriptionId', '==', subscriptionId)
        .limit(1)
        .get();

      if (!paymentsSnap.empty) {
        const paymentDoc = paymentsSnap.docs[0];
        const currentData = paymentDoc.data() || {};
        const paymentAccountId = currentData['paymentAccountId'];
        const validation = await validateWebhookApiKey(paymentAccountId, { subscriptionId });
        if (!validation.ok) {
          res.status(validation.status).send({ ok: false });
          return;
        }

        if (
          currentData['status'] === mappedStatus &&
          String(currentData['providerStatusCode'] ?? '') === String(statusCode ?? '')
        ) {
          res.status(200).send({ ok: true });
          return;
        }

        await paymentDoc.ref.set(
          {
            status: mappedStatus,
            providerStatusCode: statusCode ?? null,
            providerStatusName: statusName ?? null,
            providerPayload: payload,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      } else {
        console.warn('Webhook subscription not found', { subscriptionId });
        res.status(404).send({ ok: false });
        return;
      }
    } else {
      console.warn('Safe2Pay webhook without reference', body);
      res.status(400).send({ ok: false });
      return;
    }

    res.status(200).send({ ok: true });
  } catch (e) {
    console.error('safe2payWebhook error', e);
    res.status(500).send({ ok: false });
  }
});

export const onPaymentAuthorized = functions.firestore
  .document('payments/{paymentId}')
  .onUpdate(async (change: functions.Change<admin.firestore.DocumentSnapshot>) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    if (before.status === after.status) return;
    if (after.status !== 'authorized') return;
    if (after.purpose !== 'event_ticket') return;

    const eventId = after.eventId;
    const ticketId = after.ticketId;
    const userId = after.userId;
    const formData = after.formData || {};

    if (!eventId || !ticketId || !userId) return;

    const ticketRef = db.collection('events').doc(eventId).collection('tickets').doc(ticketId);
    const ticketSnap = await ticketRef.get();
    if (!ticketSnap.exists) return;

    const registrationRef = db
      .collection('events')
      .doc(eventId)
      .collection('registrations')
      .doc(`${ticketId}_${userId}`);

    await db.runTransaction(async (tx) => {
      const [freshTicketSnap, registrationSnap] = await Promise.all([
        tx.get(ticketRef),
        tx.get(registrationRef),
      ]);
      if (!freshTicketSnap.exists || registrationSnap.exists) return;

      const ticketData = freshTicketSnap.data() || {};
      const quantity = ticketData.quantity as number | undefined;
      const soldCount = Number(ticketData.soldCount || 0);
      if (quantity && soldCount >= quantity) return;

      const qrCode = `${eventId}-${ticketId}-${userId}-${crypto.randomUUID()}`;
      tx.set(registrationRef, {
        eventId,
        ticketId,
        userId,
        userName: formData.userName || '',
        userEmail: formData.userEmail || '',
        userPhone: formData.userPhone || '',
        formData,
        qrCode,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isUsed: false,
      });
      tx.update(ticketRef, {
        soldCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  });

export const mirrorGroupMemberships = functions.firestore
  .document('groups/{groupId}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() || {} : null;
    const before = change.before.exists ? change.before.data() || {} : null;
    const groupId = context.params.groupId;
    const membersRef = db.collection('groups').doc(groupId).collection('members');

    if (!after) {
      const existing = await membersRef.limit(500).get();
      const batch = db.batch();
      existing.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      return;
    }

    const memberIds = extractUserIds(after.members);
    const adminIds = new Set(extractUserIds(after.groupAdmin));
    await mirrorMembershipDocs(membersRef, memberIds, adminIds);

    if (!before) return;
    const previousIds = new Set(extractUserIds(before.members));
    const currentIds = new Set(memberIds);
    await deleteRemovedMembershipDocs(membersRef, previousIds, currentIds);
  });

export const mirrorMinistryMemberships = functions.firestore
  .document('ministries/{ministryId}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() || {} : null;
    const before = change.before.exists ? change.before.data() || {} : null;
    const ministryId = context.params.ministryId;
    const membersRef = db.collection('ministries').doc(ministryId).collection('members');

    if (!after) {
      const existing = await membersRef.limit(500).get();
      const batch = db.batch();
      existing.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      return;
    }

    const memberIds = extractUserIds(after.members);
    const adminIds = new Set(extractUserIds(after.ministrieAdmin));
    await mirrorMembershipDocs(membersRef, memberIds, adminIds);

    if (!before) return;
    const previousIds = new Set(extractUserIds(before.members));
    const currentIds = new Set(memberIds);
    await deleteRemovedMembershipDocs(membersRef, previousIds, currentIds);
  });

function extractUserIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((item) => {
    if (typeof item === 'string') {
      return item.split('/').filter(Boolean).pop() || '';
    }
    if (item instanceof admin.firestore.DocumentReference) {
      return item.id;
    }
    const path = (item as { path?: string })?.path;
    return typeof path === 'string' ? path.split('/').pop() || '' : '';
  }).filter(Boolean))];
}

async function mirrorMembershipDocs(
  membersRef: admin.firestore.CollectionReference,
  memberIds: string[],
  adminIds: Set<string>
): Promise<void> {
  for (let i = 0; i < memberIds.length; i += 450) {
    const batch = db.batch();
    memberIds.slice(i, i + 450).forEach((userId) => {
      batch.set(membersRef.doc(userId), {
        userId,
        userRef: db.collection('users').doc(userId),
        role: adminIds.has(userId) ? 'admin' : 'member',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    await batch.commit();
  }
}

async function deleteRemovedMembershipDocs(
  membersRef: admin.firestore.CollectionReference,
  previousIds: Set<string>,
  currentIds: Set<string>
): Promise<void> {
  const removed = [...previousIds].filter((userId) => !currentIds.has(userId));
  for (let i = 0; i < removed.length; i += 450) {
    const batch = db.batch();
    removed.slice(i, i + 450).forEach((userId) => {
      batch.delete(membersRef.doc(userId));
    });
    await batch.commit();
  }
}
