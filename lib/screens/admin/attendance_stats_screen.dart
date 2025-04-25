import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/event_attendance_service.dart';
import '../../models/user_attendance_stats.dart';
import '../../theme/app_colors.dart';

/*
 * IMPORTANTE: Módulo de Estadísticas de Asistencia
 * 
 * Este módulo permite visualizar estadísticas detalladas de asistencia de usuarios 
 * a eventos de ministerios y grupos.
 * 
 * Funcionalidades principales:
 * - Visualización de tasa de asistencia para cada miembro
 * - Filtrado por rango de fechas
 * - Ordenamiento por tasa de asistencia, cantidad de eventos asistidos, o fecha de última asistencia
 * - Vista consolidada para todos los ministerios o todos los grupos
 * - Vista específica para un ministerio o grupo concreto
 * 
 * Esta pantalla puede ser accedida desde el menú de administración pero está temporalmente
 * oculta en la interfaz del perfil de usuario. Puede reactivarse en el futuro si se requiere
 * esta funcionalidad.
 * 
 * Relacionado con:
 * - event_attendance_service.dart: Servicio que contiene la lógica de negocio
 * - user_attendance_stats.dart: Modelo de datos para las estadísticas
 */

class AttendanceStatsScreen extends StatefulWidget {
  const AttendanceStatsScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceStatsScreen> createState() => _AttendanceStatsScreenState();
}

class _AttendanceStatsScreenState extends State<AttendanceStatsScreen> {
  final EventAttendanceService _attendanceService = EventAttendanceService();
  bool _isLoading = true;
  String _selectedEntityId = '';
  String _selectedEntityType = '';
  String _selectedEntityName = '';
  List<Map<String, dynamic>> _availableEntities = [];
  List<UserAttendanceStats> _stats = [];
  int _sortColumn = 0; // 0 = rate, 1 = count, 2 = last date
  
