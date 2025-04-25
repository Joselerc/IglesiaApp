/// Modelo para estadísticas de asistencia de un usuario
class UserAttendanceStats {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int totalEvents;
  final int eventsAttended;
  final double attendanceRate; // Porcentaje de asistencia (0-100)
  final DateTime lastAttendance; // Fecha de la última asistencia
  final List<String>? recentEventIds; // IDs de los eventos recientes
  final String entityName; // Nombre del grupo o ministerio al que pertenece

  UserAttendanceStats({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.totalEvents,
    required this.eventsAttended,
    required this.attendanceRate,
    required this.lastAttendance,
    this.recentEventIds,
    this.entityName = '',
  });

  // Método para ordenar usuarios por tasa de asistencia (de mayor a menor)
  static int compareByAttendanceRate(UserAttendanceStats a, UserAttendanceStats b) {
    return b.attendanceRate.compareTo(a.attendanceRate);
  }

  // Método para ordenar usuarios por número de eventos asistidos (de mayor a menor)
  static int compareByEventsAttended(UserAttendanceStats a, UserAttendanceStats b) {
    return b.eventsAttended.compareTo(a.eventsAttended);
  }

  // Método para ordenar usuarios por fecha de última asistencia (más reciente primero)
  static int compareByLastAttendance(UserAttendanceStats a, UserAttendanceStats b) {
    return b.lastAttendance.compareTo(a.lastAttendance);
  }
} 