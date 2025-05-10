import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../models/ministry.dart';
import '../../services/permission_service.dart';
import 'tabs/new/ministry_history_tab.dart';
import 'tabs/new/ministry_events_tab.dart';
import 'package:intl/intl.dart';

class MinistryMembersStatsScreen extends StatefulWidget {
  const MinistryMembersStatsScreen({Key? key}) : super(key: key);

  @override
  State<MinistryMembersStatsScreen> createState() => _MinistryMembersStatsScreenState();
}

class _MinistryMembersStatsScreenState extends State<MinistryMembersStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = true;
  List<Ministry> _ministries = [];
  Map<String, dynamic> _ministryStats = {};
  String _sortField = 'members';
  bool _sortAscending = false; // false = descendente (de maior a menor)
  
  // Variables para ordenar miembros dentro de un ministerio
  String _memberSortField = 'name'; // Campo por defecto para ordenar miembros ('name', 'attendance', 'events')
  bool _memberSortAscending = false; // Dirección de ordenamiento
  
  // Mapa para almacenar las configuraciones de orden por ministerio
  Map<String, Map<String, dynamic>> _ministrySortSettings = {};
  
  // Variables para el filtro de fecha
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateFilterActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMinistries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMinistries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar todos os ministérios
      final ministriesSnapshot = await FirebaseFirestore.instance
          .collection('ministries')
          .get();

      // Converter para lista de objetos Ministry
      final ministries = ministriesSnapshot.docs
          .map((doc) => Ministry.fromFirestore(doc))
          .toList();

      // Ordenar por número de membros (descendente)
      ministries.sort((a, b) => b.memberIds.length.compareTo(a.memberIds.length));

      if (mounted) {
        setState(() {
          _ministries = ministries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar ministérios: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas de Ministérios'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Membros'),
            Tab(text: 'Histórico'),
            Tab(text: 'Eventos'),
          ],
        ),
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('view_ministry_stats'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text('Erro ao verificar permissão: ${permissionSnapshot.error}'));
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Acesso Negado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Você não tem permissão para visualizar estatísticas de ministérios.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          // Contenido original cuando tiene permiso
          return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(),
                  _buildHistoryTab(),
                  _buildEventsTab(),
                ],
              );
        },
      ),
    );
  }

  // Primeira aba: Membros
  Widget _buildMembersTab() {
    // Contar total de membros de todos os ministérios (sem duplicados)
    final Set<String> uniqueMembers = {};
    for (var ministry in _ministries) {
      uniqueMembers.addAll(ministry.memberIds);
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
                                _isDateFilterActive = true;
                              });
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
                                _isDateFilterActive = true;
                              });
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
                ],
              ),
            ),
          ),
        ),
        
        // Card de resumo com total de membros únicos
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.people, size: 40, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total de Membros Únicos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${uniqueMembers.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Opções de ordenação
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
                      
                      // Reordenar a lista
                      _ministries.sort((a, b) {
                        int comparison;
                        if (_sortField == 'members') {
                          comparison = a.memberIds.length.compareTo(b.memberIds.length);
                        } else if (_sortField == 'name') {
                          comparison = a.name.compareTo(b.name);
                        } else { // creation
                          comparison = a.createdAt.compareTo(b.createdAt);
                        }
                        
                        return _sortAscending ? comparison : -comparison;
                      });
                    });
                  }
                },
              ),
              IconButton(
                icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                    _ministries = _ministries.reversed.toList();
                  });
                },
              ),
            ],
          ),
        ),

        // Lista de ministérios em acordeões
        Expanded(
          child: _ministries.isEmpty
              ? const Center(child: Text('Não há ministérios disponíveis'))
              : ListView.builder(
                  itemCount: _ministries.length,
                  itemBuilder: (context, index) {
                    final ministry = _ministries[index];
                    return _buildMinistryExpansionTile(ministry);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMinistryExpansionTile(Ministry ministry) {
    // Obtener o crear configuración de ordenamiento para este ministerio
    _ministrySortSettings.putIfAbsent(ministry.id, () => {
      'field': 'name',
      'ascending': false,
    });
    
    final sortSettings = _ministrySortSettings[ministry.id]!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
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
            '${ministry.memberIds.length} membros',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getMinistryMembersWithStats(ministry),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'Erro ao carregar membros: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final members = snapshot.data ?? [];
              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                    child: Text('Não há membros neste ministério'),
                );
              }

                // Ordenar miembros según la configuración actual
                _sortMembers(members, sortSettings['field'], sortSettings['ascending']);

              return Column(
                children: [
                    // Encabezados con botones de ordenación
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Nombre (ocupará el espacio de la imagen de perfil + nombre)
                          const Expanded(
                            flex: 6,
                            child: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          // Botones de ordenación
                          Expanded(
                            flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                                // Botón para ordenar por porcentaje de presencia
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (sortSettings['field'] == 'attendance') {
                                        sortSettings['ascending'] = !sortSettings['ascending'];
                                      } else {
                                        sortSettings['field'] = 'attendance';
                                        sortSettings['ascending'] = false; // Por defecto descendente
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '% Presença',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: sortSettings['field'] == 'attendance' 
                                                ? AppColors.primary 
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        if (sortSettings['field'] == 'attendance')
                                          Icon(
                                            sortSettings['ascending'] ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 11,
                                            color: AppColors.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Botón para ordenar por eventos
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (sortSettings['field'] == 'events') {
                                        sortSettings['ascending'] = !sortSettings['ascending'];
                                      } else {
                                        sortSettings['field'] = 'events';
                                        sortSettings['ascending'] = false; // Por defecto descendente
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Eventos',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: sortSettings['field'] == 'events' 
                                                ? AppColors.primary 
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        if (sortSettings['field'] == 'events')
                                          Icon(
                                            sortSettings['ascending'] ? Icons.arrow_upward : Icons.arrow_downward,
                                            size: 11,
                                            color: AppColors.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de miembros
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          elevation: 0,
                          color: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                        leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                          backgroundImage: member['photoUrl'] != null && member['photoUrl'].isNotEmpty
                              ? NetworkImage(member['photoUrl'])
                              : null,
                          child: member['photoUrl'] == null || member['photoUrl'].isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Row(
                          children: [
                                Text(
                                  member['name'] ?? 'Usuário',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                            if (member['isAdmin'] == true)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(member['email'] ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${member['attendedEvents'] ?? 0}/${member['registeredEvents'] ?? 0} eventos',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getAttendanceColor(member['attendancePercentage'] ?? 0)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${((member['attendancePercentage'] ?? 0) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getAttendanceColor(member['attendancePercentage'] ?? 0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                            ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
        ),
      ),
    );
  }
  
  // Método para ordenar miembros según un campo y dirección
  void _sortMembers(List<Map<String, dynamic>> members, String field, bool ascending) {
    members.sort((a, b) {
      // Ordenar por el campo seleccionado
      int comparison = 0;
      
      switch (field) {
        case 'name':
          // Solo para el campo nombre, priorizamos a los administradores
          if (a['isAdmin'] != b['isAdmin']) {
            return a['isAdmin'] ? -1 : 1;
          }
          comparison = (a['name'] ?? '').compareTo(b['name'] ?? '');
          break;
        case 'attendance':
          final aPercentage = a['attendancePercentage'] ?? 0.0;
          final bPercentage = b['attendancePercentage'] ?? 0.0;
          comparison = aPercentage.compareTo(bPercentage);
          break;
        case 'events':
          // Ordenar por eventos CONFIRMADOS
          final aEvents = a['attendedEvents'] ?? 0;
          final bEvents = b['attendedEvents'] ?? 0;
          comparison = aEvents.compareTo(bEvents);
          break;
        default:
          // Por defecto ordenamos por nombre, priorizando admins
          if (a['isAdmin'] != b['isAdmin']) {
            return a['isAdmin'] ? -1 : 1;
          }
          comparison = (a['name'] ?? '').compareTo(b['name'] ?? '');
      }
      
      // Invertir el resultado si es ascendente
      return ascending ? comparison : -comparison;
    });
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 0.8) {
      return Colors.green;
    } else if (percentage >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Método para limpiar filtro de fecha
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isDateFilterActive = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getMinistryMembersWithStats(Ministry ministry) async {
    final List<Map<String, dynamic>> membersWithStats = [];

    // 1. Crear una referencia al documento del ministerio
    final ministryRef = FirebaseFirestore.instance.doc('ministries/${ministry.id}');
    
    // 2. Obtener todos los eventos para este ministerio en una sola consulta
    // Si hay filtro de fecha, aplicarlo
    Query eventsQuery = FirebaseFirestore.instance
        .collection('ministry_events')
        .where('ministryId', isEqualTo: ministryRef);
    
    // Aplicar filtro de fecha si está activo
    if (_isDateFilterActive) {
      if (_startDate != null) {
        eventsQuery = eventsQuery.where('date', 
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
      }
      
      if (_endDate != null) {
        // Ajustar la fecha final para incluir todo el día
        final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        eventsQuery = eventsQuery.where('date', 
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
    }
    
    final eventsSnapshot = await eventsQuery.get();
    
    // Si no hay eventos, procesar todos los miembros con estadísticas en cero
    if (eventsSnapshot.docs.isEmpty) {
      // Obtener datos de todos los usuarios en una sola consulta
      final userIds = ministry.memberIds;
      if (userIds.isNotEmpty) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: userIds.take(10).toList())
            .get();
        
        // Crear un mapa para acceso rápido
        final usersMap = {
          for (var doc in usersSnapshot.docs)
            doc.id: doc.data()
        };
        
        // Procesar rápidamente cada miembro
        for (final memberId in ministry.memberIds) {
          final userData = usersMap[memberId];
          if (userData != null) {
            membersWithStats.add({
              'userId': memberId,
              'name': userData['name'] ?? userData['displayName'] ?? 'Usuário',
              'email': userData['email'] ?? '',
              'photoUrl': userData['photoUrl'] ?? '',
              'isAdmin': ministry.adminIds.contains(memberId),
              'registeredEvents': 0,
              'attendedEvents': 0,
              'attendancePercentage': 0.0,
            });
          }
        }
      }
    } else {
      // Hay eventos, optimizar la consulta de estadísticas
      
      // Obtener IDs de todos los eventos
      final eventIds = eventsSnapshot.docs.map((doc) => doc.id).toList();
      
      // 3. Obtener todos los registros (event_attendees) de una vez
      // Nota: puede requerir múltiples consultas si hay muchos eventos
      Map<String, Set<String>> registeredEventsMap = {};
      
      // Dividir en lotes si hay muchos IDs
      final eventBatches = _createBatches(eventIds, 10);
      
      for (final batch in eventBatches) {
        final registrationsQuery = await FirebaseFirestore.instance
            .collection('event_attendees')
            .where('eventId', whereIn: batch)
            .where('eventType', isEqualTo: 'ministry')
            .get();

        // Procesar todos los registros de una vez
        for (final doc in registrationsQuery.docs) {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final eventId = data['eventId'] as String?;
          
          if (userId != null && eventId != null && ministry.memberIds.contains(userId)) {
            registeredEventsMap.putIfAbsent(userId, () => {}).add(eventId);
          }
        }
      }
      
      // 4. Obtener todas las asistencias confirmadas (event_attendance) de una vez
      Map<String, Set<String>> attendedEventsMap = {};
      
      for (final batch in eventBatches) {
        final attendancesQuery = await FirebaseFirestore.instance
            .collection('event_attendance')
            .where('eventId', whereIn: batch)
            .where('eventType', isEqualTo: 'ministry')
            .where('attended', isEqualTo: true)
            .get();

        // Procesar todas las asistencias de una vez
        for (final doc in attendancesQuery.docs) {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final eventId = data['eventId'] as String?;
          
          if (userId != null && eventId != null && ministry.memberIds.contains(userId)) {
            attendedEventsMap.putIfAbsent(userId, () => {}).add(eventId);
          }
        }
      }
      
      // 5. Obtener datos de usuario en lote
      final userIds = ministry.memberIds;
      Map<String, Map<String, dynamic>> usersData = {};
      
      if (userIds.isNotEmpty) {
        // Firestore tiene límite de 10 elementos para whereIn
        final userBatches = _createBatches(userIds, 10);
        
        for (final batch in userBatches) {
          final usersQuery = await FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
              
          for (final doc in usersQuery.docs) {
            usersData[doc.id] = doc.data();
          }
        }
      }
      
      // 6. Finalmente, procesar y calcular estadísticas para cada miembro
      for (final memberId in ministry.memberIds) {
        final userData = usersData[memberId];
        if (userData != null) {
          // Contar registros y asistencias usando los mapas
          final registeredEvents = registeredEventsMap[memberId]?.length ?? 0;
          final attendedEvents = attendedEventsMap[memberId]?.length ?? 0;
          
          // Calcular porcentaje - dividir por 1 si registeredEvents es 0
        final attendancePercentage = registeredEvents > 0 
            ? attendedEvents / registeredEvents 
              : attendedEvents / 1.0;

        membersWithStats.add({
          'userId': memberId,
            'name': userData['name'] ?? userData['displayName'] ?? 'Usuário',
          'email': userData['email'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
            'isAdmin': ministry.adminIds.contains(memberId),
          'registeredEvents': registeredEvents,
          'attendedEvents': attendedEvents,
          'attendancePercentage': attendancePercentage,
        });
        }
      }
    }

    // Ordenar: primeiro admins, depois por nome
    membersWithStats.sort((a, b) {
      if (a['isAdmin'] == b['isAdmin']) {
        return (a['name'] ?? '').compareTo(b['name'] ?? '');
      }
      return a['isAdmin'] == true ? -1 : 1;
    });

    return membersWithStats;
  }

  // Función auxiliar para dividir una lista en lotes
  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    List<List<T>> batches = [];
    for (var i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  // Segunda aba: Histórico
  Widget _buildHistoryTab() {
    return MinistryHistoryTab(ministries: _ministries);
  }

  // Terceira aba: Eventos
  Widget _buildEventsTab() {
    return MinistryEventsTab(ministries: _ministries);
  }
} 