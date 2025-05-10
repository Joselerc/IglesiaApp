import 'package:cloud_firestore/cloud_firestore.dart';

class KidRoomModel {
  final String id;
  final String name;
  final int? capacity;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  KidRoomModel({
    required this.id,
    required this.name,
    this.capacity,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory KidRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return KidRoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      capacity: data['capacity'] as int?,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// Colección en Firestore: kidRooms 