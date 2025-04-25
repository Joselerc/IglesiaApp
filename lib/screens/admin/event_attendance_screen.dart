import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/event_attendance_service.dart';
import '../../models/event_attendance.dart';
import '../../theme/app_colors.dart';

class EventAttendanceScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String entityId;
  final String entityType;

  const EventAttendanceScreen({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.entityId,
    required this.entityType,
  }) : super(key: key);

  @override
  State<EventAttendanceScreen> createState() => _EventAttendanceScreenState();
}

class _EventAttendanceScreenState extends State<EventAttendanceScreen> {
  final EventAttendanceService _attendanceService = EventAttendanceService();
  bool _isLoading = true;
  bool _isAttendanceLoading = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _confirmedAttendees = [];
  List<Map<String, dynamic>> _allMembers = [];
  List<EventAttendance> _attendance = [];

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cargar miembros potenciales (se mantiene igual por ahora)
      final potentialAttendees = await _attendanceService.getPotentialAttendees(
        entityId: widget.entityId,
        entityType: widget.entityType,
        eventId: widget.eventId,
      );
      
      // 2. Obtener IDs de asistentes confirmados desde 'event_attendees'
      final attendeesSnapshot = await FirebaseFirestore.instance
          .collection('event_attendees')
          .where('eventId', isEqualTo: widget.eventId)
          .where('eventType', isEqualTo: widget.entityType)
          .where('attending', isEqualTo: true)
          .get();
      
      // Extraer solo los IDs de usuario
      final List<String> confirmedUserIds = attendeesSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
          
