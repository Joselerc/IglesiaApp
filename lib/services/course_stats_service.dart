import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/user_course_progress.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Importar para debugPrint

// Estructura para almacenar estadísticas de un curso
class CourseStats {
  final Course course;
  final int enrollmentCount;
  final double averageProgressPercentage;
  final double averageCompletedLessons;
  final Duration? averageCompletionTime; // Duración promedio para completar
  final Map<String, double> completionMilestones; // % usuarios en hitos (25, 50, 75, 90, 100)

  CourseStats({
    required this.course,
    required this.enrollmentCount,
    required this.averageProgressPercentage,
    required this.averageCompletedLessons,
    this.averageCompletionTime,
    required this.completionMilestones,
  });
}

// NUEVA Estructura para estadísticas DETALLADAS de un curso
class DetailedCourseStats {
  final Course course;
  final int enrollmentCount; // Total inscritos (considerando filtro fecha)
  final double averageProgressPercentage;
  final double averageCompletedLessons;
  final Duration? averageCompletionTime;
  final Map<String, double> completionMilestones; // { '25': %, '50': %, ... }
  final int completedUsersCount; // Usuarios que completaron (100%)
  final double completionRate; // % de inscritos que completaron
  final Duration? fastestCompletionTime;
  final Duration? slowestCompletionTime;
  // TODO: Añadir datos para gráficos (evolución inscripciones, distribución progreso)
  // final List<EnrollmentOverTimeData> enrollmentEvolution;
  // final Map<String, int> progressDistribution; // { '0-25': count, '25-50': count, ... }

  DetailedCourseStats({
    required this.course,
    required this.enrollmentCount,
    required this.averageProgressPercentage,
    required this.averageCompletedLessons,
    this.averageCompletionTime,
    required this.completionMilestones,
    required this.completedUsersCount,
    required this.completionRate,
    this.fastestCompletionTime,
    this.slowestCompletionTime,
    // required this.enrollmentEvolution,
    // required this.progressDistribution,
  });
}

class CourseStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _coursesRef => _firestore.collection('courses');
  CollectionReference get _progressRef => _firestore.collection('userCourseProgress');
  CollectionReference get _lessonsRef => _firestore.collection('courseLessons');

  // --- Estadísticas Generales ---

  // Obtiene el número total de inscripciones (basado en documentos de progreso)
  Future<int> getTotalEnrollments() async {
    try {
      final snapshot = await _progressRef.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Erro ao obter total de inscrições: $e');
      return 0;
    }
  }

  // --- Estadísticas por Curso ---

  // Obtiene estadísticas detalladas para todos los cursos
  Future<List<CourseStats>> getAllCourseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<CourseStats> courseStatsList = [];

    try {
      // 1. Obtener todos los cursos
      final coursesSnapshot = await _coursesRef.get();
      final courses = coursesSnapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();

      // 2. Para cada curso, obtener sus estadísticas de progreso
      for (final course in courses) {
        // Aplicar filtro de fecha si es necesario
        Query progressQuery = _progressRef.where('courseId', isEqualTo: course.id);
        if (startDate != null) {
          progressQuery = progressQuery.where('enrolledAt', isGreaterThanOrEqualTo: startDate);
        }
        if (endDate != null) {
          progressQuery = progressQuery.where('enrolledAt', isLessThanOrEqualTo: endDate);
        }
        
        final progressSnapshot = await progressQuery.get();
        final enrollments = progressSnapshot.docs.map((doc) => UserCourseProgress.fromFirestore(doc)).toList();

        // Calcular estadísticas
        final int enrollmentCount = enrollments.length;
        double totalPercentage = 0;
        int totalCompletedLessonsCount = 0;
        Duration totalCompletionDuration = Duration.zero;
        int usersCompletedCourse = 0;
        int reached25 = 0;
        int reached50 = 0;
        int reached75 = 0;
        int reached90 = 0;

        if (enrollmentCount > 0 && course.totalLessons > 0) {
          for (final progress in enrollments) {
            // Calcular porcentaje individual basado en lecciones reales
            double individualPercentage = (progress.completedLessons.length / course.totalLessons) * 100;
            totalPercentage += individualPercentage;
            totalCompletedLessonsCount += progress.completedLessons.length;

            // Calcular tiempo de finalización
            if (progress.completedAt != null) {
              totalCompletionDuration += progress.completedAt!.difference(progress.enrolledAt);
              usersCompletedCourse++;
            }
            
            // Calcular hitos
            if (individualPercentage >= 25) reached25++;
            if (individualPercentage >= 50) reached50++;
            if (individualPercentage >= 75) reached75++;
            if (individualPercentage >= 90) reached90++;
          }
        }
        
        final double averageProgressPercentage = 
            enrollmentCount > 0 ? totalPercentage / enrollmentCount : 0;
        final double averageCompletedLessons = 
            enrollmentCount > 0 ? totalCompletedLessonsCount / enrollmentCount : 0;
        final Duration? averageCompletionTime = 
            usersCompletedCourse > 0 ? totalCompletionDuration ~/ usersCompletedCourse : null;
            
        final Map<String, double> completionMilestones = {
          '25': enrollmentCount > 0 ? (reached25 / enrollmentCount) * 100 : 0,
          '50': enrollmentCount > 0 ? (reached50 / enrollmentCount) * 100 : 0,
          '75': enrollmentCount > 0 ? (reached75 / enrollmentCount) * 100 : 0,
          '90': enrollmentCount > 0 ? (reached90 / enrollmentCount) * 100 : 0,
          '100': enrollmentCount > 0 ? (usersCompletedCourse / enrollmentCount) * 100 : 0,
        };
            
        courseStatsList.add(CourseStats(
          course: course,
          enrollmentCount: enrollmentCount,
          averageProgressPercentage: averageProgressPercentage,
          averageCompletedLessons: averageCompletedLessons,
          averageCompletionTime: averageCompletionTime,
          completionMilestones: completionMilestones,
        ));
      }

      return courseStatsList;
    } catch (e) {
      print('Erro ao obter estatísticas dos cursos: $e');
      return []; // Retornar lista vacía en caso de error
    }
  }
  
  // --- Implementar métodos para otras estadísticas (Tiempo, Hitos) aquí ---

  // --- NUEVO: Estadísticas Detalladas para un Curso Específico ---

  Future<DetailedCourseStats?> getDetailedCourseStats(String courseId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final courseDoc = await _coursesRef.doc(courseId).get();
      if (!courseDoc.exists) return null;
      final course = Course.fromFirestore(courseDoc);

      final realTotalLessons = await _getRealLessonCount(courseId);

      Query progressQuery = _progressRef.where('courseId', isEqualTo: courseId);
      if (startDate != null) {
        progressQuery = progressQuery.where('enrolledAt', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        progressQuery = progressQuery.where('enrolledAt', isLessThanOrEqualTo: endDate);
      }
      
      final progressSnapshot = await progressQuery.get();
      final enrollments = progressSnapshot.docs.map((doc) => UserCourseProgress.fromFirestore(doc)).toList();

      final int enrollmentCount = enrollments.length;
      if (enrollmentCount == 0) {
        return DetailedCourseStats(
          course: course,
          enrollmentCount: 0,
          averageProgressPercentage: 0,
          averageCompletedLessons: 0,
          completionMilestones: {'25': 0, '50': 0, '75': 0, '90': 0, '100': 0},
          completedUsersCount: 0,
          completionRate: 0,
        );
      }

      // --- Recálculo específico para este curso ---
      double totalPercentageSum = 0;
      int totalCompletedLessonsCount = 0;
      Duration totalCompletionDurationSum = Duration.zero;
      int usersCompletedCourseCount = 0;
      Duration? fastestTime;
      Duration? slowestTime;
      int reached25 = 0, reached50 = 0, reached75 = 0, reached90 = 0;

      for (final progress in enrollments) {
        double individualPercentage = realTotalLessons > 0
            ? (progress.completedLessons.length / realTotalLessons) * 100
            : (progress.completedLessons.isNotEmpty ? 100.0 : 0.0);
        individualPercentage = individualPercentage.clamp(0.0, 100.0);

        // --- DEBUG PRINT DETALLADO ---
        debugPrint('[DETAILED STATS] User: ${progress.userId} -> Completed: ${progress.completedLessons.length}, Total: $realTotalLessons, Percentage: $individualPercentage');
        // ---------------------------

        totalPercentageSum += individualPercentage;
        totalCompletedLessonsCount += progress.completedLessons.length;

        if (progress.completedAt != null) {
          final completionTime = progress.completedAt!.difference(progress.enrolledAt);
          if (!completionTime.isNegative) {
             totalCompletionDurationSum += completionTime;
             usersCompletedCourseCount++;
             if (fastestTime == null || completionTime < fastestTime) fastestTime = completionTime;
             if (slowestTime == null || completionTime > slowestTime) slowestTime = completionTime;
          }
        }
        
        if (individualPercentage >= 25) reached25++;
        if (individualPercentage >= 50) reached50++;
        if (individualPercentage >= 75) reached75++;
        if (individualPercentage >= 90) reached90++;
      }
      
      final double averageProgressPercentage = totalPercentageSum / enrollmentCount;
      final double averageCompletedLessons = totalCompletedLessonsCount / enrollmentCount;
      final Duration? averageCompletionTime = usersCompletedCourseCount > 0 
          ? totalCompletionDurationSum ~/ usersCompletedCourseCount 
          : null;
          
      final Map<String, double> completionMilestones = {
        '25': (reached25 / enrollmentCount) * 100,
        '50': (reached50 / enrollmentCount) * 100,
        '75': (reached75 / enrollmentCount) * 100,
        '90': (reached90 / enrollmentCount) * 100,
        '100': (usersCompletedCourseCount / enrollmentCount) * 100,
      };
      final double completionRate = completionMilestones['100'] ?? 0.0;

      // --- DEBUG PRINT FINAL --- 
      debugPrint('[DETAILED STATS] Final Milestones for $courseId: $completionMilestones');
      debugPrint('[DETAILED STATS] Counts - enrolled: $enrollmentCount, reached25: $reached25, reached50: $reached50, reached75: $reached75, reached90: $reached90, completed100: $usersCompletedCourseCount');
      // ------------------------

      return DetailedCourseStats(
        course: course,
        enrollmentCount: enrollmentCount,
        averageProgressPercentage: averageProgressPercentage,
        averageCompletedLessons: averageCompletedLessons,
        averageCompletionTime: averageCompletionTime,
        completionMilestones: completionMilestones,
        completedUsersCount: usersCompletedCourseCount,
        completionRate: completionRate,
        fastestCompletionTime: fastestTime,
        slowestCompletionTime: slowestTime,
      );

    } catch (e) {
      print('Erro ao obter estatísticas detalhadas do curso $courseId: $e');
      return null;
    }
  }

  // Método auxiliar para obtener el número real de lecciones (¡NUEVO!)
  Future<int> _getRealLessonCount(String courseId) async {
    try {
      final snapshot = await _lessonsRef.where('courseId', isEqualTo: courseId).get();
      return snapshot.docs.length;
    } catch (e) {
      print('Erro ao contar lições para o curso $courseId: $e');
      return 0;
    }
  }

  Map<String, dynamic> _calculateGlobalMilestoneStats(List<CourseStats> statsList) {
    if (statsList.isEmpty) {
      return {
        'globalMilestones': {'25': 0.0, '50': 0.0, '75': 0.0, '90': 0.0, '100': 0.0},
        'topCompletionCourse': null,
      };
    }

    // Usar doubles para sumas ponderadas
    Map<String, double> milestoneWeightedSums = {'25': 0, '50': 0, '75': 0, '90': 0, '100': 0};
    int totalEnrollments = 0;
    CourseStats? topCompletionC = statsList.isNotEmpty ? statsList[0] : null;

    for (var stats in statsList) {
      totalEnrollments += stats.enrollmentCount;
      
      // Ponderar cada hito por el número de inscritos
      milestoneWeightedSums['25'] = milestoneWeightedSums['25']! + (stats.completionMilestones['25']! * stats.enrollmentCount);
      milestoneWeightedSums['50'] = milestoneWeightedSums['50']! + (stats.completionMilestones['50']! * stats.enrollmentCount);
      milestoneWeightedSums['75'] = milestoneWeightedSums['75']! + (stats.completionMilestones['75']! * stats.enrollmentCount);
      milestoneWeightedSums['90'] = milestoneWeightedSums['90']! + (stats.completionMilestones['90']! * stats.enrollmentCount);
      milestoneWeightedSums['100'] = milestoneWeightedSums['100']! + (stats.completionMilestones['100']! * stats.enrollmentCount);
      
      // Actualizar curso con mayor tasa de finalización (100%)
      if (topCompletionC == null || (stats.completionMilestones['100'] ?? 0) > (topCompletionC.completionMilestones['100'] ?? 0)) {
        topCompletionC = stats;
      }
    }

    // Calcular la media global dividiendo la suma ponderada por el total de inscritos
    final Map<String, double> globalMilestones = {
      '25': totalEnrollments > 0 ? (milestoneWeightedSums['25']! / totalEnrollments) : 0,
      '50': totalEnrollments > 0 ? (milestoneWeightedSums['50']! / totalEnrollments) : 0,
      '75': totalEnrollments > 0 ? (milestoneWeightedSums['75']! / totalEnrollments) : 0,
      '90': totalEnrollments > 0 ? (milestoneWeightedSums['90']! / totalEnrollments) : 0,
      '100': totalEnrollments > 0 ? (milestoneWeightedSums['100']! / totalEnrollments) : 0,
    };

    return {
      'globalMilestones': globalMilestones,
      'topCompletionCourse': topCompletionC,
    };
  }
} 