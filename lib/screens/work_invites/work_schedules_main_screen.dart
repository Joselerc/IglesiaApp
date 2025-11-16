import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/work_invite.dart';
import '../../services/work_schedule_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import './work_invite_detail_screen.dart';

class WorkSchedulesMainScreen extends StatefulWidget {
  const WorkSchedulesMainScreen({super.key});

  @override
  State<WorkSchedulesMainScreen> createState() => _WorkSchedulesMainScreenState();
}

class _WorkSchedulesMainScreenState extends State<WorkSchedulesMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final WorkScheduleService _workScheduleService = WorkScheduleService();
  
  // Mapas para almacenar eventos por día
  Map<DateTime, List<WorkInvite>> _allInvites = {};
  Map<DateTime, List<WorkInvite>> _pendingInvites = {};
  Map<DateTime, List<WorkInvite>> _acceptedInvites = {};
  Map<DateTime, List<WorkInvite>> _rejectedInvites = {};
  
  bool _isLoading = true;
  String _currentView = 'list'; // 'list' o 'calendar'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _selectedDay = _focusedDay;
    _loadInvites();
    
    // Listener para actualizar los tabs cuando cambie la pestaña
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Obtener todas las invitaciones
      final invitesSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(userId))
          .get();

      // Limpiar mapas
      _allInvites.clear();
      _pendingInvites.clear();
      _acceptedInvites.clear();
      _rejectedInvites.clear();

      for (var doc in invitesSnapshot.docs) {
        final invite = WorkInvite.fromFirestore(doc);
        final date = _normalizeDate(invite.date);

        // Agregar a todas las invitaciones
        if (!_allInvites.containsKey(date)) {
          _allInvites[date] = [];
        }
        _allInvites[date]!.add(invite);

        // Agregar a los mapas específicos según el estado
        switch (invite.status) {
          case 'pending':
            if (!_pendingInvites.containsKey(date)) {
              _pendingInvites[date] = [];
            }
            _pendingInvites[date]!.add(invite);
            break;
          case 'accepted':
          case 'confirmed':
          case 'seen':
            if (!_acceptedInvites.containsKey(date)) {
              _acceptedInvites[date] = [];
            }
            _acceptedInvites[date]!.add(invite);
            break;
          case 'rejected':
          case 'declined':
            if (!_rejectedInvites.containsKey(date)) {
              _rejectedInvites[date] = [];
            }
            _rejectedInvites[date]!.add(invite);
            break;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando invitaciones: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _getCurrentTabTitle() {
    if (!mounted) return '';
    
    switch (_tabController.index) {
      case 0:
        return AppLocalizations.of(context)!.allSchedules;
      case 1:
        return AppLocalizations.of(context)!.pendingSchedules;
      case 2:
        return AppLocalizations.of(context)!.acceptedSchedules;
      case 3:
        return AppLocalizations.of(context)!.rejectedSchedules;
      default:
        return AppLocalizations.of(context)!.myWorkSchedules;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            // AppBar personalizada con gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            _getCurrentTabTitle(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _currentView == 'list' ? Icons.calendar_month : Icons.list,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentView = _currentView == 'list' ? 'calendar' : 'list';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    _buildTabs(),
                  ],
                ),
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentView == 'list'
                      ? _buildListView()
                      : _buildCalendarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final currentIndex = _tabController.index;
    final allTabs = [
      AppLocalizations.of(context)!.allSchedules,
      AppLocalizations.of(context)!.pendingSchedules,
      AppLocalizations.of(context)!.acceptedSchedules,
      AppLocalizations.of(context)!.rejectedSchedules,
    ];
    
    // Contar invitaciones pendientes
    int pendingCount = 0;
    _pendingInvites.forEach((date, invites) {
      pendingCount += invites.length;
    });
    
    // Crear lista de pestañas excluyendo la actual (igual que calendario)
    final visibleTabs = <Widget>[];
    for (int i = 0; i < allTabs.length; i++) {
      if (i != currentIndex) {
        visibleTabs.add(Tab(text: allTabs[i]));
      }
    }
    
    // Si solo hay 1 pestaña visible o menos, no mostrar el TabBar
    if (visibleTabs.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        itemCount: allTabs.length - 1,
        itemBuilder: (context, index) {
          int tabIndex = index;
          if (index >= currentIndex) {
            tabIndex = index + 1;
          }
          
          // Verificar si esta pestaña es "Pendientes" y tiene elementos
          bool isPendingTab = tabIndex == 1;
          bool showBadge = isPendingTab && pendingCount > 0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                _tabController.animateTo(tabIndex);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        allTabs[tabIndex],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadInvites,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInvitesList(_getInvitesForTab(0)),
          _buildInvitesList(_getInvitesForTab(1)),
          _buildInvitesList(_getInvitesForTab(2)),
          _buildInvitesList(_getInvitesForTab(3)),
        ],
      ),
    );
  }

  List<WorkInvite> _getInvitesForTab(int tabIndex) {
    Map<DateTime, List<WorkInvite>> currentMap;
    
    switch (tabIndex) {
      case 0:
        currentMap = _allInvites;
        break;
      case 1:
        currentMap = _pendingInvites;
        break;
      case 2:
        currentMap = _acceptedInvites;
        break;
      case 3:
        currentMap = _rejectedInvites;
        break;
      default:
        currentMap = _allInvites;
    }

    List<WorkInvite> allInvites = [];
    currentMap.forEach((date, invites) {
      allInvites.addAll(invites);
    });
    
    allInvites.sort((a, b) => a.date.compareTo(b.date));
    return allInvites;
  }

  Widget _buildInvitesList(List<WorkInvite> invites) {
    if (invites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invites.length,
      itemBuilder: (context, index) {
        return _buildInviteCard(invites[index]);
      },
    );
  }

  String _getEmptyMessage() {
    switch (_tabController.index) {
      case 1:
        return AppLocalizations.of(context)!.noPendingSchedules;
      case 2:
        return AppLocalizations.of(context)!.noAcceptedSchedules;
      case 3:
        return AppLocalizations.of(context)!.noRejectedSchedules;
      default:
        return AppLocalizations.of(context)!.noSchedulesFound;
    }
  }

  Widget _buildInviteCard(WorkInvite invite) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final isPast = invite.date.isBefore(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPast ? Colors.grey.shade300 : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (invite.status == 'pending' && !invite.isRead) {
            _workScheduleService.markInviteAsRead(invite.id);
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkInviteDetailScreen(invite: invite),
            ),
          ).then((_) => _loadInvites());
        },
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isPast ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                invite.entityType == 'cult' ? Icons.church : Icons.event,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                invite.entityType == 'cult' ? 'Culto' : 'Evento',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invite.entityName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(invite.status),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Detalles
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.event,
                            dateFormat.format(invite.date),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.access_time,
                            '${timeFormat.format(invite.startTime)} - ${timeFormat.format(invite.endTime)}',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.work_outline,
                            invite.ministryName,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.person_outline,
                            invite.role,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Botones de acción para invitaciones pendientes
                if (invite.status == 'pending' && !isPast)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showRejectConfirmation(invite),
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(AppLocalizations.of(context)!.reject),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAcceptConfirmation(invite),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(AppLocalizations.of(context)!.accept),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyText2.copyWith(
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'accepted':
      case 'confirmed':
        color = Colors.green;
        label = AppLocalizations.of(context)!.acceptedStatus;
        break;
      case 'rejected':
      case 'declined':
        color = Colors.red;
        label = AppLocalizations.of(context)!.rejectedStatus;
        break;
      case 'seen':
        color = Colors.orange;
        label = AppLocalizations.of(context)!.seenStatus;
        break;
      case 'pending':
      default:
        color = Colors.amber;
        label = AppLocalizations.of(context)!.pendingStatus;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Calendario
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              final normalizedDay = _normalizeDate(day);
              Map<DateTime, List<WorkInvite>> currentMap;
              
              switch (_tabController.index) {
                case 0:
                  currentMap = _allInvites;
                  break;
                case 1:
                  currentMap = _pendingInvites;
                  break;
                case 2:
                  currentMap = _acceptedInvites;
                  break;
                case 3:
                  currentMap = _rejectedInvites;
                  break;
                default:
                  currentMap = _allInvites;
              }
              
              return currentMap[normalizedDay] ?? [];
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
            ),
            calendarFormat: CalendarFormat.month,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
          ),
        ),
        
        // Lista de eventos del día seleccionado
        Expanded(
          child: _buildSelectedDayInvites(),
        ),
      ],
    );
  }

  Widget _buildSelectedDayInvites() {
    final normalizedDay = _normalizeDate(_selectedDay ?? _focusedDay);
    
    Map<DateTime, List<WorkInvite>> currentMap;
    switch (_tabController.index) {
      case 0:
        currentMap = _allInvites;
        break;
      case 1:
        currentMap = _pendingInvites;
        break;
      case 2:
        currentMap = _acceptedInvites;
        break;
      case 3:
        currentMap = _rejectedInvites;
        break;
      default:
        currentMap = _allInvites;
    }

    final dayInvites = currentMap[normalizedDay] ?? [];

    if (dayInvites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noActivitiesForThisDay,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayInvites.length,
      itemBuilder: (context, index) {
        return _buildInviteCard(dayInvites[index]);
      },
    );
  }

  Future<void> _showAcceptConfirmation(WorkInvite invite) async {
    final confirmed = await showDialog<bool>(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _respondToInvite(invite.id, 'accepted');
    }
  }

  Future<void> _showRejectConfirmation(WorkInvite invite) async {
    final confirmed = await showDialog<bool>(
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
            ),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _respondToInvite(invite.id, 'rejected');
    }
  }

  Future<void> _respondToInvite(String inviteId, String status) async {
    try {
      await _workScheduleService.respondToInvite(inviteId, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? AppLocalizations.of(context)!.scheduleAcceptedSuccessfully
                  : AppLocalizations.of(context)!.scheduleRejectedSuccessfully,
            ),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Recargar invitaciones
        await _loadInvites();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? AppLocalizations.of(context)!.errorAcceptingSchedule
                  : AppLocalizations.of(context)!.errorRejectingSchedule,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

