import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String id;
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumbnailUrl;
  final DateTime uploadDate;
  final int likes;
  final List<String> likedByUsers;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.uploadDate,
    this.likes = 0,
    this.likedByUsers = const [],
  });

  factory Video.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Video(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'thumbnailUrl': thumbnailUrl,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'likes': likes,
      'likedByUsers': likedByUsers,
    };
  }
} 