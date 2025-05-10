import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../models/course.dart';
import '../../models/user_course_progress.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Estado para los filtros
  String? _selectedCategory;
  CourseStatus _selectedStatus = CourseStatus.published;
  
  // Categorías disponibles (se cargarán desde Firestore)
  List<String> _categories = [];
  bool _isLoadingCategories = true;
  
  // Estado para favoritos
  bool _showOnlyFavorites = false;
  String? _userId;
  
  // Añadir debounce para la búsqueda
  Timer? _debounce;
  String _searchQuery = '';
  
  // Animación para cambios de estado
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Stream de los cursos para mantener una sola instancia
  Stream<List<Course>>? _coursesStream;
  Stream<List<Course>>? _favoritesStream;
  
  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadCategories();
    
    // Inicializar controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.value = 1.0; // Iniciar visible
    
    // Inicializar streams
    _initStreams();
    
    // Configurar listener para búsqueda con debounce
    _searchController.addListener(_onSearchChanged);
  }
  
  void _initStreams() {
    // Stream para todos los cursos
    _coursesStream = _courseService.getCourses(
      status: _selectedStatus,
      category: _selectedCategory,
    );
    
    // Stream para favoritos (si hay usuario)
    if (_userId != null) {
      _favoritesStream = _courseService.getUserFavoriteCourses(_userId!);
    }
  }
  
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  // Cargar categorías disponibles desde Firestore
  Future<void> _loadCategories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingCategories = true;
    });
    
    try {
      // Obtener categorías únicas de los cursos existentes
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('status', isEqualTo: 'published')
          .get();
      
      // Extraer categorías únicas
      final Set<String> categories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      // Ordenar categorías
      final sortedCategories = categories.toList()..sort();
      
      if (mounted) {
        setState(() {
          _categories = sortedCategories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
      }
    }
  }
  
  // Método para cambiar filtros con animación
  void _changeFilters({String? category}) {
    // Animar para esconder el contenido
    _animationController.reverse().then((_) {
      // Cambiar los filtros en el estado
      setState(() {
        _selectedCategory = category;
      });
      
      // Re-inicializar los streams con los nuevos filtros
      _initStreams();
      
      // Animar para mostrar el nuevo contenido
      _animationController.forward();
    });
  }
  
  // Método para cambiar a vista de favoritos
  void _toggleFavorites() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faça login para ver seus cursos favoritos'),
        ),
      );
      return;
    }
    
    // Animar para esconder el contenido
    _animationController.reverse().then((_) {
      setState(() {
        _showOnlyFavorites = !_showOnlyFavorites;
      });
      // Animar para mostrar el nuevo contenido
      _animationController.forward();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Cursos Online'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              floating: true,
              snap: true,
              pinned: false,
            ),
            SliverPersistentHeader(
              delegate: _SliverSearchHeaderDelegate(
                minHeight: 160,
                maxHeight: 160,
                child: _buildSearchAndFilters(),
              ),
              pinned: true,
            ),
          ];
        },
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: child,
            );
          },
          child: _showOnlyFavorites
              ? _buildFavoriteCoursesView()
              : _buildAllCoursesView(),
        ),
      ),
    );
  }
  
  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cursos...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Fila de filtros (chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Chip para todas las categorías
                FilterChip(
                  label: const Text('Todas'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    // Siempre permitir seleccionar "Todas"
                    _changeFilters(category: null);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withOpacity(0.1),
                  showCheckmark: false,
                  avatar: _selectedCategory == null 
                      ? const Icon(Icons.check, size: 16, color: AppColors.primary) 
                      : null,
                  labelStyle: TextStyle(
                    color: _selectedCategory == null ? AppColors.primary : Colors.grey[700],
                    fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _selectedCategory == null ? AppColors.primary : Colors.grey.shade300,
                      width: _selectedCategory == null ? 1.5 : 1,
                    ),
                  ),
                ),
                
                // Chips para cada categoría
                ..._categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        _changeFilters(category: category);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary.withOpacity(0.1),
                      showCheckmark: false,
                      avatar: _selectedCategory == category 
                          ? const Icon(Icons.check, size: 16, color: AppColors.primary) 
                          : null,
                      labelStyle: TextStyle(
                        color: _selectedCategory == category ? AppColors.primary : Colors.grey[700],
                        fontWeight: _selectedCategory == category ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCategory == category ? AppColors.primary : Colors.grey.shade300,
                          width: _selectedCategory == category ? 1.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(width: 8),
                
                // Separador vertical
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                
                // Botón de favoritos
                FilterChip(
                  label: const Text('Favoritos'),
                  selected: _showOnlyFavorites,
                  onSelected: (_) => _toggleFavorites(),
                  backgroundColor: Colors.white,
                  selectedColor: Colors.red.shade50,
                  showCheckmark: false,
                  avatar: Icon(
                    Icons.favorite,
                    size: 16,
                    color: _showOnlyFavorites ? Colors.red : Colors.grey,
                  ),
                  labelStyle: TextStyle(
                    color: _showOnlyFavorites ? Colors.red : Colors.grey[700],
                    fontWeight: _showOnlyFavorites ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _showOnlyFavorites ? Colors.red : Colors.grey.shade300,
                      width: _showOnlyFavorites ? 1.5 : 1,
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
  
  // Vista de todos los cursos con filtrado
  Widget _buildAllCoursesView() {
    if (_coursesStream == null) {
      _initStreams();
    }
    
    return StreamBuilder<List<Course>>(
      stream: _coursesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }
        
        final courses = snapshot.data ?? [];
        
        // Aplicar filtro de búsqueda si hay texto
        final filteredCourses = _searchQuery.isNotEmpty
            ? courses.where((course) {
                return course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                       course.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                       course.instructorName.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList()
            : courses;
        
        if (filteredCourses.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_outlined,
            title: 'Nenhum curso encontrado',
            message: _searchQuery.isNotEmpty
                ? 'Tente com outros termos de busca'
                : 'Tente com outros filtros',
          );
        }
        
        return _buildCoursesGrid(filteredCourses);
      },
    );
  }
  
  // Vista de cursos favoritos
  Widget _buildFavoriteCoursesView() {
    if (_userId == null) {
      return _buildEmptyState(
        icon: Icons.person_outline,
        title: 'Faça login para ver seus favoritos',
        message: 'Você precisa estar logado para acessar esta função',
      );
    }
    
    if (_favoritesStream == null) {
      _initStreams();
    }
    
    return StreamBuilder<List<Course>>(
      stream: _favoritesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }
        
        final favoriteCourses = snapshot.data ?? [];
        
        // Aplicar filtros adicionales
        final filteredCourses = favoriteCourses.where((course) {
          final matchesCategory = _selectedCategory == null || 
                                 course.category == _selectedCategory;
          
          final matchesSearch = _searchQuery.isEmpty || 
                               course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               course.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               course.instructorName.toLowerCase().contains(_searchQuery.toLowerCase());
          
          return matchesCategory && matchesSearch;
        }).toList();
        
        if (filteredCourses.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'Você não tem cursos favoritos',
            message: 'Marque cursos como favoritos para vê-los aqui',
            actionButton: _searchQuery.isEmpty && _selectedCategory == null ? 
              ElevatedButton.icon(
                onPressed: () => _toggleFavorites(),
                icon: const Icon(Icons.view_list, size: 16),
                label: const Text('Ver todos os cursos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ) : null,
          );
        }
        
        return _buildCoursesGrid(filteredCourses);
      },
    );
  }
  
  // Estado vacío personalizable
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? actionButton,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.headline3.copyWith(
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyText1.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionButton != null) ...[
                const SizedBox(height: 24),
                actionButton,
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // Grid de cursos
  Widget _buildCoursesGrid(List<Course> courses) {
    return RefreshIndicator(
      onRefresh: () async {
        // Recargar datos
        _animationController.reverse();
        
        _initStreams();
        await _loadCategories();
        
        _animationController.forward();
      },
      child: GridView.builder(
        controller: _scrollController, // Usar controlador para recordar la posición
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7, // Ajustado para un mejor aspecto
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }
  
  // Card de curso individual
  Widget _buildCourseCard(Course course) {
    return Hero(
      tag: 'course_${course.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/courses/detail',
              arguments: course.id,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
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
                      // Imagen con efecto de brillo suave
                      ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                            stops: const [0.7, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.darken,
                        child: Image.network(
                          course.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      
                      // Duración como badge
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(course.totalDuration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Botón de favorito (se mostrará cuando el usuario esté autenticado)
                      if (_userId != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildFavoriteButton(course),
                        ),
                    ],
                  ),
                ),
                
                // Información del curso
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titulo
                        Text(
                          course.title,
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Instructor
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.instructorName,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Lecciones
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.totalLessons} ${course.totalLessons == 1 ? 'lição' : 'lições'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Categoría (badge)
                        if (course.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              course.category,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Botón para marcar/desmarcar curso como favorito
  Widget _buildFavoriteButton(Course course) {
    if (_userId == null) return const SizedBox.shrink();
    
    return StreamBuilder<UserCourseProgress?>(
      stream: _courseService.getUserCourseProgress(_userId!, course.id),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final isFavorite = progress?.isFavorite ?? false;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              try {
                await _courseService.toggleFavoriteCourse(_userId!, course.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(isFavorite),
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Widget de carga en forma de grid
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const ShimmerLoading(
            height: 240,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        );
      },
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

// Delegado personalizado para mantener la cabecera persistente
class _SliverSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverSearchHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverSearchHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
} 