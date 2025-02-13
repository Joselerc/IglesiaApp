import 'package:cloud_firestore/cloud_firestore.dart';

class GroupPostComment {
  final String id;
  final String content;
  final DateTime createdAt;
  final DocumentReference authorId;
  final DocumentReference groupPostId;
  final DocumentReference? parentCommentId;
  final List<DocumentReference> likes;

  GroupPostComment({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.authorId,
    required this.groupPostId,
    this.parentCommentId,
    required this.likes,
  });

  factory GroupPostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupPostComment(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorId: data['authorId'],
      groupPostId: data['groupPostId'],
      parentCommentId: data['parentCommentId'],
      likes: List<DocumentReference>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
      'groupPostId': groupPostId,
      'parentCommentId': parentCommentId,
      'likes': likes,
    };
  }
} 