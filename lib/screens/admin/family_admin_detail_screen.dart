import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_group.dart';
import '../../services/family_group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/age_range.dart';
import '../../utils/age_range_localizations.dart';
import '../../utils/family_localizations.dart';
import '../families/widgets/family_card.dart';

class FamilyAdminDetailScreen extends StatelessWidget {
  final String familyId;
  FamilyAdminDetailScreen({super.key, required this.familyId});

  final FamilyGroupService _familyService = FamilyGroupService();

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snap.data();
  }

  String _displayNameForUser(AppLocalizations strings, Map<String, dynamic>? data) {
    if (data == null) return strings.unknownUser;
    return (data['displayName'] ??
            '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim())
        .toString()
        .trim()
        .isNotEmpty
        ? (data['displayName'] ??
                '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim())
            .toString()
            .trim()
        : strings.unknownUser;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final localizations = MaterialLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.familyDetailTitle),
      ),
      body: StreamBuilder<FamilyGroup?>(
        stream: _familyService.watchFamily(familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final family = snapshot.data;
          if (family == null) {
            return Center(child: Text(strings.familyNotFound));
          }
          final createdText = strings.created(
            localizations.formatShortDate(family.createdAt),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              FamilyCard(
                title: family.name.isNotEmpty
                    ? family.name
                    : strings.familyFallbackName,
                subtitle: [
                  strings.familyMembersCount(family.memberIds.length),
                  createdText,
                  if (family.description.isNotEmpty) family.description,
                ].join('\n'),
                photoUrl: family.photoUrl,
                surfaceTint: colorScheme.surfaceContainerLow,
                titleMaxLines: 2,
                subtitleMaxLines: 3,
              ),
              const SizedBox(height: 18),
              Text(
                strings.members,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...family.memberIds.map((userId) {
                final role = family.memberRoles[userId] ?? 'otro';
                final isAdmin = family.adminIds.contains(userId);
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUser(userId),
                  builder: (context, userSnap) {
                    final data = userSnap.data;
                    final name = _displayNameForUser(strings, data);
                    final photoUrl = data?['photoUrl']?.toString();
                    final ageRange = AgeRange.fromFirestoreValue(
                      data?['ageRange'] as String?,
                    );
                    final subtitleParts = <String>[
                      familyRoleLabel(strings, role),
                      if (ageRange != null) ageRange.label(strings),
                    ];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(name.isNotEmpty ? name[0] : '?')
                            : null,
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyText2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                strings.adminLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                );
              }),
              const SizedBox(height: 18),
              Text(
                strings.pendingRequests,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (family.pendingRequests.isEmpty)
                Text(
                  strings.noPendingRequests,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ...family.pendingRequests.entries.map((entry) {
                final role =
                    (entry.value as Map<String, dynamic>)['role'] ?? 'otro';
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUser(entry.key),
                  builder: (context, userSnap) {
                    final data = userSnap.data;
                    final name = _displayNameForUser(strings, data);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.schedule,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(familyRoleLabel(strings, role)),
                      trailing: Text(requestStatusLabel(strings, 'pending')),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
