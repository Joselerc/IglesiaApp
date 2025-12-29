import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_group.dart';
import '../../services/family_group_service.dart';
import '../../services/membership_request_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/family_localizations.dart';
import '../../utils/age_group.dart';
import '../../widgets/circular_image_picker.dart';
import '../../widgets/select_users_widget.dart';

class FamilyDetailScreen extends StatefulWidget {
  final String familyId;
  const FamilyDetailScreen({super.key, required this.familyId});

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  final FamilyGroupService _familyService = FamilyGroupService();
  final MembershipRequestService _requestService = MembershipRequestService();
  bool _isActionLoading = false;
  late final Future<AgeGroup?> _currentUserAgeGroup;

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snap.data();
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _currentUserAgeGroup = uid == null
        ? Future.value(null)
        : FirebaseFirestore.instance.collection('users').doc(uid).get().then(
              (doc) => AgeGroup.fromFirestoreValue(
                doc.data()?['age_group'] as String?,
              ),
            );
  }

  Future<void> _renameFamily(FamilyGroup family) async {
    final strings = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: family.name);
    final descriptionController =
        TextEditingController(text: family.description);
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: viewInsets + 16,
            top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.familyDetailTitle,
                        style: AppTextStyles.subtitle1
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonLabel,
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: strings.familyNameLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: strings.descriptionOptional,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                    }),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(strings.save),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    final newName = result?['name'] ?? '';
    final newDescription = result?['description'] ?? '';
    if (newName.isEmpty || newName == family.name) {
      if (newDescription == family.description) return;
    }
    setState(() => _isActionLoading = true);
    try {
      await _familyService.updateFamilyInfo(
        familyId: family.id,
        name: newName.isEmpty ? family.name : newName,
        description: newDescription,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _openInviteSheet(FamilyGroup family) async {
    final strings = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: SelectUsersWidget(
                  excludeUserIds: [
                    ...family.memberIds,
                    ...family.pendingInvites.keys,
                    ...family.pendingRequests.keys
                  ],
                  title: strings.inviteMembers,
                  confirmButtonText: strings.sendInvitations,
                  emptyStateText: strings.noUsersFound,
                  searchPlaceholder: strings.searchUsers,
                  onConfirm: (userIds) async {
                    Navigator.pop(context);
                    if (userIds.isEmpty) return;
                    setState(() => _isActionLoading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _familyService.inviteMembers(
                        familyId: family.id,
                        userIds: userIds,
                        role: 'otro',
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(strings.invitesSent)),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                            content:
                                Text('${strings.somethingWentWrong}: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _isActionLoading = false);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeRole(
      FamilyGroup family, String userId, String currentRole) async {
    final strings = AppLocalizations.of(context)!;
    final newRole = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: FamilyGroup.roleOptions
              .where((r) => r != 'admin')
              .map(
                (role) => ListTile(
                  title: Text(familyRoleLabel(strings, role)),
                  trailing:
                      role == currentRole ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, role),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (newRole == null || newRole == currentRole) return;
    setState(() => _isActionLoading = true);
    try {
      await _familyService.changeRole(
        familyId: family.id,
        userId: userId,
        role: newRole,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _toggleAdmin(
      FamilyGroup family, String userId, bool makeAdmin) async {
    final strings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true);
    try {
      await _familyService.setAdmin(
        familyId: family.id,
        userId: userId,
        isAdmin: makeAdmin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _removeMember(FamilyGroup family, String userId) async {
    final strings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true);
    try {
      await _familyService.removeMember(
        familyId: family.id,
        userId: userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleLeave() async {
    final strings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true);
    try {
      await _familyService.leaveFamily(widget.familyId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _acceptJoin(
      FamilyGroup family, String userId, String? role) async {
    final strings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true);
    try {
      await _familyService.acceptJoinRequest(
        familyId: family.id,
        userId: userId,
      );
      if (role != null) {
        await _familyService.changeRole(
          familyId: family.id,
          userId: userId,
          role: role,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _rejectJoin(FamilyGroup family, String userId) async {
    final strings = AppLocalizations.of(context)!;
    setState(() => _isActionLoading = true);
    try {
      await _familyService.rejectJoinRequest(
        familyId: family.id,
        userId: userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _cancelInvite(FamilyGroup family, String userId) async {
    try {
      final reqDoc =
          await _requestService.findRequest(userId, family.id, 'family');
      if (reqDoc != null) {
        await reqDoc.reference.delete();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.somethingWentWrong)),
        );
      }
    }
  }

  Widget _memberTile(
    FamilyGroup family,
    String userId,
    bool currentUserIsAdmin,
  ) {
    final role = family.memberRoles[userId] ?? 'otro';
    final isAdmin = family.adminIds.contains(userId);
    final strings = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(userId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data != null
            ? (data['displayName'] ??
                '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim())
            : strings.unknownUser;
        final photo = data?['photoUrl'] as String?;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppColors.warmSand,
            backgroundImage:
                photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
            child: (photo == null || photo.isEmpty)
                ? Text(name.isNotEmpty ? name[0] : '?')
                : null,
          ),
          title: Text(
            name,
            style: AppTextStyles.subtitle2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            familyRoleLabel(strings, role),
            style: AppTextStyles.caption.copyWith(color: AppColors.mutedGray),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    strings.adminLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (currentUserIsAdmin && userId != family.creatorId) ...[
                if (isAdmin) const SizedBox(width: 6),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'role':
                        _changeRole(family, userId, role);
                        break;
                      case 'admin':
                        _toggleAdmin(family, userId, !isAdmin);
                        break;
                      case 'remove':
                        _removeMember(family, userId);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'role', child: Text(strings.changeRole)),
                    PopupMenuItem(
                        value: 'admin',
                        child: Text(isAdmin
                            ? strings.removeAdmin
                            : strings.makeAdmin)),
                    PopupMenuItem(
                        value: 'remove', child: Text(strings.removeMember)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final strings = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.familyDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isActionLoading ? null : _handleLeave,
            tooltip: strings.leaveFamily,
          ),
          if (_isActionLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: FutureBuilder<AgeGroup?>(
        future: _currentUserAgeGroup,
        builder: (context, ageSnapshot) {
          if (ageSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final isAdult = ageSnapshot.data == AgeGroup.plus18;
          return StreamBuilder<FamilyGroup?>(
            stream: _familyService.watchFamily(widget.familyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final family = snapshot.data;
              if (family == null) {
                return Center(child: Text(strings.familyNotFound));
              }

              final currentIsAdmin =
                  isAdult && family.adminIds.contains(userId);

              return Stack(
                children: [
              SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(16, 16, 16, currentIsAdmin ? 96 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FamilyProfileHeader(
                      family: family,
                      isAdmin: currentIsAdmin,
                      isLoading: _isActionLoading,
                      onEdit: currentIsAdmin ? () => _renameFamily(family) : null,
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: '${strings.members} (${family.memberIds.length})',
                      subtitle: strings.familyMembersLabel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...family.memberIds
                              .map((id) => _memberTile(family, id, currentIsAdmin)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentIsAdmin) ...[
                      _RequestsSection(
                        family: family,
                        isActionLoading: _isActionLoading,
                        fetchUser: _fetchUser,
                        onAccept: (uid, role) =>
                            _acceptJoin(family, uid, role),
                        onReject: (uid) => _rejectJoin(family, uid),
                        trailing: _CountBadge(count: family.pendingRequests.length),
                      ),
                      const SizedBox(height: 12),
                      _InvitesSection(
                        family: family,
                        onCancel: (uid) => _cancelInvite(family, uid),
                        requestService: _requestService,
                        subtitle: strings.invitationLabel,
                      ),
                    ],
                  ],
                ),
              ),
              if (currentIsAdmin)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: _isActionLoading
                            ? null
                            : () => _openInviteSheet(family),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(strings.inviteMembers),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.subtitle1
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodyText2.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _FamilyProfileHeader extends StatelessWidget {
  const _FamilyProfileHeader({
    required this.family,
    required this.isAdmin,
    required this.isLoading,
    this.onEdit,
  });

  final FamilyGroup family;
  final bool isAdmin;
  final bool isLoading;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          CircularImagePicker(
            documentId: family.id,
            currentImageUrl: family.photoUrl,
            storagePath: 'family_groups',
            collectionName: 'family_groups',
            fieldName: 'photoUrl',
            defaultIcon: CircleAvatar(
              radius: 42,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.family_restroom_outlined,
                  color: colorScheme.primary),
            ),
            isEditable: isAdmin && !isLoading,
            size: 124,
            showEditIconOutside: true,
          ),
          const SizedBox(height: 10),
          Text(
            family.name.isNotEmpty
                ? family.name
                : strings.familyFallbackName,
            style:
                AppTextStyles.headline3.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            family.description.isNotEmpty
                ? family.description
                : strings.familyDetailTitle,
            style: AppTextStyles.bodyText2
                .copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: isAdmin && !isLoading ? onEdit : null,
              icon: const Icon(Icons.edit_outlined),
              label: Text(strings.edit),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.family,
    required this.isActionLoading,
    required this.fetchUser,
    required this.onAccept,
    required this.onReject,
    this.trailing,
  });

  final FamilyGroup family;
  final bool isActionLoading;
  final Future<Map<String, dynamic>?> Function(String userId) fetchUser;
  final void Function(String userId, String? role) onAccept;
  final void Function(String userId) onReject;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return _SectionCard(
      title: strings.pendingRequests,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (family.pendingRequests.isEmpty)
            Text(
              strings.noPendingRequests,
              style: AppTextStyles.bodyText2
                  .copyWith(color: AppColors.textSecondary),
            ),
          ...family.pendingRequests.entries.map(
            (entry) {
              final role =
                  (entry.value as Map<String, dynamic>)['role'] ?? 'otro';
              return FutureBuilder<Map<String, dynamic>?>(
                future: fetchUser(entry.key),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final name = data != null
                      ? (data['displayName'] ??
                          '${data['name'] ?? ''} ${data['surname'] ?? ''}'
                              .trim())
                      : strings.unknownUser;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(familyRoleLabel(strings, role)),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: isActionLoading
                                ? null
                                : () => onReject(entry.key),
                            child: Text(strings.reject),
                          ),
                          FilledButton.tonal(
                            onPressed: isActionLoading
                                ? null
                                : () => onAccept(
                                      entry.key,
                                      role,
                                    ),
                            child: Text(strings.accept),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InvitesSection extends StatelessWidget {
  const _InvitesSection({
    required this.family,
    required this.onCancel,
    required this.requestService,
    this.subtitle,
  });

  final FamilyGroup family;
  final Future<void> Function(String userId) onCancel;
  final MembershipRequestService requestService;
  final String? subtitle;

  Color _statusColor(ColorScheme scheme, String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.shade600;
      case 'rejected':
        return scheme.error;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: requestService.getAllRequests(family.id, 'family'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Text(
            strings.noInvitesFound,
            style: AppTextStyles.bodyText2
                .copyWith(color: AppColors.textSecondary),
          );
        }
        final invites = snapshot.data?.docs
                .where((doc) =>
                    (doc['requestType'] ?? 'join') == 'invite' &&
                    ((doc['status'] ?? 'pending') == 'pending' ||
                        (doc['status'] ?? 'pending') == 'accepted'))
                .toList() ??
            [];
        return _SectionCard(
          title: strings.sentInvitations,
          subtitle: subtitle,
          trailing: invites.isNotEmpty ? _CountBadge(count: invites.length) : null,
          child: invites.isEmpty
              ? Text(
                  strings.noInvitesFound,
                  style: AppTextStyles.bodyText2
                      .copyWith(color: AppColors.textSecondary),
                )
              : Column(
                  children: invites.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final userName =
                        data['userName']?.toString() ?? strings.unknownUser;
                    final photoUrl = data['userPhotoUrl']?.toString();
                    final status = data['status']?.toString() ?? 'pending';
                    final role = data['desiredRole']?.toString() ?? 'otro';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Dismissible(
                        key: ValueKey(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child:
                              Icon(Icons.delete_outline, color: colorScheme.error),
                        ),
                        confirmDismiss: (_) async => true,
                        onDismissed: (_) async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await onCancel(data['userId']);
                          } catch (_) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(strings.somethingWentWrong)),
                            );
                          }
                        },
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tileColor: colorScheme.surfaceContainerLowest,
                          leading: CircleAvatar(
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Text(userName.isNotEmpty ? userName[0] : '?')
                                : null,
                          ),
                          title: Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(familyRoleLabel(strings, role)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor(colorScheme, status)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              requestStatusLabel(strings, status),
                              style: AppTextStyles.caption.copyWith(
                                color: _statusColor(colorScheme, status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: AppTextStyles.caption.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
