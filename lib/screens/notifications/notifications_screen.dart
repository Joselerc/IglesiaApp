import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification.dart';
import '../../models/work_invite.dart';
import '../../services/notification_service.dart';
import '../../services/work_schedule_service.dart';
import '../../theme/app_colors.dart';
import 'notification_detail_screen.dart';
import '../../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _filterNotification(AppNotification notification) {
    if (_selectedFilter == null) {
      return true;
    }
    return notification.type == _selectedFilter;
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.all),
            Tab(text: AppLocalizations.of(context)!.unread),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: AppLocalizations.of(context)!.markAllAsRead,
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                await notificationService.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.allNotificationsMarkedAsRead)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.error(e.toString()))),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context)!.moreOptions,
            onSelected: (value) async {
              if (value == 'delete_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.deleteAllNotifications),
                    content: Text(AppLocalizations.of(context)!.areYouSureYouWantToDeleteAllNotifications),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(AppLocalizations.of(context)!.deleteAll),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  setState(() => _isLoading = true);
                  try {
                    await notificationService.deleteAllNotifications();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.allNotificationsDeleted)),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.error(e.toString()))),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete_all',
                child: Text(AppLocalizations.of(context)!.deleteAll),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationListStream(notificationService.getUserNotifications()),
              _buildNotificationListStream(notificationService.getUnreadNotifications()),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationListStream(Stream<List<AppNotification>> stream) {
    return StreamBuilder<List<AppNotification>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())));
        }
        
        final notifications = snapshot.data ?? [];
        final filteredNotifications = notifications.where(_filterNotification).toList();
        
        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        // Agrupar notificaciones de chat
        final groupedNotifications = _groupChatNotifications(filteredNotifications);
        
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: groupedNotifications.length,
          itemBuilder: (context, index) {
            final item = groupedNotifications[index];
            
            if (item is AppNotification) {
              // Notificación individual
              final notification = item;
              if (notification.type == NotificationType.ministryNewWorkSchedule) {
                return _WorkScheduleNotificationCard(
                  notification: notification,
                  notificationService: Provider.of<NotificationService>(context, listen: false),
                );
              }
              
              return _NotificationCard(
                notification: notification,
                notificationService: Provider.of<NotificationService>(context, listen: false),
              );
            } else if (item is _ChatNotificationGroup) {
              // Grupo de notificaciones de chat
              return _ChatGroupCard(
                group: item,
                notificationService: Provider.of<NotificationService>(context, listen: false),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  // Nueva lógica de agrupación
  List<dynamic> _groupChatNotifications(List<AppNotification> notifications) {
    final List<dynamic> result = [];
    final Map<String, _ChatNotificationGroup> groups = {};
    
    for (var notification in notifications) {
      // Identificar si es una notificación de chat (Ministerio o Grupo)
      if (notification.type == NotificationType.ministryNewChat || 
          notification.type == NotificationType.groupNewChat) {
        
        // Usar entityId como clave de agrupación (ID del ministerio o grupo)
        final key = notification.entityId ?? 'unknown';
        
        if (!groups.containsKey(key)) {
          groups[key] = _ChatNotificationGroup(
            entityId: key,
            type: notification.type,
            notifications: [],
            title: notification.title, // "Nuevo mensaje en [Nombre]"
          );
        }
        groups[key]!.notifications.add(notification);
      } else {
        // Si no es chat, añadir directamente a la lista principal
        result.add(notification);
      }
    }
    
    // Insertar los grupos al principio o donde corresponda (por ahora al principio para destacar)
    // O mejor, mantener el orden cronológico basado en el mensaje más reciente del grupo.
    
    // Convertir mapa a lista
    final groupList = groups.values.toList();
    
    // Añadir grupos a la lista de resultados
    result.addAll(groupList);
    
    // Ordenar todo por fecha (para grupos, usar la fecha del mensaje más reciente)
    result.sort((a, b) {
      DateTime dateA;
      DateTime dateB;
      
      if (a is AppNotification) dateA = a.createdAt;
      else dateA = (a as _ChatNotificationGroup).notifications.first.createdAt; // Asumiendo que vienen ordenadas del stream
      
      if (b is AppNotification) dateB = b.createdAt;
      else dateB = (b as _ChatNotificationGroup).notifications.first.createdAt;
      
      return dateB.compareTo(dateA); // Descendente
    });
    
    return result;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _tabController.index == 0 ? Icons.notifications_off : Icons.mark_email_read,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == null
                ? (_tabController.index == 0 
                    ? AppLocalizations.of(context)!.youHaveNoNotifications 
                    : AppLocalizations.of(context)!.youHaveNoUnreadNotifications)
                : (_tabController.index == 0 
                    ? AppLocalizations.of(context)!.youHaveNoNotificationsOfType 
                    : AppLocalizations.of(context)!.youHaveNoUnreadNotificationsOfType),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_selectedFilter != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = null;
                });
              },
              child: Text(AppLocalizations.of(context)!.removeFilter),
            ),
          ],
        ],
      ),
    );
  }
}

