import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar estadísticas detalladas de un grupo
class GroupStats {
  final String groupId;
  final String groupName;
  final String? groupDescription;
  final String? groupPhotoUrl;
  
  // Estadísticas de miembros
  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final List<Map<String, dynamic>> memberJoinHistory;
  final List<Map<String, dynamic>> memberLeaveHistory;
  
  // Estadísticas de eventos
  final int totalEvents;
  final int upcomingEvents;
  final int eventsLastMonth;
  final double attendanceRate;
  final double confirmationRate;
  final List<Map<String, dynamic>> topAttendedEvents;
  
  // Estadísticas de liderazgo
  final Map<String, dynamic> currentLeader;
  final List<Map<String, dynamic>> leadershipHistory;
  
  // Estadísticas de actividad
  final DateTime? lastEventDate;
  final int membersAtRisk;
  final double activityScore;
  
  GroupStats({
    required this.groupId,
    required this.groupName,
    this.groupDescription,
    this.groupPhotoUrl,
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.memberJoinHistory,
    required this.memberLeaveHistory,
    required this.totalEvents,
    required this.upcomingEvents,
    required this.eventsLastMonth,
    required this.attendanceRate,
    required this.confirmationRate,
    required this.topAttendedEvents,
    required this.currentLeader,
    required this.leadershipHistory,
    this.lastEventDate,
    required this.membersAtRisk,
    required this.activityScore,
  });
  
  // Constructor desde mapa para permitir serialización
  factory GroupStats.fromMap(Map<String, dynamic> map) {
    return GroupStats(
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? 'Grupo sin nombre',
      groupDescription: map['groupDescription'],
      groupPhotoUrl: map['groupPhotoUrl'],
      totalMembers: map['totalMembers'] ?? 0,
      activeMembers: map['activeMembers'] ?? 0,
      inactiveMembers: map['inactiveMembers'] ?? 0,
      memberJoinHistory: List<Map<String, dynamic>>.from(map['memberJoinHistory'] ?? []),
      memberLeaveHistory: List<Map<String, dynamic>>.from(map['memberLeaveHistory'] ?? []),
      totalEvents: map['totalEvents'] ?? 0,
      upcomingEvents: map['upcomingEvents'] ?? 0,
      eventsLastMonth: map['eventsLastMonth'] ?? 0,
      attendanceRate: map['attendanceRate']?.toDouble() ?? 0.0,
      confirmationRate: map['confirmationRate']?.toDouble() ?? 0.0,
      topAttendedEvents: List<Map<String, dynamic>>.from(map['topAttendedEvents'] ?? []),
      currentLeader: Map<String, dynamic>.from(map['currentLeader'] ?? {}),
      leadershipHistory: List<Map<String, dynamic>>.from(map['leadershipHistory'] ?? []),
      lastEventDate: map['lastEventDate'] != null 
          ? (map['lastEventDate'] is Timestamp 
              ? (map['lastEventDate'] as Timestamp).toDate() 
              : DateTime.parse(map['lastEventDate']))
          : null,
      membersAtRisk: map['membersAtRisk'] ?? 0,
      activityScore: map['activityScore']?.toDouble() ?? 0.0,
    );
  }
  
