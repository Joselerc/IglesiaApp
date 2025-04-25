import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

class ServiceCultsStatsTab extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  const ServiceCultsStatsTab({
    Key? key,
    this.startDate,
    this.endDate,
    required this.searchQuery,
  }) : super(key: key);

  @override
  State<ServiceCultsStatsTab> createState() => _ServiceCultsStatsTabState();
}

class _ServiceCultsStatsTabState extends State<ServiceCultsStatsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cults = [];
  List<String> _services = [];
  Map<String, String> _serviceNames = {};
  String _selectedService = '';
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadServices().then((_) => _loadCults());
  }

  @override
  void didUpdateWidget(ServiceCultsStatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar datos si cambian los filtros
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadCults();
    }
  }

  Future<void> _loadServices() async {
    try {
      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .orderBy('name')
          .get();
      
      List<String> services = [''];
      Map<String, String> serviceNames = {'': 'Todos los servicios'};
      
      for (var doc in servicesSnapshot.docs) {
        services.add(doc.id);
        serviceNames[doc.id] = doc.data()['name'] ?? 'Servicio sin nombre';
      }
      
      setState(() {
        _services = services;
        _serviceNames = serviceNames;
      });
    } catch (e) {
      print('Error al cargar servicios: $e');
    }
  }

  Future<void> _loadCults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot cultsSnapshot;
      
      // Consulta base
      Query query = FirebaseFirestore.instance.collection('cults');
      
      // Filtrar por servicio si se ha seleccionado uno
      if (_selectedService.isNotEmpty) {
        query = query.where('serviceId', isEqualTo: FirebaseFirestore.instance.collection('services').doc(_selectedService));
      }
      
      // Filtrar por fecha si se han seleccionado fechas
      if (widget.startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate!));
      }
      
      if (widget.endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(widget.endDate!));
      }
      
      // Ordenar por fecha
      query = query.orderBy('date', descending: true);
      
      cultsSnapshot = await query.get();
      
      // Procesar los resultados
      List<Map<String, dynamic>> cults = [];
      
      for (var doc in cultsSnapshot.docs) {
        final cultData = doc.data() as Map<String, dynamic>;
        
        // Aplicar filtro de búsqueda si existe
        if (widget.searchQuery.isNotEmpty &&
            !cultData['name'].toString().toLowerCase().contains(widget.searchQuery.toLowerCase())) {
          continue;
        }
        
        // Obtener nombre del servicio
        String serviceName = 'Servicio desconocido';
        String serviceId = '';
        
        if (cultData['serviceId'] is DocumentReference) {
          serviceId = cultData['serviceId'].id;
          serviceName = _serviceNames[serviceId] ?? 'Servicio desconocido';
        }
        
        // Obtener franjas horarias para este culto
        final timeSlotsQuery = await FirebaseFirestore.instance
            .collection('time_slots')
            .where('entityId', isEqualTo: doc.id)
            .where('entityType', isEqualTo: 'cult')
            .get();
        
        // Obtener IDs de franjas horarias
        List<String> timeSlotIds = timeSlotsQuery.docs.map((doc) => doc.id).toList();
        
        // Contar invitaciones y asistencias
        int totalInvitations = 0;
        int acceptedInvitations = 0;
        int rejectedInvitations = 0;
        int totalAttendances = 0;
        int totalAbsences = 0;
        
        // Buscar invitaciones específicas para este culto
        final invitationsQuery = await FirebaseFirestore.instance
            .collection('work_invites')
            .where('entityId', isEqualTo: doc.id)
            .where('entityType', isEqualTo: 'cult')
            .get();
        
        totalInvitations += invitationsQuery.docs.length;
        
        for (var inviteDoc in invitationsQuery.docs) {
          final inviteData = inviteDoc.data();
          if (inviteData['status'] == 'accepted' || inviteData['status'] == 'confirmed') {
            acceptedInvitations++;
          }
          if (inviteData['status'] == 'rejected' || inviteData['isRejected'] == true) {
            rejectedInvitations++;
          }
        }
        
        // Obtener asignaciones para todas las franjas horarias
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
        
        // Construir objeto de culto con estadísticas
        cults.add({
          'id': doc.id,
          'name': cultData['name'] ?? 'Culto sin nombre',
          'date': (cultData['date'] as Timestamp).toDate(),
          'startTime': (cultData['startTime'] as Timestamp).toDate(),
          'endTime': (cultData['endTime'] as Timestamp).toDate(),
          'status': cultData['status'] ?? 'planificado',
          'serviceId': serviceId,
          'serviceName': serviceName,
          'totalInvitations': totalInvitations,
          'acceptedInvitations': acceptedInvitations,
          'rejectedInvitations': rejectedInvitations,
          'totalAttendances': totalAttendances,
          'totalAbsences': totalAbsences,
          'timeSlotsCount': timeSlotIds.length,
        });
      }
      
      // Ordenar los cultos
      _sortCults(cults);
      
      setState(() {
        _cults = cults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar cultos: $e');
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
      case 'attendances':
        cults.sort((a, b) => _sortAscending
            ? a['totalAttendances'].compareTo(b['totalAttendances'])
            : b['totalAttendances'].compareTo(a['totalAttendances']));
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

  void _changeService(String serviceId) {
    setState(() {
      _selectedService = serviceId;
    });
    _loadCults();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No se encontraron cultos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_selectedService.isNotEmpty || widget.searchQuery.isNotEmpty)
              const SizedBox(height: 16),
            if (_selectedService.isNotEmpty || widget.searchQuery.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedService = '';
                  });
                  _loadCults();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpiar filtros'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilters(),
        _buildSortOptions(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cults.length,
            itemBuilder: (context, index) {
              final cult = _cults[index];
              
              final cultDate = cult['date'] as DateTime;
              final startTime = cult['startTime'] as DateTime;
              final endTime = cult['endTime'] as DateTime;
              
              final formattedDate = DateFormat('EEE, d MMM yyyy', 'es').format(cultDate);
              final formattedTime = '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}';
              
              Color statusColor;
              String statusText;
              
              switch (cult['status']) {
                case 'planificado':
                  statusColor = Colors.blue;
                  statusText = 'Planificado';
                  break;
                case 'en_curso':
                  statusColor = Colors.green;
                  statusText = 'En curso';
                  break;
                case 'finalizado':
                  statusColor = Colors.grey;
                  statusText = 'Finalizado';
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = 'Desconocido';
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.business, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            cult['serviceName'],
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
                            'Estadísticas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Estadísticas de invitaciones
                          _buildStatRow(
                            'Invitaciones enviadas', 
                            cult['totalInvitations'], 
                            Colors.blue
                          ),
                          _buildStatRow(
                            'Invitaciones aceptadas', 
                            cult['acceptedInvitations'], 
                            Colors.green
                          ),
                          _buildStatRow(
                            'Invitaciones rechazadas', 
                            cult['rejectedInvitations'], 
                            Colors.red
                          ),
                          
                          const Divider(height: 16),
                          
                          // Estadísticas de asistencia
                          _buildStatRow(
                            'Total asistencias', 
                            cult['totalAttendances'], 
                            Colors.green
                          ),
                          _buildStatRow(
                            'Total ausencias', 
                            cult['totalAbsences'], 
                            Colors.orange
                          ),
                          _buildStatRow(
                            'Franjas horarias', 
                            cult['timeSlotsCount'], 
                            Colors.purple
                          ),
                          
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Aquí irá la navegación a los detalles del culto
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver detalles'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _selectedService,
        decoration: const InputDecoration(
          labelText: 'Filtrar por servicio',
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: OutlineInputBorder(),
        ),
        items: _services.map((String serviceId) {
          return DropdownMenuItem<String>(
            value: serviceId,
            child: Text(_serviceNames[serviceId] ?? 'Desconocido'),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            _changeService(value);
          }
        },
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Text(
            'Ordenar por:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          _buildSortButton('Nombre', 'name'),
          _buildSortButton('Fecha', 'date'),
          _buildSortButton('Invitaciones', 'invitations'),
          _buildSortButton('Asistencias', 'attendances'),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    return TextButton(
      onPressed: () => _changeSortOrder(value),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _sortBy == value ? AppColors.primary : Colors.grey[700],
              fontWeight: _sortBy == value ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (_sortBy == value)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppColors.primary,
            ),
        ],
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }
} 