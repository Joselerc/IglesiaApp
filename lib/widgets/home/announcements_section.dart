import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement_model.dart';
import '../../screens/announcements/announcement_detail_screen.dart';
import '../../screens/announcements/cult_announcements_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../announcement_card.dart'; // Asegúrate que la ruta sea correcta

class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anúncios',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CultAnnouncementsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.church, size: 16),
                label: const Text('Ver Cultos'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary, // Color explícito
                    padding: EdgeInsets.zero, // Ajustar padding si es necesario
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140, // Ajustado para tarjetas con proporción 16:9
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .where('isActive', isEqualTo: true)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                ))
                .orderBy('date', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar anúncios'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final announcements = snapshot.data!.docs
                  .map((doc) => AnnouncementModel.fromFirestore(doc))
                  .toList();

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final filteredAnnouncements = announcements.where((announcement) {
                if (announcement.startDate == null) return true;
                final startDate = DateTime(
                  announcement.startDate!.year,
                  announcement.startDate!.month,
                  announcement.startDate!.day
                );
                return startDate.compareTo(today) <= 0;
              }).toList();

              if (filteredAnnouncements.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30), // Ajustar padding
                  child: Center(
                    child: Text(
                      'Não há anúncios disponíveis',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredAnnouncements.length,
                itemBuilder: (context, index) {
                  final announcement = filteredAnnouncements[index];
                  return AnnouncementCard(
                    announcement: announcement,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetailScreen(
                            announcement: announcement,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 