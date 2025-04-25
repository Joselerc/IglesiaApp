import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../models/group.dart';

class GroupHistoryTab extends StatefulWidget {
  final List<Group> groups;

  const GroupHistoryTab({
    Key? key,
    required this.groups,
  }) : super(key: key);

  @override
  State<GroupHistoryTab> createState() => _GroupHistoryTabState();
}

class _GroupHistoryTabState extends State<GroupHistoryTab> {
  // Mapa para guardar los filtros seleccionados para cada grupo
  final Map<String, String?> _groupFilters = {};
  
  // Mapa para guardar los contadores de cada tipo para cada grupo
  final Map<String, Map<String, int>> _groupCounts = {};
  
  // Mapa para guardar estadísticas detalladas para cada grupo
  final Map<String, Map<String, int>> _groupDetailedStats = {};

  // Indicador de carga inicial
  bool _isLoading = true;
  
  // Datos cargados de Firestore (se cargan una vez en initState)
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupsData = {};
  
  // Variables para el filtro de fecha
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _filteredByDateMembers = [];
  bool _isDateFilterActive = false;
  
  // Variables para controlar el ordenamiento
  String _sortField = 'members';
  bool _sortAscending = false;
  
  // Lista ordenada para usar en el render
  List<Group> _sortedGroups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _sortedGroups = List<Group>.from(widget.groups);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await _getMembershipHistory();
      
      if (mounted) {
        setState(() {
          _groupsData = data;
          _updateCounters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error cargando datos: $e');
    }
  }
  
  // Método para aplicar filtro de fecha
  void _applyDateFilter() {
    if (_startDate == null && _endDate == null) {
      setState(() {
        _isDateFilterActive = false;
        _filteredByDateMembers = [];
      });
      return;
    }
    
    final List<Map<String, dynamic>> filteredMembers = [];
    
    // Convertir las fechas a Timestamp para comparación
    final startTimestamp = _startDate != null 
        ? Timestamp.fromDate(_startDate!) 
        : null;
    
    final endTimestamp = _endDate != null 
        ? Timestamp.fromDate(_endDate!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))) 
        : null;
    
    // Recorrer todos los grupos
    for (final groupId in _groupsData.keys) {
      final groupData = _groupsData[groupId]!;
      
      // Recorrer todos los tipos de registros
      for (final status in ['pending', 'accepted', 'rejected', 'exited']) {
        for (final member in groupData[status] ?? []) {
          final memberTimestamp = member['timestamp'] as Timestamp?;
          
          if (memberTimestamp != null) {
            bool includeRecord = true;
            
            // Comprobar fecha inicial
            if (startTimestamp != null && memberTimestamp.compareTo(startTimestamp) < 0) {
              includeRecord = false;
            }
            
            // Comprobar fecha final
            if (includeRecord && endTimestamp != null && memberTimestamp.compareTo(endTimestamp) > 0) {
              includeRecord = false;
            }
            
            if (includeRecord) {
              filteredMembers.add({
                ...member,
                'groupId': groupId,
              });
            }
          }
        }
      }
    }
    