// Clase auxiliar para agrupar notificaciones
class _ChatNotificationGroup {
  final String entityId;
  final NotificationType type;
  final String title;
  final List<AppNotification> notifications;

  _ChatNotificationGroup({
    required this.entityId,
    required this.type,
    required this.title,
    required this.notifications,
  });
  
  // Obtener el último mensaje (asumiendo orden descendente en la lista original)
  AppNotification get latestNotification => notifications.first;
  
  int get count => notifications.length;
  
  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

// Tarjeta para grupo de chats
class _ChatGroupCard extends StatelessWidget {
  final _ChatNotificationGroup group;
  final NotificationService notificationService;

  const _ChatGroupCard({
    required this.group,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    final latest = group.latestNotification;
    // Extraer el nombre del ministerio/grupo del título "Nuevo mensaje en [Nombre]"
    // O usar el título tal cual si no se puede parsear fácilmente.
    // El formato en NotificationService es 'Nuevo mensaje en $name'
    String title = group.title; 
    
    // Limpiar el cuerpo del mensaje (quitar "Juan: " si es necesario para mostrar solo el último)
    String subtitle = '${group.count} mensajes nuevos';
    if (group.count == 1) {
      subtitle = latest.message;
    } else {
      subtitle = '${group.count} mensajes • Último: ${latest.message}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: group.unreadCount > 0 ? 2 : 0,
      color: group.unreadCount > 0 ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: group.unreadCount == 0 ? BorderSide(color: Colors.grey.shade200) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Marcar todas como leídas
          for (var n in group.notifications) {
            if (!n.isRead) {
              notificationService.markAsRead(n.id);
            }
          }
          // Navegar al chat
          if (latest.actionRoute != null) {
            Navigator.pushNamed(context, latest.actionRoute!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar grupal
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      group.type == NotificationType.ministryNewChat ? Icons.people : Icons.groups,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  if (group.unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${group.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: group.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(latest.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: group.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: group.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (group.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final NotificationService notificationService;

  const _NotificationCard({
    required this.notification,
    required this.notificationService,
  });

  String _getTranslatedTitle(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (notification.type) {
      case NotificationType.newAnnouncement: return loc.notifTypeNewAnnouncement;
      case NotificationType.newCultAnnouncement: return loc.notifTypeNewCultAnnouncement;
      case NotificationType.newMinistry: return loc.notifTypeNewMinistry;
      case NotificationType.ministryJoinRequestAccepted: return loc.notifTypeMinistryJoinRequestAccepted;
      case NotificationType.ministryJoinRequestRejected: return loc.notifTypeMinistryJoinRequestRejected;
      case NotificationType.ministryJoinRequest: return loc.notifTypeMinistryJoinRequest;
      case NotificationType.ministryManuallyAdded: return loc.notifTypeMinistryManuallyAdded;
      case NotificationType.ministryNewEvent: return loc.notifTypeMinistryNewEvent;
      case NotificationType.ministryNewPost: return loc.notifTypeMinistryNewPost;
      case NotificationType.ministryNewWorkSchedule: return loc.notifTypeMinistryNewWorkSchedule;
      case NotificationType.ministryWorkScheduleAccepted: return loc.notifTypeMinistryWorkScheduleAccepted;
      case NotificationType.ministryWorkScheduleRejected: return loc.notifTypeMinistryWorkScheduleRejected;
      case NotificationType.ministryWorkSlotFilled: return loc.notifTypeMinistryWorkSlotFilled;
      case NotificationType.ministryWorkSlotAvailable: return loc.notifTypeMinistryWorkSlotAvailable;
      case NotificationType.ministryEventReminder: return loc.notifTypeMinistryEventReminder;
      case NotificationType.ministryNewChat: return loc.notifTypeMinistryNewChat;
      case NotificationType.ministryPromotedToAdmin: return loc.notifTypeMinistryPromotedToAdmin;
      case NotificationType.newGroup: return loc.notifTypeNewGroup;
      case NotificationType.groupJoinRequestAccepted: return loc.notifTypeGroupJoinRequestAccepted;
      case NotificationType.groupJoinRequestRejected: return loc.notifTypeGroupJoinRequestRejected;
      case NotificationType.groupJoinRequest: return loc.notifTypeGroupJoinRequest;
      case NotificationType.groupManuallyAdded: return loc.notifTypeGroupManuallyAdded;
      case NotificationType.groupNewEvent: return loc.notifTypeGroupNewEvent;
      case NotificationType.groupNewPost: return loc.notifTypeGroupNewPost;
      case NotificationType.groupEventReminder: return loc.notifTypeGroupEventReminder;
      case NotificationType.groupNewChat: return loc.notifTypeGroupNewChat;
      case NotificationType.groupPromotedToAdmin: return loc.notifTypeGroupPromotedToAdmin;
      case NotificationType.newPrivatePrayer: return loc.notifTypeNewPrivatePrayer;
      case NotificationType.privatePrayerPrayed: return loc.notifTypePrivatePrayerPrayed;
      case NotificationType.publicPrayerAccepted: return loc.notifTypePublicPrayerAccepted;
      case NotificationType.newEvent: return loc.notifTypeNewEvent;
      case NotificationType.eventReminder: return loc.notifTypeEventReminder;
      case NotificationType.newCounselingRequest: return loc.notifTypeNewCounselingRequest;
      case NotificationType.counselingAccepted: return loc.notifTypeCounselingAccepted;
      case NotificationType.counselingRejected: return loc.notifTypeCounselingRejected;
      case NotificationType.counselingCancelled: return loc.notifTypeCounselingCancelled;
      case NotificationType.newVideo: return loc.notifTypeNewVideo;
      case NotificationType.message: return loc.notifTypeMessage;
      default: return notification.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notificationDeleted)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead ? BorderSide(color: Colors.grey.shade200) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!notification.isRead) {
              notificationService.markAsRead(notification.id);
            }
            if (notification.actionRoute != null) {
              Navigator.pushNamed(context, notification.actionRoute!);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailScreen(notification: notification),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: notification.isRead 
                    ? Colors.grey.shade100 
                    : notification.getColor().withOpacity(0.1),
                  child: Icon(
                    notification.getIcon(),
                    color: notification.isRead ? Colors.grey : notification.getColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _getTranslatedTitle(context),
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM').format(notification.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: notification.isRead ? Colors.grey.shade600 : Colors.black87,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkScheduleNotificationCard extends StatefulWidget {
  final AppNotification notification;
  final NotificationService notificationService;

  const _WorkScheduleNotificationCard({
    required this.notification,
    required this.notificationService,
  });

  @override
  State<_WorkScheduleNotificationCard> createState() => _WorkScheduleNotificationCardState();
}

class _WorkScheduleNotificationCardState extends State<_WorkScheduleNotificationCard> {
  bool _isExpanded = false;
  WorkInvite? _workInvite;
  bool _isLoading = true;
  final WorkScheduleService _workScheduleService = WorkScheduleService();

  @override
  void initState() {
    super.initState();
    _loadWorkInvite();
  }

  Future<void> _loadWorkInvite() async {
    if (widget.notification.entityId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('work_invites')
          .doc(widget.notification.entityId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _workInvite = WorkInvite.fromFirestore(doc);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _translateNotificationText(String text) {
    // Compatibilidad con textos antiguos o hardcodeados
    if (text == 'NEW_SERVICE_INVITATION') {
      return AppLocalizations.of(context)!.newServiceInvitation;
    }
    if (text.startsWith('INVITED_TO_SERVE_AS:')) {
      final role = text.substring('INVITED_TO_SERVE_AS:'.length);
      return AppLocalizations.of(context)!.invitedToServeAs(role);
    }
    
    // Nueva lógica basada en tipo (prioridad)
    final loc = AppLocalizations.of(context)!;
    if (widget.notification.type == NotificationType.ministryNewWorkSchedule) {
      return loc.notifTypeMinistryNewWorkSchedule;
    }
    
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_workInvite == null) return _buildFallback();

    final isPending = _workInvite!.status == 'pending';

    return Dismissible(
      key: Key(widget.notification.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        widget.notificationService.deleteNotification(widget.notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notificationDeleted)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: widget.notification.isRead ? 0 : 2,
        color: widget.notification.isRead ? Colors.white : Colors.blue.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPending 
            ? BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5) 
            : (widget.notification.isRead ? BorderSide(color: Colors.grey.shade200) : BorderSide.none),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
            if (!widget.notification.isRead) {
              widget.notificationService.markAsRead(widget.notification.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      radius: 20,
                      child: Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translateNotificationText(widget.notification.title),
                            style: TextStyle(
                              fontWeight: widget.notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_workInvite!.role} • ${DateFormat('dd/MM/yyyy').format(_workInvite!.date)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                        if (!widget.notification.isRead) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                if (_isExpanded) ...[
                  const Divider(height: 24),
                  _buildExpandedContent(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final isPending = _workInvite!.status == 'pending';
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoColumn(
                Icons.church,
                _workInvite!.entityType == 'cult' ? 'Culto' : 'Evento', // Idealmente traducir esto también
                _workInvite!.entityName,
              ),
            ),
            Expanded(
              child: _buildInfoColumn(
                Icons.work_outline,
                AppLocalizations.of(context)!.ministry,
                _workInvite!.ministryName,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoColumn(
                Icons.event,
                AppLocalizations.of(context)!.date,
                DateFormat('dd/MM/yyyy').format(_workInvite!.date),
              ),
            ),
            Expanded(
              child: _buildInfoColumn(
                Icons.access_time,
                AppLocalizations.of(context)!.time,
                '${DateFormat('HH:mm').format(_workInvite!.startTime)} - ${DateFormat('HH:mm').format(_workInvite!.endTime)}',
              ),
            ),
          ],
        ),
        if (isPending) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rejectSchedule,
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(AppLocalizations.of(context)!.reject),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _acceptSchedule,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(AppLocalizations.of(context)!.accept),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
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

  Widget _buildSkeleton() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 16, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 150, height: 12, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Fallback simple si falla la carga de detalles de la invitación
  Widget _buildFallback() {
    return _NotificationCard(
      notification: widget.notification,
      notificationService: widget.notificationService,
    );
  }

  Future<void> _acceptSchedule() async {
    // ... (Lógica existente sin cambios, solo asegurando que llame al servicio correctamente)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmAcceptSchedule),
        content: Text(AppLocalizations.of(context)!.confirmAcceptScheduleMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.accept)),
        ],
      ),
    );

    if (confirm != true || _workInvite == null) return;

    try {
      await _workScheduleService.updateAssignmentStatus(_workInvite!.id, 'accepted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scheduleAcceptedSuccessfully), backgroundColor: Colors.green));
        await _loadWorkInvite();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorAcceptingSchedule}: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmRejectSchedule),
        content: Text(AppLocalizations.of(context)!.confirmRejectScheduleMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );

    if (confirm != true || _workInvite == null) return;

    try {
      await _workScheduleService.updateAssignmentStatus(_workInvite!.id, 'rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scheduleRejectedSuccessfully), backgroundColor: Colors.orange));
        await _loadWorkInvite();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.errorRejectingSchedule}: $e'), backgroundColor: Colors.red));
    }
  }
}
