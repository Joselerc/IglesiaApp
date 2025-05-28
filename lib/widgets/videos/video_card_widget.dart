import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../screens/videos/video_details_screen.dart';
import '../../theme/app_colors.dart'; // Para colores si los usas directamente
import '../../theme/app_text_styles.dart'; // Para estilos de texto si los usas
import '../../utils/date_formatter.dart'; // Asumiendo que movemos _formatDate a una utilidad

class VideoCardWidget extends StatelessWidget {
  final Video video;

  const VideoCardWidget({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 2),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailsScreen(video: video),
            ),
          );
        },
        child: SizedBox(
          width: 240,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, size: 32, color: Colors.white54),
                            ),
                          );
                        },
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primary, // Usar color primario
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Vídeo', // Placeholder temporal
                              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatDate(video.uploadDate),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 