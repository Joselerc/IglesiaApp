import 'package:cloud_firestore/cloud_firestore.dart';

class GroupEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String imageUrl;
  final DocumentReference groupId;
  final DocumentReference createdBy;
  final DateTime createdAt;
  final bool isActive;
  final List<DocumentReference> attendees;

  GroupEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.groupId,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    required this.attendees,
  });

  factory GroupEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] ?? '',
      groupId: data['groupId'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      attendees: List<DocumentReference>.from(data['attendees'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'groupId': groupId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'attendees': attendees,
    };
  }
} 