import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar las estadísticas generales mostradas en el dashboard
class DashboardStats {
  // Estadísticas de usuarios
  final int? totalUsers;
  final int? activeUsersLastWeek;
  final int? activeUsersLastMonth;
  final int? newUsersLastMonth;
  final Map<String, int> usersByRole;
  
  // Estadísticas de ministerios y grupos
  final int? totalMinistries;
  final int? totalGroups;
  final double averageMembersPerMinistry;
  final double averageMembersPerGroup;
  
  // Estadísticas de eventos
  final int? totalEvents;
  final int? eventsLastMonth;
  final double averageAttendanceRate;
  final double averageConfirmationRate;
  
  // Estadísticas de cultos
  final int? totalCults;
  final int? cultsLastMonth;
  final double averageCultAttendance;
  
  // Estadísticas de actividad pastoral
  final int? totalCounselingRequests;
  final int? totalPrivatePrayers;
  final Duration averageResponseTime;
  
  DashboardStats({
    required this.totalUsers,
    required this.activeUsersLastWeek,
    required this.activeUsersLastMonth,
    required this.newUsersLastMonth,
    required this.usersByRole,
    required this.totalMinistries,
    required this.totalGroups,
    required this.averageMembersPerMinistry,
    required this.averageMembersPerGroup,
    required this.totalEvents,
    required this.eventsLastMonth,
    required this.averageAttendanceRate,
    required this.averageConfirmationRate,
    required this.totalCults,
    required this.cultsLastMonth,
    required this.averageCultAttendance,
    required this.totalCounselingRequests,
    required this.totalPrivatePrayers,
    required this.averageResponseTime,
  });
  
  // Constructor desde mapa para permitir serialización
  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalUsers: map['totalUsers'] ?? 0,
      activeUsersLastWeek: map['activeUsersLastWeek'] ?? 0,
      activeUsersLastMonth: map['activeUsersLastMonth'] ?? 0,
      newUsersLastMonth: map['newUsersLastMonth'] ?? 0,
      usersByRole: Map<String, int>.from(map['usersByRole'] ?? {}),
      totalMinistries: map['totalMinistries'] ?? 0,
      totalGroups: map['totalGroups'] ?? 0,
      averageMembersPerMinistry: map['averageMembersPerMinistry']?.toDouble() ?? 0.0,
      averageMembersPerGroup: map['averageMembersPerGroup']?.toDouble() ?? 0.0,
      totalEvents: map['totalEvents'] ?? 0,
      eventsLastMonth: map['eventsLastMonth'] ?? 0,
      averageAttendanceRate: map['averageAttendanceRate']?.toDouble() ?? 0.0,
      averageConfirmationRate: map['averageConfirmationRate']?.toDouble() ?? 0.0,
      totalCults: map['totalCults'] ?? 0,
      cultsLastMonth: map['cultsLastMonth'] ?? 0,
      averageCultAttendance: map['averageCultAttendance']?.toDouble() ?? 0.0,
      totalCounselingRequests: map['totalCounselingRequests'] ?? 0,
      totalPrivatePrayers: map['totalPrivatePrayers'] ?? 0,
      averageResponseTime: Duration(minutes: map['averageResponseTimeMinutes'] ?? 0),
    );
  }
  
  // Convertir a mapa para serialización
  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'activeUsersLastWeek': activeUsersLastWeek,
      'activeUsersLastMonth': activeUsersLastMonth,
      'newUsersLastMonth': newUsersLastMonth,
      'usersByRole': usersByRole,
      'totalMinistries': totalMinistries,
      'totalGroups': totalGroups,
      'averageMembersPerMinistry': averageMembersPerMinistry,
      'averageMembersPerGroup': averageMembersPerGroup,
      'totalEvents': totalEvents,
      'eventsLastMonth': eventsLastMonth,
      'averageAttendanceRate': averageAttendanceRate,
      'averageConfirmationRate': averageConfirmationRate,
      'totalCults': totalCults,
      'cultsLastMonth': cultsLastMonth,
      'averageCultAttendance': averageCultAttendance,
      'totalCounselingRequests': totalCounselingRequests,
      'totalPrivatePrayers': totalPrivatePrayers,
      'averageResponseTimeMinutes': averageResponseTime.inMinutes,
    };
  }
} 