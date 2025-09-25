import 'package:flutter/material.dart';

/// Colores definidos para toda la aplicación
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF1E6FF2); // Azul principal
  static const Color secondary = Color(0xFFF5F7FA); // Gris azulado claro
  
  // --- Colores antiguos remapeados para compatibilidad ---
  static const Color warmSand = Color(0xFFDDE2E8); // Mapeado desde el antiguo 'Arena cálida' al nuevo 'Gris claro' (accentLight)
  static const Color terracotta = Color(0xFFD32F2F); // Mapeado desde el antiguo 'Terracota' al nuevo 'Rojo para errores'
  static const Color softGold = Color(0xFF90A4AE); // Mapeado desde el antiguo 'Dorado suave' al nuevo 'Gris azulado' (accent)
  // --- Fin de colores remapeados ---

  // Colores de acento
  static const Color accent = Color(0xFF90A4AE); // Gris azulado
  static const Color primaryDark = Color(0xFF0D47A1); // Azul oscuro
  static const Color accentLight = Color(0xFFDDE2E8); // Gris claro
  
  // Colores neutrales
  static const Color background = Color(0xFFF5F7FA); // Fondo gris azulado claro
  static const Color surface = Colors.white;
  static const Color charcoal = Color(0xFF2F2F2F); // Carbón (para texto principal)
  static const Color mutedGray = Color(0xFFB8B8B8); // Gris apagado
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF2F2F2F);
  static const Color textSecondary = Color(0xFF607D8B); // Gris azulado para texto secundario
  static const Color textOnDark = Color(0xFFFFFFFF); // Texto sobre fondos oscuros (ej. primario)
  
  // Estados funcionales
  static const Color error = Color(0xFFD32F2F); // Rojo para errores
  static const Color success = Color(0xFF388E3C); // Verde para éxito
} 