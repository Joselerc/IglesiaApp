import 'package:cloud_firestore/cloud_firestore.dart';

class GroupPost {
  final String id;
  final String contentText;
  final DateTime createdAt;
  final DocumentReference authorId;
  final DocumentReference groupId;
  final List<String> imageUrls;
  final List<DocumentReference> likes;
  final List<DocumentReference> savedBy;
  final List<DocumentReference> shares;

  GroupPost({
    required this.id,
    required this.contentText,
    required this.createdAt,
    required this.authorId,
    required this.groupId,
    required this.imageUrls,
    required this.likes,
    required this.savedBy,
    required this.shares,
  });

  factory GroupPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupPost(
      id: doc.id,
      contentText: data['contentText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      authorId: data['authorId'],
      groupId: data['groupId'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: List<DocumentReference>.from(data['likes'] ?? []),
      savedBy: List<DocumentReference>.from(data['savedBy'] ?? []),
      shares: List<DocumentReference>.from(data['shares'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentText': contentText,
      'createdAt': Timestamp.fromDate(createdAt),
      'authorId': authorId,
      'groupId': groupId,
      'imageUrls': imageUrls,
      'likes': likes,
      'savedBy': savedBy,
      'shares': shares,
    };
  }
} 