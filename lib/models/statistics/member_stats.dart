import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar estadísticas de compromiso detalladas de un miembro
class MemberStats {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  final String memberId;
  final String name;
  final String role;
  final String? phone;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? joinDate;
  final int totalEventsAttended;
  final int totalCultsAttended;
  final int totalPrayers;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> ministries;
  final List<Map<String, dynamic>> attendanceHistory;
  final List<Map<String, dynamic>> recentActivity;
  final int consecutiveAbsences;
  
  // Estadísticas de participación
  final int totalEventsInvited;
  final int eventsAttended;
  final int eventsConfirmed;
  final int eventsConfirmedButNotAttended;
  final double attendanceRate;
  final double confirmationRate;
  
  // Estadísticas de trabajo
  final int totalWorkAssignments;
  final int acceptedWorkAssignments;
  final int rejectedWorkAssignments;
  final int pendingWorkAssignments;
  final double workAcceptanceRate;
  
  // Estadísticas de actividad general
  final DateTime? lastActive;
  final DateTime? lastEventAttended;
  final DateTime? lastWorkCompleted;
  final int consecutiveEventsMissed;
  final int consecutiveRejections;
  
  // Puntaje de compromiso (0-100)
  final double engagementScore;
  final bool isAtRisk;
  
  MemberStats({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.email,
    required this.memberId,
    required this.name,
    required this.role,
    this.phone,
    required this.isActive,
    this.lastLogin,
    this.joinDate,
    required this.totalEventsAttended,
    required this.totalCultsAttended,
    required this.totalPrayers,
    required this.groups,
    required this.ministries,
    required this.attendanceHistory,
    required this.recentActivity,
    required this.consecutiveAbsences,
    required this.totalEventsInvited,
    required this.eventsAttended,
    required this.eventsConfirmed,
    required this.eventsConfirmedButNotAttended,
    required this.attendanceRate,
    required this.confirmationRate,
    required this.totalWorkAssignments,
    required this.acceptedWorkAssignments,
    required this.rejectedWorkAssignments,
    required this.pendingWorkAssignments,
    required this.workAcceptanceRate,
    this.lastActive,
    this.lastEventAttended,
    this.lastWorkCompleted,
    required this.consecutiveEventsMissed,
    required this.consecutiveRejections,
    required this.engagementScore,
    required this.isAtRisk,
  });
  
