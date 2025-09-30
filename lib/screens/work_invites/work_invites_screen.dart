import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/work_invite.dart';
import '../../services/work_schedule_service.dart';
import './work_invite_detail_screen.dart';
import '../../l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.workInvites),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _statusFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'all',
                child: Text(AppLocalizations.of(context)!.all),
              ),
              PopupMenuItem<String>(
                value: 'pending',
                child: Text(AppLocalizations.of(context)!.pending),
              ),
              PopupMenuItem<String>(
                value: 'accepted',
                child: Text(AppLocalizations.of(context)!.accepted),
              ),
              PopupMenuItem<String>(
                value: 'rejected',
                child: Text(AppLocalizations.of(context)!.rejected),
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
              child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.youHaveNoWorkInvites,
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
                AppLocalizations.of(context)!.youHaveNoInvitesOfType(_getStatusText(_statusFilter)),
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
        return AppLocalizations.of(context)!.pending;
      case 'accepted':
        return AppLocalizations.of(context)!.accepted;
      case 'rejected':
        return AppLocalizations.of(context)!.rejected;
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
          // Marcar como lida se estiver pendente
          if (invite.status == 'pending' && !invite.isRead) {
            _workScheduleService.markInviteAsRead(invite.id);
          }
          
          // Navegar para detalhes
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
                        child: Text(AppLocalizations.of(context)!.reject),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _respondToInvite(invite.id, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(AppLocalizations.of(context)!.accept),
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
        label = AppLocalizations.of(context)!.acceptedStatus;
        break;
      case 'rejected':
        color = Colors.red;
        label = AppLocalizations.of(context)!.rejectedStatus;
        break;
      case 'seen':
        color = Colors.orange;
        label = AppLocalizations.of(context)!.seenStatus;
        break;
      case 'pending':
      default:
        color = Colors.amber;
        label = AppLocalizations.of(context)!.pendingStatus;
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
            content: Text(status == 'accepted' 
                ? AppLocalizations.of(context)!.inviteAcceptedSuccessfully 
                : AppLocalizations.of(context)!.inviteRejectedSuccessfully),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorRespondingToInvite(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 