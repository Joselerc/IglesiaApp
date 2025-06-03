import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionsService {
  static final CloudFunctionsService _instance = CloudFunctionsService._internal();
  factory CloudFunctionsService() => _instance;
  CloudFunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Configurar para usar el emulador en desarrollo
  void configureEmulator({String host = 'localhost', int port = 5001}) {
    if (kDebugMode) {
      _functions.useFunctionsEmulator(host, port);
      debugPrint('🔧 Cloud Functions configurado para usar emulador en $host:$port');
    }
  }

  /// Enviar notificaciones push masivas usando Cloud Function
  Future<Map<String, dynamic>> sendPushNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? customData,
  }) async {
    try {
      debugPrint('📤 Llamando a Cloud Function sendPushNotifications...');
      debugPrint('📋 Destinatarios: ${userIds.length}');
      
      // Llamar a la Cloud Function
      final callable = _functions.httpsCallable('sendPushNotifications');
      
      final result = await callable.call<Map<String, dynamic>>({
        'userIds': userIds,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
        'data': customData ?? {},
      });

      final data = result.data;
      
      debugPrint('✅ Cloud Function respondió:');
      debugPrint('   - Exitosas: ${data['successCount']}');
      debugPrint('   - Fallidas: ${data['failureCount']}');
      debugPrint('   - Total: ${data['totalRecipients']}');
      
      return data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Error en Cloud Function: ${e.code} - ${e.message}');
      debugPrint('   Detalles: ${e.details}');
      
      // Re-lanzar con un mensaje más amigable
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('Debes iniciar sesión para enviar notificaciones');
        case 'permission-denied':
          throw Exception('No tienes permiso para enviar notificaciones push');
        case 'invalid-argument':
          throw Exception(e.message ?? 'Datos inválidos');
        default:
          throw Exception('Error al enviar notificaciones: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error inesperado: $e');
      throw Exception('Error inesperado al enviar notificaciones');
    }
  }
} 