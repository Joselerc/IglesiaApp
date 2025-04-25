// ARCHIVO DE GUÍA DE DISEÑO
// Este archivo sirve como referencia para todo el rediseño de la aplicación.

import 'package:flutter/material.dart';

/// GUÍA DE COLORES
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFFE94F1A); // Naranja
  static const Color secondary = Color(0xFF627E6E); // Verde Sage
  
  // Colores de acento
  static const Color warmSand = Color(0xFFF3E8DD); // Arena cálida
  static const Color terracotta = Color(0xFFC1421A); // Terracota
  static const Color softGold = Color(0xFFD9A441); // Dorado suave
  
  // Colores neutrales
  static const Color background = Color(0xFFFAF9F6); // Crema claro
  static const Color surface = Colors.white;
  static const Color charcoal = Color(0xFF2F2F2F); // Carbón
  static const Color mutedGray = Color(0xFFB8B8B8); // Gris apagado
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF2F2F2F);
  static const Color textSecondary = Color(0xFF627E6E);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // Estados funcionales
  static const Color error = Color(0xFFC1421A);
  static const Color success = Color(0xFF627E6E);
}

/// GUÍA DE TIPOGRAFÍA
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
  
  // Subtítulos
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
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
}

/// GUÍA DE ESPACIADO
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
}

/// GUÍA DE BORDES
class AppBorderRadius {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 16.0;
  
  static final BorderRadius buttonRadius = BorderRadius.circular(medium);
  static final BorderRadius cardRadius = BorderRadius.circular(medium);
  static final BorderRadius inputRadius = BorderRadius.circular(small);
}

/// GUÍA DE BOTONES
class AppButtonStyles {
  // Botón primario (naranja)
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnDark,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    ),
    elevation: 1,
  );
  
  // Botón secundario (verde sage)
  static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.textOnDark,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    ),
    elevation: 1,
  );
  
  // Botón outline
  static final ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: BorderSide(color: AppColors.primary),
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
    ),
  );
  
  // Botón de texto
  static final ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  );
}

/// GUÍA DE CONTENEDORES
class AppContainerStyles {
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
  
  static final BoxDecoration warmSandContainer = BoxDecoration(
    color: AppColors.warmSand,
    borderRadius: BorderRadius.circular(AppSpacing.md),
  );
  
  static final BoxDecoration softGoldAccent = BoxDecoration(
    color: AppColors.softGold.withOpacity(0.15),
    borderRadius: BorderRadius.circular(AppSpacing.sm),
  );
}

/// GUÍA DE INPUTS Y FORMULARIOS
class AppInputStyles {
  static InputDecoration textFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: AppTextStyles.bodyText2,
      hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.mutedGray),
      contentPadding: AppSpacing.inputPadding,
      border: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: BorderSide(color: AppColors.mutedGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: BorderSide(color: AppColors.mutedGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.inputRadius,
        borderSide: BorderSide(color: AppColors.error),
      ),
    );
  }
}

/// GUÍA DE MENSAJES Y NOTIFICACIONES
class AppNotificationStyles {
  // Mensaje de éxito
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message, style: AppTextStyles.bodyText2.copyWith(color: AppColors.textOnDark)),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
    );
  }
  
  // Mensaje de error
  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message, style: AppTextStyles.bodyText2.copyWith(color: AppColors.textOnDark)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
    );
  }
  
  // Diálogo de confirmación
  static Widget confirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) {
    return AlertDialog(
      title: Text(title, style: AppTextStyles.headline2),
      content: Text(message, style: AppTextStyles.bodyText1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: AppButtonStyles.textButton,
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: AppButtonStyles.primaryButton,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// PLAN DE IMPLEMENTACIÓN
/*
PASOS PARA IMPLEMENTAR EL NUEVO DISEÑO:

1. Configuración inicial
   - Añadir fuente Poppins a pubspec.yaml
   - Crear estructura de directorios para theme y widgets comunes
   - Dividir el archivo design_guide.dart en archivos individuales

2. Implementar tema central
   - Crear app_theme.dart que importe todos los estilos
   - Configurar ThemeData en main.dart

3. Crear widgets reutilizables
   - AppButton, AppCard, AppTextField, AppDialog, etc.
   - Crear una carpeta widgets/common/ para estos componentes

4. Rediseñar por prioridad
   - Pantallas principales primero (login, home, perfil)
   - Pantallas secundarias después
   - Componentes comunes entre pantallas

5. Testing y revisión
   - Revisar consistencia visual
   - Validar accesibilidad
   - Resolver detalles (dark mode si aplica)

6. Documentación final
   - Actualizar README con guía de uso del sistema de diseño
   - Crear una pantalla de referencia para mostrar componentes
*/ 