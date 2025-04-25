/// Modelo para estadísticas de participación de un usuario en servicios
class UserStats {
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String ministry;
  final int totalInvitations;     // Total de invitaciones recibidas
  final int totalAttendances;     // Total asistencias confirmadas
  final int totalAbsences;        // Total ausencias registradas
  final int acceptedInvitations;  // Invitaciones aceptadas
  final int rejectedInvitations;  // Invitaciones rechazadas
  final int pendingInvitations;   // Invitaciones pendientes
  final int cancelledInvitations; // Invitaciones canceladas
  
  UserStats({
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.ministry,
    required this.totalInvitations,
    required this.totalAttendances,
    required this.totalAbsences,
    required this.acceptedInvitations,
    required this.rejectedInvitations,
    required this.pendingInvitations,
    this.cancelledInvitations = 0,
  });

  // Método para ordenar usuarios por nombre
  static int compareByName(UserStats a, UserStats b) {
    return a.userName.compareTo(b.userName);
  }

  // Método para ordenar usuarios por total de invitaciones
  static int compareByTotalInvitations(UserStats a, UserStats b) {
    return b.totalInvitations.compareTo(a.totalInvitations);
  }

  // Método para ordenar usuarios por total de asistencias
  static int compareByTotalAttendances(UserStats a, UserStats b) {
    return b.totalAttendances.compareTo(a.totalAttendances);
  }

  // Método para ordenar usuarios por total de ausencias
  static int compareByTotalAbsences(UserStats a, UserStats b) {
    return b.totalAbsences.compareTo(a.totalAbsences);
  }

  // Método para ordenar usuarios por invitaciones aceptadas
  static int compareByAcceptedInvitations(UserStats a, UserStats b) {
    return b.acceptedInvitations.compareTo(a.acceptedInvitations);
  }

  // Método para ordenar usuarios por invitaciones rechazadas
  static int compareByRejectedInvitations(UserStats a, UserStats b) {
    return b.rejectedInvitations.compareTo(a.rejectedInvitations);
  }

  // Método para ordenar usuarios por invitaciones pendientes
  static int compareByPendingInvitations(UserStats a, UserStats b) {
    return b.pendingInvitations.compareTo(a.pendingInvitations);
  }
} 