import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final bool isActive;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as DocumentReference,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }
} 