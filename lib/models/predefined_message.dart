import 'package:cloud_firestore/cloud_firestore.dart';

class PredefinedMessage {
  final String id;
  final String content;
  final DocumentReference createdBy;
  final DateTime createdAt;
  final bool isActive;

  PredefinedMessage({
    required this.id,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  factory PredefinedMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PredefinedMessage(
      id: doc.id,
      content: data['content'] ?? '',
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
} 