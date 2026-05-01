import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/image_service.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';

enum AspectRatioOption {
  square,
  portrait,
  landscape
}

enum PostComposerEntityType { group, ministry }

class CreateGroupPostBottomSheet extends StatefulWidget {
  final String? groupId;
  final String? ministryId;
  final PostComposerEntityType entityType;

  const CreateGroupPostBottomSheet({
    super.key,
    this.groupId,
    this.ministryId,
    this.entityType = PostComposerEntityType.group,
  }) : assert(
          (entityType == PostComposerEntityType.group && groupId != null) ||
              (entityType == PostComposerEntityType.ministry && ministryId != null),
        );

  @override
  State<CreateGroupPostBottomSheet> createState() => _CreateGroupPostBottomSheetState();
}

class _CreateGroupPostBottomSheetState extends State<CreateGroupPostBottomSheet> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  AspectRatioOption _selectedAspectRatio = AspectRatioOption.square;

  String get _entityId => widget.entityType == PostComposerEntityType.group
      ? widget.groupId!
      : widget.ministryId!;
  String get _entityCollection => widget.entityType == PostComposerEntityType.group
      ? 'groups'
      : 'ministries';
  String get _postCollection => widget.entityType == PostComposerEntityType.group
      ? 'group_posts'
      : 'ministry_posts';
  String get _entityField => widget.entityType == PostComposerEntityType.group
      ? 'groupId'
      : 'ministryId';
  String get _adminField => widget.entityType == PostComposerEntityType.group
      ? 'groupAdmin'
      : 'ministrieAdmin';

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
      
      for (var image in images) {
        final imageFile = File(image.path);
        final compressedImage = await ImageService().compressImage(imageFile, quality: 85);
        if (compressedImage != null) {
          setState(() {
            _selectedImages.add(compressedImage);
          });
        } else {
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
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseAddContent)),
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final entityRef = FirebaseFirestore.instance.collection(_entityCollection).doc(_entityId);
      final List<String> imageUrls = [];

      if (_selectedImages.isNotEmpty) {
        for (var imageFile in _selectedImages) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child(_postCollection)
              .child(_entityId)
              .child(fileName);

          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'aspectRatio': _selectedAspectRatio.toString(),
              'compressed': 'true',
              'uploadedBy': userId,
            },
          );

          await storageRef.putFile(imageFile, metadata);
          final imageUrl = await storageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }
      }

      final postRef = await FirebaseFirestore.instance.collection(_postCollection).add({
        'contentText': content,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': userRef,
        _entityField: entityRef,
        'imageUrls': imageUrls,
        'aspectRatio': _selectedAspectRatio.toString(),
        'likes': [],
        'savedBy': [],
        'shares': [],
        'commentCount': 0,
      });

      // Notificación
      try {
        final entityDoc = await entityRef.get();
        if (entityDoc.exists) {
          final data = entityDoc.data() as Map<String, dynamic>;
          final entityName = data['name'] ?? (widget.entityType == PostComposerEntityType.group ? 'Grupo' : 'Ministerio');
          final memberIds = <String>[];
            
          if (data['members'] != null) {
            for (var member in (data['members'] as List)) {
              if (member is DocumentReference) {
                memberIds.add(member.id);
              } else if (member is String) {
                memberIds.add(member.startsWith('/users/') ? member.split('/').last : member);
              }
            }
          }
          if (data[_adminField] != null) {
            for (var admin in (data[_adminField] as List)) {
              String? adminId;
              if (admin is DocumentReference) {
                adminId = admin.id;
              } else if (admin is String) {
                adminId = admin.startsWith('/users/') ? admin.split('/').last : admin;
              }
              if (adminId != null && !memberIds.contains(adminId)) {
                memberIds.add(adminId);
              }
            }
          }

          final title = content.isNotEmpty
              ? (content.length > 50 ? '${content.substring(0, 50)}...' : content)
              : 'Nueva publicación';
          if (widget.entityType == PostComposerEntityType.group) {
            await notificationService.sendGroupNewPostNotification(
              groupId: _entityId,
              groupName: entityName,
              postId: postRef.id,
              postTitle: title,
              memberIds: memberIds,
            );
          } else {
            await notificationService.sendMinistryNewPostNotification(
              ministryId: _entityId,
              ministryName: entityName,
              postId: postRef.id,
              postTitle: title,
              memberIds: memberIds,
            );
          }
        }
      } catch (e) {
        debugPrint('Error notificando publicación: $e');
      }

      if (context.mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.postCreatedSuccessfully)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${l10n.errorCreatingPost}: $e')),
        );
      }
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  AppLocalizations.of(context)!.createOrEdit,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.publish),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.whatDoYouWantToShare,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    style: const TextStyle(fontSize: 18),
                    maxLines: null,
                    minLines: 3,
                  ),
                  
                  const SizedBox(height: 20),

                  if (_selectedImages.isNotEmpty) 
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: _getAspectRatioValue(),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
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
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _pickImages,
                      icon: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                      tooltip: AppLocalizations.of(context)!.addImages,
                    ),
                    const SizedBox(width: 16),
                    if (_selectedImages.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildAspectRatioChip(AspectRatioOption.square, AppLocalizations.of(context)!.square),
                              const SizedBox(width: 8),
                              _buildAspectRatioChip(AspectRatioOption.portrait, AppLocalizations.of(context)!.vertical),
                              const SizedBox(width: 8),
                              _buildAspectRatioChip(AspectRatioOption.landscape, AppLocalizations.of(context)!.horizontal),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioChip(AspectRatioOption option, String label) {
    final isSelected = _selectedAspectRatio == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAspectRatio = option;
          });
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  double _getAspectRatioValue() {
    switch (_selectedAspectRatio) {
      case AspectRatioOption.square: return 1.0;
      case AspectRatioOption.portrait: return 4.0 / 5.0;
      case AspectRatioOption.landscape: return 16.0 / 9.0;
    }
  }
}