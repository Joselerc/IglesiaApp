import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentReminder {
  final DateTime date;
  final bool isSet;

  AppointmentReminder({
    required this.date,
    required this.isSet,
  });

  factory AppointmentReminder.fromMap(Map<String, dynamic> map) {
    return AppointmentReminder(
      date: (map['date'] as Timestamp).toDate(),
      isSet: map['isSet'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'isSet': isSet,
    };
  }
}

class CounselingAppointment {
  final String id;
  final DocumentReference pastorId;
  final DocumentReference userId;
  final DateTime date;
  final bool isOnline;
  final String location;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final AppointmentReminder? reminder;
  final DateTime createdAt;

  CounselingAppointment({
    required this.id,
    required this.pastorId,
    required this.userId,
    required this.date,
    required this.isOnline,
    required this.location,
    required this.status,
    this.reminder,
    required this.createdAt,
  });

  factory CounselingAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CounselingAppointment(
      id: doc.id,
      pastorId: data['pastorId'],
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      location: data['location'] ?? '',
      status: data['status'] ?? 'scheduled',
      reminder: data['reminder'] != null 
          ? AppointmentReminder.fromMap(data['reminder'])
          : null,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pastorId': pastorId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'isOnline': isOnline,
      'location': location,
      'status': status,
      'reminder': reminder?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isPast => date.isBefore(DateTime.now());
  
  bool get isUpcoming => date.isAfter(DateTime.now()) && status == 'scheduled';
  
  bool get isCancelled => status == 'cancelled';
  
  bool get isCompleted => status == 'completed' || 
      (date.isBefore(DateTime.now()) && status == 'scheduled');
} 