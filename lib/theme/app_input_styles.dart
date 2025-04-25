import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// Estilos de inputs unificados
class AppInputStyles {
  // Decoración para campos de texto
  static InputDecoration textFieldDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: AppTextStyles.bodyText2,
      hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.mutedGray),
      helperStyle: AppTextStyles.caption,
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      contentPadding: AppSpacing.inputPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        borderSide: BorderSide(color: AppColors.mutedGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        borderSide: BorderSide(color: AppColors.mutedGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
  
  // Decoración para campos de búsqueda
  static InputDecoration searchFieldDecoration({
    String hintText = 'Buscar...',
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon ?? Icon(Icons.search, color: AppColors.mutedGray),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.warmSand.withOpacity(0.5),
      hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.mutedGray),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        borderSide: BorderSide(color: AppColors.primary, width: 1),
      ),
    );
  }
  
  // Decoración para campos de textarea
  static InputDecoration textAreaDecoration({
    required String labelText,
    String? hintText,
  }) {
    return textFieldDecoration(
      labelText: labelText,
      hintText: hintText,
    ).copyWith(
      alignLabelWithHint: true,
      contentPadding: EdgeInsets.all(AppSpacing.md),
    );
  }
} 