    // Ordenar por fecha (más reciente primero)
    filteredMembers.sort((a, b) {
      final aDate = a['timestamp'] as Timestamp?;
      final bDate = b['timestamp'] as Timestamp?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _filteredByDateMembers = filteredMembers;
      _isDateFilterActive = true;
    });
  }
  
  // Método para limpiar filtro de fecha
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isDateFilterActive = false;
      _filteredByDateMembers = [];
    });
  }

  // Método para actualizar los contadores basados en los datos cargados
  void _updateCounters() {
    // Recorre cada grupo
    for (final group in widget.groups) {
      final groupId = group.id;
      final groupData = _groupsData[groupId];
      
      // Inicializa los contadores básicos si no existen
      if (!_groupCounts.containsKey(groupId)) {
        _groupCounts[groupId] = {
          'pending': 0,
          'accepted': 0,
          'rejected': 0,
          'exited': 0,
          'total': 0,
        };
      }
      
      // Inicializa las estadísticas detalladas si no existen
      if (!_groupDetailedStats.containsKey(groupId)) {
        _groupDetailedStats[groupId] = {
          'members_current': group.memberIds.length,
          'total_entries': 0,
          'added_direct': 0,  // Añadidos directamente por admin
          'added_request': 0, // Añadidos por solicitud aceptada
          'total_exits': 0,
          'removed_admin': 0,  // Removidos por admin
          'exit_voluntary': 0, // Salidas voluntarias
        };
      }
      
      // Actualiza los contadores con los datos cargados
      if (groupData != null) {
        // Contadores básicos
        final pendingCount = groupData['pending']?.length ?? 0;
        final acceptedCount = groupData['accepted']?.length ?? 0;
        final rejectedCount = groupData['rejected']?.length ?? 0;
        final exitedCount = groupData['exited']?.length ?? 0;
        
        _groupCounts[groupId] = {
          'pending': pendingCount,
          'accepted': acceptedCount,
          'rejected': rejectedCount,
          'exited': exitedCount,
          'total': pendingCount + acceptedCount + rejectedCount + exitedCount,
        };
        
        // Estadísticas detalladas
        int addedDirect = 0;
        int addedRequest = 0;
        int removedAdmin = 0;
        int exitVoluntary = 0;
        
        // Contar aceptados por tipo
        for (final entry in groupData['accepted'] ?? []) {
          if (entry['directAdd'] == true) {
            addedDirect++;
          } else {
            addedRequest++;
          }
        }
        
        // Contar salidas por tipo
        for (final exit in groupData['exited'] ?? []) {
          if (exit['exitType'] == 'removed') {
            removedAdmin++;
          } else {
            exitVoluntary++;
          }
        }
        
        _groupDetailedStats[groupId] = {
          'members_current': group.memberIds.length,
          'total_entries': addedDirect + addedRequest,
          'added_direct': addedDirect,
          'added_request': addedRequest,
          'total_exits': removedAdmin + exitVoluntary,
          'removed_admin': removedAdmin,
          'exit_voluntary': exitVoluntary,
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_groupsData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Não há histórico de membros para mostrar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
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
                                        primary: Colors.green,
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
                                        primary: Colors.green,
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
                    if (_isDateFilterActive && _filteredByDateMembers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Registros encontrados: ${_filteredByDateMembers.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green,
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
                        _sortGroups();
                      });
                    }
                  },
                ),
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _sortGroups();
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
      ),
    );
  }
  
  // Vista de todos los registros filtrados por fecha
  Widget _buildDateFilteredView() {
    if (_filteredByDateMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Não há registros nas datas selecionadas',
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
    
    // Agrupar por grupo
    final Map<String, List<Map<String, dynamic>>> recordsByGroup = {};
    
    for (final record in _filteredByDateMembers) {
      final groupId = record['groupId'] as String;
      
      if (!recordsByGroup.containsKey(groupId)) {
        recordsByGroup[groupId] = [];
      }
      
      recordsByGroup[groupId]!.add(record);
    }
    
    // Crear lista de grupos ordenada
    final List<String> sortedGroupIds = recordsByGroup.keys.toList();
    
    // Asociar nombres de grupos
    final Map<String, String> groupNames = {};
    for (final group in widget.groups) {
      groupNames[group.id] = group.name;
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedGroupIds.length,
      itemBuilder: (context, index) {
        final groupId = sortedGroupIds[index];
        final groupRecords = recordsByGroup[groupId]!;
        final groupName = groupNames[groupId] ?? 'Grupo desconhecido';
        
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
                groupName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${groupRecords.length} registros no período',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groupRecords.length,
                  itemBuilder: (context, recordIndex) {
                    final memberData = groupRecords[recordIndex];
                    return _buildMemberHistoryItem(memberData);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Vista normal por grupo
  Widget _buildNormalView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sortedGroups.length,
      itemBuilder: (context, index) {
        final group = _sortedGroups[index];
        final groupId = group.id;
        final groupAllData = _groupsData[groupId] ?? {};
        
        // Obtener el filtro seleccionado para este grupo o usar el predeterminado (todos)
        final selectedFilter = _groupFilters[groupId];
        
        // Determinar qué datos mostrar basados en el filtro
        List<Map<String, dynamic>> filteredMembers = [];
        if (selectedFilter == null) {
          // Mostrar todos los miembros (mezclando todas las categorías)
          groupAllData.forEach((key, value) {
            filteredMembers.addAll(value);
          });
        } else {
          // Mostrar solo los miembros del tipo seleccionado
          filteredMembers = List<Map<String, dynamic>>.from(groupAllData[selectedFilter] ?? []);
        }
        
        // Ordenar por fecha (más reciente primero)
        filteredMembers.sort((a, b) {
          final aDate = a['timestamp'] as Timestamp?;
          final bDate = b['timestamp'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        
        // Obtener los contadores para este grupo
        final counts = _groupCounts[groupId] ?? {
          'pending': 0, 'accepted': 0, 'rejected': 0, 'exited': 0, 'total': 0
        };
        
        // Obtener estadísticas detalladas
        final stats = _groupDetailedStats[groupId] ?? {
          'members_current': 0,
          'total_entries': 0,
          'added_direct': 0,
          'added_request': 0,
          'total_exits': 0,
          'removed_admin': 0,
          'exit_voluntary': 0,
        };
        
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
                group.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                selectedFilter == null
                    ? '${counts['total']} registros históricos'
                    : '${counts[selectedFilter] ?? 0} ${_getFilterName(selectedFilter)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              children: [
                // Tarjetas de resumen estadístico
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatCard(
                            title: 'Membros atuais',
                            count: stats['members_current'] ?? 0,
                            color: Colors.green,
                            icon: Icons.people,
                            onTap: null, // No se filtra
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            title: 'Total de entradas',
                            count: stats['total_entries'] ?? 0,
                            color: Colors.blue,
                            icon: Icons.input,
                            onTap: () {
                              _showEntriesDetailDialog(context, group.name, stats);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            title: 'Total de saídas',
                            count: stats['total_exits'] ?? 0,
                            color: Colors.red,
                            icon: Icons.output,
                            onTap: () {
                              _showExitsDetailDialog(context, group.name, stats);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Filtros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Filtrar por: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip(
                                    context: context,
                                    label: 'Todos',
                                    count: counts['total'] ?? 0,
                                    selected: _groupFilters[groupId] == null,
                                    color: Colors.green,
                                    onSelected: (selected) {
                                      setState(() {
                                        _groupFilters[groupId] = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    context: context,
                                    label: 'Pendentes',
                                    count: counts['pending'] ?? 0,
                                    selected: _groupFilters[groupId] == 'pending',
                                    color: Colors.orange,
                                    onSelected: (selected) {
                                      setState(() {
                                        _groupFilters[groupId] = selected ? 'pending' : null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    context: context,
                                    label: 'Aceitos',
                                    count: counts['accepted'] ?? 0,
                                    selected: _groupFilters[groupId] == 'accepted',
                                    color: Colors.green,
                                    onSelected: (selected) {
                                      setState(() {
                                        _groupFilters[groupId] = selected ? 'accepted' : null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    context: context,
                                    label: 'Rejeitados',
                                    count: counts['rejected'] ?? 0,
                                    selected: _groupFilters[groupId] == 'rejected',
                                    color: Colors.red,
                                    onSelected: (selected) {
                                      setState(() {
                                        _groupFilters[groupId] = selected ? 'rejected' : null;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    context: context,
                                    label: 'Saídas',
                                    count: counts['exited'] ?? 0,
                                    selected: _groupFilters[groupId] == 'exited',
                                    color: Colors.purple,
                                    onSelected: (selected) {
                                      setState(() {
                                        _groupFilters[groupId] = selected ? 'exited' : null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Divider
                const Divider(height: 1),
                
                // Lista de miembros filtrados
                if (filteredMembers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        selectedFilter == null
                            ? 'Não há registros históricos para este grupo'
                            : 'Não há registros de ${_getFilterName(selectedFilter)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, memberIndex) {
                      final memberData = filteredMembers[memberIndex];
                      return _buildMemberHistoryItem(memberData);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método para mostrar diálogo con detalles de entradas
  void _showEntriesDetailDialog(BuildContext context, String groupName, Map<String, int> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Entradas em $groupName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatDetailRow(
              label: 'Adicionados por admin',
              count: stats['added_direct'] ?? 0,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatDetailRow(
              label: 'Por solicitação',
              count: stats['added_request'] ?? 0,
              color: Colors.green,
            ),
            const Divider(),
            _buildStatDetailRow(
              label: 'Total de entradas',
              count: stats['total_entries'] ?? 0,
              color: Colors.black,
              isBold: true,
            ),
          ],
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

  // Método para mostrar diálogo con detalles de salidas
  void _showExitsDetailDialog(BuildContext context, String groupName, Map<String, int> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Saídas de $groupName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatDetailRow(
              label: 'Removidos por admin',
              count: stats['removed_admin'] ?? 0,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildStatDetailRow(
              label: 'Saídas voluntárias',
              count: stats['exit_voluntary'] ?? 0,
              color: Colors.orange,
            ),
            const Divider(),
            _buildStatDetailRow(
              label: 'Total de saídas',
              count: stats['total_exits'] ?? 0,
              color: Colors.black,
              isBold: true,
            ),
          ],
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

  // Widget para mostrar una fila de estadística en el diálogo
  Widget _buildStatDetailRow({
    required String label, 
    required int count, 
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para construir tarjeta de estadística
  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required Function()? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: color.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required int count,
    required bool selected,
    required Color color,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
      selectedColor: color,
      backgroundColor: Colors.grey[200],
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? color : Colors.grey[300]!,
        ),
      ),
      onSelected: onSelected,
    );
  }

  String _getFilterName(String filter) {
    switch (filter) {
      case 'pending':
        return 'pendentes';
      case 'accepted':
        return 'aceitos';
      case 'rejected':
        return 'rejeitados';
      case 'exited':
        return 'saídas';
      default:
        return 'registros';
    }
  }

  Widget _buildMemberHistoryItem(Map<String, dynamic> memberData) {
    final String status = memberData['status'] as String;
    final userName = memberData['userName'] ?? 'Usuário';
    final userPhotoUrl = memberData['userPhotoUrl'];
    final timestamp = memberData['timestamp'] as Timestamp?;
    
    // Formatear la fecha
    String dateStr = 'Data desconhecida';
    if (timestamp != null) {
      final date = timestamp.toDate();
      dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
    
    // Determinar colores y textos según el estado
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendente';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Aceito';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejeitado';
        statusIcon = Icons.cancel;
        break;
      case 'exited':
        statusColor = Colors.purple;
        statusText = 'Saiu';
        statusIcon = Icons.exit_to_app;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconhecido';
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl == null || userPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 52), // Alineado con el avatar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostrar detalles adicionales según el tipo de registro
                      if (status == 'accepted' && memberData['directAdd'] == true) ...[
                        Row(
                          children: [
                            const Text(
                              'Adicionado por: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                memberData['addedByName'] ?? 'Administrador',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (status == 'accepted' && memberData['directAdd'] != true) ...[
                        Row(
                          children: [
                            const Text(
                              'Modo: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Solicitação aceita',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (memberData['respondedBy'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Text(
                                  'Aceito por: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    memberData['respondedByName'] ?? 'Administrador',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (status == 'rejected') ...[
                        Row(
                          children: [
                            const Text(
                              'Rejeitado por: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                memberData['respondedByName'] ?? 'Administrador',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (status == 'exited') ...[
                        Row(
                          children: [
                            const Text(
                              'Tipo de saída: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                memberData['exitType'] == 'voluntary' 
                                    ? 'Voluntária' 
                                    : 'Removido',
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (memberData['exitType'] == 'removed' && memberData['removedByName'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Text(
                                  'Removido por: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    memberData['removedByName'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      // Mensaje si existe
                      if (memberData['message'] != null && memberData['message'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mensagem: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  memberData['message'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Razón de salida si existe
                      if (status == 'exited' && memberData['exitReason'] != null && memberData['exitReason'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Motivo de saída: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  memberData['exitReason'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _getMembershipHistory() async {
    // Estructura del resultado: 
    // { groupId: { pending: [...], accepted: [...], rejected: [...], exited: [...] } }
    final Map<String, Map<String, List<Map<String, dynamic>>>> result = {};
    
    try {
      for (final group in widget.groups) {
        final groupId = group.id;
        result[groupId] = {
          'pending': [],
          'accepted': [],
          'rejected': [],
          'exited': [],
        };
        
        // 1. Obtener solicitudes pendientes
        final pendingRequestsQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('entityId', isEqualTo: groupId)
            .where('entityType', isEqualTo: 'group')
            .where('status', isEqualTo: 'pending')
            .get();
            
        for (final doc in pendingRequestsQuery.docs) {
          final data = doc.data();
          result[groupId]!['pending']!.add({
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'] ?? 'Usuário',
            'userEmail': data['userEmail'] ?? '',
            'userPhotoUrl': data['userPhotoUrl'],
            'timestamp': data['requestTimestamp'],
            'message': data['message'],
            'status': 'pending',
          });
        }
        
        // 2. Obtener solicitudes aceptadas
        final acceptedRequestsQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('entityId', isEqualTo: groupId)
            .where('entityType', isEqualTo: 'group')
            .where('status', isEqualTo: 'accepted')
            .get();
            
        for (final doc in acceptedRequestsQuery.docs) {
          final data = doc.data();
          final directAdd = data['directAdd'] as bool? ?? false;
          
          // Obtener el nombre del admin que respondió (si aplica)
          String? respondedByName;
          if (!directAdd && data['respondedBy'] != null) {
            try {
              final adminDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['respondedBy'])
                  .get();
                  
              if (adminDoc.exists) {
                final adminData = adminDoc.data() ?? {};
                respondedByName = adminData['name'] ?? adminData['displayName'] ?? 'Administrador';
              }
            } catch (e) {
              // Ignorar errores
            }
          }
          
          result[groupId]!['accepted']!.add({
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'] ?? 'Usuário',
            'userEmail': data['userEmail'] ?? '',
            'userPhotoUrl': data['userPhotoUrl'],
            'timestamp': data['responseTimestamp'] ?? data['requestTimestamp'],
            'requestTimestamp': data['requestTimestamp'],
            'message': data['message'],
            'directAdd': directAdd,
            'addedBy': data['addedBy'],
            'addedByName': data['addedByName'],
            'respondedBy': data['respondedBy'],
            'respondedByName': respondedByName,
            'status': 'accepted',
          });
        }
        
        // 3. Obtener solicitudes rechazadas
        final rejectedRequestsQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('entityId', isEqualTo: groupId)
            .where('entityType', isEqualTo: 'group')
            .where('status', isEqualTo: 'rejected')
            .get();
            
        for (final doc in rejectedRequestsQuery.docs) {
          final data = doc.data();
          
          // Obtener el nombre del admin que rechazó
          String? respondedByName;
          if (data['respondedBy'] != null) {
            try {
              final adminDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['respondedBy'])
                  .get();
                  
              if (adminDoc.exists) {
                final adminData = adminDoc.data() ?? {};
                respondedByName = adminData['name'] ?? adminData['displayName'] ?? 'Administrador';
              }
            } catch (e) {
              // Ignorar errores
            }
          }
          
          result[groupId]!['rejected']!.add({
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'] ?? 'Usuário',
            'userEmail': data['userEmail'] ?? '',
            'userPhotoUrl': data['userPhotoUrl'],
            'timestamp': data['responseTimestamp'] ?? data['requestTimestamp'],
            'requestTimestamp': data['requestTimestamp'],
            'message': data['message'],
            'responseReason': data['responseReason'],
            'respondedBy': data['respondedBy'],
            'respondedByName': respondedByName,
            'status': 'rejected',
          });
        }
        
        // 4. Obtener salidas de miembros
        final exitsQuery = await FirebaseFirestore.instance
            .collection('member_exits')
            .where('entityId', isEqualTo: groupId)
            .where('entityType', isEqualTo: 'group')
            .get();
            
        for (final doc in exitsQuery.docs) {
          final data = doc.data();
          final exitType = data['exitType'] as String? ?? 'unknown';
          
          // Si fue removido por admin, obtener el nombre
          String? removedByName;
          if (exitType == 'removed' && data['removedById'] != null) {
            try {
              final adminDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(data['removedById'])
                  .get();
                  
              if (adminDoc.exists) {
                final adminData = adminDoc.data() ?? {};
                removedByName = adminData['name'] ?? adminData['displayName'] ?? 'Administrador';
              }
            } catch (e) {
              // Ignorar errores
            }
          }
          
          result[groupId]!['exited']!.add({
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'] ?? 'Usuário',
            'userEmail': data['userEmail'] ?? '',
            'userPhotoUrl': data['userPhotoUrl'],
            'timestamp': data['exitTimestamp'],
            'joinTimestamp': data['joinTimestamp'],
            'exitType': exitType,
            'exitReason': data['exitReason'],
            'removedById': data['removedById'],
            'removedByName': removedByName,
            'status': 'exited',
          });
        }
        
        // Ordenar cada lista por fecha (más reciente primero)
        for (final status in ['pending', 'accepted', 'rejected', 'exited']) {
          result[groupId]![status]!.sort((a, b) {
            final aTimestamp = a['timestamp'] as Timestamp?;
            final bTimestamp = b['timestamp'] as Timestamp?;
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            return bTimestamp.compareTo(aTimestamp);
          });
        }
      }
      
      return result;
    } catch (e) {
      print('Error cargando historial: $e');
      throw Exception('Erro ao carregar histórico: $e');
    }
  }

  // Método para ordenar los grupos según los criterios seleccionados
  void _sortGroups() {
    final groupsList = List<Group>.from(widget.groups);
    
    groupsList.sort((a, b) {
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
      _sortedGroups = groupsList;
    });
  }
} 