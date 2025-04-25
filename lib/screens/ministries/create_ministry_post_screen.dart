import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../services/image_service.dart';

class CreateMinistryPostScreen extends StatefulWidget {
  final String ministryId;

  const CreateMinistryPostScreen({
    super.key,
    required this.ministryId,
  });

  @override
  State<CreateMinistryPostScreen> createState() => _CreateMinistryPostScreenState();
}

class _CreateMinistryPostScreenState extends State<CreateMinistryPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

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
    if (_contentController.text.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega texto o imágenes para crear el post')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> imageUrls = [];
      
      // Subir imágenes si hay alguna seleccionada
      for (var imageFile in _selectedImages) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('ministry_posts')
            .child(fileName);
        
        // Crear metadatos para la imagen
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'compressed': 'true',
            'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
          },
        );
        
        await ref.putFile(imageFile, metadata);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Crear el post en Firestore
      await FirebaseFirestore.instance.collection('ministry_posts').add({
        'contentText': _contentController.text,
        'imageUrls': imageUrls,
        'ministryId': FirebaseFirestore.instance
            .collection('ministries')
            .doc(widget.ministryId),
        'authorId': FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': [],
        'shares': [],
        'savedBy': [],
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el post: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publicar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Campo de texto
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '¿Qué quieres compartir?',
                  border: InputBorder.none,
                ),
              ),
            ),

            // Visualización de imágenes seleccionadas
            if (_selectedImages.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: _pickImages,
            ),
            // Aquí puedes agregar más opciones como ubicación, etiquetas, etc.
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}