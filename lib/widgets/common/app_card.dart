import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_container_styles.dart';

/// Tarjeta reutilizable con estilos consistentes
class AppCard extends StatelessWidget {
  /// Contenido de la tarjeta
  final Widget child;
  
  /// Padding interno
  final EdgeInsetsGeometry padding;
  
  /// Acción al tocar la tarjeta
  final VoidCallback? onTap;
  
  /// Usar fondo arena
  final bool useSandBackground;
  
  /// Usar fondo dorado suave
  final bool useGoldBackground;
  
  /// Usar estilo destacado
  final bool isHighlighted;
  
  /// Margen externo
  final EdgeInsetsGeometry margin;
  
  /// Elevación de la tarjeta
  final double elevation;
  
  /// Altura personalizada
  final double? height;
  
  /// Ancho personalizado
  final double? width;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.useSandBackground = false,
    this.useGoldBackground = false,
    this.isHighlighted = false,
    this.margin = const EdgeInsets.all(0),
    this.elevation = 1,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determinar la decoración según el tipo
    BoxDecoration decoration;
    
    if (isHighlighted) {
      decoration = AppContainerStyles.highlightedContainer;
    } else if (useSandBackground) {
      decoration = AppContainerStyles.warmSandContainer;
    } else if (useGoldBackground) {
      decoration = AppContainerStyles.softGoldAccent;
    } else {
      decoration = AppContainerStyles.cardDecoration.copyWith(
        boxShadow: elevation > 0 
            ? [
                BoxShadow(
                  color: AppColors.mutedGray.withOpacity(0.1 * elevation),
                  blurRadius: 4.0 * elevation,
                  offset: Offset(0, 2 * elevation),
                ),
              ]
            : null,
      );
    }
    
    Widget cardContent = Container(
      height: height,
      width: width,
      margin: margin,
      decoration: decoration,
      padding: padding,
      child: child,
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: cardContent,
      );
    }
    
    return cardContent;
  }
} 