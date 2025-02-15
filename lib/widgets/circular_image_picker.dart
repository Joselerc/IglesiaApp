import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';

class CircularImagePicker extends StatefulWidget {
  final String documentId;
  final String currentImageUrl;
  final String storagePath;
  final String collectionName;
  final String fieldName;
  final double radius;
  final Widget? defaultIcon;
  final bool isEditable;

  const CircularImagePicker({
    super.key,
    required this.documentId,
    required this.currentImageUrl,
    required this.storagePath,
    required this.collectionName,
    required this.fieldName,
    this.radius = 60,
    this.defaultIcon = const Icon(Icons.person, size: 60),
    this.isEditable = true,
  });

  @override
  State<CircularImagePicker> createState() => _CircularImagePickerState();
}

class _CircularImagePickerState extends State<CircularImagePicker> {
  late final cropController = CropController();

  Future<void> _updateImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;

      final bytes = await image.readAsBytes();
      Uint8List? croppedBytes;

      await showDialog(
        context: context,
        builder: (context) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Crop Image'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => cropController.crop(),
                ),
              ],
            ),
            body: Crop(
              image: bytes,
              controller: cropController,
              aspectRatio: 1,
              initialSize: 0.8,
              withCircleUi: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withOpacity(0.6),
              onCropped: (value) {
                croppedBytes = value;
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );

      if (croppedBytes == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp.jpg');
      await tempFile.writeAsBytes(croppedBytes!);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.storagePath)
          .child('${widget.documentId}.jpg');

      if (widget.currentImageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(widget.currentImageUrl).delete();
        } catch (e) {
          debugPrint('Error deleting old image: $e');
        }
      }

      await storageRef.putFile(tempFile);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.documentId)
          .update({widget.fieldName: imageUrl});

      await tempFile.delete();
      await tempDir.delete();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating image: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable ? () => _updateImage(context) : null,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundImage: widget.currentImageUrl.isNotEmpty
            ? NetworkImage(widget.currentImageUrl)
            : null,
        child: widget.currentImageUrl.isEmpty ? widget.defaultIcon : null,
      ),
    );
  }
} 