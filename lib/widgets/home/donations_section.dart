import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../common/app_card.dart'; // O usar Card normal
import '../../screens/donations/donation_details_screen.dart';
import '../../l10n/app_localizations.dart';

class DonationsSection extends StatelessWidget {
  final String title; // Título viene de homeScreenSections
  final Map<String, dynamic> configData; // Datos para la pantalla de detalles

  const DonationsSection({
    super.key,
    required this.title,
    required this.configData,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica si hay datos de configuración mínimos para mostrar algo
    // (Podríamos añadir una condición más estricta si es necesario)
    bool hasContent = configData.isNotEmpty;

    if (!hasContent) {
      // Si no hay configuración en app_config/donations, no mostrar nada
      // Aunque HomeScreen ya debería filtrar esto, es una salvaguarda.
      return const SizedBox.shrink(); 
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), // Padding reducido para la tarjeta
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Título de la sección (mostrado por HomeScreen)
           Padding(
             padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs), // Padding ajustado
             child: Text(
               title,
               style: AppTextStyles.headline3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ),
           ),
           // Tarjeta clickable
           AppCard(
             padding: EdgeInsets.zero, 
             child: ListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
               leading: Icon(Icons.volunteer_activism, color: AppColors.primary, size: 28),
               title: Text(
                 AppLocalizations.of(context)!.viewDonationOptions, 
                 style: Theme.of(context).textTheme.bodyLarge,
               ),
               trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
               onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => DonationDetailsScreen(configData: configData),
                   ),
                 );
               },
             ),
           ),
        ],
      ),
    );
  }
} 