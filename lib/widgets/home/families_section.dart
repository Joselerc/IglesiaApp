import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/families/families_home_screen.dart';
import '../../services/family_group_service.dart';
import '../../services/membership_request_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';

class FamiliesSection extends StatelessWidget {
  FamiliesSection({super.key, this.displayTitle});

  final MembershipRequestService _requestService = MembershipRequestService();
  final FamilyGroupService _familyService = FamilyGroupService();
  final String? displayTitle;

  Stream<int> _pendingInvitesCount(String userId) {
    return _requestService.getUserRequests(userId).map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['entityType'] == 'family' &&
            (data['requestType'] ?? 'join') == 'invite' &&
            (data['status'] ?? 'pending') == 'pending';
      }).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final strings = AppLocalizations.of(context)!;
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final titleText = (displayTitle == null || displayTitle!.trim().isEmpty)
        ? strings.familiesTitle
        : displayTitle!;

    return StreamBuilder<int>(
      stream: _pendingInvitesCount(userId),
      builder: (context, inviteSnapshot) {
        final invites = inviteSnapshot.data ?? 0;
        return StreamBuilder(
          stream: _familyService.streamUserFamilies(userId),
          builder: (context, snapshot) {
            final familiesCount = snapshot.data?.length ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: AppTextStyles.headline3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FamiliesHomeScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: AppColors.warmSand,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                Icons.family_restroom_outlined,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                            if (invites > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  constraints:
                                      const BoxConstraints(minWidth: 20, minHeight: 20),
                                  child: Center(
                                    child: Text(
                                      '$invites',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                style: AppTextStyles.subtitle1.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                strings.familyMembersSummary(familiesCount),
                                style: AppTextStyles.bodyText2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
