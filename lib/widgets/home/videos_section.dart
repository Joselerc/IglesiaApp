import 'package:flutter/material.dart';
import '../../screens/videos/videos_preview_section.dart'; // Importa el widget existente
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class VideosSection extends StatelessWidget {
  const VideosSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vídeos',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/videos');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Ver mais',
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const VideosPreviewSection(), // Usa el widget existente
      ],
    );
  }
} 