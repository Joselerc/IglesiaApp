import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';
import 'package:intl/intl.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Plugin de notificaciones locales
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  // Constructor
  NotificationService() {
    _initNotifications();
  }
  
  // Inicializar notificaciones locales
  Future<void> _initNotifications() async {
    if (_isInitialized) return;
    
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        // Manejar cuando el usuario toca la notificación
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
          print('Notificación tocada: ${notificationResponse.payload}');
        },
      );
      
      // Solicitar permisos de notificación en iOS
      final platform = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (platform != null) {
        await platform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      
      // Solicitar permisos en Android 13 y superior
      final androidImplementation = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
      
      _isInitialized = true;
      print('✅ Notificaciones locales inicializadas correctamente');
    } catch (e) {
      print('❌ Error al inicializar notificaciones locales: $e');
    }
  }
  
  // Mostrar notificación local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Asegurarse de que las notificaciones estén inicializadas
      if (!_isInitialized) {
        await _initNotifications();
      }
      
      const androidDetails = AndroidNotificationDetails(
        'church_app_channel_id',
        'Notificaciones de la Iglesia',
        channelDescription: 'Canal para las notificaciones de la aplicación de la iglesia',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
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
      
      final id = DateTime.now().millisecond + DateTime.now().second * 1000;
      
      await _flutterLocalNotificationsPlugin.show(
        id, // ID único
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      print('✅ Notificación local mostrada: $title - $body');
    } catch (e) {
      print('❌ Error al mostrar notificación local: $e');
    }
  }
  
  // Referencia a la colección de notificaciones
  CollectionReference get _notificationsRef => _firestore.collection('notifications');
  
  // Obtener las notificaciones del usuario actual
  Stream<List<AppNotification>> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }
  
  // Obtener las notificaciones no leídas del usuario actual
  Stream<List<AppNotification>> getUnreadNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }
  
  // Obtener el número de notificaciones no leídas
  Stream<int> getUnreadNotificationsCount() {
    return getUnreadNotifications()
        .map((notifications) => notifications.length);
  }
  
  // Crear una nueva notificación
  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    required String userId,
    String senderId = '',
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionRoute,
    String? entityId,
    String? entityType,
  }) async {
    try {
      final notification = AppNotification(
        id: '',
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
        userId: userId,
        senderId: senderId,
        isRead: false,
        data: data,
        imageUrl: imageUrl,
        actionRoute: actionRoute,
        entityId: entityId,
        entityType: entityType,
      );
      
      // Guardar en Firestore
      await _notificationsRef.add(notification.toFirestore());
      
      // Si el destinatario es el usuario actual, mostrar notificación en primer plano
      final currentUserId = _auth.currentUser?.uid;
      if (userId == currentUserId) {
        print('📱 Mostrando notificación local para el usuario actual');
        await _showLocalNotification(
          title: title,
          body: message,
          payload: actionRoute,
        );
      }
    } catch (e) {
      print('Error al crear notificación: $e');
      rethrow;
    }
  }
  
  // Marcar una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      rethrow;
    }
  }
  
  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error al marcar todas las notificaciones como leídas: $e');
      rethrow;
    }
  }
  
  // Eliminar una notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      print('Error al eliminar notificación: $e');
      rethrow;
    }
  }
  
  // Eliminar todas las notificaciones del usuario
  Future<void> deleteAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final batch = _firestore.batch();
      final notifications = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error al eliminar todas las notificaciones: $e');
      rethrow;
    }
  }
  
  // Enviar notificación para anuncios nuevos
  Future<void> sendNewAnnouncementNotification({
    required String announcementId,
    required String title,
    required String announcementTitle,
  }) async {
    final message = 'Nuevo anuncio: $announcementTitle';
    final users = await _firestore.collection('users').get();
    
    for (final user in users.docs) {
      final userId = user.id;
      await createNotification(
        title: title,
        message: message,
        type: NotificationType.newAnnouncement,
        userId: userId,
        entityId: announcementId,
        entityType: 'announcement',
        actionRoute: '/announcements/$announcementId',
      );
    }
  }
  
  // Enviar notificación para cultos nuevos
  Future<void> sendNewCultAnnouncementNotification({
    required String announcementId,
    required String cultId,
    required String cultTitle,
  }) async {
    final message = 'Nuevo anuncio de culto: $cultTitle';
    final users = await _firestore.collection('users').get();
    
    for (final user in users.docs) {
      final userId = user.id;
      await createNotification(
        title: 'Nuevo culto programado',
        message: message,
        type: NotificationType.newCultAnnouncement,
        userId: userId,
        entityId: announcementId,
        entityType: 'cult_announcement',
        data: {'cultId': cultId},
        actionRoute: '/cults/$cultId',
      );
    }
  }
  
  // Enviar notificación para ministerios nuevos
  Future<void> sendNewMinistryNotification({
    required String ministryId,
    required String ministryName,
  }) async {
    final message = 'Nuevo ministerio creado: $ministryName';
    final users = await _firestore.collection('users').get();
    
    for (final user in users.docs) {
      final userId = user.id;
      await createNotification(
        title: 'Nuevo ministerio disponible',
        message: message,
        type: NotificationType.newMinistry,
        userId: userId,
        entityId: ministryId,
        entityType: 'ministry',
        actionRoute: '/ministries/$ministryId',
      );
    }
  }
  
  // Enviar notificación cuando se acepta una solicitud para unirse a un ministerio
  Future<void> sendMinistryJoinRequestAcceptedNotification({
    required String userId,
    required String ministryId,
    required String ministryName,
  }) async {
    await createNotification(
      title: 'Solicitud aceptada',
      message: 'Tu solicitud para unirte al ministerio $ministryName ha sido aceptada',
      type: NotificationType.ministryJoinRequestAccepted,
      userId: userId,
      entityId: ministryId,
      entityType: 'ministry',
      actionRoute: '/ministries/$ministryId',
    );
  }
  
  // Enviar notificación cuando se rechaza una solicitud para unirse a un ministerio
  Future<void> sendMinistryJoinRequestRejectedNotification({
    required String userId,
    required String ministryId,
    required String ministryName,
  }) async {
    await createNotification(
      title: 'Solicitud rechazada',
      message: 'Tu solicitud para unirte al ministerio $ministryName ha sido rechazada',
      type: NotificationType.ministryJoinRequestRejected,
      userId: userId,
      entityId: ministryId,
      entityType: 'ministry',
    );
  }
  
  // Enviar notificación a los administradores cuando alguien solicita unirse a un ministerio
  Future<void> sendMinistryJoinRequestNotification({
    required String requestUserId,
    required String requestUserName,
    required String ministryId,
    required String ministryName,
    required List<String> adminIds,
  }) async {
    for (final adminId in adminIds) {
      await createNotification(
        title: 'Nueva solicitud de unión',
        message: '$requestUserName ha solicitado unirse al ministerio $ministryName',
        type: NotificationType.ministryJoinRequest,
        userId: adminId,
        senderId: requestUserId,
        entityId: ministryId,
        entityType: 'ministry',
        actionRoute: '/ministries/$ministryId/requests',
        data: {'requestUserId': requestUserId},
      );
    }
  }
  
  // Enviar notificación cuando un usuario es añadido manualmente a un ministerio
  Future<void> sendMinistryManuallyAddedNotification({
    required String userId,
    required String ministryId,
    required String ministryName,
    required String adminId,
    required String adminName,
  }) async {
    await createNotification(
      title: 'Añadido a un ministerio',
      message: '$adminName te ha añadido al ministerio $ministryName',
      type: NotificationType.ministryManuallyAdded,
      userId: userId,
      senderId: adminId,
      entityId: ministryId,
      entityType: 'ministry',
      actionRoute: '/ministries/$ministryId',
    );
  }
  
  // Enviar notificación a todos los miembros de un ministerio cuando se crea un nuevo evento
  Future<void> sendMinistryNewEventNotification({
    required String ministryId,
    required String ministryName,
    required String eventId,
    required String eventTitle,
    required List<String> memberIds,
  }) async {
    for (final memberId in memberIds) {
      await createNotification(
        title: 'Nuevo evento del ministerio',
        message: 'Se ha creado un nuevo evento para el ministerio $ministryName: $eventTitle',
        type: NotificationType.ministryNewEvent,
        userId: memberId,
        entityId: eventId,
        entityType: 'ministry_event',
        actionRoute: '/ministries/$ministryId/events/$eventId',
        data: {'ministryId': ministryId},
      );
    }
  }
  
  // Enviar notificación a todos los miembros de un ministerio cuando se crea un nuevo post
  Future<void> sendMinistryNewPostNotification({
    required String ministryId,
    required String ministryName,
    required String postId,
    required String postTitle,
    required List<String> memberIds,
  }) async {
    for (final memberId in memberIds) {
      await createNotification(
        title: 'Nueva publicación en el ministerio',
        message: 'Se ha publicado un nuevo post en el ministerio $ministryName: $postTitle',
        type: NotificationType.ministryNewPost,
        userId: memberId,
        entityId: postId,
        entityType: 'ministry_post',
        actionRoute: '/ministries/$ministryId/posts/$postId',
        data: {'ministryId': ministryId},
      );
    }
  }
  
  // Enviar notificación cuando se crea un nuevo horario de trabajo
  Future<void> sendMinistryNewWorkScheduleNotification({
    required String ministryId,
    required String ministryName,
    required String scheduleId,
    required String scheduleName,
    required List<String> workerIds,
  }) async {
    for (final workerId in workerIds) {
      await createNotification(
        title: 'Nuevo horario de trabajo',
        message: 'Se ha creado un nuevo horario de trabajo en el ministerio $ministryName: $scheduleName',
        type: NotificationType.ministryNewWorkSchedule,
        userId: workerId,
        entityId: scheduleId,
        entityType: 'work_schedule',
        actionRoute: '/ministries/$ministryId/work-schedules/$scheduleId',
        data: {'ministryId': ministryId},
      );
    }
  }
  
  // Enviar notificación cuando se acepte un horario de trabajo
  Future<void> sendMinistryWorkScheduleAcceptedNotification({
    required String ministryId,
    required String ministryName,
    required String scheduleId,
    required String scheduleName,
    required String workerId,
    required String workerName,
    required String adminId,
  }) async {
    await createNotification(
      title: 'Horario de trabajo aceptado',
      message: '$workerName ha aceptado el horario de trabajo $scheduleName',
      type: NotificationType.ministryWorkScheduleAccepted,
      userId: adminId,
      senderId: workerId,
      entityId: scheduleId,
      entityType: 'work_schedule',
      actionRoute: '/ministries/$ministryId/work-schedules/$scheduleId',
      data: {'ministryId': ministryId, 'workerId': workerId},
    );
  }
  
  // Enviar notificación cuando se rechace un horario de trabajo
  Future<void> sendMinistryWorkScheduleRejectedNotification({
    required String ministryId,
    required String ministryName,
    required String scheduleId,
    required String scheduleName,
    required String workerId,
    required String workerName,
    required String adminId,
  }) async {
    await createNotification(
      title: 'Horario de trabajo rechazado',
      message: '$workerName ha rechazado el horario de trabajo $scheduleName',
      type: NotificationType.ministryWorkScheduleRejected,
      userId: adminId,
      senderId: workerId,
      entityId: scheduleId,
      entityType: 'work_schedule',
      actionRoute: '/ministries/$ministryId/work-schedules/$scheduleId',
      data: {'ministryId': ministryId, 'workerId': workerId},
    );
  }
  
  // Enviar notificación cuando un slot de trabajo se llene
  Future<void> sendMinistryWorkSlotFilledNotification({
    required String ministryId,
    required String ministryName,
    required String scheduleId,
    required String scheduleName,
    required String slotId,
    required String slotName,
    required String adminId,
  }) async {
    await createNotification(
      title: 'Slot de trabajo completo',
      message: 'El slot $slotName del horario $scheduleName está completo',
      type: NotificationType.ministryWorkSlotFilled,
      userId: adminId,
      entityId: scheduleId,
      entityType: 'work_schedule',
      actionRoute: '/ministries/$ministryId/work-schedules/$scheduleId',
      data: {'ministryId': ministryId, 'slotId': slotId},
    );
  }
  
  // Enviar notificación cuando un slot de trabajo tenga espacios disponibles
  Future<void> sendMinistryWorkSlotAvailableNotification({
    required String ministryId,
    required String ministryName,
    required String scheduleId,
    required String scheduleName,
    required String slotId,
    required String slotName,
    required String adminId,
  }) async {
    await createNotification(
      title: 'Slot de trabajo disponible',
      message: 'El slot $slotName del horario $scheduleName tiene espacios disponibles',
      type: NotificationType.ministryWorkSlotAvailable,
      userId: adminId,
      entityId: scheduleId,
      entityType: 'work_schedule',
      actionRoute: '/ministries/$ministryId/work-schedules/$scheduleId',
      data: {'ministryId': ministryId, 'slotId': slotId},
    );
  }
  
  // Enviar recordatorio de evento de ministerio
  Future<void> sendMinistryEventReminderNotification({
    required String ministryId,
    required String ministryName,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String userId,
  }) async {
    // Usar DateFormat para pt_BR
    final formattedDate = DateFormat("d/M/yyyy 'às' HH:mm", 'pt_BR').format(eventDate);
    
    await createNotification(
      title: 'Lembrete de evento', // Traduzido
      message: 'O evento $eventTitle do ministério $ministryName começa amanhã $formattedDate', // Traduzido
      type: NotificationType.ministryEventReminder,
      userId: userId,
      entityId: eventId,
      entityType: 'ministry_event',
      actionRoute: '/ministries/$ministryId/events/$eventId',
      data: {'ministryId': ministryId},
    );
  }
  
  // Enviar notificación de nuevo chat en ministerio
  Future<void> sendMinistryNewChatNotification({
    required String ministryId,
    required String ministryName,
    required String chatId,
    required String senderName,
    required String message,
    required List<String> memberIds,
    required String senderId,
  }) async {
    for (final memberId in memberIds) {
      // No enviar notificación al remitente
      if (memberId == senderId) continue;
      
      await createNotification(
        title: 'Nuevo mensaje en $ministryName',
        message: '$senderName: $message',
        type: NotificationType.ministryNewChat,
        userId: memberId,
        senderId: senderId,
        entityId: ministryId,
        entityType: 'ministry_chat',
        actionRoute: '/ministries/$ministryId/chat',
        data: {'chatId': chatId},
      );
    }
  }
  
  // Enviar notificación cuando un usuario es promovido a administrador de ministerio
  Future<void> sendMinistryPromotedToAdminNotification({
    required String userId,
    required String ministryId,
    required String ministryName,
    required String adminId,
    required String adminName,
  }) async {
    await createNotification(
      title: 'Promovido a administrador',
      message: '$adminName te ha promovido a administrador del ministerio $ministryName',
      type: NotificationType.ministryPromotedToAdmin,
      userId: userId,
      senderId: adminId,
      entityId: ministryId,
      entityType: 'ministry',
      actionRoute: '/ministries/$ministryId',
    );
  }
  
  // Enviar notificación para grupos nuevos
  Future<void> sendNewGroupNotification({
    required String groupId,
    required String groupName,
  }) async {
    final message = 'Nuevo grupo creado: $groupName';
    final users = await _firestore.collection('users').get();
    
    for (final user in users.docs) {
      final userId = user.id;
      await createNotification(
        title: 'Nuevo grupo disponible',
        message: message,
        type: NotificationType.newGroup,
        userId: userId,
        entityId: groupId,
        entityType: 'group',
        actionRoute: '/groups/$groupId',
      );
    }
  }
  
  // Enviar notificación cuando se acepta una solicitud para unirse a un grupo
  Future<void> sendGroupJoinRequestAcceptedNotification({
    required String userId,
    required String groupId,
    required String groupName,
  }) async {
    await createNotification(
      title: 'Solicitud aceptada',
      message: 'Tu solicitud para unirte al grupo $groupName ha sido aceptada',
      type: NotificationType.groupJoinRequestAccepted,
      userId: userId,
      entityId: groupId,
      entityType: 'group',
      actionRoute: '/groups/$groupId',
    );
  }
  
  // Enviar notificación cuando se rechaza una solicitud para unirse a un grupo
  Future<void> sendGroupJoinRequestRejectedNotification({
    required String userId,
    required String groupId,
    required String groupName,
  }) async {
    await createNotification(
      title: 'Solicitud rechazada',
      message: 'Tu solicitud para unirte al grupo $groupName ha sido rechazada',
      type: NotificationType.groupJoinRequestRejected,
      userId: userId,
      entityId: groupId,
      entityType: 'group',
    );
  }
  
  // Enviar notificación a los administradores cuando alguien solicita unirse a un grupo
  Future<void> sendGroupJoinRequestNotification({
    required String requestUserId,
    required String requestUserName,
    required String groupId,
    required String groupName,
    required List<String> adminIds,
  }) async {
    for (final adminId in adminIds) {
      await createNotification(
        title: 'Nueva solicitud de unión',
        message: '$requestUserName ha solicitado unirse al grupo $groupName',
        type: NotificationType.groupJoinRequest,
        userId: adminId,
        senderId: requestUserId,
        entityId: groupId,
        entityType: 'group',
        actionRoute: '/groups/$groupId/requests',
        data: {'requestUserId': requestUserId},
      );
    }
  }
  
  // Enviar notificación cuando un usuario es añadido manualmente a un grupo
  Future<void> sendGroupManuallyAddedNotification({
    required String userId,
    required String groupId,
    required String groupName,
    required String adminId,
    required String adminName,
  }) async {
    await createNotification(
      title: 'Añadido a un grupo',
      message: '$adminName te ha añadido al grupo $groupName',
      type: NotificationType.groupManuallyAdded,
      userId: userId,
      senderId: adminId,
      entityId: groupId,
      entityType: 'group',
      actionRoute: '/groups/$groupId',
    );
  }
  
  // Enviar notificación a todos los miembros de un grupo cuando se crea un nuevo evento
  Future<void> sendGroupNewEventNotification({
    required String groupId,
    required String groupName,
    required String eventId,
    required String eventTitle,
    required List<String> memberIds,
  }) async {
    for (final memberId in memberIds) {
      await createNotification(
        title: 'Nuevo evento del grupo',
        message: 'Se ha creado un nuevo evento para el grupo $groupName: $eventTitle',
        type: NotificationType.groupNewEvent,
        userId: memberId,
        entityId: eventId,
        entityType: 'group_event',
        actionRoute: '/groups/$groupId/events/$eventId',
        data: {'groupId': groupId},
      );
    }
  }
  
  // Enviar notificación a todos los miembros de un grupo cuando se crea un nuevo post
  Future<void> sendGroupNewPostNotification({
    required String groupId,
    required String groupName,
    required String postId,
    required String postTitle,
    required List<String> memberIds,
  }) async {
    for (final memberId in memberIds) {
      await createNotification(
        title: 'Nueva publicación en el grupo',
        message: 'Se ha publicado un nuevo post en el grupo $groupName: $postTitle',
        type: NotificationType.groupNewPost,
        userId: memberId,
        entityId: postId,
        entityType: 'group_post',
        actionRoute: '/groups/$groupId/posts/$postId',
        data: {'groupId': groupId},
      );
    }
  }
  
  // Enviar recordatorio de evento de grupo
  Future<void> sendGroupEventReminderNotification({
    required String groupId,
    required String groupName,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String userId,
  }) async {
    // Usar DateFormat para pt_BR
    final formattedDate = DateFormat("d/M/yyyy 'às' HH:mm", 'pt_BR').format(eventDate);
    
    await createNotification(
      title: 'Lembrete de evento', // Traduzido
      message: 'O evento $eventTitle do grupo $groupName começa amanhã $formattedDate', // Traduzido
      type: NotificationType.groupEventReminder,
      userId: userId,
      entityId: eventId,
      entityType: 'group_event',
      actionRoute: '/groups/$groupId/events/$eventId',
      data: {'groupId': groupId},
    );
  }
  
  // Enviar notificación de nuevo chat en grupo
  Future<void> sendGroupNewChatNotification({
    required String groupId,
    required String groupName,
    required String chatId,
    required String senderName,
    required String message,
    required List<String> memberIds,
    required String senderId,
  }) async {
    for (final memberId in memberIds) {
      // No enviar notificación al remitente
      if (memberId == senderId) continue;
      
      await createNotification(
        title: 'Nuevo mensaje en $groupName',
        message: '$senderName: $message',
        type: NotificationType.groupNewChat,
        userId: memberId,
        senderId: senderId,
        entityId: groupId,
        entityType: 'group_chat',
        actionRoute: '/groups/$groupId/chat',
        data: {'chatId': chatId},
      );
    }
  }
  
  // Enviar notificación cuando un usuario es promovido a administrador de grupo
  Future<void> sendGroupPromotedToAdminNotification({
    required String userId,
    required String groupId,
    required String groupName,
    required String adminId,
    required String adminName,
  }) async {
    await createNotification(
      title: 'Promovido a administrador',
      message: '$adminName te ha promovido a administrador del grupo $groupName',
      type: NotificationType.groupPromotedToAdmin,
      userId: userId,
      senderId: adminId,
      entityId: groupId,
      entityType: 'group',
      actionRoute: '/groups/$groupId',
    );
  }
  
  // Enviar notificación cuando se crea una nueva oración privada
  Future<void> sendNewPrivatePrayerNotification({
    required String prayerId,
    required String requestorName,
    required String requestorId,
    required List<String> pastorIds,
  }) async {
    for (final pastorId in pastorIds) {
      await createNotification(
        title: 'Nueva solicitud de oración',
        message: '$requestorName ha solicitado una oración privada',
        type: NotificationType.newPrivatePrayer,
        userId: pastorId,
        senderId: requestorId,
        entityId: prayerId,
        entityType: 'private_prayer',
        actionRoute: '/prayers/private/$prayerId',
      );
    }
  }
  
  // Enviar notificación cuando un pastor ha rezado por una solicitud de oración privada
  Future<void> sendPrivatePrayerPrayedNotification({
    required String prayerId,
    required String pastorName,
    required String pastorId,
    required String requestorId,
  }) async {
    await createNotification(
      title: 'Oración completada',
      message: '$pastorName ha rezado por tu solicitud de oración',
      type: NotificationType.privatePrayerPrayed,
      userId: requestorId,
      senderId: pastorId,
      entityId: prayerId,
      entityType: 'private_prayer',
      actionRoute: '/prayers/private/requests',
    );
  }
  
  // Enviar notificación cuando se acepta una oración pública
  Future<void> sendPublicPrayerAcceptedNotification({
    required String prayerId,
    required String prayerTitle,
    required List<String> voterIds,
  }) async {
    for (final voterId in voterIds) {
      await createNotification(
        title: 'Oración pública aceptada',
        message: 'La oración "$prayerTitle" ha sido aceptada',
        type: NotificationType.publicPrayerAccepted,
        userId: voterId,
        entityId: prayerId,
        entityType: 'public_prayer',
        actionRoute: '/prayers/public/$prayerId',
      );
    }
  }
  
  // Enviar notificación cuando se crea un nuevo evento
  Future<void> sendNewEventNotification({
    required String eventId,
    required String eventTitle,
  }) async {
    final users = await _firestore.collection('users').get();
    
    for (final user in users.docs) {
      final userId = user.id;
      await createNotification(
        title: 'Nuevo evento',
        message: 'Se ha creado un nuevo evento: $eventTitle',
        type: NotificationType.newEvent,
        userId: userId,
        entityId: eventId,
        entityType: 'event',
        actionRoute: '/events/$eventId',
      );
    }
  }
  
  // Enviar recordatorio de evento
  Future<void> sendEventReminderNotification({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String userId,
  }) async {
    // Usar DateFormat para pt_BR
    final formattedDate = DateFormat("d/M/yyyy 'às' HH:mm", 'pt_BR').format(eventDate);
    
    await createNotification(
      title: 'Lembrete de evento', // Traduzido
      message: 'O evento $eventTitle começa amanhã $formattedDate', // Traduzido
      type: NotificationType.eventReminder,
      userId: userId,
      entityId: eventId,
      entityType: 'event',
      actionRoute: '/events/$eventId',
    );
  }
  
  // Enviar notificación cuando se crea una nueva solicitud de consejería
  Future<void> sendNewCounselingRequestNotification({
    required String appointmentId,
    required String requestorName,
    required String requestorId,
    required String pastorId,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} a las ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}';
    
    await createNotification(
      title: 'Nueva solicitud de consejería',
      message: '$requestorName ha solicitado una cita de consejería para el $formattedDate',
      type: NotificationType.newCounselingRequest,
      userId: pastorId,
      senderId: requestorId,
      entityId: appointmentId,
      entityType: 'counseling_appointment',
      actionRoute: '/counseling/pastor-requests',
    );
  }
  
  // Enviar notificación cuando se acepta una solicitud de consejería
  Future<void> sendCounselingAcceptedNotification({
    required String appointmentId,
    required String pastorName,
    required String pastorId,
    required String requestorId,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} a las ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}';
    
    await createNotification(
      title: 'Cita de consejería confirmada',
      message: '$pastorName ha confirmado tu cita de consejería para el $formattedDate',
      type: NotificationType.counselingAccepted,
      userId: requestorId,
      senderId: pastorId,
      entityId: appointmentId,
      entityType: 'counseling_appointment',
      actionRoute: '/counseling',
    );
  }
  
  // Enviar notificación cuando se rechaza una solicitud de consejería
  Future<void> sendCounselingRejectedNotification({
    required String appointmentId,
    required String pastorName,
    required String pastorId,
    required String requestorId,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} a las ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}';
    
    await createNotification(
      title: 'Cita de consejería rechazada',
      message: '$pastorName ha rechazado tu cita de consejería para el $formattedDate',
      type: NotificationType.counselingRejected,
      userId: requestorId,
      senderId: pastorId,
      entityId: appointmentId,
      entityType: 'counseling_appointment',
      actionRoute: '/counseling',
    );
  }
  
  // Enviar notificación cuando se cancela una cita de consejería (tanto por el pastor como por el usuario)
  Future<void> sendCounselingCancelledNotification({
    required String appointmentId,
    required String cancellerName,
    required String cancellerId,
    required String receiverId,
    required DateTime appointmentDate,
  }) async {
    final formattedDate = '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} a las ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}';
    
    await createNotification(
      title: 'Cita de consejería cancelada',
      message: '$cancellerName ha cancelado la cita de consejería para el $formattedDate',
      type: NotificationType.counselingCancelled,
      userId: receiverId,
      senderId: cancellerId,
      entityId: appointmentId,
      entityType: 'counseling_appointment',
      actionRoute: '/counseling',
    );
  }
  
  // Enviar notificación cuando se sube un nuevo video
  Future<void> sendNewVideoNotification({
    required String videoId,
    required String videoTitle,
  }) async {
    final users = await _firestore.collection('users').get();
    
    for (final user in users.docs) {
      final userId = user.id;
      await createNotification(
        title: 'Nuevo video disponible',
        message: 'Se ha subido un nuevo video: $videoTitle',
        type: NotificationType.newVideo,
        userId: userId,
        entityId: videoId,
        entityType: 'video',
        actionRoute: '/videos/$videoId',
      );
    }
  }
  
  // Método genérico para enviar notificaciones
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String? entityId,
    String? entityType,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionRoute,
  }) async {
    final currentUserId = _auth.currentUser?.uid ?? '';
    print('🔔 NotificationService - Enviando a: $userId');
    print('🔔 NotificationService - Remitente (currentUser): $currentUserId');
    print('🔔 NotificationService - ¿Es el mismo usuario?: ${userId == currentUserId}');
    print('🔔 NotificationService - Título: $title');
    print('🔔 NotificationService - Datos adicionales: $data');
    
    try {
      await createNotification(
        title: title,
        message: body,
        type: NotificationType.generic,
        userId: userId,
        data: data,
        entityId: entityId,
        entityType: entityType,
        imageUrl: imageUrl,
        actionRoute: actionRoute,
      );
      print('✅ NotificationService - Notificación creada exitosamente para: $userId');
    } catch (e) {
      print('❌ Error al enviar notificación: $e');
      rethrow;
    }
  }
} 