import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/image_service.dart';

class CreatePostModal extends StatefulWidget {
  final String ministryId;

  const CreatePostModal({
    super.key,
    required this.ministryId,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final TextEditingController contentController = TextEditingController();
  List<File> selectedImages = [];
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });
      
      // Comprimir la imagen antes de añadirla
      final imageFile = File(pickedFile.path);
      final compressedImage = await ImageService().compressImage(imageFile, quality: 85);
      
      setState(() {
        selectedImages.add(compressedImage ?? imageFile);
        isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    if (contentController.text.isEmpty && selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or images')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      List<String> imageUrls = [];
      
      // Subir imágenes si hay alguna seleccionada
      for (var image in selectedImages) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg';
        final storageRef = FirebaseStorage.instance
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

        await storageRef.putFile(image, metadata);
        final imageUrl = await storageRef.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Crear el post
      await FirebaseFirestore.instance.collection('ministry_posts').add({
        'contentText': contentController.text,
        'imageUrls': imageUrls,
        'ministryId': FirebaseFirestore.instance
            .collection('ministries')
            .doc(widget.ministryId),
        'authorId': FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'shares': [],
        'savedBy': [],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Text(
                  'Create Post',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: isLoading ? null : _createPost,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: InputBorder.none,
              ),
            ),
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_photo_alternate),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedImages.removeAt(index);
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
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: _pickImage,
                ),
                // Aquí puedes agregar más botones para otras funcionalidades
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
} 