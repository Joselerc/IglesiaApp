import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'manage_course_modules_screen.dart';
import '../../l10n/app_localizations.dart';

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
  bool _commentsEnabled = true;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  File? _imageFile;
  String? _imageUrl;
  
  bool get _isEditing => widget.course != null;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _userDisplayName => FirebaseAuth.instance.currentUser?.displayName ?? AppLocalizations.of(context)!.instructor;

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
      _commentsEnabled = widget.course!.commentsEnabled;
      _imageUrl = widget.course!.imageUrl;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Preparar imagem se foi selecionada
      if (_isEditing && _imageFile != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });
        
        _imageUrl = await _courseService.uploadCourseImage(
          _imageFile!,
          widget.course!.id,
          isCardImage: false,
        );
        
        setState(() => _uploadProgress = 1.0);
      }
      
      // Crear objeto Course
      final course = Course(
        id: _isEditing ? widget.course!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrl ?? '',
        cardImageUrl: null, // Eliminado completamente
        instructorId: _isEditing ? widget.course!.instructorId : _userId,
        instructorName: _instructorNameController.text.trim(),
        category: _categoryController.text.trim(),
        totalDuration: _isEditing ? widget.course!.totalDuration : 0,
        status: _selectedStatus,
        createdAt: _isEditing ? widget.course!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        publishedAt: _selectedStatus == CourseStatus.published 
            ? (_isEditing ? widget.course!.publishedAt : DateTime.now()) 
            : null,
        isFeatured: false, // Eliminado la funcionalidad
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.courseUpdatedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context);
        }
      } else {
        final newCourseId = await _courseService.createCourse(course);
        
        // Hacer upload de la imagen con el ID recién-creado
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
          
          setState(() => _uploadProgress = 1.0);
          
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.courseCreatedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          
          // Preguntar al usuario si desea agregar módulos ahora
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.addModules),
            content: Text(AppLocalizations.of(context)!.addModulesNow),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    Navigator.pop(context); // Volver a la lista de cursos
                  },
                  child: Text(AppLocalizations.of(context)!.later),
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
                  child: Text(AppLocalizations.of(context)!.yesAddNow),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isEditing ? AppLocalizations.of(context)!.editCourse : AppLocalizations.of(context)!.createNewCourse),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header informativo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? AppLocalizations.of(context)!.editCourse : AppLocalizations.of(context)!.createNewCourse,
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.fillCourseInfo,
                                style: AppTextStyles.bodyText2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Card principal do formulário
                  Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título do curso
                          _buildFormField(
                            label: AppLocalizations.of(context)!.courseTitle,
                            controller: _titleController,
                            hint: AppLocalizations.of(context)!.courseTitleHint,
                            icon: Icons.title,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)!.titleRequired;
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Descrição
                          _buildFormField(
                            label: AppLocalizations.of(context)!.description,
                            controller: _descriptionController,
                            hint: AppLocalizations.of(context)!.descriptionHint,
                            icon: Icons.description,
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)!.descriptionRequired;
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Imagem de capa melhorada
                          _buildImageSection(),
                          
                          const SizedBox(height: 20),
                          
                          // Categoria
                          _buildFormField(
                            label: AppLocalizations.of(context)!.category,
                            controller: _categoryController,
                            hint: AppLocalizations.of(context)!.categoryHint,
                            icon: Icons.category,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)!.categoryRequired;
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Instrutor
                          _buildFormField(
                            label: AppLocalizations.of(context)!.instructorName,
                            controller: _instructorNameController,
                            hint: AppLocalizations.of(context)!.instructorNameHint,
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(context)!.instructorRequired;
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Status
                          _buildStatusDropdown(),
                          
                          const SizedBox(height: 20),
                          
                          // Permitir comentários (fora de opciones adicionales)
                          _buildCommentsSwitch(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón salvar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEditing ? Icons.update : Icons.add_circle_outline),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? AppLocalizations.of(context)!.updateCourse : AppLocalizations.of(context)!.createCourse,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Nota sobre la duración
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.courseDurationNote,
                              style: TextStyle(color: Colors.blue[700], fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
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
                      label: Text(AppLocalizations.of(context)!.manageModulesAndLessons),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.coverImage,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.coverImageDescription,
          style: AppTextStyles.bodyText2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: _imageFile != null || _imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : NetworkImage(_imageUrl!) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Overlay para indicar que es clickeable
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.tapToChange,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.tapToAddImage,
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.recommendedSize,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.courseStatus,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CourseStatus>(
          value: _selectedStatus,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.visibility, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem<CourseStatus>(
              value: CourseStatus.published,
              child: Text(AppLocalizations.of(context)!.published),
            ),
            DropdownMenuItem<CourseStatus>(
              value: CourseStatus.draft,
              child: Text(AppLocalizations.of(context)!.draft),
            ),
            DropdownMenuItem<CourseStatus>(
              value: CourseStatus.upcoming,
              child: Text(AppLocalizations.of(context)!.upcoming),
            ),
            DropdownMenuItem<CourseStatus>(
              value: CourseStatus.archived,
              child: Text(AppLocalizations.of(context)!.archived),
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
      ],
    );
  }

  Widget _buildCommentsSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.allowComments,
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.studentsCanComment,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _commentsEnabled,
            onChanged: (value) {
              setState(() {
                _commentsEnabled = value;
              });
            },
            activeColor: AppColors.primary,
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
            Text(AppLocalizations.of(context)!.uploadingImages),
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
            Text(AppLocalizations.of(context)!.savingCourse),
          ],
        ],
      ),
    );
  }
} 