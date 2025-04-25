import 'package:flutter/material.dart';

/// Sistema de espaciado unificado para toda la aplicación
class AppSpacing {
  // Espaciado base (4 píxeles)
  static const double base = 4.0;
  
  // Multiplicadores comunes
  static const double xs = base; // 4px
  static const double sm = base * 2; // 8px
  static const double md = base * 4; // 16px
  static const double lg = base * 6; // 24px
  static const double xl = base * 8; // 32px
  static const double xxl = base * 12; // 48px
  
  // Padding estándar para contenedores
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  
  // Separadores verticales
  static const Widget verticalSpacerXS = SizedBox(height: xs);
  static const Widget verticalSpacerSM = SizedBox(height: sm);
  static const Widget verticalSpacerMD = SizedBox(height: md);
  static const Widget verticalSpacerLG = SizedBox(height: lg);
  static const Widget verticalSpacerXL = SizedBox(height: xl);
  
  // Separadores horizontales
  static const Widget horizontalSpacerXS = SizedBox(width: xs);
  static const Widget horizontalSpacerSM = SizedBox(width: sm);
  static const Widget horizontalSpacerMD = SizedBox(width: md);
  static const Widget horizontalSpacerLG = SizedBox(width: lg);
  static const Widget horizontalSpacerXL = SizedBox(width: xl);
}

/// Radios de bordes consistentes
class AppBorderRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;
  
  static final BorderRadius buttonRadius = BorderRadius.circular(medium);
  static final BorderRadius cardRadius = BorderRadius.circular(medium);
  static final BorderRadius inputRadius = BorderRadius.circular(small);
} 