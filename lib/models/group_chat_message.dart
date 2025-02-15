import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatMessage {
  final String id;
  final DocumentReference authorId;
  final String content;
  final DateTime createdAt;

  GroupChatMessage({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory GroupChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    
    if (data['content'] == null || data['authorId'] == null) {
      throw FormatException('Invalid chat message data');
    }

    return GroupChatMessage(
      id: doc.id,
      authorId: data['authorId'],
      content: data['content'] as String,
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}