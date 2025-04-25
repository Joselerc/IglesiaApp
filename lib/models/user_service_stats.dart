/// Modelo para estadísticas de participación de un usuario en servicios de cultos
class UserServiceStats {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int totalAssignments;    // Total de asignaciones recibidas
  final int confirmedAssignments; // Asignaciones confirmadas/atendidas
  final int acceptedAssignments;  // Asignaciones aceptadas
  final int rejectedAssignments;  // Asignaciones rechazadas
  final int pendingAssignments;   // Asignaciones pendientes
  final int cancelledAssignments; // Asignaciones canceladas
  final double confirmationRate;  // Porcentaje de confirmación (0-100)
  final DateTime lastServiceDate; // Fecha del último servicio
  final List<String>? recentAssignmentIds; // IDs de las asignaciones recientes

  UserServiceStats({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.totalAssignments,
    required this.confirmedAssignments,
    required this.acceptedAssignments,
    required this.rejectedAssignments,
    required this.pendingAssignments,
    this.cancelledAssignments = 0,
    required this.confirmationRate,
    required this.lastServiceDate,
    this.recentAssignmentIds,
  });

  // Método para ordenar usuarios por tasa de confirmación (de mayor a menor)
  static int compareByConfirmationRate(UserServiceStats a, UserServiceStats b) {
    return b.confirmationRate.compareTo(a.confirmationRate);
  }

  // Método para ordenar usuarios por número de asignaciones confirmadas (de mayor a menor)
  static int compareByConfirmedAssignments(UserServiceStats a, UserServiceStats b) {
    return b.confirmedAssignments.compareTo(a.confirmedAssignments);
  }

  // Método para ordenar usuarios por fecha del último servicio (más reciente primero)
  static int compareByLastServiceDate(UserServiceStats a, UserServiceStats b) {
    return b.lastServiceDate.compareTo(a.lastServiceDate);
  }
} 