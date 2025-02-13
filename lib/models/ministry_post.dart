import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryPost {
  final String id;
  final DocumentReference authorId;  // Cambiado a DocumentReference
  final String contentText;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<DocumentReference> likes;  // Cambiado a DocumentReference
  final DocumentReference ministryId;  // Cambiado a DocumentReference
  final List<DocumentReference> savedBy;  // Cambiado a DocumentReference
  final List<DocumentReference> shares;  // Añadido para compartidos
  final List<DocumentReference> comments;  // Añadido para comentarios

  MinistryPost({
    required this.id,
    required this.authorId,
    required this.contentText,
    required this.createdAt,
    required this.imageUrls,
    required this.likes,
    required this.ministryId,
    required this.savedBy,
    required this.shares,
    required this.comments,
  });

  factory MinistryPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinistryPost(
      id: doc.id,
      authorId: data['authorId'] as DocumentReference,
      contentText: data['contentText'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: List<DocumentReference>.from(data['likes'] ?? []),
      ministryId: data['ministryId'] as DocumentReference,
      savedBy: List<DocumentReference>.from(data['savedBy'] ?? []),
      shares: List<DocumentReference>.from(data['shares'] ?? []),
      comments: List<DocumentReference>.from(data['comments'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'contentText': contentText,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrls': imageUrls,
      'likes': likes,
      'ministryId': ministryId,
      'savedBy': savedBy,
      'shares': shares,
      'comments': comments,
    };
  }
} 