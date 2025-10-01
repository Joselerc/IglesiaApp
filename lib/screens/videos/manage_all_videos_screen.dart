import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';

class ManageAllVideosScreen extends StatefulWidget {
  const ManageAllVideosScreen({super.key});

  @override
  State<ManageAllVideosScreen> createState() => _ManageAllVideosScreenState();
}

class _ManageAllVideosScreenState extends State<ManageAllVideosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PermissionService _permissionService = PermissionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_videos'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.accessDenied,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.noPermissionManageVideos),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.recentVideos,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Para equilibrar el espacio
                      ],
                    ),
                  ),
                ),
              ),
              // Lista de videos
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('videos')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_library_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noVideosFound,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final videos = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        final videoData = video.data() as Map<String, dynamic>;
                        final videoId = video.id;
                        final title = videoData['title'] ?? AppLocalizations.of(context)!.noTitle;
                        final thumbnailUrl = videoData['thumbnailUrl'] ?? '';
                        final createdAt = videoData['createdAt'] as Timestamp?;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: thumbnailUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: thumbnailUrl,
                                      width: 80,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 80,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 80,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.video_library, color: Colors.grey),
                                    ),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: createdAt != null
                                ? Text(
                                    _formatDate(createdAt.toDate()),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                              tooltip: AppLocalizations.of(context)!.deleteVideo,
                              onPressed: () => _confirmDeleteVideo(videoId, title),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes.toString());
      }
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours.toString());
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays.toString());
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _confirmDeleteVideo(String videoId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVideo),
        content: Text(AppLocalizations.of(context)!.deleteVideoConfirmation(title)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Eliminar el video de la colección principal
        await _firestore.collection('videos').doc(videoId).delete();
        
        // También eliminar referencias en las secciones personalizadas
        final sectionsSnapshot = await _firestore
            .collection('videoSections')
            .where('type', isEqualTo: 'custom')
            .get();
            
        final batch = _firestore.batch();
        
        for (var doc in sectionsSnapshot.docs) {
          final videoIds = List<String>.from(doc.data()['videoIds'] ?? []);
          if (videoIds.contains(videoId)) {
            videoIds.remove(videoId);
            batch.update(doc.reference, {'videoIds': videoIds});
          }
        }
        
        await batch.commit();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.videoDeletedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorDeletingVideo(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 