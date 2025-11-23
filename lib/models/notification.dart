import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  // Anuncios
  newAnnouncement,
  newCultAnnouncement,
  
  // Ministerios
  newMinistry,
  ministryJoinRequestAccepted,
  ministryJoinRequestRejected,
  ministryJoinRequest,
  ministryManuallyAdded,
  ministryNewEvent,
  ministryNewPost,
  ministryNewWorkSchedule,
  ministryWorkScheduleAccepted,
  ministryWorkScheduleRejected,
  ministryWorkSlotFilled,
  ministryWorkSlotAvailable,
  ministryEventReminder,
  ministryNewChat,
  ministryPromotedToAdmin,
  
  // Grupos
  newGroup,
  groupJoinRequestAccepted,
  groupJoinRequestRejected,
  groupJoinRequest,
  groupManuallyAdded,
  groupNewEvent,
  groupNewPost,
  groupEventReminder,
  groupNewChat,
  groupPromotedToAdmin,
  
  // Oraciones
  newPrivatePrayer,
  privatePrayerPrayed,
  publicPrayerAccepted,
  
  // Eventos
  newEvent,
  eventReminder,
  
  // Consejería
  newCounselingRequest,
  counselingAccepted,
  counselingRejected,
  counselingCancelled,
  
  // Videos
  newVideo,
  
  // Otras
  message,
  generic,
  custom
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String userId; // ID del usuario que recibe la notificación
  final String senderId; // ID de quien envía la notificación (opcional)
  final Map<String, dynamic> data; // Datos adicionales específicos del tipo
  final String? imageUrl;
  final String? actionRoute; // Ruta a la que navegar al tocar la notificación
  final String? entityId; // ID de la entidad relacionada (evento, ministerio, etc.)
  final String? entityType; // Tipo de entidad (evento, ministerio, etc.)
  final String? ministryId; // ID del ministerio relacionado (para filtrado fácil)
  final String? groupId; // ID del grupo relacionado (para filtrado fácil)

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.userId,
    this.senderId = '',
    this.isRead = false,
    this.data = const {},
    this.imageUrl,
    this.actionRoute,
    this.entityId,
    this.entityType,
    this.ministryId,
    this.groupId,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => NotificationType.custom,
      ),
      userId: data['userId'] ?? '',
      senderId: data['senderId'] ?? '',
      isRead: data['isRead'] ?? false,
      data: data['data'] ?? {},
      imageUrl: data['imageUrl'],
      actionRoute: data['actionRoute'],
      entityId: data['entityId'],
      entityType: data['entityType'],
      ministryId: data['ministryId'],
      groupId: data['groupId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.toString().split('.').last,
      'userId': userId,
      'senderId': senderId,
      'isRead': isRead,
      'data': data,
      'imageUrl': imageUrl,
      'actionRoute': actionRoute,
      'entityId': entityId,
      'entityType': entityType,
      'ministryId': ministryId,
      'groupId': groupId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    NotificationType? type,
    String? userId,
    String? senderId,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionRoute,
    String? entityId,
    String? entityType,
    String? ministryId,
    String? groupId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionRoute: actionRoute ?? this.actionRoute,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      ministryId: ministryId ?? this.ministryId,
      groupId: groupId ?? this.groupId,
    );
  }
  
  // Método para obtener el icono según el tipo de notificación
  IconData getIcon() {
    switch (type) {
      // Anuncios
      case NotificationType.newAnnouncement:
      case NotificationType.newCultAnnouncement:
        return Icons.announcement;
      
      // Ministerios
      case NotificationType.newMinistry:
      case NotificationType.ministryJoinRequestAccepted:
      case NotificationType.ministryJoinRequestRejected:
      case NotificationType.ministryJoinRequest:
      case NotificationType.ministryManuallyAdded:
      case NotificationType.ministryPromotedToAdmin:
        return Icons.people;
      
      case NotificationType.ministryNewEvent:
      case NotificationType.ministryEventReminder:
        return Icons.event;
      
      case NotificationType.ministryNewPost:
        return Icons.article;
      
      case NotificationType.ministryNewWorkSchedule:
      case NotificationType.ministryWorkScheduleAccepted:
      case NotificationType.ministryWorkScheduleRejected:
      case NotificationType.ministryWorkSlotFilled:
      case NotificationType.ministryWorkSlotAvailable:
        return Icons.work;
      
      case NotificationType.ministryNewChat:
        return Icons.chat;
      
      // Grupos
      case NotificationType.newGroup:
      case NotificationType.groupJoinRequestAccepted:
      case NotificationType.groupJoinRequestRejected:
      case NotificationType.groupJoinRequest:
      case NotificationType.groupManuallyAdded:
      case NotificationType.groupPromotedToAdmin:
        return Icons.group;
      
      case NotificationType.groupNewEvent:
      case NotificationType.groupEventReminder:
        return Icons.event_note;
      
      case NotificationType.groupNewPost:
        return Icons.post_add;
      
      case NotificationType.groupNewChat:
        return Icons.chat_bubble;
      
      // Oraciones
      case NotificationType.newPrivatePrayer:
      case NotificationType.privatePrayerPrayed:
      case NotificationType.publicPrayerAccepted:
        return Icons.healing;
      
      // Eventos
      case NotificationType.newEvent:
      case NotificationType.eventReminder:
        return Icons.calendar_today;
      
      // Consejería
      case NotificationType.newCounselingRequest:
      case NotificationType.counselingAccepted:
      case NotificationType.counselingRejected:
      case NotificationType.counselingCancelled:
        return Icons.support_agent;
      
      // Videos
      case NotificationType.newVideo:
        return Icons.video_library;
      
      // Otros
      case NotificationType.message:
        return Icons.message;
      
      case NotificationType.generic:
        return Icons.help;
      
      case NotificationType.custom:
        return Icons.notifications;
    }
  }
  
  // Devuelve el color asociado con el tipo de notificación
  Color getColor() {
    switch (type) {
      // Anuncios
      case NotificationType.newAnnouncement:
      case NotificationType.newCultAnnouncement:
        return Colors.amber;
      
      // Ministerios
      case NotificationType.newMinistry:
      case NotificationType.ministryJoinRequestAccepted:
      case NotificationType.ministryJoinRequestRejected:
      case NotificationType.ministryJoinRequest:
      case NotificationType.ministryManuallyAdded:
      case NotificationType.ministryNewEvent:
      case NotificationType.ministryNewPost:
      case NotificationType.ministryNewWorkSchedule:
      case NotificationType.ministryWorkScheduleAccepted:
      case NotificationType.ministryWorkScheduleRejected:
      case NotificationType.ministryWorkSlotFilled:
      case NotificationType.ministryWorkSlotAvailable:
      case NotificationType.ministryEventReminder:
      case NotificationType.ministryNewChat:
      case NotificationType.ministryPromotedToAdmin:
        return Colors.blue;
      
      // Grupos
      case NotificationType.newGroup:
      case NotificationType.groupJoinRequestAccepted:
      case NotificationType.groupJoinRequestRejected:
      case NotificationType.groupJoinRequest:
      case NotificationType.groupManuallyAdded:
      case NotificationType.groupNewEvent:
      case NotificationType.groupNewPost:
      case NotificationType.groupEventReminder:
      case NotificationType.groupNewChat:
      case NotificationType.groupPromotedToAdmin:
        return Colors.green;
      
      // Oraciones
      case NotificationType.newPrivatePrayer:
      case NotificationType.privatePrayerPrayed:
      case NotificationType.publicPrayerAccepted:
        return Colors.purple;
      
      // Eventos
      case NotificationType.newEvent:
      case NotificationType.eventReminder:
        return Colors.orange;
      
      // Consejería
      case NotificationType.newCounselingRequest:
      case NotificationType.counselingAccepted:
      case NotificationType.counselingRejected:
      case NotificationType.counselingCancelled:
        return Colors.teal;
      
      // Videos
      case NotificationType.newVideo:
        return Colors.red;
      
      // Otros
      case NotificationType.message:
        return Colors.indigo;
      
      case NotificationType.generic:
        return Colors.grey;
      
      case NotificationType.custom:
        return Colors.grey;
    }
  }
} 