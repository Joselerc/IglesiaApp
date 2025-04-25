import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/cult.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class CultsSection extends StatelessWidget {
  const CultsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Programação de Cultos',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cults')
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                ))
                .orderBy('date', descending: false)
                .limit(7)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      'Não há cultos programados',
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final cultDocs = snapshot.data!.docs;
              final cults = cultDocs
                  .map((doc) {
                    try {
                      return Cult.fromFirestore(doc);
                    } catch (e) {
                      debugPrint('Error parsing cult ${doc.id}: $e');
                      return null; // Ignorar cultos con error de parseo
                    }
                  })
                  .where((cult) => cult != null) // Filtrar nulos
                  .cast<Cult>()
                  .toList();

              if (cults.isEmpty) {
                 return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      'Não há cultos programados',
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cults.length,
                itemBuilder: (context, index) {
                  final cult = cults[index];
                  return _buildCultScheduleCard(context, cult); // Reutiliza el método existente
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Método copiado de HomeScreen (podría moverse a un archivo de utils o mantenerse aquí)
  Widget _buildCultScheduleCard(BuildContext context, Cult cult) {
    final dayFormatter = DateFormat('EEEE', 'pt_BR');
    final dateFormatter = DateFormat('dd/MM/yy', 'pt_BR');
    final timeFormatter = DateFormat('HH:mm', 'pt_BR');

    String dayString = dayFormatter.format(cult.date);
    dayString = dayString[0].toUpperCase() + dayString.substring(1);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final cultDateOnly = DateTime(cult.date.year, cult.date.month, cult.date.day);

    final bool isToday = cultDateOnly.isAtSameMomentAs(today);
    final bool isTomorrow = cultDateOnly.isAtSameMomentAs(tomorrow);
    final bool highlightCard = isToday || isTomorrow;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Hoje';
    } else if (isTomorrow) {
      dateLabel = 'Amanhã';
    } else {
      dateLabel = dateFormatter.format(cult.date);
    }

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: highlightCard
            ? Border.all(color: AppColors.primary.withOpacity(0.7), width: 1.5)
            : Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.0),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 4,
             offset: const Offset(0, 1),
           ),
        ],
      ),
      child: ClipRRect(
         borderRadius: BorderRadius.circular(AppSpacing.md),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             Container(
               color: AppColors.warmSand,
               padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     dayString,
                     style: AppTextStyles.caption.copyWith(
                       color: AppColors.primary,
                       fontWeight: FontWeight.bold,
                     ),
                     overflow: TextOverflow.ellipsis,
                   ),
                   Text(
                     dateLabel,
                     style: AppTextStyles.caption.copyWith(
                       color: AppColors.textSecondary,
                       fontWeight: (isToday || isTomorrow) ? FontWeight.bold : FontWeight.normal,
                     ),
                     overflow: TextOverflow.ellipsis,
                   ),
                 ],
               ),
             ),
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       cult.name,
                       style: AppTextStyles.subtitle2.copyWith(
                         fontWeight: FontWeight.w600,
                         color: AppColors.textPrimary,
                       ),
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                     Row(
                       children: [
                         Icon(Icons.access_time_outlined, size: 14, color: AppColors.textSecondary),
                         const SizedBox(width: 4),
                         Text(
                           '${timeFormatter.format(cult.startTime)} - ${timeFormatter.format(cult.endTime)}',
                           style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             ),
           ],
         ),
      ),
    );
  }
} 