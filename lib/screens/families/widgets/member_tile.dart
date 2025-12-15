import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/family_group.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/family_localizations.dart';

class MemberTile extends StatelessWidget {
  final FamilyGroup family;
  final String userId;
  final bool currentUserIsAdmin;
  final Function(FamilyGroup, String, String) onChangeRole;
  final Function(FamilyGroup, String, bool) onToggleAdmin;
  final Function(FamilyGroup, String) onRemoveMember;

  const MemberTile({
    super.key,
    required this.family,
    required this.userId,
    required this.currentUserIsAdmin,
    required this.onChangeRole,
    required this.onToggleAdmin,
    required this.onRemoveMember,
  });

  Future<Map<String, dynamic>?> _fetchUser() async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    final role = family.memberRoles[userId] ?? 'otro';
    final isAdmin = family.adminIds.contains(userId);
    final strings = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data != null
            ? (data['displayName'] ??
                '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim())
            : strings.unknownUser;
        final photo = data?['photoUrl'] as String?;
        
        // If loading and no data yet, show a placeholder or keep previous if possible.
        // For now, we return the tile. If data is null (loading), name is unknownUser.
        // To avoid "jumps" from loading state to content, we can show a skeleton or just empty.
        // But since this Future is inside the widget, it will only fire once per widget lifecycle.
        
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
                        onChangeRole(family, userId, role);
                        break;
                      case 'admin':
                        onToggleAdmin(family, userId, !isAdmin);
                        break;
                      case 'remove':
                        onRemoveMember(family, userId);
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
}
