import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
    super.key,
    required this.documentId,
    required this.currentImageUrl,
    required this.storagePath,
    required this.collectionName,
    required this.fieldName,
    required this.defaultIcon,
    this.isEditable = true,
    this.size = 80,
    this.showEditIconOutside = false,
  });

  @override
  State<CircularImagePicker> createState() => _CircularImagePickerState();
}

class _CircularImagePickerState extends State<CircularImagePicker> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();
      final croppedFile = await _cropToCircle(bytes);
      if (croppedFile == null) return;

      setState(() => _isUploading = true);

      final compressedImage =
          await ImageService().compressImage(croppedFile, quality: 85);
      final file = compressedImage ?? croppedFile;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.storagePath)
          .child('${widget.documentId}.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path},
      );

      await storageRef.putFile(file, metadata);
      final imageUrl = await storageRef.getDownloadURL();

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
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  strings != null ? strings.somethingWentWrong : 'Error: $e')),
        );
      }
    }
  }

  Future<File?> _cropToCircle(Uint8List bytes) async {
    final parentContext = context;
    final croppedBytes = await showDialog<Uint8List>(
      // ignore: use_build_context_synchronously
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = CropController();
        bool isCropping = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: isCropping
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check, color: Colors.white),
                            onPressed: isCropping
                                ? null
                                : () {
                                    setState(() => isCropping = true);
                                    controller.crop();
                                  },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Crop(
                          controller: controller,
                          image: bytes,
                          aspectRatio: 1,
                          withCircleUi: true,
                          maskColor: Colors.black.withValues(alpha: 0.55),
                          onCropped: (data) {
                            Navigator.pop(dialogContext, data);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (croppedBytes == null) return null;
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = await File(filePath).writeAsBytes(croppedBytes);
    return file;
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
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  if (widget.isEditable &&
                      !_isUploading &&
                      !widget.showEditIconOutside)
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
