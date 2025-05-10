import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/culto_stats_service.dart';
import '../../models/user_service_stats.dart';
import '../../theme/app_colors.dart';
import '../../services/permission_service.dart';

/*
 * IMPORTANTE: Módulo de Estadísticas de Cultos
 * 
 * Este módulo permite visualizar estadísticas detalladas de la participación
 * de usuarios en los servicios religiosos (cultos) organizados por los ministerios.
 * 
 * Funcionalidades principales:
 * - Visualización de la tasa de confirmación para cada miembro 
 * - Análisis de asignaciones aceptadas, rechazadas, pendientes y canceladas
 * - Filtrado por rango de fechas con opciones predefinidas (último mes, últimos 3 meses, etc.)
 * - Selección de ministerio específico o vista consolidada de todos los ministerios
 * 
 * Esta pantalla ha sido eliminada de la interfaz del perfil de usuario pero el código 
 * se mantiene para posible uso futuro. El acceso directo a la ruta '/admin/culto-stats' 
 * sigue funcionando y puede ser accedido programáticamente.
 * 
 * Relacionado con:
 * - culto_stats_service.dart: Servicio que contiene la lógica de negocio
 * - user_service_stats.dart: Modelo de datos para las estadísticas
 */

class CultoStatsScreen extends StatefulWidget {
  const CultoStatsScreen({Key? key}) : super(key: key);

  @override
  State<CultoStatsScreen> createState() => _CultoStatsScreenState();
}

class _CultoStatsScreenState extends State<CultoStatsScreen> {
  final CultoStatsService _cultoService = CultoStatsService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = true;
  String _selectedEntityId = '';
  String _selectedEntityName = '';
  List<Map<String, dynamic>> _availableEntities = [];
  List<UserServiceStats> _stats = [];
  int _sortColumn = 0; // 0 = tasa de confirmación, 1 = asignaciones confirmadas, 2 = última fecha
  
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

