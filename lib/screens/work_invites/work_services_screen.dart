import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/work_schedule_service.dart';

class WorkServicesScreen extends StatefulWidget {
  const WorkServicesScreen({Key? key}) : super(key: key);

  @override
  State<WorkServicesScreen> createState() => _WorkServicesScreenState();
}

class _WorkServicesScreenState extends State<WorkServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isMemberOfMinistry = false;
  String _userId = '';
  
  // Key para forzar reconstrucción de las invitaciones
  Key _invitationsStreamKey = UniqueKey();
  
  // Key para forzar reconstrucción de las asignaciones
  Key _assignmentsStreamKey = UniqueKey();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    
    // Añadir verificación de invitaciones rechazadas para depuración
    _checkRejectedInvitations();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _isMemberOfMinistry = false;
        });
        return;
      }
      
      _userId = currentUser.uid;
      
      // Comprobar si el usuario pertenece a algún ministerio
      // Método 1: Verificar en la colección ministry_members
      final ministriesSnapshot = await FirebaseFirestore.instance
          .collection('ministry_members')
          .where('userId', isEqualTo: _userId) // Usar el ID como string en lugar de DocumentReference
          .where('isActive', isEqualTo: true)
          .get();
          
      // Si no encontramos membresía en ministry_members, probar directamente en la colección ministries
      if (ministriesSnapshot.docs.isEmpty) {
        debugPrint('No se encontraron membresías en ministry_members, verificando en ministries...');
        
        // Buscar ministerios que tengan al usuario en su lista de miembros
        final ministriesQuery = await FirebaseFirestore.instance
            .collection('ministries')
            .get();
            
        bool foundInMinistry = false;
        
        for (var doc in ministriesQuery.docs) {
          final data = doc.data();
          if (data.containsKey('members') && data['members'] is List) {
            final members = data['members'] as List;
            
            // Verificar si el usuario está en la lista de miembros
            bool userFound = members.any((member) {
              if (member is DocumentReference) {
                return member.id == _userId;
              } else if (member is String) {
                return member == _userId;
              } else if (member is Map && member['id'] != null) {
                return member['id'] == _userId;
              }
              return false;
            });
            
            if (userFound) {
              foundInMinistry = true;
              break;
            }
          }
        }
        
        setState(() {
          _isLoading = false;
          _isMemberOfMinistry = foundInMinistry;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isMemberOfMinistry = true;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos de usuario: $e');
      setState(() {
        _isLoading = false;
        _isMemberOfMinistry = false;
      });
    }
  }

  // Método para verificar invitaciones rechazadas (solo para depuración)
  Future<void> _checkRejectedInvitations() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      // Buscar invitaciones rechazadas
      final rejectedInvitesSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('userId', isEqualTo: userRef)
          .where('isRejected', isEqualTo: true)
          .get();
          
      debugPrint('🔍 Encontradas ${rejectedInvitesSnapshot.docs.length} invitaciones rechazadas por isRejected=true');
      
      // Buscar invitaciones con status=rejected
      final rejectedByStatusSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('userId', isEqualTo: userRef)
          .where('status', isEqualTo: 'rejected')
          .get();
          
      debugPrint('🔍 Encontradas ${rejectedByStatusSnapshot.docs.length} invitaciones rechazadas por status=rejected');
      
      // Buscar invitaciones pendientes
      final pendingInvitesSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('userId', isEqualTo: userRef)
          .where('status', isEqualTo: 'pending')
          .where('isActive', isEqualTo: true)
          .where('isVisible', isEqualTo: true)
          .get();
          
      debugPrint('🔍 Encontradas ${pendingInvitesSnapshot.docs.length} invitaciones pendientes activas y visibles');
      
    } catch (e) {
      debugPrint('Error al verificar invitaciones rechazadas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Escalas'),
        bottom: _isMemberOfMinistry ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Convites'),
            Tab(text: 'Designações'),
          ],
          indicatorColor: Colors.deepPurple,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          dividerColor: Colors.transparent,
        ) : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isMemberOfMinistry
              ? _buildNotMemberView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvitationsTab(),
                    _buildAssignmentsTab(),
                  ],
                ),
    );
  }
  
  Widget _buildNotMemberView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Você não pertence a nenhum ministério',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Para receber convites e designações de trabalho, você deve ser membro de pelo menos um ministério.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la pantalla de ministerios para unirse
                Navigator.pushNamed(context, '/ministries');
              },
              icon: const Icon(Icons.search),
              label: const Text('Explorar Ministérios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvitationsTab() {
    return StreamBuilder<QuerySnapshot>(
      key: _invitationsStreamKey, // Usar la clave para forzar reconstrucción completa
      stream: FirebaseFirestore.instance
          .collection('work_invites')
          .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(_userId))
          .where('isActive', isEqualTo: true)
          .where('isVisible', isEqualTo: true)
          .where('status', whereIn: ['pending', 'seen'])
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Você não tem convites pendentes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Neste momento não há convites disponíveis para você. Isso pode ocorrer porque as funções já estão ocupadas ou porque não há serviços programados em breve.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Quando um líder te convidar para servir, os convites aparecerão aqui.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final invite = snapshot.data!.docs[index];
            final data = invite.data() as Map<String, dynamic>;
            
            // Extraer los datos necesarios
            final String inviteId = invite.id;
            final String? assignmentId = data['assignmentId'];
            final String ministryName = data['ministryName'] ?? 'Ministério';
            final String role = data['role'] ?? 'Função';
            final DateTime startTime = (data['startTime'] as Timestamp).toDate();
            final DateTime endTime = (data['endTime'] as Timestamp).toDate();
            final String entityName = data['entityName'] ?? '';
            final String entityType = data['entityType'] ?? '';
            
            // Determinar el tipo de entidad (culto, evento, etc.)
            String typeLabel = 'Atividade';
            IconData typeIcon = Icons.event;
            
            switch (entityType) {
              case 'cult':
                typeLabel = 'Culto';
                typeIcon = Icons.church;
                break;
              case 'event':
                typeLabel = 'Evento';
                typeIcon = Icons.celebration;
                break;
              case 'meeting':
                typeLabel = 'Reunião';
                typeIcon = Icons.group;
                break;
            }
            
            // Formatear fechas
            final dateFormatter = DateFormat('EEE, d MMM', 'pt_BR');
            final timeFormatter = DateFormat('HH:mm');
            final dateStr = dateFormatter.format(startTime);
            final timeStr = '${timeFormatter.format(startTime)} - ${timeFormatter.format(endTime)}';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$typeLabel: $entityName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ministryName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await _respondToInvite(inviteId, assignmentId, 'rejected');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Rejeitar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await _respondToInvite(inviteId, assignmentId, 'accepted');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aceitar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _respondToInvite(String inviteId, String? assignmentId, String status) async {
    try {
      debugPrint('======== RESPONDIENDO A INVITACIÓN ========');
      debugPrint('ID Invitación: $inviteId');
      debugPrint('ID Asignación: $assignmentId');
      debugPrint('Estado: $status');
      
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando resposta...'),
            ],
          ),
        ),
      );
      
      debugPrint('Llamando a WorkScheduleService().updateAssignmentStatus()');
      
      // Siempre usar el servicio para manejar las respuestas a invitaciones
      await WorkScheduleService().updateAssignmentStatus(inviteId, status);
      
      debugPrint('✅ Respuesta procesada correctamente');
      
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Forzar actualización de la UI generando una nueva clave para el StreamBuilder
      setState(() {
        debugPrint('⚡ Actualizando UI con nueva clave para StreamBuilder');
        _invitationsStreamKey = UniqueKey();
      });
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'accepted'
              ? 'Você aceitou o convite'
              : 'Você rejeitou o convite'),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ),
      );
      
      debugPrint('✅ Respuesta a invitación completada con éxito');
    } catch (e) {
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar a resposta: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Mostrar información detallada del error
      debugPrint('❌ ERROR al procesar resposta: $e');
      debugPrint('Tipo de error: ${e.runtimeType}');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
  
  Widget _buildAssignmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      key: _assignmentsStreamKey, // Usar la clave para forzar reconstrucción
      stream: FirebaseFirestore.instance
          .collection('work_assignments')
          .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(_userId))
          .where('isActive', isEqualTo: true)
          .where('status', whereIn: ['accepted', 'confirmed'])
          .orderBy('timeSlotId')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Você não tem designações ativas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final assignment = snapshot.data!.docs[index];
            final data = assignment.data() as Map<String, dynamic>;
            
            // Extraer los datos necesarios
            final String assignmentId = assignment.id;
            final String timeSlotId = data['timeSlotId'] ?? '';
            final DocumentReference ministryRef = data['ministryId'];
            final String role = data['role'] ?? 'Função';
            final String status = data['status'] ?? 'accepted';
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('time_slots').doc(timeSlotId).get(),
              builder: (context, timeSlotSnapshot) {
                if (timeSlotSnapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                
                if (!timeSlotSnapshot.hasData || !timeSlotSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                
                final timeSlotData = timeSlotSnapshot.data!.data() as Map<String, dynamic>;
                final String entityId = timeSlotData['entityId'] ?? '';
                final String entityType = timeSlotData['entityType'] ?? '';
                final DateTime startTime = (timeSlotData['startTime'] as Timestamp).toDate();
                final DateTime endTime = (timeSlotData['endTime'] as Timestamp).toDate();
                final String timeSlotName = timeSlotData['name'] ?? 'Faixa Horária';
                
                return FutureBuilder<DocumentSnapshot>(
                  future: ministryRef.get(),
                  builder: (context, ministrySnapshot) {
                    String ministryName = 'Ministério';
                    
                    if (ministrySnapshot.hasData && ministrySnapshot.data!.exists) {
                      final ministryData = ministrySnapshot.data!.data() as Map<String, dynamic>;
                      ministryName = ministryData['name'] ?? 'Ministério';
                    }
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: entityType == 'cult'
                          ? FirebaseFirestore.instance.collection('cults').doc(entityId).get()
                          : entityType == 'event'
                              ? FirebaseFirestore.instance.collection('events').doc(entityId).get()
                              : null,
                      builder: (context, entitySnapshot) {
                        String entityName = 'Atividade';
                        DateTime date = startTime;
                        
                        if (entitySnapshot != null && entitySnapshot.hasData && entitySnapshot.data!.exists) {
                          final entityData = entitySnapshot.data!.data() as Map<String, dynamic>;
                          entityName = entityType == 'cult'
                              ? entityData['name'] ?? 'Culto'
                              : entityData['title'] ?? 'Evento';
                              
                          if (entityType == 'cult' && entityData.containsKey('date')) {
                            date = (entityData['date'] as Timestamp).toDate();
                          } else if (entityType == 'event' && entityData.containsKey('date')) {
                            date = (entityData['date'] as Timestamp).toDate();
                          }
                        }
                        
                        // Determinar el tipo de entidad (culto, evento, etc.)
                        String typeLabel = 'Atividade';
                        IconData typeIcon = Icons.event;
                        
                        switch (entityType) {
                          case 'cult':
                            typeLabel = 'Culto';
                            typeIcon = Icons.church;
                            break;
                          case 'event':
                            typeLabel = 'Evento';
                            typeIcon = Icons.celebration;
                            break;
                          case 'meeting':
                            typeLabel = 'Reunião';
                            typeIcon = Icons.group;
                            break;
                        }
                        
                        // Formatear fechas
                        final dateFormatter = DateFormat('EEE, d MMM', 'pt_BR');
                        final timeFormatter = DateFormat('HH:mm');
                        final dateStr = dateFormatter.format(date);
                        final timeStr = '${timeFormatter.format(startTime)} - ${timeFormatter.format(endTime)}';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(typeIcon, color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$typeLabel: $entityName',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'confirmed'
                                            ? Colors.green[100]
                                            : Colors.blue[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status == 'confirmed' ? 'Confirmado' : 'Aceito',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == 'confirmed'
                                              ? Colors.green[900]
                                              : Colors.blue[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeSlotName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeStr,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ministryName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.purple[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (status == 'accepted')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () async {
                                            await _cancelAssignment(assignmentId);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                          ),
                                          child: const Text('Cancelar'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  
  Future<void> _cancelAssignment(String assignmentId) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Designação'),
        content: const Text('Tem certeza de que deseja cancelar esta designação? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, cancelar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cancelando designação...'),
            ],
          ),
        ),
      );
      
      debugPrint('Cancelando designação com ID: $assignmentId');
      
      // En lugar de passar directamente o assignmentId, precisamos buscar a invitação
      // relacionada com esta designação e usar esse ID com updateAssignmentStatus
      
      // Buscar invitação correspondente a esta designação
      final invitesSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('assignmentId', isEqualTo: assignmentId)
          .limit(1)
          .get();
      
      if (invitesSnapshot.docs.isNotEmpty) {
        final inviteId = invitesSnapshot.docs.first.id;
        debugPrint('Encontrada invitação com ID: $inviteId para a designação: $assignmentId');
        
        // Usar o inviteId para atualizar o estado
        await WorkScheduleService().updateAssignmentStatus(inviteId, 'rejected');
      } else {
        // Se não houver invitação, atualizar a designação diretamente
        debugPrint('⚠️ No se encontró invitação para a designação: $assignmentId. Actualizando diretamente.');
        await FirebaseFirestore.instance
            .collection('work_assignments')
            .doc(assignmentId)
            .update({
              'status': 'rejected',
              'isActive': false, 
              'updatedAt': Timestamp.now(),
            });
      }
      
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Forzar atualização da UI para que a designação desapareça imediatamente
      setState(() {
        _assignmentsStreamKey = UniqueKey();
      });
      
      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você cancelou a designação'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar a designação: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Imprimir detalhes do erro para diagnóstico
      debugPrint('❌ ERROR ao cancelar designação: $e');
      debugPrint('Tipo de erro: ${e.runtimeType}');
    }
  }
} 