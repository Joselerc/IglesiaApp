import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/ministry_event.dart';
import '../../models/group_event.dart';
import '../../models/cult.dart';
import '../../models/work_assignment.dart';
import '../../models/time_slot.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class CalendarGlobalView extends StatefulWidget {
  final DateTime selectedDate;
  
  const CalendarGlobalView({
    super.key,
    required this.selectedDate,
  });

  @override
  State<CalendarGlobalView> createState() => _CalendarGlobalViewState();
}

class _CalendarGlobalViewState extends State<CalendarGlobalView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allActivities = [];

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }
  
  @override
  void didUpdateWidget(CalendarGlobalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadAllActivities();
    }
  }

  Future<void> _loadAllActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final selectedDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
      final nextDay = selectedDay.add(const Duration(days: 1));
      
      final activities = <Map<String, dynamic>>[];
      
      // Cargar eventos generales
      await _loadEvents(activities, selectedDay);
      
      // Cargar eventos de ministerios
      await _loadMinistryEvents(activities, selectedDay);
      
      // Cargar eventos de grupos
      await _loadGroupEvents(activities, selectedDay);
      
      // Cargar cultos
      await _loadCults(activities, selectedDay);
      
      // Cargar servicios asignados
      await _loadServices(activities, selectedDay, nextDay);
      
      // Cargar citas de aconsejamiento
      await _loadCounseling(activities, selectedDay, nextDay);
      
      // Ordenar por hora
      activities.sort((a, b) {
        final timeA = a['time'] as DateTime;
        final timeB = b['time'] as DateTime;
        return timeA.compareTo(timeB);
      });
      
      setState(() {
        _allActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar actividades: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEvents(List<Map<String, dynamic>> activities, DateTime selectedDay) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (var doc in snapshot.docs) {
        try {
          final event = EventModel.fromFirestore(doc);
          if (event.startDate.year == selectedDay.year &&
              event.startDate.month == selectedDay.month &&
              event.startDate.day == selectedDay.day) {
            activities.add({
              'type': 'event',
              'title': event.title,
              'time': event.startDate,
              'icon': Icons.event,
              'color': Colors.red,
              'data': event,
            });
          }
        } catch (e) {
          debugPrint('Error al procesar evento: $e');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar eventos: $e');
    }
  }

  Future<void> _loadMinistryEvents(List<Map<String, dynamic>> activities, DateTime selectedDay) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ministry_events')
          .get();
      
      for (var doc in snapshot.docs) {
        try {
          final event = MinistryEvent.fromFirestore(doc);
          if (event.date.year == selectedDay.year &&
              event.date.month == selectedDay.month &&
              event.date.day == selectedDay.day) {
            
            // Obtener nombre del ministerio
            String ministryName = 'Ministério';
            try {
              final ministryDoc = await event.ministryId.get();
              if (ministryDoc.exists) {
                ministryName = (ministryDoc.data() as Map<String, dynamic>)['name'] ?? 'Ministério';
              }
            } catch (e) {
              debugPrint('Error al obtener ministerio: $e');
            }
            
            activities.add({
              'type': 'ministry',
              'title': event.title,
              'subtitle': ministryName,
              'time': event.date,
              'icon': Icons.groups,
              'color': AppColors.primary,
              'data': event,
            });
          }
        } catch (e) {
          debugPrint('Error al procesar evento de ministerio: $e');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar eventos de ministerios: $e');
    }
  }

  Future<void> _loadGroupEvents(List<Map<String, dynamic>> activities, DateTime selectedDay) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('group_events')
          .get();
      
      for (var doc in snapshot.docs) {
        try {
          final event = GroupEvent.fromFirestore(doc);
          if (event.date.year == selectedDay.year &&
              event.date.month == selectedDay.month &&
              event.date.day == selectedDay.day) {
            
            // Obtener nombre del grupo
            String groupName = 'Grupo';
            try {
              final groupDoc = await event.groupId.get();
              if (groupDoc.exists) {
                groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'Grupo';
              }
            } catch (e) {
              debugPrint('Error al obtener grupo: $e');
            }
            
            activities.add({
              'type': 'group',
              'title': event.title,
              'subtitle': groupName,
              'time': event.date,
              'icon': Icons.people,
              'color': Colors.green,
              'data': event,
            });
          }
        } catch (e) {
          debugPrint('Error al procesar evento de grupo: $e');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar eventos de grupos: $e');
    }
  }

  Future<void> _loadCults(List<Map<String, dynamic>> activities, DateTime selectedDay) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cults')
          .get();
      
      for (var doc in snapshot.docs) {
        try {
          final cult = Cult.fromFirestore(doc);
          if (cult.date.year == selectedDay.year &&
              cult.date.month == selectedDay.month &&
              cult.date.day == selectedDay.day) {
            activities.add({
              'type': 'cult',
              'title': cult.name,
              'subtitle': '${DateFormat('HH:mm').format(cult.startTime)} - ${DateFormat('HH:mm').format(cult.endTime)}',
              'time': cult.startTime,
              'icon': Icons.church,
              'color': Colors.purple,
              'data': cult,
            });
          }
        } catch (e) {
          debugPrint('Error al procesar culto: $e');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar cultos: $e');
    }
  }

  Future<void> _loadServices(List<Map<String, dynamic>> activities, DateTime selectedDay, DateTime nextDay) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      // Obtener time slots del día
      final timeSlotSnapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('entityType', isEqualTo: 'cult')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDay))
          .where('startTime', isLessThan: Timestamp.fromDate(nextDay))
          .get();
      
      for (final timeSlotDoc in timeSlotSnapshot.docs) {
        final timeSlotId = timeSlotDoc.id;
        
        // Buscar asignaciones aceptadas para este time slot
        final assignmentSnapshot = await FirebaseFirestore.instance
            .collection('work_assignments')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('userId', isEqualTo: userRef)
            .where('status', isEqualTo: 'accepted')
            .where('isActive', isEqualTo: true)
            .get();
        
        for (final assignmentDoc in assignmentSnapshot.docs) {
          try {
            final assignment = WorkAssignment.fromFirestore(assignmentDoc);
            final timeSlot = TimeSlot.fromFirestore(timeSlotDoc);
            
            // Obtener nombre del culto
            String cultName = 'Culto';
            try {
              final cultDoc = await FirebaseFirestore.instance
                  .collection('cults')
                  .doc(timeSlot.entityId)
                  .get();
              if (cultDoc.exists) {
                cultName = cultDoc.data()?['name'] ?? 'Culto';
              }
            } catch (e) {
              debugPrint('Error al obtener culto: $e');
            }
            
            activities.add({
              'type': 'service',
              'title': 'Serviço: ${assignment.role}',
              'subtitle': cultName,
              'time': timeSlot.startTime,
              'icon': Icons.work,
              'color': AppColors.primary,
              'data': {'assignment': assignment, 'timeSlot': timeSlot},
            });
          } catch (e) {
            debugPrint('Error al procesar asignación: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error al cargar servicios: $e');
    }
  }

  Future<void> _loadCounseling(List<Map<String, dynamic>> activities, DateTime selectedDay, DateTime nextDay) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      // Verificar si es pastor
      final userDoc = await userRef.get();
      final userData = userDoc.data();
      final isUserPastor = userData?['role'] == 'pastor';
      
      QuerySnapshot appointmentsSnapshot;
      
      if (isUserPastor) {
        appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('pastorId', isEqualTo: userRef)
            .where('status', isEqualTo: 'confirmed')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDay))
            .where('date', isLessThan: Timestamp.fromDate(nextDay))
            .get();
      } else {
        appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('userId', isEqualTo: userRef)
            .where('status', isEqualTo: 'confirmed')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDay))
            .where('date', isLessThan: Timestamp.fromDate(nextDay))
            .get();
      }
      
      for (final doc in appointmentsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          final type = data['type'] as String? ?? 'online';
          
          // Obtener nombre de la otra persona
          final otherPersonRef = isUserPastor 
              ? data['userId'] as DocumentReference
              : data['pastorId'] as DocumentReference;
          
          String otherPersonName = 'Sem nome';
          try {
            final otherPersonDoc = await otherPersonRef.get();
            final otherPersonData = otherPersonDoc.data() as Map<String, dynamic>?;
            otherPersonName = otherPersonData?['name'] as String? ?? 'Sem nome';
          } catch (e) {
            debugPrint('Error al obtener persona: $e');
          }
          
          final title = isUserPastor 
              ? 'Aconselhamento com $otherPersonName'
              : 'Aconselhamento com Pastor $otherPersonName';
          
          activities.add({
            'type': 'counseling',
            'title': title,
            'subtitle': type == 'online' ? 'Online' : 'Presencial',
            'time': date,
            'icon': type == 'online' ? Icons.video_call : Icons.person,
            'color': Colors.blue,
            'data': data,
          });
        } catch (e) {
          debugPrint('Error al procesar cita de aconsejamiento: $e');
        }
      }
    } catch (e) {
      debugPrint('Error al cargar citas de aconsejamiento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_allActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noActivitiesForThisDay,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allActivities.length,
      itemBuilder: (context, index) {
        final activity = _allActivities[index];
        return _buildActivityCard(context, activity);
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final title = activity['title'] as String;
    final subtitle = activity['subtitle'] as String?;
    final time = activity['time'] as DateTime;
    final icon = activity['icon'] as IconData;
    final color = activity['color'] as Color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _handleActivityTap(context, activity),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono con color de categoría
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información de la actividad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm').format(time),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Chip de categoría
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCategoryLabel(type, context),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String type, BuildContext context) {
    switch (type) {
      case 'event':
        return AppLocalizations.of(context)!.events;
      case 'ministry':
        return AppLocalizations.of(context)!.ministries;
      case 'group':
        return AppLocalizations.of(context)!.groups;
      case 'cult':
        return AppLocalizations.of(context)!.cultsTab;
      case 'service':
        return AppLocalizations.of(context)!.services;
      case 'counseling':
        return AppLocalizations.of(context)!.counseling;
      default:
        return type;
    }
  }

  void _handleActivityTap(BuildContext context, Map<String, dynamic> activity) {
    final type = activity['type'] as String;
    final data = activity['data'];
    
    switch (type) {
      case 'event':
        final event = data as EventModel;
        Navigator.pushNamed(context, '/events/${event.id}');
        break;
      case 'ministry':
        final event = data as MinistryEvent;
        Navigator.pushNamed(
          context,
          '/ministries/${event.ministryId.id}/events/${event.id}',
        );
        break;
      case 'group':
        final event = data as GroupEvent;
        Navigator.pushNamed(
          context,
          '/groups/${event.groupId.id}/events/${event.id}',
        );
        break;
      case 'cult':
        // Mostrar detalles del culto en un diálogo o navegar
        break;
      case 'service':
        // Mostrar detalles del servicio
        break;
      case 'counseling':
        Navigator.pushNamed(context, '/counseling');
        break;
    }
  }
}

