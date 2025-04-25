import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto unificados para toda la aplicación
class AppTextStyles {
  static const String fontFamily = 'Poppins';
  
  // Títulos
  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  // Subtítulos
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Cuerpo de texto
  static const TextStyle bodyText1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    color: AppColors.textSecondary,
  );
  
  // Etiquetas y botones
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.textOnDark,
  );
  
  // Etiquetas pequeñas
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    color: AppColors.textSecondary,
  );
  
  // Texto con énfasis
  static TextStyle get emphasized => bodyText1.copyWith(
    fontWeight: FontWeight.w600,
  );
  
  // Texto para fecha/tiempo
  static TextStyle get dateTime => caption.copyWith(
    fontStyle: FontStyle.italic,
  );
} 