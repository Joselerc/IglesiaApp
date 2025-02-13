import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupPostBottomSheet extends StatefulWidget {
  final String groupId;

  const GroupPostBottomSheet({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupPostBottomSheet> createState() => _GroupPostBottomSheetState();
}

class _GroupPostBottomSheetState extends State<GroupPostBottomSheet> {
  final TextEditingController _contentController = TextEditingController();
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles;
      });
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or images')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];

      // Upload images if any
      if (_selectedImages.isNotEmpty) {
        for (var image in _selectedImages) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('group_posts')
              .child('${DateTime.now().millisecondsSinceEpoch}_${image.name}');

          await storageRef.putFile(File(image.path));
          final imageUrl = await storageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      // Create post document
      await FirebaseFirestore.instance.collection('group_posts').add({
        'contentText': _contentController.text,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid),
        'groupId': FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId),
        'likes': [],
        'savedBy': [],
        'shares': [],
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
        setState(() => _isLoading = false);
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
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Write something...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.image),
              title: Text(
                _selectedImages.isEmpty
                    ? 'Add Images'
                    : '${_selectedImages.length} images selected',
              ),
              trailing: _selectedImages.isNotEmpty
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: _pickImages,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 