import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

/// Título de sección con estilo unificado
class AppSectionTitle extends StatelessWidget {
  /// Texto del título
  final String title;
  
  /// Texto de acción opcional
  final String? actionText;
  
  /// Acción opcional al presionar
  final VoidCallback? onActionPressed;
  
  /// Si tiene línea inferior
  final bool hasDivider;
  
  /// Padding personalizado
  final EdgeInsetsGeometry padding;
  
  /// Alineación del título
  final CrossAxisAlignment alignment;
  
  /// Estilo personalizado para el título
  final TextStyle? titleStyle;
  
  /// Widget adicional después del título
  final Widget? trailing;
  
  /// Si se muestra un icono de flecha para la acción
  final bool showActionArrow;

  const AppSectionTitle({
    Key? key,
    required this.title,
    this.actionText,
    this.onActionPressed,
    this.hasDivider = true,
    this.padding = const EdgeInsets.only(bottom: 12),
    this.alignment = CrossAxisAlignment.start,
    this.titleStyle,
    this.trailing,
    this.showActionArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: titleStyle ?? AppTextStyles.headline3,
                ),
              ),
              if (trailing != null) trailing!,
              if (actionText != null && onActionPressed != null) ...[
                TextButton(
                  onPressed: onActionPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText!,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                      if (showActionArrow) ...[
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (hasDivider) ...[
            AppSpacing.verticalSpacerXS,
            Divider(
              color: AppColors.mutedGray.withOpacity(0.3),
              height: 1,
            ),
          ],
        ],
      ),
    );
  }
} 