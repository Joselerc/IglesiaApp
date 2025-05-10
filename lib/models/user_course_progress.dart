import 'package:cloud_firestore/cloud_firestore.dart';

class UserCourseProgress {
  final String id; // documentId
  final String userId;
  final String courseId;
  final bool isFavorite;
  final DateTime enrolledAt;
  final DateTime lastAccessedAt;
  final double completionPercentage; // 0-100
  final List<String> completedLessons; // lista de IDs de lecciones completadas
  final Map<String, double> lessonRatings; // mapa de lectionId -> valoración (1-5)
  final DateTime? completedAt; // cuándo se completó el curso (o null si no se ha completado)

  UserCourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.isFavorite,
    required this.enrolledAt,
    required this.lastAccessedAt,
    required this.completionPercentage,
    required this.completedLessons,
    required this.lessonRatings,
    this.completedAt,
  });

  factory UserCourseProgress.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Procesar valoraciones de lecciones
    Map<String, double> ratings = {};
    if (data['lessonRatings'] != null) {
      final Map<String, dynamic> rawRatings = Map<String, dynamic>.from(data['lessonRatings']);
      rawRatings.forEach((key, value) {
        ratings[key] = (value as num).toDouble();
      });
    }
    
    return UserCourseProgress(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
      enrolledAt: (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastAccessedAt: (data['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completionPercentage: (data['completionPercentage'] ?? 0.0).toDouble(),
      completedLessons: List<String>.from(data['completedLessons'] ?? []),
      lessonRatings: ratings,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'isFavorite': isFavorite,
      'enrolledAt': enrolledAt,
      'lastAccessedAt': lastAccessedAt,
      'completionPercentage': completionPercentage,
      'completedLessons': completedLessons,
      'lessonRatings': lessonRatings,
      'completedAt': completedAt,
    };
  }

  // Método para actualizar el progreso con una nueva lección completada
  UserCourseProgress markLessonAsCompleted(String lessonId, int totalCourseLessons) {
    // Si la lección ya está marcada como completada, devolver el mismo objeto
    if (completedLessons.contains(lessonId)) {
      return this;
    }
    
    // Añadir la lección a las completadas
    List<String> updatedLessons = List.from(completedLessons)..add(lessonId);
    
    // Calcular el nuevo porcentaje de finalización
    double newPercentage = totalCourseLessons > 0 
        ? (updatedLessons.length / totalCourseLessons) * 100 
        : 0;
    
    // Comprobar si se ha completado el curso
    DateTime? newCompletedAt = completedAt;
    if (newPercentage >= 100 && completedAt == null) {
      newCompletedAt = DateTime.now();
    }
    
    return UserCourseProgress(
      id: id,
      userId: userId,
      courseId: courseId,
      isFavorite: isFavorite,
      enrolledAt: enrolledAt,
      lastAccessedAt: DateTime.now(),
      completionPercentage: newPercentage,
      completedLessons: updatedLessons,
      lessonRatings: lessonRatings,
      completedAt: newCompletedAt,
    );
  }

  // Método para actualizar la valoración de una lección
  UserCourseProgress rateLesson(String lessonId, double rating) {
    // Actualizar valoraciones
    Map<String, double> updatedRatings = Map.from(lessonRatings);
    updatedRatings[lessonId] = rating;
    
    return UserCourseProgress(
      id: id,
      userId: userId,
      courseId: courseId,
      isFavorite: isFavorite,
      enrolledAt: enrolledAt,
      lastAccessedAt: DateTime.now(),
      completionPercentage: completionPercentage,
      completedLessons: completedLessons,
      lessonRatings: updatedRatings,
      completedAt: completedAt,
    );
  }

  // Método para marcar/desmarcar un curso como favorito
  UserCourseProgress toggleFavorite() {
    return UserCourseProgress(
      id: id,
      userId: userId,
      courseId: courseId,
      isFavorite: !isFavorite,
      enrolledAt: enrolledAt,
      lastAccessedAt: DateTime.now(),
      completionPercentage: completionPercentage,
      completedLessons: completedLessons,
      lessonRatings: lessonRatings,
      completedAt: completedAt,
    );
  }
  
  // Método para crear una nueva inscripción
  static UserCourseProgress createEnrollment(String userId, String courseId) {
    return UserCourseProgress(
      id: '', // El ID se asignará al guardar en Firestore
      userId: userId,
      courseId: courseId,
      isFavorite: false,
      enrolledAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      completionPercentage: 0,
      completedLessons: [],
      lessonRatings: {},
      completedAt: null,
    );
  }
  
  // Método para actualizar el tiempo de último acceso
  UserCourseProgress updateLastAccessed() {
    return UserCourseProgress(
      id: id,
      userId: userId,
      courseId: courseId,
      isFavorite: isFavorite,
      enrolledAt: enrolledAt,
      lastAccessedAt: DateTime.now(),
      completionPercentage: completionPercentage,
      completedLessons: completedLessons,
      lessonRatings: lessonRatings,
      completedAt: completedAt,
    );
  }
} 