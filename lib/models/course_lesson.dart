import 'package:cloud_firestore/cloud_firestore.dart';

class CourseLesson {
  final String id;
  final String courseId;
  final String moduleId;
  final String title;
  final String description;
  final String videoUrl; // URL de YouTube/Vimeo
  final String? videoThumbnailUrl;
  final int duration; // Duración en minutos
  final int order; // Posición de la lección en el módulo
  final List<String> complementaryMaterialUrls; // URLs de material descargable
  final List<String> complementaryMaterialNames; // Nombres de los materiales
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasComments; // Si está habilitado los comentarios
  final double averageRating; // Valoración promedio (1-5 estrellas)
  final int totalRatings; // Número total de valoraciones
  final Map<String, dynamic> ratingDistribution; // Distribución de valoraciones {1: 5, 2: 10, ...}

  CourseLesson({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.videoThumbnailUrl,
    required this.duration,
    required this.order,
    required this.complementaryMaterialUrls,
    required this.complementaryMaterialNames,
    required this.createdAt,
    required this.updatedAt,
    required this.hasComments,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory CourseLesson.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Procesamiento de materiales complementarios
    List<String> materialUrls = [];
    List<String> materialNames = [];
    
    if (data['complementaryMaterials'] != null) {
      List<dynamic> materials = data['complementaryMaterials'];
      for (var material in materials) {
        materialUrls.add(material['url'] ?? '');
        materialNames.add(material['name'] ?? '');
      }
    } else {
      materialUrls = List<String>.from(data['complementaryMaterialUrls'] ?? []);
      materialNames = List<String>.from(data['complementaryMaterialNames'] ?? []);
    }
    
    // Procesamiento de rating distribution
    Map<String, dynamic> ratingDist = {};
    if (data['ratingDistribution'] != null) {
      ratingDist = Map<String, dynamic>.from(data['ratingDistribution']);
    } else {
      // Inicializar con valores por defecto
      ratingDist = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    }
    
    return CourseLesson(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      moduleId: data['moduleId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      videoThumbnailUrl: data['videoThumbnailUrl'],
      duration: data['duration'] ?? 0,
      order: data['order'] ?? 0,
      complementaryMaterialUrls: materialUrls,
      complementaryMaterialNames: materialNames,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasComments: data['hasComments'] ?? true,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      ratingDistribution: ratingDist,
    );
  }

  Map<String, dynamic> toMap() {
    // Crear una lista de materiales complementarios
    List<Map<String, dynamic>> materials = [];
    for (int i = 0; i < complementaryMaterialUrls.length; i++) {
      String name = i < complementaryMaterialNames.length 
          ? complementaryMaterialNames[i] 
          : 'Material ${i + 1}';
      
      materials.add({
        'url': complementaryMaterialUrls[i],
        'name': name,
      });
    }
    
    return {
      'courseId': courseId,
      'moduleId': moduleId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'videoThumbnailUrl': videoThumbnailUrl,
      'duration': duration,
      'order': order,
      'complementaryMaterials': materials,
      'complementaryMaterialUrls': complementaryMaterialUrls,
      'complementaryMaterialNames': complementaryMaterialNames,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'hasComments': hasComments,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': ratingDistribution,
    };
  }

  // Método para crear una copia con algunos campos actualizados
  CourseLesson copyWith({
    String? courseId,
    String? moduleId,
    String? title,
    String? description,
    String? videoUrl,
    String? videoThumbnailUrl,
    int? duration,
    int? order,
    List<String>? complementaryMaterialUrls,
    List<String>? complementaryMaterialNames,
    DateTime? updatedAt,
    bool? hasComments,
    double? averageRating,
    int? totalRatings,
    Map<String, dynamic>? ratingDistribution,
  }) {
    return CourseLesson(
      id: this.id,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      videoThumbnailUrl: videoThumbnailUrl ?? this.videoThumbnailUrl,
      duration: duration ?? this.duration,
      order: order ?? this.order,
      complementaryMaterialUrls: complementaryMaterialUrls ?? this.complementaryMaterialUrls,
      complementaryMaterialNames: complementaryMaterialNames ?? this.complementaryMaterialNames,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasComments: hasComments ?? this.hasComments,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }
  
  // Método para extraer ID de YouTube
  String? get youtubeId {
    // Intentar extraer desde URL de YouTube regular
    final RegExp regExp1 = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
    );
    
    if (regExp1.hasMatch(videoUrl)) {
      return regExp1.firstMatch(videoUrl)?.group(7);
    }
    
    // Intentar extraer desde URL acortada youtu.be
    final RegExp regExp2 = RegExp(r'^.*(youtu.be\/|v\/|e\/|u\/\w+\/|embed\/|v=)([^#&?]*).*');
    
    if (regExp2.hasMatch(videoUrl)) {
      return regExp2.firstMatch(videoUrl)?.group(2);
    }
    
    return null;
  }
  
  // Método para verificar si el video es de YouTube
  bool get isYoutubeVideo {
    return videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be');
  }
  
  // Método para verificar si el video es de Vimeo
  bool get isVimeoVideo {
    return videoUrl.contains('vimeo.com');
  }
  
  // Método para extraer ID de Vimeo
  String? get vimeoId {
    final RegExp regExp = RegExp(
      r'\/([0-9]+)(?:\/|\?|$)',
    );
    
    if (regExp.hasMatch(videoUrl)) {
      return regExp.firstMatch(videoUrl)?.group(1);
    }
    
    return null;
  }
  
  // Método para obtener la URL de la miniatura del video si no está explícitamente definida
  String getVideoThumbnailUrl() {
    if (videoThumbnailUrl != null && videoThumbnailUrl!.isNotEmpty) {
      return videoThumbnailUrl!;
    }
    
    if (isYoutubeVideo && youtubeId != null) {
      return 'https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg';
    }
    
    // Para Vimeo se necesitaría una llamada a la API para obtener la miniatura
    // Aquí se devuelve una imagen de marcador de posición
    return 'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebase.com/o/assets%2Fvideo-placeholder.jpg?alt=media';
  }
} 