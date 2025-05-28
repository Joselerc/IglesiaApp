import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class PrayerCardSkeleton extends StatelessWidget {
  const PrayerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white, // El Shimmer se aplica sobre esto
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: baseColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder para la fecha/estado en la parte superior
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 10.0,
                  width: MediaQuery.of(context).size.width * 0.25,
                  color: baseColor,
                ),
                Container(
                  height: 10.0,
                  width: MediaQuery.of(context).size.width * 0.15,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Placeholder para el contenido de la oración (varias líneas)
            Container(
              height: 12.0,
              width: double.infinity,
              color: baseColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 12.0,
              width: MediaQuery.of(context).size.width * 0.8,
              color: baseColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 12.0,
              width: MediaQuery.of(context).size.width * 0.6,
              color: baseColor,
            ),
            // Podrías añadir más líneas si las tarjetas suelen ser más largas
            const SizedBox(height: AppSpacing.md),
            // Placeholder para acciones o respuesta del pastor (si aplica)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 20.0, // Un poco más alto para simular un botón/área de respuesta
                  width: MediaQuery.of(context).size.width * 0.2,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
} 