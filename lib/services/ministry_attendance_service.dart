import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ministry_attendance.dart';

class MinistryAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ministry_attendance';

  // Registrar asistencia
  Future<void> recordAttendance(MinistryAttendance attendance) async {
    final docId = '${attendance.taskId}_${attendance.userId}';
    await _firestore
        .collection(_collection)
        .doc(docId)
        .set(attendance.toFirestore());
  }

  // Obtener historial de asistencia de un usuario
  Stream<List<MinistryAttendance>> getUserAttendanceHistory(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MinistryAttendance.fromFirestore(doc))
            .toList());
  }

  // Obtener estadísticas de asistencia de un usuario
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    int total = querySnapshot.docs.length;
    int attended = 0;
    int missed = 0;
    int rejected = 0;

    for (var doc in querySnapshot.docs) {
      final attendance = MinistryAttendance.fromFirestore(doc);
      switch (attendance.status) {
        case 'attended':
          attended++;
          break;
        case 'missed':
          missed++;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    double attendanceRate = total > 0 ? (attended / total) * 100 : 0;

    return {
      'total': total,
      'attended': attended,
      'missed': missed,
      'rejected': rejected,
      'attendanceRate': attendanceRate,
    };
  }

  // Obtener asistencia para una tarea específica
  Stream<List<MinistryAttendance>> getTaskAttendance(String taskId) {
    return _firestore
        .collection(_collection)
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MinistryAttendance.fromFirestore(doc))
            .toList());
  }

  // Actualizar estado de asistencia
  Future<void> updateAttendanceStatus(
    String taskId,
    String userId,
    String status, {
    String? reason,
  }) async {
    final docId = '${taskId}_${userId}';
    await _firestore.collection(_collection).doc(docId).update({
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  // Obtener asistencia por rango de fechas
  Future<List<MinistryAttendance>> getAttendanceByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    return querySnapshot.docs
        .map((doc) => MinistryAttendance.fromFirestore(doc))
        .toList();
  }
} 