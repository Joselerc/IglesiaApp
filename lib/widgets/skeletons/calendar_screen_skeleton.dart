import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo app_spacing.dart
import '../../theme/app_colors.dart'; // Para colores de pestañas y header

class CalendarScreenSkeleton extends StatelessWidget {
  const CalendarScreenSkeleton({super.key});

  Widget _buildPlaceholderContainer(BuildContext context, double height, double width, Color color, {double borderRadius = AppSpacing.sm}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;
    final Color headerColor = AppColors.primary.withOpacity(0.8);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          // Placeholder para el AppBar y TabBar
          Container(
            padding: const EdgeInsets.only(top: kToolbarHeight / 2, bottom: AppSpacing.sm), // Aproximar altura de SafeArea y AppBar
            decoration: BoxDecoration(
              color: headerColor, // Usar un color similar al AppBar real
            ),
            child: Column(
              children: [
                // Placeholder para el título "Calendários" y botón de atrás
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      _buildPlaceholderContainer(context, 24, 24, Colors.white.withOpacity(0.5)), // Icono
                      const SizedBox(width: AppSpacing.md),
                      _buildPlaceholderContainer(context, 20, 120, Colors.white.withOpacity(0.7)), // Título
                    ],
                  ),
                ),
                // Placeholder para las pestañas
                SizedBox(
                  height: 48, // Altura típica de TabBar
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: 6, // Número de pestañas
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: _buildPlaceholderContainer(context, 20, 70, Colors.white.withOpacity(0.5), borderRadius: AppSpacing.xs),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Placeholder para el TableCalendar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildPlaceholderContainer(context, 300, double.infinity, baseColor, borderRadius: AppSpacing.md),
          ),

          // Placeholder para la fecha seleccionada
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: _buildPlaceholderContainer(context, 40, double.infinity, baseColor.withOpacity(0.5), borderRadius: AppSpacing.md),
          ),

          // Placeholder para la lista de eventos del día
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 3, // Mostrar algunos items de esqueleto para la lista
              itemBuilder: (context, index) => _buildPlaceholderContainer(context, 60, double.infinity, baseColor),
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
            ),
          ),
        ],
      ),
    );
  }
} 