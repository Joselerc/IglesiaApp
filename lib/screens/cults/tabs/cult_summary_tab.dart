import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/cult.dart';
import '../../../models/time_slot.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/cult_summary_export_service.dart';

class CultSummaryTab extends StatefulWidget {
  final Cult cult;
  
  const CultSummaryTab({
    super.key,
    required this.cult,
  });

  @override
  State<CultSummaryTab> createState() => _CultSummaryTabState();
}

class _CultSummaryTabState extends State<CultSummaryTab> {
  bool _isCompactView = true;
  String _selectedFilter = 'all'; // all, pending, accepted, rejected, vacant
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controles superiores
        _buildControls(),
        
        // Contenido principal
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('time_slots')
                .where('entityId', isEqualTo: widget.cult.id)
                .where('entityType', isEqualTo: 'cult')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, timeSlotsSnapshot) {
              if (timeSlotsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!timeSlotsSnapshot.hasData || timeSlotsSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noTimeSlotsCreated,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }
              
              final timeSlots = timeSlotsSnapshot.data!.docs
                  .map((doc) => TimeSlot.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  return _buildTimeSlotSection(timeSlots[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Botón de descarga
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDownloadOptions,
              icon: const Icon(Icons.download, size: 20),
              label: Text(AppLocalizations.of(context)!.downloadSummary),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Toggle Vista Compacta/Detallada
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.summaryView,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(AppLocalizations.of(context)!.compact, style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.view_compact, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(AppLocalizations.of(context)!.detailed, style: const TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.view_list, size: 16),
                  ),
                ],
                selected: {_isCompactView},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isCompactView = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.grey[200]!;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return Colors.grey[700]!;
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', AppLocalizations.of(context)!.all, Icons.select_all),
                const SizedBox(width: 8),
                _buildFilterChip('pending', AppLocalizations.of(context)!.pending, Icons.schedule),
                const SizedBox(width: 8),
                _buildFilterChip('accepted', AppLocalizations.of(context)!.accepted, Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', AppLocalizations.of(context)!.rejected, Icons.cancel),
                const SizedBox(width: 8),
                _buildFilterChip('vacant', AppLocalizations.of(context)!.filterVacant, Icons.person_off),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
  
  Widget _buildTimeSlotSection(TimeSlot timeSlot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la franja horaria
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeSlot.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${DateFormat('HH:mm').format(timeSlot.startTime)} - ${DateFormat('HH:mm').format(timeSlot.endTime)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de ministerios y roles
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('available_roles')
                .where('timeSlotId', isEqualTo: timeSlot.id)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, rolesSnapshot) {
              if (rolesSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (!rolesSnapshot.hasData || rolesSnapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.noRolesAssigned,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              
              // Agrupar roles por ministerio
              final Map<String, List<Map<String, dynamic>>> rolesByMinistry = {};
              
              for (var doc in rolesSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final ministryName = data['ministryName'] ?? AppLocalizations.of(context)!.noMinistry;
                
                if (!rolesByMinistry.containsKey(ministryName)) {
                  rolesByMinistry[ministryName] = [];
                }
                
                rolesByMinistry[ministryName]!.add({
                  'id': doc.id,
                  'role': data['role'],
                  'capacity': data['capacity'] ?? 1,
                  'current': data['current'] ?? 0,
                  'ministryId': data['ministryId'],
                });
              }
              
              return Column(
                children: rolesByMinistry.entries.map((entry) {
                  return _buildMinistrySection(
                    entry.key,
                    entry.value,
                    timeSlot.id,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMinistrySection(
    String ministryName,
    List<Map<String, dynamic>> roles,
    String timeSlotId,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del ministerio
          Row(
            children: [
              Icon(Icons.groups, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                ministryName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Lista de roles
          ...roles.map((roleData) => _buildRoleItem(roleData, timeSlotId)),
        ],
      ),
    );
  }
  
  Widget _buildRoleItem(Map<String, dynamic> roleData, String timeSlotId) {
    final String role = roleData['role'];
    final int capacity = roleData['capacity'];
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, assignmentsSnapshot) {
        if (assignmentsSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        final assignments = assignmentsSnapshot.data?.docs ?? [];
        
        // Filtrar según el filtro seleccionado
        final filteredAssignments = _filterAssignments(assignments);
        
        // Si está filtrado y no hay resultados, no mostrar nada
        if (_selectedFilter != 'all' && filteredAssignments.isEmpty) {
          // Verificar si es vacante cuando el filtro es 'vacant'
          if (_selectedFilter == 'vacant' && assignments.isEmpty) {
            // Mostrar como vacante
          } else {
            return const SizedBox.shrink();
          }
        }
        
        if (_isCompactView) {
          return _buildCompactRoleView(role, capacity, assignments);
        } else {
          return _buildDetailedRoleView(role, capacity, assignments);
        }
      },
    );
  }
  
  List<QueryDocumentSnapshot> _filterAssignments(List<QueryDocumentSnapshot> assignments) {
    if (_selectedFilter == 'all') return assignments;
    
    return assignments.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      
      switch (_selectedFilter) {
        case 'pending':
          return status == 'pending';
        case 'accepted':
          return status == 'accepted';
        case 'rejected':
          return status == 'rejected';
        default:
          return true;
      }
    }).toList();
  }
  
  Widget _buildCompactRoleView(String role, int capacity, List<QueryDocumentSnapshot> assignments) {
    final int filled = assignments.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      return status == 'accepted';
    }).length;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              role,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '$filled/$capacity ${AppLocalizations.of(context)!.filled}',
            style: TextStyle(
              fontSize: 13,
              color: filled >= capacity ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedRoleView(String role, int capacity, List<QueryDocumentSnapshot> assignments) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del rol con capacidad
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  role,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${assignments.where((d) => (d.data() as Map)['status'] == 'accepted').length}/$capacity',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Lista de personas asignadas + vacantes
          ...List.generate(capacity, (index) {
            if (index < assignments.length) {
              return _buildPersonAssignment(assignments[index]);
            } else {
              // Mostrar vacante para posiciones no ocupadas
              return Padding(
                padding: const EdgeInsets.only(left: 24, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.unassigned,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),
                    _buildStatusChip(AppLocalizations.of(context)!.vacantStatus, 'vacant'),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }
  
  Widget _buildPersonAssignment(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final status = data['status'] ?? 'pending';
    
    // Obtener ID del usuario
    String userIdStr = '';
    if (userId is DocumentReference) {
      userIdStr = userId.id;
    } else if (userId is String) {
      userIdStr = userId.replaceAll('/users/', '');
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userIdStr)
          .get(),
      builder: (context, userSnapshot) {
        final userName = userSnapshot.hasData && userSnapshot.data!.exists
            ? (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? AppLocalizations.of(context)!.user
            : AppLocalizations.of(context)!.loading;
        
        return Padding(
          padding: const EdgeInsets.only(left: 24, top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              _buildStatusChip(status, status),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatusChip(String label, String status) {
    Color color;
    IconData icon;
    String displayText;
    
    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        displayText = AppLocalizations.of(context)!.accepted;
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        displayText = AppLocalizations.of(context)!.pending;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        displayText = AppLocalizations.of(context)!.rejected;
        break;
      case 'vacant':
      default:
        color = Colors.grey;
        icon = Icons.person_off;
        displayText = label;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDownloadOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.downloadSummary),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(AppLocalizations.of(context)!.downloadPDF),
              subtitle: Text(AppLocalizations.of(context)!.printableDocument),
              onTap: () {
                Navigator.pop(context);
                _downloadPDF();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(AppLocalizations.of(context)!.downloadExcel),
              subtitle: Text(AppLocalizations.of(context)!.editableSpreadsheet),
              onTap: () {
                Navigator.pop(context);
                _downloadExcel();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }
  
  Future<void> _downloadPDF() async {
    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Preparar datos
      final data = await _prepareExportData();
      
      // Cerrar indicador de carga
      if (!mounted) return;
      Navigator.pop(context);
      
      // Generar PDF
      final filePath = await CultSummaryExportService.exportToPDF(
        cult: widget.cult,
        timeSlots: data['timeSlots'],
        rolesData: data['rolesData'],
        churchName: data['churchName'],
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF descargado exitosamente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      filePath,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Abrir',
            textColor: Colors.white,
            onPressed: () {
              // Aquí podrías abrir el archivo si lo deseas
            },
          ),
        ),
      );
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al generar PDF: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _downloadExcel() async {
    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando Excel...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Preparar datos
      final data = await _prepareExportData();
      
      // Cerrar indicador de carga
      if (!mounted) return;
      Navigator.pop(context);
      
      // Generar Excel
      final filePath = await CultSummaryExportService.exportToExcel(
        cult: widget.cult,
        timeSlots: data['timeSlots'],
        rolesData: data['rolesData'],
        churchName: data['churchName'],
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excel descargado exitosamente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      filePath,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Abrir',
            textColor: Colors.white,
            onPressed: () {
              // Aquí podrías abrir el archivo si lo deseas
            },
          ),
        ),
      );
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al generar Excel: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  /// Prepara los datos necesarios para la exportación
  Future<Map<String, dynamic>> _prepareExportData() async {
    // Obtener nombre de la iglesia
    String churchName = 'Iglesia';
    try {
      final churchDoc = await FirebaseFirestore.instance
          .collection('churches')
          .doc(widget.cult.churchId)
          .get();
      if (churchDoc.exists) {
        churchName = churchDoc.data()?['name'] ?? 'Iglesia';
      }
    } catch (e) {
      debugPrint('Error obteniendo nombre de iglesia: $e');
    }
    
    // Obtener todos los time slots
    final timeSlotsSnapshot = await FirebaseFirestore.instance
        .collection('time_slots')
        .where('entityId', isEqualTo: widget.cult.id)
        .where('entityType', isEqualTo: 'cult')
        .where('isActive', isEqualTo: true)
        .get();
    
    final timeSlots = timeSlotsSnapshot.docs
        .map((doc) => TimeSlot.fromFirestore(doc))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Para cada time slot, obtener roles y asignaciones
    final Map<String, List<Map<String, dynamic>>> rolesData = {};
    
    for (final timeSlot in timeSlots) {
      final rolesSnapshot = await FirebaseFirestore.instance
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlot.id)
          .where('isActive', isEqualTo: true)
          .get();
      
      final roles = <Map<String, dynamic>>[];
      
      for (final roleDoc in rolesSnapshot.docs) {
        final roleData = roleDoc.data();
        final roleId = roleDoc.id;
        final roleName = roleData['role'] as String;
        final capacity = roleData['capacity'] as int? ?? 1;
        final ministryName = roleData['ministryName'] as String?;
        
        // Obtener asignaciones para este rol
        final assignmentsSnapshot = await FirebaseFirestore.instance
            .collection('work_assignments')
            .where('availableRoleId', isEqualTo: roleId)
            .get();
        
        final assignments = <Map<String, dynamic>>[];
        
        for (final assignDoc in assignmentsSnapshot.docs) {
          final assignData = assignDoc.data();
          final userId = assignData['userId'] as String;
          final status = assignData['status'] as String;
          
          // Obtener nombre del usuario
          String userName = 'Usuario';
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              userName = userDoc.data()?['name'] ?? 'Usuario';
            }
          } catch (e) {
            debugPrint('Error obteniendo usuario: $e');
          }
          
          assignments.add({
            'userName': userName,
            'status': status,
          });
        }
        
        roles.add({
          'roleName': roleName,
          'ministryName': ministryName,
          'capacity': capacity,
          'assignments': assignments,
        });
      }
      
      rolesData[timeSlot.id] = roles;
    }
    
    return {
      'timeSlots': timeSlots,
      'rolesData': rolesData,
      'churchName': churchName,
    };
  }
}

