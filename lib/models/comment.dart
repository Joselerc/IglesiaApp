import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorId;  // Referencia a /users/{userId}
  final String content;
  final DateTime createdAt;
  final int level;
  final String? parentCommentId;  // Referencia a /comments/{commentId}
  final String postId;  // Referencia a /ministry_posts/{postId}

  Comment({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.level,
    this.parentCommentId,
    required this.postId,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      level: map['level'] ?? 1,
      parentCommentId: map['parentCommentId'],
      postId: map['postId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'level': level,
      'parentCommentId': parentCommentId,
      'postId': postId,
    };
  }
} 