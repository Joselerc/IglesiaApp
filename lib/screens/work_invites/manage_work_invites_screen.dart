import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/work_invite.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'work_invite_detail_screen.dart';

// Clase para agrupar invitaciones
class InviteGroup {
  final String timeSlotId;
  final String ministryId;
  final String ministryName;
  final String role;
  final String entityName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final List<WorkInvite> invites;
  
  InviteGroup({
    required this.timeSlotId,
    required this.ministryId,
    required this.ministryName,
    required this.role,
    required this.entityName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.invites,
  });
  
  int get acceptedCount => invites.where((i) => i.status == 'accepted').length;
  bool get isFull => acceptedCount >= capacity;
  
  String getGroupKey() => '$timeSlotId-$ministryId-$role';
}

class ManageWorkInvitesScreen extends StatefulWidget {
  const ManageWorkInvitesScreen({super.key});

  @override
  State<ManageWorkInvitesScreen> createState() => _ManageWorkInvitesScreenState();
}

class _ManageWorkInvitesScreenState extends State<ManageWorkInvitesScreen> {
  String _selectedFilter = 'all';
  String _sortOrder = 'desc'; // desc = más reciente primero
  String _searchQuery = ''; // Query de búsqueda de título
  DateTimeRange? _selectedDateRange; // Rango de fechas seleccionado para filtrar
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _usersCache = {}; // Caché de usuarios
  final Map<String, String> _cultsCache = {}; // Caché de nombres de cultos
  Set<String> _loadedInviteIds = {}; // Para rastrear qué invitaciones ya procesamos
  Timer? _debounceTimer; // Timer para debouncing de búsqueda

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.manageSchedules),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.userNotAuthenticated),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.manageSchedules,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          // Botón para cambiar orden
          IconButton(
            icon: Icon(_sortOrder == 'desc' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
            tooltip: _sortOrder == 'desc' 
              ? AppLocalizations.of(context)!.newestFirst
              : AppLocalizations.of(context)!.oldestFirst,
            onPressed: () {
              setState(() {
                _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filtros con mejor diseño
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.all,
                    value: 'all',
                    icon: Icons.view_list_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.pending,
                    value: 'pending',
                    icon: Icons.schedule_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.accepted,
                    value: 'accepted',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: AppLocalizations.of(context)!.rejected,
                    value: 'rejected',
                    icon: Icons.cancel_rounded,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // Buscadores (Título y Fecha)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                // Campo de búsqueda por título
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // Cancelar el timer anterior si existe
                      _debounceTimer?.cancel();
                      
                      // Crear un nuevo timer para esperar 400ms antes de actualizar
                      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                        if (mounted) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchByTitle,
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
                      suffixIcon: _searchQuery.isNotEmpty || _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600),
                              onPressed: () {
                                _debounceTimer?.cancel();
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Selector de rango de fechas
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: _selectedDateRange,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        locale: const Locale('es', 'ES'),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDateRange = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: _selectedDateRange != null
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: _selectedDateRange != null 
                                ? AppColors.primary 
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                                  : AppLocalizations.of(context)!.dateLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedDateRange != null 
                                    ? Colors.black87 
                                    : Colors.grey.shade600,
                                fontWeight: _selectedDateRange != null 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedDateRange != null)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDateRange = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de invitaciones agrupadas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('work_invites')
                  .where('sentBy', isEqualTo: FirebaseFirestore.instance.collection('users').doc(currentUser.uid))
                  .orderBy('createdAt', descending: _sortOrder == 'desc')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final allInvites = snapshot.data!.docs
                    .map((doc) => WorkInvite.fromFirestore(doc))
                    .toList();

                // Pre-cargar datos de usuarios en segundo plano (sin bloquear)
                _preloadUserData(allInvites);

                // Cargar nombres de cultos ANTES de agrupar (solo la primera vez)
                return FutureBuilder<void>(
                  future: _preloadCultNames(allInvites),
                  builder: (context, cultSnapshot) {
                    // Mientras se cargan los nombres de cultos, mostrar loading (muy rápido)
                    if (cultSnapshot.connectionState == ConnectionState.waiting && _cultsCache.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Agrupar invitaciones (carga instantánea)
                    List<InviteGroup> groups = _groupInvites(allInvites);

                    // Aplicar filtro de estado
                    if (_selectedFilter != 'all') {
                      groups = groups.where((group) {
                        return group.invites.any((invite) => invite.status == _selectedFilter);
                      }).toList();
                    }

                    // Aplicar búsqueda por título
                    if (_searchQuery.isNotEmpty) {
                      groups = groups.where((group) {
                        final cultName = group.entityName.toLowerCase();
                        final searchWords = _searchQuery.split(' ').where((w) => w.isNotEmpty);
                        // Todas las palabras del título deben coincidir
                        return searchWords.every((word) => cultName.contains(word));
                      }).toList();
                    }

                    // Aplicar filtro por rango de fechas
                    if (_selectedDateRange != null) {
                      groups = groups.where((group) {
                        // Normalizar fechas a medianoche para comparación correcta
                        final groupDate = DateTime(group.date.year, group.date.month, group.date.day);
                        final startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                        final endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
                        
                        // La fecha del grupo debe estar dentro del rango (inclusivo)
                        return (groupDate.isAfter(startDate) || groupDate.isAtSameMomentAs(startDate)) &&
                               (groupDate.isBefore(endDate) || groupDate.isAtSameMomentAs(endDate));
                      }).toList();
                    }

                    if (groups.isEmpty) {
                      return _buildEmptyFilterState();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: groups.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return RepaintBoundary(
                          child: _buildGroupCard(group),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _preloadUserData(List<WorkInvite> invites) {
    // Crear un Set de IDs actuales para comparar
    final currentInviteIds = invites.map((i) => i.id).toSet();
    
    // Solo procesar si hay invitaciones nuevas
    if (currentInviteIds.difference(_loadedInviteIds).isEmpty) {
      return; // Ya se procesaron todas estas invitaciones
    }
    
    // Actualizar el Set de invitaciones procesadas
    _loadedInviteIds = currentInviteIds;
    
    final userIds = invites.map((i) => i.userId).toSet();
    
    // Cargar solo usuarios que no están en caché
    final missingUserIds = userIds.where((id) => !_usersCache.containsKey(id)).toList();
    
    if (missingUserIds.isEmpty) return;

    // Cargar en segundo plano sin bloquear el UI y SIN setState
    Future.wait(
      missingUserIds.map((userId) => 
        FirebaseFirestore.instance.collection('users').doc(userId).get()
      ),
    ).then((userDocs) {
      if (mounted) {
        // Solo guardar en caché, NO llamar setState
        for (final doc in userDocs) {
          if (doc.exists) {
            _usersCache[doc.id] = doc.data() as Map<String, dynamic>;
          }
        }
      }
    }).catchError((e) {
      debugPrint('Error pre-cargando usuarios: $e');
    });
  }

  Future<void> _preloadCultNames(List<WorkInvite> invites) async {
    final cultIds = invites.map((i) => i.entityId).toSet();
    
    // Cargar solo cultos que no están en caché
    final missingCultIds = cultIds.where((id) => !_cultsCache.containsKey(id)).toList();
    
    if (missingCultIds.isEmpty) {
      return;
    }

    try {
      // Cargar todos los cultos necesarios
      final cultDocs = await Future.wait(
        missingCultIds.map((cultId) => 
          FirebaseFirestore.instance.collection('cults').doc(cultId).get()
        ),
      );
      
      if (mounted) {
        // Guardar en caché
        for (final doc in cultDocs) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            _cultsCache[doc.id] = data['name'] as String? ?? 'Culto';
          }
        }
      }
    } catch (e) {
      debugPrint('Error pre-cargando cultos: $e');
    }
  }

  List<InviteGroup> _groupInvites(List<WorkInvite> invites) {
    final Map<String, List<WorkInvite>> groupMap = {};

    // Agrupar por clave (date + time + ministry + role para agrupar correctamente)
    for (final invite in invites) {
      final dateKey = DateFormat('yyyy-MM-dd-HHmm').format(invite.startTime);
      final key = '$dateKey-${invite.entityId}-${invite.ministryId}-${invite.role}';
      
      if (!groupMap.containsKey(key)) {
        groupMap[key] = [];
      }
      groupMap[key]!.add(invite);
    }

    // Crear grupos sin queries adicionales (carga instantánea)
    final List<InviteGroup> groups = [];
    
    for (final entry in groupMap.entries) {
      final inviteList = entry.value;
      final firstInvite = inviteList.first;

      // Inferir capacidad: número de aceptados + pendientes (mínimo)
      final acceptedCount = inviteList.where((i) => i.status == 'accepted').length;
      final pendingCount = inviteList.where((i) => i.status == 'pending').length;
      final capacity = acceptedCount > 0 ? acceptedCount : (pendingCount > 0 ? pendingCount : inviteList.length);

      // Obtener el nombre del culto desde el caché o usar el de la invitación
      final cultName = _cultsCache[firstInvite.entityId] ?? firstInvite.entityName;
      
      groups.add(InviteGroup(
        timeSlotId: '', // No necesario para la visualización
        ministryId: firstInvite.ministryId,
        ministryName: firstInvite.ministryName,
        role: firstInvite.role,
        entityName: cultName.isNotEmpty ? cultName : 'Culto',
        date: firstInvite.date,
        startTime: firstInvite.startTime,
        endTime: firstInvite.endTime,
        capacity: capacity,
        invites: inviteList,
      ));
    }

    // Ordenar por fecha según _sortOrder
    groups.sort((a, b) {
      final aDate = a.invites.first.createdAt;
      final bDate = b.invites.first.createdAt;
      return _sortOrder == 'desc' 
        ? bDate.compareTo(aDate) // Más reciente primero
        : aDate.compareTo(bDate); // Más antiguo primero
    });

    return groups;
  }

  Widget _buildGroupCard(InviteGroup group) {
    return _InviteGroupCard(
      group: group,
      usersCache: _usersCache,
      selectedFilter: _selectedFilter,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final isSelected = _selectedFilter == value;
    final chipColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : chipColor.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget separado con su propio estado para evitar rebuild de toda la lista
class _InviteGroupCard extends StatefulWidget {
  final InviteGroup group;
  final Map<String, Map<String, dynamic>> usersCache;
  final String selectedFilter;

  const _InviteGroupCard({
    required this.group,
    required this.usersCache,
    required this.selectedFilter,
  });

  @override
  State<_InviteGroupCard> createState() => _InviteGroupCardState();
}

class _InviteGroupCardState extends State<_InviteGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final groupKey = widget.group.getGroupKey();
    final acceptedCount = widget.group.acceptedCount;
    final isFull = widget.group.isFull;
    
    // Contar invitaciones pendientes (para el badge)
    final pendingCount = widget.group.invites.where((invite) => invite.status == 'pending').length;

    return Card(
      key: ValueKey(groupKey),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFull ? Colors.green.shade200 : Colors.grey.shade200,
          width: isFull ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del grupo
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFull ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.church_rounded,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.group.entityName.isNotEmpty ? widget.group.entityName : 'Culto',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_rounded,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.group.ministryName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.group.role,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          // Badge de capacidad
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isFull ? Colors.green.shade600 : Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$acceptedCount/${widget.group.capacity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isFull ? AppLocalizations.of(context)!.completeBadge : AppLocalizations.of(context)!.acceptedPlural,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Badge de invitaciones pendientes
                          if (pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$pendingCount',
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fecha y horario
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          DateFormat('dd/MM/yyyy', 'es').format(widget.group.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${DateFormat('HH:mm').format(widget.group.startTime)} - ${DateFormat('HH:mm').format(widget.group.endTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lista de invitaciones (expandible con animación)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        ...widget.group.invites
                            .where((invite) => 
                              widget.selectedFilter == 'all' || invite.status == widget.selectedFilter
                            )
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final invite = entry.value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index > 0) const SizedBox(height: 8),
                              _buildCompactInviteItem(invite, isFull),
                            ],
                          );
                        }),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInviteItem(WorkInvite invite, bool positionFilled) {
    // Obtener datos del usuario del caché (sin parpadeo)
    final userData = widget.usersCache[invite.userId];
    final userName = userData != null 
        ? (userData['displayName'] ?? '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim())
        : 'Usuario';
    final photoUrl = userData?['photoUrl'] as String?;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkInviteDetailScreen(invite: invite),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar y nombre del usuario (desde caché)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getStatusColor(invite.status).withOpacity(0.1),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(Icons.person_rounded, color: _getStatusColor(invite.status), size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(invite.status, isCompact: true),
                // Indicador si el puesto ya está cubierto y esta invitación ya no es necesaria
                if (positionFilled && invite.status != 'accepted')
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: AppLocalizations.of(context)!.positionAlreadyFilled,
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Fecha de envío
            Row(
              children: [
                Icon(Icons.send_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${AppLocalizations.of(context)!.sentColon} ${DateFormat('dd/MM/yy HH:mm').format(invite.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, {bool isCompact = false}) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 14 : 16, color: color),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      case 'pending':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return AppLocalizations.of(context)!.accepted;
      case 'rejected':
        return AppLocalizations.of(context)!.rejected;
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      default:
        return status;
    }
  }
}

// Métodos auxiliares para el estado principal
extension _ManageWorkInvitesScreenStateHelper on _ManageWorkInvitesScreenState {
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.errorLoadingInvitations,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noInvitationsSent,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.invitationsWillAppearHere,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    final hasFilters = _searchQuery.isNotEmpty || _selectedDateRange != null;
    final icon = hasFilters ? Icons.search_off_rounded : Icons.filter_alt_off_rounded;
    
    String message = AppLocalizations.of(context)!.noInvitationsWithThisFilter;
    if (hasFilters) {
      final filters = <String>[];
      if (_searchQuery.isNotEmpty) filters.add('"$_searchQuery"');
      if (_selectedDateRange != null) {
        final dateRangeStr = '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}';
        filters.add(dateRangeStr);
      }
      message = AppLocalizations.of(context)!.noResultsFor(filters.join(' y '));
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.tryOtherTermsOrDate,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
