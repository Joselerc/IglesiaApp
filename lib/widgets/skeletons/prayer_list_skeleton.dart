import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import './prayer_card_skeleton.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class PrayerListSkeleton extends StatelessWidget {
  final int itemCount;

  const PrayerListSkeleton({super.key, this.itemCount = 4}); // Un poco menos que ListTabContentSkeleton por defecto

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md), // Padding general para la lista
        itemCount: itemCount,
        itemBuilder: (context, index) => const PrayerCardSkeleton(),
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      ),
    );
  }
} 