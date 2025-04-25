import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar estadísticas detalladas de un evento específico
class EventStats {
  final String eventId;
  final String eventName;
  final String? eventDescription;
  final String? eventPhotoUrl;
  final DateTime? eventDate;
  final String? eventLocation;
  final String eventType; // 'ministry', 'group', 'church', etc.
  
  // Entidad relacionada (ministerio, grupo, etc.)
  final String? relatedEntityId;
  final String? relatedEntityName;
  final String? relatedEntityType;
  
  // Estadísticas de invitaciones y asistencia
  final int totalInvited;
  final int confirmedAttendance;
  final int actualAttendance;
  final int rejectedInvitations;
  final int pendingResponses;
  final double confirmationRate;
  final double attendanceRate;
  
  // Detalle de asistentes
  final List<Map<String, dynamic>> topAttendeesByEngagement;
  final Map<String, int> attendanceByRole;
  final Map<String, int> attendanceByAgeGroup;
  
  // Historial de eventos relacionados
  final List<Map<String, dynamic>> relatedEvents;
  
  EventStats({
    required this.eventId,
    required this.eventName,
    this.eventDescription,
    this.eventPhotoUrl,
    this.eventDate,
    this.eventLocation,
    required this.eventType,
    this.relatedEntityId,
    this.relatedEntityName,
    this.relatedEntityType,
    required this.totalInvited,
    required this.confirmedAttendance,
    required this.actualAttendance,
    required this.rejectedInvitations,
    required this.pendingResponses,
    required this.confirmationRate,
    required this.attendanceRate,
    required this.topAttendeesByEngagement,
    required this.attendanceByRole,
    required this.attendanceByAgeGroup,
    required this.relatedEvents,
  });
  
  // Constructor desde mapa para permitir serialización
  factory EventStats.fromMap(Map<String, dynamic> map) {
    return EventStats(
      eventId: map['eventId'] ?? '',
      eventName: map['eventName'] ?? 'Evento sin nombre',
      eventDescription: map['eventDescription'],
      eventPhotoUrl: map['eventPhotoUrl'],
      eventDate: map['eventDate'] != null 
          ? (map['eventDate'] is Timestamp 
              ? (map['eventDate'] as Timestamp).toDate() 
              : DateTime.parse(map['eventDate']))
          : null,
      eventLocation: map['eventLocation'],
      eventType: map['eventType'] ?? 'general',
      relatedEntityId: map['relatedEntityId'],
      relatedEntityName: map['relatedEntityName'],
      relatedEntityType: map['relatedEntityType'],
      totalInvited: map['totalInvited'] ?? 0,
      confirmedAttendance: map['confirmedAttendance'] ?? 0,
      actualAttendance: map['actualAttendance'] ?? 0,
      rejectedInvitations: map['rejectedInvitations'] ?? 0,
      pendingResponses: map['pendingResponses'] ?? 0,
      confirmationRate: map['confirmationRate']?.toDouble() ?? 0.0,
      attendanceRate: map['attendanceRate']?.toDouble() ?? 0.0,
      topAttendeesByEngagement: List<Map<String, dynamic>>.from(map['topAttendeesByEngagement'] ?? []),
      attendanceByRole: Map<String, int>.from(map['attendanceByRole'] ?? {}),
      attendanceByAgeGroup: Map<String, int>.from(map['attendanceByAgeGroup'] ?? {}),
      relatedEvents: List<Map<String, dynamic>>.from(map['relatedEvents'] ?? []),
    );
  }
  
  // Convertir a mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'eventDescription': eventDescription,
      'eventPhotoUrl': eventPhotoUrl,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'eventLocation': eventLocation,
      'eventType': eventType,
      'relatedEntityId': relatedEntityId,
      'relatedEntityName': relatedEntityName,
      'relatedEntityType': relatedEntityType,
      'totalInvited': totalInvited,
      'confirmedAttendance': confirmedAttendance,
      'actualAttendance': actualAttendance,
      'rejectedInvitations': rejectedInvitations,
      'pendingResponses': pendingResponses,
      'confirmationRate': confirmationRate,
      'attendanceRate': attendanceRate,
      'topAttendeesByEngagement': topAttendeesByEngagement,
      'attendanceByRole': attendanceByRole,
      'attendanceByAgeGroup': attendanceByAgeGroup,
      'relatedEvents': relatedEvents,
    };
  }
  
  // Comparar por tasa de asistencia (mayor a menor)
  static int compareByAttendanceRate(EventStats a, EventStats b) {
    return b.attendanceRate.compareTo(a.attendanceRate);
  }
  
  // Comparar por tasa de confirmación (mayor a menor)
  static int compareByConfirmationRate(EventStats a, EventStats b) {
    return b.confirmationRate.compareTo(a.confirmationRate);
  }
  
  // Comparar por fecha (más reciente a más antiguo)
  static int compareByDate(EventStats a, EventStats b) {
    if (a.eventDate == null && b.eventDate == null) return 0;
    if (a.eventDate == null) return 1;
    if (b.eventDate == null) return -1;
    return b.eventDate!.compareTo(a.eventDate!);
  }
}

