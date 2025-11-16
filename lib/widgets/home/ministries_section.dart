import 'package:flutter/material.dart';
import '../../screens/ministries/ministries_list_screen.dart';
import '../../screens/work_invites/work_schedules_main_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MinistriesSection extends StatelessWidget {
  final String displayTitle;
  
  const MinistriesSection({
    super.key,
    this.displayTitle = 'Ministérios',
  });

  // Verificar si el usuario es miembro de algún ministerio
  Future<bool> _checkIfUserBelongsToAnyMinistry() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      final userPath = '/users/$userId';
      
      final ministeriosQuery = await FirebaseFirestore.instance
          .collection('ministries')
          .get();
      
      for (var doc in ministeriosQuery.docs) {
        final data = doc.data();
        if (!data.containsKey('members')) continue;
        
        final members = data['members'];
        if (members is! List) continue;
        
        for (var member in members) {
          final String memberStr = member.toString();
          if (memberStr == userPath || memberStr == userId) {
            return true;
          }
          
          if (member is DocumentReference && member.id == userId) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Obtener número de invitaciones pendientes
  Future<int> _getPendingInvitesCount() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return 0;

      final invitesSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(userId))
          .where('status', isEqualTo: 'pending')
          .get();

      return invitesSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error obteniendo invitaciones pendientes: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _checkIfUserBelongsToAnyMinistry(),
        _getPendingInvitesCount(),
      ]),
      builder: (context, snapshot) {
        final isMember = snapshot.hasData && snapshot.data![0] == true;
        final pendingCount = snapshot.hasData ? snapshot.data![1] as int : 0;
        
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
            
            // Tarjeta de Ministerios (siempre visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MinistriesListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.warmSand,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.people_outline,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.ministries,
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.participateInChurchMinistries,
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
            
            // Tarjeta de Escalas (solo si es miembro de ministerios)
            if (isMember) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkSchedulesMainScreen(),
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
                              Icons.calendar_today_outlined,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          // Badge con número de pendientes
                          if (pendingCount > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    '$pendingCount',
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
                                  AppLocalizations.of(context)!.workSchedules,
                                  style: AppTextStyles.subtitle1.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$pendingCount ${pendingCount == 1 ? AppLocalizations.of(context)!.pendingSchedule : AppLocalizations.of(context)!.pendingSchedulesLowercase}',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
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
                              AppLocalizations.of(context)!.manageYourServiceSchedules,
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
          ],
        );
      },
    );
  }
} 