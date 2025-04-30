import 'package:cloud_firestore/cloud_firestore.dart';

class StreamImage {
  final String id;
  final String imageUrl;
  final Timestamp uploadedAt;
  final String uploadedBy; // User ID

  StreamImage({
    required this.id,
    required this.imageUrl,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory StreamImage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StreamImage(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      uploadedAt: data['uploadedAt'] ?? Timestamp.now(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'uploadedAt': uploadedAt,
      'uploadedBy': uploadedBy,
    };
  }
} 