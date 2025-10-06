import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'calendar_events_view.dart';
import 'calendar_ministries_view.dart';
import 'calendar_groups_view.dart';
import 'calendar_cults_view.dart';
import 'calendar_services_view.dart';
import 'calendar_counseling_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ministry_event.dart';
import '../../models/group_event.dart';
import '../../models/event_model.dart';
import '../../models/cult.dart';
import '../../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../main.dart' as main_app;
import '../../cubits/navigation_cubit.dart';
import '../../widgets/skeletons/calendar_screen_skeleton.dart';
import '../../l10n/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Mapa para almacenar los eventos por día
  Map<DateTime, List<dynamic>> _allEvents = {};
  Map<DateTime, List<dynamic>> _ministryEvents = {};
  Map<DateTime, List<dynamic>> _groupEvents = {};
  Map<DateTime, List<dynamic>> _cultEvents = {};
  Map<DateTime, List<dynamic>> _serviceEvents = {};
  Map<DateTime, List<dynamic>> _counselingEvents = {};
  
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _selectedDay = _focusedDay;
    _loadAllEvents();
    
    // Listener para cambiar eventos cuando cambia la pestaña
    _tabController.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Cargar todos los eventos de todas las categorías
  Future<void> _loadAllEvents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Future.wait([
        _loadEvents(),
        _loadMinistryEvents(),
        _loadGroupEvents(),
        _loadCultEvents(),
        _loadServiceEvents(),
        _loadCounselingEvents(),
      ]);
    } catch (e) {
      debugPrint(AppLocalizations.of(context)!.errorLoadingEvents(e.toString()));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Cargar eventos generales
  Future<void> _loadEvents() async {
    final Map<DateTime, List<dynamic>> events = {};
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('isActive', isEqualTo: true)
          .get();
          
      for (var doc in snapshot.docs) {
        try {
          final event = EventModel.fromFirestore(doc);
          final day = DateTime(
            event.startDate.year,
            event.startDate.month,
            event.startDate.day,
          );
          
          if (events[day] != null) {
            events[day]!.add(event);
          } else {
            events[day] = [event];
          }
        } catch (e) {
          debugPrint('Erro ao processar evento: $e');
        }
      }
      
      setState(() {
        _allEvents = events;
      });
    } catch (e) {
      debugPrint('Erro ao carregar eventos: $e');
    }
  }
  
  // Cargar eventos de ministerios
  Future<void> _loadMinistryEvents() async {
    final Map<DateTime, List<dynamic>> events = {};
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ministry_events')
          // .where('isActive', isEqualTo: true) // <--- Línea eliminada/comentada
          .get();
          
      debugPrint('Encontrados ${snapshot.docs.length} eventos de ministério na coleção (todos, sin filtro isActive)');
      
      for (var doc in snapshot.docs) {
        try {
          // Loguear datos crudos para debugging
          final rawData = doc.data();
          debugPrint('Processando ministryEvent: ${doc.id}');
          debugPrint('  Title: ${rawData['title']}');
          debugPrint('  ministryId: ${rawData['ministryId']}');
          
          // Usar constructor fromMap o extraer manualmente los campos si hay problemas
          final event = MinistryEvent.fromFirestore(doc);
          debugPrint('  Evento processado com sucesso: ${event.title}');
          
          // Normalizar la fecha
          final day = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          
          if (events[day] != null) {
            events[day]!.add(event);
          } else {
            events[day] = [event];
          }
        } catch (e) {
          debugPrint('Erro ao processar evento de ministério: $e');
          // Añadir más detalles para diagnosticar mejor
          debugPrint('  ID do documento: ${doc.id}');
          debugPrint('  Dados brutos: ${doc.data()}');
        }
      }
      
      setState(() {
        _ministryEvents = events;
      });
      
      // Mostrar días que tienen eventos
      if (events.isNotEmpty) {
        debugPrint('Dias com eventos de ministérios:');
        for (final day in events.keys) {
          debugPrint('${day.day}/${day.month}/${day.year}: ${events[day]!.length} evento(s)');
        }
      } else {
        debugPrint('Não foram encontrados eventos de ministérios');
      }
    } catch (e) {
      debugPrint('Erro ao carregar eventos de ministérios: $e');
    }
  }
  
  // Cargar eventos de grupos
  Future<void> _loadGroupEvents() async {
    final Map<DateTime, List<dynamic>> events = {};
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('group_events')
          // .where('isActive', isEqualTo: true) // <--- Línea eliminada/comentada
          .get();
          
      debugPrint('Encontrados ${snapshot.docs.length} eventos de grupo na coleção (todos, sin filtro isActive)');
      
      for (var doc in snapshot.docs) {
        try {
          // Loguear datos crudos para debugging
          final rawData = doc.data();
          debugPrint('Processando groupEvent: ${doc.id}');
          debugPrint('  Title: ${rawData['title']}');
          debugPrint('  groupId: ${rawData['groupId']}');
          
          // Usar constructor fromMap o extraer manualmente los campos si hay problemas
          final event = GroupEvent.fromFirestore(doc);
          debugPrint('  Evento processado com sucesso: ${event.title}');
          
          // Normalizar la fecha
          final day = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          
          if (events[day] != null) {
            events[day]!.add(event);
          } else {
            events[day] = [event];
          }
        } catch (e) {
          debugPrint('Erro ao processar evento de grupo: $e');
          // Añadir más detalles para diagnosticar mejor
          debugPrint('  ID do documento: ${doc.id}');
          debugPrint('  Dados brutos: ${doc.data()}');
        }
      }
      
      setState(() {
        _groupEvents = events;
      });
      
      // Mostrar días que tienen eventos
      if (events.isNotEmpty) {
        debugPrint('Dias com eventos de grupos:');
        for (final day in events.keys) {
          debugPrint('${day.day}/${day.month}/${day.year}: ${events[day]!.length} evento(s)');
        }
      } else {
        debugPrint('Não foram encontrados eventos de grupos');
      }
    } catch (e) {
      debugPrint('Erro ao carregar eventos de grupos: $e');
    }
  }
  
  // Cargar cultos
  Future<void> _loadCultEvents() async {
    final Map<DateTime, List<dynamic>> events = {};
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cults')
          .get();
          
      for (var doc in snapshot.docs) {
        try {
          final cult = Cult.fromFirestore(doc);
          final day = DateTime(
            cult.date.year,
            cult.date.month,
            cult.date.day,
          );
          
          if (events[day] != null) {
            events[day]!.add(cult);
          } else {
            events[day] = [cult];
          }
        } catch (e) {
          debugPrint('Erro ao processar culto: $e');
        }
      }
      
      setState(() {
        _cultEvents = events;
      });
    } catch (e) {
      debugPrint('Erro ao carregar cultos: $e');
    }
  }
  
  // Cargar servicios asignados
  Future<void> _loadServiceEvents() async {
    final Map<DateTime, List<dynamic>> events = {};
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Crear referencia al documento del usuario
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      // Obtener asignaciones de trabajo aceptadas por el usuario
      final assignmentsSnapshot = await FirebaseFirestore.instance
          .collection('work_assignments')
          .where('userId', isEqualTo: userRef)
          .where('status', isEqualTo: 'accepted')
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Encontradas ${assignmentsSnapshot.docs.length} atribuições para calendário de serviços');
      
      // Para cada asignación, obtener la franja horaria correspondiente
      for (final doc in assignmentsSnapshot.docs) {
        try {
          final assignmentData = doc.data();
          final timeSlotId = assignmentData['timeSlotId'] as String? ?? '';
          
          if (timeSlotId.isEmpty) continue;
          
          final timeSlotDoc = await FirebaseFirestore.instance
              .collection('time_slots')
              .doc(timeSlotId)
              .get();
          
          if (!timeSlotDoc.exists) continue;
          
          final timeSlotData = timeSlotDoc.data()!;
          
          // Solo procesar franjas horarias relacionadas con cultos
          final entityType = timeSlotData['entityType'] as String? ?? '';
          if (entityType != 'cult') continue;
          
          // Verificar si existe startTime
          if (timeSlotData['startTime'] == null) continue;
          
          final startTime = (timeSlotData['startTime'] as Timestamp).toDate();
          
          // Normalizar la fecha (usar solo día, mes, año)
          final normalizedDate = DateTime(
            startTime.year,
            startTime.month,
            startTime.day,
          );
          
          // Crear un objeto con información simplificada
          final serviceInfo = {
            'id': doc.id,
            'timeSlotId': timeSlotId,
            'startTime': startTime,
            'role': assignmentData['role'] ?? 'Sem função',
          };
          
          // Guardar la información en el mapa
          if (events[normalizedDate] != null) {
            events[normalizedDate]!.add(serviceInfo);
          } else {
            events[normalizedDate] = [serviceInfo];
          }
        } catch (e) {
          debugPrint('Erro ao processar atribuição de trabalho: $e');
        }
      }
      
      setState(() {
        _serviceEvents = events;
      });
      
      // Solo para depuración
      if (events.isNotEmpty) {
        debugPrint('Dias com serviços:');
        for (final day in events.keys) {
          debugPrint('${day.day}/${day.month}/${day.year}: ${events[day]!.length} serviço(s)');
        }
      } else {
        debugPrint('Não foram encontrados dias com serviços');
      }
    } catch (e) {
      debugPrint('Erro ao carregar serviços: $e');
    }
  }
  
  // Cargar citas de aconsejamiento
  Future<void> _loadCounselingEvents() async {
    final Map<DateTime, List<dynamic>> events = {};
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Referência ao documento do usuário
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      // Verificar se o usuário é pastor
      final userDoc = await userRef.get();
      final userData = userDoc.data();
      final isUserPastor = userData?['role'] == 'pastor';
      
      QuerySnapshot appointmentsSnapshot;
      
      if (isUserPastor) {
        // Se for pastor, buscar consultas onde ele é o pastor e estão confirmadas
        appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('pastorId', isEqualTo: userRef)
            .where('status', isEqualTo: 'confirmed')
            .get();
      } else {
        // Se for membro regular, buscar consultas onde ele é o usuário e estão confirmadas
        appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('userId', isEqualTo: userRef)
            .where('status', isEqualTo: 'confirmed')
            .get();
      }
      
      debugPrint('Encontradas ${appointmentsSnapshot.docs.length} consultas de aconselhamento para calendário');
      
      for (final doc in appointmentsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          
          // Normalizar a data
          final day = DateTime(
            date.year,
            date.month,
            date.day,
          );
          
          // Criar um objeto simplificado para o calendário
          final appointmentInfo = {
            'id': doc.id,
            'date': date,
            'type': data['type'] ?? 'online',
            'isUserPastor': isUserPastor,
          };
          
          if (events[day] != null) {
            events[day]!.add(appointmentInfo);
          } else {
            events[day] = [appointmentInfo];
          }
        } catch (e) {
          debugPrint('Erro ao processar consulta de aconselhamento: $e');
        }
      }
      
      setState(() {
        _counselingEvents = events;
      });
      
      // Apenas para depuração
      if (events.isNotEmpty) {
        debugPrint('Dias com consultas de aconselhamento:');
        for (final day in events.keys) {
          debugPrint('${day.day}/${day.month}/${day.year}: ${events[day]!.length} consulta(s)');
        }
      } else {
        debugPrint('Não foram encontradas consultas de aconselhamento');
      }
    } catch (e) {
      debugPrint('Erro ao carregar consultas de aconselhamento: $e');
    }
  }
  
  // Obtener los eventos según la pestaña actual
  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    List<dynamic> events = [];
    final currentTabIndex = _tabController.index;

    String tabName = ''; // Para el debug print

    switch (currentTabIndex) {
      case 0:
        tabName = AppLocalizations.of(context)!.events;
        events = _allEvents[normalizedDay] ?? [];
        break;
      case 1:
        tabName = AppLocalizations.of(context)!.ministries;
        events = _ministryEvents[normalizedDay] ?? [];
        break;
      case 2:
        tabName = AppLocalizations.of(context)!.groups;
        events = _groupEvents[normalizedDay] ?? [];
        break;
      case 3:
        tabName = AppLocalizations.of(context)!.cultsTab;
        events = _cultEvents[normalizedDay] ?? [];
        break;
      case 4:
        tabName = AppLocalizations.of(context)!.services;
        events = _serviceEvents[normalizedDay] ?? [];
        break;
      case 5:
        tabName = AppLocalizations.of(context)!.counseling;
        events = _counselingEvents[normalizedDay] ?? [];
        break;
      default:
        events = [];
    }

    // --- Debug Print Detallado ---
    if (currentTabIndex == 1 || currentTabIndex == 2 || currentTabIndex == 5) {
      final mapToCheck = currentTabIndex == 1 
          ? _ministryEvents 
          : (currentTabIndex == 2 ? _groupEvents : _counselingEvents);
      bool foundInMap = mapToCheck.containsKey(normalizedDay);
      int countInMap = foundInMap ? mapToCheck[normalizedDay]!.length : 0;
      int countReturned = events.length;

      debugPrint('[$tabName] _getEventsForDay(${normalizedDay.toIso8601String().substring(0, 10)}): '
                  'Map has key? $foundInMap ($countInMap events). Returning list with $countReturned events.');
    }
    // --- Fin Debug Print ---

    return events;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: CalendarScreenSkeleton());
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              main_app.navigationCubit.navigateTo(NavigationState.home);
                            },
                          ),
                          Text(
                            AppLocalizations.of(context)!.calendars,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
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
              child: RefreshIndicator(
                onRefresh: _loadAllEvents,
                child: _buildTabViews(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalendarWithEvents(Widget eventsView) {
    return Column(
      children: [
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Calendario que ahora se desplaza con el scroll
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
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
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(fontWeight: FontWeight.bold),
                              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
                              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
                            ),
                            calendarFormat: CalendarFormat.month,
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: _getMarkerColor(_tabController.index),
                                shape: BoxShape.circle,
                              ),
                              markersMaxCount: 3,
                              weekendTextStyle: const TextStyle(color: Colors.red),
                            ),
                            locale: Localizations.localeOf(context).toString(),
                            // Función para cargar eventos según el día
                            eventLoader: _getEventsForDay,
                            // Personalización del marcador de eventos
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isEmpty) return null;
                                
                                final currentTab = _tabController.index;
                                final color = _getMarkerColor(currentTab);
                                
                                return Positioned(
                                  bottom: 1,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      // Fecha seleccionada
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDay != null 
                                ? DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).toString()).format(_selectedDay!)
                                : DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).toString()).format(_focusedDay),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            // Vista de eventos para el día seleccionado
            body: eventsView,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      padding: const EdgeInsets.only(left: 6),
      indicatorPadding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      tabAlignment: TabAlignment.start,
      tabs: [
        Tab(text: AppLocalizations.of(context)!.events),
        Tab(text: AppLocalizations.of(context)!.ministries),
        Tab(text: AppLocalizations.of(context)!.groups),
        Tab(text: AppLocalizations.of(context)!.cultsTab),
        Tab(text: AppLocalizations.of(context)!.services),
        Tab(text: AppLocalizations.of(context)!.counseling),
      ],
    );
  }

  Widget _buildTabViews() {
    // Obtener la fecha seleccionada o enfocada
    final dateForView = _selectedDay ?? _focusedDay;

    // Obtener las listas de eventos para la fecha actual según la pestaña
    // Nota: _getEventsForDay ya filtra internamente por la pestaña actual
    final eventsForDay = _getEventsForDay(dateForView);
    
    // Asegurar el tipo correcto para cada vista
    final ministryEventsForDay = eventsForDay.whereType<MinistryEvent>().toList();
    final groupEventsForDay = eventsForDay.whereType<GroupEvent>().toList();
    
    // NOTA: Las otras vistas (Events, Cults, Services, Counseling) usan enfoques diferentes
    // y no necesitan este cambio por ahora.
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCalendarWithEvents(CalendarEventsView(selectedDate: dateForView)), // Sin cambios necesarios
        _buildCalendarWithEvents(CalendarMinistriesView(events: ministryEventsForDay, selectedDate: dateForView)), // Pasar lista filtrada
        _buildCalendarWithEvents(CalendarGroupsView(events: groupEventsForDay, selectedDate: dateForView)),       // Pasar lista filtrada
        _buildCalendarWithEvents(CalendarCultsView(selectedDate: dateForView)),       // Sin cambios necesarios
        _buildCalendarWithEvents(CalendarServicesView(selectedDate: dateForView)),     // Sin cambios necesarios
        _buildCalendarWithEvents(CalendarCounselingView(selectedDate: dateForView)),   // Sin cambios necesarios
      ],
    );
  }
  
  // Obtener un color para los marcadores según la pestaña seleccionada
  Color _getMarkerColor(int tabIndex) {
    switch (tabIndex) {
      case 0: // Eventos
        return Colors.red;
      case 1: // Ministerios
        return AppColors.primary;
      case 2: // Grupos
        return Colors.green;
      case 3: // Cultos
        return Colors.purple;
      case 4: // Servicios
        return AppColors.primary;
      case 5: // Aconselhamento
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
} 