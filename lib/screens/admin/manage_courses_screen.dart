import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'create_edit_course_screen.dart';
import '../../l10n/app_localizations.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> with SingleTickerProviderStateMixin {
  final CourseService _courseService = CourseService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  CourseStatus? _selectedFilter = null; // null representa "todos"
  List<Course> _allCourses = [];
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
    _animationController!.value = 1.0; // Iniciar como visible
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _changeFilter(CourseStatus? newFilter) {
    if (_selectedFilter != newFilter) {
      _animationController!.reverse().then((_) {
        setState(() {
          _selectedFilter = newFilter;
        });
        _animationController!.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageCoursesTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_courses'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(
              child: Text(AppLocalizations.of(context)!.errorCheckingPermission(permissionSnapshot.error.toString())),
            );
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.accessDenied, 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.noPermissionManageCourses,
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          return Column(
            children: [
              // Barra de filtros
              _buildFilterBar(),
              
              // Lista de cursos
              Expanded(
                child: _buildCoursesList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _navigateToCourseEdit(null),
        child: const Icon(Icons.add),
        tooltip: AppLocalizations.of(context)!.createNewCourse,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.filterBy,
            style: AppTextStyles.bodyText2.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.all),
                  selected: _selectedFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      _changeFilter(null);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == null 
                      ? AppColors.primary
                      : AppColors.textPrimary,
                    fontWeight: _selectedFilter == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selectedFilter == null 
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.published),
                  selected: _selectedFilter == CourseStatus.published,
                  onSelected: (selected) {
                    if (selected) {
                      _changeFilter(CourseStatus.published);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == CourseStatus.published 
                      ? AppColors.primary
                      : AppColors.textPrimary,
                    fontWeight: _selectedFilter == CourseStatus.published
                      ? FontWeight.bold
                      : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selectedFilter == CourseStatus.published 
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.drafts),
                  selected: _selectedFilter == CourseStatus.draft,
                  onSelected: (selected) {
                    if (selected) {
                      _changeFilter(CourseStatus.draft);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == CourseStatus.draft 
                      ? AppColors.primary
                      : AppColors.textPrimary,
                    fontWeight: _selectedFilter == CourseStatus.draft
                      ? FontWeight.bold
                      : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selectedFilter == CourseStatus.draft 
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(AppLocalizations.of(context)!.archived),
                  selected: _selectedFilter == CourseStatus.archived,
                  onSelected: (selected) {
                    if (selected) {
                      _changeFilter(CourseStatus.archived);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == CourseStatus.archived 
                      ? AppColors.primary
                      : AppColors.textPrimary,
                    fontWeight: _selectedFilter == CourseStatus.archived
                      ? FontWeight.bold
                      : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selectedFilter == CourseStatus.archived 
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    return StreamBuilder<List<Course>>(
      stream: _courseService.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(AppLocalizations.of(context)!.errorLoadingCourses(snapshot.error.toString())),
          );
        }
        
        final allCourses = snapshot.data ?? [];
        _allCourses = allCourses; // Guardar todos los cursos
        
        // Filtrar localmente
        final courses = _selectedFilter == null
          ? allCourses
          : allCourses.where((course) => course.status == _selectedFilter).toList();
        
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noCoursesFound,
                  style: AppTextStyles.headline3,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.clickToCreateNewCourse,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Ordenar cursos: primero los destacados, luego por fecha de actualización
        courses.sort((a, b) {
          // Primero por destacados
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          
          // Luego por fecha de actualización (más reciente primero)
          return b.updatedAt.compareTo(a.updatedAt);
        });
        
        return AnimatedBuilder(
          animation: _animationController!,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation!.value,
              child: child,
            );
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildCourseCard(course);
            },
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(Course course) {
    final statusText = {
      CourseStatus.draft: AppLocalizations.of(context)!.draft,
      CourseStatus.published: AppLocalizations.of(context)!.published,
      CourseStatus.archived: AppLocalizations.of(context)!.archived,
    }[course.status] ?? AppLocalizations.of(context)!.unknown;
    
    final statusColor = {
      CourseStatus.draft: Colors.grey,
      CourseStatus.published: Colors.green,
      CourseStatus.archived: Colors.orange,
    }[course.status] ?? Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/courses/detail',
            arguments: course.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del curso con badge de estado
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16/9,
                  child: Image.network(
                    course.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey, size: 48),
                      );
                    },
                  ),
                ),
                // Overlay para dar gradiente a la imagen
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badges de estado y destacado
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              course.status == CourseStatus.published 
                                ? Icons.public 
                                : course.status == CourseStatus.draft
                                  ? Icons.edit 
                                  : Icons.archive,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (course.isFeatured)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Destacado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del curso
                  Text(
                    course.title,
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Descripción
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Fila: categoría, módulos, lecciones
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Categoría
                        Column(
                          children: [
                            Icon(Icons.category, size: 20, color: Colors.blueGrey[700]),
                            const SizedBox(height: 4),
                            Text(
                              course.category,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.blueGrey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Divisor vertical
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        
                        // Módulos
                        Column(
                          children: [
                            Icon(Icons.folder, size: 20, color: Colors.blueGrey[700]),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.modules(course.totalModules),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.blueGrey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Divisor vertical
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        
                        // Lecciones
                        Column(
                          children: [
                            Icon(Icons.menu_book, size: 20, color: Colors.blueGrey[700]),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.lessons(course.totalLessons),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.blueGrey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Botón de opciones (menú contextual) para acciones secundarias
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showCourseOptions(course);
                          },
                        ),
                      ),
                      
                      // Espacio flexible para separar
                      const Spacer(),
                      
                      // Botón de editar (siempre visible)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(AppLocalizations.of(context)!.edit),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () => _navigateToCourseEdit(course),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Botón de publicar/despublicar dependiendo del estado
                      course.status == CourseStatus.published
                        ? ElevatedButton(
                            onPressed: () => _updateCourseStatus(course, CourseStatus.draft),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.unpublished, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(AppLocalizations.of(context)!.unpublish),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => _updateCourseStatus(course, CourseStatus.published),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.publish, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(AppLocalizations.of(context)!.publish),
                              ],
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

  void _showCourseOptions(Course course) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.optionsFor(course.title),
                  style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              
              // Cambiar estado: Publicar/Despublicar
              if (course.status != CourseStatus.published)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.publish, color: Colors.green),
                  ),
                  title: Text(AppLocalizations.of(context)!.publishCourse),
                  subtitle: Text(AppLocalizations.of(context)!.makeCourseVisibleToAllUsers),
                  onTap: () {
                    _updateCourseStatus(course, CourseStatus.published);
                    Navigator.pop(context);
                  },
                )
              else
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.unpublished, color: Colors.orange),
                  ),
                  title: Text(AppLocalizations.of(context)!.unpublishCourse),
                  subtitle: Text(AppLocalizations.of(context)!.makeCourseInvisible),
                  onTap: () {
                    _updateCourseStatus(course, CourseStatus.draft);
                    Navigator.pop(context);
                  },
                ),
              
              // Destacar/Quitar destacado
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    course.isFeatured ? Icons.star_border : Icons.star,
                    color: Colors.amber,
                  ),
                ),
                title: Text(course.isFeatured ? AppLocalizations.of(context)!.removeFeatured : AppLocalizations.of(context)!.addFeatured),
                subtitle: Text(course.isFeatured 
                  ? AppLocalizations.of(context)!.removeFromFeatured
                  : AppLocalizations.of(context)!.addToFeatured),
                onTap: () {
                  _toggleFeatureCourse(course);
                  Navigator.pop(context);
                },
              ),
              
              // Eliminar curso
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever, color: Colors.red),
                ),
                title: Text(AppLocalizations.of(context)!.deleteCourse),
                subtitle: Text(AppLocalizations.of(context)!.thisActionIsIrreversible),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteCourse(course);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _updateCourseStatus(Course course, CourseStatus newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      final updatedCourse = course.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      
      await _courseService.updateCourse(updatedCourse);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == CourseStatus.published
                  ? AppLocalizations.of(context)!.coursePublishedSuccessfully
                  : AppLocalizations.of(context)!.courseUnpublishedSuccessfully
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingStatus(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleFeatureCourse(Course course) async {
    setState(() => _isLoading = true);
    
    try {
      final updatedCourse = course.copyWith(
        isFeatured: !course.isFeatured,
        updatedAt: DateTime.now(),
      );
      
      await _courseService.updateCourse(updatedCourse);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedCourse.isFeatured
                  ? AppLocalizations.of(context)!.courseFeaturedSuccessfully
                  : AppLocalizations.of(context)!.featuredRemovedSuccessfully
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingFeatured(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDeleteCourse(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.areYouSureYouWantToDelete(course.title)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.irreversibleActionWarning,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourse(course);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _deleteCourse(Course course) async {
    setState(() => _isLoading = true);
    
    try {
      await _courseService.deleteCourse(course.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.courseDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDeletingCourse(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToCourseEdit(Course? course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditCourseScreen(course: course),
      ),
    );
  }
}

// Extensión para agregar el status "all" a CourseStatus
extension CourseStatusExtension on CourseStatus {
  static CourseStatus get all => CourseStatus.values.first;
} 