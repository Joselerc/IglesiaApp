import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Estilos de contenedores unificados
class AppContainerStyles {
  // Decoración estándar para tarjetas
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppSpacing.md),
    boxShadow: [
      BoxShadow(
        color: AppColors.mutedGray.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  // Decoración con fondo arena cálida
  static final BoxDecoration warmSandContainer = BoxDecoration(
    color: AppColors.warmSand,
    borderRadius: BorderRadius.circular(AppSpacing.md),
  );
  
  // Decoración con fondo dorado suave
  static final BoxDecoration softGoldAccent = BoxDecoration(
    color: AppColors.softGold.withOpacity(0.15),
    borderRadius: BorderRadius.circular(AppSpacing.sm),
  );
  
  // Decoración para contenedor destacado
  static final BoxDecoration highlightedContainer = BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppSpacing.md),
    border: Border.all(
      color: AppColors.primary.withOpacity(0.3),
      width: 1,
    ),
  );
  
  // Decoración para contenedor de borde sutil
  static final BoxDecoration subtleBorderContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppSpacing.md),
    border: Border.all(
      color: AppColors.mutedGray.withOpacity(0.3),
      width: 1,
    ),
  );
  
  // Decoración para sección de ajustes
  static final BoxDecoration settingsSection = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppSpacing.sm),
  );
} 