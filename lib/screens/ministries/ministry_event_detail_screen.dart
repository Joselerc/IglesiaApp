import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/ministry_event.dart';
import '../../models/ministry.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class MinistryEventDetailScreen extends StatefulWidget {
  final MinistryEvent event;

  const MinistryEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<MinistryEventDetailScreen> createState() => _MinistryEventDetailScreenState();
}

class _MinistryEventDetailScreenState extends State<MinistryEventDetailScreen> {
  bool _isLoading = false;
  bool _isJoining = false;
  String _ministryName = ""; // Se cargará dinámicamente
  bool _hasReminder = false;
  
  @override
  void initState() {
    super.initState();
    _loadMinistryName();
    _checkReminder();
  }
  
  Future<void> _loadMinistryName() async {
    try {
      final ministryDoc = await widget.event.ministryId.get();
      if (ministryDoc.exists) {
        setState(() {
          _ministryName = (ministryDoc.data() as Map<String, dynamic>)['name'] ?? 'Ministério';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar informações do ministério: $e');
    }
  }
  
  Future<void> _checkReminder() async {
    try {
      final userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
      if (userId == null) return;
      
      final reminderSnapshot = await FirebaseFirestore.instance
          .collection('event_reminders')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: widget.event.id)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (mounted) {
        setState(() {
          _hasReminder = reminderSnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar lembrete: $e');
    }
  }
  
  Future<void> _addReminder() async {
    if (_isJoining) return;
    
    setState(() {
      _isJoining = true;
    });
    
    try {
      await EventService().addEventReminder(
        eventId: widget.event.id,
        eventTitle: widget.event.title,
        eventDate: widget.event.date,
        eventType: 'ministry',
        entityId: widget.event.ministryId.id,
        entityName: _ministryName,
      );
      
      // Actualizar estado local
      setState(() {
        _hasReminder = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSettingReminder(e.toString()))),
        );
      }
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<void> _deleteEvent(BuildContext context) async {
    // Verificar permisos para eliminar
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final isCreator = widget.event.createdBy.id == currentUser?.uid;
    
    // Obtener el ministerio para verificar si es administrador
    final ministryDoc = await widget.event.ministryId.get();
    bool isAdmin = false;
    
    if (ministryDoc.exists) {
      // Opción 1: Convertir el documento a Ministry y usar el método isAdmin
      try {
        final ministry = Ministry.fromFirestore(ministryDoc);
        isAdmin = ministry.isAdmin(currentUser?.uid ?? '');
      } catch (e) {
        // Opción 2: En caso de error, verificar manualmente con los datos
        debugPrint('Error al convertir a Ministry: $e');
        final data = ministryDoc.data() as Map<String, dynamic>?;
        final adminIds = data?['adminIds'] as List<dynamic>? ?? [];
        isAdmin = adminIds.contains(currentUser?.uid);
      }
    }
    
    if (!isCreator && !isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noPermissionToDeleteEvent),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteEvent),
        content: Text(AppLocalizations.of(context)!.sureDeleteEvent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldDelete) return;
    
    try {
      // Navegar primero para mejorar la velocidad percibida
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Luego eliminar en segundo plano
      await EventService().deleteEvent(
        eventId: widget.event.id,
        eventType: 'ministry',
      );

      // Mostrar confirmación como overlay independiente
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.eventDeletedSuccessfully),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDeletingEvent(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildDetailRow(IconData icon, String text, {Color? color, bool isBold = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyText1.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para marcar/desmarcar asistencia
  Future<void> _toggleAttendance(BuildContext context, bool attending) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await EventService().markAttendance(
        eventId: widget.event.id,
        userId: Provider.of<AuthService>(context, listen: false).currentUser!.uid,
        eventType: 'ministry',
        attending: attending,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attending 
                ? AppLocalizations.of(context)!.youConfirmedAttendance
                : AppLocalizations.of(context)!.youCancelledAttendance),
            backgroundColor: attending ? Colors.green : Colors.amber,
          ),
        );
      }
      
      // Actualizar estado local
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingAttendance(e.toString())),
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
    final dateFormat = DateFormat('EEEE, d MMMM • HH:mm', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // AppBar (estilo limpio Google Calendar)
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black, 
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.event.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.mutedGray),
                      )
                    : Container(color: AppColors.primary.withOpacity(0.1)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black12],
                          stops: [0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteEvent(context),
                  tooltip: AppLocalizations.of(context)!.deleteEvent,
                ),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Fecha y Hora
                    _buildDetailRow(
                      Icons.access_time,
                      widget.event.endDate != null
                          ? '${dateFormat.format(widget.event.date)} – ${timeFormat.format(widget.event.endDate!)}'
                          : dateFormat.format(widget.event.date),
                    ),

                    // Nombre del Ministerio
                    if (_ministryName.isNotEmpty)
                      _buildDetailRow(
                        Icons.church_outlined,
                        _ministryName,
                        color: AppColors.primary,
                        isBold: true,
                      ),

                    // Organizado por
                    FutureBuilder<DocumentSnapshot>(
                      future: widget.event.createdBy.get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        
                        // Lógica para obtener nombre completo
                        String creatorName = 'Usuario';
                        if (userData != null) {
                          if (userData['displayName'] != null && userData['displayName'].toString().isNotEmpty) {
                            creatorName = userData['displayName'];
                          } else if (userData['name'] != null && userData['surname'] != null) {
                            creatorName = '${userData['name']} ${userData['surname']}';
                          } else if (userData['name'] != null) {
                            creatorName = userData['name'];
                          }
                        }
                        
                        return _buildDetailRow(
                          Icons.person_outline,
                          '${AppLocalizations.of(context)!.organizedBy} $creatorName',
                          color: Colors.grey[700],
                        );
                      },
                    ),
                      
                    // Ubicación
                    if (widget.event.location.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            Icons.location_on_outlined,
                            widget.event.location,
                            isBold: true, // Nombre en negrita
                          ),
                          if (widget.event.address != null && widget.event.address!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 36, bottom: 16), // Indentación para alinear
                              child: Text(
                                widget.event.address!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 8),
                    const Divider(height: 32),
                    
                    // Descripción
                    if (widget.event.description.isNotEmpty) ...[
                      _buildDetailRow(
                        Icons.subject,
                        widget.event.description,
                      ),
                      const Divider(height: 32),
                    ],

                    // Botones de Acción
                    Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<bool>(
                            future: EventService().isUserAttending(
                              eventId: widget.event.id,
                              eventType: 'ministry',
                            ),
                            builder: (context, snapshot) {
                              final isAttending = snapshot.data ?? false;
                              
                              if (!isAttending) {
                                // Estado: NO Asiste -> Botón llamativo para participar
                                return ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _toggleAttendance(context, true),
                                  icon: const Icon(Icons.person_add, color: Colors.white),
                                  label: Text(
                                    AppLocalizations.of(context)!.participate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              } else {
                                // Estado: YA Asiste -> Botón discreto para cancelar
                                return OutlinedButton.icon(
                                  onPressed: _isLoading ? null : () => _toggleAttendance(context, false),
                                  icon: const Icon(Icons.check_circle, color: AppColors.success),
                                  label: Text(
                                    AppLocalizations.of(context)!.youAreGoing,
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: AppColors.success),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filledTonal(
                          onPressed: _hasReminder ? null : _addReminder,
                          icon: Icon(
                            _hasReminder ? Icons.notifications_active : Icons.notifications_none,
                            color: _hasReminder ? AppColors.primary : Colors.black87,
                          ),
                          tooltip: AppLocalizations.of(context)!.addReminder,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Participantes
                    Text(
                      AppLocalizations.of(context)!.participants,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lista
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('event_attendees')
                          .where('eventId', isEqualTo: widget.event.id)
                          .where('eventType', isEqualTo: 'ministry')
                          .where('attending', isEqualTo: true)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final attendees = snapshot.data!.docs;
                        
                        if (attendees.isEmpty) {
                          return Text(
                            AppLocalizations.of(context)!.noOneConfirmedYet,
                            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          );
                        }

                        return Column(
                          children: attendees.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
                              builder: (context, userSnap) {
                                if (!userSnap.hasData) return const SizedBox.shrink();
                                final user = userSnap.data!.data() as Map<String, dynamic>;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundImage: user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                                        ? NetworkImage(user['photoUrl'])
                                        : null,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    child: user['photoUrl'] == null || user['photoUrl'].isEmpty
                                        ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                                        : null,
                                    radius: 16,
                                  ),
                                  title: Text(
                                    user['name'] ?? 'Usuario',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  dense: true,
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 