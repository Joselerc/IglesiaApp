import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../l10n/app_localizations.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    // Inicializar formato de fecha para portugués si no se ha hecho
    try {
      initializeDateFormatting('pt_BR');
    } catch(e) {
      print('Erro ao inicializar formato pt_BR: $e');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: AppLocalizations.of(context)!.delete,
            onPressed: () async {
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.delete),
                  content: Text(AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisNotification),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                try {
                  await notificationService.deleteNotification(notification.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.notificationDeleted),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorDeleting(e.toString())),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con icono y tipo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: notification.getColor().withOpacity(0.2),
                  radius: 24,
                  child: Icon(
                    notification.getIcon(),
                    color: notification.getColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNotificationTypeName(context, notification.type),
                        style: TextStyle(
                          color: notification.getColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Fecha y hora
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat("EEEE, d 'de' MMMM 'de' y, HH:mm", 'pt_BR')
                        .format(notification.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contenido
            Text(
              AppLocalizations.of(context)!.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            
            // Información adicional si existe (filtrando IDs)
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.additionalInformation,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...notification.data.entries
                  .where((entry) => !entry.key.toLowerCase().endsWith('id')) 
                  .map((entry) {
                 return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value}',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            
            const SizedBox(height: 32),
            
            // Botón para navegar a la acción relacionada si existe
            if (notification.actionRoute != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, notification.actionRoute!);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(AppLocalizations.of(context)!.viewDetails),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getNotificationTypeName(BuildContext context, NotificationType type) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      // Anúncios
      case NotificationType.newAnnouncement:
        return loc.notifTypeNewAnnouncement;
      case NotificationType.newCultAnnouncement:
        return loc.notifTypeNewCultAnnouncement;
      
      // Ministérios
      case NotificationType.newMinistry:
        return loc.notifTypeNewMinistry;
      case NotificationType.ministryJoinRequestAccepted:
        return loc.notifTypeMinistryJoinRequestAccepted;
      case NotificationType.ministryJoinRequestRejected:
        return loc.notifTypeMinistryJoinRequestRejected;
      case NotificationType.ministryJoinRequest:
        return loc.notifTypeMinistryJoinRequest;
      case NotificationType.ministryManuallyAdded:
        return loc.notifTypeMinistryManuallyAdded;
      case NotificationType.ministryNewEvent:
        return loc.notifTypeMinistryNewEvent;
      case NotificationType.ministryNewPost:
        return loc.notifTypeMinistryNewPost;
      case NotificationType.ministryNewWorkSchedule:
        return loc.notifTypeMinistryNewWorkSchedule;
      case NotificationType.ministryWorkScheduleAccepted:
        return loc.notifTypeMinistryWorkScheduleAccepted;
      case NotificationType.ministryWorkScheduleRejected:
        return loc.notifTypeMinistryWorkScheduleRejected;
      case NotificationType.ministryWorkSlotFilled:
        return loc.notifTypeMinistryWorkSlotFilled;
      case NotificationType.ministryWorkSlotAvailable:
        return loc.notifTypeMinistryWorkSlotAvailable;
      case NotificationType.ministryEventReminder:
        return loc.notifTypeMinistryEventReminder;
      case NotificationType.ministryNewChat:
        return loc.notifTypeMinistryNewChat;
      case NotificationType.ministryPromotedToAdmin:
        return loc.notifTypeMinistryPromotedToAdmin;
      
      // Grupos
      case NotificationType.newGroup:
        return loc.notifTypeNewGroup;
      case NotificationType.groupJoinRequestAccepted:
        return loc.notifTypeGroupJoinRequestAccepted;
      case NotificationType.groupJoinRequestRejected:
        return loc.notifTypeGroupJoinRequestRejected;
      case NotificationType.groupJoinRequest:
        return loc.notifTypeGroupJoinRequest;
      case NotificationType.groupManuallyAdded:
        return loc.notifTypeGroupManuallyAdded;
      case NotificationType.groupNewEvent:
        return loc.notifTypeGroupNewEvent;
      case NotificationType.groupNewPost:
        return loc.notifTypeGroupNewPost;
      case NotificationType.groupEventReminder:
        return loc.notifTypeGroupEventReminder;
      case NotificationType.groupNewChat:
        return loc.notifTypeGroupNewChat;
      case NotificationType.groupPromotedToAdmin:
        return loc.notifTypeGroupPromotedToAdmin;
      
      // Orações
      case NotificationType.newPrivatePrayer:
        return loc.notifTypeNewPrivatePrayer;
      case NotificationType.privatePrayerPrayed:
        return loc.notifTypePrivatePrayerPrayed;
      case NotificationType.publicPrayerAccepted:
        return loc.notifTypePublicPrayerAccepted;
      
      // Eventos
      case NotificationType.newEvent:
        return loc.notifTypeNewEvent;
      case NotificationType.eventReminder:
        return loc.notifTypeEventReminder;
      
      // Aconselhamento
      case NotificationType.newCounselingRequest:
        return loc.notifTypeNewCounselingRequest;
      case NotificationType.counselingAccepted:
        return loc.notifTypeCounselingAccepted;
      case NotificationType.counselingRejected:
        return loc.notifTypeCounselingRejected;
      case NotificationType.counselingCancelled:
        return loc.notifTypeCounselingCancelled;
      
      // Vídeos
      case NotificationType.newVideo:
        return loc.notifTypeNewVideo;
      
      // Outros
      case NotificationType.message:
        return loc.notifTypeMessage;
      case NotificationType.generic:
        return loc.notifTypeGeneric;
      case NotificationType.custom:
        return loc.notifTypeCustom;
      default:
        return loc.notifTypeGeneric; // Fallback genérico
    }
  }
} 