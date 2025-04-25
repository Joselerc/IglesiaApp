import 'package:flutter/material.dart';
import '../models/ministry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../screens/shared/entity_info_screen.dart';

class MinistryCard extends StatelessWidget {
  final Ministry ministry;
  final String userId;
  final Function(Ministry) onActionPressed;

  const MinistryCard({
    Key? key,
    required this.ministry,
    required this.userId,
    required this.onActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = userId.isNotEmpty ? ministry.getUserStatus(userId) : 'Solicitar';
    final isAdmin = ministry.isAdmin(userId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con avatar y nombre
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.warmSand,
                    shape: BoxShape.circle,
                    image: ministry.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(ministry.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: ministry.imageUrl.isEmpty
                      ? Icon(Icons.groups_rounded, color: AppColors.primary, size: 28)
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Información del ministerio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ministry.name,
                              style: AppTextStyles.subtitle1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ministry.description.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.info_outline, 
                                size: 20, 
                                color: AppColors.textSecondary
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Mais informações',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EntityInfoScreen(
                                      entityId: ministry.id,
                                      entityType: EntityType.ministry,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      Text(
                        _formatMemberCount(ministry.memberIds.length),
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildButton(BuildContext context, String status) {
    if (status == 'Enter') {
      return ElevatedButton(
        onPressed: () => onActionPressed(ministry),
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
        child: const Text('Entrar'),
      );
    } else if (status == 'Pending') {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: const Text('Pendente'),
      );
    } else {
      return OutlinedButton(
        onPressed: () => onActionPressed(ministry),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: const Text('Solicitar'),
      );
    }
  }
  
  String _formatMemberCount(int count) {
    if (count == 1) {
      return '1 membro';
    } else {
      return '$count membros';
    }
  }
} 