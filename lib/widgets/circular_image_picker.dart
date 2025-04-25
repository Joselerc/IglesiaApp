import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/image_service.dart';

class CircularImagePicker extends StatefulWidget {
  final String documentId;
  final String currentImageUrl;
  final String storagePath;
  final String collectionName;
  final String fieldName;
  final Widget defaultIcon;
  final bool isEditable;
  final double size;
  final bool showEditIconOutside;

  const CircularImagePicker({
    Key? key,
    required this.documentId,
    required this.currentImageUrl,
    required this.storagePath,
    required this.collectionName,
    required this.fieldName,
    required this.defaultIcon,
    this.isEditable = true,
    this.size = 80,
    this.showEditIconOutside = false,
  }) : super(key: key);

  @override
  State<CircularImagePicker> createState() => _CircularImagePickerState();
}

class _CircularImagePickerState extends State<CircularImagePicker> {
  late final cropController = CropController();
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final image = File(pickedFile.path);
      
      // Comprimir la imagen para reducir su tamaño
      final compressedImage = await ImageService().compressImage(image, quality: 85);
      final file = compressedImage ?? image;

      // Subir la imagen a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.storagePath)
          .child('${widget.documentId}.jpg');

      // Configurar los metadatos para el tipo de archivo
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path},
      );

      await storageRef.putFile(file, metadata);
      final imageUrl = await storageRef.getDownloadURL();

      // Actualizar la URL de la imagen en Firestore
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.documentId)
          .update({widget.fieldName: imageUrl});

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  bool get isValidUrl {
    try {
      final uri = Uri.parse(widget.currentImageUrl);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.isEditable ? _pickImage : null,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.currentImageUrl.isNotEmpty && isValidUrl)
                    Image.network(
                      widget.currentImageUrl,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return widget.defaultIcon;
                      },
                    )
                  else
                    widget.defaultIcon,
                  if (_isUploading)
                    Container(
                      width: widget.size,
                      height: widget.size,
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  if (widget.isEditable && !_isUploading && !widget.showEditIconOutside)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.isEditable && !_isUploading && widget.showEditIconOutside)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 