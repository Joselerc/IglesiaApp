import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryEvent {
  final String id;
  final String title;
  final String imageUrl;
  final DocumentReference ministryId;
  final DateTime date;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final String description;
  final bool isActive;

  MinistryEvent({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ministryId,
    required this.date,
    required this.createdAt,
    required this.createdBy,
    required this.description,
    required this.isActive,
  });

  factory MinistryEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinistryEvent(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ministryId: data['ministryId'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }
} 