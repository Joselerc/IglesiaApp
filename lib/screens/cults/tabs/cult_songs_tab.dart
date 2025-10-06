import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/cult.dart';
import '../../../models/cult_song.dart';
import '../modals/create_cult_song_modal.dart';
import '../cult_song_detail_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class CultSongsTab extends StatelessWidget {
  final Cult cult;
  
  const CultSongsTab({
    Key? key,
    required this.cult,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cult_songs')
            .where('cultId', isEqualTo: FirebaseFirestore.instance.collection('cults').doc(cult.id))
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.noSongsAssignedToCult),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateSongModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)!.addMusic),
                  ),
                ],
              ),
            );
          }
          
          final songs = snapshot.data!.docs.map((doc) {
            try {
              return CultSong.fromFirestore(doc);
            } catch (e) {
              print('Erro ao converter música: $e');
              return null;
            }
          }).whereType<CultSong>().toList();
          
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: songs.length,
            onReorder: (oldIndex, newIndex) {
              _reorderSongs(context, songs, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final song = songs[index];
              
              return Card(
                key: ValueKey(song.id),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CultSongDetailScreen(
                          cultSong: song,
                          cult: cult,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(song.duration),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${song.files.length} ${AppLocalizations.of(context)!.files}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.drag_handle,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSongModal(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showCreateSongModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateCultSongModal(cult: cult),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Future<void> _reorderSongs(BuildContext context, List<CultSong> songs, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);
    
    try {
      // Actualizar el orden en Firestore
      for (int i = 0; i < songs.length; i++) {
        await FirebaseFirestore.instance
            .collection('cult_songs')
            .doc(songs[i].id)
            .update({'order': i});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorReorderingSongs(e.toString()))),
      );
    }
  }
} 