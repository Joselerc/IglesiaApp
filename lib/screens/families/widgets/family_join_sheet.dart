import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/family_group.dart';
import '../../../services/family_group_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/family_localizations.dart';
import 'modal_sheet_scaffold.dart';

Future<void> showJoinFamilySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const FamilyJoinSheet(),
  );
}

class FamilyJoinSheet extends StatelessWidget {
  const FamilyJoinSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height * 0.7;
    return ModalSheetScaffold(
      title: strings.joinFamily,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: const FamilyJoinContent(),
      ),
    );
  }
}

class FamilyJoinContent extends StatefulWidget {
  const FamilyJoinContent({super.key});

  @override
  State<FamilyJoinContent> createState() => _FamilyJoinContentState();
}

class _FamilyJoinContentState extends State<FamilyJoinContent> {
  final TextEditingController _searchController = TextEditingController();
  final FamilyGroupService _familyService = FamilyGroupService();
  String _searchTerm = '';
  String? _submittingId;

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

  Future<void> _requestJoin(FamilyGroup family) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final strings = AppLocalizations.of(context)!;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.loginToYourAccount)));
      return;
    }
    final role = await _pickRole();
    if (role == null) return;
    setState(() => _submittingId = family.id);
    try {
      await _familyService.requestToJoin(
        familyId: family.id,
        desiredRole: role,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.joinRequestSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.somethingWentWrong}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingId = null);
    }
  }

  Future<String?> _pickRole() async {
    final strings = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String selected = 'hijo';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.selectFamilyRole,
                          style: AppTextStyles.subtitle1
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...FamilyGroup.roleOptions.where((r) => r != 'admin').map(
                    (role) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(familyRoleLabel(strings, role)),
                      value: role,
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selected = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.pop(context, selected),
                      child: Text(strings.confirm),
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    final surfaceCard = colorScheme.surfaceContainerLow;
    final chipTextStyle =
        AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: strings.searchFamilies,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FamilyGroup>>(
            stream: _familyService.streamAllFamilies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(strings.somethingWentWrong));
              }
              final families = (snapshot.data ?? []).where((family) {
                final normalized = (family.name.isNotEmpty
                        ? family.name
                        : strings.familyFallbackName)
                    .toLowerCase()
                    .trim();
                return _searchTerm.isEmpty || normalized.contains(_searchTerm);
              }).toList();

              if (families.isEmpty) {
                return Center(
                  child: Text(
                    strings.noFamiliesFound,
                    style: AppTextStyles.subtitle2
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: families.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final family = families[index];
                  final isMember = family.memberIds.contains(currentUserId);
                  final isPending =
                      family.pendingRequests.containsKey(currentUserId);
                  final subtitle =
                      strings.familyMembersCount(family.memberIds.length);

                  final title =
                      family.name.isNotEmpty ? family.name : strings.familyFallbackName;
                  return Container(
                    decoration: BoxDecoration(
                      color: surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: primary.withValues(alpha: 0.12),
                                backgroundImage: family.photoUrl.isNotEmpty
                                    ? NetworkImage(family.photoUrl)
                                    : null,
                                child: family.photoUrl.isEmpty
                                    ? Icon(
                                        Icons.family_restroom_outlined,
                                        color: primary,
                                        size: 24,
                                      )
                                    : null,
                              ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.subtitle2
                                      .copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      subtitle,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const Spacer(),
                                    _trailingForState(
                                      isMember: isMember,
                                      isPending: isPending,
                                      onJoin: () => _requestJoin(family),
                                      primary: primary,
                                      textStyle: chipTextStyle,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _trailingForState({
    required bool isMember,
    required bool isPending,
    required VoidCallback onJoin,
    required Color primary,
    required TextStyle textStyle,
  }) {
    if (isMember) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.alreadyMember,
            style: textStyle.copyWith(color: Colors.green),
          ),
        ],
      );
    }
    if (isPending) {
      return Text(
        AppLocalizations.of(context)!.requestPending,
        style: textStyle.copyWith(color: primary),
      );
    }
    final canTap = _submittingId == null;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: canTap ? onJoin : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          AppLocalizations.of(context)!.requestJoinAction,
          style: textStyle.copyWith(
            color: primary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
