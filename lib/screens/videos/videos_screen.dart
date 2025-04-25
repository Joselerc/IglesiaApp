import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/video.dart';
import '../../models/video_section.dart';
import '../../screens/videos/video_details_screen.dart';
import '../../screens/videos/manage_sections_screen.dart';
import '../../screens/videos/add_video_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final int _limit = 10;
  bool _showFavorites = false;
  bool _isPastor = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkForFavorites();
    _checkPastorStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkPastorStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isPastor = userData['role'] == 'pastor';
        });
      }
    }
  }

  Future<void> _checkForFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final videosSnapshot = await FirebaseFirestore.instance
            .collection('videos')
            .where('likedByUsers', arrayContains: user.uid)
            .get();
        
        if (mounted) {
          setState(() {
            _showFavorites = videosSnapshot.docs.isNotEmpty;
          });
        }
      } catch (e) {
        print('Erro ao verificar favoritos: $e');
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    // Implementar paginação
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
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
                  child: FlexibleSpaceBar(
                    title: const Text(
                      'Vídeos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Elementos decorativos
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    // Siempre navegar a la home_screen
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
                actions: [
                  if (_isPastor)
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageSectionsScreen(),
                          ),
                        ).then((_) {
                          setState(() {});
                          _checkForFavorites();
                        });
                      },
                      tooltip: 'Gerenciar seções',
                    ),
                ],
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: () async {
              await _checkForFavorites();
              setState(() {});
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 35),
              children: [
                // Sección de últimos vídeos
                _buildSection(
                  title: 'Vídeos Recentes',
                  icon: Icons.new_releases,
                  stream: FirebaseFirestore.instance
                      .collection('videos')
                      .orderBy('uploadDate', descending: true)
                      .limit(_limit)
                      .snapshots(),
                ),
                
                // Sección de favoritos (si hay)
                if (_showFavorites && FirebaseAuth.instance.currentUser != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.red[400], size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Meus Favoritos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('videos')
                              .where('likedByUsers', arrayContains: FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (snapshot.hasError) {
                              return Center(child: Text('Erro: ${snapshot.error}'));
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text('Nenhum vídeo favorito',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }

                            final videos = snapshot.data!.docs
                                .map((doc) => Video.fromFirestore(doc))
                                .toList();
                            
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: videos.length,
                              itemBuilder: (context, index) {
                                return _buildVideoCard(videos[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              
                // Secciones personalizadas
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('videoSections')
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    
                    final sections = snapshot.data!.docs
                        .map((doc) => VideoSection.fromFirestore(doc))
                        .toList();
                    
                    return Column(
                      children: sections.map((section) {
                        if (section.type == 'custom') {
                          return _buildCustomSection(section);
                        } else if (section.type == 'latest') {
                          return _buildSection(
                            title: section.title,
                            icon: Icons.new_releases,
                            stream: FirebaseFirestore.instance
                                .collection('videos')
                                .orderBy('uploadDate', descending: true)
                                .limit(10)
                                .snapshots(),
                          );
                        } else if (section.type == 'favorites') {
                          return _buildSection(
                            title: section.title,
                            icon: Icons.thumb_up,
                            stream: FirebaseFirestore.instance
                                .collection('videos')
                                .orderBy('likes', descending: true)
                                .limit(10)
                                .snapshots(),
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),
                    );
                  },
                ),
                
                // Espacio adicional al final
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isPastor ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddVideoScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Adicionar vídeo'),
        backgroundColor: AppColors.primary,
      ) : null,
    );
  }

  Widget _buildSection({
    required String title,
    required Stream<QuerySnapshot> stream,
    IconData icon = Icons.video_library,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 192,
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final videos = snapshot.data!.docs
                  .map((doc) => Video.fromFirestore(doc))
                  .toList();

              if (videos.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum vídeo disponível',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return _buildVideoCard(videos[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSection(VideoSection section) {
    if (section.videoIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.video_collection, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 192,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('videos')
                .where(FieldPath.documentId, whereIn: section.videoIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final videos = snapshot.data!.docs
                  .map((doc) => Video.fromFirestore(doc))
                  .toList();

              if (videos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Nenhum vídeo disponível',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }

              // Ordenar videos según el orden en videoIds
              videos.sort((a, b) {
                final indexA = section.videoIds.indexOf(a.id);
                final indexB = section.videoIds.indexOf(b.id);
                return indexA.compareTo(indexB);
              });

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return _buildVideoCard(videos[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(Video video) {
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
                            const Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(video.uploadDate),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}