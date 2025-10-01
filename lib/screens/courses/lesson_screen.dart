import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/course.dart';
import '../../models/course_lesson.dart';
import '../../models/course_comment.dart';
import '../../models/user_course_progress.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../l10n/app_localizations.dart';

class LessonScreen extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const LessonScreen({
    Key? key,
    required this.courseId,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  final CourseService _courseService = CourseService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _commentController = TextEditingController();

  late TabController _tabController;
  
  bool _isLoading = true;
  bool _isMarkingComplete = false;
  bool _isRating = false;
  
  Course? _course;
  CourseLesson? _lesson;
  UserCourseProgress? _progress;
  YoutubePlayerController? _youtubeController;
  
  double _userRating = 0;
  bool _lessonCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cargar el curso y la lección
      final courseResult = await _courseService.getCourseById(widget.courseId);
      final lessonResult = await _getLessonFuture();
      
      // Si el usuario está autenticado, cargar su progreso
      if (_userId != null) {
        final progressStream = _courseService.getUserCourseProgress(_userId!, widget.courseId);
        await for (final progress in progressStream) {
          if (progress != null) {
            setState(() {
              _progress = progress;
              // Comprobar si la lección ya está completada
              _lessonCompleted = progress.completedLessons.contains(widget.lessonId);
              // Obtener la valoración del usuario para esta lección
              _userRating = progress.lessonRatings[widget.lessonId] ?? 0;
            });
            break;
          }
        }
      }
      
      // Guardar los datos cargados
      setState(() {
        _course = courseResult;
        _lesson = lessonResult;
        _isLoading = false;
      });
      
      // Inicializar el reproductor de YouTube si es necesario
      if (_lesson?.isYoutubeVideo == true && _lesson?.youtubeId != null) {
        _initializeYoutubePlayer(_lesson!.youtubeId!);
      }
      
      // NO marcar automáticamente como visto
      // Se eliminó el código que marcaba automáticamente la lección como completada
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar a lição: $e')),
        );
      }
    }
  }
  
  void _initializeYoutubePlayer(String videoId) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        enableCaption: true,
        captionLanguage: 'pt',
      ),
    );
  }
  
  // Obtiene la lección desde Firestore
  Future<CourseLesson?> _getLessonFuture() async {
    try {
      // Buscar en todos los módulos del curso
      final modules = await _courseService.getModulesForCourse(widget.courseId).first;
      
      for (final module in modules) {
        final lessons = await _courseService.getLessonsForModule(module.id).first;
        
        for (final lesson in lessons) {
          if (lesson.id == widget.lessonId) {
            return lesson;
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_lesson == null || _course == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.lessonNotFound),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.lessonNotFoundDetails),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson!.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.8),
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.lesson),
            Tab(text: AppLocalizations.of(context)!.materials),
            Tab(text: AppLocalizations.of(context)!.comments),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab de Lección (video y contenido)
          _buildLessonTab(),
          
          // Tab de Materiales complementarios
          _buildMaterialsTab(),
          
          // Tab de Comentarios
          _buildCommentsTab(),
        ],
      ),
    );
  }
  
  // Tab de lección con video y contenido
  Widget _buildLessonTab() {
    return Column(
      children: [
        // Video player - Sin padding, ocupa todo el ancho
        _buildVideoPlayer(),
        
        // Contenido con scroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y descripción
                Text(
                  _lesson!.title,
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Información del módulo
                Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${AppLocalizations.of(context)!.course}: ${_course!.title}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.durationLabel(_formatDuration(_lesson!.duration)),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón de marcar/desmarcar como completada
                if (_userId != null)
                  Container(
                    width: double.infinity,
                    child: _lessonCompleted
                      ? ElevatedButton.icon(
                          onPressed: _isMarkingComplete ? null : _toggleLessonCompletion,
                          icon: const Icon(Icons.check_circle),
                          label: Text(_isMarkingComplete ? AppLocalizations.of(context)!.processing : AppLocalizations.of(context)!.unmarkAsCompleted),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isMarkingComplete ? null : _toggleLessonCompletion,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(_isMarkingComplete ? AppLocalizations.of(context)!.processing : AppLocalizations.of(context)!.markAsCompleted),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                  ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Descripción de la lección
                Text(
                  AppLocalizations.of(context)!.description,
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Mostrar descripción o mensaje si está vacía
                (_lesson!.description.isNotEmpty)
                  ? Text(
                      _lesson!.description,
                      style: AppTextStyles.bodyText1,
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.noDescription,
                            style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                
                if (_progress != null) ...[
                  const SizedBox(height: 32),
                  
                  // Sistema de valoración
                  _buildRatingSection(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Tab de materiales complementarios
  Widget _buildMaterialsTab() {
    if (_lesson!.complementaryMaterialUrls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMaterialsForThisLesson,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lesson!.complementaryMaterialUrls.length,
      itemBuilder: (context, index) {
        final url = _lesson!.complementaryMaterialUrls[index];
        String name = 'Material ${index + 1}';
        
        // Obtener el nombre del material si está disponible
        if (index < _lesson!.complementaryMaterialNames.length) {
          name = _lesson!.complementaryMaterialNames[index];
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _getFileIcon(url),
            title: Text(name),
            subtitle: Text(
              _getFileExtension(url),
              style: AppTextStyles.caption,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.launch, color: AppColors.primary),
                  onPressed: () => _openUrl(url),
                  tooltip: AppLocalizations.of(context)!.open,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.primary),
                  onPressed: () => _copyToClipboard(url),
                  tooltip: AppLocalizations.of(context)!.copyLink,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Tab de comentarios
  Widget _buildCommentsTab() {
    if (!_lesson!.hasComments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.commentsDisabled,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Campo para añadir comentario
        if (_userId != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.addYourComment,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          
        // Lista de comentarios
        Expanded(
          child: StreamBuilder<List<CourseComment>>(
            stream: _courseService.getCommentsForLesson(widget.lessonId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro: ${snapshot.error}'),
                );
              }
              
              final comments = snapshot.data ?? [];
              
              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noCommentsYet,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.beTheFirstToComment,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return _buildCommentItem(comments[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Construye el reproductor de video
  Widget _buildVideoPlayer() {
    if (_lesson!.videoUrl.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: Center(
          child: Text(AppLocalizations.of(context)!.noVideoAvailable),
        ),
      );
    }
    
    // Calcular el ancho y alto para ocupar el ancho completo de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth * 9 / 16; // Aspecto 16:9
    
    // Para videos de YouTube con el reproductor integrado
    if (_lesson!.isYoutubeVideo && _lesson!.youtubeId != null && _youtubeController != null) {
      return SizedBox(
        width: screenWidth,
        height: playerHeight,
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
          ),
          onReady: () {
            // Configurar el reproductor cuando está listo
            _youtubeController!.addListener(() {});
          },
        ),
      );
    }
    
    // Para videos de Vimeo o URLs genéricas, mostrar un thumbnail con botón de reproducción
    Widget videoWidget;
    
    if (_lesson!.isYoutubeVideo && _lesson!.youtubeId != null) {
      // YouTube thumbnail con botón de reproducción
      videoWidget = GestureDetector(
        onTap: () {
          // Inicializar el reproductor y abrir el video
          _initializeYoutubePlayer(_lesson!.youtubeId!);
          setState(() {});
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Miniatura de YouTube
            Image.network(
              'https://img.youtube.com/vi/${_lesson!.youtubeId}/maxresdefault.jpg',
              height: playerHeight,
              width: screenWidth,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://img.youtube.com/vi/${_lesson!.youtubeId}/hqdefault.jpg',
                  height: playerHeight,
                  width: screenWidth,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: playerHeight,
                      width: screenWidth,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            // Overlay para oscurecer la imagen
            Container(
              height: playerHeight,
              width: screenWidth,
              color: Colors.black.withOpacity(0.3),
            ),
            
            // Botón de reproducción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      );
    } else if (_lesson!.isVimeoVideo && _lesson!.vimeoId != null) {
      // Vimeo thumbnail
      videoWidget = GestureDetector(
        onTap: () => _openUrl(_lesson!.videoUrl),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Placeholder para Vimeo
            Container(
              height: playerHeight,
              width: screenWidth,
              color: Colors.grey[700],
              child: _lesson!.videoThumbnailUrl != null
                  ? Image.network(
                      _lesson!.videoThumbnailUrl!,
                      fit: BoxFit.cover,
                      width: screenWidth,
                      height: playerHeight,
                    )
                  : null,
            ),
            
            // Overlay para oscurecer la imagen
            Container(
              height: playerHeight,
              width: screenWidth,
              color: Colors.black.withOpacity(0.3),
            ),
            
            // Botón de reproducción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1AB7EA), // Color de Vimeo
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      );
    } else {
      // URL genérica de video
      videoWidget = GestureDetector(
        onTap: () => _openUrl(_lesson!.videoUrl),
        child: Container(
          height: playerHeight,
          width: screenWidth,
          color: Colors.grey[700],
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white70,
              ),
              Positioned(
                bottom: 20,
                child: Text(
                  AppLocalizations.of(context)!.clickToWatchVideo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return videoWidget;
  }
  
  // Construye la sección de valoración (Reimplementada con números)
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.evaluateThisLesson,
          style: AppTextStyles.headline3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Fila de botones numéricos para valoración
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final ratingValue = index + 1;
            final bool isSelected = _userRating == ratingValue.toDouble();
            
            return ElevatedButton(
              onPressed: _isRating ? null : () => _rateLesson(ratingValue.toDouble()),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? AppColors.primary : Colors.grey[200],
                foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
                elevation: isSelected ? 4 : 1,
              ),
              child: Text(
                '$ratingValue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }),
        ),
        
        // Información sobre las valoraciones
        if (_lesson!.totalRatings > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16.0), // Añadir padding superior
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.averageRating,
                    style: AppTextStyles.bodyText2.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _lesson!.averageRating.toStringAsFixed(1),
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_lesson!.totalRatings})',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  // Valorar la lección (actualiza UI ANTES de guardar para respuesta visual)
  Future<void> _rateLesson(double rating) async {
    if (_userId == null || _isRating) return;
    
    // No hacer nada si se pulsa la misma valoración
    if (_userRating == rating) return;

    // Actualizar visualmente DE INMEDIATO
    setState(() {
      _isRating = true; // Bloquear mientras se guarda
      _userRating = rating;
    });

    try {
      await _courseService.rateLessonWithProgress(
        _userId!,
        widget.courseId,
        widget.lessonId,
        rating, 
      );
      // La UI ya está actualizada
    } catch (e) {
      if (mounted) {
        // Si falla, podríamos revertir la UI, pero es más complejo
        // Por ahora, solo mostramos error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar avaliação: $e')),
        );
      }
    } finally {
      if (mounted) {
        // Desbloquear botones después de que la operación termine
        setState(() {
          _isRating = false;
        });
      }
    }
  }
  
  // Construye un elemento de comentario
  Widget _buildCommentItem(CourseComment comment) {
    final bool isCurrentUser = _userId != null && comment.userId == _userId;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: comment.userPhotoUrl != null
                  ? NetworkImage(comment.userPhotoUrl!)
                  : null,
              child: comment.userPhotoUrl == null
                  ? Text(
                      comment.userDisplayName.isNotEmpty
                          ? comment.userDisplayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Nombre y fecha
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userDisplayName,
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.you,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    _formatDate(comment.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón de eliminar (solo para comentarios propios)
            if (isCurrentUser)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDeleteComment(comment),
                color: Colors.red[300],
              ),
          ],
        ),
        
        // Contenido del comentario
        Padding(
          padding: const EdgeInsets.only(left: 48, top: 8),
          child: Text(comment.comment),
        ),
        
        // Likes y respuestas
        Padding(
          padding: const EdgeInsets.only(left: 44, top: 8),
          child: Row(
            children: [
              // Botón de like
              if (_userId != null)
                TextButton.icon(
                  onPressed: () => _toggleLikeComment(comment),
                  icon: Icon(
                    comment.isLikedByUser(_userId!)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 16,
                    color: comment.isLikedByUser(_userId!)
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  label: Text(
                    comment.likedBy.length.toString(),
                    style: TextStyle(
                      color: comment.isLikedByUser(_userId!)
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              
              const SizedBox(width: 16),
              
              // Respuestas
              if (comment.replyCount > 0)
                TextButton.icon(
                  onPressed: () => _viewReplies(comment),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  label: Text(
                    '${comment.replyCount} ${comment.replyCount == 1 ? AppLocalizations.of(context)!.reply : AppLocalizations.of(context)!.replies}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Marcar la lección como completada
  Future<void> _toggleLessonCompletion() async {
    if (_userId == null || _isMarkingComplete) return;
    
    setState(() {
      _isMarkingComplete = true;
    });
    
    try {
      if (_lessonCompleted) {
        // Desmarcar como completada
        await _courseService.unmarkLessonAsCompleted(
          _userId!,
          widget.courseId,
          widget.lessonId,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.lessonUnmarked),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // Marcar como completada
        await _courseService.markLessonAsCompleted(
          _userId!,
          widget.courseId,
          widget.lessonId,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.lessonCompleted),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      setState(() {
        _lessonCompleted = !_lessonCompleted;
        _isMarkingComplete = false;
      });
    } catch (e) {
      setState(() {
        _isMarkingComplete = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  // Añadir un comentario
  Future<void> _addComment() async {
    if (_userId == null || _commentController.text.trim().isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final comment = CourseComment.create(
      lessonId: widget.lessonId,
      courseId: widget.courseId,
      userId: user.uid,
      userDisplayName: user.displayName ?? 'Usuário',
      userPhotoUrl: user.photoURL,
      comment: _commentController.text.trim(),
    );
    
    try {
      await _courseService.addComment(comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  // Dar/quitar like a un comentario
  Future<void> _toggleLikeComment(CourseComment comment) async {
    if (_userId == null) return;
    
    try {
      await _courseService.toggleLikeComment(comment.id, _userId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  // Ver respuestas a un comentario
  void _viewReplies(CourseComment comment) {
    // Implementar esto cuando hagamos la pantalla de respuestas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.repliesFunctionality)),
    );
  }
  
  // Confirmar eliminación de comentario
  void _confirmDeleteComment(CourseComment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteComment),
        content: Text(AppLocalizations.of(context)!.confirmDeleteComment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  // Eliminar un comentario
  Future<void> _deleteComment(CourseComment comment) async {
    try {
      await _courseService.deleteComment(comment.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.commentDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  // Abrir una URL
  Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir a URL: $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  // Copiar URL al portapapeles
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.linkCopiedToClipboard),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // Obtener icono según el tipo de archivo
  Widget _getFileIcon(String url) {
    final extension = _getFileExtension(url).toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx':
        return const Icon(Icons.table_chart, color: Colors.green);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow, color: Colors.orange);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return const Icon(Icons.image, color: Colors.purple);
      case 'mp3':
      case 'wav':
        return const Icon(Icons.audiotrack, color: Colors.cyan);
      case 'mp4':
      case 'avi':
      case 'mov':
        return const Icon(Icons.video_library, color: Colors.red);
      case 'zip':
      case 'rar':
        return const Icon(Icons.archive, color: Colors.brown);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }
  
  // Obtener extensión de un archivo desde la URL
  String _getFileExtension(String url) {
    try {
      final Uri uri = Uri.parse(url);
      final String path = uri.path;
      
      // Obtener la extensión
      final int lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1);
      }
    } catch (e) {
      // Ignorar errores al parsear
    }
    
    return AppLocalizations.of(context)!.unknown;
  }
  
  // Formatear fecha
  String _formatDate(DateTime date) {
    // Diferencia en días
    final difference = DateTime.now().difference(date).inDays;
    
    if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference);
    } else {
      // Formatear como dd/mm/yyyy
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
  
  // Pantalla de carga
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loading),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  // Formatea la duración en minutos a formato legible
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours h';
      } else {
        return '$hours h $remainingMinutes min';
      }
    }
  }
} 