  // Convertir a mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupPhotoUrl': groupPhotoUrl,
      'totalMembers': totalMembers,
      'activeMembers': activeMembers,
      'inactiveMembers': inactiveMembers,
      'memberJoinHistory': memberJoinHistory,
      'memberLeaveHistory': memberLeaveHistory,
      'totalEvents': totalEvents,
      'upcomingEvents': upcomingEvents,
      'eventsLastMonth': eventsLastMonth,
      'attendanceRate': attendanceRate,
      'confirmationRate': confirmationRate,
      'topAttendedEvents': topAttendedEvents,
      'currentLeader': currentLeader,
      'leadershipHistory': leadershipHistory,
      'lastEventDate': lastEventDate != null ? Timestamp.fromDate(lastEventDate!) : null,
      'membersAtRisk': membersAtRisk,
      'activityScore': activityScore,
    };
  }
  
  // Comparar por cantidad de miembros (mayor a menor)
  static int compareByMemberCount(GroupStats a, GroupStats b) {
    return b.totalMembers.compareTo(a.totalMembers);
  }
  
  // Comparar por tasa de asistencia (mayor a menor)
  static int compareByAttendanceRate(GroupStats a, GroupStats b) {
    return b.attendanceRate.compareTo(a.attendanceRate);
  }
  
  // Comparar por puntaje de actividad (mayor a menor)
  static int compareByActivityScore(GroupStats a, GroupStats b) {
    return b.activityScore.compareTo(a.activityScore);
  }
}

/// Modelo para almacenar un resumen de estadísticas de varios grupos
class GroupStatsSummary {
  final List<GroupStats> groupsStats;
  final int totalGroups;
  final int totalGroupMembers;
  final double overallAttendanceRate;
  final double averageMembersPerGroup;
  
  // Variables adicionales usadas en la pantalla
  final int activeGroups;
  final double overallParticipationRate;
  final Map<String, int> groupsByAge;
  final List<Map<String, dynamic>> activityTrends;
  
  // Top grupos por diferentes métricas
  final List<Map<String, dynamic>> largestGroups;
  final List<Map<String, dynamic>> mostActiveGroups;
  final List<Map<String, dynamic>> highestAttendanceGroups;
  
  GroupStatsSummary({
    required this.groupsStats,
    required this.totalGroups,
    required this.totalGroupMembers,
    required this.overallAttendanceRate,
    required this.averageMembersPerGroup,
    required this.largestGroups,
    required this.mostActiveGroups,
    required this.highestAttendanceGroups,
    this.activeGroups = 0,
    this.overallParticipationRate = 0.0,
    this.groupsByAge = const {},
    this.activityTrends = const [],
  });
  
  // Constructor desde mapa para permitir serialización
  factory GroupStatsSummary.fromMap(Map<String, dynamic> map) {
    return GroupStatsSummary(
      groupsStats: (map['groupsStats'] as List<dynamic>?)
          ?.map((e) => GroupStats.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      totalGroups: map['totalGroups'] ?? 0,
      totalGroupMembers: map['totalGroupMembers'] ?? 0,
      overallAttendanceRate: map['overallAttendanceRate']?.toDouble() ?? 0.0,
      averageMembersPerGroup: map['averageMembersPerGroup']?.toDouble() ?? 0.0,
      largestGroups: List<Map<String, dynamic>>.from(map['largestGroups'] ?? []),
      mostActiveGroups: List<Map<String, dynamic>>.from(map['mostActiveGroups'] ?? []),
      highestAttendanceGroups: List<Map<String, dynamic>>.from(map['highestAttendanceGroups'] ?? []),
      activeGroups: map['activeGroups'] ?? 0,
      overallParticipationRate: map['overallParticipationRate']?.toDouble() ?? 0.0,
      groupsByAge: Map<String, int>.from(map['groupsByAge'] ?? {}),
      activityTrends: List<Map<String, dynamic>>.from(map['activityTrends'] ?? []),
    );
  }
  
  // Convertir a mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'groupsStats': groupsStats.map((e) => e.toMap()).toList(),
      'totalGroups': totalGroups,
      'totalGroupMembers': totalGroupMembers,
      'overallAttendanceRate': overallAttendanceRate,
      'averageMembersPerGroup': averageMembersPerGroup,
      'largestGroups': largestGroups,
      'mostActiveGroups': mostActiveGroups,
      'highestAttendanceGroups': highestAttendanceGroups,
      'activeGroups': activeGroups,
      'overallParticipationRate': overallParticipationRate,
      'groupsByAge': groupsByAge,
      'activityTrends': activityTrends,
    };
  }
} 