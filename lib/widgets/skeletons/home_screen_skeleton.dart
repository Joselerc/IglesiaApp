import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart para consistencia

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;
    const double titleHeight = 20.0;
    const double titleWidthFactor = 0.4; // 40% del ancho para el título
    const double cardHeight = 120.0;
    const double cardWidth = 150.0;
    const double gridItemSize = 80.0;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.md, // Usar AppSpacing si está definido
          bottom: AppSpacing.xxl, // Usar AppSpacing si está definido
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        children: [
          // Placeholder para la sección de "banner" o anuncios (una tarjeta grande)
          _buildPlaceholderTitle(context, titleHeight, titleWidthFactor, baseColor),
          const SizedBox(height: AppSpacing.sm),
          _buildPlaceholderContainer(context, 150, double.infinity, baseColor),
          const SizedBox(height: AppSpacing.xl),

          // Placeholder para una sección de tarjetas horizontales (ej. Cultos)
          _buildPlaceholderTitle(context, titleHeight, titleWidthFactor * 0.8, baseColor),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) =>
                  _buildPlaceholderContainer(context, cardHeight, cardWidth, baseColor),
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Placeholder para una sección de cuadrícula (ej. Servicios)
          _buildPlaceholderTitle(context, titleHeight, titleWidthFactor * 0.7, baseColor),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) =>
                _buildPlaceholderContainer(context, gridItemSize, double.infinity, baseColor),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Placeholder para otra sección de tarjetas horizontales (ej. Eventos)
          _buildPlaceholderTitle(context, titleHeight, titleWidthFactor * 0.8, baseColor),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 2,
              itemBuilder: (context, index) =>
                  _buildPlaceholderContainer(context, cardHeight, cardWidth * 1.2, baseColor),
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTitle(BuildContext context, double height, double widthFactor, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        width: MediaQuery.of(context).size.width * widthFactor,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.sm / 2),
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs), // Margen para el título
      ),
    );
  }

  Widget _buildPlaceholderContainer(
      BuildContext context, double height, double width, Color color, {bool isCircle = false}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isCircle ? height / 2 : AppSpacing.md),
      ),
    );
  }
} 