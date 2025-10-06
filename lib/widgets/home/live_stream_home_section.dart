import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marquee/marquee.dart'; // Importar marquee
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../common/app_card.dart'; // Asumiendo que tienes un AppCard reutilizable
import '../../l10n/app_localizations.dart';

class LiveStreamHomeSection extends StatelessWidget {
  final Map<String, dynamic> configData;
  final bool isVisible; // Nuevo parámetro para saber si debe mostrarse
  final String displayTitle; // NUEVO PARÁMETRO

  const LiveStreamHomeSection({
    super.key, 
    required this.configData,
    this.isVisible = true, // Por defecto true si se construye
    required this.displayTitle, // NUEVO PARÁMETRO REQUERIDO
  });

  @override
  Widget build(BuildContext context) {
    // Ya no necesitamos isCurrentlyLive. La visibilidad la controla HomeScreen.
    // El estado "en vivo" visualmente (tag, borde) depende de si se muestra Y tiene link.
    final String imageUrl = configData['imageUrl'] ?? '';
    final String imageTitle = configData['imageTitle'] ?? '';
    final String liveUrl = configData['url'] ?? '';

    final bool hasLink = liveUrl.isNotEmpty; // Restaurado
    // El estado visual "en vivo" ahora es simplemente si es visible y tiene link
    final bool showAsLive = isVisible && hasLink; 

    // No mostrar nada si isVisible es false (aunque HomeScreen ya debería filtrarlo)
    if (!isVisible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección - Usando AppTextStyles.headline3
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md), // Añadir padding inferior como en CultsSection
            child: Text(
              displayTitle,  // USAR EL NUEVO PARÁMETRO displayTitle
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.textPrimary, // Asegurar color consistente
                fontWeight: FontWeight.bold, // Asegurar negrita consistente
              )
            ),
          ),
          // const SizedBox(height: AppSpacing.md), // Eliminado porque el padding ya da espacio

          // La tarjeta principal de la transmisión
          GestureDetector(
            // Clickable solo si se muestra como vivo (visible + link)
            onTap: showAsLive 
                ? () async {
                    final uri = Uri.parse(liveUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenLink(liveUrl))),
                      );
                    }
                  }
                : null, // Desactivar onTap si no está en vivo o no hay link
            child: AppCard(
              padding: EdgeInsets.zero, // El padding lo manejaremos dentro
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.md), // Asegurar borde redondeado
                  // Borde solo si se muestra como vivo
                  border: showAsLive
                      ? Border.all(color: AppColors.primary, width: 2.0) 
                      : null,
                ),
                child: ClipRRect( // Clip para que el contenido respete el borde redondeado
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  child: Stack(
                    alignment: Alignment.bottomLeft, // Alinear contenido inferior izquierdo
                    children: [
                      // Imagen de fondo
                      Container(
                        height: 200, // Altura fija o adaptable
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.md), // Heredar o definir radio
                          image: imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.4), // Oscurecer un poco para el texto
                                    BlendMode.darken,
                                  ),
                                )
                              : null, // Sin imagen si no hay URL
                          color: imageUrl.isEmpty ? Colors.grey.shade300 : null, // Color placeholder
                        ),
                        // Mostrar icono si no hay imagen
                        child: imageUrl.isEmpty
                           ? const Center(child: Icon(Icons.live_tv, size: 60, color: Colors.grey))
                           : null,
                      ),

                      // Contenido superpuesto (Título y estado)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                           borderRadius: const BorderRadius.only(
                             bottomLeft: Radius.circular(AppSpacing.md),
                             bottomRight: Radius.circular(AppSpacing.md),
                           ),
                           gradient: LinearGradient(
                             begin: Alignment.bottomCenter,
                             end: Alignment.topCenter,
                             colors: [
                               Colors.black.withOpacity(0.7),
                               Colors.black.withOpacity(0.0),
                             ],
                           ),
                        ),
                        child: Column(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Título sobre la imagen con Marquee
                             if (imageTitle.isNotEmpty)
                               SizedBox(
                                 height: 25, // Altura fija para el marquee
                                 child: Marquee(
                                   text: imageTitle,
                                   // Usando estilo estándar titleLarge
                                   style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                   scrollAxis: Axis.horizontal,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   blankSpace: 20.0,
                                   velocity: 50.0, // Velocidad del scroll
                                   pauseAfterRound: const Duration(seconds: 1),
                                   showFadingOnlyWhenScrolling: true,
                                   fadingEdgeStartFraction: 0.1,
                                   fadingEdgeEndFraction: 0.1,
                                   startPadding: 10.0,
                                   accelerationDuration: const Duration(milliseconds: 500),
                                   accelerationCurve: Curves.linear,
                                   decelerationDuration: const Duration(milliseconds: 500),
                                   decelerationCurve: Curves.easeOut,
                                 ),
                               ),
                             const SizedBox(height: AppSpacing.sm),

                             // Mensaje de estado (Link disponible o no)
                             Text(
                               // Mensaje depende solo de si hay link (ya que solo se muestra si está activo)
                               hasLink
                                   ? AppLocalizations.of(context)!.tapToWatchNow
                                   : AppLocalizations.of(context)!.streamLinkComingSoon, // Ya no hay caso "indisponible"
                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                             ),
                           ],
                        ),
                      ),

                      // Tag "AO VIVO"
                      if (showAsLive)
                        Positioned(
                          top: AppSpacing.md,
                          right: AppSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.live,
                              // Usando estilo estándar bodySmall
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 