  // Filtros de fecha
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadUserEntities();
  }

  Future<void> _loadUserEntities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _availableEntities = [];
        });
        return;
      }

      // Agregar opciones generales al inicio de la lista
      List<Map<String, dynamic>> entities = [
        {
          'id': 'all_ministries',
          'type': 'all_ministries',
          'name': 'Todos os ministérios',
          'eventCount': 0,
        },
        {
          'id': 'all_groups',
          'type': 'all_groups',
          'name': 'Todos os grupos',
          'eventCount': 0,
        }
      ];
      
      // Cargar todos los ministerios
      final ministries = await FirebaseFirestore.instance.collection('ministries').get();
      
      // Filtrar los ministerios donde el usuario es admin manualmente
      for (var ministry in ministries.docs) {
        final ministryData = ministry.data();
        final String adminField = 'ministrieAdmin';
        
        if (ministryData.containsKey(adminField) && ministryData[adminField] is List) {
          bool isAdmin = false;
          final List<dynamic> admins = ministryData[adminField];
          
          for (var admin in admins) {
            String adminId = '';
            
            // Si es una referencia de documento, extraer el ID
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          // Si es admin, agregar a la lista de entidades
          if (isAdmin) {
            entities.add({
              'id': ministry.id,
              'type': 'ministry',
              'name': ministryData['name'] ?? 'Ministério sem nome',
              'eventCount': 0, // Lo actualizaremos después si es necesario
            });
          }
        }
      }
      
      // Cargar todos los grupos
      final groups = await FirebaseFirestore.instance.collection('groups').get();
      
      // Filtrar los grupos donde el usuario es admin manualmente
      for (var group in groups.docs) {
        final groupData = group.data();
        final String adminField = 'groupAdmin';
        
        if (groupData.containsKey(adminField) && groupData[adminField] is List) {
          bool isAdmin = false;
          final List<dynamic> admins = groupData[adminField];
          
          for (var admin in admins) {
            String adminId = '';
            
            // Si es una referencia de documento, extraer el ID
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          // Si es admin, agregar a la lista de entidades
          if (isAdmin) {
            entities.add({
              'id': group.id,
              'type': 'group',
              'name': groupData['name'] ?? 'Grupo sem nome',
              'eventCount': 0, // Lo actualizaremos después si es necesario
            });
          }
        }
      }
      
      // Si hay entidades, cargar conteo de eventos para cada una
      if (entities.isNotEmpty) {
        // Intentar cargar eventos de cada entidad para mostrar conteo
        await Future.forEach(entities, (Map<String, dynamic> entity) async {
          final String entityId = entity['id'];
          final String entityType = entity['type'];
          
          try {
            Query eventsQuery;
            if (entityType == 'ministry') {
              eventsQuery = FirebaseFirestore.instance
                  .collection('ministry_events')
                  .where('ministryId', isEqualTo: FirebaseFirestore.instance.collection('ministries').doc(entityId));
            } else {
              eventsQuery = FirebaseFirestore.instance
                  .collection('group_events')
                  .where('groupId', isEqualTo: FirebaseFirestore.instance.collection('groups').doc(entityId));
            }
            
            final eventDocs = await eventsQuery.get();
            entity['eventCount'] = eventDocs.docs.length;
          } catch (e) {
            debugPrint('Erro ao contar eventos de ${entity['name']}: $e');
          }
        });
      }
      
      setState(() {
        _availableEntities = entities;
        _isLoading = false;
      });
      
      if (entities.isNotEmpty) {
        _selectEntity(entities[0]['id'], entities[0]['type'], entities[0]['name']);
      }
    } catch (e) {
      debugPrint('Erro ao carregar entidades: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar entidades: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _selectEntity(String entityId, String entityType, String entityName) async {
    setState(() {
      _selectedEntityId = entityId;
      _selectedEntityType = entityType;
      _selectedEntityName = entityName;
      _isLoading = true;
    });
    
    try {
      final stats = await _attendanceService.generateAttendanceStats(
        entityId: entityId,
        entityType: entityType,
        startDate: _startDate,
        endDate: _endDate,
        showOnlyMembers: entityType != 'all', // Mostrar solo miembros para entidades específicas
      );
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar estatísticas: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
  
  void _sortStats() {
    if (_sortColumn == 0) {
      // Ordenar por tasa de asistencia
      _stats.sort(UserAttendanceStats.compareByAttendanceRate);
    } else if (_sortColumn == 1) {
      // Ordenar por conteo de asistencia
      _stats.sort(UserAttendanceStats.compareByEventsAttended);
    } else {
      // Ordenar por fecha de última asistencia
      _stats.sort(UserAttendanceStats.compareByLastAttendance);
    }
    
    setState(() {});
  }

  void _showDateFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DateFilterModal(
        startDate: _startDate,
        endDate: _endDate,
        onApply: (startDate, endDate) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
          });
          
          // Recargar estadísticas con nuevos filtros
          _selectEntity(_selectedEntityId, _selectedEntityType, _selectedEntityName);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definir un título descriptivo basado en el tipo de entidad seleccionada
    final String screenTitle = _selectedEntityType == 'all' ? 'Estatísticas Gerais' :
                              _selectedEntityType == 'all_ministries' ? 'Estatísticas de Ministérios' :
                              _selectedEntityType == 'all_groups' ? 'Estatísticas de Grupos' :
                              _selectedEntityType == 'ministry' ? 'Estatísticas: $_selectedEntityName' :
                              'Estatísticas: $_selectedEntityName';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showDateFilterModal,
            tooltip: 'Filtrar por data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _selectEntity(_selectedEntityId, _selectedEntityType, _selectedEntityName),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableEntities.isEmpty
              ? _buildEmptyState()
              : SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Selector de entidad
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Selecionar Entidade',
                            labelStyle: TextStyle(color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          value: _availableEntities.isNotEmpty && _selectedEntityId.isNotEmpty 
                              ? '$_selectedEntityType:$_selectedEntityId'
                              : null,
                          items: _availableEntities.map((entity) {
                            final String id = entity['id'];
                            final String type = entity['type'];
                            final String name = entity['name'];
                            final int eventCount = entity['eventCount'];
                            final String key = '$type:$id';
                            
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type == 'ministry' ? Icons.people : 
                                    type == 'group' ? Icons.group :
                                    type == 'all_ministries' ? Icons.people_alt :
                                    type == 'all_groups' ? Icons.groups :
                                    Icons.dashboard_customize,
                                    color: type == 'ministry' ? AppColors.primary : 
                                           type == 'group' ? Colors.green :
                                           type == 'all_ministries' ? AppColors.primary :
                                           type == 'all_groups' ? Colors.green :
                                           AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$eventCount eventos',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final parts = value.split(':');
                              final type = parts[0];
                              final id = parts[1];
                              
                              final entity = _availableEntities.firstWhere(
                                (e) => e['id'] == id && e['type'] == type,
                              );
                              
                              _selectEntity(id, type, entity['name']);
                            }
                          },
                          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          dropdownColor: Colors.white,
                        ),
                      ),
                      
                      // Filtros activos
                      if (_startDate != null || _endDate != null)
                        SizedBox(
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_startDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Chip(
                                        label: Text('Desde: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'),
                                        deleteIcon: const Icon(Icons.close, size: 16),
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        deleteIconColor: AppColors.primary,
                                        labelStyle: TextStyle(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _startDate = null;
                                          });
                                          
                                          _selectEntity(_selectedEntityId, _selectedEntityType, _selectedEntityName);
                                        },
                                      ),
                                    ),
                                  if (_endDate != null)
                                    Chip(
                                      label: Text('Até: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      deleteIconColor: AppColors.primary,
                                      labelStyle: TextStyle(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                      ),
                                      onDeleted: () {
                                        setState(() {
                                          _endDate = null;
                                        });
                                        
                                        _selectEntity(_selectedEntityId, _selectedEntityType, _selectedEntityName);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Ordenar por
                      SizedBox(
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Ordenar por:'),
                                const SizedBox(width: 8),
                                _buildSortButton(0, 'Taxa de Presença'),
                                const SizedBox(width: 8),
                                _buildSortButton(1, 'Eventos Presentes'),
                                const SizedBox(width: 8),
                                _buildSortButton(2, 'Última Presença'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Tabla o lista de estadísticas
                      Expanded(
                        child: _stats.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Não há dados de presença',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Text(
                                        'Nenhum membro encontrado para ${_selectedEntityName}. Certifique-se de que há membros atribuídos a esta entidade.',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _stats.length,
                                padding: const EdgeInsets.all(16),
                                itemBuilder: (context, index) {
                                  final stat = _stats[index];
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundImage: stat.userPhotoUrl.isNotEmpty ? 
                                          NetworkImage(stat.userPhotoUrl) : null,
                                        child: stat.userPhotoUrl.isEmpty ? 
                                          const Icon(Icons.person) : null,
                                      ),
                                      title: Text(
                                        stat.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (stat.entityName.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              stat.entityName,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _buildStatChip(
                                                label: '${stat.attendanceRate.toStringAsFixed(0)}%',
                                                icon: Icons.percent,
                                                color: _getColorForRate(stat.attendanceRate),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildStatChip(
                                                label: '${stat.eventsAttended}/${stat.totalEvents}',
                                                icon: Icons.event_available,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              _buildStatChip(
                                                label: stat.lastAttendance.year > 2001 ? 
                                                  'Última: ${DateFormat('dd/MM').format(stat.lastAttendance)}' : 'Sem presença',
                                                icon: Icons.calendar_today,
                                                color: Colors.purple,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildSortButton(int column, String label) {
    final isSelected = _sortColumn == column;
    
    return InkWell(
      onTap: () {
        setState(() {
          _sortColumn = column;
        });
        _sortStats();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Você não administra nenhum grupo ou ministério',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Para ver estatísticas de presença, você deve ser líder de pelo menos um grupo ou ministério',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserEntities,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getColorForRate(double rate) {
    if (rate >= 80) {
      return Colors.green;
    } else if (rate >= 60) {
      return Colors.lightGreen;
    } else if (rate >= 40) {
      return Colors.orange;
    } else if (rate >= 20) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}

class DateFilterModal extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onApply;

  const DateFilterModal({
    Key? key,
    this.startDate,
    this.endDate,
    required this.onApply,
  }) : super(key: key);

  @override
  State<DateFilterModal> createState() => _DateFilterModalState();
}

class _DateFilterModalState extends State<DateFilterModal> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365));
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Si la fecha de inicio es posterior a la de fin, actualizar la de fin
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = pickedDate;
          // Si la fecha de fin es anterior a la de inicio, actualizar la de inicio
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrar por Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Data de Início'),
            subtitle: Text(
              _startDate == null ? 'Não especificado' : DateFormat('dd/MM/yyyy').format(_startDate!),
              style: TextStyle(
                color: _startDate == null ? Colors.grey : Colors.black87,
                fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: OutlinedButton(
              onPressed: () => _selectDate(context, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Selecionar'),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            title: const Text('Data Final'),
            subtitle: Text(
              _endDate == null ? 'Não especificado' : DateFormat('dd/MM/yyyy').format(_endDate!),
              style: TextStyle(
                color: _endDate == null ? Colors.grey : Colors.black87,
                fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: OutlinedButton(
              onPressed: () => _selectDate(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Selecionar'),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Limpar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onApply(_startDate, _endDate);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 