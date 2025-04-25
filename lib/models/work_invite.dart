import 'package:cloud_firestore/cloud_firestore.dart';

class WorkInvite {
  final String id;
  final String assignmentId;
  final String userId;
  final String entityId; // ID del culto, evento, etc.
  final String entityType; // tipo: 'cult', 'event', etc.
  final String entityName; // nombre del culto, evento, etc.
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String ministryId;
  final String ministryName;
  final String role;
  final String status; // pending, accepted, rejected, seen
  final bool isRead;
  final bool isActive;
  final bool isVisible; // Campo para controlar visibilidad basada en capacidad
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String sentBy;

  WorkInvite({
    required this.id,
    required this.assignmentId,
    required this.userId,
    required this.entityId,
    required this.entityType,
    required this.entityName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.ministryId,
    required this.ministryName,
    required this.role,
    required this.status,
    this.isRead = false,
    this.isActive = true,
    this.isVisible = true,
    required this.createdAt,
    this.respondedAt,
    required this.sentBy,
  });

  factory WorkInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkInvite(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      userId: data['userId']?.id ?? '',
      entityId: data['entityId'] ?? '',
      entityType: data['entityType'] ?? '',
      entityName: data['entityName'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ministryId: data['ministryId']?.id ?? '',
      ministryName: data['ministryName'] ?? '',
      role: data['role'] ?? '',
      status: data['status'] ?? 'pending',
      isRead: data['isRead'] ?? false,
      isActive: data['isActive'] ?? true,
      isVisible: data['isVisible'] ?? true, // Por defecto, visible
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      sentBy: data['sentBy']?.id ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'assignmentId': assignmentId,
      'userId': FirebaseFirestore.instance.collection('users').doc(userId),
      'entityId': entityId,
      'entityType': entityType,
      'entityName': entityName,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'ministryId': FirebaseFirestore.instance.collection('ministries').doc(ministryId),
      'ministryName': ministryName,
      'role': role,
      'status': status,
      'isRead': isRead,
      'isActive': isActive,
      'isVisible': isVisible,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentBy': FirebaseFirestore.instance.collection('users').doc(sentBy),
    };

    if (respondedAt != null) {
      map['respondedAt'] = Timestamp.fromDate(respondedAt!);
    }

    return map;
  }

  // Método para crear una copia del objeto con nuevos valores
  WorkInvite copyWith({
    String? id,
    String? assignmentId,
    String? userId,
    String? entityId,
    String? entityType,
    String? entityName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? ministryId,
    String? ministryName,
    String? role,
    String? status,
    bool? isRead,
    bool? isActive,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? sentBy,
  }) {
    return WorkInvite(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      userId: userId ?? this.userId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      entityName: entityName ?? this.entityName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ministryId: ministryId ?? this.ministryId,
      ministryName: ministryName ?? this.ministryName,
      role: role ?? this.role,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      sentBy: sentBy ?? this.sentBy,
    );
  }
} 