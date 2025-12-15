import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/family_localizations.dart';

class RequestTile extends StatelessWidget {
  final String userId;
  final String role;
  final bool isActionLoading;
  final Function(String) onReject;
  final Function(String, String) onAccept;

  const RequestTile({
    super.key,
    required this.userId,
    required this.role,
    required this.isActionLoading,
    required this.onReject,
    required this.onAccept,
  });

  Future<Map<String, dynamic>?> _fetchUser() async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUser(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data != null
            ? (data['displayName'] ??
                '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim())
            : strings.unknownUser;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                  onPressed: isActionLoading ? null : () => onReject(userId),
                  child: Text(strings.reject),
                ),
                FilledButton.tonal(
                  onPressed:
                      isActionLoading ? null : () => onAccept(userId, role),
                  child: Text(strings.accept),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
