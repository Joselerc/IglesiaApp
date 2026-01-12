import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_group.dart';
import '../../services/family_group_service.dart';
import '../../services/membership_request_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/age_range.dart';
import 'family_detail_screen.dart';
import 'widgets/create_family_sheet.dart';
import 'widgets/family_card.dart';
import 'widgets/family_invites_sheet.dart';
import 'widgets/family_join_sheet.dart';

class FamiliesHomeScreen extends StatefulWidget {
  const FamiliesHomeScreen({super.key});

  @override
  State<FamiliesHomeScreen> createState() => _FamiliesHomeScreenState();
}

class _FamiliesHomeScreenState extends State<FamiliesHomeScreen> {
  final FamilyGroupService _familyService = FamilyGroupService();
  final MembershipRequestService _requestService = MembershipRequestService();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateFamily() {
    showCreateFamilySheet(context);
  }

  void _openJoinFamily() {
    showJoinFamilySheet(context);
  }

  void _openInvites() {
    showFamilyInvitesSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(strings.familiesTitle),
        ),
        body: Center(
          child: Text(strings.loginToYourAccount),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, userSnapshot) {
        final ageRange = AgeRange.fromFirestoreValue(
          userSnapshot.data?.data()?['ageRange'] as String?,
        );
        final isAdult = ageRange?.isAdult ?? false;

        void openCreateFamilyGuarded() {
          if (!isAdult) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.familiesAdultsOnlyMessage)),
            );
            return;
          }
          _openCreateFamily();
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(strings.familiesTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                onPressed: _openInvites,
                tooltip: strings.familyInvitations,
              ),
            ],
          ),
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FamiliesHeroCard(
                          onCreate: openCreateFamilyGuarded,
                          onJoin: _openJoinFamily,
                        ),
                        const SizedBox(height: 14),
                        StreamBuilder<QuerySnapshot>(
                          stream: _requestService.getUserRequests(userId),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            final hasPending = docs.any((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return (data['entityType'] ?? 'family') ==
                                      'family' &&
                                  (data['requestType'] ?? 'invite') ==
                                      'invite' &&
                                  (data['status'] ?? 'pending') == 'pending';
                            });
                            return _InvitesBanner(
                              onTap: _openInvites,
                              showDot: hasPending,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: strings.searchFamilies,
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            strings.familiesTitle,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<List<FamilyGroup>>(
                          stream: _familyService.streamUserFamilies(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(strings.somethingWentWrong),
                                ),
                              );
                            }
                            var families = snapshot.data ?? [];
                            families = families
                                .where((family) =>
                                    family.name
                                        .toLowerCase()
                                        .contains(_searchTerm) ||
                                    _searchTerm.isEmpty)
                                .toList();
                            if (families.isEmpty) {
                              return _EmptyFamiliesState(
                                onCreate: openCreateFamilyGuarded,
                                onJoin: _openJoinFamily,
                              );
                            }
                            return ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: families.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              padding: const EdgeInsets.only(bottom: 16),
                              itemBuilder: (context, index) {
                                final family = families[index];
                                final isAdmin =
                                    isAdult && family.isAdmin(userId);
                                final hasPendingRequests =
                                    isAdmin && family.pendingRequests.isNotEmpty;
                                return FamilyCard(
                                  title: family.name.isNotEmpty
                                      ? family.name
                                      : strings.familyFallbackName,
                                  subtitle: strings.familyMembersCount(
                                    family.memberIds.length,
                                  ),
                                  badge: isAdmin ? strings.adminLabel : null,
                                  surfaceTint:
                                      colorScheme.surfaceContainerLow,
                                  photoUrl: family.photoUrl,
                                  titleMaxLines: 2,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasPendingRequests) ...[
                                        Icon(
                                          Icons.notifications_active,
                                          size: 18,
                                          color: colorScheme.error,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FamilyDetailScreen(
                                        familyId: family.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FamiliesHeroCard extends StatelessWidget {
  const _FamiliesHeroCard({
    required this.onCreate,
    required this.onJoin,
  });

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 132,
      child: Row(
        children: [
          Expanded(
            child: _HeroActionCard(
              title: strings.createFamily,
              icon: Icons.add_circle,
              onTap: onCreate,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _HeroActionCard(
              title: strings.joinFamily,
              icon: Icons.group_add_outlined,
              onTap: onJoin,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base.withValues(alpha: 0.12),
              base.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: base.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: base, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle2.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFamiliesState extends StatelessWidget {
  const _EmptyFamiliesState({
    required this.onCreate,
    required this.onJoin,
  });

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.family_restroom_outlined,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            strings.noFamiliesYet,
            style: AppTextStyles.subtitle2
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onCreate,
            child: Text(strings.createFamily),
          ),
          TextButton(
            onPressed: onJoin,
            child: Text(strings.joinFamily),
          ),
        ],
      ),
    );
  }
}

class _InvitesBanner extends StatelessWidget {
  const _InvitesBanner({required this.onTap, required this.showDot});

  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.mail_outline, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.familyInvitations,
                  style: AppTextStyles.subtitle2,
                ),
              ),
              const SizedBox(width: 8),
              if (showDot) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
