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
  return res.status(410).json({
    success: false,
    error: 'Endpoint deprecated. Use authenticated callable sendPushNotifications.',
  });
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
  return res.status(410).json({ success: false, error: 'Endpoint deprecated.' });
});

/**
 * Cloud Function para desuscribir usuarios de topics
 */
exports.unsubscribeFromTopic = functions.https.onRequest(async (req, res) => {
  return res.status(410).json({ success: false, error: 'Endpoint deprecated.' });
});
