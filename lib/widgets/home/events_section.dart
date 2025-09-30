import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../screens/events/events_page.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../common/app_card.dart';
import '../../l10n/app_localizations.dart';

class EventsSection extends StatelessWidget {
  const EventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.events,
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventsPage()),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.seeMore,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320, // Altura para tarjetas de eventos
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('isActive', isEqualTo: true)
                .where('startDate', isGreaterThanOrEqualTo: Timestamp.now())
                .orderBy('startDate', descending: false)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorPlaceholder(context, snapshot.error.toString());
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPlaceholder(context);
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildNoEventsPlaceholder(context);
              }
              
              List<EventModel> events = [];
              for (var doc in snapshot.data!.docs) {
                try {
                  events.add(EventModel.fromFirestore(doc));
                } catch (e) {
                  debugPrint('ERROR - Al procesar evento ${doc.id}: $e');
                  continue;
                }
              }
              
              if (events.isEmpty) {
                 return _buildNoEventsPlaceholder(context);
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      width: 280,
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen
                            _buildEventImage(context, event),
                            // Detalles
                            _buildEventDetails(context, event),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Widgets internos y helpers para Eventos (copiados de HomeScreen) ---

  Widget _buildErrorPlaceholder(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.error(error),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyText2.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildNoEventsPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.noUpcomingEvents,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(BuildContext context, EventModel event) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.md),
          topRight: Radius.circular(AppSpacing.md),
        ),
        child: event.imageUrl.isNotEmpty
            ? Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.warmSand.withOpacity(0.5),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.warmSand,
                    child: Icon(
                      Icons.event,
                      size: 40,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  );
                },
              )
            : Container(
                color: AppColors.warmSand,
                child: Icon(
                  Icons.event,
                  size: 40,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, EventModel event) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(event.startDate)} - ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(event.endDate)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventTypeChip(context, event.eventType),
              if (event.eventType != 'online' && _buildLocationString(context, event).isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _buildLocationString(context, event),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (event.description.isNotEmpty) ...[
            Text(
              event.description,
              style: AppTextStyles.bodyText2.copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventTypeChip(BuildContext context, String eventType) {
    String label;
    Color bgColor;
    Color textColor;
    IconData iconData;

    switch (eventType) {
      case 'online':
        label = AppLocalizations.of(context)!.online;
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        iconData = Icons.videocam_outlined;
        break;
      case 'presential':
        label = AppLocalizations.of(context)!.inPerson;
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        iconData = Icons.location_on_outlined;
        break;
      case 'hybrid':
        label = AppLocalizations.of(context)!.hybrid;
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        iconData = Icons.groups_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: textColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  String _buildLocationString(BuildContext context, EventModel event) {
    List<String> parts = [];
    if (event.street != null && event.street!.isNotEmpty) parts.add(event.street!);
    if (event.number != null && event.number!.isNotEmpty) parts.add(event.number!);
    if (event.neighborhood != null && event.neighborhood!.isNotEmpty) parts.add(event.neighborhood!);
    if (event.city != null && event.city!.isNotEmpty) parts.add(event.city!);
    return parts.join(', ');
  }
} 