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
    return ModalSheetScaffold(
      title: strings.familyInvitations,
      padding: EdgeInsets.zero,
      child: FamilyInvitesContent(
        height: MediaQuery.of(context).size.height * 0.6,
      ),
    );
  }
}

class FamilyInvitesContent extends StatelessWidget {
  FamilyInvitesContent({super.key, this.height});

  final MembershipRequestService _requestService = MembershipRequestService();
  final FamilyGroupService _familyService = FamilyGroupService();
  final double? height;

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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.family_restroom_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                familyName,
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (role != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  familyRoleLabel(strings, role),
                                  style: AppTextStyles.bodyText2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isInvite
                                ? strings.invitationLabel
                                : strings.requestLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            requestStatusLabel(strings, status),
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isInvite && isPending) ...[
                          OutlinedButton(
                            onPressed: () => _rejectInvite(
                              context,
                              familyId: data['entityId'],
                              userId: userId,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            child: Text(strings.reject),
                          ),
                          const SizedBox(width: 8),
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

    return height == null
        ? content
        : SizedBox(
            height: height,
            child: content,
          );
  }
}
