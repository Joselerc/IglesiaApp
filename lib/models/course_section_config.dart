import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      title: data['title'] ?? 'Cursos', // Se traduce en la UI con AppLocalizations
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
  // Nota: Los textos se traducen en la UI con AppLocalizations
  static CourseSectionConfig createDefault({String? userId}) {
    return CourseSectionConfig(
      id: '',
      title: 'onlineCourses', // Clave de traducción
      subtitle: 'learnWithOurExclusiveCourses', // Clave de traducción
      backgroundImageUrl: null,
      cardBackgroundColor: null, // Usa AppColors.primary por defecto
      cardTextColor: null, // Usa blanco por defecto
      isActive: true,
      updatedAt: DateTime.now(),
      updatedBy: userId,
      order: 99,
    );
  }

  // Método para obtener el color de fondo como un entero (para Flutter)
  int getBackgroundColorValue() {
    if (cardBackgroundColor == null || !cardBackgroundColor!.startsWith('#')) {
      return AppColors.primary.value; // Usa el color primario de la app
    }
    
    try {
      String hex = cardBackgroundColor!.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF' + hex; // Añadir opacidad total
      }
      return int.parse('0x$hex');
    } catch (e) {
      return AppColors.primary.value; // Usa el color primario en caso de error
    }
  }

  // Método para obtener el color de texto como un entero (para Flutter)
  int getTextColorValue() {
    if (cardTextColor == null || !cardTextColor!.startsWith('#')) {
      return Colors.white.value; // Blanco por defecto
    }
    
    try {
      String hex = cardTextColor!.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF' + hex; // Añadir opacidad total
      }
      return int.parse('0x$hex');
    } catch (e) {
      return Colors.white.value; // Blanco por defecto en caso de error
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