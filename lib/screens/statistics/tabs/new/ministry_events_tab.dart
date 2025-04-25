import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../models/ministry.dart';
import '../../../../theme/app_colors.dart';

class MinistryEventsTab extends StatefulWidget {
  final List<Ministry> ministries;

  const MinistryEventsTab({
    Key? key,
    required this.ministries,
  }) : super(key: key);

  @override
  State<MinistryEventsTab> createState() => _MinistryEventsTabState();
}

class _MinistryEventsTabState extends State<MinistryEventsTab> {
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _ministryStats = {};
  Map<String, List<Map<String, dynamic>>> _ministryEvents = {};
  
  // Variables para el filtro de fecha
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _filteredByDateEvents = [];
  bool _isDateFilterActive = false;
  
  // Variables para controlar el ordenamiento
  String _sortField = 'members';
  bool _sortAscending = false;
  
  // Lista ordenada para usar en el render
  List<Ministry> _sortedMinistries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _sortedMinistries = List<Ministry>.from(widget.ministries);
  }

  // Método para aplicar filtro de fecha
  void _applyDateFilter() {
    if (_startDate == null && _endDate == null) {
      setState(() {
        _isDateFilterActive = false;
        _filteredByDateEvents = [];
      });
      return;
    }
    
    final List<Map<String, dynamic>> filteredEvents = [];
    
    // Convertir las fechas a DateTime para comparación
    final startDate = _startDate;
    final endDate = _endDate != null 
        ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
        : null;
    
    // Recorrer todos los ministerios
    for (final ministryId in _ministryEvents.keys) {
      final ministryEvents = _ministryEvents[ministryId] ?? [];
      
      for (final event in ministryEvents) {
        final eventDate = event['date'] as DateTime?;
        
        if (eventDate != null) {
          bool includeRecord = true;
          
          // Comprobar fecha inicial
          if (startDate != null && eventDate.isBefore(startDate)) {
            includeRecord = false;
          }
          
          // Comprobar fecha final
          if (includeRecord && endDate != null && eventDate.isAfter(endDate)) {
            includeRecord = false;
          }
          
          if (includeRecord) {
            filteredEvents.add({
              ...event,
              'ministryId': ministryId,
            });
          }
        }
      }
    }
    
    // Ordenar por fecha (más reciente primero)
    filteredEvents.sort((a, b) {
      final aDate = a['date'] as DateTime?;
      final bDate = b['date'] as DateTime?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _filteredByDateEvents = filteredEvents;
      _isDateFilterActive = true;
    });
  }
  
  // Método para limpiar filtro de fecha
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isDateFilterActive = false;
      _filteredByDateEvents = [];
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _loadMinistryEventsData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('Error cargando datos: $e');
      }
    }
  }

  Future<void> _loadMinistryEventsData() async {
    for (final ministry in widget.ministries) {
      // 1. Obtener todos los eventos para este ministerio
      final ministryRef = FirebaseFirestore.instance.doc('ministries/${ministry.id}');
      final eventsQuery = await FirebaseFirestore.instance
          .collection('ministry_events')
          .where('ministryId', isEqualTo: ministryRef)
          .get();

      final events = eventsQuery.docs.map((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Sem título',
          'date': date,
          'timestamp': data['date'],
          'location': data['location'] ?? '',
          'registrations': 0, // Se llenará después
          'attendees': 0,     // Se llenará después
        };
      }).toList();
      
      // Organizar por fecha (más reciente primero)
      events.sort((a, b) => 
        (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
      
      // 2. Obtener estadísticas generales
      int totalRegistrations = 0;
      int totalAttendees = 0;
      
      // 3. Si hay eventos, obtener registros y asistencias
      if (events.isNotEmpty) {
        final eventIds = events.map((e) => e['id'] as String).toList();
        
        // Procesar por lotes si hay muchos IDs
        final eventBatches = _createBatches(eventIds, 10);
        
        // Obtener registros para cada evento
        for (final batch in eventBatches) {
          final registrationsQuery = await FirebaseFirestore.instance
              .collection('event_attendees')
              .where('eventId', whereIn: batch)
              .where('eventType', isEqualTo: 'ministry')
              .get();
              
          // Contar registros por evento
          for (final doc in registrationsQuery.docs) {
            final data = doc.data();
            final eventId = data['eventId'] as String?;
            
            if (eventId != null) {
              final eventIndex = events.indexWhere((e) => e['id'] == eventId);
              if (eventIndex >= 0) {
                events[eventIndex]['registrations'] = 
                    (events[eventIndex]['registrations'] as int) + 1;
                totalRegistrations++;
              }
            }
          }
          
          // Obtener asistencias confirmadas para cada evento
          final attendancesQuery = await FirebaseFirestore.instance
              .collection('event_attendance')
              .where('eventId', whereIn: batch)
              .where('eventType', isEqualTo: 'ministry')
              .where('attended', isEqualTo: true)
              .get();
              
          // Contar asistencias por evento
          for (final doc in attendancesQuery.docs) {
            final data = doc.data();
            final eventId = data['eventId'] as String?;
            
            if (eventId != null) {
              final eventIndex = events.indexWhere((e) => e['id'] == eventId);
              if (eventIndex >= 0) {
                events[eventIndex]['attendees'] = 
                    (events[eventIndex]['attendees'] as int) + 1;
                totalAttendees++;
              }
            }
          }
        }
      }
      
      // 4. Guardar datos para este ministerio
      if (mounted) {
        setState(() {
          _ministryStats[ministry.id] = {
            'totalEvents': events.length,
            'totalRegistrations': totalRegistrations,
            'totalAttendees': totalAttendees,
          };
          
          _ministryEvents[ministry.id] = events;
        });
      }
    }
  }

  // Función auxiliar para dividir listas
  List<List<T>> _createBatches<T>(List<T> items, int size) {
    List<List<T>> batches = [];
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size < items.length) ? i + size : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_ministryStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Não há eventos para mostrar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtro de fecha
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtrar por data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (_isDateFilterActive)
                        TextButton.icon(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpar filtro'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              locale: const Locale('pt', 'BR'),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            
                            if (selectedDate != null) {
                              setState(() {
                                _startDate = selectedDate;
                              });
                              _applyDateFilter();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                      : 'Data inicial',
                                  style: TextStyle(
                                    color: _startDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              locale: const Locale('pt', 'BR'),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            
                            if (selectedDate != null) {
                              setState(() {
                                _endDate = selectedDate;
                              });
                              _applyDateFilter();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                      : 'Data final',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? Colors.black87
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isDateFilterActive && _filteredByDateEvents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Eventos encontrados: ${_filteredByDateEvents.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Opciones de ordenamiento
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Text('Ordenar por: '),
              DropdownButton<String>(
                value: _sortField,
                items: const [
                  DropdownMenuItem(value: 'members', child: Text('Membros')),
                  DropdownMenuItem(value: 'name', child: Text('Nome')),
                  DropdownMenuItem(value: 'creation', child: Text('Data de criação')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      if (_sortField == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortField = value;
                        _sortAscending = false; // Default: descendente
                      }
                      
                      // Reordenar la lista
                      _sortMinistries();
                    });
                  }
                },
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _sortMinistries();
                  });
                },
              ),
            ],
          ),
        ),
        
        // Vista filtrada por fecha o vista normal
        Expanded(
          child: _isDateFilterActive
              ? _buildDateFilteredView()
              : _buildNormalView(),
        ),
      ],
    );
  }

  // Vista de todos los eventos filtrados por fecha
  Widget _buildDateFilteredView() {
    if (_filteredByDateEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Não há eventos nas datas selecionadas',
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
    
    // Agrupar por ministerio
    final Map<String, List<Map<String, dynamic>>> eventsByMinistry = {};
    
    for (final event in _filteredByDateEvents) {
      final ministryId = event['ministryId'] as String;
      
      if (!eventsByMinistry.containsKey(ministryId)) {
        eventsByMinistry[ministryId] = [];
      }
      
      eventsByMinistry[ministryId]!.add(event);
    }
    
    // Crear lista de ministerios ordenada
    final List<String> sortedMinistryIds = eventsByMinistry.keys.toList();
    
    // Asociar nombres de ministerios
    final Map<String, String> ministryNames = {};
    for (final ministry in widget.ministries) {
      ministryNames[ministry.id] = ministry.name;
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMinistryIds.length,
      itemBuilder: (context, index) {
        final ministryId = sortedMinistryIds[index];
        final ministryEvents = eventsByMinistry[ministryId]!;
        final ministryName = ministryNames[ministryId] ?? 'Ministério desconhecido';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                ministryName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${ministryEvents.length} eventos no período',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ministryEvents.length,
                  itemBuilder: (context, eventIndex) {
                    final event = ministryEvents[eventIndex];
                    return _buildEventCard(event);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Vista normal por ministerio
  Widget _buildNormalView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _sortedMinistries.length,
        itemBuilder: (context, index) {
          final ministry = _sortedMinistries[index];
          final stats = _ministryStats[ministry.id] ?? {
            'totalEvents': 0,
            'totalRegistrations': 0,
            'totalAttendees': 0,
          };
          final events = _ministryEvents[ministry.id] ?? [];
          
          return _buildMinistryExpansionTile(ministry, stats, events);
        },
      ),
    );
  }

  // Método auxiliar para construir la tarjeta de un evento filtrado
  Widget _buildEventCard(Map<String, dynamic> event) {
    final date = event['date'] as DateTime;
    final timeStr = DateFormat('HH:mm').format(date);
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] as String? ?? 'Evento',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event['location'] as String? ?? 'Local não informado',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => _showAttendeesDialog(
                    context, 
                    event['id'] as String? ?? '',
                    event['title'] as String? ?? 'Evento',
                    'registrations'
                  ),
                  child: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.blue[50],
                    label: Text(
                      'Registrados: ${event['registrations'] ?? 0}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showAttendeesDialog(
                    context, 
                    event['id'] as String? ?? '',
                    event['title'] as String? ?? 'Evento',
                    'attendees'
                  ),
                  child: Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.green[50],
                    label: Text(
                      'Presentes: ${event['attendees'] ?? 0}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinistryExpansionTile(
    Ministry ministry, 
    Map<String, dynamic> stats, 
    List<Map<String, dynamic>> events) {
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            ministry.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '${stats['totalEvents']} eventos',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          children: [
            // Tarjetas de estadísticas
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    title: 'Eventos',
                    count: stats['totalEvents'] ?? 0,
                    icon: Icons.event,
                    color: Colors.orange[300]!,
                    onTap: null,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Registrados',
                    count: stats['totalRegistrations'] ?? 0,
                    icon: Icons.how_to_reg,
                    color: Colors.blue,
                    onTap: null,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Asistentes',
                    count: stats['totalAttendees'] ?? 0,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onTap: null,
                  ),
                ],
              ),
            ),
            
            // Lista de eventos
            if (events.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Eventos de ${ministry.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...events.map((event) {
                    final date = event['date'] as DateTime;
                    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
                    final formattedTime = DateFormat('HH:mm').format(date);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Data: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Hora: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Local: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  event['location'] as String,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    _showAttendeesDialog(
                                      context, 
                                      event['id'] as String, 
                                      event['title'] as String,
                                      'registrations',
                                    );
                                  },
                                  child: Text(
                                    'Registrados: ${event['registrations']}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () {
                                    _showAttendeesDialog(
                                      context, 
                                      event['id'] as String, 
                                      event['title'] as String,
                                      'attendees',
                                    );
                                  },
                                  child: Text(
                                    'Asistentes: ${event['attendees']}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Center(
                  child: Text(
                    'Não há eventos para ${ministry.name}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
              ),
              if (onTap != null) const SizedBox(height: 4),
              if (onTap != null)
                Icon(
                  Icons.touch_app,
                  size: 14,
                  color: color.withOpacity(0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAttendeesDialog(
    BuildContext context,
    String eventId,
    String eventTitle,
    String type, // 'registrations' o 'attendees'
  ) async {
    // Comenzar a cargar
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando usuários...'),
          ],
        ),
      ),
    );
    
    try {
      // Determinar qué colección consultar
      late final QuerySnapshot snapshot;
      final String title = type == 'registrations' 
          ? 'Usuários Registrados' 
          : 'Asistentes Confirmados';
      
      if (type == 'registrations') {
        snapshot = await FirebaseFirestore.instance
            .collection('event_attendees')
            .where('eventId', isEqualTo: eventId)
            .where('eventType', isEqualTo: 'ministry')
            .get();
      } else { // attendees
        snapshot = await FirebaseFirestore.instance
            .collection('event_attendance')
            .where('eventId', isEqualTo: eventId)
            .where('eventType', isEqualTo: 'ministry')
            .where('attended', isEqualTo: true)
            .get();
      }
      
      // Obtener los IDs de usuario
      final userIds = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return data is Map ? data['userId'] as String? : null;
          })
          .where((userId) => userId != null)
          .cast<String>()
          .toList();
      
      // Cargar la información de los usuarios
      final List<Map<String, dynamic>> usersInfo = [];
      
      if (userIds.isNotEmpty) {
        // Procesar por lotes si hay muchos IDs
        final userBatches = _createBatches(userIds, 10);
        
        for (final batch in userBatches) {
          final usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
              
          for (final doc in usersSnapshot.docs) {
            final userData = doc.data();
            usersInfo.add({
              'id': doc.id,
              'name': userData['name'] ?? userData['displayName'] ?? 'Usuário',
              'email': userData['email'] ?? '',
              'photoUrl': userData['photoUrl'] ?? '',
            });
          }
        }
        
        // Ordenar por nombre
        usersInfo.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      }
      
      // Cerrar el diálogo de carga
      Navigator.pop(context);
      
      // Mostrar el diálogo con los usuarios
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$title - $eventTitle'),
            content: SizedBox(
              width: double.maxFinite,
              child: usersInfo.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Não há usuários para mostrar'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: usersInfo.length,
                      itemBuilder: (context, index) {
                        final user = usersInfo[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: user['photoUrl'] != null && 
                                            user['photoUrl'].isNotEmpty
                                ? NetworkImage(user['photoUrl'])
                                : null,
                            child: user['photoUrl'] == null || 
                                   user['photoUrl'].isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(user['name'] as String),
                          subtitle: Text(user['email'] as String),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar el diálogo de carga
      Navigator.pop(context);
      
      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Método para ordenar los ministerios según los criterios seleccionados
  void _sortMinistries() {
    final ministriesList = List<Ministry>.from(widget.ministries);
    
    ministriesList.sort((a, b) {
      int comparison;
      
      switch (_sortField) {
        case 'members':
          comparison = a.memberIds.length.compareTo(b.memberIds.length);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'creation':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = a.memberIds.length.compareTo(b.memberIds.length);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _sortedMinistries = ministriesList;
    });
  }
} 