import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import 'event_attendance_screen.dart';

class AdminEventsListScreen extends StatefulWidget {
  final String initialFilterType;

  const AdminEventsListScreen({
    Key? key,
    this.initialFilterType = 'all', // 'all', 'ministry', 'group'
  }) : super(key: key);

  @override
  State<AdminEventsListScreen> createState() => _AdminEventsListScreenState();
}

class _AdminEventsListScreenState extends State<AdminEventsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _displayedEvents = [];
  late String _filterType; // 'all', 'ministry' o 'group'
  
  // Paginación
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  bool _hasMoreEvents = true;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialFilterType;
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadEvents();
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    // Si estamos cerca del final del scroll, cargamos más eventos
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreEvents) {
        _loadMoreEvents();
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreEvents = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _events = [];
          _displayedEvents = [];
        });
        return;
      }

      List<Map<String, dynamic>> allEvents = [];
      
      // Buscar ministerios donde el usuario es líder
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
          
          // Si es admin, cargar los eventos de este ministerio
          if (isAdmin) {
            try {
              final ministryEvents = await FirebaseFirestore.instance
                .collection('ministry_events')
                .where('ministryId', isEqualTo: FirebaseFirestore.instance.collection('ministries').doc(ministry.id))
                .orderBy('date', descending: true)
                .get();
                
              for (var event in ministryEvents.docs) {
                final eventData = event.data();
                if (eventData['date'] != null) {
                  allEvents.add({
                    'id': event.id,
                    'title': eventData['title'] ?? 'Sem título',
                    'date': (eventData['date'] as Timestamp).toDate(),
                    'entityId': ministry.id,
                    'entityName': ministryData['name'] ?? 'Ministério',
                    'entityType': 'ministry',
                    'imageUrl': eventData['imageUrl'] ?? '',
                    'description': eventData['description'] ?? '',
                    'location': eventData['location'] ?? '',
                  });
                }
              }
            } catch (e) {
              debugPrint('Erro ao carregar eventos do ministério ${ministry.id}: $e');
            }
          }
        }
      }
      
      // Buscar grupos donde el usuario es líder
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
          
          // Si es admin, cargar los eventos de este grupo
          if (isAdmin) {
            try {
              final groupEvents = await FirebaseFirestore.instance
                .collection('group_events')
                .where('groupId', isEqualTo: FirebaseFirestore.instance.collection('groups').doc(group.id))
                .orderBy('date', descending: true)
                .get();
                
              for (var event in groupEvents.docs) {
                final eventData = event.data();
                if (eventData['date'] != null) {
                  allEvents.add({
                    'id': event.id,
                    'title': eventData['title'] ?? 'Sem título',
                    'date': (eventData['date'] as Timestamp).toDate(),
                    'entityId': group.id,
                    'entityName': groupData['name'] ?? 'Grupo',
                    'entityType': 'group',
                    'imageUrl': eventData['imageUrl'] ?? '',
                    'description': eventData['description'] ?? '',
                    'location': eventData['location'] ?? '',
                  });
                }
              }
            } catch (e) {
              debugPrint('Erro ao carregar eventos do grupo ${group.id}: $e');
            }
          }
        }
      }
      
      // Ordenar eventos por fecha (más recientes primero)
      allEvents.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      setState(() {
        _events = allEvents;
        _applyFilterAndPagination();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar eventos: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar eventos: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
  
  void _applyFilterAndPagination() {
    List<Map<String, dynamic>> filtered = _filterType == 'all' 
        ? List.from(_events)
        : _events.where((event) => event['entityType'] == _filterType).toList();
    
    // Calcular eventos a mostrar según paginación
    int endIndex = _currentPage * _itemsPerPage;
    if (endIndex > filtered.length) {
      endIndex = filtered.length;
      _hasMoreEvents = false;
    } else {
      _hasMoreEvents = true;
    }
    
    _displayedEvents = filtered.sublist(0, endIndex);
  }

  Future<void> _loadMoreEvents() async {
    if (!_hasMoreEvents || _isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500)); // Simulación de carga
    
    setState(() {
      _currentPage++;
      _applyFilterAndPagination();
      _isLoadingMore = false;
    });
  }

  void _onFilterChanged(String newFilter) {
    if (newFilter == _filterType) return;
    
    setState(() {
      _filterType = newFilter;
      _currentPage = 1;
      _applyFilterAndPagination();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Administrados'),
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterChip('Todos', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ministérios', 'ministry'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Grupos', 'group'),
                    ],
                  ),
                ),
              ),
            ),
            
            // Lista de eventos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayedEvents.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadEvents,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _displayedEvents.length + (_hasMoreEvents ? 1 : 0),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemBuilder: (context, index) {
                              // Widget de carga al final de la lista
                              if (index == _displayedEvents.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              
                              final event = _displayedEvents[index];
                              final DateTime eventDate = event['date'] as DateTime;
                              final bool isMinistry = event['entityType'] == 'ministry';
                              final Color themeColor = isMinistry ? AppColors.primary : Colors.green;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventAttendanceScreen(
                                          eventId: event['id'],
                                          eventTitle: event['title'],
                                          entityId: event['entityId'],
                                          entityType: event['entityType'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Imagen del evento (si la tiene)
                                      if (event['imageUrl'] != null && event['imageUrl'].isNotEmpty)
                                        SizedBox(
                                          height: 150,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Imagen con caché
                                              CachedNetworkImage(
                                                imageUrl: event['imageUrl'],
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      color: themeColor.withOpacity(0.5),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    isMinistry ? Icons.people : Icons.group,
                                                    color: Colors.grey,
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                              
                                              // Gradiente para mejorar legibilidad de la etiqueta
                                              Positioned(
                                                top: 0,
                                                left: 0,
                                                right: 0,
                                                height: 60,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                      colors: [
                                                        Colors.black.withOpacity(0.7),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              
                                              // Etiqueta del tipo de entidad
                                              Positioned(
                                                top: 10,
                                                left: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: themeColor.withOpacity(0.8),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isMinistry ? Icons.people : Icons.group,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        event['entityName'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      // Cabecera del evento (si no tiene imagen)
                                      if (event['imageUrl'] == null || event['imageUrl'].isEmpty)
                                        Container(
                                          color: themeColor.withOpacity(0.1),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isMinistry ? Icons.people : Icons.group,
                                                color: themeColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                event['entityName'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: themeColor,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      
                                      // Contenido del evento
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    event['title'],
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            const SizedBox(height: 10),
                                            
                                            // Fecha y hora
                                            Row(
                                              children: [
                                                Icon(Icons.event, size: 14, color: Colors.grey[700]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('EEEE dd/MM/yyyy', 'pt_BR').format(eventDate),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('HH:mm', 'pt_BR').format(eventDate),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            // Ubicación si existe
                                            if (event['location'] != null && event['location'].isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      event['location'],
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            
                                            // Descripción corta si existe
                                            if (event['description'] != null && event['description'].isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              Text(
                                                event['description'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            
                                            const SizedBox(height: 16),
                                            
                                            // Botón de gestionar asistencia
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => EventAttendanceScreen(
                                                        eventId: event['id'],
                                                        eventTitle: event['title'],
                                                        entityId: event['entityId'],
                                                        entityType: event['entityType'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: themeColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  elevation: 1,
                                                ),
                                                child: const Text('Gerenciar Presença'),
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
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filterType == filterValue;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onFilterChanged(filterValue);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
          ? BorderSide(color: AppColors.primary.withOpacity(0.5)) 
          : BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Não há eventos ${_filterType == 'all' ? '' : _filterType == 'ministry' ? 'de ministérios' : 'de grupos'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Os eventos que você administra serão exibidos aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
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
} 