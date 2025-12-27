import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/family_group_service.dart';
import '../../../services/membership_request_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/family_localizations.dart';
import 'modal_sheet_scaffold.dart';

Future<void> showFamilyInvitesSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const FamilyInvitesSheet(),
  );
}

class FamilyInvitesSheet extends StatelessWidget {
  const FamilyInvitesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ModalSheetScaffold(
      title: strings.familyInvitations,
      titleStyle: theme.textTheme.titleMedium,
      padding: EdgeInsets.zero,
      useScrollView: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: FamilyInvitesContent(),
      ),
    );
  }
}

class FamilyInvitesContent extends StatelessWidget {
  FamilyInvitesContent({super.key});

  final MembershipRequestService _requestService = MembershipRequestService();
  final FamilyGroupService _familyService = FamilyGroupService();

  Future<void> _acceptInvite(
    BuildContext context, {
    required String familyId,
    required String userId,
  }) async {
    final strings = AppLocalizations.of(context)!;
    try {
      await _familyService.acceptInvite(familyId: familyId, userId: userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.inviteAccepted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
      );
    }
  }

  Future<void> _rejectInvite(
    BuildContext context, {
    required String familyId,
    required String userId,
  }) async {
    final strings = AppLocalizations.of(context)!;
    try {
      await _familyService.rejectInvite(familyId: familyId, userId: userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.inviteRejected)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surfaceContainerLow;

    if (userId == null) {
      return Center(child: Text(strings.loginToYourAccount));
    }

    final content = StreamBuilder<QuerySnapshot>(
      stream: _requestService.getUserRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(strings.somethingWentWrong));
        }
        final docs = snapshot.data?.docs ?? [];
        final familyDocs = docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isFamily = (data['entityType'] ?? '') == 'family';
              final isInvite = (data['requestType'] ?? 'invite') == 'invite';
              final isPending = (data['status'] ?? 'pending') == 'pending';
              return isFamily && isInvite && isPending;
            })
            .toList();
        if (familyDocs.isEmpty) {
          return Center(
            child: Text(
              strings.noInvitesFound,
              style: AppTextStyles.subtitle2
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          physics: const BouncingScrollPhysics(),
          itemCount: familyDocs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = familyDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isInvite = (data['requestType'] ?? 'join') == 'invite';
            final status = data['status'] ?? 'pending';
            final familyName =
                data['entityName'] ?? strings.familyFallbackName;
            final role = data['desiredRole']?.toString();
            final isPending = status == 'pending';
            Color statusColor;
            switch (status) {
              case 'accepted':
                statusColor = Colors.green.shade600;
                break;
              case 'rejected':
                statusColor = colorScheme.error;
                break;
              default:
                statusColor = colorScheme.primary;
            }
            return Card(
              elevation: 1,
              color: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.12),
                          child: Icon(Icons.family_restroom_outlined,
                              color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                familyName,
                                style: AppTextStyles.subtitle1
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                requestStatusLabel(strings, status),
                                style: AppTextStyles.bodyText2.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (role != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  familyRoleLabel(strings, role),
                                  style: AppTextStyles.caption.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isInvite && isPending)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _rejectInvite(
                              context,
                              familyId: data['entityId'],
                              userId: userId,
                            ),
                            child: Text(strings.reject),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => _acceptInvite(
                              context,
                              familyId: data['entityId'],
                              userId: userId,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: Text(strings.accept),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return content;
  }
}
