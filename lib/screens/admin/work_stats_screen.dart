import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/event_attendance_service.dart';
import '../../models/user_work_stats.dart';

class WorkStatsScreen extends StatefulWidget {
  const WorkStatsScreen({Key? key}) : super(key: key);

  @override
  State<WorkStatsScreen> createState() => _WorkStatsScreenState();
}

class _WorkStatsScreenState extends State<WorkStatsScreen> {
  final EventAttendanceService _attendanceService = EventAttendanceService();
  bool _isLoading = true;
  String _selectedEntityId = '';
  String _selectedEntityName = '';
  List<Map<String, dynamic>> _availableEntities = [];
  List<UserWorkStats> _stats = [];
  int _sortColumn = 0; // 0 = acceptance rate, 1 = jobs accepted, 2 = last date
  
  // Filtros de fecha
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadUserMinistries();
  }

  Future<void> _loadUserMinistries() async {
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

      // Agregar opción "Todos los ministerios" al inicio de la lista
      List<Map<String, dynamic>> entities = [
        {
          'id': 'all_ministries',
          'name': 'Todos los ministerios',
          'workCount': 0,
        }
      ];
      
      // Cargar solo ministerios ya que los trabajos sólo existen en ministerios
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
              'name': ministryData['name'] ?? 'Ministerio sin nombre',
              'workCount': 0, // Lo actualizaremos después si es necesario
            });
          }
        }
      }
      
      // Si hay entidades, cargar conteo de trabajos para cada una
      if (entities.isNotEmpty) {
        // Intentar cargar trabajos de cada ministerio para mostrar conteo
        await Future.forEach(entities.where((e) => e['id'] != 'all_ministries'), (Map<String, dynamic> entity) async {
          final String entityId = entity['id'];
          
          try {
            final workSchedulesQuery = FirebaseFirestore.instance
                .collection('work_schedules')
                .where('ministryId', isEqualTo: entityId);
            
            final schedules = await workSchedulesQuery.get();
            entity['workCount'] = schedules.docs.length;
          } catch (e) {
            debugPrint('Error al contar trabajos de ${entity['name']}: $e');
          }
        });
      }
      
      setState(() {
        _availableEntities = entities;
        _isLoading = false;
      });
      
      if (entities.isNotEmpty) {
        _selectEntity(entities[0]['id'], entities[0]['name']);
      }
    } catch (e) {
      debugPrint('Error al cargar ministerios: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ministerios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _selectEntity(String entityId, String entityName) async {
    setState(() {
      _selectedEntityId = entityId;
      _selectedEntityName = entityName;
      _isLoading = true;
    });
    
    try {
      final stats = await _attendanceService.generateWorkStats(
        ministryId: entityId,
        startDate: _startDate,
        endDate: _endDate,
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
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _sortStats() {
    if (_sortColumn == 0) {
      // Ordenar por tasa de aceptación
      _stats.sort(UserWorkStats.compareByAcceptanceRate);
    } else if (_sortColumn == 1) {
      // Ordenar por trabajos aceptados
      _stats.sort(UserWorkStats.compareByAcceptedJobs);
    } else {
      // Ordenar por fecha del último trabajo
      _stats.sort(UserWorkStats.compareByLastWorkDate);
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
          _selectEntity(_selectedEntityId, _selectedEntityName);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definir un título descriptivo
    final String screenTitle = _selectedEntityId == 'all_ministries' 
        ? 'Estadísticas de Trabajo' 
        : 'Trabajo: $_selectedEntityName';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showDateFilterModal,
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _selectEntity(_selectedEntityId, _selectedEntityName),
            tooltip: 'Actualizar',
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
                            labelText: 'Seleccionar Ministerio',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          value: _availableEntities.isNotEmpty && _selectedEntityId.isNotEmpty 
                              ? _selectedEntityId
                              : null,
                          items: _availableEntities.map((entity) {
                            final String id = entity['id'];
                            final String name = entity['name'];
                            final int workCount = entity['workCount'] ?? 0;
                            
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    id == 'all_ministries' ? Icons.groups_2 : Icons.people,
                                    color: Colors.blue.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (id != 'all_ministries') ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '$workCount trabajos',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final entity = _availableEntities.firstWhere(
                                (e) => e['id'] == value,
                              );
                              
                              _selectEntity(value, entity['name']);
                            }
                          },
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
                                        onDeleted: () {
                                          setState(() {
                                            _startDate = null;
                                          });
                                          
                                          _selectEntity(_selectedEntityId, _selectedEntityName);
                                        },
                                      ),
                                    ),
                                  if (_endDate != null)
                                    Chip(
                                      label: Text('Hasta: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      onDeleted: () {
                                        setState(() {
                                          _endDate = null;
                                        });
                                        
                                        _selectEntity(_selectedEntityId, _selectedEntityName);
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
                                _buildSortButton(0, 'Tasa de Aceptación'),
                                const SizedBox(width: 8),
                                _buildSortButton(1, 'Trabajos Aceptados'),
                                const SizedBox(width: 8),
                                _buildSortButton(2, 'Último Trabajo'),
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
                                      Icons.work_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No hay datos de trabajos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      child: Text(
                                        'No se encontraron registros de trabajos para $_selectedEntityName',
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Encabezado con datos de usuario
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: stat.userPhotoUrl.isNotEmpty ? 
                                                  NetworkImage(stat.userPhotoUrl) : null,
                                                child: stat.userPhotoUrl.isEmpty ? 
                                                  const Icon(Icons.person) : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      stat.userName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Último trabajo: ${DateFormat('dd/MM/yyyy').format(stat.lastWorkDate)}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              _buildRateChip(stat.acceptanceRate),
                                            ],
                                          ),
                                          
                                          const Divider(height: 24),
                                          
                                          // Estadísticas detalladas
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildStatColumn(
                                                'Total', 
                                                stat.totalInvitations.toString(),
                                                Icons.work,
                                                Colors.blue,
                                              ),
                                              _buildStatColumn(
                                                'Aceptados', 
                                                stat.acceptedJobs.toString(),
                                                Icons.check_circle,
                                                Colors.green,
                                              ),
                                              _buildStatColumn(
                                                'Rechazados', 
                                                stat.rejectedJobs.toString(),
                                                Icons.cancel,
                                                Colors.red,
                                              ),
                                              _buildStatColumn(
                                                'Pendientes', 
                                                stat.pendingJobs.toString(),
                                                Icons.hourglass_empty,
                                                Colors.orange,
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
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.blue.shade800,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRateChip(double rate) {
    final Color color = _getColorForRate(rate);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.percent,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${rate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No administras ningún ministerio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Para ver estadísticas de trabajo, debes ser líder de al menos un ministerio',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserMinistries,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
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
      locale: const Locale('es', 'ES'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por Fecha',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de inicio',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                  : 'Seleccionar',
                              style: TextStyle(
                                color: _startDate != null ? Colors.black : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de fin',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                  : 'Seleccionar',
                              style: TextStyle(
                                color: _endDate != null ? Colors.black : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
                child: const Text('Limpiar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onApply(_startDate, _endDate);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
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