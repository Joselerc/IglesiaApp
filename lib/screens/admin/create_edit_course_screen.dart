import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'manage_course_modules_screen.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final Course? course;

  const CreateEditCourseScreen({Key? key, this.course}) : super(key: key);

  @override
  State<CreateEditCourseScreen> createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseService = CourseService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _instructorNameController = TextEditingController();
  
  CourseStatus _selectedStatus = CourseStatus.draft;
  bool _isFeatured = false;
  bool _commentsEnabled = true;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  File? _imageFile;
  File? _cardImageFile;
  String? _imageUrl;
  String? _cardImageUrl;
  
  bool get _isEditing => widget.course != null;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _userDisplayName => FirebaseAuth.instance.currentUser?.displayName ?? 'Instrutor';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Preencher formulário com dados do curso existente
      _titleController.text = widget.course!.title;
      _descriptionController.text = widget.course!.description;
      _categoryController.text = widget.course!.category;
      _instructorNameController.text = widget.course!.instructorName;
      _selectedStatus = widget.course!.status;
      _isFeatured = widget.course!.isFeatured;
      _commentsEnabled = widget.course!.commentsEnabled;
      _imageUrl = widget.course!.imageUrl;
      _cardImageUrl = widget.course!.cardImageUrl;
    } else {
      // Preencher nome do instrutor com o nome do usuário atual
      _instructorNameController.text = _userDisplayName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _instructorNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCardImage) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        if (isCardImage) {
          _cardImageFile = File(pickedFile.path);
        } else {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Preparar imagens se foram selecionadas
      if (_isEditing) {
        if (_imageFile != null) {
          setState(() {
            _isUploading = true;
            _uploadProgress = 0.0;
          });
          
          _imageUrl = await _courseService.uploadCourseImage(
            _imageFile!,
            widget.course!.id,
            isCardImage: false,
          );
          
          setState(() => _uploadProgress = 0.5);
        }
        
        if (_cardImageFile != null) {
          _cardImageUrl = await _courseService.uploadCourseImage(
            _cardImageFile!,
            widget.course!.id,
            isCardImage: true,
          );
          
          setState(() => _uploadProgress = 1.0);
        }
      }
      
      // Crear objeto Course
      final course = Course(
        id: _isEditing ? widget.course!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl ?? '',
        cardImageUrl: _cardImageUrl,
        instructorId: _isEditing ? widget.course!.instructorId : _userId,
        instructorName: _instructorNameController.text.trim(),
        category: _categoryController.text.trim(),
        totalDuration: _isEditing ? widget.course!.totalDuration : 0, // Se calculará automáticamente
        status: _selectedStatus,
        createdAt: _isEditing ? widget.course!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: _selectedStatus == CourseStatus.published 
            ? (_isEditing ? widget.course!.publishedAt : DateTime.now()) 
            : null,
        isFeatured: _isFeatured,
        commentsEnabled: _commentsEnabled,
        enrolledUsers: _isEditing ? widget.course!.enrolledUsers : [],
        totalModules: _isEditing ? widget.course!.totalModules : 0,
        totalLessons: _isEditing ? widget.course!.totalLessons : 0,
      );
      
      // Guardar en Firestore
      if (_isEditing) {
        await _courseService.updateCourse(course);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        final newCourseId = await _courseService.createCourse(course);
        
        // Hacer upload de las imágenes con el ID recién-creado
        if (_imageFile != null) {
          setState(() {
            _isUploading = true;
            _uploadProgress = 0.0;
          });
          
          final imageUrl = await _courseService.uploadCourseImage(
            _imageFile!,
            newCourseId,
            isCardImage: false,
          );
          
          setState(() => _uploadProgress = 0.5);
          
          // Actualizar el curso con la URL de la imagen
          if (imageUrl != null) {
            await _courseService.updateCourse(
              course.copyWith(
                id: newCourseId,
                imageUrl: imageUrl,
              ),
            );
          }
        }
        
        if (_cardImageFile != null) {
          final cardImageUrl = await _courseService.uploadCourseImage(
            _cardImageFile!,
            newCourseId,
            isCardImage: true,
          );
          
          setState(() => _uploadProgress = 1.0);
          
          // Actualizar el curso con la URL de la imagen del card
          if (cardImageUrl != null) {
            await _courseService.updateCourse(
              course.copyWith(
                id: newCourseId,
                cardImageUrl: cardImageUrl,
              ),
            );
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Curso criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Preguntar al usuario si desea agregar módulos ahora
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Adicionar Módulos'),
              content: const Text('Deseja adicionar módulos ao curso agora?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    Navigator.pop(context); // Volver a la lista de cursos
                  },
                  child: const Text('Mais tarde'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    Navigator.pop(context); // Volver a la lista de cursos
                    
                    // Navegar a la pantalla de administración de módulos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageCourseModulesScreen(
                          courseId: newCourseId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sim, adicionar agora'),
                ),
              ],
            ),
          );
        }
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
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Curso' : 'Criar Novo Curso'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Título do curso
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título do Curso',
                      hintText: 'Ex: Fundamentos da Bíblia',
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
                  
                  // Descrição
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Descreva o conteúdo do curso...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'A descrição é obrigatória';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Imagem de capa
                  _buildImagePicker(
                    title: 'Imagem de Capa',
                    description: 'Esta imagem será exibida na página de detalhes do curso',
                    imageFile: _imageFile,
                    imageUrl: _imageUrl,
                    onPick: () => _pickImage(false),
                  ),
                  const SizedBox(height: 16),
                  
                  // Imagem do card
                  _buildImagePicker(
                    title: 'Imagem do Card (Opcional)',
                    description: 'Esta imagem será exibida no card do curso na página inicial',
                    imageFile: _cardImageFile,
                    imageUrl: _cardImageUrl,
                    onPick: () => _pickImage(true),
                    isOptional: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Categoria
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      hintText: 'Ex: Teologia',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'A categoria é obrigatória';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Instrutor
                  TextFormField(
                    controller: _instructorNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Instrutor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome do instrutor é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Status
                  DropdownButtonFormField<CourseStatus>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    dropdownColor: Colors.white,
                    items: [
                      DropdownMenuItem<CourseStatus>(
                        value: CourseStatus.published,
                        child: const Text('Publicado'),
                      ),
                      DropdownMenuItem<CourseStatus>(
                        value: CourseStatus.draft,
                        child: const Text('Rascunho'),
                      ),
                      DropdownMenuItem<CourseStatus>(
                        value: CourseStatus.upcoming,
                        child: const Text('Em breve'),
                      ),
                      DropdownMenuItem<CourseStatus>(
                        value: CourseStatus.archived,
                        child: const Text('Arquivado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Opções adicionais
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opções Adicionais',
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Switch: Destacar na página inicial
                          SwitchListTile(
                            title: const Text('Destacar na Página Inicial'),
                            subtitle: const Text('O curso aparecerá em destaque na seção de cursos'),
                            value: _isFeatured,
                            onChanged: (value) {
                              setState(() {
                                _isFeatured = value;
                              });
                            },
                          ),
                          
                          // Switch: Permitir comentários
                          SwitchListTile(
                            title: const Text('Permitir Comentários'),
                            subtitle: const Text('Os alunos poderão comentar nas lições'),
                            value: _commentsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _commentsEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón salvar
                  ElevatedButton(
                    onPressed: _saveCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Atualizar Curso' : 'Criar Curso',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Nota sobre la duración
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'A duração total do curso é calculada automaticamente com base na duração das lições.',
                                style: TextStyle(color: Colors.blue[700], fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Botón para administrar módulos (solo para cursos existentes)
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageCourseModulesScreen(courseId: widget.course!.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.library_books),
                      label: const Text('Gerenciar Módulos e Lições'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required String description,
    required File? imageFile,
    required String? imageUrl,
    required VoidCallback onPick,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOptional)
                Text(
                  ' (Opcional)',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyText2.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Previsualização da imagem
          if (imageFile != null || imageUrl != null)
            AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: imageFile != null
                        ? FileImage(imageFile)
                        : NetworkImage(imageUrl!) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 16/9,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          // Recomendación para proporción de imagen
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Recomendado: Imagem com proporção 16:9',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Botão para selecionar imagem
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  imageFile != null || imageUrl != null
                      ? 'Trocar Imagem'
                      : 'Selecionar Imagem',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isUploading) ...[
            const Text('Enviando imagens...'),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text('${(_uploadProgress * 100).toInt()}%'),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Salvando curso...'),
          ],
        ],
      ),
    );
  }
} 