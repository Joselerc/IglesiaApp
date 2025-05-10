import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/course.dart';
import '../../models/course_module.dart';
import '../../models/course_lesson.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'manage_lesson_materials_screen.dart';

class ManageCourseModulesScreen extends StatefulWidget {
  final String courseId;

  const ManageCourseModulesScreen({Key? key, required this.courseId}) : super(key: key);

  @override
  State<ManageCourseModulesScreen> createState() => _ManageCourseModulesScreenState();
}

class _ManageCourseModulesScreenState extends State<ManageCourseModulesScreen> {
  final CourseService _courseService = CourseService();
  final _moduleFormKey = GlobalKey<FormState>();
  final _lessonFormKey = GlobalKey<FormState>();
  final _moduleTitleController = TextEditingController();
  final _moduleSummaryController = TextEditingController();
  final _lessonTitleController = TextEditingController();
  final _lessonDescriptionController = TextEditingController();
  final _lessonDurationController = TextEditingController();
  final _lessonVideoUrlController = TextEditingController();
  
  Course? _course;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _reorderingModules = false;
  bool _reorderingLessons = false;
  String? _currentModuleId;
  List<CourseModule> _modules = [];

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  @override
  void dispose() {
    _moduleTitleController.dispose();
    _moduleSummaryController.dispose();
    _lessonTitleController.dispose();
    _lessonDescriptionController.dispose();
    _lessonDurationController.dispose();
    _lessonVideoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar el curso
      final course = await _courseService.getCourseById(widget.courseId);
      if (course == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso não encontrado'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Cargar los módulos
      final modules = await _courseService.getModulesForCourse(widget.courseId).first;
      
      // Ordenar módulos por orden
      modules.sort((a, b) => a.order.compareTo(b.order));
      
      if (mounted) {
        setState(() {
          _course = course;
          _modules = modules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddModuleDialog() {
    // Resetear el formulario
    _moduleTitleController.text = '';
    _moduleSummaryController.text = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Módulo'),
        content: Form(
          key: _moduleFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _moduleTitleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Módulo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O título é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moduleSummaryController,
                decoration: const InputDecoration(
                  labelText: 'Resumo (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _createModule(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createModule() async {
    if (!_moduleFormKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Crear un nuevo módulo
      final newModule = CourseModule(
        id: '',
        courseId: widget.courseId,
        title: _moduleTitleController.text.trim(),
        description: _moduleSummaryController.text.trim().isNotEmpty
            ? _moduleSummaryController.text.trim()
            : '',
        order: _modules.length, // Asignar orden al final
        totalLessons: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final moduleId = await _courseService.createModule(newModule);
      
      // Añadir el módulo a la lista local con su nuevo ID
      final createdModule = CourseModule(
        id: moduleId,
        courseId: newModule.courseId,
        title: newModule.title,
        description: newModule.description,
        order: newModule.order,
        totalLessons: newModule.totalLessons,
        createdAt: newModule.createdAt,
        updatedAt: newModule.updatedAt,
      );
      
      setState(() {
        _modules.add(createdModule);
        _isSaving = false;
      });
      
      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Módulo adicionado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditModuleDialog(CourseModule module) {
    // Llenar el formulario con los datos del módulo
    _moduleTitleController.text = module.title;
    _moduleSummaryController.text = module.description;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Módulo'),
        content: Form(
          key: _moduleFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _moduleTitleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Módulo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O título é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moduleSummaryController,
                decoration: const InputDecoration(
                  labelText: 'Resumo (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _updateModule(module),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateModule(CourseModule module) async {
    if (!_moduleFormKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Actualizar el módulo
      final updatedModule = module.copyWith(
        title: _moduleTitleController.text.trim(),
        description: _moduleSummaryController.text.trim().isNotEmpty
            ? _moduleSummaryController.text.trim()
            : '',
        updatedAt: DateTime.now(),
      );
      
      await _courseService.updateModule(updatedModule);
      
      // Actualizar el módulo en la lista local
      setState(() {
        final index = _modules.indexWhere((m) => m.id == module.id);
        if (index != -1) {
          _modules[index] = updatedModule;
        }
        _isSaving = false;
      });
      
      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Módulo atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteModule(CourseModule module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Módulo'),
        content: Text(
          'Tem certeza que deseja excluir o módulo "${module.title}"?\n\n'
          'Todas as lições deste módulo também serão excluídas. Esta ação não pode ser desfeita.',
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _deleteModule(module),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteModule(CourseModule module) async {
    setState(() => _isSaving = true);
    
    try {
      // Eliminar el módulo
      await _courseService.deleteModule(module.id, widget.courseId);
      
      // Eliminar el módulo de la lista local
      setState(() {
        _modules.removeWhere((m) => m.id == module.id);
        _isSaving = false;
      });
      
      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Módulo excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddLessonDialog(String moduleId) {
    // Resetear el formulario
    _lessonTitleController.text = '';
    _lessonDescriptionController.text = '';
    _lessonDurationController.text = '';
    _lessonVideoUrlController.text = '';
    
    // Guardar el ID del módulo actual
    _currentModuleId = moduleId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Lição'),
        content: Form(
          key: _lessonFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _lessonTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da Lição',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O título é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Duração (minutos)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A duração é obrigatória';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonVideoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Vídeo (YouTube ou Vimeo)',
                    hintText: 'Ex: https://www.youtube.com/watch?v=...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A URL do vídeo é obrigatória';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _createLesson(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createLesson() async {
    if (!_lessonFormKey.currentState!.validate() || _currentModuleId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Obtener el módulo actual
      final moduleIndex = _modules.indexWhere((m) => m.id == _currentModuleId);
      if (moduleIndex == -1) {
        throw Exception('Módulo não encontrado');
      }
      final module = _modules[moduleIndex];
      
      // Crear una nueva lección
      final newLesson = CourseLesson(
        id: '',
        courseId: widget.courseId,
        moduleId: _currentModuleId!,
        title: _lessonTitleController.text.trim(),
        description: _lessonDescriptionController.text.trim().isNotEmpty
            ? _lessonDescriptionController.text.trim()
            : '',
        videoUrl: _lessonVideoUrlController.text.trim(),
        duration: int.parse(_lessonDurationController.text.trim()),
        order: module.totalLessons, // Asignar orden al final
        hasComments: true,
        complementaryMaterialUrls: [],
        complementaryMaterialNames: [],
        totalRatings: 0,
        averageRating: 0,
        ratingDistribution: const {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final lessonId = await _courseService.createLesson(newLesson);
      
      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lição adicionada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recargar los módulos para obtener la lección recién creada
        _loadCourseData();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showModuleOptions(CourseModule module) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Módulo: ${module.title}',
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              tileColor: Colors.grey[100],
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Editar Módulo'),
              onTap: () {
                Navigator.pop(context);
                _showEditModuleDialog(module);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Adicionar Lição'),
              onTap: () {
                Navigator.pop(context);
                _showAddLessonDialog(module.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir Módulo'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteModule(module);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?.title ?? 'Gerenciar Módulos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Botón para alternar el modo de reordenamiento de módulos
          if (!_isLoading && _modules.isNotEmpty)
            IconButton(
              icon: Icon(
                _reorderingModules ? Icons.done : Icons.reorder,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _reorderingModules = !_reorderingModules;
                  // Desactivar reordenamiento de lecciones al cambiar el modo
                  _reorderingLessons = false;
                });
              },
              tooltip: _reorderingModules ? 'Finalizar' : 'Reordenar Módulos',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _modules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum módulo criado',
                        style: AppTextStyles.headline3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Adicione módulos para organizar o conteúdo do curso',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddModuleDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Adicionar Módulo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _reorderingModules
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _modules.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _modules.removeAt(oldIndex);
                          _modules.insert(newIndex, item);
                          
                          // Actualizar el orden de los módulos
                          for (int i = 0; i < _modules.length; i++) {
                            _modules[i] = _modules[i].copyWith(order: i);
                          }
                        });
                        
                        // Guardar el nuevo orden en Firestore
                        _saveModuleOrder();
                      },
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        return Card(
                          key: Key(module.id),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            title: Text(
                              module.title,
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Ordem: ${index + 1} • ${module.totalLessons} lições',
                              style: AppTextStyles.caption,
                            ),
                            leading: const Icon(Icons.drag_handle),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _modules.length,
                      itemBuilder: (context, index) {
                        final module = _modules[index];
                        return _buildModuleCard(module);
                      },
                    ),
      floatingActionButton: !_isLoading && !_reorderingModules
          ? FloatingActionButton(
              onPressed: _showAddModuleDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildModuleCard(CourseModule module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del módulo con opciones
          ListTile(
            title: Text(
              module.title,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              module.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${module.totalLessons} lições',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showModuleOptions(module),
                ),
              ],
            ),
          ),
          
          // Lista de lecciones
          StreamBuilder<List<CourseLesson>>(
            stream: _courseService.getLessonsForModule(module.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erro: ${snapshot.error}'),
                  ),
                );
              }

              final lessons = snapshot.data ?? [];
              
              // Ordenar lecciones por orden
              lessons.sort((a, b) => a.order.compareTo(b.order));
              
              if (lessons.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Nenhuma lição neste módulo'),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lições',
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        // Botón para reordenar lecciones
                        if (lessons.length > 1)
                          TextButton.icon(
                            icon: Icon(
                              _reorderingLessons && _currentModuleId == module.id
                                  ? Icons.done
                                  : Icons.reorder,
                              size: 18,
                            ),
                            label: Text(
                              _reorderingLessons && _currentModuleId == module.id
                                  ? 'Finalizar'
                                  : 'Reordenar',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_reorderingLessons && _currentModuleId == module.id) {
                                  _reorderingLessons = false;
                                  _currentModuleId = null;
                                } else {
                                  _reorderingLessons = true;
                                  _currentModuleId = module.id;
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  // Lista de lecciones (normal o reordenable)
                  if (_reorderingLessons && _currentModuleId == module.id)
                    // Lista reordenable
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lessons.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = lessons.removeAt(oldIndex);
                          lessons.insert(newIndex, item);
                          
                          // Actualizar el orden de las lecciones
                          for (int i = 0; i < lessons.length; i++) {
                            lessons[i] = lessons[i].copyWith(order: i);
                          }
                        });
                        
                        // Guardar el nuevo orden en Firestore
                        _saveLessonOrder(lessons);
                      },
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        return Card(
                          key: Key(lesson.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey[100],
                          child: ListTile(
                            title: Text(
                              lesson.title,
                              style: AppTextStyles.bodyText1.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Ordem: ${index + 1} • ${_formatDuration(lesson.duration)}',
                              style: AppTextStyles.caption,
                            ),
                            leading: const Icon(Icons.drag_handle),
                          ),
                        );
                      },
                    )
                  else
                    // Lista normal
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.grey[100],
                          child: ListTile(
                            title: Text(
                              lesson.title,
                              style: AppTextStyles.bodyText1.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatDuration(lesson.duration)} • Vídeo${lesson.complementaryMaterialUrls.isNotEmpty ? ' • Materiais: ${lesson.complementaryMaterialUrls.length}' : ''}',
                              style: AppTextStyles.caption,
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditLessonDialog(lesson);
                                } else if (value == 'materials') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageLessonMaterialsScreen(lesson: lesson),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  _confirmDeleteLesson(lesson);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Editar Lição'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'materials',
                                  child: Row(
                                    children: [
                                      Icon(Icons.attach_file, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Gerenciar Materiais'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Excluir Lição'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Botón para añadir lecciones
                  if (!_reorderingLessons || _currentModuleId != module.id)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Lição'),
                        onPressed: () => _showAddLessonDialog(module.id),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditLessonDialog(CourseLesson lesson) {
    // Llenar el formulario con los datos de la lección
    _lessonTitleController.text = lesson.title;
    _lessonDescriptionController.text = lesson.description ?? '';
    _lessonDurationController.text = lesson.duration.toString();
    _lessonVideoUrlController.text = lesson.videoUrl;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Lição'),
        content: Form(
          key: _lessonFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _lessonTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da Lição',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'O título é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Duração (minutos)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A duração é obrigatória';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lessonVideoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL do Vídeo (YouTube ou Vimeo)',
                    hintText: 'Ex: https://www.youtube.com/watch?v=...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A URL do vídeo é obrigatória';
                    }
                    return null;
                  },
                ),
                // Más campos pueden ser añadidos aquí
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _updateLesson(lesson),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateLesson(CourseLesson lesson) async {
    if (!_lessonFormKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Actualizar la lección
      final updatedLesson = lesson.copyWith(
        title: _lessonTitleController.text.trim(),
        description: _lessonDescriptionController.text.trim().isNotEmpty
            ? _lessonDescriptionController.text.trim()
            : '',
        videoUrl: _lessonVideoUrlController.text.trim(),
        duration: int.parse(_lessonDurationController.text.trim()),
        updatedAt: DateTime.now(),
      );
      
      await _courseService.updateLesson(updatedLesson);
      
      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lição atualizada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmDeleteLesson(CourseLesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Lição'),
        content: Text(
          'Tem certeza que deseja excluir a lição "${lesson.title}"?\n\n'
          'Esta ação não pode ser desfeita.',
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _deleteLesson(lesson),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLesson(CourseLesson lesson) async {
    setState(() => _isSaving = true);
    
    try {
      // Eliminar la lección
      await _courseService.deleteLesson(
        lesson.id,
        lesson.moduleId,
        lesson.courseId,
      );
      
      // Cerrar el diálogo
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lição excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveModuleOrder() async {
    try {
      // Guardar el nuevo orden de los módulos en Firestore
      for (var module in _modules) {
        await _courseService.updateModule(module);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordem dos módulos atualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar a ordem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveLessonOrder(List<CourseLesson> lessons) async {
    try {
      // Guardar el nuevo orden de las lecciones en Firestore
      for (var lesson in lessons) {
        await _courseService.updateLesson(lesson);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordem das lições atualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar a ordem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
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