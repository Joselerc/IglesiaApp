import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/course.dart';
import '../../models/course_module.dart';
import '../../models/course_lesson.dart';
import '../../models/user_course_progress.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../l10n/app_localizations.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseService _courseService = CourseService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  
  bool _isEnrolled = false;
  bool _isEnrolling = false;
  
  @override
  Widget build(BuildContext context) {
    // Configurar la barra de estado para que sea visible y con texto claro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Fondo transparente
        statusBarIconBrightness: Brightness.light, // Iconos claros
        statusBarBrightness: Brightness.dark, // Para iOS
      ),
    );
    
    return StreamBuilder<Course?>(
      stream: Stream.fromFuture(_courseService.getCourseById(widget.courseId) ?? Future.value(null)),
      builder: (context, courseSnapshot) {
        if (courseSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (courseSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erro'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text('Erro: ${courseSnapshot.error}'),
            ),
          );
        }

        final course = courseSnapshot.data;
        if (course == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.courseNotFound),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(AppLocalizations.of(context)!.courseNotFoundDetails),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background, // Forzar fondo claro
          body: FutureBuilder<int>(
            future: _getRealLessonCount(widget.courseId),
            builder: (context, lessonCountSnapshot) {
              if (lessonCountSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              if (lessonCountSnapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.errorLoadingLessonCount));
              }
              final realTotalLessons = lessonCountSnapshot.data ?? course.totalLessons;

              return StreamBuilder<UserCourseProgress?>(
                stream: _userId != null
                    ? _courseService.getUserCourseProgress(_userId!, widget.courseId)
                    : Stream.value(null),
                builder: (context, progressSnapshot) {
                  final progress = progressSnapshot.data;
                  _isEnrolled = progress != null;
                  
                  return AnnotatedRegion<SystemUiOverlayStyle>(
                    value: const SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: Brightness.light,
                      statusBarBrightness: Brightness.dark,
                    ),
                    child: SafeArea(
                      top: false, 
                      bottom: true,
                      // Envolver con Theme para forzar tema claro
                      child: Theme(
                        data: ThemeData(
                          brightness: Brightness.light,
                          canvasColor: AppColors.background,
                          // Puedes añadir más personalizaciones del tema aquí si es necesario
                        ),
                        child: CustomScrollView(
                          slivers: [
                            _buildAppBar(course, progress),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(course, progress, realTotalLessons),
                                    const SizedBox(height: 16),
                                    _buildCourseInfo(course, realTotalLessons),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Descrição',
                                      style: AppTextStyles.headline3.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary, // Asegurar color
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      course.description,
                                      style: AppTextStyles.bodyText1.copyWith(
                                        color: AppColors.textSecondary, // Asegurar color
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildEnrollButton(course, progress),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  AppLocalizations.of(context)!.courseContent,
                                  style: AppTextStyles.headline3.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary, // Asegurar color
                                  ),
                                ),
                              ),
                            ),
                            _buildModulesList(course, progress),
                            SliverToBoxAdapter(
                              child: SizedBox(height: 40),
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
        );
      },
    );
  }
  
  // AppBar con imagen de fondo
  Widget _buildAppBar(Course course, UserCourseProgress? progress) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      stretch: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Asegurar transparencia
        statusBarIconBrightness: Brightness.light, // Forzar iconos claros
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              course.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.primary,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.white60,
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_userId != null && progress != null)
          IconButton(
            icon: Icon(
              progress.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: progress.isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () async {
              try {
                await _courseService.toggleFavoriteCourse(_userId!, course.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.errorTogglingFavorite(e.toString()))),
                  );
                }
              }
            },
          ),
      ],
    );
  }
  
  // Encabezado con título, instructor y porcentaje (usa conteo real)
  Widget _buildHeader(Course course, UserCourseProgress? progress, int realTotalLessons) {
    double completionPercentage = 0;
    int completedCount = 0;
    
    if (progress != null) {
      completedCount = progress.completedLessons.length;
      if (realTotalLessons > 0) { // Usar conteo real
        completionPercentage = (completedCount / realTotalLessons) * 100;
      } else {
        completionPercentage = 0;
      }
    } else {
      completionPercentage = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: AppTextStyles.headline2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.instructorLabel(course.instructorName),
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.progress(completionPercentage.toInt(), completedCount, realTotalLessons),
                style: AppTextStyles.bodyText2.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  // Información del curso (usa conteo real)
  Widget _buildCourseInfo(Course course, int realTotalLessons) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.access_time,
            title: AppLocalizations.of(context)!.duration,
            value: _formatDuration(course.totalDuration),
          ),
          _buildInfoItem(
            icon: Icons.menu_book,
            title: AppLocalizations.of(context)!.lessonsLabel,
            value: '$realTotalLessons', // Usar conteo real
          ),
          _buildInfoItem(
            icon: Icons.category,
            title: AppLocalizations.of(context)!.category,
            value: course.category,
          ),
        ],
      ),
    );
  }
  
  // Item de información individual
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Botón de inscripción o continuar (sin porcentaje)
  Widget _buildEnrollButton(Course course, UserCourseProgress? progress) {
    if (progress != null) {
      return ElevatedButton(
        onPressed: () {
          if (progress.completedLessons.isNotEmpty) {
            _navigateToNextLesson(course.id, progress);
          } else {
            _navigateToFirstLesson(course.id);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white, // Asegurar texto e icono blanco
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_filled,
              color: Colors.white, // Asegurar color blanco del icono
            ),
            const SizedBox(width: 8),
            Text(
                progress.completedLessons.isEmpty
                    ? AppLocalizations.of(context)!.startCourse
                    : AppLocalizations.of(context)!.continueCourse,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: _isEnrolling ? null : () => _enrollInCourse(course.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: _isEnrolling
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.enroll,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      );
    }
  }
  
  // Lista de módulos y lecciones
  Widget _buildModulesList(Course course, UserCourseProgress? progress) {
    return StreamBuilder<List<CourseModule>>(
      stream: _courseService.getModulesForCourse(course.id),
      builder: (context, modulesSnapshot) {
        if (modulesSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (modulesSnapshot.hasError) {
          return SliverToBoxAdapter(
              child: Center(child: Text(AppLocalizations.of(context)!.errorLoadingModules(modulesSnapshot.error.toString()))),
          );
        }

        final modules = modulesSnapshot.data ?? [];
        if (modules.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: Text(AppLocalizations.of(context)!.noModulesAvailable),
              ),
            ),
          );
        }

        // Construir la lista de módulos
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final module = modules[index];
              return _buildModuleItem(module, progress);
            },
            childCount: modules.length,
          ),
        );
      },
    );
  }
  
  // Item de módulo con sus lecciones
  Widget _buildModuleItem(CourseModule module, UserCourseProgress? progress) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${module.order + 1}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.lessons(module.totalLessons),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          childrenPadding: EdgeInsets.zero,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: StreamBuilder<List<CourseLesson>>(
                stream: _courseService.getLessonsForModule(module.id),
                builder: (context, lessonsSnapshot) {
                  if (lessonsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (lessonsSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(AppLocalizations.of(context)!.errorLoadingLessons(lessonsSnapshot.error.toString())),
                      ),
                    );
                  }

                  final lessons = lessonsSnapshot.data ?? [];
                  if (lessons.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(AppLocalizations.of(context)!.noLessonsAvailableInModule),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final isCompleted = progress?.completedLessons.contains(lesson.id) ?? false;
                      return _buildLessonItem(lesson, isCompleted);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Item de lección
  Widget _buildLessonItem(CourseLesson lesson, bool isCompleted) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: isCompleted
          ? Icon(Icons.check_circle, color: Colors.green[600])
          : Icon(Icons.circle_outlined, color: Colors.grey[400]),
      title: Text(
        lesson.title,
        style: TextStyle(
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        _formatDuration(lesson.duration),
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.play_circle_fill, color: AppColors.primary),
      onTap: _isEnrolled
        ? () => _navigateToLesson(lesson.courseId, lesson.id)
        : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.enrollToAccessLesson),
                ),
              );
          },
    );
  }
  
  // Navegar a la primera lección del curso
  void _navigateToFirstLesson(String courseId) async {
    try {
      // Obtener todos los módulos del curso
      final modules = await _courseService.getModulesForCourse(courseId).first;
      if (modules.isEmpty) {
        _showNoContentMessage();
        return;
      }
      
      // Ordenar módulos por orden
      modules.sort((a, b) => a.order.compareTo(b.order));
      
      // Obtener lecciones del primer módulo
      final lessons = await _courseService.getLessonsForModule(modules.first.id).first;
      if (lessons.isEmpty) {
        _showNoContentMessage();
        return;
      }
      
      // Ordenar lecciones por orden
      lessons.sort((a, b) => a.order.compareTo(b.order));
      
      // Navegar a la primera lección
      _navigateToLesson(courseId, lessons.first.id);
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }
  
  // Navegar a la siguiente lección no completada
  void _navigateToNextLesson(String courseId, UserCourseProgress progress) async {
    try {
      // Obtener todas las lecciones del curso
      final lessons = await _courseService.getAllLessonsForCourse(courseId);
      if (lessons.isEmpty) {
        _showNoContentMessage();
        return;
      }
      
      // Ordenar lecciones por módulo y orden
      lessons.sort((a, b) {
        if (a.moduleId != b.moduleId) {
          return a.moduleId.compareTo(b.moduleId);
        }
        return a.order.compareTo(b.order);
      });
      
      // Encontrar la primera lección no completada
      for (var lesson in lessons) {
        if (!progress.completedLessons.contains(lesson.id)) {
          _navigateToLesson(courseId, lesson.id);
          return;
        }
      }
      
      // Si todas están completadas, ir a la primera lección
      _navigateToLesson(courseId, lessons.first.id);
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }
  
  // Mostrar mensaje de error cuando no hay contenido
  void _showNoContentMessage() {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noLessonsAvailable),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }
  
  // Mostrar mensaje de error genérico
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Navegar a una lección específica
  void _navigateToLesson(String courseId, String lessonId) {
    Navigator.pushNamed(
      context,
      '/courses/lesson',
      arguments: {
        'courseId': courseId,
        'lessonId': lessonId,
      },
    );
  }
  
  // Pantalla de carga
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.loading),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de carga
            const ShimmerLoading(height: 200),
            const SizedBox(height: 16),
            
            // Título de carga
            const ShimmerLoading(height: 32),
            const SizedBox(height: 8),
            
            // Subtítulo de carga
            const ShimmerLoading(height: 20, width: 200),
            const SizedBox(height: 16),
            
            // Información de carga
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading(height: 60, width: 60),
                  ShimmerLoading(height: 60, width: 60),
                  ShimmerLoading(height: 60, width: 60),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Descripción de carga
            const ShimmerLoading(height: 20),
            const SizedBox(height: 8),
            const ShimmerLoading(height: 20),
            const SizedBox(height: 8),
            const ShimmerLoading(height: 20, width: 300),
            const SizedBox(height: 24),
            
            // Botón de carga
            const ShimmerLoading(height: 50),
            const SizedBox(height: 24),
            
            // Título de módulos
            const ShimmerLoading(height: 24, width: 200),
            const SizedBox(height: 16),
            
            // Módulos de carga
            for (int i = 0; i < 3; i++) ...[
              const ShimmerLoading(height: 80),
              const SizedBox(height: 16),
            ],
          ],
        ),
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
  
  // Método para inscribirse en un curso
  Future<void> _enrollInCourse(String courseId) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginToEnroll),
        ),
      );
      return;
    }
    
    setState(() {
      _isEnrolling = true;
    });
    
    try {
      await _courseService.enrollUserInCourse(_userId!, courseId);
      setState(() {
        _isEnrolled = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.enrolledSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorEnrolling(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  // NUEVO: Método auxiliar para obtener el conteo real de lecciones
  Future<int> _getRealLessonCount(String courseId) async {
    final lessons = await _courseService.getAllLessonsForCourse(courseId);
    return lessons.length;
  }
} 