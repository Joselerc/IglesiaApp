import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/course.dart';
import '../../models/course_section_config.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/shimmer_loading.dart';
import '../../utils/guest_utils.dart';

class CoursesSection extends StatefulWidget {
  final String? title;

  const CoursesSection({Key? key, this.title}) : super(key: key);

  @override
  State<CoursesSection> createState() => _CoursesSectionState();
}

class _CoursesSectionState extends State<CoursesSection> {
  final CourseService _courseService = CourseService();
  late Future<CourseSectionConfig> _configFuture;

  @override
  void initState() {
    super.initState();
    _configFuture = _courseService.getCourseSectionConfig();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CourseSectionConfig>(
      future: _configFuture,
      builder: (context, configSnapshot) {
        // Mientras carga la configuración
        if (configSnapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(height: 200);
        }

        // Se a error ou não ha dados
        if (configSnapshot.hasError || !configSnapshot.hasData) {
          return const SizedBox.shrink(); // No mostrar nada
        }

        // Usar a configuração carregada
        final config = configSnapshot.data!;

        // Se a seção está desativada, no mostrar nada
        if (!config.isActive) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado da seção
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title ?? config.title,
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      // Verificar si el usuario es invitado
                      final isGuest = await GuestUtils.checkGuestAndShowDialog(context);
                      
                      // Solo navegar si NO es invitado
                      if (!isGuest && context.mounted) {
                        Navigator.pushNamed(context, '/courses');
                      }
                    },
                    child: Text(
                      'Ver todos',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card principal personalizado con proporción 16:9
            _buildFeaturedCard(config),
            
            // Lista horizontal de cursos destacados
            StreamBuilder<List<Course>>(
              stream: _courseService.getCourses(
                status: CourseStatus.published,
                onlyFeatured: true,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // No mostrar nada durante la carga
                }
                
                if (snapshot.hasError) {
                  return const SizedBox.shrink(); // No mostrar error
                }
                
                final courses = snapshot.data ?? [];
                
                // Solo mostrar la sección si hay cursos destacados
                if (courses.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                // Mostrar indicador de scroll
                return Column(
                  children: [
                    // Indicador de cursos disponibles
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Deslize para ver cursos em destaque',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de cursos horizontal
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return _buildCourseCard(course);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Construye el card principal personalizable
  Widget _buildFeaturedCard(CourseSectionConfig config) {
    // Calcular proporción 16:9 para el card
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () async {
            // Verificar si el usuario es invitado
            final isGuest = await GuestUtils.checkGuestAndShowDialog(context);
            
            // Solo navegar si NO es invitado
            if (!isGuest && context.mounted) {
              Navigator.pushNamed(context, '/courses');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(config.getBackgroundColorValue()),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
              image: config.backgroundImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(config.backgroundImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Gradient overlay más sutil
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Contenido del card con mejor espaciado
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          config.title,
                          style: AppTextStyles.headline3.copyWith(
                            color: Color(config.getTextColorValue()),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (config.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 40), // Aumentado el padding derecho
                            child: Text(
                              config.subtitle!,
                              style: AppTextStyles.bodyText2.copyWith(
                                color: Color(config.getTextColorValue()).withOpacity(0.9),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Icono para indicar que es interactivo
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Menos opaco
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Color(config.getTextColorValue()),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construye un card para un curso en la lista horizontal
  Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () async {
        // Verificar si el usuario es invitado
        final isGuest = await GuestUtils.checkGuestAndShowDialog(context);
        
        // Solo navegar si NO es invitado
        if (!isGuest && context.mounted) {
          Navigator.pushNamed(
            context, 
            '/courses/detail',
            arguments: course.id,
          );
        }
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del curso
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  // Imagen
                  Image.network(
                    course.imageUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                  
                  // Overlay para mejor legibilidad del texto
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Categoría (en lugar del nivel)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Información del curso
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    course.title,
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Instructor
                  Text(
                    course.instructorName,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Información del curso (duración, lecciones)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(course.totalDuration),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.menu_book,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.totalLessons} lecciones',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
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