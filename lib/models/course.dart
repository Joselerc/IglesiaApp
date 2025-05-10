import 'package:cloud_firestore/cloud_firestore.dart';

enum CourseStatus {
  published,
  draft,
  upcoming,
  archived
}

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? cardImageUrl; // Imagen personalizada para el card de home screen
  final String instructorId;
  final String instructorName;
  final String category;
  final int totalDuration; // Duración total en minutos (calculada automáticamente)
  final CourseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final bool isFeatured; // Para destacar en la pantalla principal
  final bool commentsEnabled; // Si se permiten comentarios en las lecciones
  final List<String> enrolledUsers; // IDs de usuarios inscritos
  final int totalModules;
  final int totalLessons;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.cardImageUrl,
    required this.instructorId,
    required this.instructorName,
    required this.category,
    required this.totalDuration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    required this.isFeatured,
    required this.commentsEnabled,
    required this.enrolledUsers,
    required this.totalModules,
    required this.totalLessons,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      cardImageUrl: data['cardImageUrl'],
      instructorId: data['instructorId'] ?? '',
      instructorName: data['instructorName'] ?? '',
      category: data['category'] ?? '',
      totalDuration: data['totalDuration'] ?? 0,
      status: _statusFromString(data['status'] ?? 'draft'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      isFeatured: data['isFeatured'] ?? false,
      commentsEnabled: data['commentsEnabled'] ?? true,
      enrolledUsers: List<String>.from(data['enrolledUsers'] ?? []),
      totalModules: data['totalModules'] ?? 0,
      totalLessons: data['totalLessons'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'cardImageUrl': cardImageUrl,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'category': category,
      'totalDuration': totalDuration,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'publishedAt': publishedAt,
      'isFeatured': isFeatured,
      'commentsEnabled': commentsEnabled,
      'enrolledUsers': enrolledUsers,
      'totalModules': totalModules,
      'totalLessons': totalLessons,
    };
  }

  static CourseStatus _statusFromString(String status) {
    switch (status) {
      case 'published':
        return CourseStatus.published;
      case 'draft':
        return CourseStatus.draft;
      case 'upcoming':
        return CourseStatus.upcoming;
      case 'archived':
        return CourseStatus.archived;
      default:
        return CourseStatus.draft;
    }
  }

  // Método para obtener el estado en forma legible
  String get statusText {
    switch (status) {
      case CourseStatus.published:
        return 'Publicado';
      case CourseStatus.draft:
        return 'Borrador';
      case CourseStatus.upcoming:
        return 'Próximamente';
      case CourseStatus.archived:
        return 'Arquivado';
    }
  }

  // Método para verificar si un usuario está inscrito
  bool isUserEnrolled(String userId) {
    return enrolledUsers.contains(userId);
  }

  // Copia del curso con campos actualizados
  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? cardImageUrl,
    String? instructorId,
    String? instructorName,
    String? category,
    int? totalDuration,
    CourseStatus? status,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isFeatured,
    bool? commentsEnabled,
    List<String>? enrolledUsers,
    int? totalModules,
    int? totalLessons,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      category: category ?? this.category,
      totalDuration: totalDuration ?? this.totalDuration,
      status: status ?? this.status,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      isFeatured: isFeatured ?? this.isFeatured,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      enrolledUsers: enrolledUsers ?? this.enrolledUsers,
      totalModules: totalModules ?? this.totalModules,
      totalLessons: totalLessons ?? this.totalLessons,
    );
  }
}

// Extensión para facilitar el filtrado de cursos
extension CourseStatusExtension on CourseStatus {
  // Método estático para representar "todos los estados"
  static CourseStatus? get all => null;
  
  // Textos para la interfaz de usuario
  String get displayName {
    switch (this) {
      case CourseStatus.published:
        return 'Publicado';
      case CourseStatus.draft:
        return 'Rascunho';
      case CourseStatus.upcoming:
        return 'Em breve';
      case CourseStatus.archived:
        return 'Arquivado';
    }
  }
} 