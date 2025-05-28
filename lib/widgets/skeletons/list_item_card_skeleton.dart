import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class ListItemCardSkeleton extends StatelessWidget {
  const ListItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;
    const double cardHeight = 90.0; // Altura aproximada de MinistryCard/GroupCard

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: cardHeight,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white, // El Shimmer se aplica sobre esto
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: baseColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Placeholder para el ícono/avatar
            Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Placeholder para título y subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12.0,
                    width: MediaQuery.of(context).size.width * 0.4,
                    color: baseColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 10.0,
                    width: MediaQuery.of(context).size.width * 0.3,
                    color: baseColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Placeholder para un botón/acción (opcional)
            Container(
              width: 60.0,
              height: 30.0,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 