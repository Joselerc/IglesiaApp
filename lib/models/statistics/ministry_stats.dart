import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar estadísticas detalladas de un ministerio
class MinistryStats {
  final String ministryId;
  final String ministryName;
  final String? ministryDescription;
  final String? ministryPhotoUrl;
  
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
  
  // Estadísticas de trabajo
  final int totalWorkAssignments;
  final int pendingWorkAssignments;
  final int completedWorkAssignments;
  final double workAcceptanceRate;
  
  MinistryStats({
    required this.ministryId,
    required this.ministryName,
    this.ministryDescription,
    this.ministryPhotoUrl,
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
    required this.totalWorkAssignments,
    required this.pendingWorkAssignments,
    required this.completedWorkAssignments,
    required this.workAcceptanceRate,
  });
  
  factory MinistryStats.fromMap(Map<String, dynamic> map) {
    return MinistryStats(
      ministryId: map['ministryId'] ?? '',
      ministryName: map['ministryName'] ?? '',
      ministryDescription: map['ministryDescription'],
      ministryPhotoUrl: map['ministryPhotoUrl'],
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
      totalWorkAssignments: map['totalWorkAssignments'] ?? 0,
      pendingWorkAssignments: map['pendingWorkAssignments'] ?? 0,
      completedWorkAssignments: map['completedWorkAssignments'] ?? 0,
      workAcceptanceRate: map['workAcceptanceRate']?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'ministryId': ministryId,
      'ministryName': ministryName,
      'ministryDescription': ministryDescription,
      'ministryPhotoUrl': ministryPhotoUrl,
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
      'totalWorkAssignments': totalWorkAssignments,
      'pendingWorkAssignments': pendingWorkAssignments,
      'completedWorkAssignments': completedWorkAssignments,
      'workAcceptanceRate': workAcceptanceRate,
    };
  }
}

/// Modelo para almacenar estadísticas resumidas de múltiples ministerios
class MinistryStatsSummary {
  final List<MinistryStats> ministriesStats;
  final int totalMinistries;
  final double overallAttendanceRate;
  final double overallWorkAcceptanceRate;
  final int totalMinistryMembers;
  
  // Top ministerios por diferentes métricas
  final List<Map<String, dynamic>> largestMinistries;
  final List<Map<String, dynamic>> mostActiveMinistries;
  final List<Map<String, dynamic>> highestAttendanceMinistries;
  
  MinistryStatsSummary({
    required this.ministriesStats,
    required this.totalMinistries,
    required this.overallAttendanceRate,
    required this.overallWorkAcceptanceRate,
    required this.totalMinistryMembers,
    required this.largestMinistries,
    required this.mostActiveMinistries,
    required this.highestAttendanceMinistries,
  });
  
  factory MinistryStatsSummary.fromMap(Map<String, dynamic> map) {
    final List<dynamic> ministriesData = map['ministriesStats'] ?? [];
    
    return MinistryStatsSummary(
      ministriesStats: ministriesData.map((data) => MinistryStats.fromMap(data)).toList(),
      totalMinistries: map['totalMinistries'] ?? 0,
      overallAttendanceRate: map['overallAttendanceRate']?.toDouble() ?? 0.0,
      overallWorkAcceptanceRate: map['overallWorkAcceptanceRate']?.toDouble() ?? 0.0,
      totalMinistryMembers: map['totalMinistryMembers'] ?? 0,
      largestMinistries: List<Map<String, dynamic>>.from(map['largestMinistries'] ?? []),
      mostActiveMinistries: List<Map<String, dynamic>>.from(map['mostActiveMinistries'] ?? []),
      highestAttendanceMinistries: List<Map<String, dynamic>>.from(map['highestAttendanceMinistries'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'ministriesStats': ministriesStats.map((stats) => stats.toMap()).toList(),
      'totalMinistries': totalMinistries,
      'overallAttendanceRate': overallAttendanceRate,
      'overallWorkAcceptanceRate': overallWorkAcceptanceRate,
      'totalMinistryMembers': totalMinistryMembers,
      'largestMinistries': largestMinistries,
      'mostActiveMinistries': mostActiveMinistries,
      'highestAttendanceMinistries': highestAttendanceMinistries,
    };
  }
} 