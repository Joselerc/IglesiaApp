/// Modelo para estadísticas de trabajo de un usuario en ministerios
class UserWorkStats {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final int totalInvitations;  // Total de invitaciones recibidas
  final int acceptedJobs;      // Trabajos aceptados
  final int rejectedJobs;      // Trabajos rechazados
  final int pendingJobs;       // Trabajos pendientes
  final double acceptanceRate; // Porcentaje de aceptación (0-100)
  final DateTime lastWorkDate; // Fecha del último trabajo
  final List<String>? recentJobIds; // IDs de los trabajos recientes

  UserWorkStats({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.totalInvitations,
    required this.acceptedJobs,
    required this.rejectedJobs,
    required this.pendingJobs,
    required this.acceptanceRate,
    required this.lastWorkDate,
    this.recentJobIds,
  });

  // Método para ordenar usuarios por tasa de aceptación (de mayor a menor)
  static int compareByAcceptanceRate(UserWorkStats a, UserWorkStats b) {
    return b.acceptanceRate.compareTo(a.acceptanceRate);
  }

  // Método para ordenar usuarios por número de trabajos aceptados (de mayor a menor)
  static int compareByAcceptedJobs(UserWorkStats a, UserWorkStats b) {
    return b.acceptedJobs.compareTo(a.acceptedJobs);
  }

  // Método para ordenar usuarios por fecha del último trabajo (más reciente primero)
  static int compareByLastWorkDate(UserWorkStats a, UserWorkStats b) {
    return b.lastWorkDate.compareTo(a.lastWorkDate);
  }
} 