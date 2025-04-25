import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryAttendance {
  final String taskId;
  final String userId;
  final String status; // 'attended', 'missed', 'rejected'
  final String? reason;
  final DateTime date;

  MinistryAttendance({
    required this.taskId,
    required this.userId,
    required this.status,
    this.reason,
    required this.date,
  });

  factory MinistryAttendance.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MinistryAttendance(
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'missed',
      reason: data['reason'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskId': taskId,
      'userId': userId,
      'status': status,
      'reason': reason,
      'date': Timestamp.fromDate(date),
    };
  }
} 