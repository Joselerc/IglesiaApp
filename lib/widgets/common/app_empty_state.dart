import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import 'app_button.dart';

/// Estado vacío o de error con estilo unificado
class AppEmptyState extends StatelessWidget {
  /// Título del estado vacío
  final String title;
  
  /// Mensaje descriptivo
  final String message;
  
  /// Icono a mostrar
  final IconData icon;
  
  /// Texto del botón de acción
  final String? buttonText;
  
  /// Acción al presionar el botón
  final VoidCallback? onButtonPressed;
  
  /// Si tiene borde
  final bool hasBorder;
  
  /// Color del icono
  final Color? iconColor;
  
  /// Tamaño del icono
  final double iconSize;
  
  /// Padding personalizado
  final EdgeInsetsGeometry padding;
  
  /// Imagen alternativa
  final Widget? imageWidget;

  const AppEmptyState({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.buttonText,
    this.onButtonPressed,
    this.hasBorder = false,
    this.iconColor,
    this.iconSize = 64,
    this.padding = const EdgeInsets.all(24),
    this.imageWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      decoration: hasBorder
          ? BoxDecoration(
              border: Border.all(
                color: AppColors.mutedGray.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.md),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (imageWidget != null)
            imageWidget!
          else
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.secondary,
            ),
          AppSpacing.verticalSpacerMD,
          Text(
            title,
            style: AppTextStyles.headline3,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSpacerSM,
          Text(
            message,
            style: AppTextStyles.bodyText2,
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            AppSpacing.verticalSpacerLG,
            AppButton(
              text: buttonText!,
              onPressed: onButtonPressed,
              icon: Icons.add,
            ),
          ],
        ],
      ),
    );
    
    return Center(
      child: SingleChildScrollView(
        child: container,
      ),
    );
  }
  
  /// Constructor para estado sin elementos
  factory AppEmptyState.noItems({
    required String itemName,
    required String message,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return AppEmptyState(
      title: 'No hay $itemName',
      message: message,
      icon: Icons.inbox,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
  
  /// Constructor para estado de error
  factory AppEmptyState.error({
    String title = 'Error',
    required String message,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: Icons.error_outline,
      iconColor: AppColors.error,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
  
  /// Constructor para estado de búsqueda sin resultados
  factory AppEmptyState.noSearchResults({
    String title = 'Sin resultados',
    String message = 'No se encontraron resultados para tu búsqueda.',
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: Icons.search_off,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
} 