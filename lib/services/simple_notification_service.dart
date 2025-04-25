import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SimpleNotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool isInitialized = false;

  SimpleNotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Configuración de inicialización para Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración de inicialización para iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      // Inicializar configuración
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Inicializar plugin
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      
      // Solicitar permisos en Android
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
      
      isInitialized = true;
      print('✅ Notificaciones locales inicializadas correctamente');
    } catch (e) {
      print('❌ Error al insicializar notificaciones: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!isInitialized) {
      await _initialize();
    }

    try {
      // Configuración para Android
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'church_app_channel_id',
        'Notificaciones de la Iglesia',
        channelDescription: 'Canal para notificaciones de la aplicación de la iglesia',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      // Configuración para iOS
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Configuración para todas las plataformas
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Mostrar la notificación
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond, // ID único
        title,
        body,
        platformChannelSpecifics,
      );
      
      print('✅ Notificación mostrada: $title | $body');
    } catch (e) {
      print('❌ Error al mostrar notificación: $e');
      rethrow;
    }
  }
} 