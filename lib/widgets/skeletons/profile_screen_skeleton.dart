import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  Widget _buildPlaceholderText(BuildContext context, double height, double widthFactor, Color color, {double maxWidth = double.infinity}) {
    return Container(
      height: height,
      width: (MediaQuery.of(context).size.width * widthFactor).clamp(0, maxWidth),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    );
  }

  Widget _buildPlaceholderField(BuildContext context, Color color, {double height = 50.0}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
    );
  }

  Widget _buildSectionHeader(BuildContext context, Color color, {double titleWidthFactor = 0.5}) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
      child: _buildPlaceholderText(context, 20, titleWidthFactor, color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con imagen de perfil, nombre y email
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPlaceholderText(context, 20, 0.6, baseColor, maxWidth: 200),
                  const SizedBox(height: AppSpacing.xs),
                  _buildPlaceholderText(context, 14, 0.4, baseColor, maxWidth: 150),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Sección de Información Personal
            _buildSectionHeader(context, baseColor, titleWidthFactor: 0.4),
            _buildPlaceholderField(context, baseColor),
            _buildPlaceholderField(context, baseColor),
            _buildPlaceholderField(context, baseColor),
            _buildPlaceholderField(context, baseColor),
            _buildPlaceholderField(context, baseColor), // Para el teléfono

            // Sección de Información Adicional
            _buildSectionHeader(context, baseColor, titleWidthFactor: 0.5),
            _buildPlaceholderField(context, baseColor, height: 40),
            _buildPlaceholderField(context, baseColor, height: 40),
            _buildPlaceholderField(context, baseColor, height: 40),
            
            // Sección de Participación (Ministerios/Grupos)
            _buildSectionHeader(context, baseColor, titleWidthFactor: 0.3),
            _buildPlaceholderField(context, baseColor, height: 60), // Para la tarjeta de ministerio/grupo
            const SizedBox(height: AppSpacing.md),
            _buildPlaceholderField(context, baseColor, height: 60), // Para la tarjeta de ministerio/grupo
            
            // Placeholder opcional para la sección de administración (muy genérico)
            _buildSectionHeader(context, baseColor, titleWidthFactor: 0.45),
            _buildPlaceholderField(context, baseColor, height: 30),
            _buildPlaceholderField(context, baseColor, height: 30),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
} 