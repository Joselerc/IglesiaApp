import 'package:cloud_firestore/cloud_firestore.dart';

class VideoSection {
  final String id;
  final String title;
  final String type;
  final int order;
  final List<String> videoIds;

  VideoSection({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
    this.videoIds = const [],
  });

  factory VideoSection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoSection(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'custom',
      order: data['order'] ?? 0,
      videoIds: List<String>.from(data['videoIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': type,
      'order': order,
      'videoIds': videoIds,
    };
  }
} 