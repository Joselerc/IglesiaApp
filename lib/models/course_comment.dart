import 'package:cloud_firestore/cloud_firestore.dart';

class CourseComment {
  final String id;
  final String lessonId;
  final String courseId;
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likedBy; // Lista de IDs de usuarios que dieron like
  final String? parentId; // ID del comentario padre (si es una respuesta)
  final int replyCount; // Contador de respuestas

  CourseComment({
    required this.id,
    required this.lessonId,
    required this.courseId,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    required this.likedBy,
    this.parentId,
    required this.replyCount,
  });

  factory CourseComment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CourseComment(
      id: doc.id,
      lessonId: data['lessonId'] ?? '',
      courseId: data['courseId'] ?? '',
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? 'Usuario anónimo',
      userPhotoUrl: data['userPhotoUrl'],
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentId: data['parentId'],
      replyCount: data['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'courseId': courseId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'comment': comment,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likedBy': likedBy,
      'parentId': parentId,
      'replyCount': replyCount,
    };
  }

  // Método para comprobar si un usuario ha dado like al comentario
  bool isLikedByUser(String userId) {
    return likedBy.contains(userId);
  }

  // Método para dar/quitar like a un comentario
  CourseComment toggleLike(String userId) {
    List<String> updatedLikes = List.from(likedBy);
    
    if (isLikedByUser(userId)) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }
    
    return CourseComment(
      id: id,
      lessonId: lessonId,
      courseId: courseId,
      userId: this.userId,
      userDisplayName: userDisplayName,
      userPhotoUrl: userPhotoUrl,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likedBy: updatedLikes,
      parentId: parentId,
      replyCount: replyCount,
    );
  }

  // Método para incrementar el contador de respuestas
  CourseComment incrementReplyCount() {
    return CourseComment(
      id: id,
      lessonId: lessonId,
      courseId: courseId,
      userId: userId,
      userDisplayName: userDisplayName,
      userPhotoUrl: userPhotoUrl,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likedBy: likedBy,
      parentId: parentId,
      replyCount: replyCount + 1,
    );
  }

  // Método para crear un nuevo comentario
  static CourseComment create({
    required String lessonId,
    required String courseId,
    required String userId,
    required String userDisplayName,
    String? userPhotoUrl,
    required String comment,
    String? parentId,
  }) {
    return CourseComment(
      id: '', // El ID se asignará al guardar en Firestore
      lessonId: lessonId,
      courseId: courseId,
      userId: userId,
      userDisplayName: userDisplayName,
      userPhotoUrl: userPhotoUrl,
      comment: comment,
      createdAt: DateTime.now(),
      updatedAt: null,
      likedBy: [],
      parentId: parentId,
      replyCount: 0,
    );
  }
} 