import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Inicializar el servicio FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 FCM_SERVICE - Inicializando Firebase Cloud Messaging...');

      // 1. Configurar notificaciones locales (sin solicitar permisos)
      await _setupLocalNotifications();

      // 2. Configurar listeners
      _setupMessageHandlers();

      // 3. Configurar refresh de token
      _setupTokenRefresh();

      _isInitialized = true;
      debugPrint('✅ FCM_SERVICE - Inicialización básica completada');
      
      // Los permisos y token se solicitarán después del login
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error en inicialización: $e');
    }
  }
  
  /// Solicitar permisos y obtener token (llamar después del login)
  Future<void> initializePermissionsAndToken() async {
    try {
      debugPrint('🔔 FCM_SERVICE - Solicitando permisos y token...');
      
      // 1. Solicitar permisos
      await _requestPermissions();
      
      // 2. Obtener token FCM
      await _getAndSaveToken();
      
      debugPrint('✅ FCM_SERVICE - Permisos y token obtenidos');
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error obteniendo permisos/token: $e');
    }
  }

  /// Solicitar permisos de notificación
  Future<void> _requestPermissions() async {
    try {
      // Solicitar permisos de FCM
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 FCM_SERVICE - Permisos FCM: ${settings.authorizationStatus}');

      // Solicitar permisos adicionales en Android
      if (!kIsWeb) {
        final status = await Permission.notification.request();
        debugPrint('🔔 FCM_SERVICE - Permisos Android: $status');
      }
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error solicitando permisos: $e');
    }
  }

  /// Configurar notificaciones locales
  Future<void> _setupLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Crear canal de notificación para Android
      const androidChannel = AndroidNotificationChannel(
        'church_app_high_importance',
        'Notificações da Igreja',
        description: 'Canal para notificações importantes da igreja',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      debugPrint('✅ FCM_SERVICE - Notificaciones locales configuradas');
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error configurando notificaciones locales: $e');
    }
  }

  /// Obtener y guardar token FCM
  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM_SERVICE - Token obtenido: ${_fcmToken?.substring(0, 20)}...');

      if (_fcmToken != null && _auth.currentUser != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error obteniendo token: $e');
    }
  }

  /// Guardar token en Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      });

      debugPrint('✅ FCM_SERVICE - Token guardado en Firestore');
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error guardando token: $e');
    }
  }

  /// Configurar manejadores de mensajes
  void _setupMessageHandlers() {
    // Mensaje recibido cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensaje tocado cuando la app está en background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Verificar si la app fue abierta desde una notificación
    _checkInitialMessage();
  }

  /// Manejar mensaje en primer plano
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 FCM_SERVICE - Mensaje en primer plano: ${message.messageId}');
    debugPrint('🔔 FCM_SERVICE - Título: ${message.notification?.title}');
    debugPrint('🔔 FCM_SERVICE - Cuerpo: ${message.notification?.body}');

    // Mostrar notificación local
    await _showLocalNotification(message);
  }

  /// Manejar tap en notificación desde background
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('🔔 FCM_SERVICE - Notificación tocada desde background: ${message.messageId}');
    _handleNotificationNavigation(message.data);
  }

  /// Verificar mensaje inicial (app abierta desde notificación)
  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 FCM_SERVICE - App abierta desde notificación: ${initialMessage.messageId}');
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error verificando mensaje inicial: $e');
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'church_app_high_importance',
        'Notificações da Igreja',
        channelDescription: 'Canal para notificações importantes da igreja',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Igreja Amor em Movimento',
        message.notification?.body ?? 'Nova notificação',
        notificationDetails,
        payload: message.data['actionRoute'],
      );
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error mostrando notificación local: $e');
    }
  }

  /// Manejar tap en notificación local
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 FCM_SERVICE - Notificación local tocada: ${response.payload}');
    if (response.payload != null) {
      _navigateToRoute(response.payload!);
    }
  }

  /// Manejar navegación desde notificación
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final actionRoute = data['actionRoute'] as String?;
    if (actionRoute != null) {
      _navigateToRoute(actionRoute);
    }
  }

  /// Navegar a ruta específica
  void _navigateToRoute(String route) {
    // TODO: Implementar navegación usando el NavigatorKey global
    debugPrint('🧭 FCM_SERVICE - Navegando a: $route');
    // Navigator.pushNamed(navigatorKey.currentContext!, route);
  }

  /// Configurar refresh de token
  void _setupTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM_SERVICE - Token renovado: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      _saveTokenToFirestore(newToken);
    });
  }

  /// Suscribirse a un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ FCM_SERVICE - Suscrito al topic: $topic');
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error suscribiéndose al topic $topic: $e');
    }
  }

  /// Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ FCM_SERVICE - Desuscrito del topic: $topic');
    } catch (e) {
      debugPrint('❌ FCM_SERVICE - Error desuscribiéndose del topic $topic: $e');
    }
  }

  /// Obtener token actual
  String? get currentToken => _fcmToken;

  /// Verificar si está inicializado
  bool get isInitialized => _isInitialized;
}

/// Manejador de mensajes en background (función top-level requerida)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM_BACKGROUND - Mensaje en background: ${message.messageId}');
  debugPrint('🔔 FCM_BACKGROUND - Título: ${message.notification?.title}');
  debugPrint('🔔 FCM_BACKGROUND - Cuerpo: ${message.notification?.body}');
  
  // Aquí puedes procesar el mensaje en background si es necesario
  // Por ejemplo, actualizar base de datos local, etc.
} 