import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

class ServiceStatsTab extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final int totalInvitations;
  final int acceptedInvitations;
  final int rejectedInvitations;
  final int totalAttendances;
  final int totalAbsences;

  const ServiceStatsTab({
    Key? key,
    this.startDate,
    this.endDate,
    required this.searchQuery,
    required this.totalInvitations,
    required this.acceptedInvitations,
    required this.rejectedInvitations,
    required this.totalAttendances,
    required this.totalAbsences,
  }) : super(key: key);

  @override
  State<ServiceStatsTab> createState() => _ServiceStatsTabState();
}

class _ServiceStatsTabState extends State<ServiceStatsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void didUpdateWidget(ServiceStatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar dados se os filtros mudarem
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate ||
        oldWidget.searchQuery != widget.searchQuery) {
      _loadServices();
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obter todos os serviços
      var query = FirebaseFirestore.instance.collection('services');
      final servicesSnapshot = await query.get();

      // Converter os resultados para nossa estrutura de dados local
      List<Map<String, dynamic>> services = [];
      
      for (var doc in servicesSnapshot.docs) {
        final serviceData = doc.data();
        
        // Aplicar filtro de busca se existir
        if (widget.searchQuery.isNotEmpty &&
            !serviceData['name'].toString().toLowerCase().contains(widget.searchQuery.toLowerCase())) {
          continue;
        }

        // Obter convites para este serviço
        final invitationsQuery = await FirebaseFirestore.instance
            .collection('work_invites')
            .where('entityType', isEqualTo: 'service')
            .where('entityId', isEqualTo: doc.id)
            .get();

        // Aplicar filtro de data se existir
        final invitations = invitationsQuery.docs.where((inviteDoc) {
          if (widget.startDate == null || widget.endDate == null) return true;
          
          final createdAt = (inviteDoc.data()['createdAt'] as Timestamp?)?.toDate();
          if (createdAt == null) return false;
          
          return createdAt.isAfter(widget.startDate!) && 
                 createdAt.isBefore(widget.endDate!);
        }).toList();

        // Contar convites por estado
        final totalInvitations = invitations.length;
        final acceptedInvitations = invitations
            .where((inviteDoc) => inviteDoc.data()['status'] == 'accepted' || inviteDoc.data()['status'] == 'confirmed')
            .length;
        final rejectedInvitations = invitations
            .where((inviteDoc) => inviteDoc.data()['status'] == 'rejected' || inviteDoc.data()['isRejected'] == true)
            .length;

        // Obter cultos para este serviço
        final cultsQuery = await FirebaseFirestore.instance
            .collection('cults')
            .where('serviceId', isEqualTo: FirebaseFirestore.instance.collection('services').doc(doc.id))
            .get();

        final cults = cultsQuery.docs.where((cultDoc) {
          if (widget.startDate == null || widget.endDate == null) return true;
          
          final cultDate = (cultDoc.data()['date'] as Timestamp?)?.toDate();
          if (cultDate == null) return false;
          
          return cultDate.isAfter(widget.startDate!) && 
                 cultDate.isBefore(widget.endDate!);
        }).toList();

        // Obter faixas de horário para todos os cultos
        List<String> timeSlotIds = [];
        for (var cultDoc in cults) {
          final timeSlotsQuery = await FirebaseFirestore.instance
              .collection('time_slots')
              .where('entityId', isEqualTo: cultDoc.id)
              .where('entityType', isEqualTo: 'cult')
              .get();
          
          timeSlotIds.addAll(timeSlotsQuery.docs.map((doc) => doc.id).toList());
        }

        // Obter atribuições para todas as faixas de horário
        int totalAttendances = 0;
        int totalAbsences = 0;

        for (String timeSlotId in timeSlotIds) {
          final assignmentsQuery = await FirebaseFirestore.instance
              .collection('work_assignments')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .where('isActive', isEqualTo: true)
              .get();

          totalAttendances += assignmentsQuery.docs
              .where((doc) => doc.data()['isAttendanceConfirmed'] == true)
              .length;
              
          totalAbsences += assignmentsQuery.docs
              .where((doc) => doc.data()['didNotAttend'] == true)
              .length;
        }

        // Salvar os dados do serviço com suas estatísticas
        services.add({
          'id': doc.id,
          'name': serviceData['name'] ?? 'Serviço sem nome',
          'description': serviceData['description'] ?? '',
          'createdAt': (serviceData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'totalInvitations': totalInvitations,
          'acceptedInvitations': acceptedInvitations,
          'rejectedInvitations': rejectedInvitations,
          'totalAttendances': totalAttendances,
          'totalAbsences': totalAbsences,
          'cultsCount': cults.length,
        });
      }

      // Ordenar os serviços
      _sortServices(services);

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar serviços: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      case 'attendances':
        services.sort((a, b) => _sortAscending
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
      _sortServices(_services);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_services.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum serviço encontrado',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        _buildSortOptions(),
        Expanded(
          child: ListView.builder(
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
                            'Criado: ${DateFormat('dd/MM/yyyy').format(service['createdAt'])}',
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
                          
                          // Estatísticas de convites
                          _buildStatRow(
                            'Convites enviados', 
                            service['totalInvitations'], 
                            Colors.blue
                          ),
                          _buildStatRow(
                            'Convites aceitos', 
                            service['acceptedInvitations'], 
                            Colors.green
                          ),
                          _buildStatRow(
                            'Convites rejeitados', 
                            service['rejectedInvitations'], 
                            Colors.red
                          ),
                          
                          const Divider(height: 16),
                          
                          // Estatísticas de presença
                          _buildStatRow(
                            'Total de presenças', 
                            service['totalAttendances'], 
                            Colors.green
                          ),
                          _buildStatRow(
                            'Total de ausências', 
                            service['totalAbsences'], 
                            Colors.orange
                          ),
                          
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text('Cultos de ${service['name']}'),
                                    ),
                                    body: const Center(
                                      child: Text('Implementação pendente'),
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('Ver cultos'),
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
          _buildSortButton('Nome', 'name'),
          _buildSortButton('Data', 'createdAt'),
          _buildSortButton('Convites', 'invitations'),
          _buildSortButton('Presenças', 'attendances'),
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