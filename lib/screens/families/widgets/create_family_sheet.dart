import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/family_group_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../services/image_service.dart';
import 'modal_sheet_scaffold.dart';
import 'package:path_provider/path_provider.dart';

Future<void> showCreateFamilySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const CreateFamilySheet(),
  );
}

class CreateFamilySheet extends StatelessWidget {
  const CreateFamilySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ModalSheetScaffold(
      title: strings.createFamily,
      child: const CreateFamilyForm(
        closeOnSuccess: true,
      ),
    );
  }
}

class CreateFamilyForm extends StatefulWidget {
  const CreateFamilyForm({
    super.key,
    this.closeOnSuccess = false,
  });

  final bool closeOnSuccess;

  @override
  State<CreateFamilyForm> createState() => _CreateFamilyFormState();
}

class _CreateFamilyFormState extends State<CreateFamilyForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FamilyGroupService _familyService = FamilyGroupService();
  bool _isSaving = false;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final cropped = await _cropToCircle(file.path);
      if (cropped != null) {
        setState(() {
          _selectedImage = File(cropped);
        });
      }
    }
  }

  Future<String?> _cropToCircle(String path) async {
    final parentContext = context;
    final imageBytes = await File(path).readAsBytes();
    final croppedBytes = await showDialog<Uint8List>(
      // ignore: use_build_context_synchronously
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        final controller = CropController();
        bool isCropping = false;
        final strings = AppLocalizations.of(parentContext)!;
        final scheme = Theme.of(parentContext).colorScheme;
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
                          Expanded(
                            child: Text(
                              strings.edit,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle1
                                  .copyWith(color: Colors.white),
                            ),
                          ),
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
                                : () async {
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
                          image: imageBytes,
                          aspectRatio: 1,
                          withCircleUi: true,
                          maskColor: Colors.black.withValues(alpha: 0.55),
                          onCropped: (data) {
                            Navigator.pop(dialogContext, data);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        strings.tapToChangeImage,
                        style: AppTextStyles.caption
                            .copyWith(color: scheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
    return file.path;
  }

  Future<void> _createFamily() async {
    final strings = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.loginToYourAccount)));
      return;
    }
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.familyNameRequired)));
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? photoUrl;
      if (_selectedImage != null) {
        final compressed =
            await ImageService().compressImage(_selectedImage!, quality: 85);
        final file = compressed ?? _selectedImage!;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('family_groups')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(file);
        photoUrl = await storageRef.getDownloadURL();
      }

      await _familyService.createFamily(
        name,
        description: description,
        photoUrl: photoUrl,
      );
      if (mounted) {
        if (widget.closeOnSuccess) {
          Navigator.of(context).pop(true);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.familyCreated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
            onTap: _isSaving ? null : _pickImage,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage:
                  _selectedImage != null ? FileImage(_selectedImage!) : null,
              child: _selectedImage == null
                  ? Icon(Icons.add_a_photo, color: colorScheme.primary, size: 28)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.familyNameLabel,
          style: AppTextStyles.subtitle2.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: strings.familyNamePlaceholder,
            prefixIcon: const Icon(Icons.family_restroom_outlined),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.descriptionOptional,
          style: AppTextStyles.subtitle2.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: strings.descriptionHint,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _selectedImage == null
                ? strings.tapToAddImage
                : strings.tapToChangeImage,
            style: AppTextStyles.bodyText2.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(strings.createFamily),
            onPressed: _isSaving ? null : _createFamily,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.familyNameRequired,
          style: AppTextStyles.caption.copyWith(
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
