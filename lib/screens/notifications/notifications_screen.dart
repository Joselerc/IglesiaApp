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

  // Aplicar filtro por tipo de notificación
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
          // Marcar todas como leídas
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: AppLocalizations.of(context)!.markAllAsRead,
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              try {
                await notificationService.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.allNotificationsMarkedAsRead),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.error(e.toString())),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
          // Menú de opciones
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
                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await notificationService.deleteAllNotifications();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.allNotificationsDeleted),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.error(e.toString())),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
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
              // Todas las notificaciones
              StreamBuilder<List<AppNotification>>(
                stream: notificationService.getUserNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())),
                    );
                  }
                  
                  final notifications = snapshot.data ?? [];
                  final filteredNotifications = notifications.where(_filterNotification).toList();
                  
                  if (filteredNotifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == null
                                ? AppLocalizations.of(context)!.youHaveNoNotifications
                                : AppLocalizations.of(context)!.youHaveNoNotificationsOfType,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
                  
                  return _buildNotificationsList(filteredNotifications);
                },
              ),
              
              // Notificaciones no leídas
              StreamBuilder<List<AppNotification>>(
                stream: notificationService.getUnreadNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())),
                    );
                  }
                  
                  final notifications = snapshot.data ?? [];
                  final filteredNotifications = notifications.where(_filterNotification).toList();
                  
                  if (filteredNotifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mark_email_read,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == null
                                ? AppLocalizations.of(context)!.youHaveNoUnreadNotifications
                                : AppLocalizations.of(context)!.youHaveNoUnreadNotificationsOfType,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
                  
                  return _buildNotificationsList(filteredNotifications);
                },
              ),
            ],
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        
        // Si es una notificación de escala, mostrar widget expandible
        if (notification.type == NotificationType.ministryNewWorkSchedule) {
          return _WorkScheduleNotificationCard(
            notification: notification,
            notificationService: notificationService,
          );
        }
        
        // Notificación normal
        return Dismissible(
          key: Key(notification.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) async {
            try {
              await notificationService.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.notificationDeleted),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.error(e.toString())),
                ),
              );
            }
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification.getColor().withOpacity(0.2),
              child: Icon(
                notification.getIcon(),
                color: notification.getColor(),
                size: 20,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: notification.isRead
                ? null
                : Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () async {
              // Si no está leída, marcarla como leída
              if (!notification.isRead) {
                await notificationService.markAsRead(notification.id);
              }
              
              // Navegar a la página de detalles
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationDetailScreen(notification: notification),
                  ),
                );
              }
            },
          ),
      );
    },
  );
}
}

// Widget expandible para notificaciones de trabajo
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _translateNotificationText(String text) {
    if (text == 'NEW_SERVICE_INVITATION') {
      return AppLocalizations.of(context)!.newServiceInvitation;
    }
    if (text.startsWith('INVITED_TO_SERVE_AS:')) {
      final role = text.substring('INVITED_TO_SERVE_AS:'.length);
      return AppLocalizations.of(context)!.invitedToServeAs(role);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    if (_workInvite == null) {
      return _buildFallbackNotification();
    }

    final isPending = _workInvite!.status == 'pending';

    return Dismissible(
      key: Key(widget.notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        try {
          await widget.notificationService.deleteNotification(widget.notification.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.notificationDeleted)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.error(e.toString()))),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: widget.notification.isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPending 
            ? BorderSide(color: AppColors.primary.withOpacity(0.3), width: 2) 
            : BorderSide.none,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado compacto (siempre visible)
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      radius: 20,
                      child: Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _translateNotificationText(widget.notification.title),
                            style: TextStyle(
                              fontWeight: widget.notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_workInvite!.role} • ${DateFormat('dd/MM/yyyy').format(_workInvite!.date)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    if (!widget.notification.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                
                // Contenido expandible
                if (_isExpanded) ...[
                  const Divider(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoColumn(
                          Icons.church,
                          _workInvite!.entityType == 'cult' ? 'Culto' : 'Evento',
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
                  
                  const SizedBox(height: 8),
                  
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
                  
                  // Botones de acción si está pendiente
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _rejectSchedule,
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(AppLocalizations.of(context)!.reject),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _acceptSchedule,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(AppLocalizations.of(context)!.accept),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackNotification() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: widget.notification.getColor().withOpacity(0.2),
        child: Icon(
          widget.notification.getIcon(),
          color: widget.notification.getColor(),
          size: 20,
        ),
      ),
      title: Text(_translateNotificationText(widget.notification.title)),
      subtitle: Text(_translateNotificationText(widget.notification.message)),
      onTap: () async {
        if (!widget.notification.isRead) {
          await widget.notificationService.markAsRead(widget.notification.id);
        }
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationDetailScreen(notification: widget.notification),
            ),
          );
        }
      },
    );
  }

  Future<void> _acceptSchedule() async {
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

    if (confirm != true || _workInvite == null) return;

    try {
      await _workScheduleService.updateAssignmentStatus(_workInvite!.id, 'accepted');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scheduleAcceptedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar el work invite
        await _loadWorkInvite();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorAcceptingSchedule}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectSchedule() async {
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

    if (confirm != true || _workInvite == null) return;

    try {
      await _workScheduleService.updateAssignmentStatus(_workInvite!.id, 'rejected');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.scheduleRejectedSuccessfully),
            backgroundColor: Colors.orange,
          ),
        );
        // Recargar el work invite
        await _loadWorkInvite();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorRejectingSchedule}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}