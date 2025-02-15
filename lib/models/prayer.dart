import 'package:cloud_firestore/cloud_firestore.dart';

class Prayer {
  final String id;
  final String content;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final bool isAnonymous;
  final List<DocumentReference> upVotedBy;
  final List<DocumentReference> downVotedBy;
  final bool isAccepted;
  final DocumentReference? acceptedBy;

  Prayer({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    required this.isAnonymous,
    required this.upVotedBy,
    required this.downVotedBy,
    required this.isAccepted,
    this.acceptedBy,
  });

  factory Prayer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prayer(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      isAnonymous: data['isAnonymous'] ?? false,
      upVotedBy: (data['upVotedBy'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
      downVotedBy: (data['downVotedBy'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
      isAccepted: data['isAccepted'] ?? false,
      acceptedBy: data['acceptedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isAnonymous': isAnonymous,
      'upVotedBy': upVotedBy,
      'downVotedBy': downVotedBy,
      'isAccepted': isAccepted,
      'acceptedBy': acceptedBy,
    };
  }
} 