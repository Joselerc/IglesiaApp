import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

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

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
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
      
      for (var imageFile in _selectedImages) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('ministry_posts')
            .child('${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
        
        await ref.putFile(imageFile);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
                const Text(
                  'New Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24), // Para balancear el header
              ],
            ),
          ),
          const Divider(height: 1),

          // Área de selección de medios
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: MediaQuery.of(context).size.width, // Cuadrado
              width: double.infinity,
              color: Colors.grey[200],
              child: _selectedImages.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Select Media',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Image.file(
                      _selectedImages[0],
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // Campo de descripción
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Add description to post',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 3,
            ),
          ),

          const Spacer(),

          // Botón de Upload
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Upload Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
} 