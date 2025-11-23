import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryPost {
  final String id;
  final DocumentReference authorId;
  final DocumentReference ministryId;
  final String? title;
  final String contentText;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<DocumentReference> likes;
  final List<DocumentReference> savedBy;
  final List<DocumentReference> shares;
  final List<DocumentReference> comments;
  final DateTime? date;
  final String aspectRatio;
  final int commentCount;

  MinistryPost({
    required this.id,
    required this.authorId,
    required this.ministryId,
    this.title,
    required this.contentText,
    required this.createdAt,
    required this.imageUrls,
    required this.likes,
    required this.savedBy,
    required this.shares,
    required this.comments,
    this.date,
    this.aspectRatio = 'AspectRatioOption.square',
    this.commentCount = 0,
  });

  factory MinistryPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinistryPost(
      id: doc.id,
      authorId: data['authorId'] as DocumentReference,
      ministryId: data['ministryId'] as DocumentReference,
      title: data['title'] as String?,
      contentText: data['contentText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: List<DocumentReference>.from(data['likes'] ?? []),
      savedBy: List<DocumentReference>.from(data['savedBy'] ?? []),
      shares: List<DocumentReference>.from(data['shares'] ?? []),
      comments: List<DocumentReference>.from(data['comments'] ?? []),
      date: (data['date'] as Timestamp?)?.toDate(),
      aspectRatio: data['aspectRatio'] ?? 'AspectRatioOption.square',
      commentCount: (data['commentCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'ministryId': ministryId,
      'title': title,
      'contentText': contentText,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrls': imageUrls,
      'likes': likes,
      'savedBy': savedBy,
      'shares': shares,
      'comments': comments,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'aspectRatio': aspectRatio,
      'commentCount': commentCount,
    };
  }
} 