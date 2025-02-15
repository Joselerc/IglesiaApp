import 'package:cloud_firestore/cloud_firestore.dart';

class DaySchedule {
  final bool isWorking;
  final String? onlineStart;
  final String? onlineEnd;
  final String? inPersonStart;
  final String? inPersonEnd;

  DaySchedule({
    required this.isWorking,
    this.onlineStart,
    this.onlineEnd,
    this.inPersonStart,
    this.inPersonEnd,
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      isWorking: map['isWorking'] ?? false,
      onlineStart: map['onlineStart'],
      onlineEnd: map['onlineEnd'],
      inPersonStart: map['inPersonStart'],
      inPersonEnd: map['inPersonEnd'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isWorking': isWorking,
      'onlineStart': onlineStart,
      'onlineEnd': onlineEnd,
      'inPersonStart': inPersonStart,
      'inPersonEnd': inPersonEnd,
    };
  }
}

class PastorAvailability {
  final String id;
  final DocumentReference userId;
  final DaySchedule monday;
  final DaySchedule tuesday;
  final DaySchedule wednesday;
  final DaySchedule thursday;
  final DaySchedule friday;
  final DaySchedule saturday;
  final DaySchedule sunday;
  final List<DateTime> unavailableDates;
  final String location;
  final bool isAcceptingOnline;
  final bool isAcceptingInPerson;
  final int sessionDuration;
  final DateTime updatedAt;

  PastorAvailability({
    required this.id,
    required this.userId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.unavailableDates,
    required this.location,
    required this.isAcceptingOnline,
    required this.isAcceptingInPerson,
    required this.sessionDuration,
    required this.updatedAt,
  });

  factory PastorAvailability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PastorAvailability(
      id: doc.id,
      userId: data['userId'],
      monday: DaySchedule.fromMap(data['monday'] ?? {}),
      tuesday: DaySchedule.fromMap(data['tuesday'] ?? {}),
      wednesday: DaySchedule.fromMap(data['wednesday'] ?? {}),
      thursday: DaySchedule.fromMap(data['thursday'] ?? {}),
      friday: DaySchedule.fromMap(data['friday'] ?? {}),
      saturday: DaySchedule.fromMap(data['saturday'] ?? {}),
      sunday: DaySchedule.fromMap(data['sunday'] ?? {}),
      unavailableDates: (data['unavailableDates'] as List?)
          ?.map((date) => (date as Timestamp).toDate())
          .toList() ?? [],
      location: data['location'] ?? '',
      isAcceptingOnline: data['isAcceptingOnline'] ?? false,
      isAcceptingInPerson: data['isAcceptingInPerson'] ?? false,
      sessionDuration: data['sessionDuration'] ?? 60,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'monday': monday.toMap(),
      'tuesday': tuesday.toMap(),
      'wednesday': wednesday.toMap(),
      'thursday': thursday.toMap(),
      'friday': friday.toMap(),
      'saturday': saturday.toMap(),
      'sunday': sunday.toMap(),
      'unavailableDates': unavailableDates.map((date) => Timestamp.fromDate(date)).toList(),
      'location': location,
      'isAcceptingOnline': isAcceptingOnline,
      'isAcceptingInPerson': isAcceptingInPerson,
      'sessionDuration': sessionDuration,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 