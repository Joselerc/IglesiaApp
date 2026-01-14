import 'package:flutter/material.dart';
import '../models/group.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../l10n/app_localizations.dart';
import '../screens/shared/entity_info_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore

class GroupCard extends StatelessWidget {
  final Group group;
  final String userId;
  final Function(Group) onActionPressed;

  const GroupCard({
    Key? key,
    required this.group,
    required this.userId,
    required this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final status = group.getUserStatus(userId);
    final isAdmin = group.isAdmin(userId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar con Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.warmSand,
                    shape: BoxShape.circle,
                    image: group.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(group.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: group.imageUrl.isEmpty
                      ? Icon(Icons.group_rounded, color: AppColors.secondary, size: 28)
                      : null,
                ),
                // Badge de notificaciones (StreamBuilder)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: userId)
                      .where('entityId', isEqualTo: group.id)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int notificationCount = 0;
                    if (snapshot.hasData) {
                      notificationCount = snapshot.data!.docs.length;
                    }
                    
                    // Sumar solicitudes pendientes si es admin
                    if (isAdmin) {
                      notificationCount += group.pendingRequests.length;
                    }

                    if (notificationCount == 0) return const SizedBox.shrink();

                    return Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Información del grupo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.description.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.info_outline, 
                            size: 20, 
                            color: AppColors.textSecondary
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: strings.moreInfo,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EntityInfoScreen(
                                  entityId: group.id,
                                  entityType: EntityType.group,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  Text(
                    strings.memberCount(group.memberIds.length),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón de acción
            _buildButton(context, status),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButton(BuildContext context, String status) {
    final strings = AppLocalizations.of(context)!;
    if (status == 'Enter') {
      return ElevatedButton(
        onPressed: () => onActionPressed(group),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: Text(strings.enterAction),
      );
    } else if (status == 'Pending') {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: Text(strings.pendingStatus),
      );
    } else {
      return OutlinedButton(
        onPressed: () => onActionPressed(group),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: Text(strings.requestJoinShort),
      );
    }
  }
}
