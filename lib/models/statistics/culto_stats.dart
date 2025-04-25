import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar estadísticas detalladas de un culto específico
class CultoStats {
  final String cultoId;
  final String cultoName;
  final DateTime? cultoDate;
  final String cultoType;
  
  // Estadísticas de invitaciones y asistencia
  final int totalInvitationsSent;
  final int invitationsAccepted;
  final int invitationsRejected;
  final int invitationsPending;
  final int confirmedAttendance;
  final int actualAttendance;
  final double confirmationRate;
  final double attendanceRate;
  
  // Estadísticas adicionales
  final int totalAttendance;
  final int expectedAttendance;
  final Map<String, int> attendanceByAge;
  final Map<String, int> attendanceByGender;
  final int firstTimeVisitors;
  final int returnVisitors;
  final List<Map<String, dynamic>> participants;
  final String? notes;
  final double growthRate;
  final int durationMinutes;
  
  // Participación por ministerios
  final List<Map<String, dynamic>> ministryParticipation;
  
  // Participación del pastor
  final String? pastorId;
  final String? pastorName;
  
  CultoStats({
    required this.cultoId,
    required this.cultoName,
    required this.cultoDate,
    required this.cultoType,
    this.totalInvitationsSent = 0,
    this.invitationsAccepted = 0,
    this.invitationsRejected = 0,
    this.invitationsPending = 0,
    this.confirmedAttendance = 0,
    this.actualAttendance = 0,
    this.confirmationRate = 0.0,
    this.attendanceRate = 0.0,
    this.ministryParticipation = const [],
    this.pastorId,
    this.pastorName,
    required this.totalAttendance,
    required this.expectedAttendance,
    required this.attendanceByAge,
    required this.attendanceByGender,
    required this.firstTimeVisitors,
    required this.returnVisitors,
    required this.participants,
    this.notes,
    required this.growthRate,
    required this.durationMinutes,
  });
  
  factory CultoStats.fromMap(Map<String, dynamic> map) {
    return CultoStats(
      cultoId: map['cultoId'] ?? '',
      cultoName: map['cultoName'] ?? '',
      cultoDate: map['cultoDate'] != null ? (map['cultoDate'] as Timestamp).toDate() : DateTime.now(),
      cultoType: map['cultoType'] ?? 'No especificado',
      totalInvitationsSent: map['totalInvitationsSent'] ?? 0,
      invitationsAccepted: map['invitationsAccepted'] ?? 0,
      invitationsRejected: map['invitationsRejected'] ?? 0,
      invitationsPending: map['invitationsPending'] ?? 0,
      confirmedAttendance: map['confirmedAttendance'] ?? 0,
      actualAttendance: map['actualAttendance'] ?? 0,
      confirmationRate: map['confirmationRate']?.toDouble() ?? 0.0,
      attendanceRate: map['attendanceRate']?.toDouble() ?? 0.0,
      ministryParticipation: List<Map<String, dynamic>>.from(map['ministryParticipation'] ?? []),
      pastorId: map['pastorId'],
      pastorName: map['pastorName'],
      totalAttendance: map['totalAttendance'] ?? 0,
      expectedAttendance: map['expectedAttendance'] ?? 0,
      attendanceByAge: Map<String, int>.from(map['attendanceByAge'] ?? {}),
      attendanceByGender: Map<String, int>.from(map['attendanceByGender'] ?? {}),
      firstTimeVisitors: map['firstTimeVisitors'] ?? 0,
      returnVisitors: map['returnVisitors'] ?? 0,
      participants: List<Map<String, dynamic>>.from(map['participants'] ?? []),
      notes: map['notes'],
      growthRate: map['growthRate']?.toDouble() ?? 0.0,
      durationMinutes: map['durationMinutes'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'cultoId': cultoId,
      'cultoName': cultoName,
      'cultoDate': cultoDate != null ? Timestamp.fromDate(cultoDate!) : null,
      'cultoType': cultoType,
      'totalInvitationsSent': totalInvitationsSent,
      'invitationsAccepted': invitationsAccepted,
      'invitationsRejected': invitationsRejected,
      'invitationsPending': invitationsPending,
      'confirmedAttendance': confirmedAttendance,
      'actualAttendance': actualAttendance,
      'confirmationRate': confirmationRate,
      'attendanceRate': attendanceRate,
      'ministryParticipation': ministryParticipation,
      'pastorId': pastorId,
      'pastorName': pastorName,
      'totalAttendance': totalAttendance,
      'expectedAttendance': expectedAttendance,
      'attendanceByAge': attendanceByAge,
      'attendanceByGender': attendanceByGender,
      'firstTimeVisitors': firstTimeVisitors,
      'returnVisitors': returnVisitors,
      'participants': participants,
      'notes': notes,
      'growthRate': growthRate,
      'durationMinutes': durationMinutes,
    };
  }
  
  // Comparar por tasa de asistencia (mayor a menor)
  static int compareByAttendanceRate(CultoStats a, CultoStats b) {
    return b.attendanceRate.compareTo(a.attendanceRate);
  }
  
  // Comparar por tasa de confirmación (mayor a menor)
  static int compareByConfirmationRate(CultoStats a, CultoStats b) {
    return b.confirmationRate.compareTo(a.confirmationRate);
  }
  
  // Comparar por fecha (más reciente a más antiguo)
  static int compareByDate(CultoStats a, CultoStats b) {
    if (a.cultoDate == null && b.cultoDate == null) return 0;
    if (a.cultoDate == null) return 1;
    if (b.cultoDate == null) return -1;
    return b.cultoDate!.compareTo(a.cultoDate!);
  }
  
  // Comparar por asistencia (mayor a menor)
  static int compareByAttendance(CultoStats a, CultoStats b) {
    return b.actualAttendance.compareTo(a.actualAttendance);
  }
}

/// Modelo para almacenar estadísticas resumidas de múltiples cultos
class CultoStatsSummary {
  final List<CultoStats> cultosStats;
  final int totalCultos;
  final int cultosLastMonth;
  final int totalAttendance;
  final double averageAttendance;
  final double overallAttendanceRate;
  final double overallConfirmationRate;
  final double confirmationRate;
  
