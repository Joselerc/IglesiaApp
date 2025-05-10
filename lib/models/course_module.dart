import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModule {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order; // Posición del módulo en el curso
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalLessons;

  CourseModule({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.totalLessons,
  });

  factory CourseModule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CourseModule(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalLessons: data['totalLessons'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalLessons': totalLessons,
    };
  }

  // Método para crear una copia con algunos campos actualizados
  CourseModule copyWith({
    String? courseId,
    String? title,
    String? description,
    int? order,
    DateTime? updatedAt,
    int? totalLessons,
  }) {
    return CourseModule(
      id: this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalLessons: totalLessons ?? this.totalLessons,
    );
  }
} 