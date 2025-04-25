import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/group_event.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../widgets/event_attendees_list.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import 'package:intl/intl.dart';

class GroupEventDetailScreen extends StatefulWidget {
  final GroupEvent event;

  const GroupEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<GroupEventDetailScreen> createState() => _GroupEventDetailScreenState();
}

class _GroupEventDetailScreenState extends State<GroupEventDetailScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _attendees = [];
  bool _isJoining = false;
  String _groupName = "Grupo";
  bool _hasReminder = false;
  
  @override
  void initState() {
    super.initState();
    _loadGroupName();
    _loadAttendees();
    _checkReminder();
  }
  
  Future<void> _loadGroupName() async {
    try {
      final groupDoc = await widget.event.groupId.get();
      if (groupDoc.exists) {
        setState(() {
          _groupName = (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'Grupo';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar informações do grupo: $e');
    }
  }
  
  Future<void> _loadAttendees() async {
    try {
      final attendeesSnapshot = await FirebaseFirestore.instance
          .collection('event_attendees')
          .where('eventId', isEqualTo: widget.event.id)
          .where('eventType', isEqualTo: 'group')
          .get();
      
      if (mounted) {
        setState(() {
          _attendees = attendeesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar participantes: $e');
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
        eventType: 'group',
        entityId: widget.event.groupId.id,
        entityName: _groupName,
      );
      
      // Actualizar estado local
      setState(() {
        _hasReminder = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao configurar lembrete: $e')),
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
    
    // Obtener el grupo para verificar si es administrador
    final groupDoc = await widget.event.groupId.get();
    bool isAdmin = false;
    
    if (groupDoc.exists) {
      // Opción 1: Convertir el documento a Group y usar el método isAdmin
      try {
        final group = Group.fromFirestore(groupDoc);
        isAdmin = group.isAdmin(currentUser?.uid ?? '');
      } catch (e) {
        // Opción 2: En caso de error, verificar manualmente con los datos
        debugPrint('Error al convertir a Group: $e');
        final data = groupDoc.data() as Map<String, dynamic>?;
        final adminIds = data?['adminIds'] as List<dynamic>? ?? [];
        isAdmin = adminIds.contains(currentUser?.uid);
      }
    }
    
    if (!isCreator && !isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para eliminar este evento'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Evento'),
        content: const Text('Tem certeza de que deseja excluir este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
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
        eventType: 'group',
      );

      // Mostrar confirmación como overlay independiente
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento excluído com sucesso'),
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
            content: Text('Erro ao excluir o evento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        eventType: 'group',
        attending: attending,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attending 
              ? 'Você confirmou sua presença em "${widget.event.title}"'
              : 'Você cancelou sua presença em "${widget.event.title}"'),
          backgroundColor: attending ? Colors.green : Colors.amber,
        ),
      );
      
      // Actualizar estado local
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar presença: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isCreator = widget.event.createdBy.id == currentUser?.uid;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: CustomScrollView(
          slivers: [
            // AppBar con imagen de fondo
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen del evento
                    widget.event.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.event.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.background,
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: AppColors.mutedGray,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.mutedGray,
                            child: const Icon(
                              Icons.event,
                              size: 80,
                              color: Colors.white30,
                            ),
                          ),
                    // Gradiente para mejorar legibilidad del título
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Botón de eliminación - ahora lo mostraremos siempre y verificaremos permisos al clickear
                    Positioned(
                      bottom: 15,
                      right: 15,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Excluir Evento',
                          padding: EdgeInsets.zero,
                          splashColor: Colors.red.withOpacity(0.3),
                          onPressed: () => _deleteEvent(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Removemos el botón de acción anterior ya que ahora tenemos uno más visible
              actions: [],
            ),
            
            // Contenido del evento
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre del grupo
                    Text(
                      _groupName,
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Título del evento
                    Text(
                      widget.event.title,
                      style: AppTextStyles.headline3,
                    ),
                    
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Fecha y hora
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmSand,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "De: ${dateFormat.format(widget.event.date)}",
                            style: AppTextStyles.bodyText2.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Fecha de fin (si existe)
                    if (widget.event.endDate != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warmSand,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_available,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Até: ${dateFormat.format(widget.event.endDate!)}",
                              style: AppTextStyles.bodyText2.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Botones de acción
                    Row(
                      children: [
                        // Botón de recordatorio como IconButton
                        Container(
                          decoration: BoxDecoration(
                            color: _hasReminder ? AppColors.success : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _hasReminder ? null : _addReminder,
                            icon: Icon(
                              _hasReminder ? Icons.check_circle : Icons.notifications_active,
                              color: AppColors.textOnDark,
                              size: 28,
                            ),
                            tooltip: _hasReminder ? 'Lembrete Adicionado' : 'Adicionar Lembrete',
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<bool>(
                            future: EventService().isUserAttending(
                              eventId: widget.event.id,
                              eventType: 'group',
                            ),
                            builder: (context, snapshot) {
                              final isAttending = snapshot.data ?? false;
                              return ElevatedButton.icon(
                                onPressed: _isJoining ? null : () => _toggleAttendance(context, !isAttending),
                                icon: Icon(
                                  isAttending ? Icons.person_remove : Icons.person_add,
                                  color: AppColors.textOnDark,
                                ),
                                label: Text(
                                  isAttending ? 'Declinar' : 'Participar',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.textOnDark,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAttending ? AppColors.error : AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  elevation: 1.5,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Descripción
                    Text(
                      'Descrição',
                      style: AppTextStyles.subtitle1,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.event.description,
                        style: AppTextStyles.bodyText1,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Encabezado principal de Participantes
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                      children: [
                        const Icon(
                          Icons.people,
                            size: 24,
                            color: Colors.white,
                        ),
                          const SizedBox(width: 8),
                        Text(
                          'Participantes',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenedor para la lista de participantes
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subsección de Asistentes
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 22,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                FutureBuilder<int>(
                                  future: FirebaseFirestore.instance
                                      .collection('event_attendees')
                                      .where('eventId', isEqualTo: widget.event.id)
                                      .where('eventType', isEqualTo: 'group')
                                      .where('attending', isEqualTo: true)
                                      .get()
                                      .then((snapshot) => snapshot.docs.length),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data ?? 0;
                                    return Text(
                                      'Asistentes ($count)',
                                      style: AppTextStyles.subtitle2.copyWith(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          // Lista personalizada de asistentes
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('event_attendees')
                                  .where('eventId', isEqualTo: widget.event.id)
                                  .where('eventType', isEqualTo: 'group')
                                  .where('attending', isEqualTo: true)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                
                                final attendees = snapshot.data?.docs ?? [];
                                
                                if (attendees.isEmpty) {
                                  return Center(
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 4),
                                        const Icon(
                                          Icons.person_outline,
                                          size: 48,
                                          color: AppColors.mutedGray,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Ninguém confirmou presença ainda',
                                          style: AppTextStyles.bodyText2.copyWith(
                                            color: AppColors.mutedGray,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                return ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: attendees.length,
                                  itemBuilder: (context, index) {
                                    final attendee = attendees[index].data() as Map<String, dynamic>;
                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(attendee['userId'])
                                          .get(),
                                      builder: (context, userSnapshot) {
                                        if (!userSnapshot.hasData) {
                                          return const SizedBox.shrink();
                                        }
                                        
                                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                        if (userData == null) return const SizedBox.shrink();
                                        
                                        final name = userData['name'] ?? userData['displayName'] ?? 'Usuário';
                                        final email = userData['email'] ?? '';
                                        final photoUrl = userData['photoUrl'] ?? '';
                                        
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: photoUrl.isNotEmpty
                                                ? NetworkImage(photoUrl)
                                                : null,
                                            child: photoUrl.isEmpty
                                                ? Icon(Icons.person, color: Colors.white)
                                                : null,
                                            backgroundColor: AppColors.primary.withOpacity(0.2),
                                          ),
                                          title: Text(
                                            name,
                                            style: AppTextStyles.subtitle2,
                                          ),
                                          subtitle: Text(
                                            email,
                                            style: AppTextStyles.bodyText2,
                                          ),
                                          dense: true,
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Espacio para el área segura inferior
                    SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
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