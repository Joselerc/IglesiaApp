import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class AdditionalFieldsSkeleton extends StatelessWidget {
  const AdditionalFieldsSkeleton({super.key});

  Widget _buildPlaceholderField(BuildContext context, Color color) {
    return Container(
      height: 40.0, // Altura típica para un campo de formulario en esta sección
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.sm), // Usar AppSpacing
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md), // Usar AppSpacing
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), // Padding para la sección
        child: Column(
          children: [
            _buildPlaceholderField(context, baseColor),
            _buildPlaceholderField(context, baseColor),
            _buildPlaceholderField(context, baseColor),
          ],
        ),
      ),
    );
  }
} 