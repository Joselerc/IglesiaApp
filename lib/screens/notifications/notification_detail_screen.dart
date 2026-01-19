import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/work_schedule_service.dart';
import '../../services/group_service.dart';
import '../../services/ministry_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/work_invite.dart';
import 'package:flutter/foundation.dart';

class NotificationDetailScreen extends StatefulWidget {
  final AppNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final WorkScheduleService _workScheduleService = WorkScheduleService();
  final GroupService _groupService = GroupService();
  final MinistryService _ministryService = MinistryService();
  WorkInvite? _workInvite;
  bool _isLoadingInvite = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadWorkInviteIfNeeded();
  }

  Future<void> _loadWorkInviteIfNeeded() async {
    // Solo cargar si es una notificación de escala y tiene entityId
    if (widget.notification.type == NotificationType.ministryNewWorkSchedule &&
        widget.notification.entityId != null) {
      setState(() {
        _isLoadingInvite = true;
      });

      try {
        final doc = await FirebaseFirestore.instance
            .collection('work_invites')
            .doc(widget.notification.entityId)
            .get();

        if (doc.exists) {
          setState(() {
            _workInvite = WorkInvite.fromFirestore(doc);
          });
        }
      } catch (e) {
        debugPrint('Error cargando work_invite: $e');
      } finally {
        setState(() {
          _isLoadingInvite = false;
        });
      }
    }
  }

  Future<void> _handleSecureNavigation(String route) async {
    final strings = AppLocalizations.of(context)!;
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.mustBeLoggedIn)),
      );
      return;
    }

    try {
      // Verificar si es una ruta de grupo: /groups/{groupId}
      if (route.startsWith('/groups/')) {
        final groupId = route.substring('/groups/'.length);
        final group = await _groupService.getGroupById(groupId);

        if (group == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.groupNotFound)),
          );
          return;
        }

        // Verificar permisos de acceso al grupo
        final userStatus = group.getUserStatus(user.uid);
        if (userStatus == 'Enter' || userStatus == 'Pending') {
          // Usuario tiene acceso o solicitud pendiente
          Navigator.pushNamed(context, route);
        } else {
          // Usuario no tiene acceso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.noAccessToGroup),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Verificar si es una ruta de ministerio: /ministries/{ministryId}
      if (route.startsWith('/ministries/')) {
        final pathParts = route.split('/');
        if (pathParts.length >= 3) {
          final ministryId = pathParts[2];
          final ministry = await _ministryService.getMinistryById(ministryId);

          if (ministry == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.ministryNotFound)),
            );
            return;
          }

          // Verificar permisos de acceso al ministerio
          final userStatus = ministry.getUserStatus(user.uid);
          if (userStatus == 'Enter' || userStatus == 'Pending') {
            // Usuario tiene acceso o solicitud pendiente
            Navigator.pushNamed(context, route);
          } else {
            // Usuario no tiene acceso
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.noAccessToMinistry),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Para otras rutas, navegar normalmente
      Navigator.pushNamed(context, route);

    } catch (e) {
      debugPrint('Error en navegación segura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorLoadingData(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptSchedule() async {
    if (_workInvite == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmAcceptSchedule),
        content: Text(AppLocalizations.of(context)!.confirmAcceptScheduleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.accept),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _workScheduleService.updateAssignmentStatus(_workInvite!.id, 'accepted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scheduleAcceptedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar la invitación para actualizar el estado
        await _loadWorkInviteIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorAcceptingSchedule}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectSchedule() async {
    if (_workInvite == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmRejectSchedule),
        content: Text(AppLocalizations.of(context)!.confirmRejectScheduleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _workScheduleService.updateAssignmentStatus(_workInvite!.id, 'rejected');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scheduleRejectedSuccessfully),
            backgroundColor: Colors.orange,
          ),
        );
        // Recargar la invitación para actualizar el estado
        await _loadWorkInviteIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorRejectingSchedule}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

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
                  await notificationService.deleteNotification(widget.notification.id);
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
                  backgroundColor: widget.notification.getColor().withOpacity(0.2),
                  radius: 24,
                  child: Icon(
                    widget.notification.getIcon(),
                    color: widget.notification.getColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translateNotificationText(widget.notification.title),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNotificationTypeName(context, widget.notification.type),
                        style: TextStyle(
                          color: widget.notification.getColor(),
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
                        .format(widget.notification.createdAt),
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
              _translateNotificationText(widget.notification.message),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            
            // Detalles de la escala si es una notificación de work schedule
            if (widget.notification.type == NotificationType.ministryNewWorkSchedule) ...[
              const SizedBox(height: 24),
              if (_isLoadingInvite)
                const Center(child: CircularProgressIndicator())
              else if (_workInvite != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.scheduleDetails,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        Icons.church,
                        _workInvite!.entityType == 'cult' ? 'Culto' : 'Evento',
                        _workInvite!.entityName,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.event,
                        AppLocalizations.of(context)!.date,
                        DateFormat('dd/MM/yyyy').format(_workInvite!.date),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.access_time,
                        AppLocalizations.of(context)!.time,
                        '${DateFormat('HH:mm').format(_workInvite!.startTime)} - ${DateFormat('HH:mm').format(_workInvite!.endTime)}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.work_outline,
                        AppLocalizations.of(context)!.ministry,
                        _workInvite!.ministryName,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.person_outline,
                        AppLocalizations.of(context)!.roleToPerform,
                        _workInvite!.role,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.info_outline,
                        AppLocalizations.of(context)!.status,
                        _getStatusLabel(_workInvite!.status),
                      ),
                    ],
                  ),
                ),
                
                // Botones de acción si la escala está pendiente
                if (_workInvite!.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _rejectSchedule,
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(AppLocalizations.of(context)!.reject),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _acceptSchedule,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(AppLocalizations.of(context)!.accept),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
            
            // Información adicional si existe (filtrando IDs)
            if (widget.notification.data.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.additionalInformation,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.notification.data.entries
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
            if (widget.notification.actionRoute != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _handleSecureNavigation(widget.notification.actionRoute!);
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
      case NotificationType.taggedPost:
        return loc.notifTypeTaggedPost;
      
      // Ministérios
      case NotificationType.newMinistry:
        return loc.notifTypeNewMinistry;
      case NotificationType.ministryJoinRequestAccepted:
        return loc.notifTypeMinistryJoinRequestAccepted;
      case NotificationType.ministryJoinRequestRejected:
        return loc.notifTypeMinistryJoinRequestRejected;
      case NotificationType.ministryJoinRequest:
        return loc.notifTypeMinistryJoinRequest;
      case NotificationType.ministryInviteReceived:
        return loc.invitationLabel;
      case NotificationType.ministryInviteAccepted:
        return loc.invitationAccepted;
      case NotificationType.ministryInviteRejected:
        return loc.invitationRejected;
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
      case NotificationType.groupInviteReceived:
        return loc.invitationLabel;
      case NotificationType.groupInviteAccepted:
        return loc.invitationAccepted;
      case NotificationType.groupInviteRejected:
        return loc.invitationRejected;
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

      // Famílias
      case NotificationType.newFamily:
        return loc.notifTypeNewFamily;
      case NotificationType.familyInviteReceived:
        return loc.invitationLabel;
      case NotificationType.familyInviteAccepted:
        return loc.invitationAccepted;
      case NotificationType.familyInviteRejected:
        return loc.invitationRejected;

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
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    final loc = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return loc.pendingStatus;
      case 'accepted':
      case 'confirmed':
        return loc.confirmed;
      case 'rejected':
      case 'declined':
        return loc.rejected;
      case 'seen':
        return loc.seen;
      default:
        return status;
    }
  }

  // Helper para traducir claves de notificación
  String _translateNotificationText(String text) {
    // Si es una clave conocida, traducirla
    if (text == 'NEW_SERVICE_INVITATION') {
      return AppLocalizations.of(context)!.newServiceInvitation;
    }
    
    // Si es un mensaje con rol (formato: INVITED_TO_SERVE_AS:RoleName)
    if (text.startsWith('INVITED_TO_SERVE_AS:')) {
      final role = text.substring('INVITED_TO_SERVE_AS:'.length);
      return AppLocalizations.of(context)!.invitedToServeAs(role);
    }
    
    // Si no es una clave, devolver el texto original (compatibilidad con notificaciones antiguas)
    return text;
  }
} 
