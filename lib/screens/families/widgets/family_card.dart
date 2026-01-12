import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class FamilyCard extends StatelessWidget {
  const FamilyCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.badge,
    this.badgeColor,
    this.icon = Icons.family_restroom_outlined,
    this.surfaceTint,
    this.photoUrl,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 2,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? badge;
  final Color? badgeColor;
  final IconData icon;
  final Color? surfaceTint;
  final String? photoUrl;
  final int titleMaxLines;
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: surfaceTint ?? colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? Icon(
                        icon,
                        color: colorScheme.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: titleMaxLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor ?? colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: AppTextStyles.caption.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
