import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_module.dart';
import '../models/course_lesson.dart';
import '../models/course_comment.dart';
import '../models/user_course_progress.dart';
import '../models/course_section_config.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImageService _imageService = ImageService();
  final NotificationService _notificationService = NotificationService();

  // Referencia a colecciones de Firestore
  CollectionReference get _coursesRef => _firestore.collection('courses');
  CollectionReference get _modulesRef => _firestore.collection('courseModules');
  CollectionReference get _lessonsRef => _firestore.collection('courseLessons');
  CollectionReference get _progressRef => _firestore.collection('userCourseProgress');
  CollectionReference get _commentsRef => _firestore.collection('courseComments');
  CollectionReference get _configRef => _firestore.collection('app_config');

  // Crea un nuevo curso
  Future<String> createCourse(Course course) async {
    try {
      final docRef = await _coursesRef.add(course.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao criar curso: $e');
      throw Exception('Não foi possível criar o curso: $e');
    }
  }

  // Actualiza un curso existente
  Future<void> updateCourse(Course course) async {
    try {
      await _coursesRef.doc(course.id).update(course.toMap());
    } catch (e) {
      debugPrint('Erro ao atualizar curso: $e');
      throw Exception('Não foi possível atualizar o curso: $e');
    }
  }

  // Elimina un curso y sus recursos asociados
  Future<void> deleteCourse(String courseId) async {
    try {
      // Comenzar uma transação de escrita por lotes para garantir a atomicidade
      final batch = _firestore.batch();
      
      // Eliminar o curso
      batch.delete(_coursesRef.doc(courseId));
      
      // Obter módulos do curso
      final modulesQuery = await _modulesRef.where('courseId', isEqualTo: courseId).get();
      
      // Iterar sobre cada módulo
      for (var moduleDoc in modulesQuery.docs) {
        final moduleId = moduleDoc.id;
        
        // Eliminar o módulo
        batch.delete(_modulesRef.doc(moduleId));
        
        // Obter lições do módulo
        final lessonsQuery = await _lessonsRef
            .where('courseId', isEqualTo: courseId)
            .where('moduleId', isEqualTo: moduleId)
            .get();
        
        // Eliminar cada lição
        for (var lessonDoc in lessonsQuery.docs) {
          batch.delete(_lessonsRef.doc(lessonDoc.id));
        }
      }
      
      // Obter comentários do curso
      final commentsQuery = await _commentsRef.where('courseId', isEqualTo: courseId).get();
      
      // Eliminar comentários
      for (var commentDoc in commentsQuery.docs) {
        batch.delete(_commentsRef.doc(commentDoc.id));
      }
      
      // Obter progresso de usuários para este curso
      final progressQuery = await _progressRef.where('courseId', isEqualTo: courseId).get();
      
      // Eliminar registros de progresso
      for (var progressDoc in progressQuery.docs) {
        batch.delete(_progressRef.doc(progressDoc.id));
      }
      
      // Executar o lote de operações
      await batch.commit();
      
      // Eliminar arquivos de Storage asociados ao curso
      try {
        await _storage.ref('courses/$courseId').delete();
      } catch (e) {
        // Ignorar erros ao excluir arquivos de Storage, já que poderiam não existir
        debugPrint('Nota: Não foram encontrados arquivos associados ao curso no Storage');
      }
    } catch (e) {
      debugPrint('Erro ao excluir curso: $e');
      throw Exception('Não foi possível excluir o curso: $e');
    }
  }

  // Obtém um curso por ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final doc = await _coursesRef.doc(courseId).get();
      
      if (doc.exists) {
        return Course.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      debugPrint('Erro ao obter curso: $e');
      throw Exception('Não foi possível obter o curso: $e');
    }
  }

  // Obtém todos os cursos (com filtros opcionais)
  Stream<List<Course>> getCourses({
    CourseStatus? status,
    String? category,
    bool onlyFeatured = false,
  }) {
    try {
      Query query = _coursesRef.orderBy('createdAt', descending: true);
      
      // Aplicar filtros se estão definidos
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (onlyFeatured) {
        query = query.where('isFeatured', isEqualTo: true);
      }
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
      });
    } catch (e) {
      debugPrint('Erro ao obter cursos: $e');
      return Stream.value([]);
    }
  }

  // MÓDULOS DE CURSO

  // Cria um novo módulo
  Future<String> createModule(CourseModule module) async {
    try {
      // Transação para atualizar também o contador de módulos no curso
      return await _firestore.runTransaction<String>(
        (transaction) async {
          // Primeiro realizar todas as leituras
          // Ler o documento do curso para obter o contador atual de módulos
          final courseRef = _coursesRef.doc(module.courseId);
          final courseSnapshot = await transaction.get(courseRef);
          
          // Depois realizar todas as escritas
          // Criar o módulo
          final moduleRef = _modulesRef.doc();
          transaction.set(moduleRef, module.toMap());
          
          // Atualizar o contador de módulos no curso
          if (courseSnapshot.exists) {
            final currentModules = courseSnapshot.get('totalModules') as int? ?? 0;
            transaction.update(courseRef, {'totalModules': currentModules + 1});
          }
          
          return moduleRef.id;
        },
        maxAttempts: 3,
      );
    } catch (e) {
      debugPrint('Erro ao criar módulo: $e');
      throw Exception('Não foi possível criar o módulo: $e');
    }
  }

  // Atualiza um módulo existente
  Future<void> updateModule(CourseModule module) async {
    try {
      await _modulesRef.doc(module.id).update(module.toMap());
    } catch (e) {
      debugPrint('Erro ao atualizar módulo: $e');
      throw Exception('Não foi possível atualizar o módulo: $e');
    }
  }

  // Elimina um módulo e suas lições
  Future<void> deleteModule(String moduleId, String courseId) async {
    try {
      return await _firestore.runTransaction<void>(
        (transaction) async {
          // Obter lições do módulo
          final lessonsQuery = await _lessonsRef
              .where('moduleId', isEqualTo: moduleId)
              .get();
          
          // Contar lições
          final lessonCount = lessonsQuery.docs.length;
          
          // Eliminar cada lição
          for (var lessonDoc in lessonsQuery.docs) {
            transaction.delete(_lessonsRef.doc(lessonDoc.id));
          }
          
          // Eliminar o módulo
          transaction.delete(_modulesRef.doc(moduleId));
          
          // Atualizar o contador de módulos e lições no curso
          final courseRef = _coursesRef.doc(courseId);
          final courseSnapshot = await transaction.get(courseRef);
          
          if (courseSnapshot.exists) {
            final currentModules = courseSnapshot.get('totalModules') as int? ?? 0;
            final currentLessons = courseSnapshot.get('totalLessons') as int? ?? 0;
            
            transaction.update(courseRef, {
              'totalModules': math.max(0, currentModules - 1),
              'totalLessons': math.max(0, currentLessons - lessonCount),
            });
          }
        },
        maxAttempts: 3,
      );
    } catch (e) {
      debugPrint('Erro ao excluir módulo: $e');
      throw Exception('Não foi possível excluir o módulo: $e');
    }
  }

  // Obter os módulos de um curso ordenados por 'order'
  Stream<List<CourseModule>> getModulesForCourse(String courseId) {
    try {
      return _modulesRef
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => CourseModule.fromFirestore(doc)).toList();
          });
    } catch (e) {
      debugPrint('Erro ao obter módulos: $e');
      return Stream.value([]);
    }
  }

  // LIÇÕES DE CURSO

  // Cria uma nova lição
  Future<String> createLesson(CourseLesson lesson) async {
    try {
      final lessonId = await _firestore.runTransaction<String>(
        (transaction) async {
          // Primer realizar todas las lecturas
          // Leer el documento del curso
          final courseRef = _coursesRef.doc(lesson.courseId);
          final courseSnapshot = await transaction.get(courseRef);
          
          // Leer el documento del módulo
          final moduleRef = _modulesRef.doc(lesson.moduleId);
          final moduleSnapshot = await transaction.get(moduleRef);
          
          // Después realizar todas las escrituras
          // Crear la lección
          final lessonRef = _lessonsRef.doc();
          transaction.set(lessonRef, lesson.toMap());
          
          // Actualizar el contador de lecciones en el curso
          if (courseSnapshot.exists) {
            final currentLessons = courseSnapshot.get('totalLessons') as int? ?? 0;
            transaction.update(courseRef, {'totalLessons': currentLessons + 1});
          }
          
          // Actualizar el contador de lecciones en el módulo
          if (moduleSnapshot.exists) {
            final currentLessons = moduleSnapshot.get('totalLessons') as int? ?? 0;
            transaction.update(moduleRef, {'totalLessons': currentLessons + 1});
          }
          
          return lessonRef.id;
        },
        maxAttempts: 3,
      );
      
      // Actualizar la duración total del curso (fuera de la transacción)
      await updateCourseTotalDuration(lesson.courseId);
      
      return lessonId;
    } catch (e) {
      debugPrint('Erro ao criar lição: $e');
      throw Exception('Não foi possível criar a lição: $e');
    }
  }

  // Atualiza uma lição existente
  Future<void> updateLesson(CourseLesson lesson) async {
    try {
      // Primero obtenemos la lección actual para comparar duración
      final currentLessonDoc = await _lessonsRef.doc(lesson.id).get();
      final currentLesson = CourseLesson.fromFirestore(currentLessonDoc);
      
      // Actualizar la lección
      await _lessonsRef.doc(lesson.id).update(lesson.toMap());
      
      // Si cambió la duración, actualizar la duración total del curso
      if (currentLesson.duration != lesson.duration) {
        await updateCourseTotalDuration(lesson.courseId);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar lição: $e');
      throw Exception('Não foi possível atualizar a lição: $e');
    }
  }

  // Elimina uma lição
  Future<void> deleteLesson(String lessonId, String moduleId, String courseId) async {
    try {
      return await _firestore.runTransaction<void>(
        (transaction) async {
          // Primero realizar todas las lecturas
          final courseRef = _coursesRef.doc(courseId);
          final courseSnapshot = await transaction.get(courseRef);
          final moduleRef = _modulesRef.doc(moduleId);
          final moduleSnapshot = await transaction.get(moduleRef);
          final lessonRef = _lessonsRef.doc(lessonId);
          
          // Obtener todos los progresos de usuarios para este curso
          final progressQuery = await _progressRef
              .where('courseId', isEqualTo: courseId)
              .get();
              
          // Después realizar todas las escrituras
          // Eliminar la lección
          transaction.delete(lessonRef);
          
          // Actualizar el contador de lecciones en el curso
          if (courseSnapshot.exists) {
            final currentLessons = courseSnapshot.get('totalLessons') as int? ?? 0;
            transaction.update(courseRef, {'totalLessons': math.max(0, currentLessons - 1)});
          }
          
          // Actualizar el contador de lecciones en el módulo
          if (moduleSnapshot.exists) {
            final currentLessons = moduleSnapshot.get('totalLessons') as int? ?? 0;
            transaction.update(moduleRef, {'totalLessons': math.max(0, currentLessons - 1)});
          }
          
          // Eliminar la lección de la lista de completadas en cada progreso de usuario
          for (final progressDoc in progressQuery.docs) {
            final progressRef = _progressRef.doc(progressDoc.id);
            transaction.update(progressRef, {
              'completedLessons': FieldValue.arrayRemove([lessonId])
            });
            
            // Recalcular el porcentaje de completado (opcional, pero recomendable)
            // Se podría hacer aquí o dejar que se recalcule la próxima vez que el usuario interactúe
            // Para simplificar, lo omitimos por ahora, pero sería ideal recalcularlo.
          }
        },
        maxAttempts: 3,
      ).then((_) async {
        // Actualizar la duración total del curso (fuera de la transacción)
        await updateCourseTotalDuration(courseId);
      });
    } catch (e) {
      debugPrint('Erro ao excluir lição: $e');
      throw Exception('Não foi possível excluir a lição: $e');
    }
  }

  // Obter as lições de um módulo ordenadas por 'order'
  Stream<List<CourseLesson>> getLessonsForModule(String moduleId) {
    try {
      return _lessonsRef
          .where('moduleId', isEqualTo: moduleId)
          .orderBy('order')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => CourseLesson.fromFirestore(doc)).toList();
          });
    } catch (e) {
      debugPrint('Erro ao obter lições: $e');
      return Stream.value([]);
    }
  }

  // Obter todas as lições de um curso ordenadas por módulo e ordem
  Future<List<CourseLesson>> getAllLessonsForCourse(String courseId) async {
    try {
      final snapshot = await _lessonsRef
          .where('courseId', isEqualTo: courseId)
          .orderBy('moduleId')
          .orderBy('order')
          .get();
      
      return snapshot.docs.map((doc) => CourseLesson.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Erro ao obter todas as lições: $e');
      return [];
    }
  }

  // PROGRESSO DO USUÁRIO

  // Inscreve um usuário em um curso
  Future<void> enrollUserInCourse(String userId, String courseId) async {
    try {
      // Verificar se já está inscrito
      final existingDoc = await _progressRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (existingDoc.docs.isNotEmpty) {
        // Já está inscrito, não fazer nada
        return;
      }
      
      // Criar uma nova inscrição
      final progress = UserCourseProgress.createEnrollment(userId, courseId);
      
      // Añadir ao curso
      await _progressRef.add(progress.toMap());
      
      // Atualizar o contador de inscrições no curso
      await _coursesRef.doc(courseId).update({
        'enrolledUsers': FieldValue.arrayUnion([userId])
      });
      
      // Obter informações do curso para a notificação
      final courseDoc = await _coursesRef.doc(courseId).get();
      if (courseDoc.exists) {
        final course = Course.fromFirestore(courseDoc);
        
        // Notificar ao instrutor
        await _notificationService.sendNotification(
          userId: course.instructorId,
          title: 'Novo aluno inscrito',
          body: 'Um usuário se inscreveu no seu curso "${course.title}"',
          data: {
            'courseId': courseId,
            'userId': userId,
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao inscrever usuário no curso: $e');
      throw Exception('Não foi possível inscrever o usuário no curso: $e');
    }
  }

  // Marca uma lição como concluída
  Future<void> markLessonAsCompleted(String userId, String courseId, String lessonId) async {
    try {
      // Obter o progresso atual
      final querySnapshot = await _progressRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // O usuário não está inscrito, inscrever primeiro
        await enrollUserInCourse(userId, courseId);
        
        // Voltar a obter
        return markLessonAsCompleted(userId, courseId, lessonId);
      }
      
      final progressDoc = querySnapshot.docs.first;
      final progress = UserCourseProgress.fromFirestore(progressDoc);
      
      // Se a lição já está marcada como concluída, não fazer nada
      if (progress.completedLessons.contains(lessonId)) {
        return;
      }
      
      // Obter o número total de lições no curso
      final totalLessons = await _getLessonCountForCourse(courseId);
      
      // Atualizar o progresso
      final updatedProgress = progress.markLessonAsCompleted(lessonId, totalLessons);
      
      // Guardar em Firestore
      await _progressRef.doc(progressDoc.id).update(updatedProgress.toMap());
      
      // Se se completa o curso, enviar notificação
      if (updatedProgress.completionPercentage >= 100 && progress.completionPercentage < 100) {
        // Obter informações do curso
        final courseDoc = await _coursesRef.doc(courseId).get();
        if (courseDoc.exists) {
          final course = Course.fromFirestore(courseDoc);
          
          // Notificar ao usuário
          await _notificationService.sendNotification(
            userId: userId,
            title: 'Parabéns!',
            body: 'Você concluiu o curso "${course.title}"',
            data: {
              'courseId': courseId,
            },
          );
          
          // Notificar ao instrutor
          await _notificationService.sendNotification(
            userId: course.instructorId,
            title: 'Curso concluído',
            body: 'Um aluno concluiu seu curso "${course.title}"',
            data: {
              'courseId': courseId,
              'userId': userId,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao marcar lição como concluída: $e');
      throw Exception('Não foi possível marcar a lição como concluída: $e');
    }
  }

  // Desmarca uma lição como concluída
  Future<void> unmarkLessonAsCompleted(String userId, String courseId, String lessonId) async {
    try {
      // Obter o progresso atual
      final querySnapshot = await _progressRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // O usuário não está inscrito, não há nada para desmarcar
        return;
      }
      
      final progressDoc = querySnapshot.docs.first;
      final progress = UserCourseProgress.fromFirestore(progressDoc);
      
      // Se a lição não está marcada como concluída, não fazer nada
      if (!progress.completedLessons.contains(lessonId)) {
        return;
      }
      
      // Remover a lição das completadas
      List<String> updatedLessons = List.from(progress.completedLessons)..remove(lessonId);
      
      // Obter o número total de lições no curso
      final totalLessons = await _getLessonCountForCourse(courseId);
      
      // Calcular o novo porcentagem de finalização
      double newPercentage = totalLessons > 0 
          ? (updatedLessons.length / totalLessons) * 100 
          : 0;
      
      // Atualizar completedAt se necessário (se o curso estava completo e agora não está)
      DateTime? newCompletedAt = progress.completedAt;
      if (newPercentage < 100 && progress.completedAt != null) {
        newCompletedAt = null;
      }
      
      // Atualizar o progresso
      final updatedProgress = UserCourseProgress(
        id: progressDoc.id,
        userId: userId,
        courseId: courseId,
        isFavorite: progress.isFavorite,
        enrolledAt: progress.enrolledAt,
        lastAccessedAt: DateTime.now(),
        completionPercentage: newPercentage,
        completedLessons: updatedLessons,
        lessonRatings: progress.lessonRatings,
        completedAt: newCompletedAt,
      );
      
      // Guardar em Firestore
      await _progressRef.doc(progressDoc.id).update(updatedProgress.toMap());
    } catch (e) {
      debugPrint('Erro ao desmarcar lição como concluída: $e');
      throw Exception('Não foi possível desmarcar a lição como concluída: $e');
    }
  }

  // Auxiliar: Obter o número total de lições em um curso
  Future<int> _getLessonCountForCourse(String courseId) async {
    try {
      // Primero verificamos el valor almacenado como referencia
      final courseDoc = await _coursesRef.doc(courseId).get();
      final storedCount = courseDoc.exists ? 
          (courseDoc.data() as Map<String, dynamic>)['totalLessons'] ?? 0 : 0;
      
      // Ahora contamos las lecciones en tiempo real
      final lessonsSnapshot = await _lessonsRef
          .where('courseId', isEqualTo: courseId)
          .get();
      
      final realLessonCount = lessonsSnapshot.docs.length;
      
      // Si hay discrepancia, actualizamos el campo totalLessons en el curso
      if (realLessonCount != storedCount && courseDoc.exists) {
        await _coursesRef.doc(courseId).update({
          'totalLessons': realLessonCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Corrigindo contador de lições para o curso: $courseId. ' +
                   'Valor armazenado: $storedCount, Valor real: $realLessonCount');
      }
      
      return realLessonCount;
    } catch (e) {
      debugPrint('Erro ao obter recuento de lições: $e');
      return 0;
    }
  }

  // Marca um curso como favorito ou tira de favoritos
  Future<void> toggleFavoriteCourse(String userId, String courseId) async {
    try {
      // Obter o progresso atual
      final querySnapshot = await _progressRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // O usuário não está inscrito, inscrever primeiro
        await enrollUserInCourse(userId, courseId);
        
        // Voltar a chamar esta função
        return toggleFavoriteCourse(userId, courseId);
      }
      
      final progressDoc = querySnapshot.docs.first;
      final progress = UserCourseProgress.fromFirestore(progressDoc);
      
      // Atualizar favorito
      final updatedProgress = progress.toggleFavorite();
      
      // Guardar em Firestore
      await _progressRef.doc(progressDoc.id).update({
        'isFavorite': updatedProgress.isFavorite,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erro ao marcar/desmarcar curso como favorito: $e');
      throw Exception('Não foi possível marcar/desmarcar o curso como favorito: $e');
    }
  }

  // Obter o progresso de um usuário em um curso
  Stream<UserCourseProgress?> getUserCourseProgress(String userId, String courseId) {
    try {
      return _progressRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            }
            return UserCourseProgress.fromFirestore(snapshot.docs.first);
          });
    } catch (e) {
      debugPrint('Erro ao obter progresso do usuário: $e');
      return Stream.value(null);
    }
  }

  // Obter todos os cursos favoritos de um usuário
  Stream<List<Course>> getUserFavoriteCourses(String userId) {
    try {
      // Primeiro obtemos os IDs de cursos favoritos
      return _progressRef
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .snapshots()
          .asyncMap((snapshot) async {
            // Extrair IDs de cursos favoritos
            final courseIds = snapshot.docs.map((doc) {
              final progress = UserCourseProgress.fromFirestore(doc);
              return progress.courseId;
            }).toList();
            
            if (courseIds.isEmpty) {
              return [];
            }
            
            // Obter documentos de cursos para estes IDs
            final courseDocs = await Future.wait(
              courseIds.map((id) => _coursesRef.doc(id).get())
            );
            
            // Converter para objetos Course e filtrar os que poderiam ter sido excluídos
            return courseDocs
                .where((doc) => doc.exists)
                .map((doc) => Course.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('Erro ao obter cursos favoritos: $e');
      return Stream.value([]);
    }
  }

  // Obter todos os cursos nos quais um usuário está inscrito
  Stream<List<Course>> getUserEnrolledCourses(String userId) {
    try {
      // Obter todos os registros de progresso do usuário
      return _progressRef
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
            // Extrair IDs de cursos
            final courseIds = snapshot.docs.map((doc) {
              final progress = UserCourseProgress.fromFirestore(doc);
              return progress.courseId;
            }).toList();
            
            if (courseIds.isEmpty) {
              return [];
            }
            
            // Obter documentos de cursos para estes IDs
            final courseDocs = await Future.wait(
              courseIds.map((id) => _coursesRef.doc(id).get())
            );
            
            // Converter para objetos Course e filtrar os que poderiam ter sido excluídos
            return courseDocs
                .where((doc) => doc.exists)
                .map((doc) => Course.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      debugPrint('Erro ao obter cursos inscritos: $e');
      return Stream.value([]);
    }
  }

  // Valora uma lição
  Future<void> rateLessonWithProgress(String userId, String courseId, String lessonId, double rating) async {
    try {
      // Verificar intervalo de avaliação (permitir 0.5)
      if (rating < 0.5 || rating > 5) {
        throw Exception('A avaliação deve estar entre 0.5 e 5');
      }
      
      // Arredondar para meio ponto mais próximo (já feito na UI, mas redundante não faz mal)
      rating = (rating * 2).round() / 2.0;
      
      // Obter progresso do usuário
      final querySnapshot = await _progressRef
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // O usuário não está inscrito, inscrever primeiro
        await enrollUserInCourse(userId, courseId);
        
        // Voltar a tentar
        return rateLessonWithProgress(userId, courseId, lessonId, rating);
      }
      
      final progressDoc = querySnapshot.docs.first;
      final progress = UserCourseProgress.fromFirestore(progressDoc);
      
      // Obter avaliação anterior (se existir)
      final previousRating = progress.lessonRatings[lessonId];
      
      // Atualizar avaliação no progresso
      final updatedProgress = progress.rateLesson(lessonId, rating);
      await _progressRef.doc(progressDoc.id).update({
        'lessonRatings': updatedProgress.lessonRatings,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });
      
      // Atualizar estatísticas de avaliação na lição
      final lessonDoc = await _lessonsRef.doc(lessonId).get();
      if (lessonDoc.exists) {
        // Obter dados atuais
        final data = lessonDoc.data() as Map<String, dynamic>;
        final totalRatings = data['totalRatings'] as int? ?? 0;
        final currentAverage = data['averageRating'] as double? ?? 0;
        
        // Obter distribuição de avaliações
        final Map<String, dynamic> distribution = 
            Map<String, dynamic>.from(data['ratingDistribution'] ?? {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0});
        
        // Calcular nova avaliação média e distribuição
        double newAverage;
        Map<String, dynamic> newDistribution = Map.from(distribution);
        
        if (previousRating != null) {
          // Se já havia avaliado antes, subtrair a avaliação anterior
          final prevRatingKey = previousRating.toInt().toString();
          newDistribution[prevRatingKey] = (newDistribution[prevRatingKey] ?? 0) - 1;
          
          // Calcular média ajustada (remover avaliação anterior, adicionar nova)
          final totalPoints = currentAverage * totalRatings;
          newAverage = (totalPoints - previousRating + rating) / totalRatings;
        } else {
          // Primeira avaliação deste usuário para esta lição
          final totalPoints = currentAverage * totalRatings;
          newAverage = (totalPoints + rating) / (totalRatings + 1);
          
          // Incrementar contador total
          await _lessonsRef.doc(lessonId).update({
            'totalRatings': FieldValue.increment(1),
          });
        }
        
        // Incrementar contador na nova avaliação
        final newRatingKey = rating.toInt().toString();
        newDistribution[newRatingKey] = (newDistribution[newRatingKey] ?? 0) + 1;
        
        // Atualizar média e distribuição
        await _lessonsRef.doc(lessonId).update({
          'averageRating': newAverage,
          'ratingDistribution': newDistribution,
        });
      }
    } catch (e) {
      debugPrint('Erro ao avaliar lição: $e');
      throw Exception('Não foi possível avaliar a lição: $e');
    }
  }

  // COMENTÁRIOS

  // Adicionar um comentário a uma lição
  Future<String> addComment(CourseComment comment) async {
    try {
      // Verificar se os comentários estão habilitados para esta lição
      final lessonDoc = await _lessonsRef.doc(comment.lessonId).get();
      if (lessonDoc.exists) {
        final lesson = CourseLesson.fromFirestore(lessonDoc);
        
        if (!lesson.hasComments) {
          throw Exception('Os comentários estão desativados para esta lição');
        }
      }
      
      // Criar comentário
      final docRef = await _commentsRef.add(comment.toMap());
      
      // Se é uma resposta, atualizar o contador de respostas do comentário pai
      if (comment.parentId != null && comment.parentId!.isNotEmpty) {
        await _commentsRef.doc(comment.parentId).update({
          'replyCount': FieldValue.increment(1),
        });
      }
      
      // Notificar ao instrutor do curso
      final courseDoc = await _coursesRef.doc(comment.courseId).get();
      if (courseDoc.exists) {
        final course = Course.fromFirestore(courseDoc);
        
        if (course.instructorId != comment.userId) {
          await _notificationService.sendNotification(
            userId: course.instructorId,
            title: 'Novo comentário no seu curso',
            body: 'Alguém comentou em uma lição de "${course.title}"',
            data: {
              'courseId': comment.courseId,
              'lessonId': comment.lessonId,
              'commentId': docRef.id,
            },
          );
        }
      }
      
      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao adicionar comentário: $e');
      throw Exception('Não foi possível adicionar o comentário: $e');
    }
  }

  // Obter comentários de uma lição (só comentários principais, não respostas)
  Stream<List<CourseComment>> getCommentsForLesson(String lessonId) {
    try {
      return _commentsRef
          .where('lessonId', isEqualTo: lessonId)
          .where('parentId', isNull: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => CourseComment.fromFirestore(doc)).toList();
          });
    } catch (e) {
      debugPrint('Erro ao obter comentários: $e');
      return Stream.value([]);
    }
  }

  // Obter respostas para um comentário
  Stream<List<CourseComment>> getRepliesForComment(String commentId) {
    try {
      return _commentsRef
          .where('parentId', isEqualTo: commentId)
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) => CourseComment.fromFirestore(doc)).toList();
          });
    } catch (e) {
      debugPrint('Erro ao obter respostas: $e');
      return Stream.value([]);
    }
  }

  // Dar "like" ou tirar "like" de um comentário
  Future<void> toggleLikeComment(String commentId, String userId) async {
    try {
      final commentDoc = await _commentsRef.doc(commentId).get();
      
      if (!commentDoc.exists) {
        throw Exception('O comentário não existe');
      }
      
      final comment = CourseComment.fromFirestore(commentDoc);
      final updatedComment = comment.toggleLike(userId);
      
      await _commentsRef.doc(commentId).update({
        'likedBy': updatedComment.likedBy,
      });
    } catch (e) {
      debugPrint('Erro ao curtir/descurtir comentário: $e');
      throw Exception('Não foi possível curtir/descurtir o comentário: $e');
    }
  }

  // Excluir um comentário
  Future<void> deleteComment(String commentId) async {
    try {
      final commentDoc = await _commentsRef.doc(commentId).get();
      
      if (!commentDoc.exists) {
        return; // Já foi excluído
      }
      
      final comment = CourseComment.fromFirestore(commentDoc);
      
      // Se tem um comentário pai, atualizar contador de respostas
      if (comment.parentId != null && comment.parentId!.isNotEmpty) {
        await _commentsRef.doc(comment.parentId).update({
          'replyCount': FieldValue.increment(-1),
        });
      }
      
      // Excluir respostas se é um comentário principal
      if (comment.parentId == null || comment.parentId!.isEmpty) {
        final repliesQuery = await _commentsRef
            .where('parentId', isEqualTo: commentId)
            .get();
        
        // Excluir cada resposta
        final batch = _firestore.batch();
        for (var doc in repliesQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      
      // Excluir o comentário
      await _commentsRef.doc(commentId).delete();
    } catch (e) {
      debugPrint('Erro ao excluir comentário: $e');
      throw Exception('Não foi possível excluir o comentário: $e');
    }
  }

  // CONFIGURAÇÃO DE SEÇÃO

  // Obter a configuração da seção de cursos
  Future<CourseSectionConfig> getCourseSectionConfig() async {
    try {
      // Tentativa de obter a configuração específica para a seção de cursos
      final doc = await _configRef.doc('course_section').get();
      
      if (doc.exists) {
        return CourseSectionConfig.fromFirestore(doc);
      }
      
      // Se não existir, criar uma configuração por padrão
      final defaultConfig = CourseSectionConfig.createDefault();
      await _configRef.doc('course_section').set(defaultConfig.toMap());
      
      // Criar uma nova instância como cópia do default mas atribuindo o ID correto
      return CourseSectionConfig(
        id: 'course_section',
        title: defaultConfig.title,
        subtitle: defaultConfig.subtitle,
        backgroundImageUrl: defaultConfig.backgroundImageUrl,
        cardBackgroundColor: defaultConfig.cardBackgroundColor,
        cardTextColor: defaultConfig.cardTextColor,
        isActive: defaultConfig.isActive,
        updatedAt: defaultConfig.updatedAt,
        updatedBy: defaultConfig.updatedBy,
        order: defaultConfig.order,
      );
    } catch (e) {
      debugPrint('Erro ao obter configuração da seção: $e');
      // Devolver configuração por padrão em caso de erro
      final defaultConfig = CourseSectionConfig.createDefault();
      return CourseSectionConfig(
        id: 'course_section',
        title: defaultConfig.title,
        subtitle: defaultConfig.subtitle,
        backgroundImageUrl: defaultConfig.backgroundImageUrl,
        cardBackgroundColor: defaultConfig.cardBackgroundColor,
        cardTextColor: defaultConfig.cardTextColor,
        isActive: defaultConfig.isActive,
        updatedAt: defaultConfig.updatedAt,
        updatedBy: defaultConfig.updatedBy,
        order: defaultConfig.order,
      );
    }
  }

  // Atualizar a configuração da seção de cursos
  Future<void> updateCourseSectionConfig(CourseSectionConfig config) async {
    try {
      await _configRef.doc('course_section').update(config.toMap());
      
      // Se a seção não existir em homeScreenSections, a criamos
      final homeSectionQuery = await _firestore
          .collection('homeScreenSections')
          .where('type', isEqualTo: 'courses')
          .get();
      
      if (homeSectionQuery.docs.isEmpty) {
        // Criar a seção em homeScreenSections
        await _firestore.collection('homeScreenSections').add({
          'title': config.title,
          'type': 'courses',
          'isActive': config.isActive,
          'order': config.order,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Atualizar a seção existente
        await homeSectionQuery.docs.first.reference.update({
          'title': config.title,
          'isActive': config.isActive,
          'order': config.order,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar configuração da seção: $e');
      throw Exception('Não foi possível atualizar a configuração: $e');
    }
  }

  // Subir uma imagem de curso e devolver a URL
  Future<String?> uploadCourseImage(File imageFile, String courseId, {bool isCardImage = false}) async {
    try {
      // Comprimir imagem
      final compressedImage = await _imageService.compressImage(imageFile, quality: 85);
      
      if (compressedImage == null) {
        throw Exception('Não foi possível comprimir a imagem');
      }
      
      // Definir a rota no Storage
      final filename = isCardImage ? 'card_image.jpg' : 'cover_image.jpg';
      final path = 'courses/$courseId/$filename';
      
      // Subir para Firebase Storage
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(compressedImage);
      final snapshot = await uploadTask;
      
      // Obter URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Erro ao enviar imagem do curso: $e');
      return null;
    }
  }

  // Subir a imagem para o card personalizado da seção
  Future<String?> uploadSectionCardImage(File imageFile) async {
    try {
      // Comprimir imagem
      final compressedImage = await _imageService.compressImage(imageFile, quality: 85);
      
      if (compressedImage == null) {
        throw Exception('Não foi possível comprimir a imagem');
      }
      
      // Definir a rota no Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'app_config/course_section_card_$timestamp.jpg';
      
      // Subir para Firebase Storage
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(compressedImage);
      final snapshot = await uploadTask;
      
      // Obter URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Erro ao enviar imagem do card: $e');
      return null;
    }
  }

  // Añadir método para calcular la duración total
  Future<int> calculateCourseTotalDuration(String courseId) async {
    try {
      // Obtener todas las lecciones del curso
      final lessons = await getAllLessonsForCourse(courseId);
      
      // Sumar la duración de todas las lecciones
      int totalDuration = 0;
      for (var lesson in lessons) {
        totalDuration += lesson.duration;
      }
      
      return totalDuration;
    } catch (e) {
      debugPrint('Erro ao calcular duração total do curso: $e');
      return 0; // Retornar 0 en caso de error
    }
  }

  // Añadir método para actualizar la duración total del curso
  Future<void> updateCourseTotalDuration(String courseId) async {
    try {
      // Calcular la duración total
      final totalDuration = await calculateCourseTotalDuration(courseId);
      
      // Actualizar el curso con la nueva duración
      await _coursesRef.doc(courseId).update({
        'totalDuration': totalDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Duração total do curso atualizada: $totalDuration minutos');
    } catch (e) {
      debugPrint('Erro ao atualizar duração total do curso: $e');
    }
  }
} 