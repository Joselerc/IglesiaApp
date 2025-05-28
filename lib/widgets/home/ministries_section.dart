import 'package:flutter/material.dart';
import '../../screens/ministries/ministries_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../common/app_card.dart';

class MinistriesSection extends StatelessWidget {
  final String displayTitle;
  
  const MinistriesSection({
    super.key,
    this.displayTitle = 'Ministérios',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            displayTitle,
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MinistriesListScreen(),
                ),
              );
            },
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmSand,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.people_outline,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ministérios',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Participe dos ministérios da igreja',
                        style: AppTextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 