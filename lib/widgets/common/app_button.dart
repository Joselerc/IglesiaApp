import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Botón reutilizable con estilos consistentes
class AppButton extends StatelessWidget {
  /// Texto a mostrar en el botón
  final String text;
  
  /// Acción a ejecutar al presionar el botón
  final VoidCallback? onPressed;
  
  /// Si es true, usará el color secundario en lugar del primario
  final bool isSecondary;
  
  /// Si es true, usará el estilo de botón outline en lugar del relleno
  final bool isOutlined;
  
  /// Si es true, usará un tamaño más pequeño
  final bool isSmall;
  
  /// Icono opcional para mostrar junto al texto
  final IconData? icon;
  
  /// Posición del icono (antes o después del texto)
  final bool iconAfterText;
  
  /// Ancho completo o ajustado al contenido
  final bool fullWidth;
  
  /// Color de fondo personalizado (opcional)
  final Color? backgroundColor;
  
  /// Tema personalizado (opcional)
  final ButtonStyle? customStyle;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.icon,
    this.iconAfterText = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.customStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Configurar estilo y contenido
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: isSmall ? 12.0 : 20.0,
      vertical: isSmall ? 8.0 : 12.0,
    );
    
    final buttonTextStyle = isSmall
        ? AppTextStyles.button.copyWith(fontSize: 14)
        : AppTextStyles.button;
    
    // Determinar el color base
    final Color baseColor = backgroundColor ?? 
        (isSecondary ? AppColors.secondary : AppColors.primary);
    
    // Construir el contenido del botón
    Widget buttonContent = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (icon != null && !iconAfterText) ...[
          Icon(
            icon, 
            size: isSmall ? 16 : 20, 
            // Asegurar que el icono sea blanco en botones no outline
            color: isOutlined ? null : Colors.white,
          ),
          SizedBox(width: 8),
        ],
        Text(
          text,
          style: buttonTextStyle,
        ),
        if (icon != null && iconAfterText) ...[
          SizedBox(width: 8),
          Icon(
            icon, 
            size: isSmall ? 16 : 20, 
            // Asegurar que el icono sea blanco en botones no outline
            color: isOutlined ? null : Colors.white,
          ),
        ],
      ],
    );
    
    // Construir el botón según el tipo
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: customStyle ?? OutlinedButton.styleFrom(
          foregroundColor: baseColor,
          side: BorderSide(color: baseColor),
          padding: buttonPadding,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: buttonContent,
      );
    }
    
    return ElevatedButton(
      onPressed: onPressed,
      style: customStyle ?? ElevatedButton.styleFrom(
        backgroundColor: baseColor,
        foregroundColor: AppColors.textOnDark,
        padding: buttonPadding,
        textStyle: buttonTextStyle,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: buttonContent,
    );
  }
} 