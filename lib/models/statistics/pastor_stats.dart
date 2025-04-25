import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar estadísticas de un pastor individual
class PastorStats {
  final String pastorId;
  final String? pastorName;
  final String? pastorPhotoUrl;
  
  // Propiedades adicionales utilizadas en el servicio
  final String? name; // Alias de pastorName
  final String? email;
  final String? phone;
  
  // Getter para compatibilidad
  String? get photoUrl => pastorPhotoUrl;
  
  // Estadísticas de eventos
  final int totalEventsOrganized;
  final int eventsOrganizedLastMonth;
  final double averageEventAttendance;
  final double eventAttendanceRate;
  
  // Estadísticas de consejería
  final int totalCounselingRequests;
  final int counselingRequestsAttended;
  final int pendingCounselingRequests;
  final Duration averageCounselingResponseTime;
  
  // Alias utilizados en el servicio
  final int totalCounselingAppointments; // Alias de totalCounselingRequests
  final int completedCounselingAppointments; // Alias de counselingRequestsAttended
  final int pendingCounselingAppointments; // Alias de pendingCounselingRequests
  final Duration averageResponseTime; // Alias de averageCounselingResponseTime
  
  // Estadísticas de oraciones privadas
  final int totalPrivatePrayers;
  final int privatePrayersAnswered;
  final int pendingPrivatePrayers;
  final Duration averagePrayerResponseTime;
  
  // Alias utilizados en el servicio
  final int answeredPrayers; // Alias de privatePrayersAnswered
  final int pendingPrayers; // Alias de pendingPrivatePrayers
  
  // Estadísticas de sermones
  final int totalSermons;
  final Map<String, int> topicsPreached;
  
  // Disponibilidad y carga de trabajo
  final double availableHours;
  final Map<String, double> availabilityByDay;
  final double currentWorkload;
  final Map<String, double> workloadByType;
  final List<String> busyDays;
  
  // Actividad reciente
  final List<Map<String, dynamic>> recentActivity;
  
  // Estadísticas de miembros
  final int totalMembersManaged;
  final List<Map<String, dynamic>> ministryMembersManaged;
  final List<Map<String, dynamic>> groupMembersManaged;
  
  // Estadísticas de trabajo
  final int totalWorkInvitationsSent;
  final int workInvitationsAccepted;
  final int workInvitationsRejected;
  final int workInvitationsPending;
  final double workInvitationAcceptanceRate;
  
  // Actividad de ministerios y grupos
  final int totalMinistriesLed;
  final int totalGroupsLed;
  final int totalMemberAdded;
  final int totalMemberRemoved;
  
  PastorStats({
    required this.pastorId,
    this.pastorName,
    this.pastorPhotoUrl,
    this.name, // Alias
    this.email,
    this.phone,
    required this.totalEventsOrganized,
    required this.eventsOrganizedLastMonth,
    required this.averageEventAttendance,
    required this.eventAttendanceRate,
    required this.totalCounselingRequests,
    required this.counselingRequestsAttended,
    required this.pendingCounselingRequests,
    required this.averageCounselingResponseTime,
    this.totalCounselingAppointments = 0, // Alias
    this.completedCounselingAppointments = 0, // Alias
    this.pendingCounselingAppointments = 0, // Alias
    this.averageResponseTime = const Duration(), // Alias
    required this.totalPrivatePrayers,
    required this.privatePrayersAnswered,
    required this.pendingPrivatePrayers,
    required this.averagePrayerResponseTime,
    this.answeredPrayers = 0, // Alias
    this.pendingPrayers = 0, // Alias
    this.totalSermons = 0,
    this.topicsPreached = const {},
    this.availableHours = 0.0,
    this.availabilityByDay = const {},
    this.currentWorkload = 0.0,
    this.workloadByType = const {},
    this.busyDays = const [],
    this.recentActivity = const [],
    required this.totalMembersManaged,
    required this.ministryMembersManaged,
    required this.groupMembersManaged,
    required this.totalWorkInvitationsSent,
    required this.workInvitationsAccepted,
    required this.workInvitationsRejected,
    required this.workInvitationsPending,
    required this.workInvitationAcceptanceRate,
    required this.totalMinistriesLed,
    required this.totalGroupsLed,
    required this.totalMemberAdded,
    required this.totalMemberRemoved,
  });
  