      // 3. Obtener datos de los usuarios confirmados en una sola consulta (Optimización)
      Map<String, Map<String, dynamic>> usersDataMap = {};
      if (confirmedUserIds.isNotEmpty) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: confirmedUserIds)
            .get();

        for (var userDoc in usersSnapshot.docs) {
          usersDataMap[userDoc.id] = userDoc.data();
        }
      }
      
      // 4. Construir la lista de asistentes confirmados con los datos obtenidos
      List<Map<String, dynamic>> confirmedAttendeesList = [];
      for (String userId in confirmedUserIds) {
        final userData = usersDataMap[userId];
        if (userData != null) {
          confirmedAttendeesList.add({
            'id': userId,
            'name': userData['displayName'] ?? 'Usuário',
            'photoUrl': userData['photoUrl'] ?? '',
            'isConfirmed': true,
          });
        }
      }
      
      // 5. Cargar registros de asistencia existentes (Stream)
      _attendanceService.getEventAttendance(widget.eventId).listen((attendanceList) {
        if (mounted) {
          setState(() {
            _attendance = attendanceList;
          });
        }
      });
      
      setState(() {
        _confirmedAttendees = confirmedAttendeesList;
        _allMembers = potentialAttendees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAttendance(String userId, bool attended) async {
    setState(() {
      _isAttendanceLoading = true;
    });

    try {
      await _attendanceService.markAttendance(
        eventId: widget.eventId,
        userId: userId,
        eventType: widget.entityType,
        entityId: widget.entityId,
        attended: attended,
      );
      
      setState(() {
        _isAttendanceLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attended
                ? 'Presença registrada com sucesso'
                : 'Ausência registrada com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAttendanceLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar presença: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddAttendeeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppColors.surface,
      builder: (context) => AddAttendeeModal(
        eventId: widget.eventId,
        entityId: widget.entityId,
        entityType: widget.entityType,
        onAttendeeAdded: _loadEventData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMinistry = widget.entityType == 'ministry';
    const primaryColor = AppColors.primary;
    
    List<Map<String, dynamic>> displayMembers = _allMembers;
    
    if (_searchQuery.isNotEmpty) {
      displayMembers = _allMembers
          .where((member) => member['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Presença - ${widget.eventTitle}'),
        backgroundColor: primaryColor,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEventData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar participantes',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.mutedGray.withOpacity(0.1),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Estadísticas rápidas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Confirmados',
                        _confirmedAttendees.length.toString(),
                        Icons.event_available,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'Presentes',
                        _attendance.where((a) => a.attended).length.toString(),
                        Icons.check_circle,
                        AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        'Ausentes',
                        _attendance.where((a) => !a.attended).length.toString(),
                        Icons.cancel,
                        AppColors.error,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Título de la sección
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gerenciar Presença',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddAttendeeModal,
                        icon: const Icon(Icons.person_add, color: AppColors.textOnDark),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de miembros
                Expanded(
                  child: displayMembers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.mutedGray,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhum membro encontrado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: displayMembers.length,
                          itemBuilder: (context, index) {
                            final member = displayMembers[index];
                            final userId = member['id'];
                            
                            // Buscar registro de asistencia
                            final attendanceRecord = _attendance.firstWhere(
                              (a) => a.userId == userId,
                              orElse: () => EventAttendance(
                                id: '',
                                eventId: widget.eventId,
                                userId: userId,
                                eventType: widget.entityType,
                                entityId: widget.entityId,
                                attended: false,
                                verificationDate: DateTime.now(),
                                verifiedBy: '',
                                wasExpected: _confirmedAttendees.any((a) => a['id'] == userId),
                              ),
                            );
                            
                            // Verificar si está confirmado
                            final isConfirmed = _confirmedAttendees.any((a) => a['id'] == userId);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: member['photoUrl'] != null && member['photoUrl'].isNotEmpty
                                      ? NetworkImage(member['photoUrl'])
                                      : null,
                                  child: member['photoUrl'] == null || member['photoUrl'].isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  member['name'], 
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Wrap(
                                  spacing: 4,
                                  children: [
                                    if (isConfirmed)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.event_available, size: 10, color: AppColors.primary),
                                            const SizedBox(width: 2),
                                            Text(
                                              'Confirmado',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (attendanceRecord.id.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: attendanceRecord.attended ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              attendanceRecord.attended ? Icons.check : Icons.close,
                                              size: 10,
                                              color: attendanceRecord.attended ? AppColors.success : AppColors.error,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              attendanceRecord.attended ? 'Presente' : 'Ausente',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: attendanceRecord.attended ? AppColors.success : AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: 80, // Ancho fijo para los botones
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _isAttendanceLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primaryColor,
                                              ),
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.check_circle, size: 22), // Reducir tamaño
                                              padding: EdgeInsets.zero, // Eliminar padding
                                              visualDensity: VisualDensity.compact, // Más compacto
                                              color: attendanceRecord.attended ? AppColors.success : AppColors.mutedGray,
                                              onPressed: () => _markAttendance(userId, true),
                                              constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36), // Limitar tamaño
                                            ),
                                      _isAttendanceLoading
                                          ? const SizedBox(width: 24)
                                          : IconButton(
                                              icon: const Icon(Icons.cancel, size: 22), // Reducir tamaño
                                              padding: EdgeInsets.zero, // Eliminar padding
                                              visualDensity: VisualDensity.compact, // Más compacto
                                              color: !attendanceRecord.attended && attendanceRecord.id.isNotEmpty
                                                  ? AppColors.error
                                                  : AppColors.mutedGray,
                                              onPressed: () => _markAttendance(userId, false),
                                              constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36), // Limitar tamaño
                                            ),
                                    ],
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Reducir padding
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.mutedGray.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modal para añadir asistentes
class AddAttendeeModal extends StatefulWidget {
  final String eventId;
  final String entityId;
  final String entityType;
  final VoidCallback onAttendeeAdded;

  const AddAttendeeModal({
    Key? key,
    required this.eventId,
    required this.entityId,
    required this.entityType,
    required this.onAttendeeAdded,
  }) : super(key: key);

  @override
  State<AddAttendeeModal> createState() => _AddAttendeeModalState();
}

class _AddAttendeeModalState extends State<AddAttendeeModal> {
  final TextEditingController _searchController = TextEditingController();
  final EventAttendanceService _attendanceService = EventAttendanceService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Cargar usuarios recientes automáticamente
    _loadRecentUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  // Carregar alguns usuários recentes para mostrar
  // inicialmente (mostra até 10 usuários)
  Future<void> _loadRecentUsers() async {
    setState(() {
      _isSearching = true;
    });

    try {
      // Cargar usuarios recientes de Firestore (os 10 mais recentes)
      final results = await _attendanceService.getRecentUsers(10);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar usuários: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.length >= 2) {  // Reducimos a 2 caracteres mínimos
      _performSearch(_searchController.text);
    } else if (_searchController.text.isEmpty) {
      // Se o campo estiver vazio, mostrar usuários recentes
      _loadRecentUsers();
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _attendanceService.searchUsers(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar usuários: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _addAttendee(String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Marcar asistencia para o usuário
      await _attendanceService.markAttendance(
        eventId: widget.eventId,
        userId: userId,
        eventType: widget.entityType,
        entityId: widget.entityId,
        attended: true,
        wasExpected: false, // Não estava na lista original
      );

      widget.onAttendeeAdded();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Participante adicionado com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar participante: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: mediaQuery.viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Adicionar Participante',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar usuário por nome',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.mutedGray.withOpacity(0.1),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _loadRecentUsers();
                    },
                  )
                : null,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_searchController.text.isNotEmpty && _searchController.text.length < 2)
            const Center(
              child: Text(
                'Digite pelo menos 2 caracteres para buscar',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.mutedGray,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum resultado encontrado',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tente com outro nome ou sobrenome',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searchController.text.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Usuários recentes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                                ? NetworkImage(user['photoUrl'])
                                : null,
                            child: user['photoUrl'] == null || user['photoUrl'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add_circle),
                                  color: AppColors.success,
                                  onPressed: () => _addAttendee(user['id']),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 