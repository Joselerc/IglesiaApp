import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_group.dart';
import '../../services/family_group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'family_admin_detail_screen.dart';

class FamiliesAdminScreen extends StatelessWidget {
  FamiliesAdminScreen({super.key});

  final FamilyGroupService _familyService = FamilyGroupService();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.familiesTitle),
      ),
      body: StreamBuilder<List<FamilyGroup>>(
        stream: _familyService.streamAllFamilies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(strings.somethingWentWrong));
          }
          final families = snapshot.data ?? [];
          if (families.isEmpty) {
            return Center(
              child: Text(strings.noFamiliesFound,
                  style: AppTextStyles.subtitle2
                      .copyWith(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            itemCount: families.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final family = families[index];
              return ListTile(
                title: Text(
                  family.name,
                  style: AppTextStyles.subtitle1,
                ),
                subtitle: Text(strings.familyMembersCount(family.memberIds.length)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilyAdminDetailScreen(familyId: family.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
