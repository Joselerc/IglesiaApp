/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function mejorada que envía notificaciones push FCM
 * Soporta envío masivo, validación de tokens y manejo de errores
 */
exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    // Configurar CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    // Manejar preflight OPTIONS request
    if (req.method === 'OPTIONS') {
      return res.status(200).end();
    }

    // Verificar método
    if (req.method !== 'POST') {
      return res.status(405).json({ 
        success: false, 
        error: 'Method not allowed. Use POST.' 
      });
    }
    
    // Verificar cuerpo de la solicitud
    const { userIds, tokens, notification, data, topic } = req.body;
    
    if (!notification || !notification.title || !notification.body) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: notification with title and body' 
      });
    }
    
    let tokensToSend = [];
    let sendMethod = 'tokens'; // 'tokens' o 'topic'
    
    // Método 1: Envío por topic (más eficiente para grupos grandes)
    if (topic && typeof topic === 'string') {
      sendMethod = 'topic';
      console.log(`Enviando a topic: ${topic}`);
    }
    // Método 2: Tokens directos
    else if (tokens && Array.isArray(tokens) && tokens.length > 0) {
      tokensToSend = tokens.filter(token => token && typeof token === 'string' && token.length > 0);
    } 
    // Método 3: IDs de usuarios (buscar tokens en Firestore)
    else if (userIds && Array.isArray(userIds) && userIds.length > 0) {
      console.log(`Buscando tokens para ${userIds.length} usuarios`);
      
      // Procesar en lotes de 10 (límite de Firestore 'in' query)
      const batchSize = 10;
      for (let i = 0; i < userIds.length; i += batchSize) {
        const batch = userIds.slice(i, i + batchSize);
        
      const usersSnapshot = await admin.firestore()
        .collection('users')
          .where(admin.firestore.FieldPath.documentId(), 'in', batch)
        .get();
      
      usersSnapshot.docs.forEach(doc => {
        const userData = doc.data();
          if (userData.fcmToken && typeof userData.fcmToken === 'string') {
          tokensToSend.push(userData.fcmToken);
        }
      });
      }
    } else {
      return res.status(400).json({ 
        success: false, 
        error: 'You must provide either userIds, tokens array, or topic' 
      });
    }
    
    // Construir mensaje base
    const messageBase = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        ...data,
        // Añadir timestamp para tracking
        sentAt: new Date().toISOString(),
      },
      // Configuraciones específicas por plataforma
      android: {
        notification: {
          channelId: 'church_app_high_importance',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
      },
      data: data || {},
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body,
            },
            badge: 1,
            sound: 'default',
          },
        },
        headers: {
          'apns-priority': '10',
        },
      },
    };
    
    // Si hay URL de imagen, añadirla
    if (notification.imageUrl) {
      messageBase.notification.imageUrl = notification.imageUrl;
    }
    
    let response;
    
    if (sendMethod === 'topic') {
      // Envío por topic
      const topicMessage = {
        ...messageBase,
        topic: topic,
      };
      
      response = await admin.messaging().send(topicMessage);
      console.log(`Mensaje enviado al topic ${topic}: ${response}`);
      
      return res.json({
        success: true,
        method: 'topic',
        topic: topic,
        messageId: response,
      });
    } else {
      // Envío por tokens
      // Filtrar tokens únicos y válidos
      tokensToSend = [...new Set(tokensToSend.filter(token => 
        token && typeof token === 'string' && token.length > 0
      ))];
      
      if (tokensToSend.length === 0) {
        return res.json({ 
          success: true, 
          message: 'No valid tokens found. No notifications sent.',
          method: 'tokens',
          tokensProcessed: 0,
        });
      }
      
      // Enviar en lotes de 500 (límite de FCM)
      const batchSize = 500;
      let totalSuccessCount = 0;
      let totalFailureCount = 0;
      const allFailedTokens = [];
      const allMessageIds = [];
      
      for (let i = 0; i < tokensToSend.length; i += batchSize) {
        const batchTokens = tokensToSend.slice(i, i + batchSize);
        
        const batchMessage = {
          ...messageBase,
          tokens: batchTokens,
        };
        
        const batchResponse = await admin.messaging().sendMulticast(batchMessage);
        
        totalSuccessCount += batchResponse.successCount;
        totalFailureCount += batchResponse.failureCount;
        
        // Recopilar IDs de mensajes exitosos
        batchResponse.responses.forEach((resp, idx) => {
          if (resp.success) {
            allMessageIds.push(resp.messageId);
          } else {
            allFailedTokens.push({
              token: batchTokens[idx],
              error: resp.error?.message || 'Unknown error',
              errorCode: resp.error?.code || 'unknown',
          });
        }
      });
        
        console.log(`Lote ${Math.floor(i/batchSize) + 1}: ${batchResponse.successCount}/${batchTokens.length} exitosos`);
      }
      
      // Limpiar tokens inválidos de Firestore (opcional, solo en producción)
      if (allFailedTokens.length > 0 && !functions.config().debug?.enabled) {
        await cleanupInvalidTokens(allFailedTokens);
      }
      
      console.log(`Total enviado: ${totalSuccessCount} exitosos, ${totalFailureCount} fallidos de ${tokensToSend.length} tokens`);
    
    return res.json({
      success: true,
        method: 'tokens',
        messageIds: allMessageIds,
        successCount: totalSuccessCount,
        failureCount: totalFailureCount,
        tokensProcessed: tokensToSend.length,
        failedTokens: allFailedTokens.slice(0, 10), // Solo primeros 10 para evitar respuesta muy grande
      });
    }
    
  } catch (error) {
    console.error('Error al enviar notificaciones push:', error);
    return res.status(500).json({ 
      success: false, 
      error: error.message,
      code: error.code || 'unknown',
    });
  }
});

