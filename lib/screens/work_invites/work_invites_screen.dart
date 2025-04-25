import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/work_invite.dart';
import '../../services/work_schedule_service.dart';
import './work_invite_detail_screen.dart';

class WorkInvitesScreen extends StatefulWidget {
  const WorkInvitesScreen({Key? key}) : super(key: key);

  @override
  State<WorkInvitesScreen> createState() => _WorkInvitesScreenState();
}

class _WorkInvitesScreenState extends State<WorkInvitesScreen> {
  final WorkScheduleService _workScheduleService = WorkScheduleService();
  String _statusFilter = 'pending'; // 'all', 'pending', 'accepted', 'rejected'
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitaciones de Trabajo'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'all',
                child: Text('Todas'),
              ),
              const PopupMenuItem<String>(
                value: 'pending',
                child: Text('Pendientes'),
              ),
              const PopupMenuItem<String>(
                value: 'accepted',
                child: Text('Aceptadas'),
              ),
              const PopupMenuItem<String>(
                value: 'rejected',
                child: Text('Rechazadas'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<WorkInvite>>(
        stream: _workScheduleService.getUserInvites(
          FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No tienes invitaciones de trabajo',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          
          // Filtrar invitaciones según el estado seleccionado
          final invites = snapshot.data!.where((invite) {
            if (_statusFilter == 'all') {
              return true;
            }
            return invite.status == _statusFilter;
          }).toList();
          
          if (invites.isEmpty) {
            return Center(
              child: Text(
                'No tienes invitaciones ${_getStatusText(_statusFilter)}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              return _buildInviteCard(invite);
            },
          );
        },
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'pendientes';
      case 'accepted':
        return 'aceptadas';
      case 'rejected':
        return 'rechazadas';
      default:
        return '';
    }
  }
  
  Widget _buildInviteCard(WorkInvite invite) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Marcar como leída si es pendiente
          if (invite.status == 'pending' && !invite.isRead) {
            _workScheduleService.markInviteAsRead(invite.id);
          }
          
          // Navegar a detalle
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkInviteDetailScreen(invite: invite),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con estado y entidad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        invite.entityType == 'cult' ? Icons.church : Icons.event,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        invite.entityName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(invite.status),
                ],
              ),
              
              const Divider(height: 16),
              
              // Detalles de la invitación
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fecha y Horario
                        Row(
                          children: [
                            const Icon(Icons.event, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(invite.date),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${timeFormat.format(invite.startTime)} - ${timeFormat.format(invite.endTime)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ministerio y Rol
                        Row(
                          children: [
                            const Icon(Icons.work, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                invite.ministryName,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                invite.role,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Acciones (para invitaciones pendientes)
              if (invite.status == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _respondToInvite(invite.id, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Rechazar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _respondToInvite(invite.id, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aceptar'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Aceptada';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rechazada';
        break;
      case 'seen':
        color = Colors.orange;
        label = 'Vista';
        break;
      case 'pending':
      default:
        color = Colors.amber;
        label = 'Pendiente';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.amber ? Colors.black : color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _respondToInvite(String inviteId, String status) async {
    try {
      await _workScheduleService.respondToInvite(inviteId, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitación ${status == 'accepted' ? 'aceptada' : 'rechazada'} exitosamente'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al responder a la invitación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 