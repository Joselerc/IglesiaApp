import 'package:flutter/material.dart';
import '../../screens/ministries/ministries_list_screen.dart';
import '../../screens/groups/groups_list_screen.dart';
import '../../screens/prayers/public_prayer_screen.dart';
import '../../screens/prayers/private_prayer_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';

class ServicesGridSection extends StatelessWidget {
  const ServicesGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Serviços',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Fila 1: Ministerios y Grupos
              Row(
                children: [
                  // Ministerios
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MinistriesListScreen(),
                          ),
                        );
                      },
                      child: _buildServiceItem(
                        icon: Icons.people_outline,
                        label: 'Ministérios',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Grupos
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GroupsListScreen(),
                          ),
                        );
                      },
                      child: _buildServiceItem(
                        icon: Icons.group_outlined,
                        label: 'Connect',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Fila 2: Oración Privada y Pública
              Row(
                children: [
                  // Oración Privada
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivatePrayerScreen(),
                          ),
                        );
                      },
                      child: _buildServiceItem(
                        icon: Icons.lock_person_outlined,
                        label: 'Oração Privada',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Oración Pública
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PublicPrayerScreen(),
                          ),
                        );
                      },
                      child: _buildServiceItem(
                        icon: Icons.campaign_outlined,
                        label: 'Oração Pública',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget para construir cada item del grid
  Widget _buildServiceItem({required IconData icon, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.warmSand,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTextStyles.subtitle2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 