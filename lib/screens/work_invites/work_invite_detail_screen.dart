import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/work_invite.dart';
import '../../services/work_schedule_service.dart';

class WorkInviteDetailScreen extends StatefulWidget {
  final WorkInvite invite;
  
  const WorkInviteDetailScreen({
    Key? key,
    required this.invite,
  }) : super(key: key);

  @override
  State<WorkInviteDetailScreen> createState() => _WorkInviteDetailScreenState();
}

class _WorkInviteDetailScreenState extends State<WorkInviteDetailScreen> {
  final WorkScheduleService _workScheduleService = WorkScheduleService();
  bool _isLoading = false;
  String? _senderName;
  String? _entityImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadSenderInfo();
    _loadEntityInfo();
  }
  
  Future<void> _loadSenderInfo() async {
    try {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.invite.sentBy)
          .get();
      
      if (senderDoc.exists) {
        setState(() {
          _senderName = (senderDoc.data() as Map<String, dynamic>)['name'] ?? 'Usuario';
        });
      }
    } catch (e) {
      debugPrint('Error al cargar información del remitente: $e');
    }
  }
  
  Future<void> _loadEntityInfo() async {
    try {
      if (widget.invite.entityType == 'cult') {
        final cultDoc = await FirebaseFirestore.instance
            .collection('cults')
            .doc(widget.invite.entityId)
            .get();
        
        if (cultDoc.exists) {
          // Los cultos no suelen tener imágenes, podríamos usar una imagen predeterminada
          setState(() {
            _entityImageUrl = 'https://via.placeholder.com/150?text=Culto';
          });
        }
      } else if (widget.invite.entityType == 'event') {
        final eventDoc = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.invite.entityId)
            .get();
        
        if (eventDoc.exists) {
          setState(() {
            _entityImageUrl = (eventDoc.data() as Map<String, dynamic>)['imageUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar información de la entidad: $e');
    }
  }
  
  Future<void> _respondToInvite(String status) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _workScheduleService.respondToInvite(widget.invite.id, status);
      
      if (mounted) {
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM, yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Invitación'),
        actions: [
          if (widget.invite.status == 'pending')
            IconButton(
              icon: const Icon(Icons.done),
              tooltip: 'Aceptar',
              onPressed: () => _respondToInvite('accepted'),
            ),
          if (widget.invite.status == 'pending')
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Rechazar',
              onPressed: () => _respondToInvite('rejected'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen de la entidad
                  if (_entityImageUrl != null)
                    SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Image.network(
                        _entityImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Información de la invitación
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado de la invitación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invitación de Trabajo',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildStatusChip(widget.invite.status),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Información básica
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.invite.entityName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Fecha y hora
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dateFormat.format(widget.invite.date),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${timeFormat.format(widget.invite.startTime)} - ${timeFormat.format(widget.invite.endTime)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Detalles del trabajo
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detalles del Trabajo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Ministerio
                                Row(
                                  children: [
                                    const Icon(Icons.work, size: 16, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ministerio',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            widget.invite.ministryName,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Rol
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Rol a desempeñar',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            widget.invite.role,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Información de la invitación
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Información de la Invitación',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Enviado por
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Enviado por',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _senderName ?? 'Cargando...',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Fecha de envío
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_outlined, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Fecha de envío',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd/MM/yyyy, HH:mm').format(widget.invite.createdAt),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                if (widget.invite.respondedAt != null) ...[
                                  const SizedBox(height: 16),
                                  
                                  // Fecha de respuesta
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Fecha de respuesta',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd/MM/yyyy, HH:mm').format(widget.invite.respondedAt!),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: widget.invite.status == 'pending'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _respondToInvite('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _respondToInvite('accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            )
          : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.amber ? Colors.black : color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 