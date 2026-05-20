import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

// Inicializar Firebase Admin
admin.initializeApp();

// Obtener referencias
const db = admin.firestore();
const messaging = admin.messaging();

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

interface RegisterFreeTicketRequest {
  eventId: string;
  ticketId: string;
  userName: string;
  userEmail: string;
  userPhone: string;
  formData: Record<string, unknown>;
}

function requireCallableUid(request: any): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  }
  return uid;
}

function normalizeString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

// Cloud Function para enviar notificaciones push masivas
export const sendPushNotifications = functions.https.onCall(async (request) => {
  // Verificar autenticación
  if (!request.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  }

  const data = request.data as SendPushNotificationRequest;

  // Verificar permisos (solo usuarios con permiso send_push_notifications)
  const callerDoc = await db.collection('users').doc(request.auth.uid).get();
  
  if (!callerDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Usuario no encontrado');
  }

  const callerData = callerDoc.data();
  const isSuperUser = callerData?.isSuperUser === true;
  const roleId = callerData?.roleId;

  // Verificar si es superusuario
  if (!isSuperUser) {
    // Si no es superusuario, verificar rol y permisos
    let hasPermission = false;
    
    if (roleId) {
      const roleDoc = await db.collection('roles').doc(roleId).get();
      if (roleDoc.exists) {
        const roleData = roleDoc.data();
        const permissions = roleData?.permissions || [];
        hasPermission = permissions.includes('send_push_notifications');
      }
    }

    if (!hasPermission) {
      throw new functions.https.HttpsError('permission-denied', 'No tienes permiso para enviar notificaciones push');
    }
  }

  // Validar datos
  if (!data.userIds || !Array.isArray(data.userIds) || data.userIds.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'userIds debe ser un array no vacío');
  }

  if (!data.notification || !data.notification.title || !data.notification.body) {
    throw new functions.https.HttpsError('invalid-argument', 'notification.title y notification.body son requeridos');
  }

  const { userIds, notification, data: customData = {} } = data;

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
      sentBy: request.auth.uid,
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
      sentBy: request.auth.uid,
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

export const registerFreeEventTicket = functions.https.onCall(async (request) => {
  const uid = requireCallableUid(request);
  const payload = request.data as RegisterFreeTicketRequest;
  if (!payload.eventId || !payload.ticketId) {
    throw new functions.https.HttpsError('invalid-argument', 'eventId/ticketId inválidos');
  }

  const eventRef = db.collection('events').doc(payload.eventId);
  const ticketRef = eventRef.collection('tickets').doc(payload.ticketId);
  const [eventSnap, ticketSnap] = await Promise.all([eventRef.get(), ticketRef.get()]);
  if (!eventSnap.exists || !ticketSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Evento o ticket no encontrado');
  }

  const eventData = eventSnap.data() || {};
  const ticketData = ticketSnap.data() || {};
  if (ticketData.isPaid === true) {
    throw new functions.https.HttpsError('failed-precondition', 'Este ticket requiere pago');
  }

  const now = new Date();
  const deadline = ticketData.registrationDeadline as admin.firestore.Timestamp | undefined;
  const eventStart = eventData.startDate as admin.firestore.Timestamp | undefined;
  if (deadline && now > deadline.toDate()) {
    throw new functions.https.HttpsError('failed-precondition', 'Prazo de inscrição expirado');
  }
  if (ticketData.useEventDateAsDeadline !== false && eventStart && now > eventStart.toDate()) {
    throw new functions.https.HttpsError('failed-precondition', 'Evento já iniciado');
  }

  const restriction = normalizeString(ticketData.accessRestriction) || 'public';
  if (restriction === 'church') {
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.data()?.isChurchMember !== true) {
      throw new functions.https.HttpsError('permission-denied', 'Este ingresso é exclusivo para membros da igreja');
    }
  }

  const registrationRef = eventRef.collection('registrations').doc(`${payload.ticketId}_${uid}`);
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
      eventId: payload.eventId,
      ticketId: payload.ticketId,
      userId: uid,
      userName: normalizeString(payload.userName),
      userEmail: normalizeString(payload.userEmail),
      userPhone: normalizeString(payload.userPhone),
      formData: payload.formData || {},
      qrCode: `${payload.eventId}-${payload.ticketId}-${uid}-${crypto.randomUUID()}`,
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