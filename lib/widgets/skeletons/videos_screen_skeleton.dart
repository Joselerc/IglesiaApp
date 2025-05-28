import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import './video_section_skeleton.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class VideosScreenSkeleton extends StatelessWidget {
  const VideosScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl, top: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            VideoSectionSkeleton(),
            SizedBox(height: AppSpacing.lg), // Espacio entre secciones
            VideoSectionSkeleton(),
            SizedBox(height: AppSpacing.lg),
            VideoSectionSkeleton(itemCount: 2), // Mostrar menos items en la tercera sección por variedad
          ],
        ),
      ),
    );
  }
} 