  factory MemberStats.fromMap(Map<String, dynamic> map) {
    return MemberStats(
      userId: map['userId'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      email: map['email'],
      memberId: map['memberId'] ?? map['userId'] ?? '',
      name: map['name'] ?? map['displayName'] ?? 'Miembro sin nombre',
      role: map['role'] ?? 'member',
      phone: map['phone'],
      isActive: map['isActive'] ?? false,
      lastLogin: map['lastLogin'] != null ? (map['lastLogin'] is DateTime ? map['lastLogin'] : (map['lastLogin'] as Timestamp).toDate()) : null,
      joinDate: map['joinDate'] != null ? (map['joinDate'] is DateTime ? map['joinDate'] : (map['joinDate'] as Timestamp).toDate()) : null,
      totalEventsAttended: map['totalEventsAttended'] ?? 0,
      totalCultsAttended: map['totalCultsAttended'] ?? 0,
      totalPrayers: map['totalPrayers'] ?? 0,
      groups: List<Map<String, dynamic>>.from(map['groups'] ?? []),
      ministries: List<Map<String, dynamic>>.from(map['ministries'] ?? []),
      attendanceHistory: List<Map<String, dynamic>>.from(map['attendanceHistory'] ?? []),
      recentActivity: List<Map<String, dynamic>>.from(map['recentActivity'] ?? []),
      consecutiveAbsences: map['consecutiveAbsences'] ?? 0,
      totalEventsInvited: map['totalEventsInvited'] ?? 0,
      eventsAttended: map['eventsAttended'] ?? 0,
      eventsConfirmed: map['eventsConfirmed'] ?? 0,
      eventsConfirmedButNotAttended: map['eventsConfirmedButNotAttended'] ?? 0,
      attendanceRate: map['attendanceRate']?.toDouble() ?? 0.0,
      confirmationRate: map['confirmationRate']?.toDouble() ?? 0.0,
      totalWorkAssignments: map['totalWorkAssignments'] ?? 0,
      acceptedWorkAssignments: map['acceptedWorkAssignments'] ?? 0,
      rejectedWorkAssignments: map['rejectedWorkAssignments'] ?? 0,
      pendingWorkAssignments: map['pendingWorkAssignments'] ?? 0,
      workAcceptanceRate: map['workAcceptanceRate']?.toDouble() ?? 0.0,
      lastActive: map['lastActive'] != null ? (map['lastActive'] is DateTime ? map['lastActive'] : (map['lastActive'] as Timestamp).toDate()) : null,
      lastEventAttended: map['lastEventAttended'] != null ? (map['lastEventAttended'] is DateTime ? map['lastEventAttended'] : (map['lastEventAttended'] as Timestamp).toDate()) : null,
      lastWorkCompleted: map['lastWorkCompleted'] != null ? (map['lastWorkCompleted'] is DateTime ? map['lastWorkCompleted'] : (map['lastWorkCompleted'] as Timestamp).toDate()) : null,
      consecutiveEventsMissed: map['consecutiveEventsMissed'] ?? 0,
      consecutiveRejections: map['consecutiveRejections'] ?? 0,
      engagementScore: map['engagementScore']?.toDouble() ?? 0.0,
      isAtRisk: map['isAtRisk'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'email': email,
      'memberId': memberId,
      'name': name,
      'role': role,
      'phone': phone,
      'isActive': isActive,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'joinDate': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'totalEventsAttended': totalEventsAttended,
      'totalCultsAttended': totalCultsAttended,
      'totalPrayers': totalPrayers,
      'groups': groups,
      'ministries': ministries,
      'attendanceHistory': attendanceHistory,
      'recentActivity': recentActivity,
      'consecutiveAbsences': consecutiveAbsences,
      'totalEventsInvited': totalEventsInvited,
      'eventsAttended': eventsAttended,
      'eventsConfirmed': eventsConfirmed,
      'eventsConfirmedButNotAttended': eventsConfirmedButNotAttended,
      'attendanceRate': attendanceRate,
      'confirmationRate': confirmationRate,
      'totalWorkAssignments': totalWorkAssignments,
      'acceptedWorkAssignments': acceptedWorkAssignments,
      'rejectedWorkAssignments': rejectedWorkAssignments,
      'pendingWorkAssignments': pendingWorkAssignments,
      'workAcceptanceRate': workAcceptanceRate,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'lastEventAttended': lastEventAttended != null ? Timestamp.fromDate(lastEventAttended!) : null,
      'lastWorkCompleted': lastWorkCompleted != null ? Timestamp.fromDate(lastWorkCompleted!) : null,
      'consecutiveEventsMissed': consecutiveEventsMissed,
      'consecutiveRejections': consecutiveRejections,
      'engagementScore': engagementScore,
      'isAtRisk': isAtRisk,
    };
  }
  
  // Ordenar por puntuación de compromiso (mayor a menor)
  static int compareByEngagementScore(MemberStats a, MemberStats b) {
    return b.engagementScore.compareTo(a.engagementScore);
  }
  
  // Ordenar por tasa de asistencia (mayor a menor)
  static int compareByAttendanceRate(MemberStats a, MemberStats b) {
    return b.attendanceRate.compareTo(a.attendanceRate);
  }
  
  // Ordenar por tasa de aceptación de trabajo (mayor a menor)
  static int compareByWorkAcceptanceRate(MemberStats a, MemberStats b) {
    return b.workAcceptanceRate.compareTo(a.workAcceptanceRate);
  }
}

/// Modelo para encapsular un resumen de estadísticas de varios miembros
class MemberStatsSummary {
  final List<MemberStats> membersStats;
  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final double activeRate;
  final Map<String, int> membersByRole;
  final Map<String, int> membersByAgeGroup;
  final Map<String, int> membersByGender;
  final double overallEngagementScore;
  final double overallAttendanceRate;
  final double overallWorkAcceptanceRate;
  final double overallParticipationRate;
  final double averageAttendanceRate;
  final List<Map<String, dynamic>> membersAtRisk;
  final List<Map<String, dynamic>> mostAttendingMembers;
  final List<Map<String, dynamic>> memberJoinTrend;
  final List<Map<String, dynamic>> attendanceTrends;
  final Map<String, dynamic> activityByCategory;
  
  // Top miembros por diferentes métricas
  final List<MemberStats> mostEngagedMembers;
  final List<Map<String, dynamic>> mostActiveMembers;
  final List<MemberStats> lowEngagementMembers;
  
  MemberStatsSummary({
    required this.membersStats,
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.activeRate,
    required this.membersByRole,
    required this.membersByAgeGroup,
    required this.membersByGender,
    required this.overallEngagementScore,
    required this.overallAttendanceRate,
    required this.overallWorkAcceptanceRate,
    required this.overallParticipationRate,
    required this.averageAttendanceRate,
    required this.membersAtRisk,
    required this.mostAttendingMembers,
    required this.memberJoinTrend,
    required this.attendanceTrends,
    required this.activityByCategory,
    required this.mostEngagedMembers,
    required this.mostActiveMembers, 
    required this.lowEngagementMembers,
  });
  
  factory MemberStatsSummary.fromMap(Map<String, dynamic> map) {
    final List<dynamic> membersData = map['membersStats'] ?? [];
    final List<dynamic> mostEngagedData = map['mostEngagedMembers'] ?? [];
    final List<dynamic> mostActiveData = map['mostActiveMembers'] ?? [];
    final List<dynamic> mostAttendingData = map['mostAttendingMembers'] ?? [];
    final List<dynamic> lowEngagementData = map['lowEngagementMembers'] ?? [];
    
    return MemberStatsSummary(
      membersStats: membersData.map((data) => MemberStats.fromMap(data)).toList(),
      totalMembers: map['totalMembers'] ?? 0,
      activeMembers: map['activeMembers'] ?? 0,
      inactiveMembers: map['inactiveMembers'] ?? 0,
      activeRate: map['activeRate']?.toDouble() ?? 0.0,
      membersByRole: Map<String, int>.from(map['membersByRole'] ?? {}),
      membersByAgeGroup: Map<String, int>.from(map['membersByAgeGroup'] ?? {}),
      membersByGender: Map<String, int>.from(map['membersByGender'] ?? {}),
      overallEngagementScore: map['overallEngagementScore']?.toDouble() ?? 0.0,
      overallAttendanceRate: map['overallAttendanceRate']?.toDouble() ?? 0.0,
      overallWorkAcceptanceRate: map['overallWorkAcceptanceRate']?.toDouble() ?? 0.0,
      overallParticipationRate: map['overallParticipationRate']?.toDouble() ?? 0.0,
      averageAttendanceRate: map['averageAttendanceRate']?.toDouble() ?? 0.0,
      membersAtRisk: List<Map<String, dynamic>>.from(map['membersAtRisk'] ?? []),
      mostAttendingMembers: List<Map<String, dynamic>>.from(mostAttendingData),
      memberJoinTrend: List<Map<String, dynamic>>.from(map['memberJoinTrend'] ?? []),
      attendanceTrends: List<Map<String, dynamic>>.from(map['attendanceTrends'] ?? []),
      activityByCategory: Map<String, dynamic>.from(map['activityByCategory'] ?? {}),
      mostEngagedMembers: mostEngagedData.map((data) => MemberStats.fromMap(data)).toList(),
      mostActiveMembers: List<Map<String, dynamic>>.from(mostActiveData),
      lowEngagementMembers: lowEngagementData.map((data) => MemberStats.fromMap(data)).toList(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'membersStats': membersStats.map((stats) => stats.toMap()).toList(),
      'totalMembers': totalMembers,
      'activeMembers': activeMembers,
      'inactiveMembers': inactiveMembers,
      'activeRate': activeRate,
      'membersByRole': membersByRole,
      'membersByAgeGroup': membersByAgeGroup,
      'membersByGender': membersByGender,
      'overallEngagementScore': overallEngagementScore,
      'overallAttendanceRate': overallAttendanceRate,
      'overallWorkAcceptanceRate': overallWorkAcceptanceRate,
      'overallParticipationRate': overallParticipationRate,
      'averageAttendanceRate': averageAttendanceRate,
      'membersAtRisk': membersAtRisk,
      'mostAttendingMembers': mostAttendingMembers,
      'memberJoinTrend': memberJoinTrend,
      'attendanceTrends': attendanceTrends,
      'activityByCategory': activityByCategory,
      'mostEngagedMembers': mostEngagedMembers.map((stats) => stats.toMap()).toList(),
      'mostActiveMembers': mostActiveMembers,
      'lowEngagementMembers': lowEngagementMembers.map((stats) => stats.toMap()).toList(),
    };
  }
} 