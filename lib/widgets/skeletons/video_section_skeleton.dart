import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import './video_card_skeleton.dart';
import '../../theme/app_spacing.dart'; // Asumiendo que tienes app_spacing.dart

class VideoSectionSkeleton extends StatelessWidget {
  final bool showTitle;
  final int itemCount;
  final String? titlePlaceholderText;

  const VideoSectionSkeleton({
    super.key,
    this.showTitle = true,
    this.itemCount = 3,
    this.titlePlaceholderText,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey[300]!;
    final Color highlightColor = Colors.grey[100]!;
    const double titleHeight = 20.0;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm
              ),
              child: titlePlaceholderText != null && titlePlaceholderText!.isNotEmpty
                  ? Text(
                      titlePlaceholderText!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    )
                  : Container(
                      height: titleHeight,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(AppSpacing.xs),
                      ),
                    ),
            ),
          SizedBox(
            height: 192, // Altura similar a la sección real de videos
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md, bottom: AppSpacing.xs / 2), // Ajustado aquí
                  child: const VideoCardSkeleton(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 