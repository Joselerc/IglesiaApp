import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryAvailability {
  final String userId;
  final String ministryId;
  final Map<String, List<String>> weeklyAvailability;
  final DateTime lastUpdated;

  MinistryAvailability({
    required this.userId,
    required this.ministryId,
    required this.weeklyAvailability,
    required this.lastUpdated,
  });

  factory MinistryAvailability.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MinistryAvailability(
      userId: data['userId'] ?? '',
      ministryId: data['ministryId'] ?? '',
      weeklyAvailability: Map<String, List<String>>.from(
        data['availability'].map((key, value) => 
          MapEntry(key, List<String>.from(value))
        ),
      ),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'ministryId': ministryId,
      'availability': weeklyAvailability,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
} 