import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/image_service.dart';
import '../l10n/app_localizations.dart';

enum AspectRatioOption {
  square, // 1:1
  portrait, // 9:16
  landscape // 16:9
}

class CreatePostBottomSheet extends StatefulWidget {
  final String ministryId;

  const CreatePostBottomSheet({
    super.key,
    required this.ministryId,
  });

  @override
  State<CreatePostBottomSheet> createState() => _CreatePostBottomSheetState();
}

class _CreatePostBottomSheetState extends State<CreatePostBottomSheet> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  AspectRatioOption _selectedAspectRatio = AspectRatioOption.square; // Por defecto 1:1

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      
      // Comprimir las imágenes antes de añadirlas
      for (var image in images) {
        final imageFile = File(image.path);
        final compressedImage = await ImageService().compressImage(imageFile, quality: 85);
        if (compressedImage != null) {
          setState(() {
            _selectedImages.add(compressedImage);
          });
        } else {
          // Si la compresión falla, usar la original
          setState(() {
            _selectedImages.add(imageFile);
          });
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    // Validar contenido (no vacío después de quitar espacios)
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseAddContentOrImages)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Referencia al documento del ministerio
      final ministryRef = FirebaseFirestore.instance
          .collection('ministries')
          .doc(widget.ministryId);

      // Obtener ID del usuario actual
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Referencia al documento del usuario
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Lista para almacenar URLs de imágenes
      final List<String> imageUrls = [];

      // Subir imágenes si hay alguna seleccionada
      if (_selectedImages.isNotEmpty) {
        for (var imageFile in _selectedImages) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('ministry_posts')
              .child(widget.ministryId)
              .child(fileName);

          // Crear metadatos para la imagen
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'aspectRatio': _selectedAspectRatio.toString(),
              'compressed': 'true',
              'uploadedBy': userId,
            },
          );

          // Subir imagen
          await storageRef.putFile(imageFile, metadata);

          // Obtener URL de descarga
          final imageUrl = await storageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      // Crear documento de post
      await FirebaseFirestore.instance.collection('ministry_posts').add({
        'ministryId': ministryRef,
        'authorId': userRef,
        'contentText': content,
        'imageUrls': imageUrls,
        'aspectRatio': _selectedAspectRatio.toString(), // Guardar la relación de aspecto seleccionada
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'savedBy': [],
        'shares': [],
        'comments': [],
        'commentCount': 0,
      });

      // Cerrar bottom sheet
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.postCreatedSuccessfully)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorCreatingPost}: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  AppLocalizations.of(context)!.newPost,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _createPost,
                      ),
              ],
            ),
          ),

          // Contenido scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de texto
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.whatDoYouWantToShare,
                      border: InputBorder.none,
                    ),
                    maxLines: 5,
                    minLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Imágenes seleccionadas
                  if (_selectedImages.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.selectedImages,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Selector de relación de aspecto
                    if (_selectedImages.isNotEmpty) ...[
                      Text(
                        AppLocalizations.of(context)!.imageAspectRatio,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAspectRatioOption(
                            AspectRatioOption.square,
                            '1:1',
                            AppLocalizations.of(context)!.square,
                          ),
                          _buildAspectRatioOption(
                            AspectRatioOption.portrait,
                            '9:16',
                            AppLocalizations.of(context)!.vertical,
                          ),
                          _buildAspectRatioOption(
                            AspectRatioOption.landscape,
                            '16:9',
                            AppLocalizations.of(context)!.horizontal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Vista previa de relación de aspecto
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: _getAspectRatioValue(),
                            child: Image.file(
                              _selectedImages.first,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Botón para seleccionar imágenes
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image),
                      label: Text(
                        _selectedImages.isEmpty
                            ? AppLocalizations.of(context)!.addImages
                            : AppLocalizations.of(context)!.addMoreImages,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón de publicar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        AppLocalizations.of(context)!.publish,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para opción de relación de aspecto
  Widget _buildAspectRatioOption(AspectRatioOption option, String ratio, String label) {
    final isSelected = _selectedAspectRatio == option;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAspectRatio = option;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              ratio,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Obtener valor numérico de la relación de aspecto
  double _getAspectRatioValue() {
    switch (_selectedAspectRatio) {
      case AspectRatioOption.square:
        return 1.0; // 1:1
      case AspectRatioOption.portrait:
        return 9.0 / 16.0; // 9:16
      case AspectRatioOption.landscape:
        return 16.0 / 9.0; // 16:9
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
} 