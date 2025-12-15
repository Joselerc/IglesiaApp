import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_group.dart';
import '../../services/family_group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/family_localizations.dart';

class FamilyAdminDetailScreen extends StatelessWidget {
  final String familyId;
  FamilyAdminDetailScreen({super.key, required this.familyId});

  final FamilyGroupService _familyService = FamilyGroupService();

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                family.name,
                style: AppTextStyles.headline3
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                strings.familyMembersCount(family.memberIds.length),
                style: AppTextStyles.bodyText2
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                strings.members,
                style: AppTextStyles.subtitle1
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...family.memberIds.map((userId) => FutureBuilder<
                      Map<String, dynamic>?>(
                    future: _fetchUser(userId),
                    builder: (context, userSnap) {
                      final data = userSnap.data;
                      final name = data != null
                          ? (data['displayName'] ??
                              '${data['name'] ?? ''} ${data['surname'] ?? ''}'
                                  .trim())
                          : strings.unknownUser;
                      final role = family.memberRoles[userId] ?? 'otro';
                      final isAdmin = family.adminIds.contains(userId);
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(name),
                        subtitle: Text(familyRoleLabel(strings, role)),
                      trailing: isAdmin
                          ? Chip(
                              label: Text(strings.adminLabel),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                      );
                    },
                  )),
              const SizedBox(height: 16),
              Text(strings.pendingRequests,
                  style: AppTextStyles.subtitle1
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (family.pendingRequests.isEmpty)
                Text(strings.noPendingRequests,
                    style: AppTextStyles.bodyText2
                        .copyWith(color: AppColors.textSecondary)),
              ...family.pendingRequests.entries.map((entry) {
                final role =
                    (entry.value as Map<String, dynamic>)['role'] ?? 'otro';
                return FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchUser(entry.key),
                  builder: (context, userSnap) {
                    final data = userSnap.data;
                    final name = data != null
                        ? (data['displayName'] ??
                            '${data['name'] ?? ''} ${data['surname'] ?? ''}'
                                .trim())
                        : strings.unknownUser;
                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(name),
                      subtitle: Text(familyRoleLabel(strings, role)),
                      trailing: const Text('pending'),
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
