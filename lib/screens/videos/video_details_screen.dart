import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/video.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

class VideoDetailsScreen extends StatefulWidget {
  final Video video;

  const VideoDetailsScreen({
    super.key,
    required this.video,
  });

  @override
  State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
  late YoutubePlayerController _controller;
  bool _isLiked = false;
  bool _isInFullScreen = false;
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'pt_BR');

  @override
  void initState() {
    super.initState();
    print('VideoDetails: initState');
    initializeDateFormatting('pt_BR');
    final videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    )..addListener(_fullscreenListener);
    _checkIfLiked();
    
    print('VideoDetails: Setting initial SystemUiMode with status bar visible');
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    print('VideoDetails: dispose');
    _controller.removeListener(_fullscreenListener);
    _controller.dispose();
    print('VideoDetails: Restoring SystemUiMode and Orientations in dispose');
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    // Restaurar orientación por si acaso salimos de forma abrupta
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _fullscreenListener() {
    print('VideoDetails: _fullscreenListener triggered');
    if (_controller.value.isFullScreen != _isInFullScreen) {
      final enteringFullscreen = _controller.value.isFullScreen;
      print('VideoDetails: Fullscreen state changed. Entering Fullscreen: $enteringFullscreen');
      setState(() {
        _isInFullScreen = enteringFullscreen;
      });
      if (!enteringFullscreen) {
        print('VideoDetails: Exiting fullscreen - Attempting to restore orientation and UI mode');
        // Restaurar orientación inmediatamente
        print('VideoDetails: --> Setting Portrait Orientations');
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        // Restaurar UI mode con un pequeño retraso
        print('VideoDetails: --> Scheduling SystemUiMode.manual restore (with delay)');
        Future.delayed(const Duration(milliseconds: 150), () {
          print('VideoDetails: --> Delayed restore: Setting SystemUiMode.manual with overlays');
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual, 
            overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
          );
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ));
        });
      } else {
        print('VideoDetails: Entering fullscreen - Attempting to set immersive UI mode');
        print('VideoDetails: --> Setting SystemUiMode.immersiveSticky');
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }
  }

  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLiked = widget.video.likedByUsers.contains(user.uid);
      });
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para curtir vídeos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final videoRef = FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.video.id);
      
      // Obtener el documento actual para verificar el estado
      final docSnapshot = await videoRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Vídeo não encontrado');
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      final currentlyLiked = likedByUsers.contains(user.uid);

      if (currentlyLiked) {
        // Quitar like
        await videoRef.update({
          'likes': FieldValue.increment(-1),
          'likedByUsers': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        // Añadir like
        await videoRef.update({
          'likes': FieldValue.increment(1),
          'likedByUsers': FieldValue.arrayUnion([user.uid]),
        });
      }

      setState(() {
        _isLiked = !currentlyLiked;
      });
      
      // Notificar a la pantalla de videos para que actualice la sección de favoritos
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'Adicionado aos favoritos' : 'Removido dos favoritos'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _isLiked ? Colors.green : Colors.red[300],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareVideo() async {
    await Share.share(
      '${widget.video.youtubeUrl}',
      subject: widget.video.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('VideoDetails: build method - isInFullScreen: $_isInFullScreen');
    // Calcular altura del reproductor para aspect ratio 16:9 (solo para vista normal)
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth / (16 / 9);
    
    return Scaffold(
      // El body cambia completamente según el estado de pantalla completa
      body: _isInFullScreen
          ? Container( // Contenedor simple para el reproductor en fullscreen
              color: Colors.black, // Fondo negro por si acaso
              child: YoutubePlayer(
                 controller: _controller,
                 showVideoProgressIndicator: true,
                 progressIndicatorColor: AppColors.primary,
                 progressColors: const ProgressBarColors(
                    playedColor: Colors.red,
                    handleColor: Colors.redAccent,
                  ),
                 onEnded: (metaData) {
                    print('VideoDetails: Fullscreen Player onEnded');
                    if (_isInFullScreen) { 
                      print('VideoDetails: --> Was in fullscreen, calling toggleFullScreenMode()');
                      _controller.toggleFullScreenMode();
                    }
                  },
              ),
            )
          : SafeArea( // SafeArea estándar envolviendo la vista normal
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vista normal: SizedBox con altura calculada
                  SizedBox(
                    width: screenWidth,
                    height: playerHeight,
                    child: Stack(
                      children: [
                        YoutubePlayer(
                          controller: _controller,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: AppColors.primary,
                          progressColors: const ProgressBarColors(
                            playedColor: Colors.red,
                            handleColor: Colors.redAccent,
                          ),
                          onReady: () {
                             print('VideoDetails: Normal Player onReady - Setting SystemUiMode.manual with status bar');
                             SystemChrome.setEnabledSystemUIMode(
                               SystemUiMode.manual, 
                               overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
                             );
                             SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
                               statusBarColor: Colors.transparent,
                               statusBarIconBrightness: Brightness.dark,
                               systemNavigationBarColor: Colors.white,
                               systemNavigationBarIconBrightness: Brightness.dark,
                             ));
                          },
                           onEnded: (metaData) {
                              print('VideoDetails: Normal Player onEnded');
                           },
                        ),
                        // Botón Volver siempre visible en vista normal
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, size: 22),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Voltar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Resto del contenido (título, descripción, etc.)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.video.title,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _isLiked ? Colors.red.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: _isLiked ? Colors.red : Colors.grey[600],
                                        ),
                                        tooltip: _isLiked ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                                        onPressed: _toggleLike,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.share, color: Colors.blue),
                                        tooltip: 'Compartilhar',
                                        onPressed: _shareVideo,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Mostrar número de likes
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('videos')
                                      .doc(widget.video.id)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox.shrink();
                                    
                                    final data = snapshot.data!.data() as Map<String, dynamic>;
                                    final likes = data['likes'] ?? 0;
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.favorite, color: Colors.red[400], size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            '$likes ${likes == 1 ? 'curtida' : 'curtidas'}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Fecha de publicación
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Publicado em ${_dateFormat.format(widget.video.uploadDate)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Descripción
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.description, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Descrição',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Divider
                                Container(
                                  height: 1,
                                  color: Colors.grey[200],
                                  margin: const EdgeInsets.only(bottom: 12),
                                ),
                                
                                Text(
                                  widget.video.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 