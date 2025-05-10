import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSectionConfig {
  final String id;
  final String title;
  final String? subtitle;
  final String? backgroundImageUrl;
  final String? cardBackgroundColor;
  final String? cardTextColor;
  final bool isActive;
  final DateTime updatedAt;
  final String? updatedBy;
  final int order;

  CourseSectionConfig({
    required this.id,
    required this.title,
    this.subtitle,
    this.backgroundImageUrl,
    this.cardBackgroundColor,
    this.cardTextColor,
    required this.isActive,
    required this.updatedAt,
    this.updatedBy,
    required this.order,
  });

  factory CourseSectionConfig.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CourseSectionConfig(
      id: doc.id,
      title: data['title'] ?? 'Cursos',
      subtitle: data['subtitle'],
      backgroundImageUrl: data['backgroundImageUrl'],
      cardBackgroundColor: data['cardBackgroundColor'],
      cardTextColor: data['cardTextColor'],
      isActive: data['isActive'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'],
      order: data['order'] ?? 99, // Valor alto para que aparezca al final por defecto
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'backgroundImageUrl': backgroundImageUrl,
      'cardBackgroundColor': cardBackgroundColor,
      'cardTextColor': cardTextColor,
      'isActive': isActive,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'order': order,
    };
  }

  // Método para crear una configuración por defecto
  static CourseSectionConfig createDefault({String? userId}) {
    return CourseSectionConfig(
      id: '',
      title: 'Cursos Online',
      subtitle: 'Aprenda com os nossos cursos exclusivos',
      backgroundImageUrl: null,
      cardBackgroundColor: '#FFA726', // Color naranja claro
      cardTextColor: '#FFFFFF', // Texto blanco
      isActive: true,
      updatedAt: DateTime.now(),
      updatedBy: userId,
      order: 99,
    );
  }

  // Método para obtener el color de fondo como un entero (para Flutter)
  int getBackgroundColorValue() {
    if (cardBackgroundColor == null || !cardBackgroundColor!.startsWith('#')) {
      return 0xFFFFA726; // Naranja por defecto
    }
    
    try {
      String hex = cardBackgroundColor!.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF' + hex; // Añadir opacidad total
      }
      return int.parse('0x$hex');
    } catch (e) {
      return 0xFFFFA726; // Naranja por defecto en caso de error
    }
  }

  // Método para obtener el color de texto como un entero (para Flutter)
  int getTextColorValue() {
    if (cardTextColor == null || !cardTextColor!.startsWith('#')) {
      return 0xFFFFFFFF; // Blanco por defecto
    }
    
    try {
      String hex = cardTextColor!.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF' + hex; // Añadir opacidad total
      }
      return int.parse('0x$hex');
    } catch (e) {
      return 0xFFFFFFFF; // Blanco por defecto en caso de error
    }
  }

  CourseSectionConfig copyWith({
    String? title,
    String? subtitle,
    String? backgroundImageUrl,
    String? cardBackgroundColor,
    String? cardTextColor,
    bool? isActive,
    DateTime? updatedAt,
    String? updatedBy,
    int? order,
  }) {
    return CourseSectionConfig(
      id: this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      cardTextColor: cardTextColor ?? this.cardTextColor,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      order: order ?? this.order,
    );
  }
} 