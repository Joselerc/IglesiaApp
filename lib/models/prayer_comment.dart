import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerComment {
  final String id;
  final DocumentReference authorId;
  final String content;
  final DateTime createdAt;
  final List<DocumentReference> likes;
  final DocumentReference prayerId;

  PrayerComment({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.prayerId,
  });

  factory PrayerComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrayerComment(
      id: doc.id,
      authorId: data['authorId'],
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likes: (data['likes'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
      prayerId: data['prayerId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'prayerId': prayerId,
    };
  }
} 