import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventBasicInfoStep extends StatefulWidget {
  final Function(String title, String category, String description, String? imageUrl) onNext;
  final VoidCallback onCancel;
  final String? initialTitle;
  final String? initialCategory;
  final String? initialDescription;
  final String? initialImageUrl;

  const EventBasicInfoStep({
    super.key,
    required this.onNext,
    required this.onCancel,
    this.initialTitle,
    this.initialCategory,
    this.initialDescription,
    this.initialImageUrl,
  });

  @override
  State<EventBasicInfoStep> createState() => _EventBasicInfoStepState();
}

class _EventBasicInfoStepState extends State<EventBasicInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _selectedCategory;
  List<String> _categories = [];
  List<String> _hiddenCategories = []; // Lista de categorías ocultas
  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;
    _loadHiddenCategories().then((_) => _loadCategories());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Cargar las categorías ocultas desde SharedPreferences
  Future<void> _loadHiddenCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _hiddenCategories = prefs.getStringList('hiddenEventCategories') ?? [];
      });
    } catch (e) {
      debugPrint('Error al cargar categorías ocultas: $e');
    }
  }

  // Guardar las categorías ocultas en SharedPreferences
  Future<void> _saveHiddenCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hiddenEventCategories', _hiddenCategories);
    } catch (e) {
      debugPrint('Error al guardar categorías ocultas: $e');
    }
  }

  // Ocultar una categoría
  Future<void> _hideCategory(String category) async {
    // Primero confirmar con el usuario
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ocultar categoria'),
        content: Text('A categoria "$category" não aparecerá mais na lista de categorias disponíveis. Esta ação não afeta eventos existentes.\n\nDeseja continuar?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ocultar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _hiddenCategories.add(category);
      _categories.remove(category);
      
      // Si la categoría oculta era la seleccionada, deseleccionarla
      if (_selectedCategory == category) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      }
    });
    
    await _saveHiddenCategories();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoria "$category" ocultada'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              setState(() {
                _hiddenCategories.remove(category);
              });
              await _saveHiddenCategories();
              await _loadCategories();
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('eventCategories')
          .orderBy('name')
          .get();
      
      final allCategories = snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      
      setState(() {
        // Filtrar las categorías ocultas
        _categories = allCategories.where((category) => !_hiddenCategories.contains(category)).toList();
        _isLoading = false;
        
        // Si la categoría seleccionada ya no está disponible (porque se ocultó), seleccionar la primera disponible
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
      }
    }
  }

  Future<void> _createCategory() async {
    final TextEditingController categoryController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Nova Categoria'),
        content: TextField(
          controller: categoryController,
          decoration: const InputDecoration(
            labelText: 'Nome da Categoria',
            hintText: 'Digite o nome da categoria',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (categoryController.text.trim().isNotEmpty) {
                setState(() {
                  _isLoading = true;
                });
                
                try {
                  await FirebaseFirestore.instance
                      .collection('eventCategories')
                      .add({
                    'name': categoryController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadCategories();
                    setState(() {
                      _selectedCategory = categoryController.text.trim();
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar categoria: $e')),
                    );
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Limitar tamaño máximo
        maxHeight: 1080,
      );
      
      if (image != null) {
        setState(() {
          // Mostrar loading mientras se sube la imagen
          _isUploadingImage = true;
        });

        // Crear referencia única para la imagen
        final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child('$fileName.jpg');

        // Subir imagen
        final UploadTask uploadTask = storageRef.putFile(File(image.path));

        // Mostrar progreso
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          // Aquí podrías actualizar un indicador de progreso si quisieras
        });

        // Esperar a que se complete la subida y obtener URL
        final TaskSnapshot taskSnapshot = await uploadTask;
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer upload da imagem: $e')),
        );
      }
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: MediaQuery.of(context).size.width * 9 / 16, // Proporción 16:9
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isUploadingImage
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fazendo upload da imagem...',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  ],
                ),
              )
            : _imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                    : null,
                                color: AppColors.primary,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => 
                            const Center(child: Icon(Icons.error, color: Colors.red, size: 40)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _imageUrl = null;
                              });
                            },
                            tooltip: 'Excluir imagem',
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.photo, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Toque para alterar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, 
                           size: 48, 
                           color: AppColors.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('Adicionar Imagem do Evento (16:9)',
                           style: TextStyle(
                             color: AppColors.textPrimary,
                             fontWeight: FontWeight.w500,
                             fontSize: 16,
                           )),
                      const SizedBox(height: 8),
                      Text('Tamanho recomendado: 1920x1080',
                           style: TextStyle(
                             color: AppColors.textSecondary,
                             fontSize: 13,
                           )),
                    ],
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y subtítulo
                Text(
                  'Informações Básicas',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina os dados essenciais do seu evento',
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              
                // Texto explicativo
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Adicione as informações básicas sobre o seu evento.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Selector de imagen
                _buildImagePicker(),
                const SizedBox(height: 24),
                
                // Campos de formulario
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Evento',
                    hintText: 'Escreva um título claro e descritivo',
                    prefixIcon: Icon(Icons.event, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    floatingLabelStyle: TextStyle(color: AppColors.primary),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o nome do evento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Categoría
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Selecione uma categoria',
                    prefixIcon: Icon(Icons.category, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                      tooltip: 'Criar nova categoria',
                      onPressed: _createCategory,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    floatingLabelStyle: TextStyle(color: AppColors.primary),
                  ),
                  items: _categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () {
                              // Cerrar el desplegable y luego mostrar confirmación
                              Navigator.of(context).pop();
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _hideCategory(category);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma categoria';
                    }
                    return null;
                  },
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  menuMaxHeight: 300,
                  selectedItemBuilder: (context) {
                    return _categories.map((category) {
                      return Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      );
                    }).toList();
                  },
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descreva os detalhes do evento',
                    prefixIcon: Icon(Icons.description, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    alignLabelWithHint: true,
                    floatingLabelStyle: TextStyle(color: AppColors.primary),
                  ),
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira uma descrição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Botones de navegación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading || _isUploadingImage 
                          ? null 
                          : () {
                              if (_formKey.currentState!.validate()) {
                                widget.onNext(
                                  _titleController.text.trim(),
                                  _selectedCategory!,
                                  _descriptionController.text.trim(),
                                  _imageUrl,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                      label: const Text(
                        'Avançar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Espacio adicional para alejar los botones del borde inferior
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 