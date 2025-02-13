import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String ministryId;
  final String authorId;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> savedBy;

  Post({
    required this.id,
    required this.ministryId,
    required this.authorId,
    required this.content,
    required this.imageUrls,
    required this.createdAt,
    required this.likes,
    required this.savedBy,
  });

  factory Post.fromMap(Map<String, dynamic> map, String id) {
    return Post(
      id: id,
      ministryId: map['ministryId'] ?? '',
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
      savedBy: List<String>.from(map['savedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ministryId': ministryId,
      'authorId': authorId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'savedBy': savedBy,
    };
  }
} 