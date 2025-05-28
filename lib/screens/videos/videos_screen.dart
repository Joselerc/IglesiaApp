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
import '../../widgets/skeletons/videos_screen_skeleton.dart';
import '../../widgets/skeletons/video_section_skeleton.dart';
import '../../widgets/home/favorite_videos_section.dart';
import '../../widgets/videos/video_card_widget.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final ScrollController _scrollController = ScrollController();
  final int _limit = 10;
  bool _isPastor = false;
  bool _showFavoritesSection = false;
  bool _isScreenSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _performInitialScreenSetup();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performInitialScreenSetup() async {
    await Future.wait([
      _checkPastorStatus(),
      _checkIfFavoritesSectionShouldBeShown(),
    ]);
    if (mounted) {
      setState(() {
        _isScreenSetupComplete = true;
      });
    }
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
        _isPastor = userData['role'] == 'pastor';
      }
    }
  }

  Future<void> _checkIfFavoritesSectionShouldBeShown() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final favoritesQuery = await FirebaseFirestore.instance
            .collection('videos')
            .where('likedByUsers', arrayContains: user.uid)
            .limit(1)
            .get();
        
        _showFavoritesSection = favoritesQuery.docs.isNotEmpty;

      } catch (e) {
        print('Erro ao verificar existência de favoritos: $e');
        _showFavoritesSection = false;
      }
    } else {
      _showFavoritesSection = false;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    // Implementar paginação
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
                          _checkIfFavoritesSectionShouldBeShown();
                        });
                      },
                      tooltip: 'Gerenciar seções',
                    ),
                ],
              ),
            ];
          },
          body: !_isScreenSetupComplete 
              ? const VideosScreenSkeleton()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isScreenSetupComplete = false;
                    });
                    await _performInitialScreenSetup();
                  },
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 35),
                    children: [
                      _buildSection(
                        title: 'Vídeos Recentes',
                        icon: Icons.new_releases,
                        stream: FirebaseFirestore.instance
                            .collection('videos')
                            .orderBy('uploadDate', descending: true)
                            .limit(_limit)
                            .snapshots(),
                      ),
                      
                      if (currentUser != null && _showFavoritesSection)
                        FavoriteVideosSection(userId: currentUser.uid),
                      
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('videoSections')
                            .orderBy('order')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const VideosScreenSkeleton();
                          }
                          if (snapshot.hasError) {
                            print('Error en StreamBuilder de Secciones Personalizadas: ${snapshot.error}');
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(child: Text('Erro ao carregar seções: ${snapshot.error}')),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data == null) {
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
                                return const SizedBox.shrink();
                              }
                              return const SizedBox.shrink();
                            }).toList(),
                          );
                        },
                      ),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const VideoSectionSkeleton(showTitle: false, itemCount: 3);
              }
              if (snapshot.hasError) {
                print('Error en StreamBuilder de _buildSection: ${snapshot.error}');
                return Center(child: Text('Erro na seção: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum vídeo disponível nesta seção',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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
                  return VideoCardWidget(video: videos[index]);
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const VideoSectionSkeleton(showTitle: false, itemCount: 2);
              }
              if (snapshot.hasError) {
                print('Error en StreamBuilder de _buildCustomSection: ${snapshot.error}');
                return Center(child: Text('Erro na seção customizada: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Nenhum vídeo nesta seção personalizada',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              final videos = snapshot.data!.docs
                  .map((doc) => Video.fromFirestore(doc))
                  .toList();

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
                  return VideoCardWidget(video: videos[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}