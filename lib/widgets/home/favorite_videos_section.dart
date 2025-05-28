import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/video.dart';
import '../../widgets/skeletons/video_section_skeleton.dart';
import '../../theme/app_colors.dart';
import '../videos/video_card_widget.dart'; // IMPORTAR VideoCardWidget

class FavoriteVideosSection extends StatefulWidget {
  final String userId;
  const FavoriteVideosSection({super.key, required this.userId});

  @override
  State<FavoriteVideosSection> createState() => _FavoriteVideosSectionState();
}

class _FavoriteVideosSectionState extends State<FavoriteVideosSection> {
  // Cache para evitar reconstrucciones innecesarias
  List<Video>? _cachedVideos;
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .where('likedByUsers', arrayContains: widget.userId)
          .limit(10) // Limitar resultados para mejor performance
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedVideos == null) {
          return const VideoSectionSkeleton(
            showTitle: true, 
            itemCount: 2, 
            titlePlaceholderText: 'Meus Favoritos'
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error en StreamBuilder de FavoriteVideosSection: ${snapshot.error}');
          // Mostrar cache si hay error y tenemos datos previos
          if (_cachedVideos != null && _cachedVideos!.isNotEmpty) {
            return _buildVideoSection(_cachedVideos!);
          }
          return const SizedBox.shrink(); 
        }

        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
          // Limpiar cache si no hay datos
          _cachedVideos = null;
          return const SizedBox.shrink();
        }

        try {
        final videos = snapshot.data!.docs
              .map((doc) {
                try {
                  return Video.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error al procesar video ${doc.id}: $e');
                  return null;
                }
              })
              .where((video) => video != null)
              .cast<Video>()
            .toList();

          // Actualizar cache solo si hay cambios
          if (_lastUserId != widget.userId || _cachedVideos == null || 
              _cachedVideos!.length != videos.length) {
            _cachedVideos = videos;
            _lastUserId = widget.userId;
          }

          return _buildVideoSection(videos);
        } catch (e) {
          debugPrint('Error general en FavoriteVideosSection: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildVideoSection(List<Video> videos) {
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                Icon(Icons.favorite, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                Text(
                    'Meus Favoritos',
                    style: TextStyle(
                    fontSize: 18,
                      fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
            SizedBox(
            height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  child: VideoCardWidget(video: videos[index]),
                );
                },
              ),
            ),
          ],
      ),
    );
  }
} 