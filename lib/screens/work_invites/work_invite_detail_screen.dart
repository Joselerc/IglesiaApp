import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/work_invite.dart';
import '../../services/work_schedule_service.dart';
import '../../l10n/app_localizations.dart';

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
  String? _senderPhoto;
  bool _isRecipient = false;
  
  @override
  void initState() {
    super.initState();
    _checkIfRecipient();
    _loadSenderInfo();
  }
  
  void _checkIfRecipient() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _isRecipient = currentUser.uid == widget.invite.userId;
      });
    }
  }
  
  Future<void> _loadSenderInfo() async {
    try {
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.invite.sentBy)
          .get();
      
      if (senderDoc.exists && mounted) {
        final data = senderDoc.data() as Map<String, dynamic>;
        setState(() {
          _senderName = data['displayName'] ?? 
                        '${data['name'] ?? ''} ${data['surname'] ?? ''}'.trim();
          _senderPhoto = data['photoUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error al cargar información del remitente: $e');
    }
  }
  
  Future<void> _respondToInvite(String status) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _workScheduleService.updateAssignmentStatus(widget.invite.id, status);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  status == 'accepted' ? Icons.check_circle : Icons.info,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status == 'accepted' 
                      ? AppLocalizations.of(context)!.invitationAccepted 
                      : AppLocalizations.of(context)!.invitationRejected
                  ),
                ),
              ],
            ),
            backgroundColor: status == 'accepted' ? Colors.green.shade600 : Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.invitationDetails,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getStatusColor(widget.invite.status).withOpacity(0.1),
                          _getStatusColor(widget.invite.status).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.invite.status).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(widget.invite.status),
                            size: 48,
                            color: _getStatusColor(widget.invite.status),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getStatusLabel(widget.invite.status),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.invite.status),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.workInvitation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Culto info
                        _buildSection(
                          title: widget.invite.entityName,
                          icon: Icons.church_rounded,
                          iconColor: Colors.blue,
                          children: [
                            _buildInfoRow(
                              icon: Icons.calendar_today_rounded,
                              label: dateFormat.format(widget.invite.date),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.access_time_rounded,
                              label: '${timeFormat.format(widget.invite.startTime)} - ${timeFormat.format(widget.invite.endTime)}',
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Detalles del trabajo
                        _buildSection(
                          title: AppLocalizations.of(context)!.jobDetails,
                          icon: Icons.work_rounded,
                          iconColor: Colors.purple,
                          children: [
                            _buildDetailRow(
                              label: AppLocalizations.of(context)!.ministries,
                              value: widget.invite.ministryName,
                              icon: Icons.people_rounded,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              label: AppLocalizations.of(context)!.roleToPerform,
                              value: widget.invite.role,
                              icon: Icons.person_rounded,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Información de la invitación
                        _buildSection(
                          title: AppLocalizations.of(context)!.invitationInfo,
                          icon: Icons.info_rounded,
                          iconColor: Colors.orange,
                          children: [
                            // Enviado por
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _senderPhoto != null && _senderPhoto!.isNotEmpty
                                      ? NetworkImage(_senderPhoto!)
                                      : null,
                                  child: _senderPhoto == null || _senderPhoto!.isEmpty
                                      ? Icon(Icons.person, color: Colors.grey.shade600)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.sentBy,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _senderName ?? AppLocalizations.of(context)!.loading,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              label: AppLocalizations.of(context)!.sentDate,
                              value: DateFormat('dd/MM/yyyy, HH:mm').format(widget.invite.createdAt),
                              icon: Icons.send_rounded,
                            ),
                            if (widget.invite.respondedAt != null) ...[
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                label: AppLocalizations.of(context)!.responseDate,
                                value: DateFormat('dd/MM/yyyy, HH:mm').format(widget.invite.respondedAt!),
                                icon: Icons.check_circle_rounded,
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isRecipient && widget.invite.status == 'pending'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _respondToInvite('rejected'),
                        icon: const Icon(Icons.close_rounded),
                        label: Text(AppLocalizations.of(context)!.reject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade600, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _respondToInvite('accepted'),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(AppLocalizations.of(context)!.accept),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