      // Verificar si el usuario tiene permiso para ver estadísticas
      final hasPermission = await _permissionService.hasPermission('view_cult_stats');
      if (!hasPermission) {
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
          'name': 'Todos os ministérios',
          'serviceCount': 0,
        }
      ];
      
      // Cargar todos los ministerios disponibles
      final ministries = await FirebaseFirestore.instance.collection('ministries').get();
      for (var ministry in ministries.docs) {
        final ministryData = ministry.data();
        entities.add({
          'id': ministry.id,
          'name': ministryData['name'] ?? 'Ministério sem nome',
          'serviceCount': 0, // Lo actualizaremos después si es necesario
        });
      }
      
      // Si hay entidades, cargar conteo de servicios para cada una
      if (entities.length > 1) {
        // Intentar cargar servicios de cada ministerio para mostrar conteo
        await Future.forEach(entities.where((e) => e['id'] != 'all_ministries'), (Map<String, dynamic> entity) async {
          final String entityId = entity['id'];
          
          try {
            // Contar asignaciones de trabajo para ese ministerio
            final countQuery = FirebaseFirestore.instance
                .collection('work_assignments')
                .where('ministryId', isEqualTo: '/ministries/$entityId');
            
            final countSnapshot = await countQuery.count().get();
            entity['serviceCount'] = countSnapshot.count;
          } catch (e) {
            debugPrint('Error al contar servicios de ${entity['name']}: $e');
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
            content: Text('Erro ao carregar ministérios: $e'),
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
      final stats = await _cultoService.generateServiceStats(
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
            content: Text('Erro ao carregar estatísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _sortStats() {
    if (_sortColumn == 0) {
      // Ordenar por tasa de confirmación
      _stats.sort(UserServiceStats.compareByConfirmationRate);
    } else if (_sortColumn == 1) {
      // Ordenar por servicios confirmados
      _stats.sort(UserServiceStats.compareByConfirmedAssignments);
    } else {
      // Ordenar por fecha del último servicio
      _stats.sort(UserServiceStats.compareByLastServiceDate);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas de Cultos'),
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
            onPressed: () => _selectEntity(_selectedEntityId, _selectedEntityName),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('view_cult_stats'),
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
                    Text('Você não tem permissão para visualizar estatísticas de cultos.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          return _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    // Título de la sección
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participação em Escalas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Selector de ministerio más simple
                          InkWell(
                            onTap: () => _showMinistrySelector(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withOpacity(0.05),
                                    Colors.white,
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.church, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ministério',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          _selectedEntityName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de usuarios
                    Expanded(
                      child: _stats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Não há dados para mostrar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tente com outro ministério ou intervalo de datas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _stats.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final stat = _stats[index];
                                return _buildUserCard(stat);
                              },
                            ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  // Método para mostrar selector de ministerio
  void _showMinistrySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Selecione um ministério',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableEntities.length,
                  itemBuilder: (context, index) {
                    final entity = _availableEntities[index];
                    return ListTile(
                      leading: Icon(
                        Icons.church,
                        color: entity['id'] == _selectedEntityId 
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                      title: Text(entity['name']),
                      selected: entity['id'] == _selectedEntityId,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () {
                        Navigator.pop(context);
                        _selectEntity(entity['id'], entity['name']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildUserCard(UserServiceStats stat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con nombre del usuario
            Row(
              children: [
                // Avatar del usuario
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: stat.userPhotoUrl.isNotEmpty
                      ? NetworkImage(stat.userPhotoUrl)
                      : null,
                  child: stat.userPhotoUrl.isEmpty
                      ? Text(
                          stat.userName.isNotEmpty ? stat.userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Nombre del usuario
                Expanded(
                  child: Text(
                    stat.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Estadísticas en una única fila compacta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStatItem(
                  Icons.work_outline,
                  stat.totalAssignments.toString(),
                  'Total',
                  Colors.blue,
                ),
                _buildCompactStatItem(
                  Icons.check_circle_outline,
                  stat.confirmedAssignments.toString(),
                  'Confirmados',
                  Colors.green,
                ),
                _buildCompactStatItem(
                  Icons.thumb_up_alt_outlined,
                  stat.acceptedAssignments.toString(),
                  'Aceitos',
                  Colors.orange,
                ),
                _buildCompactStatItem(
                  Icons.thumb_down_alt_outlined,
                  stat.rejectedAssignments.toString(),
                  'Rejeitados',
                  Colors.red,
                ),
                _buildCompactStatItem(
                  Icons.hourglass_empty,
                  stat.pendingAssignments.toString(),
                  'Pendentes',
                  Colors.purple,
                ),
                _buildCompactStatItem(
                  Icons.cancel_outlined,
                  stat.cancelledAssignments.toString(),
                  'Cancelados',
                  Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompactStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Widget para filtro de fechas
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
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título con icono
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_alt, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Filtrar por data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Campos de fecha
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(true),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data inicial',
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: Text(
                      _startDate == null
                          ? 'Não selecionada'
                          : DateFormat('dd/MM/yyyy').format(_startDate!),
                      style: TextStyle(
                        color: _startDate == null ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(false),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data final',
                      prefixIcon: const Icon(Icons.calendar_today, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: Text(
                      _endDate == null
                          ? 'Não selecionada'
                          : DateFormat('dd/MM/yyyy').format(_endDate!),
                      style: TextStyle(
                        color: _endDate == null ? Colors.grey : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Texto de presets
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Presets rápidos:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          
          // Botones de acciones comunes
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildPresetChip(
                'Último mês',
                Icons.date_range,
                Colors.blue,
                () {
                  final now = DateTime.now();
                  setState(() {
                    _endDate = now;
                    _startDate = DateTime(now.year, now.month - 1, now.day);
                  });
                },
              ),
              _buildPresetChip(
                'Últimos 3 meses',
                Icons.date_range,
                Colors.green,
                () {
                  final now = DateTime.now();
                  setState(() {
                    _endDate = now;
                    _startDate = DateTime(now.year, now.month - 3, now.day);
                  });
                },
              ),
              _buildPresetChip(
                'Este ano',
                Icons.calendar_today,
                Colors.purple,
                () {
                  final now = DateTime.now();
                  setState(() {
                    _endDate = now;
                    _startDate = DateTime(now.year, 1, 1);
                  });
                },
              ),
              _buildPresetChip(
                'Limpar filtros',
                Icons.clear_all,
                Colors.grey,
                () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Aplicar filtros'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: color,
      onPressed: onTap,
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }
} 