  // Datos para gráficos y análisis
  final List<Map<String, dynamic>> attendanceTrends;
  final Map<String, dynamic> attendanceByDayOfWeek;
  final Map<String, dynamic> attendanceByType;
  final Map<String, double> averageAttendanceByType;
  final String mostPopularType;
  
  // Top cultos por diferentes métricas
  final List<Map<String, dynamic>> highestAttendanceCultos;
  final List<CultoStats> lowestAttendanceCultos;
  final List<Map<String, dynamic>> topAttendedCultos;
  
  // Estadísticas por pastor
  final List<Map<String, dynamic>> attendanceByPastor;
  
  CultoStatsSummary({
    required this.cultosStats,
    required this.totalCultos,
    this.cultosLastMonth = 0,
    required this.totalAttendance,
    required this.averageAttendance,
    this.overallAttendanceRate = 0.0,
    this.overallConfirmationRate = 0.0,
    this.confirmationRate = 0.0,
    required this.attendanceTrends,
    required this.attendanceByDayOfWeek,
    required this.attendanceByType,
    this.highestAttendanceCultos = const [],
    this.lowestAttendanceCultos = const [],
    this.attendanceByPastor = const [],
    required this.averageAttendanceByType,
    required this.mostPopularType,
    required this.topAttendedCultos,
  });
  
  factory CultoStatsSummary.fromMap(Map<String, dynamic> map) {
    final List<dynamic> cultosData = map['cultosStats'] ?? [];
    
    return CultoStatsSummary(
      cultosStats: cultosData.map((data) => CultoStats.fromMap(data)).toList(),
      totalCultos: map['totalCultos'] ?? 0,
      cultosLastMonth: map['cultosLastMonth'] ?? 0,
      totalAttendance: map['totalAttendance'] ?? 0,
      averageAttendance: map['averageAttendance']?.toDouble() ?? 0.0,
      overallAttendanceRate: map['overallAttendanceRate']?.toDouble() ?? 0.0,
      overallConfirmationRate: map['overallConfirmationRate']?.toDouble() ?? 0.0,
      confirmationRate: map['confirmationRate']?.toDouble() ?? 0.0,
      attendanceTrends: List<Map<String, dynamic>>.from(map['attendanceTrends'] ?? []),
      attendanceByDayOfWeek: Map<String, dynamic>.from(map['attendanceByDayOfWeek'] ?? {}),
      attendanceByType: Map<String, dynamic>.from(map['attendanceByType'] ?? {}),
      highestAttendanceCultos: List<Map<String, dynamic>>.from(map['highestAttendanceCultos'] ?? []),
      lowestAttendanceCultos: (map['lowestAttendanceCultos'] as List<dynamic>?)
          ?.map((data) => CultoStats.fromMap(data))
          .toList() ?? [],
      attendanceByPastor: List<Map<String, dynamic>>.from(map['attendanceByPastor'] ?? []),
      averageAttendanceByType: Map<String, double>.from(map['averageAttendanceByType'] ?? {}),
      mostPopularType: map['mostPopularType'] as String? ?? 'No hay datos',
      topAttendedCultos: List<Map<String, dynamic>>.from(map['topAttendedCultos'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'cultosStats': cultosStats.map((stats) => stats.toMap()).toList(),
      'totalCultos': totalCultos,
      'cultosLastMonth': cultosLastMonth,
      'totalAttendance': totalAttendance,
      'averageAttendance': averageAttendance,
      'overallAttendanceRate': overallAttendanceRate,
      'overallConfirmationRate': overallConfirmationRate,
      'confirmationRate': confirmationRate,
      'attendanceTrends': attendanceTrends,
      'attendanceByDayOfWeek': attendanceByDayOfWeek,
      'attendanceByType': attendanceByType,
      'highestAttendanceCultos': highestAttendanceCultos,
      'lowestAttendanceCultos': lowestAttendanceCultos.map((stats) => stats.toMap()).toList(),
      'attendanceByPastor': attendanceByPastor,
      'averageAttendanceByType': averageAttendanceByType,
      'mostPopularType': mostPopularType,
      'topAttendedCultos': topAttendedCultos,
    };
  }
} 