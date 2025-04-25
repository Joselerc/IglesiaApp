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
admin.initializeApp();

/**
 * Cloud Function que envía notificaciones push a varios dispositivos
 * Acepta userIds o tokens FCM directamente
 */
exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    // Verificar método
    if (req.method !== 'POST') {
      return res.status(405).json({ success: false, error: 'Method not allowed. Use POST.' });
    }
    
    // Verificar cuerpo de la solicitud
    const { userIds, tokens, notification, data } = req.body;
    
    if (!notification || !notification.title || !notification.body) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields: notification with title and body' 
      });
    }
    
    let tokensToSend = [];
    
    // Si se proporcionan tokens directamente, usarlos
    if (tokens && Array.isArray(tokens) && tokens.length > 0) {
      tokensToSend = tokens;
    } 
    // Si se proporcionan IDs de usuarios, buscar sus tokens
    else if (userIds && Array.isArray(userIds) && userIds.length > 0) {
      // Obtener documentos de usuarios
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', userIds)
        .get();
      
      // Extraer tokens FCM
      usersSnapshot.docs.forEach(doc => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokensToSend.push(userData.fcmToken);
        }
      });
    } else {
      return res.status(400).json({ 
        success: false, 
        error: 'You must provide either userIds or tokens array' 
      });
    }
    
    // Filtrar tokens vacíos o duplicados
    tokensToSend = [...new Set(tokensToSend.filter(token => token && token.length > 0))];
    
    if (tokensToSend.length === 0) {
      return res.json({ 
        success: true, 
        message: 'No valid tokens found. No notifications sent.' 
      });
    }
    
    // Construir mensaje
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data || {},
      tokens: tokensToSend,
    };
    
    // Si hay URL de imagen, añadirla
    if (notification.imageUrl) {
      message.notification.imageUrl = notification.imageUrl;
    }
    
    // Enviar notificación en lotes
    const response = await admin.messaging().sendMulticast(message);
    
    console.log(`Enviadas ${response.successCount} notificaciones de ${tokensToSend.length}`);
    
    // Registrar los resultados detallados
    const failedTokens = [];
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push({
            token: tokensToSend[idx],
            error: resp.error.message
          });
        }
      });
    }
    
    return res.json({
      success: true,
      messageIds: response.responses.filter(r => r.success).map(r => r.messageId),
      successCount: response.successCount,
      failureCount: response.failureCount,
      failedTokens: failedTokens
    });
    
  } catch (error) {
    console.error('Error al enviar notificaciones push:', error);
    return res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});
