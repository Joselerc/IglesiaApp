import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import './list_item_card_skeleton.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class ListTabContentSkeleton extends StatelessWidget {
  final int itemCount;

  const ListTabContentSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const ListItemCardSkeleton(),
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      ),
    );
  }
} 