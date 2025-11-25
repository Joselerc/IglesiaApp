import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement_model.dart';
import '../../screens/announcements/announcement_detail_screen.dart';
// import '../../screens/announcements/cult_announcements_screen.dart'; // Eliminada esta importación
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../announcement_card.dart'; // Asegúrate que la ruta sea correcta
import '../../l10n/app_localizations.dart';

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
                AppLocalizations.of(context)!.announcements,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // TextButton.icon eliminado
            ],
          ),
        ),
        SizedBox(
          height: 140, // Ajustado para tarjetas con proporción 16:9
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .where('isActive', isEqualTo: true)
                .orderBy('date', descending: false) // Ordenar por fecha ascendente para mostrar los que van a caducar pronto
                .limit(20) // Límite generoso para filtrar en memoria
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.errorLoadingAnnouncements));
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
                // Si no tiene fecha, mostrar siempre (hasta que sea eliminado manualmente)
                // Nota: Asumimos que si `date` viene de Firestore podría ser una fecha lejana o nula si así se guarda.
                // Pero según el modelo actual, `date` es required. Si queremos que sea opcional, 
                // el modelo debería permitirlo. Si el modelo obliga a `date`, entonces la lógica de "sin fecha"
                // depende de cómo se guarde (ej: año 2100).
                
                // Lógica de expiración:
                // El anuncio se muestra SI la fecha de expiración es HOY o FUTURA.
                // O si no tiene fecha de inicio definida (startDate), o si ya pasó la fecha de inicio.
                
                // 1. Verificar inicio (startDate) - Para programar a futuro
                if (announcement.startDate != null) {
                final startDate = DateTime(
                  announcement.startDate!.year,
                  announcement.startDate!.month,
                  announcement.startDate!.day
                );
                  if (startDate.isAfter(today)) return false; // Aún no empieza
                }

                // 2. Verificar expiración (date)
                // Convertir a fecha sin hora para comparar solo días
                final expirationDate = DateTime(
                  announcement.date.year,
                  announcement.date.month,
                  announcement.date.day
                );
                
                // Si la fecha de expiración es ANTERIOR a hoy, ya expiró.
                // (date < today) -> Expirado
                if (expirationDate.isBefore(today)) return false;

                return true;
              }).toList();
              
              // Reordenar: Primero los más nuevos (creados recientemente) o los que van a caducar más tarde?
              // Generalmente queremos ver lo más nuevo primero.
              filteredAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (filteredAnnouncements.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30), // Ajustar padding
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noAnnouncementsAvailable,
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
