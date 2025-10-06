import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../l10n/app_localizations.dart';

class NotificationTypeFilter extends StatelessWidget {
  final NotificationType? selectedFilter;
  final Function(NotificationType?) onFilterSelected;

  const NotificationTypeFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.filterByType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedFilter != null)
                TextButton(
                  onPressed: () => onFilterSelected(null),
                  child: Text(AppLocalizations.of(context)!.removeFilter),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anuncios
                  _buildCategoryHeader(AppLocalizations.of(context)!.announcements, Icons.announcement, Colors.amber),
                  _buildFilterTile(
                    context,
                    NotificationType.newAnnouncement,
                    AppLocalizations.of(context)!.generalAnnouncements,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.newCultAnnouncement,
                    AppLocalizations.of(context)!.cultAnnouncements,
                  ),
                  const Divider(),
                  
                  // Ministerios
                  _buildCategoryHeader(AppLocalizations.of(context)!.ministries, Icons.people, Colors.blue),
                  _buildFilterTile(
                    context,
                    NotificationType.newMinistry,
                    AppLocalizations.of(context)!.newMinistries,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryJoinRequest,
                    AppLocalizations.of(context)!.joinRequests,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryJoinRequestAccepted,
                    AppLocalizations.of(context)!.approvedRequests,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewEvent,
                    AppLocalizations.of(context)!.ministryEvents,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewPost,
                    AppLocalizations.of(context)!.ministryPosts,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewWorkSchedule,
                    AppLocalizations.of(context)!.workSchedules,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewChat,
                    AppLocalizations.of(context)!.ministryMessages,
                  ),
                  const Divider(),
                  
                  // Grupos
                  _buildCategoryHeader(AppLocalizations.of(context)!.groups, Icons.group, Colors.green),
                  _buildFilterTile(
                    context,
                    NotificationType.newGroup,
                    AppLocalizations.of(context)!.newGroups,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupJoinRequest,
                    AppLocalizations.of(context)!.joinRequests,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupJoinRequestAccepted,
                    AppLocalizations.of(context)!.approvedRequests,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupNewEvent,
                    AppLocalizations.of(context)!.groupEvents,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupNewPost,
                    AppLocalizations.of(context)!.groupPosts,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupNewChat,
                    AppLocalizations.of(context)!.groupMessages,
                  ),
                  const Divider(),
                  
                  // Oraciones
                  _buildCategoryHeader(AppLocalizations.of(context)!.prayers, Icons.healing, Colors.purple),
                  _buildFilterTile(
                    context,
                    NotificationType.newPrivatePrayer,
                    AppLocalizations.of(context)!.privatePrayerRequests,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.privatePrayerPrayed,
                    AppLocalizations.of(context)!.completedPrayers,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.publicPrayerAccepted,
                    AppLocalizations.of(context)!.approvedPublicPrayers,
                  ),
                  const Divider(),
                  
                  // Eventos
                  _buildCategoryHeader(AppLocalizations.of(context)!.events, Icons.event, Colors.orange),
                  _buildFilterTile(
                    context,
                    NotificationType.newEvent,
                    AppLocalizations.of(context)!.newEvents,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.eventReminder,
                    AppLocalizations.of(context)!.eventReminders,
                  ),
                  const Divider(),
                  
                  // Consejería
                  _buildCategoryHeader(AppLocalizations.of(context)!.counseling, Icons.support_agent, Colors.teal),
                  _buildFilterTile(
                    context,
                    NotificationType.newCounselingRequest,
                    AppLocalizations.of(context)!.newRequests,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.counselingAccepted,
                    AppLocalizations.of(context)!.confirmedAppointments,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.counselingRejected,
                    AppLocalizations.of(context)!.rejectedAppointments,
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.counselingCancelled,
                    AppLocalizations.of(context)!.cancelledAppointments,
                  ),
                  const Divider(),
                  
                  // Videos
                  _buildCategoryHeader(AppLocalizations.of(context)!.videos, Icons.video_library, Colors.red),
                  _buildFilterTile(
                    context,
                    NotificationType.newVideo,
                    AppLocalizations.of(context)!.newVideos,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context,
    NotificationType type,
    String title,
  ) {
    final isSelected = selectedFilter == type;
    
    return ListTile(
      title: Text(title),
      leading: Radio<NotificationType>(
        value: type,
        groupValue: selectedFilter,
        onChanged: (value) => onFilterSelected(value),
      ),
      selected: isSelected,
      onTap: () => onFilterSelected(type),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      dense: true,
    );
  }
} 