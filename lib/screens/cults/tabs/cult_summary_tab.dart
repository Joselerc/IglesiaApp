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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Fila compacta: Descarga + Vista
          Row(
            children: [
              // Icono de descarga sutil
              IconButton(
                onPressed: _showDownloadOptions,
                icon: const Icon(Icons.download_rounded, size: 20),
                tooltip: AppLocalizations.of(context)!.downloadSummary,
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              // Label Vista
              Text(
                'Vista:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              // Toggle compacto con mejor contraste
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.view_headline_rounded, size: 16),
                    tooltip: AppLocalizations.of(context)!.compact,
                  ),
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.view_list_rounded, size: 16),
                    tooltip: AppLocalizations.of(context)!.detailed,
                  ),
                ],
                selected: {_isCompactView},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isCompactView = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).colorScheme.primary;
                      }
                      return Theme.of(context).colorScheme.surfaceVariant;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return Theme.of(context).colorScheme.onSurfaceVariant;
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Filtros tipo chips modernos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', AppLocalizations.of(context)!.all, Icons.grid_view_rounded),
                const SizedBox(width: 6),
                _buildFilterChip('pending', AppLocalizations.of(context)!.pending, Icons.schedule_rounded),
                const SizedBox(width: 6),
                _buildFilterChip('accepted', AppLocalizations.of(context)!.accepted, Icons.check_circle_rounded),
                const SizedBox(width: 6),
                _buildFilterChip('rejected', AppLocalizations.of(context)!.rejected, Icons.cancel_rounded),
                const SizedBox(width: 6),
                _buildFilterChip('vacant', AppLocalizations.of(context)!.filterVacant, Icons.person_off_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected 
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeSlotSection(TimeSlot timeSlot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera minimalista
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeSlot.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${DateFormat('HH:mm').format(timeSlot.startTime)} - ${DateFormat('HH:mm').format(timeSlot.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                final roleName = data['role'] ?? '';
                final capacity = data['capacity'] ?? 1;
                
                // Filtrar roles vacíos o con capacidad 0
                if (roleName.isEmpty || capacity == 0) {
                  continue;
                }
                
                final ministryName = data['ministryName'] ?? AppLocalizations.of(context)!.noMinistry;
                
                if (!rolesByMinistry.containsKey(ministryName)) {
                  rolesByMinistry[ministryName] = [];
                }
                
                rolesByMinistry[ministryName]!.add({
                  'id': doc.id,
                  'role': roleName,
                  'capacity': capacity,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre minimalista
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(
                  Icons.groups_2_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  ministryName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
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
    // No mostrar si el rol está vacío o la capacidad es 0
    if (role.isEmpty || capacity == 0) {
      return const SizedBox.shrink();
    }
    
    final int filled = assignments.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      return status == 'accepted';
    }).length;
    
    final bool isComplete = filled >= capacity;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: isComplete 
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              role,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isComplete 
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isComplete 
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            child: Text(
              '$filled/$capacity',
              style: TextStyle(
                color: isComplete 
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD32F2F),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailedRoleView(String role, int capacity, List<QueryDocumentSnapshot> assignments) {
    // No mostrar si el rol está vacío o la capacidad es 0
    if (role.isEmpty || capacity == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del rol - más sutil
          Row(
            children: [
              Expanded(
                child: Text(
                  role,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${assignments.where((d) => (d.data() as Map)['status'] == 'accepted').length}/$capacity',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Lista de personas
          ...List.generate(capacity, (index) {
            if (index < assignments.length) {
              return _buildPersonAssignment(assignments[index]);
            } else {
              return Padding(
                padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 12,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.unassigned,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
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
          padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
          child: Row(
            children: [
              Icon(
                status == 'accepted' ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 12,
                color: status == 'accepted' 
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
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
    Color textColor;
    String displayText;
    
    switch (status) {
      case 'accepted':
        textColor = Theme.of(context).colorScheme.tertiary;
        displayText = AppLocalizations.of(context)!.accepted;
        break;
      case 'pending':
        textColor = Theme.of(context).colorScheme.primary.withOpacity(0.7);
        displayText = AppLocalizations.of(context)!.pending;
        break;
      case 'rejected':
        textColor = Theme.of(context).colorScheme.error;
        displayText = AppLocalizations.of(context)!.rejected;
        break;
      case 'vacant':
      default:
        textColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6);
        displayText = label;
    }
    
    return Text(
      displayText,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
        fontSize: 10,
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
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.generatingPDF),
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
                    Text(
                      AppLocalizations.of(context)!.pdfDownloadedSuccessfully,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
            label: AppLocalizations.of(context)!.openFile,
            textColor: Colors.white,
            onPressed: () {
              CultSummaryExportService.openFile(filePath);
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
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.generatingExcel),
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
                    Text(
                      AppLocalizations.of(context)!.excelDownloadedSuccessfully,
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
            label: AppLocalizations.of(context)!.openFile,
            textColor: Colors.white,
            onPressed: () {
              CultSummaryExportService.openFile(filePath);
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