/// Modelo para almacenar un resumen de estadísticas de varios eventos
class EventStatsSummary {
  final List<EventStats> eventsStats;
  final int totalEvents;
  final int eventsLastWeek;
  final int eventsLastMonth;
  final int upcomingEvents;
  final double overallAttendanceRate;
  final double overallConfirmationRate;
  final double averageAttendance;
  
  // Agrupación por tipo
  final Map<String, int> eventsByType;
  
  // Top eventos por diferentes métricas
  final List<Map<String, dynamic>> highestAttendanceEvents;
  final List<Map<String, dynamic>> mostRecentEvents;
  final List<Map<String, dynamic>> upcomingEventsList;
  
  // Tendencias de asistencia
  final List<Map<String, dynamic>> attendanceTrend;
  
  // Propiedades adicionales utilizadas en event_stats_screen.dart
  final List<Map<String, dynamic>> topAttendedEvents;
  final Map<String, int> eventSatisfaction;
  final List<Map<String, dynamic>> eventTrends;
  
  EventStatsSummary({
    required this.eventsStats,
    required this.totalEvents,
    required this.eventsLastWeek,
    required this.eventsLastMonth,
    required this.upcomingEvents,
    required this.overallAttendanceRate,
    required this.overallConfirmationRate,
    required this.eventsByType,
    required this.highestAttendanceEvents,
    required this.mostRecentEvents,
    required this.upcomingEventsList,
    required this.attendanceTrend,
    this.averageAttendance = 0.0,
    this.topAttendedEvents = const [],
    this.eventSatisfaction = const {},
    this.eventTrends = const [],
  });
  
  // Constructor desde mapa para permitir serialización
  factory EventStatsSummary.fromMap(Map<String, dynamic> map) {
    return EventStatsSummary(
      eventsStats: (map['eventsStats'] as List<dynamic>?)
          ?.map((e) => EventStats.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      totalEvents: map['totalEvents'] ?? 0,
      eventsLastWeek: map['eventsLastWeek'] ?? 0,
      eventsLastMonth: map['eventsLastMonth'] ?? 0,
      upcomingEvents: map['upcomingEvents'] ?? 0,
      overallAttendanceRate: map['overallAttendanceRate']?.toDouble() ?? 0.0,
      overallConfirmationRate: map['overallConfirmationRate']?.toDouble() ?? 0.0,
      eventsByType: Map<String, int>.from(map['eventsByType'] ?? {}),
      highestAttendanceEvents: List<Map<String, dynamic>>.from(map['highestAttendanceEvents'] ?? []),
      mostRecentEvents: List<Map<String, dynamic>>.from(map['mostRecentEvents'] ?? []),
      upcomingEventsList: List<Map<String, dynamic>>.from(map['upcomingEventsList'] ?? []),
      attendanceTrend: List<Map<String, dynamic>>.from(map['attendanceTrend'] ?? []),
      averageAttendance: map['averageAttendance']?.toDouble() ?? 0.0,
      topAttendedEvents: List<Map<String, dynamic>>.from(map['topAttendedEvents'] ?? []), 
      eventSatisfaction: Map<String, int>.from(map['eventSatisfaction'] ?? {}),
      eventTrends: List<Map<String, dynamic>>.from(map['eventTrends'] ?? []),
    );
  }
  
  // Convertir a mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'eventsStats': eventsStats.map((e) => e.toMap()).toList(),
      'totalEvents': totalEvents,
      'eventsLastWeek': eventsLastWeek,
      'eventsLastMonth': eventsLastMonth,
      'upcomingEvents': upcomingEvents,
      'overallAttendanceRate': overallAttendanceRate,
      'overallConfirmationRate': overallConfirmationRate,
      'eventsByType': eventsByType,
      'highestAttendanceEvents': highestAttendanceEvents,
      'mostRecentEvents': mostRecentEvents,
      'upcomingEventsList': upcomingEventsList,
      'attendanceTrend': attendanceTrend,
      'averageAttendance': averageAttendance,
      'topAttendedEvents': topAttendedEvents,
      'eventSatisfaction': eventSatisfaction,
      'eventTrends': eventTrends,
    };
  }
} 