/**
 * Función auxiliar para limpiar tokens inválidos de Firestore
 */
async function cleanupInvalidTokens(failedTokens) {
  try {
    const invalidTokens = failedTokens.filter(failed => 
      failed.errorCode === 'messaging/registration-token-not-registered' ||
      failed.errorCode === 'messaging/invalid-registration-token'
    );
    
    if (invalidTokens.length === 0) return;
    
    console.log(`Limpiando ${invalidTokens.length} tokens inválidos`);
    
    const batch = admin.firestore().batch();
    let batchCount = 0;
    
    for (const invalidToken of invalidTokens) {
      // Buscar usuarios con este token
      const usersWithToken = await admin.firestore()
        .collection('users')
        .where('fcmToken', '==', invalidToken.token)
        .limit(5) // Limitar para evitar operaciones costosas
        .get();
      
      usersWithToken.docs.forEach(doc => {
        batch.update(doc.ref, { 
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenCleanedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batchCount++;
      });
      
      // Ejecutar batch cada 500 operaciones (límite de Firestore)
      if (batchCount >= 500) {
        await batch.commit();
        batchCount = 0;
      }
    }
    
    // Ejecutar batch restante
    if (batchCount > 0) {
      await batch.commit();
    }
    
    console.log(`Tokens inválidos limpiados: ${invalidTokens.length}`);
  } catch (error) {
    console.error('Error limpiando tokens inválidos:', error);
  }
}

/**
 * Cloud Function para suscribir usuarios a topics
 */
exports.subscribeToTopic = functions.https.onRequest(async (req, res) => {
  try {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      return res.status(200).end();
    }

    if (req.method !== 'POST') {
      return res.status(405).json({ success: false, error: 'Method not allowed' });
    }

    const { tokens, topic } = req.body;

    if (!tokens || !Array.isArray(tokens) || !topic) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing tokens array or topic' 
      });
    }

    const response = await admin.messaging().subscribeToTopic(tokens, topic);
    
    return res.json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      errors: response.errors,
    });
  } catch (error) {
    console.error('Error subscribing to topic:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * Cloud Function para desuscribir usuarios de topics
 */
exports.unsubscribeFromTopic = functions.https.onRequest(async (req, res) => {
  try {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      return res.status(200).end();
    }

    if (req.method !== 'POST') {
      return res.status(405).json({ success: false, error: 'Method not allowed' });
    }

    const { tokens, topic } = req.body;

    if (!tokens || !Array.isArray(tokens) || !topic) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing tokens array or topic' 
      });
    }

    const response = await admin.messaging().unsubscribeFromTopic(tokens, topic);
    
    return res.json({
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      errors: response.errors,
    });
  } catch (error) {
    console.error('Error unsubscribing from topic:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});
