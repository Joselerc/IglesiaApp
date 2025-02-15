import 'package:cloud_firestore/cloud_firestore.dart';

class PrivatePrayer {
  final String id;
  final DocumentReference pastorId;
  final DocumentReference userId;
  final String content;
  final DateTime createdAt;
  final bool isAccepted;
  final List<String> preferredMethods;
  final String? selectedMethod;
  final DateTime? scheduledAt;

  PrivatePrayer({
    required this.id,
    required this.pastorId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.isAccepted,
    required this.preferredMethods,
    this.selectedMethod,
    this.scheduledAt,
  });

  factory PrivatePrayer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrivatePrayer(
      id: doc.id,
      pastorId: data['pastorId'],
      userId: data['userId'],
      content: data['content'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isAccepted: data['isAccepted'] ?? false,
      preferredMethods: List<String>.from(data['preferredMethods'] ?? []),
      selectedMethod: data['selectedMethod'],
      scheduledAt: data['scheduledAt'] != null 
          ? (data['scheduledAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pastorId': pastorId,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAccepted': isAccepted,
      'preferredMethods': preferredMethods,
      'selectedMethod': selectedMethod,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    };
  }
} 