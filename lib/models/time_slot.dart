import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String id;
  final String entityId; // ID del culto, evento, u otra entidad a la que pertenece
  final String entityType; // 'cult', 'event', etc.
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  TimeSlot({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  factory TimeSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeSlot(
      id: doc.id,
      entityId: data['entityId'] ?? '',
      entityType: data['entityType'] ?? '',
      name: data['name'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy']?.id ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'name': name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': FirebaseFirestore.instance.collection('users').doc(createdBy),
    };
  }

  // Método para crear una copia del objeto con nuevos valores
  TimeSlot copyWith({
    String? id,
    String? entityId,
    String? entityType,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
} 