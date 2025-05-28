import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;
    const double aspectRatio = 16 / 9;

    return SizedBox(
      width: 240, // Ancho similar al VideoCard real
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0, // Sin elevación para el skeleton
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md), // Usar AppSpacing
        ),
        clipBehavior: Clip.antiAlias,
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder para la miniatura
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  color: baseColor,
                ),
              ),
              // Placeholder para el título y fecha
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm), // Usar AppSpacing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10.0,
                      width: double.infinity,
                      color: baseColor,
                    ),
                    const SizedBox(height: AppSpacing.xs), // Usar AppSpacing
                    Container(
                      height: 8.0,
                      width: MediaQuery.of(context).size.width * 0.3,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 