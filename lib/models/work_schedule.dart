import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
    );
  }
}

class WorkSchedule {
  final String? id;
  final String jobName;
  final String? description;
  final int requiredWorkers;
  final DateTime date;
  final TimeSlot timeSlot;
  final List<DocumentReference> invitedWorkers;
  final String status; // 'pending', 'active', 'completed'
  final String ministryId;
  final DateTime createdAt;
  final Map<DocumentReference, String> workersStatus; // userId: 'pending', 'accepted', 'rejected'
  final List<StatusChange> statusHistory;

  int get acceptedWorkersCount => 
    workersStatus.values.where((status) => status == 'accepted').length;

  bool get hasAvailableSpots => 
    acceptedWorkersCount < requiredWorkers;

  WorkSchedule({
    this.id,
    required this.jobName,
    this.description,
    required this.requiredWorkers,
    required this.date,
    required this.timeSlot,
    required this.invitedWorkers,
    required this.status,
    required this.ministryId,
    required this.createdAt,
    required this.workersStatus,
    this.statusHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'jobName': jobName,
      'description': description,
      'requiredWorkers': requiredWorkers,
      'date': Timestamp.fromDate(date),
      'timeSlot': timeSlot.toMap(),
      'invitedWorkers': invitedWorkers,
      'status': status,
      'ministryId': ministryId,
      'createdAt': Timestamp.fromDate(createdAt),
      'workersStatus': workersStatus.map((key, value) => MapEntry(key.path, value)),
      'statusHistory': statusHistory.map((change) => change.toMap()).toList(),
    };
  }

  factory WorkSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir el mapa de workersStatus de paths a DocumentReferences
    final Map<String, dynamic> rawWorkersStatus = data['workersStatus'] ?? {};
    final Map<DocumentReference, String> convertedWorkersStatus = {};
    
    for (var entry in rawWorkersStatus.entries) {
      final userRef = FirebaseFirestore.instance.doc(entry.key);
      convertedWorkersStatus[userRef] = entry.value;
    }

    return WorkSchedule(
      id: doc.id,
      jobName: data['jobName'] ?? '',
      description: data['description'],
      requiredWorkers: data['requiredWorkers'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      timeSlot: TimeSlot.fromMap(data['timeSlot'] as Map<String, dynamic>),
      invitedWorkers: List<DocumentReference>.from(data['invitedWorkers'] ?? []),
      status: data['status'] ?? 'pending',
      ministryId: data['ministryId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      workersStatus: convertedWorkersStatus,
      statusHistory: (data['statusHistory'] as List<dynamic>?)
          ?.map((change) => StatusChange.fromMap(change as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class StatusChange {
  final DocumentReference user;
  final String fromStatus;
  final String toStatus;
  final DateTime timestamp;

  StatusChange({
    required this.user,
    required this.fromStatus,
    required this.toStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'user': user,
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      user: map['user'],
      fromStatus: map['fromStatus'],
      toStatus: map['toStatus'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
} 