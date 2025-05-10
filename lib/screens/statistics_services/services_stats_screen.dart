import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_stats.dart';
import '../../services/user_stats_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';

class ServicesStatsScreen extends StatefulWidget {
  const ServicesStatsScreen({Key? key}) : super(key: key);

  @override
  State<ServicesStatsScreen> createState() => _ServicesStatsScreenState();
}

class _ServicesStatsScreenState extends State<ServicesStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = true;
  
  // Variables para controlar el estado de carga de cada pestaña
  bool _servicesLoaded = false;
  bool _usersLoaded = false;
  
  // Filtros de fecha
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  String _localServiceSearchQuery = ''; // Para búsqueda en tiempo real de servicios
  List<Map<String, dynamic>> _filteredServices = []; // Lista filtrada para servicios
  bool _isDateFilterActive = false;
  
  // Estadísticas globales
  int _totalInvitations = 0;
  int _acceptedInvitations = 0;
  int _rejectedInvitations = 0;
  int _totalAttendances = 0;
  int _totalAbsences = 0;
  
  // Lista de servicios
  List<Map<String, dynamic>> _services = [];
  
  // Ordenación
  String _sortBy = 'name';
  bool _sortAscending = true;
  
  // Variables para el tab de usuarios
  final UserStatsService _userStatsService = UserStatsService();
  List<UserStats> _usersStats = [];
  List<UserStats> _filteredUsersStats = []; // Lista filtrada para la búsqueda
  List<Map<String, dynamic>> _availableMinistries = [];
  String _selectedMinistryId = 'all_ministries';
  String _selectedMinistryName = 'Todos os Ministérios';
  String _userSortBy = 'name';
  bool _userSortAscending = true;
  String _userSearchQuery = '';
  String _localSearchQuery = ''; // Para búsqueda en tiempo real local
  
  // Función para normalizar texto (eliminar tildes, minúsculas, etc.)
  String _normalizeText(String text) {
    // Convertir a minúsculas
    String normalized = text.toLowerCase();
    
    // Reemplazar caracteres acentuados
    final accentedChars = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n'
    };
    
    for (var entry in accentedChars.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    
    return normalized;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadStatistics();
    _loadMinistries();
    _loadUsersStats();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.index == 0) {
      // Solo recargamos los servicios si aún no están cargados
      if (!_servicesLoaded) {
        _loadStatistics();
      }
    } else if (_tabController.index == 1) {
      // Solo recargamos los usuarios si aún no están cargados
      if (!_usersLoaded) {
        _loadUsersStats();
      }
    }
  }
  
  Future<void> _loadMinistries() async {
    try {
      final ministries = await _userStatsService.getAvailableMinistries();
      setState(() {
        _availableMinistries = ministries;
      });
    } catch (e) {
      debugPrint('Error al cargar ministerios: $e');
    }
  }
  
  Future<void> _loadUsersStats() async {
    if (_usersLoaded && _usersStats.isNotEmpty) {
      // Si ya tenemos datos cargados, no mostramos el indicador de carga
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final stats = await _userStatsService.generateUserStats(
        ministryId: _selectedMinistryId,
        startDate: _startDate,
        endDate: _endDate,
        searchQuery: _userSearchQuery,
      );
      
      // Ordenar los resultados
      _sortUsersStats(stats);
      
      setState(() {
        _usersStats = stats;
        // Inicializar la lista filtrada con todos los usuarios
        _filteredUsersStats = List.from(stats);
        _isLoading = false;
        _usersLoaded = true; // Marcamos que los usuarios ya están cargados
        _localSearchQuery = ''; // Resetear la búsqueda local cuando se cargan nuevos datos
      });
    } catch (e) {
      debugPrint('Error al cargar estadísticas de usuarios: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _sortUsersStats(List<UserStats> stats) {
    switch (_userSortBy) {
      case 'name':
        stats.sort((a, b) => _userSortAscending
            ? a.userName.compareTo(b.userName)
            : b.userName.compareTo(a.userName));
        break;
      case 'totalInvitations':
        stats.sort((a, b) => _userSortAscending
            ? a.totalInvitations.compareTo(b.totalInvitations)
            : b.totalInvitations.compareTo(a.totalInvitations));
        break;
      case 'totalAttendances':
        stats.sort((a, b) => _userSortAscending
            ? a.totalAttendances.compareTo(b.totalAttendances)
            : b.totalAttendances.compareTo(a.totalAttendances));
        break;
      case 'totalAbsences':
        stats.sort((a, b) => _userSortAscending
            ? a.totalAbsences.compareTo(b.totalAbsences)
            : b.totalAbsences.compareTo(a.totalAbsences));
        break;
      case 'acceptedInvitations':
        stats.sort((a, b) => _userSortAscending
            ? a.acceptedInvitations.compareTo(b.acceptedInvitations)
            : b.acceptedInvitations.compareTo(a.acceptedInvitations));
        break;
      case 'rejectedInvitations':
        stats.sort((a, b) => _userSortAscending
            ? a.rejectedInvitations.compareTo(b.rejectedInvitations)
            : b.rejectedInvitations.compareTo(a.rejectedInvitations));
        break;
      case 'pendingInvitations':
        stats.sort((a, b) => _userSortAscending
            ? a.pendingInvitations.compareTo(b.pendingInvitations)
            : b.pendingInvitations.compareTo(a.pendingInvitations));
        break;
    }
  }
  
  void _changeUserSortOrder(String sortBy) {
    setState(() {
      if (_userSortBy == sortBy) {
        _userSortAscending = !_userSortAscending;
      } else {
        _userSortBy = sortBy;
        _userSortAscending = false; // Por defecto, descendente
      }
      
      // Ordenar tanto la lista completa como la filtrada
      _sortUsersStats(_usersStats);
      _sortUsersStats(_filteredUsersStats);
    });
  }
  
  void _selectMinistry(String ministryId, String ministryName) {
    setState(() {
      _selectedMinistryId = ministryId;
      _selectedMinistryName = ministryName;
      _usersLoaded = false; // Marcar que necesitamos recargar
    });
    _loadUsersStats();
  }
  
  // Función original para búsqueda del servidor
  void _searchUsers(String query) {
    setState(() {
      _userSearchQuery = query;
      _usersLoaded = false; // Marcar que necesitamos recargar
    });
    _loadUsersStats();
  }
  
  // Función para búsqueda en tiempo real local
  void _filterUsersLocally(String query) {
    setState(() {
      _localSearchQuery = query;
      
      if (query.isEmpty) {
        // Si no hay consulta, mostrar todos los usuarios cargados
        _filteredUsersStats = List.from(_usersStats);
      } else {
        // Normalizar la consulta de búsqueda
        final normalizedQuery = _normalizeText(query);
        
        // Filtrar la lista local según la consulta normalizada
        _filteredUsersStats = _usersStats.where((user) {
          // Normalizar el nombre del usuario
          final normalizedName = _normalizeText(user.userName);
          return normalizedName.contains(normalizedQuery);
        }).toList();
        
        // Aplicar el ordenamiento actual
        _sortUsersStats(_filteredUsersStats);
      }
    });
  }

  Future<void> _loadStatistics() async {
    if (_servicesLoaded && _services.isNotEmpty) {
      // Si ya tenemos datos cargados, no mostramos el indicador de carga
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Variables para estadísticas globales
      int totalInvitations = 0;
      int acceptedInvitations = 0;
      int rejectedInvitations = 0;
      int totalAttendances = 0;
      int totalAbsences = 0;
      
      // Obtener todos los servicios de una sola vez
      var servicesQuery = FirebaseFirestore.instance.collection('services');
      final servicesSnapshot = await servicesQuery.get();
      
      List<Map<String, dynamic>> services = [];
      List<Future> processingFutures = []; // Lista para procesar servicios en paralelo
      
      // Crear un mapa para almacenar resultados procesados
      Map<String, Map<String, dynamic>> processedServices = {};
      
      // Primera pasada: procesar servicios y preparar IDs para consultas en lote
      for (var doc in servicesSnapshot.docs) {
        final serviceData = doc.data();
        final serviceId = doc.id;
        
        // Inicializar el servicio con datos básicos
        processedServices[serviceId] = {
          'id': serviceId,
          'name': serviceData['name'] ?? 'Servicio sin nombre',
          'description': serviceData['description'] ?? '',
          'createdAt': (serviceData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'totalInvitations': 0,
          'acceptedInvitations': 0,
          'rejectedInvitations': 0,
          'totalAttendances': 0,
          'totalAbsences': 0,
          'cultsCount': 0,
          'timeSlotIds': <String>[],
        };
        
        // Añadir futuro para procesar este servicio en paralelo
        processingFutures.add(
          _processServiceStatistics(serviceId, processedServices[serviceId]!)
        );
      }
      
      // Esperar a que todos los servicios se procesen en paralelo
      await Future.wait(processingFutures);
      
      // Convertir el mapa a lista y calcular totales
      services = processedServices.values.toList();
      
      // Calcular totales
      for (var service in services) {
        totalInvitations += service['totalInvitations'] as int;
        acceptedInvitations += service['acceptedInvitations'] as int;
        rejectedInvitations += service['rejectedInvitations'] as int;
        totalAttendances += service['totalAttendances'] as int;
        totalAbsences += service['totalAbsences'] as int;
      }
      
      // Ordenar servicios
      _sortServices(services);
      
      // Actualizar estado
      setState(() {
        _totalInvitations = totalInvitations;
        _acceptedInvitations = acceptedInvitations;
        _rejectedInvitations = rejectedInvitations;
        _totalAttendances = totalAttendances;
        _totalAbsences = totalAbsences;
        _services = services;
        _filteredServices = List.from(services); // Inicializar la lista filtrada
        _localServiceSearchQuery = ''; // Resetear la búsqueda local
        _isLoading = false;
        _servicesLoaded = true; // Marcamos que los servicios ya están cargados
      });
    } catch (e) {
      print('Error al cargar estadísticas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Método auxiliar para procesar las estadísticas de un servicio en paralelo
  Future<void> _processServiceStatistics(String serviceId, Map<String, dynamic> serviceData) async {
    try {
      // Obtener cultos para este servicio
      final cultsQuery = await FirebaseFirestore.instance
          .collection('cults')
          .where('serviceId', isEqualTo: FirebaseFirestore.instance.collection('services').doc(serviceId))
          .get();
      
      // Filtro de fecha directo en lugar de filtrar después de la consulta
      List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredCults = [];
      
      if (_isDateFilterActive && _startDate != null && _endDate != null) {
        // Filtrar manualmente para mayor precisión
        for (var cultDoc in cultsQuery.docs) {
          final cultData = cultDoc.data();
          final cultTimestamp = cultData['date'] as Timestamp?;
          
          if (cultTimestamp != null) {
            final cultDate = cultTimestamp.toDate();
            
            // Crear fechas de comparación con horas ajustadas
            final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
            
            // Incluir si la fecha del culto está en el rango (inclusivo)
            if (cultDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && 
                cultDate.isBefore(endOfDay.add(const Duration(seconds: 1)))) {
              filteredCults.add(cultDoc);
            }
          }
        }
        
        // Imprimir información de depuración
        debugPrint('Servicio $serviceId: ${cultsQuery.docs.length} cultos, ${filteredCults.length} después del filtro');
      } else {
        // Sin filtro de fecha, usar todos los cultos
        filteredCults = cultsQuery.docs;
      }
      
      // Actualizar conteo de cultos
      serviceData['cultsCount'] = filteredCults.length;
      
      if (filteredCults.isEmpty) return; // No hay cultos que procesar
      
      // Lista de IDs de cultos para consultas en lote
      final cultIds = filteredCults.map((cult) => cult.id).toList();
      
      // Consultas en paralelo para franjas horarias e invitaciones
      final timeSlotsF = _getTimeSlotsForCults(cultIds);
      final invitationsF = _getInvitationsForCults(cultIds);
      
      // Esperar resultados de consultas paralelas
      final results = await Future.wait([timeSlotsF, invitationsF]);
      
      final timeSlotIds = results[0] as List<String>;
      final invitationStats = results[1] as Map<String, int>;
      
      // Actualizar datos del servicio
      serviceData['timeSlotIds'] = timeSlotIds;
      serviceData['totalInvitations'] = invitationStats['total'] ?? 0;
      serviceData['acceptedInvitations'] = invitationStats['accepted'] ?? 0;
      serviceData['rejectedInvitations'] = invitationStats['rejected'] ?? 0;
      
      // Obtener asistencias para franjas horarias
      if (timeSlotIds.isNotEmpty) {
        final attendanceStats = await _getAttendanceForTimeSlots(timeSlotIds);
        serviceData['totalAttendances'] = attendanceStats['attended'] ?? 0;
        serviceData['totalAbsences'] = attendanceStats['absent'] ?? 0;
      }
    } catch (e) {
      print('Error procesando servicio $serviceId: $e');
    }
  }
  
  // Método para obtener todas las franjas horarias para una lista de cultos
  Future<List<String>> _getTimeSlotsForCults(List<String> cultIds) async {
    if (cultIds.isEmpty) return [];
    
    List<String> allTimeSlotIds = [];
    
    // Dividir en lotes si hay muchos cultos (limite de 10 para whereIn)
    for (int i = 0; i < cultIds.length; i += 10) {
      final end = (i + 10 < cultIds.length) ? i + 10 : cultIds.length;
      final batchIds = cultIds.sublist(i, end);
      
      final timeSlotsQuery = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('entityId', whereIn: batchIds)
          .where('entityType', isEqualTo: 'cult')
          .get();
      
      allTimeSlotIds.addAll(timeSlotsQuery.docs.map((doc) => doc.id).toList());
    }
    
    return allTimeSlotIds;
  }
  
  // Método para obtener estadísticas de invitaciones para una lista de cultos
  Future<Map<String, int>> _getInvitationsForCults(List<String> cultIds) async {
    if (cultIds.isEmpty) return {'total': 0, 'accepted': 0, 'rejected': 0};
    
    int totalInvitations = 0;
    int acceptedInvitations = 0;
    int rejectedInvitations = 0;
    
    // Dividir en lotes si hay muchos cultos (limite de 10 para whereIn)
    for (int i = 0; i < cultIds.length; i += 10) {
      final end = (i + 10 < cultIds.length) ? i + 10 : cultIds.length;
      final batchIds = cultIds.sublist(i, end);
      
      final invitationsQuery = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('entityId', whereIn: batchIds)
          .where('entityType', isEqualTo: 'cult')
          .get();
      
      totalInvitations += invitationsQuery.docs.length;
      
      // Contar aceptadas y rechazadas
      for (var inviteDoc in invitationsQuery.docs) {
        final inviteData = inviteDoc.data();
        if (inviteData['status'] == 'accepted' || inviteData['status'] == 'confirmed') {
          acceptedInvitations++;
        }
        if (inviteData['status'] == 'rejected' || inviteData['isRejected'] == true) {
          rejectedInvitations++;
        }
      }
    }
    
    return {
      'total': totalInvitations,
      'accepted': acceptedInvitations,
      'rejected': rejectedInvitations,
    };
  }
  
  // Método para obtener estadísticas de asistencia para una lista de franjas horarias
  Future<Map<String, int>> _getAttendanceForTimeSlots(List<String> timeSlotIds) async {
    if (timeSlotIds.isEmpty) return {'attended': 0, 'absent': 0};
    
    int totalAttendances = 0;
    int totalAbsences = 0;
    
    // Dividir en lotes si hay muchas franjas (limite de 10 para whereIn)
    for (int i = 0; i < timeSlotIds.length; i += 10) {
      final end = (i + 10 < timeSlotIds.length) ? i + 10 : timeSlotIds.length;
      final batchIds = timeSlotIds.sublist(i, end);
      
      final assignmentsQuery = await FirebaseFirestore.instance
          .collection('work_assignments')
          .where('timeSlotId', whereIn: batchIds)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Contar asistencias y ausencias
      for (var assignmentDoc in assignmentsQuery.docs) {
        final assignmentData = assignmentDoc.data();
        if (assignmentData['isAttendanceConfirmed'] == true) {
          totalAttendances++;
        }
        if (assignmentData['didNotAttend'] == true) {
          totalAbsences++;
        }
      }
    }
    
    return {
      'attended': totalAttendances,
      'absent': totalAbsences,
    };
  }
  
  void _sortServices(List<Map<String, dynamic>> services) {
    switch (_sortBy) {
      case 'name':
        services.sort((a, b) => _sortAscending
            ? a['name'].toString().compareTo(b['name'].toString())
            : b['name'].toString().compareTo(a['name'].toString()));
        break;
      case 'createdAt':
        services.sort((a, b) => _sortAscending
            ? a['createdAt'].compareTo(b['createdAt'])
            : b['createdAt'].compareTo(a['createdAt']));
        break;
      case 'invitations':
        services.sort((a, b) => _sortAscending
            ? a['totalInvitations'].compareTo(b['totalInvitations'])
            : b['totalInvitations'].compareTo(a['totalInvitations']));
        break;
    }
  }

  void _changeSortOrder(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortServices(_services);
    });
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
    });
    _loadStatistics();
  }

  // Método para limpiar filtro de fecha
  void _clearDateFilter() {
    _updateDateFilter(null, null);
  }
  
  // Método para cambiar el filtro de fecha y asegurarse de que se aplique correctamente
  void _updateDateFilter(DateTime? start, DateTime? end) {
    setState(() {
      _startDate = start;
      _endDate = end;
      _isDateFilterActive = (start != null || end != null);
      _servicesLoaded = false; // Forzar recarga de servicios
      _usersLoaded = false;   // Forzar recarga de usuarios
    });
    
    // Imprimir información de depuración
    debugPrint('Filtro de fecha actualizado: ${_startDate?.toString()} - ${_endDate?.toString()}, activo: $_isDateFilterActive');
    
    // Recargar datos con el nuevo filtro
    _loadStatistics();
    _loadUsersStats();
  }
  
  void _showSearchDialog() {
    final TextEditingController controller = TextEditingController(text: _searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Serviço'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do serviço',
            hintText: 'Ex: Culto Dominical',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = controller.text.trim();
                _servicesLoaded = false; // Marcar que necesitamos recargar
              });
              _loadStatistics();
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Función para normalizar texto en búsqueda de servicios
  void _filterServicesLocally(String query) {
    setState(() {
      _localServiceSearchQuery = query;
      
      if (query.isEmpty) {
        // Si no hay consulta, mostrar todos los servicios cargados
        _filteredServices = List.from(_services);
      } else {
        // Normalizar la consulta de búsqueda
        final normalizedQuery = _normalizeText(query);
        
        // Filtrar la lista local según la consulta normalizada
        _filteredServices = _services.where((service) {
          // Normalizar el nombre del servicio
          final normalizedName = _normalizeText(service['name'].toString());
          return normalizedName.contains(normalizedQuery);
        }).toList();
        
        // Aplicar el ordenamiento actual
        _sortServices(_filteredServices);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas de Escalas'),
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
        // Quitar el botón de búsqueda de la AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Escalas'),
            Tab(text: 'Usuários'),
          ],
        ),
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('view_schedule_stats'),
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
                    Text('Você não tem permissão para visualizar estatísticas de escalas.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          // Contenido original cuando tiene permiso
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Servicios
              _buildServicesTab(),
              
              // Tab 2: Usuarios
              _buildUsersTab(),
            ],
          );
        },
      ),
    );
  }
  
  // Tab de servicios
  Widget _buildServicesTab() {
    // Si estamos cambiando de pestaña y los datos ya están cargados, no mostramos el loader
    final showLoader = _isLoading && !_servicesLoaded;
    
    return showLoader
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Filtro de fecha (área fija)
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
                                    _updateDateFilter(selectedDate, _endDate);
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
                                    _updateDateFilter(_startDate, selectedDate);
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
              
              // Contenido desplazable (resumen global, opciones de ordenación y lista de servicios)
              Expanded(
                child: ListView(
                  children: [
                    // Barra de búsqueda en tiempo real para servicios
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar servicio...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: _localServiceSearchQuery.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _filterServicesLocally('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                        ),
                        onChanged: _filterServicesLocally,
                      ),
                    ),
                
                    // Resumo global
                    _buildSummaryCard(),
                    
                    // Ordenación
                    _buildSortOptions(),
                    
                    // Lista de servicios
                    _filteredServices.isEmpty
                        ? SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum serviço encontrado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tente com outro filtro de busca',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredServices.length,
                            itemBuilder: (context, index) {
                              final service = _filteredServices[index];
                              
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
                                      service['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Creado: ${DateFormat('dd/MM/yyyy').format(service['createdAt'])}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${service['cultsCount']} cultos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (service['description'] != null && service['description'].isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 16),
                                                child: Text(
                                                  service['description'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            
                                            const Text(
                                              'Estatísticas',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Estadísticas de invitaciones
                                            _buildStatRow(
                                              'Convites enviados', 
                                              service['totalInvitations'], 
                                              Colors.blue,
                                              onTap: () => _showUsersList(service, 'invitations'),
                                            ),
                                            _buildStatRow(
                                              'Convites aceitos', 
                                              service['acceptedInvitations'], 
                                              Colors.green,
                                              onTap: () => _showUsersList(service, 'accepted'),
                                            ),
                                            _buildStatRow(
                                              'Convites rejeitados', 
                                              service['rejectedInvitations'], 
                                              Colors.red,
                                              onTap: () => _showUsersList(service, 'rejected'),
                                            ),
                                            
                                            const Divider(height: 16),
                                            
                                            // Estadísticas de asistencia
                                            _buildStatRow(
                                              'Total presenças', 
                                              service['totalAttendances'], 
                                              Colors.green,
                                              onTap: () => _showUsersList(service, 'attendances'),
                                            ),
                                            _buildStatRow(
                                              'Total ausências', 
                                              service['totalAbsences'], 
                                              Colors.orange,
                                              onTap: () => _showUsersList(service, 'absences'),
                                            ),
                                            
                                            const SizedBox(height: 16),
                                            Center(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  _navigateToCultsList(service);
                                                },
                                                icon: const Icon(Icons.visibility),
                                                label: const Text('Ver cultos'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          );
  }
  
  // Tab de usuarios
  Widget _buildUsersTab() {
    // Si estamos cambiando de pestaña y los datos ya están cargados, no mostramos el loader
    final showLoader = _isLoading && !_usersLoaded;
    
    return showLoader
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Filtro de fecha (área fija) - reutilizamos el mismo de servicios
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
                                    _updateDateFilter(selectedDate, _endDate);
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
                                    _updateDateFilter(_startDate, selectedDate);
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
              
              // Contenido desplazable (filtros y lista de usuarios)
              Expanded(
                child: ListView(
                  children: [
                    // Selector de ministerio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: _showMinistrySelector,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.group, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ministério',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _selectedMinistryName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Barra de búsqueda en tiempo real
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar usuario...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: _filterUsersLocally,
                      ),
                    ),
                    
                    // Opciones de ordenación
                    _buildUserSortOptions(),
                    
                    // Lista de usuarios
                    _filteredUsersStats.isEmpty
                        ? SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum usuário encontrado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tente com outro ministério ou filtro de data',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Mensaje informativo si hay usuarios pero todas las estadísticas son cero
                              if (_isDateFilterActive && 
                                  _filteredUsersStats.every((stat) => 
                                      stat.totalInvitations == 0 && 
                                      stat.totalAttendances == 0 && 
                                      stat.totalAbsences == 0))
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Não há dados para o período selecionado. Mostrando usuários com estatísticas em zero.',
                                          style: TextStyle(color: Colors.orange.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Lista de usuarios
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _filteredUsersStats.length,
                                itemBuilder: (context, index) => _buildUserCard(_filteredUsersStats[index]),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          );
  }
  
  Widget _buildUserSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            _buildUserSortButton('Nome', 'name'),
            _buildUserSortButton('Convites', 'totalInvitations'),
            _buildUserSortButton('Presenças', 'totalAttendances'),
            _buildUserSortButton('Ausências', 'totalAbsences'),
            _buildUserSortButton('Aceitos', 'acceptedInvitations'),
            _buildUserSortButton('Rejeitados', 'rejectedInvitations'),
            _buildUserSortButton('Pendentes', 'pendingInvitations'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserSortButton(String label, String value) {
    final isSelected = _userSortBy == value;
    
    return InkWell(
      onTap: () => _changeUserSortOrder(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (isSelected) Icon(
              _userSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMinistrySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Text(
              'Selecione um Ministério',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _availableMinistries.length,
              itemBuilder: (context, index) {
                final ministry = _availableMinistries[index];
                final isSelected = ministry['id'] == _selectedMinistryId;
                
                return ListTile(
                  leading: Icon(
                    Icons.group,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(ministry['name']),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  onTap: () {
                    _selectMinistry(ministry['id'], ministry['name']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserCard(UserStats stats) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con foto y nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: stats.userPhotoUrl.isNotEmpty ? NetworkImage(stats.userPhotoUrl) : null,
                  child: stats.userPhotoUrl.isEmpty
                      ? Text(
                          stats.userName.isNotEmpty ? stats.userName[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stats.ministry.isNotEmpty)
                        Text(
                          stats.ministry,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Estadísticas
            Wrap(
              spacing: 12, // espacio horizontal entre elementos
              runSpacing: 12, // espacio vertical entre filas
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                _buildUserStatItem(
                  'Convites',
                  stats.totalInvitations.toString(),
                  Icons.send,
                  Colors.blue,
                ),
                _buildUserStatItem(
                  'Presenças',
                  stats.totalAttendances.toString(),
                  Icons.event_available,
                  Colors.green,
                ),
                _buildUserStatItem(
                  'Ausências',
                  stats.totalAbsences.toString(),
                  Icons.event_busy,
                  Colors.orange,
                ),
                _buildUserStatItem(
                  'Aceitos',
                  stats.acceptedInvitations.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildUserStatItem(
                  'Rejeitados',
                  stats.rejectedInvitations.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
                _buildUserStatItem(
                  'Pendentes',
                  stats.pendingInvitations.toString(),
                  Icons.hourglass_empty,
                  Colors.purple,
                ),
                if (stats.cancelledInvitations > 0)
                  _buildUserStatItem(
                    'Cancelados',
                    stats.cancelledInvitations.toString(),
                    Icons.block,
                    Colors.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserStatItem(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      width: 70,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Resumo Global',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, // espacio horizontal entre elementos
              runSpacing: 12, // espacio vertical entre filas
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                _buildStatItem(
                  'Presenças',
                  _totalAttendances.toString(),
                  Icons.event_available,
                  Colors.green,
                ),
                _buildStatItem(
                  'Ausências',
                  _totalAbsences.toString(),
                  Icons.event_busy,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Convites',
                  _totalInvitations.toString(),
                  Icons.send,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Aceitos',
                  _acceptedInvitations.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Rejeitados',
                  _rejectedInvitations.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, MaterialColor color) {
    return Container(
      width: 95,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color[700]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color[800]),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color[700], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          _buildSortButton('Nome', 'name'),
          _buildSortButton('Data', 'createdAt'),
          _buildSortButton('Convites', 'invitations'),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    
    return InkWell(
      onTap: () => _changeSortOrder(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (isSelected) Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_services.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum serviço encontrado',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        
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
                service['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Creado: ${DateFormat('dd/MM/yyyy').format(service['createdAt'])}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${service['cultsCount']} cultos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (service['description'] != null && service['description'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            service['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      
                      const Text(
                        'Estatísticas',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Estadísticas de invitaciones
                      _buildStatRow(
                        'Convites enviados', 
                        service['totalInvitations'], 
                        Colors.blue,
                        onTap: () => _showUsersList(service, 'invitations'),
                      ),
                      _buildStatRow(
                        'Convites aceitos', 
                        service['acceptedInvitations'], 
                        Colors.green,
                        onTap: () => _showUsersList(service, 'accepted'),
                      ),
                      _buildStatRow(
                        'Convites rejeitados', 
                        service['rejectedInvitations'], 
                        Colors.red,
                        onTap: () => _showUsersList(service, 'rejected'),
                      ),
                      
                      const Divider(height: 16),
                      
                      // Estadísticas de asistencia
                      _buildStatRow(
                        'Total presenças', 
                        service['totalAttendances'], 
                        Colors.green,
                        onTap: () => _showUsersList(service, 'attendances'),
                      ),
                      _buildStatRow(
                        'Total ausências', 
                        service['totalAbsences'], 
                        Colors.orange,
                        onTap: () => _showUsersList(service, 'absences'),
                      ),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _navigateToCultsList(service);
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Ver cultos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      // Deshabilitar el scroll propio del ListView
      physics: const NeverScrollableScrollPhysics(),
      // No usar Expanded ni altura fija
      shrinkWrap: true,
    );
  }

  Widget _buildStatRow(String label, int value, MaterialColor color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Row(
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 16, color: color[400]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToCultsList(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.7,
        maxChildSize: 0.97,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CultsDetailScreen(
            serviceId: service['id'],
            serviceName: service['name'],
          ),
        ),
      ),
    );
  }

  void _showUsersList(Map<String, dynamic> service, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.7,
        maxChildSize: 0.97,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: UsersListSheet(
            cultId: service['id'],
            cultName: service['name'],
            category: category,
            timeSlotIds: List<String>.from(service['timeSlotIds'] ?? []),
            isFullScreen: true,
          ),
        ),
      ),
    );
  }
  
  String _getCategoryTitle(String category) {
    switch (category) {
      case 'invitations':
        return 'Convites enviados';
      case 'accepted':
        return 'Convites aceitos';
      case 'rejected':
        return 'Convites rejeitados';
      case 'attendances':
        return 'Presenças';
      case 'absences':
        return 'Ausências';
      default:
        return 'Lista de usuários';
    }
  }
}

// Pantalla de detalle de cultos para um serviço específico
class CultsDetailScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  
  const CultsDetailScreen({
    Key? key,
    required this.serviceId,
    required this.serviceName,
  }) : super(key: key);

  @override
  State<CultsDetailScreen> createState() => _CultsDetailScreenState();
}

class _CultsDetailScreenState extends State<CultsDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cults = [];
  String _sortBy = 'date';
  bool _sortAscending = false;
  
  @override
  void initState() {
    super.initState();
    _loadCults();
  }
  
  Future<void> _loadCults() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Consultar todos os cultos deste serviço
      final cultsQuery = await FirebaseFirestore.instance
          .collection('cults')
          .where('serviceId', isEqualTo: FirebaseFirestore.instance.collection('services').doc(widget.serviceId))
          .get();
      
      List<Map<String, dynamic>> cults = [];
      
      for (var doc in cultsQuery.docs) {
        final cultData = doc.data();
        
        // Obter franjas horárias para este culto
        final timeSlotsQuery = await FirebaseFirestore.instance
            .collection('time_slots')
            .where('entityId', isEqualTo: doc.id)
            .where('entityType', isEqualTo: 'cult')
            .get();
        
        List<String> timeSlotIds = timeSlotsQuery.docs.map((doc) => doc.id).toList();
        
        // Contar convites
        final invitesQuery = await FirebaseFirestore.instance
            .collection('work_invites')
            .where('entityId', isEqualTo: doc.id)
            .where('entityType', isEqualTo: 'cult')
            .get();
        
        int totalInvitations = invitesQuery.docs.length;
        int acceptedInvitations = 0;
        int rejectedInvitations = 0;
        
        for (var inviteDoc in invitesQuery.docs) {
          final inviteData = inviteDoc.data();
          if (inviteData['status'] == 'accepted' || inviteData['status'] == 'confirmed') {
            acceptedInvitations++;
          }
          if (inviteData['status'] == 'rejected' || inviteData['isRejected'] == true) {
            rejectedInvitations++;
          }
        }
        
        // Contar presenças
        int totalAttendances = 0;
        int totalAbsences = 0;
        
        for (String timeSlotId in timeSlotIds) {
          final assignmentsQuery = await FirebaseFirestore.instance
              .collection('work_assignments')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .where('isActive', isEqualTo: true)
              .get();
          
          for (var assignmentDoc in assignmentsQuery.docs) {
            final assignmentData = assignmentDoc.data();
            if (assignmentData['isAttendanceConfirmed'] == true) {
              totalAttendances++;
            }
            if (assignmentData['didNotAttend'] == true) {
              totalAbsences++;
            }
          }
        }
        
        // Adicionar à lista
        cults.add({
          'id': doc.id,
          'name': cultData['name'] ?? 'Culto sem nome',
          'date': (cultData['date'] as Timestamp).toDate(),
          'startTime': (cultData['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'endTime': (cultData['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'status': cultData['status'] ?? 'planejado',
          'totalInvitations': totalInvitations,
          'acceptedInvitations': acceptedInvitations, 
          'rejectedInvitations': rejectedInvitations,
          'totalAttendances': totalAttendances,
          'totalAbsences': totalAbsences,
          'timeSlotIds': timeSlotIds,
        });
      }
      
      // Ordenar
      _sortCults(cults);
      
      setState(() {
        _cults = cults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error ao carregar cultos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _sortCults(List<Map<String, dynamic>> cults) {
    switch (_sortBy) {
      case 'name':
        cults.sort((a, b) => _sortAscending
            ? a['name'].toString().compareTo(b['name'].toString())
            : b['name'].toString().compareTo(a['name'].toString()));
        break;
      case 'date':
        cults.sort((a, b) => _sortAscending
            ? a['date'].compareTo(b['date'])
            : b['date'].compareTo(a['date']));
        break;
      case 'invitations':
        cults.sort((a, b) => _sortAscending
            ? a['totalInvitations'].compareTo(b['totalInvitations'])
            : b['totalInvitations'].compareTo(a['totalInvitations']));
        break;
    }
  }
  
  void _changeSortOrder(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortCults(_cults);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cultos de ${widget.serviceName}'),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Opções de ordenação
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      _buildSortButton('Nome', 'name'),
                      _buildSortButton('Data', 'date'),
                      _buildSortButton('Convites', 'invitations'),
                    ],
                  ),
                ),
                
                // Lista de cultos
                Expanded(
                  child: _cults.isEmpty
                      ? const Center(child: Text('Nenhum culto disponível para este serviço'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cults.length,
                          itemBuilder: (context, index) {
                            final cult = _cults[index];
                            
                            return _buildCultCard(cult);
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    
    return InkWell(
      onTap: () => _changeSortOrder(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (isSelected) Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCultCard(Map<String, dynamic> cult) {
    final cultDate = cult['date'] as DateTime;
    final startTime = cult['startTime'] as DateTime;
    final endTime = cult['endTime'] as DateTime;
    
    final formattedDate = DateFormat('EEE, d MMM yyyy', 'es').format(cultDate);
    final formattedTime = '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
    
    // Determinar automáticamente el estado basado en la fecha
    final now = DateTime.now();
    String status = cult['status'] ?? '';
    
    // Si la fecha es pasada, consideramos que el culto ha finalizado
    if (cultDate.add(Duration(hours: endTime.hour, minutes: endTime.minute)).isBefore(now)) {
      status = 'finalizado';
    } 
    // Si estamos en el día y dentro del rango horario del culto
    else if (cultDate.year == now.year && 
             cultDate.month == now.month && 
             cultDate.day == now.day && 
             now.isAfter(DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute)) && 
             now.isBefore(DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute))) {
      status = 'em_curso';
    } 
    // Si la fecha es futura
    else if (cultDate.isAfter(now)) {
      status = 'planejado';
    }
    
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'planejado':
        statusColor = Colors.blue;
        statusText = 'Planejado';
        break;
      case 'em_curso':
        statusColor = Colors.green;
        statusText = 'Em curso';
        break;
      case 'finalizado':
        statusColor = Colors.purple; // Cambio de color para finalizado
        statusText = 'Finalizado';
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusText = 'Cancelado';
        break;
      default:
        statusColor = Colors.orange; // Nuevo color para desconocido
        statusText = 'Planejado';
    }
    
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
            cult['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estatísticas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Estatísticas
                  _buildStatRow(
                    'Convites enviados', 
                    cult['totalInvitations'], 
                    Colors.blue,
                    onTap: () => _showUsersList(cult, 'invitations'),
                  ),
                  _buildStatRow(
                    'Convites aceitos', 
                    cult['acceptedInvitations'], 
                    Colors.green,
                    onTap: () => _showUsersList(cult, 'accepted'),
                  ),
                  _buildStatRow(
                    'Convites rejeitados', 
                    cult['rejectedInvitations'], 
                    Colors.red,
                    onTap: () => _showUsersList(cult, 'rejected'),
                  ),
                  
                  const Divider(height: 16),
                  
                  _buildStatRow(
                    'Total presenças', 
                    cult['totalAttendances'], 
                    Colors.green,
                    onTap: () => _showUsersList(cult, 'attendances'),
                  ),
                  _buildStatRow(
                    'Total ausências', 
                    cult['totalAbsences'], 
                    Colors.orange,
                    onTap: () => _showUsersList(cult, 'absences'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, int value, MaterialColor color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Row(
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color[700],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 16, color: color[400]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUsersList(Map<String, dynamic> cult, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.7,
        maxChildSize: 0.97,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: UsersListSheet(
            cultId: cult['id'],
            cultName: cult['name'],
            category: category,
            timeSlotIds: List<String>.from(cult['timeSlotIds'] ?? []),
            isFullScreen: true,
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar a lista de usuários
class UsersListSheet extends StatefulWidget {
  final String cultId;
  final String cultName;
  final String category;
  final List<String> timeSlotIds;
  final bool isFullScreen;

  const UsersListSheet({
    Key? key,
    required this.cultId,
    required this.cultName,
    required this.category,
    required this.timeSlotIds,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  State<UsersListSheet> createState() => _UsersListSheetState();
}

class _UsersListSheetState extends State<UsersListSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> usersData = [];
      
      switch (widget.category) {
        case 'invitations':
          // Todas as convites enviadas para este culto
          final invitesQuery = await FirebaseFirestore.instance
              .collection('work_invites')
              .where('entityId', isEqualTo: widget.cultId)
              .where('entityType', isEqualTo: 'cult')
              .get();
          
          for (var doc in invitesQuery.docs) {
            final data = doc.data();
            final userId = data['userId'] is DocumentReference 
                ? data['userId'].id 
                : (data['userId'] as String? ?? '');
            
            if (userId.isEmpty) continue;
            
            // Obter dados do usuário
            final userData = await _getUserData(userId);
            if (userData == null) continue;
            
            usersData.add({
              'name': userData['displayName'] ?? 'Usuário sem nome',
              'photoUrl': userData['photoUrl'] ?? '',
              'ministry': data['ministryName'] ?? 'Sem ministério',
              'role': data['role'] ?? 'Sem cargo',
              'invitedAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'respondedAt': (data['respondedAt'] as Timestamp?)?.toDate(),
              'status': data['status'] ?? 'pendente',
              'timeSlot': await _getTimeSlotInfo(data['timeSlotId'] as String? ?? ''),
            });
          }
          break;
          
        case 'accepted':
          // Convites aceitos
          final invitesQuery = await FirebaseFirestore.instance
              .collection('work_invites')
              .where('entityId', isEqualTo: widget.cultId)
              .where('entityType', isEqualTo: 'cult')
              .where('status', whereIn: ['accepted', 'confirmed'])
              .get();
          
          for (var doc in invitesQuery.docs) {
            final data = doc.data();
            final userId = data['userId'] is DocumentReference 
                ? data['userId'].id 
                : (data['userId'] as String? ?? '');
            
            if (userId.isEmpty) continue;
            
            // Obter dados do usuário
            final userData = await _getUserData(userId);
            if (userData == null) continue;
            
            usersData.add({
              'name': userData['displayName'] ?? 'Usuário sem nome',
              'photoUrl': userData['photoUrl'] ?? '',
              'ministry': data['ministryName'] ?? 'Sem ministério',
              'role': data['role'] ?? 'Sem cargo',
              'invitedAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'respondedAt': (data['respondedAt'] as Timestamp?)?.toDate(),
              'status': 'aceito',
              'timeSlot': await _getTimeSlotInfo(data['timeSlotId'] as String? ?? ''),
            });
          }
          break;
          
        case 'rejected':
          // Convites rejeitados
          final invitesQuery = await FirebaseFirestore.instance
              .collection('work_invites')
              .where('entityId', isEqualTo: widget.cultId)
              .where('entityType', isEqualTo: 'cult')
              .get();
          
          for (var doc in invitesQuery.docs) {
            final data = doc.data();
            // Verificar se é rejeitado (há duas formas de marcar rejeições)
            final isRejected = data['status'] == 'rejected' || data['isRejected'] == true;
            if (!isRejected) continue;
            
            final userId = data['userId'] is DocumentReference 
                ? data['userId'].id 
                : (data['userId'] as String? ?? '');
            
            if (userId.isEmpty) continue;
            
            // Obter dados do usuário
            final userData = await _getUserData(userId);
            if (userData == null) continue;
            
            usersData.add({
              'name': userData['displayName'] ?? 'Usuário sem nome',
              'photoUrl': userData['photoUrl'] ?? '',
              'ministry': data['ministryName'] ?? 'Sem ministério',
              'role': data['role'] ?? 'Sem cargo',
              'invitedAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'respondedAt': (data['respondedAt'] as Timestamp?)?.toDate(),
              'status': 'rejeitado',
              'timeSlot': await _getTimeSlotInfo(data['timeSlotId'] as String? ?? ''),
            });
          }
          break;
          
        case 'attendances':
          // Presenças confirmadas
          for (String timeSlotId in widget.timeSlotIds) {
            final assignmentsQuery = await FirebaseFirestore.instance
                .collection('work_assignments')
                .where('timeSlotId', isEqualTo: timeSlotId)
                .where('isActive', isEqualTo: true)
                .where('isAttendanceConfirmed', isEqualTo: true)
                .get();
            
            for (var doc in assignmentsQuery.docs) {
              final data = doc.data();
              final userId = data['userId'] is DocumentReference 
                  ? data['userId'].id 
                  : (data['userId'] as String? ?? '');
              
              if (userId.isEmpty) continue;
              
              // Obter dados do usuário
              final userData = await _getUserData(userId);
              if (userData == null) continue;
              
              usersData.add({
                'name': userData['displayName'] ?? 'Usuário sem nome',
                'photoUrl': userData['photoUrl'] ?? '',
                'ministry': data['ministryName'] ?? 'Sem ministério',
                'role': data['role'] ?? 'Sem cargo',
                'invitedAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'attendedAt': (data['attendanceConfirmedAt'] as Timestamp?)?.toDate(),
                'attendanceConfirmedBy': data['attendanceConfirmedBy'] ?? '',
                'status': 'presente',
                'timeSlot': await _getTimeSlotInfo(timeSlotId),
              });
            }
          }
          break;
          
        case 'absences':
          // Ausências (pessoas que aceitaram mas não compareceram)
          for (String timeSlotId in widget.timeSlotIds) {
            final assignmentsQuery = await FirebaseFirestore.instance
                .collection('work_assignments')
                .where('timeSlotId', isEqualTo: timeSlotId)
                .where('isActive', isEqualTo: true)
                .where('didNotAttend', isEqualTo: true)
                .get();
            
            for (var doc in assignmentsQuery.docs) {
              final data = doc.data();
              final userId = data['userId'] is DocumentReference 
                  ? data['userId'].id 
                  : (data['userId'] as String? ?? '');
              
              if (userId.isEmpty) continue;
              
              // Obter dados do usuário
              final userData = await _getUserData(userId);
              if (userData == null) continue;
              
              usersData.add({
                'name': userData['displayName'] ?? 'Usuário sem nome',
                'photoUrl': userData['photoUrl'] ?? '',
                'ministry': data['ministryName'] ?? 'Sem ministério',
                'role': data['role'] ?? 'Sem cargo',
                'invitedAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'notAttendedAt': (data['notAttendedAt'] as Timestamp?)?.toDate(),
                'notAttendedBy': data['notAttendedBy'] ?? '',
                'status': 'ausente',
                'timeSlot': await _getTimeSlotInfo(timeSlotId),
              });
            }
          }
          break;
      }
      
      setState(() {
        _users = usersData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error ao carregar usuários: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Obtém os dados do usuário a partir do seu ID
  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userPath = userId.startsWith('/users/')
          ? userId 
          : userId.startsWith('users/') 
              ? '/$userId' 
              : '/users/$userId';
              
      // Extrair o ID limpo
      final cleanId = userPath.replaceAll('/users/', '');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanId)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error ao obter dados do usuário: $e');
      return null;
    }
  }
  
  // Obtém os dados da franja horária
  Future<Map<String, dynamic>> _getTimeSlotInfo(String timeSlotId) async {
    try {
      if (timeSlotId.isEmpty) {
        return {'name': 'Sem franja horária', 'time': ''};
      }
      
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .get();
      
      if (timeSlotDoc.exists) {
        final data = timeSlotDoc.data() as Map<String, dynamic>;
        final startTime = data['startTime'] is Timestamp 
            ? (data['startTime'] as Timestamp).toDate()
            : null;
        final endTime = data['endTime'] is Timestamp 
            ? (data['endTime'] as Timestamp).toDate()
            : null;
            
        String formattedTime = '';
        if (startTime != null && endTime != null) {
          formattedTime = '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
        }
        
        return {
          'name': data['name'] ?? 'Franja sem nome',
          'time': formattedTime,
        };
      }
      return {'name': 'Franja não encontrada', 'time': ''};
    } catch (e) {
      print('Error ao obter informações da franja horária: $e');
      return {'name': 'Erro ao carregar franja', 'time': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Título conforme a categoria
    String title = '';
    Color headerColor;
    
    switch (widget.category) {
      case 'invitations':
        title = 'Convites enviados';
        headerColor = Colors.blue;
        break;
      case 'accepted':
        title = 'Convites aceitos';
        headerColor = Colors.green;
        break;
      case 'rejected':
        title = 'Convites rejeitados';
        headerColor = Colors.red;
        break;
      case 'attendances':
        title = 'Presenças confirmadas';
        headerColor = Colors.green;
        break;
      case 'absences':
        title = 'Ausências registradas';
        headerColor = Colors.orange;
        break;
      default:
        title = 'Lista de usuários';
        headerColor = Colors.blue;
    }

    return Column(
      children: [
        // Cabeçalho
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: headerColor.withOpacity(0.3)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Culto: ${widget.cultName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de usuários
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum usuário encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho com foto y nome
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                                          ? NetworkImage(user['photoUrl'])
                                          : null,
                                      child: user['photoUrl'] == null || user['photoUrl'].isEmpty
                                          ? const Icon(Icons.person, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: headerColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  user['status'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: headerColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (user['ministry'] != null) ...[
                                                const Icon(Icons.group, size: 12, color: Colors.grey),
                                                const SizedBox(width: 2),
                                                Text(
                                                  user['ministry'],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 8),
                                const Divider(),
                                
                                // Informações de cargo
                                if (user['role'] != null) ...[
                                  _buildInfoRow(
                                    'Cargo atribuído', 
                                    user['role'], 
                                    Icons.work,
                                  ),
                                ],
                                
                                // Franja horária
                                if (user['timeSlot'] != null) ...[
                                  _buildInfoRow(
                                    'Franja horária', 
                                    '${user['timeSlot']['name']} ${user['timeSlot']['time']}', 
                                    Icons.access_time,
                                  ),
                                ],
                                
                                // Informações de datas conforme a categoria
                                if (user['invitedAt'] != null) ...[
                                  _buildInfoRow(
                                    'Convidado em', 
                                    DateFormat('dd/MM/yyyy HH:mm').format(user['invitedAt']), 
                                    Icons.send,
                                  ),
                                ],
                                
                                if (user['respondedAt'] != null) ...[
                                  _buildInfoRow(
                                    'Respondido em', 
                                    DateFormat('dd/MM/yyyy HH:mm').format(user['respondedAt']), 
                                    Icons.reply,
                                  ),
                                ],
                                
                                if (user['attendedAt'] != null) ...[
                                  _buildInfoRow(
                                    'Presença confirmada em', 
                                    DateFormat('dd/MM/yyyy HH:mm').format(user['attendedAt']), 
                                    Icons.event_available,
                                  ),
                                ],
                                
                                if (user['notAttendedAt'] != null) ...[
                                  _buildInfoRow(
                                    'Ausência registrada em', 
                                    DateFormat('dd/MM/yyyy HH:mm').format(user['notAttendedAt']), 
                                    Icons.event_busy,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 