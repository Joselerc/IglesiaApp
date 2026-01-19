import 'package:flutter/material.dart';
import '../../screens/groups/groups_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class GroupNotificationsData {
  final int pendingRequests;
  final int notifications;

  GroupNotificationsData({required this.pendingRequests, required this.notifications});
  
  int get total => pendingRequests + notifications;
}

class GroupsSection extends StatelessWidget {
  final String displayTitle;
  
  const GroupsSection({
    super.key,
    this.displayTitle = 'Connect',
  });

  // Obtener número de notificaciones de grupos (solicitudes pendientes para admins + notificaciones no leídas)
  Stream<GroupNotificationsData> _getGroupNotificationsCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(GroupNotificationsData(pendingRequests: 0, notifications: 0));

    final pendingRequestsStream = Stream.fromFuture(FirebaseFirestore.instance.collection('groups').get()).asyncMap((groupsQuery) async {
      int pendingRequestsCount = 0;
      
      for (var doc in groupsQuery.docs) {
        final data = doc.data();
        
        bool isAdmin = false;
        if (data['groupAdmin'] != null) {
             final admins = data['groupAdmin'] as List;
             for (var admin in admins) {
               if (admin is DocumentReference && admin.id == userId) isAdmin = true;
               if (admin is String && admin.contains(userId)) isAdmin = true;
             }
        }

        if (isAdmin && data['pendingRequests'] != null) {
          final pendingRequests = data['pendingRequests'] as Map<String, dynamic>;
          pendingRequestsCount += pendingRequests.length;
        }
      }
      
      return pendingRequestsCount;
    });

    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();

    final pendingInvitesStream = FirebaseFirestore.instance
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('entityType', isEqualTo: 'group')
        .where('requestType', isEqualTo: 'invite')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);

    return CombineLatestStream.combine3(
      pendingRequestsStream,
      notificationsStream,
      pendingInvitesStream,
      (int pendingCount, QuerySnapshot notificationsSnapshot, int pendingInvitesCount) {
        // Filtrar notificaciones relacionadas con grupos
        final groupNotifications = notificationsSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['entityType'] as String?;
          return type == 'group' || type == 'group_post' || type == 'group_chat' || type == 'group_event';
        }).length;
        
        return GroupNotificationsData(
          pendingRequests: pendingCount, 
          notifications: groupNotifications + pendingInvitesCount,
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupNotificationsData>(
      stream: _getGroupNotificationsCount(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? GroupNotificationsData(pendingRequests: 0, notifications: 0);
        final totalCount = data.total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                displayTitle,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupsListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.warmSand,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.group_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        // Badge de notificaciones para grupos
                        if (totalCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  '$totalCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
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
                          Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.connect,
                                style: AppTextStyles.subtitle1.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (totalCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (){
                                      if (data.pendingRequests > 0) {
                                        final locale = Localizations.localeOf(context).languageCode;
                                        if (locale == 'pt') {
                                          return '${data.pendingRequests} ${data.pendingRequests == 1 ? "solicitação" : "solicitações"}';
                                        } else {
                                          return '${data.pendingRequests} ${data.pendingRequests == 1 ? "solicitud" : "solicitudes"}';
                                        }
                                      } else {
                                        final String newItemWord = AppLocalizations.of(context)!.newItem; 
                                        // Lógica simple para pluralizar basada en idioma
                                        final locale = Localizations.localeOf(context).languageCode;
                                        if (locale == 'es') {
                                          return '${data.notifications} ${data.notifications == 1 ? "nueva" : "nuevas"}';
                                        } else if (locale == 'pt') {
                                          return '${data.notifications} ${data.notifications == 1 ? "nova" : "novas"}';
                                        } else {
                                          return '${data.notifications} new';
                                        }
                                      }
                                    }(),
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.connectWithChurchGroups,
                            style: AppTextStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }
} 