  factory PastorStats.fromMap(Map<String, dynamic> map) {
    return PastorStats(
      pastorId: map['pastorId'] ?? '',
      pastorName: map['pastorName'] ?? map['name'],
      pastorPhotoUrl: map['pastorPhotoUrl'] ?? map['photoUrl'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      totalEventsOrganized: map['totalEventsOrganized'] ?? 0,
      eventsOrganizedLastMonth: map['eventsOrganizedLastMonth'] ?? 0,
      averageEventAttendance: map['averageEventAttendance']?.toDouble() ?? 0.0,
      eventAttendanceRate: map['eventAttendanceRate']?.toDouble() ?? 0.0,
      totalCounselingRequests: map['totalCounselingRequests'] ?? map['totalCounselingAppointments'] ?? 0,
      counselingRequestsAttended: map['counselingRequestsAttended'] ?? map['completedCounselingAppointments'] ?? 0,
      pendingCounselingRequests: map['pendingCounselingRequests'] ?? map['pendingCounselingAppointments'] ?? 0,
      averageCounselingResponseTime: Duration(minutes: map['averageCounselingResponseTimeMinutes'] ?? map['averageResponseTimeMinutes'] ?? 0),
      totalCounselingAppointments: map['totalCounselingAppointments'] ?? map['totalCounselingRequests'] ?? 0,
      completedCounselingAppointments: map['completedCounselingAppointments'] ?? map['counselingRequestsAttended'] ?? 0,
      pendingCounselingAppointments: map['pendingCounselingAppointments'] ?? map['pendingCounselingRequests'] ?? 0,
      averageResponseTime: Duration(minutes: map['averageResponseTimeMinutes'] ?? map['averageCounselingResponseTimeMinutes'] ?? 0),
      totalPrivatePrayers: map['totalPrivatePrayers'] ?? 0,
      privatePrayersAnswered: map['privatePrayersAnswered'] ?? map['answeredPrayers'] ?? 0,
      pendingPrivatePrayers: map['pendingPrivatePrayers'] ?? map['pendingPrayers'] ?? 0,
      averagePrayerResponseTime: Duration(minutes: map['averagePrayerResponseTimeMinutes'] ?? 0),
      answeredPrayers: map['answeredPrayers'] ?? map['privatePrayersAnswered'] ?? 0,
      pendingPrayers: map['pendingPrayers'] ?? map['pendingPrivatePrayers'] ?? 0,
      totalSermons: map['totalSermons'] ?? 0,
      topicsPreached: Map<String, int>.from(map['topicsPreached'] ?? {}),
      availableHours: map['availableHours']?.toDouble() ?? 0.0,
      availabilityByDay: Map<String, double>.from(map['availabilityByDay'] ?? {}),
      currentWorkload: map['currentWorkload']?.toDouble() ?? 0.0,
      workloadByType: Map<String, double>.from(map['workloadByType'] ?? {}),
      busyDays: List<String>.from(map['busyDays'] ?? []),
      recentActivity: List<Map<String, dynamic>>.from(map['recentActivity'] ?? []),
      totalMembersManaged: map['totalMembersManaged'] ?? 0,
      ministryMembersManaged: List<Map<String, dynamic>>.from(map['ministryMembersManaged'] ?? []),
      groupMembersManaged: List<Map<String, dynamic>>.from(map['groupMembersManaged'] ?? []),
      totalWorkInvitationsSent: map['totalWorkInvitationsSent'] ?? 0,
      workInvitationsAccepted: map['workInvitationsAccepted'] ?? 0,
      workInvitationsRejected: map['workInvitationsRejected'] ?? 0,
      workInvitationsPending: map['workInvitationsPending'] ?? 0,
      workInvitationAcceptanceRate: map['workInvitationAcceptanceRate']?.toDouble() ?? 0.0,
      totalMinistriesLed: map['totalMinistriesLed'] ?? 0,
      totalGroupsLed: map['totalGroupsLed'] ?? 0,
      totalMemberAdded: map['totalMemberAdded'] ?? 0,
      totalMemberRemoved: map['totalMemberRemoved'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'pastorId': pastorId,
      'pastorName': pastorName ?? name,
      'pastorPhotoUrl': pastorPhotoUrl,
      'name': name ?? pastorName,
      'email': email,
      'phone': phone,
      'totalEventsOrganized': totalEventsOrganized,
      'eventsOrganizedLastMonth': eventsOrganizedLastMonth,
      'averageEventAttendance': averageEventAttendance,
      'eventAttendanceRate': eventAttendanceRate,
      'totalCounselingRequests': totalCounselingRequests,
      'counselingRequestsAttended': counselingRequestsAttended,
      'pendingCounselingRequests': pendingCounselingRequests,
      'averageCounselingResponseTimeMinutes': averageCounselingResponseTime.inMinutes,
      'totalCounselingAppointments': totalCounselingAppointments,
      'completedCounselingAppointments': completedCounselingAppointments,
      'pendingCounselingAppointments': pendingCounselingAppointments,
      'averageResponseTimeMinutes': averageResponseTime.inMinutes,
      'totalPrivatePrayers': totalPrivatePrayers,
      'privatePrayersAnswered': privatePrayersAnswered,
      'pendingPrivatePrayers': pendingPrivatePrayers,
      'averagePrayerResponseTimeMinutes': averagePrayerResponseTime.inMinutes,
      'answeredPrayers': answeredPrayers,
      'pendingPrayers': pendingPrayers,
      'totalSermons': totalSermons,
      'topicsPreached': topicsPreached,
      'availableHours': availableHours,
      'availabilityByDay': availabilityByDay,
      'currentWorkload': currentWorkload,
      'workloadByType': workloadByType,
      'busyDays': busyDays,
      'recentActivity': recentActivity,
      'totalMembersManaged': totalMembersManaged,
      'ministryMembersManaged': ministryMembersManaged,
      'groupMembersManaged': groupMembersManaged,
      'totalWorkInvitationsSent': totalWorkInvitationsSent,
      'workInvitationsAccepted': workInvitationsAccepted,
      'workInvitationsRejected': workInvitationsRejected,
      'workInvitationsPending': workInvitationsPending,
      'workInvitationAcceptanceRate': workInvitationAcceptanceRate,
      'totalMinistriesLed': totalMinistriesLed,
      'totalGroupsLed': totalGroupsLed,
      'totalMemberAdded': totalMemberAdded,
      'totalMemberRemoved': totalMemberRemoved,
    };
  }
  
  // Comparar por tasa de aceptación de trabajo (mayor a menor)
  static int compareByWorkAcceptanceRate(PastorStats a, PastorStats b) {
    return b.workInvitationAcceptanceRate.compareTo(a.workInvitationAcceptanceRate);
  }
  
  // Comparar por tasa de asistencia a eventos (mayor a menor)
  static int compareByEventAttendanceRate(PastorStats a, PastorStats b) {
    return b.eventAttendanceRate.compareTo(a.eventAttendanceRate);
  }
  
  // Comparar por tiempo de respuesta (menor a mayor)
  static int compareByResponseTime(PastorStats a, PastorStats b) {
    return a.averageCounselingResponseTime.compareTo(b.averageCounselingResponseTime);
  }
}

/// Modelo para almacenar un resumen de estadísticas de varios pastores
class PastorStatsSummary {
  final List<PastorStats> pastorsStats;
  final int totalPastors;
  final int totalCounselingRequests;
  final int totalPrivatePrayers;
  final Duration overallAverageCounselingResponseTime;
  final Duration overallAveragePrayerResponseTime;
  final double overallWorkInvitationAcceptanceRate;
  
  // Top pastores por diferentes métricas
  final List<PastorStats> mostEffectivePastors;
  final List<PastorStats> mostResponsivePastors;
  
  PastorStatsSummary({
    required this.pastorsStats,
    required this.totalPastors,
    required this.totalCounselingRequests,
    required this.totalPrivatePrayers,
    required this.overallAverageCounselingResponseTime,
    required this.overallAveragePrayerResponseTime,
    required this.overallWorkInvitationAcceptanceRate,
    required this.mostEffectivePastors,
    required this.mostResponsivePastors,
  });
  
  factory PastorStatsSummary.fromMap(Map<String, dynamic> map) {
    final List<dynamic> pastorsData = map['pastorsStats'] ?? [];
    final List<dynamic> mostEffectiveData = map['mostEffectivePastors'] ?? [];
    final List<dynamic> mostResponsiveData = map['mostResponsivePastors'] ?? [];
    
    return PastorStatsSummary(
      pastorsStats: pastorsData.map((data) => PastorStats.fromMap(data)).toList(),
      totalPastors: map['totalPastors'] ?? 0,
      totalCounselingRequests: map['totalCounselingRequests'] ?? 0,
      totalPrivatePrayers: map['totalPrivatePrayers'] ?? 0,
      overallAverageCounselingResponseTime: Duration(minutes: map['overallAverageCounselingResponseTimeMinutes'] ?? 0),
      overallAveragePrayerResponseTime: Duration(minutes: map['overallAveragePrayerResponseTimeMinutes'] ?? 0),
      overallWorkInvitationAcceptanceRate: map['overallWorkInvitationAcceptanceRate']?.toDouble() ?? 0.0,
      mostEffectivePastors: mostEffectiveData.map((data) => PastorStats.fromMap(data)).toList(),
      mostResponsivePastors: mostResponsiveData.map((data) => PastorStats.fromMap(data)).toList(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'pastorsStats': pastorsStats.map((stats) => stats.toMap()).toList(),
      'totalPastors': totalPastors,
      'totalCounselingRequests': totalCounselingRequests,
      'totalPrivatePrayers': totalPrivatePrayers,
      'overallAverageCounselingResponseTimeMinutes': overallAverageCounselingResponseTime.inMinutes,
      'overallAveragePrayerResponseTimeMinutes': overallAveragePrayerResponseTime.inMinutes,
      'overallWorkInvitationAcceptanceRate': overallWorkInvitationAcceptanceRate,
      'mostEffectivePastors': mostEffectivePastors.map((stats) => stats.toMap()).toList(),
      'mostResponsivePastors': mostResponsivePastors.map((stats) => stats.toMap()).toList(),
    };
  }
}

/// Modelo para estadísticas resumidas de actividad pastoral - utilizado en pastor_activity_screen.dart
class PastoralStatsSummary extends PastorStatsSummary {
  final int totalActivePastors;
  final Duration averageResponseTime;
  final int totalVisits;
  final double visitCompletionRate;
  final List<Map<String, dynamic>> mostActivePastors;
  final Map<String, int> activityByCategory;
  final List<Map<String, dynamic>> responseTimeTrends;
  final List<Map<String, dynamic>> pastorDetails;
  final List<Map<String, dynamic>> recentCounselingActivities;

  PastoralStatsSummary({
    required this.totalActivePastors,
    required this.averageResponseTime,
    required int totalCounselingRequests,
    required this.totalVisits,
    required this.visitCompletionRate,
    required this.mostActivePastors,
    required this.activityByCategory,
    required this.responseTimeTrends,
    required this.pastorDetails,
    this.recentCounselingActivities = const [],
    required int totalPastors,
    required int totalPrivatePrayers,
    required Duration overallAverageCounselingResponseTime,
    required Duration overallAveragePrayerResponseTime,
    required double overallWorkInvitationAcceptanceRate,
    required List<PastorStats> pastorStatsList,
    required List<PastorStats> mostEffectivePastors,
    required List<PastorStats> mostResponsivePastors,
  }) : super(
    pastorsStats: pastorStatsList,
    totalPastors: totalPastors,
    totalCounselingRequests: totalCounselingRequests,
    totalPrivatePrayers: totalPrivatePrayers,
    overallAverageCounselingResponseTime: overallAverageCounselingResponseTime,
    overallAveragePrayerResponseTime: overallAveragePrayerResponseTime,
    overallWorkInvitationAcceptanceRate: overallWorkInvitationAcceptanceRate,
    mostEffectivePastors: mostEffectivePastors,
    mostResponsivePastors: mostResponsivePastors,
  );

  factory PastoralStatsSummary.fromMap(Map<String, dynamic> map) {
    final List<dynamic> pastorsStatsData = map['pastorsStats'] ?? [];
    final List<dynamic> mostEffectiveData = map['mostEffectivePastors'] ?? [];
    final List<dynamic> mostResponsiveData = map['mostResponsivePastors'] ?? [];
    final List<dynamic> mostActiveData = map['mostActivePastors'] ?? [];
    
    return PastoralStatsSummary(
      pastorStatsList: pastorsStatsData.map((data) => PastorStats.fromMap(data)).toList(),
      totalPastors: map['totalPastors'] ?? 0,
      totalActivePastors: map['totalActivePastors'] ?? 0,
      totalCounselingRequests: map['totalCounselingRequests'] ?? 0,
      totalPrivatePrayers: map['totalPrivatePrayers'] ?? 0,
      totalVisits: map['totalVisits'] ?? 0,
      visitCompletionRate: map['visitCompletionRate']?.toDouble() ?? 0.0,
      overallAverageCounselingResponseTime: Duration(minutes: map['overallAverageCounselingResponseTimeMinutes'] ?? 0),
      overallAveragePrayerResponseTime: Duration(minutes: map['overallAveragePrayerResponseTimeMinutes'] ?? 0),
      averageResponseTime: Duration(minutes: map['averageResponseTimeMinutes'] ?? 0),
      overallWorkInvitationAcceptanceRate: map['overallWorkInvitationAcceptanceRate']?.toDouble() ?? 0.0,
      mostEffectivePastors: mostEffectiveData.map((data) => PastorStats.fromMap(data)).toList(),
      mostResponsivePastors: mostResponsiveData.map((data) => PastorStats.fromMap(data)).toList(),
      mostActivePastors: List<Map<String, dynamic>>.from(mostActiveData),
      activityByCategory: Map<String, int>.from(map['activityByCategory'] ?? {}),
      responseTimeTrends: List<Map<String, dynamic>>.from(map['responseTimeTrends'] ?? []),
      pastorDetails: List<Map<String, dynamic>>.from(pastorsStatsData),
      recentCounselingActivities: List<Map<String, dynamic>>.from(map['recentCounselingActivities'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'totalActivePastors': totalActivePastors,
      'averageResponseTimeMinutes': averageResponseTime.inMinutes,
      'totalVisits': totalVisits,
      'visitCompletionRate': visitCompletionRate,
      'mostActivePastors': mostActivePastors,
      'activityByCategory': activityByCategory,
      'responseTimeTrends': responseTimeTrends,
      'pastorDetails': pastorDetails,
      'recentCounselingActivities': recentCounselingActivities,
    };
  }
} 