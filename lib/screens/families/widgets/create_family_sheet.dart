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
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/select_users_widget.dart';

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
  final List<_SelectedInvitee> _invitees = [];
  final Map<String, Map<String, dynamic>?> _userCache = {};
  bool _showNameError = false;
  String _creatorMemberRole = 'padre';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  static const List<String> _roleOptions = [
    'padre',
    'madre',
    'abuelo',
    'abuela',
    'tio',
    'tia',
    'hijo',
    'hija',
    'tutor',
    'otro',
  ];

  String _roleLabel(AppLocalizations strings, String role) {
    switch (role) {
      case 'padre':
        return strings.familyRoleFather;
      case 'madre':
        return strings.familyRoleMother;
      case 'abuelo':
        return strings.familyRoleGrandfather;
      case 'abuela':
        return strings.familyRoleGrandmother;
      case 'tio':
        return strings.familyRoleUncle;
      case 'tia':
        return strings.familyRoleAunt;
      case 'hijo':
        return strings.familyRoleChild;
      case 'hija':
        return strings.familyRoleDaughter;
      case 'tutor':
        return strings.familyRoleTutor;
      default:
        return strings.familyRoleOther;
    }
  }

  Future<Map<String, dynamic>?> _fetchUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    _userCache[uid] = data;
    return data;
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

  Future<void> _openInviteSelector() async {
    final strings = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: SelectUsersWidget(
              title: strings.inviteMembers,
              confirmButtonText: strings.sendInvitations,
              emptyStateText: strings.noUsersFound,
              searchPlaceholder: strings.searchUsers,
              onConfirm: (ids) => Navigator.pop(context, ids),
            ),
          ),
        );
      },
    );
    if (selected == null || selected.isEmpty) return;
    setState(() {
      for (final id in selected) {
        if (_invitees.any((i) => i.userId == id)) continue;
        _invitees.add(_SelectedInvitee(userId: id, role: 'otro'));
      }
    });
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
      setState(() => _showNameError = true);
      return;
    }
    setState(() => _showNameError = false);
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

      final familyId = await _familyService.createFamily(
        name,
        description: description,
        photoUrl: photoUrl,
        creatorMemberRole: _creatorMemberRole,
      );
      if (_invitees.isNotEmpty) {
        final grouped = <String, List<String>>{};
        for (final invitee in _invitees) {
          grouped.putIfAbsent(invitee.role, () => []).add(invitee.userId);
        }
        for (final entry in grouped.entries) {
          await _familyService.inviteMembers(
            familyId: familyId,
            userIds: entry.value,
            role: entry.key,
          );
        }
      }
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null
                        ? Icon(Icons.add_a_photo,
                            color: colorScheme.primary, size: 28)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedImage == null
                        ? strings.tapToAddImage
                        : strings.tapToChangeImage,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
          if (_showNameError) ...[
            const SizedBox(height: 6),
            Text(
              strings.familyNameRequired,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
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
          const SizedBox(height: 16),
          Text(
            strings.familyCreatorRoleLabel,
            style: AppTextStyles.subtitle2.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _creatorMemberRole,
            items: _roleOptions
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(_roleLabel(strings, role)),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _creatorMemberRole = value);
                  },
            decoration: InputDecoration(
              hintText: strings.familyCreatorRoleHint,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.inviteMembers,
                  style: AppTextStyles.subtitle2
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: _isSaving ? null : _openInviteSelector,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(strings.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_invitees.isEmpty)
            Text(
              strings.noUsersFound,
              style: AppTextStyles.bodyText2.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: _invitees
                  .map(
                    (inv) => FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchUser(inv.userId),
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        final name = data != null
                            ? (data['displayName'] ??
                                '${data['name'] ?? ''} ${data['surname'] ?? ''}'
                                    .trim())
                            : inv.userId;
                        final photoUrl =
                            data?['photoUrl']?.toString().trim();
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 0,
                          color: colorScheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      colorScheme.primary.withValues(alpha: 0.12),
                                  backgroundImage: (photoUrl != null &&
                                          photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: (photoUrl == null || photoUrl.isEmpty)
                                      ? Text(
                                          name.isNotEmpty ? name[0] : '?',
                                          style: AppTextStyles.caption.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: AppTextStyles.subtitle2.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 140),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: inv.role,
                                        isDense: true,
                                        icon: const Icon(Icons.expand_more),
                                        style: AppTextStyles.caption.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        items: _roleOptions
                                            .map(
                                              (r) => DropdownMenuItem(
                                                value: r,
                                                child: Text(_roleLabel(strings, r)),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => inv.role = value);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.close,
                                      color: colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    setState(() {
                                      _invitees.remove(inv);
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
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
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _SelectedInvitee {
  _SelectedInvitee({required this.userId, required this.role});
  final String userId;
  String role;
}
