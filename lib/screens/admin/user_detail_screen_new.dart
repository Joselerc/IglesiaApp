import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/ministry.dart';
import '../../models/work_assignment.dart';
import '../../models/time_slot.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = true;
  UserModel? _user;
  String _userDocId = '';
  List<Ministry> _ministries = [];
  Map<String, List<WorkAssignment>> _workAssignmentsByMinistry = {};
  Map<String, TimeSlot> _timeSlots = {};
  Map<String, String> _pastorNames = {};
  int _totalConfirmedServices = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cargar información del usuario
      await _fetchUserInfo();
      
      // 2. Cargar ministerios a los que pertenece
      await _fetchUserMinistries();
      
      // 3. Cargar asignaciones de trabajo (work assignments)
      await _fetchUserWorkAssignments();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando datos del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserInfo() async {
    print('🔍 Buscando usuario con email: ${widget.userId}');
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userId)
        .get();
        
    if (userDoc.docs.isNotEmpty) {
      final userData = userDoc.docs.first.data();
      _userDocId = userDoc.docs.first.id;
      _user = UserModel.fromMap({...userData, 'id': _userDocId});
      
      print('✅ Usuario encontrado. ID: $_userDocId, Email: ${_user?.email}');
    } else {
      print('⚠️ No se encontró usuario con email: ${widget.userId}');
    }
  }

  Future<void> _fetchUserMinistries() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    print('🔍 Buscando ministerios para usuario: $_userDocId');
    
    final ministryDocs = await FirebaseFirestore.instance
        .collection('ministries')
        .get();
    
    for (var doc in ministryDocs.docs) {
      final data = doc.data();
      
      // Obtener miembros y administradores
      final List<dynamic> members = data['members'] ?? [];
      final List<dynamic> admins = data['ministrieAdmin'] ?? [];
      
      // Verificar si el usuario está en la lista de miembros o administradores
      bool isInMinistry = false;
      
      // Revisar miembros
      for (var member in members) {
        String memberPath = '';
        if (member is DocumentReference) {
          memberPath = member.path;
        } else if (member is String) {
          memberPath = member;
        }
        
        if (memberPath.contains(_userDocId)) {
          isInMinistry = true;
          break;
        }
      }
      
      // Revisar administradores si no está en miembros
      if (!isInMinistry) {
        for (var admin in admins) {
          String adminPath = '';
          if (admin is DocumentReference) {
            adminPath = admin.path;
          } else if (admin is String) {
            adminPath = admin;
          }
          
          if (adminPath.contains(_userDocId)) {
            isInMinistry = true;
            break;
          }
        }
      }
      
      if (isInMinistry) {
        print('✅ Usuario pertenece al ministerio: ${doc.id} - ${data['name']}');
        final ministry = Ministry.fromFirestore(doc);
        _ministries.add(ministry);
      }
    }
    
    print('📊 Total ministerios del usuario: ${_ministries.length}');
  }

  Future<void> _fetchUserWorkAssignments() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    print('🔍 Buscando asignaciones para usuario: $_userDocId');
    
    final allAssignmentDocs = await FirebaseFirestore.instance
        .collection('workAssignments')
        .get();
    
    print('📊 Total de workAssignments para verificar: ${allAssignmentDocs.docs.length}');
    
    // Para estadísticas
    int confirmedAssignmentsCount = 0;
    
    // Mapa para guardar las asignaciones por ministerio
    Map<String, List<WorkAssignment>> assignmentsByMinistry = {};
    
    for (var doc in allAssignmentDocs.docs) {
      final data = doc.data();
      final userRef = data['userId'];
      final ministryRef = data['ministryId'];
      final status = data['status'] as String? ?? '';
      
      // Verificar si la asignación pertenece a este usuario
      bool isUserAssignment = false;
      
      if (userRef is DocumentReference && userRef.id == _userDocId) {
        isUserAssignment = true;
      } else if (userRef is String) {
        // Manejar diferentes formatos de string
        if (userRef == _userDocId || 
            userRef == '/users/$_userDocId' || 
            userRef.endsWith(_userDocId) ||
            (userRef.contains(_userDocId) && userRef.startsWith('/users/'))) {
          isUserAssignment = true;
        } else if (_user?.email != null && userRef == _user!.email) {
          isUserAssignment = true;
        }
      }
      
      // Solo considerar asignaciones del usuario con status "confirmed"
      if (isUserAssignment && status.toLowerCase() == 'confirmed') {
        // Extraer el ID del ministerio
        String? ministryId;
        
        if (ministryRef is DocumentReference) {
          ministryId = ministryRef.id;
        } else if (ministryRef is String) {
          ministryId = ministryRef;
          // Si es un path, extraer solo el ID
          if (ministryRef.startsWith('/ministries/')) {
            ministryId = ministryRef.substring('/ministries/'.length);
          }
        }
        
        if (ministryId != null) {
          // Crear objeto WorkAssignment
          final assignment = WorkAssignment.fromFirestore(doc);
          
          confirmedAssignmentsCount++;
          
          // Agrupar por ministerio
          if (!assignmentsByMinistry.containsKey(ministryId)) {
            assignmentsByMinistry[ministryId] = [];
          }
          
          assignmentsByMinistry[ministryId]!.add(assignment);
          
          // Cargar información del time slot y pastor
          await _fetchTimeSlot(assignment.timeSlotId);
          await _fetchPastorName(assignment.invitedBy);
        }
      }
    }
    
    print('📊 Total servicios confirmados: $confirmedAssignmentsCount');
    print('📊 Ministerios con asignaciones: ${assignmentsByMinistry.keys.length}');
    
    // Actualizar estado
    _totalConfirmedServices = confirmedAssignmentsCount;
    _workAssignmentsByMinistry = assignmentsByMinistry;
  }

  Future<void> _fetchTimeSlot(String timeSlotId) async {
    if (_timeSlots.containsKey(timeSlotId)) return;
    
    try {
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('timeSlots')
          .doc(timeSlotId)
          .get();
      
      if (timeSlotDoc.exists) {
        _timeSlots[timeSlotId] = TimeSlot.fromFirestore(timeSlotDoc);
      }
    } catch (e) {
      print('❌ Error al cargar timeSlot: $e');
    }
  }

  Future<void> _fetchPastorName(String pastorId) async {
    if (_pastorNames.containsKey(pastorId)) return;
    
    try {
      final pastorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(pastorId)
          .get();
      
      if (pastorDoc.exists) {
        final data = pastorDoc.data() as Map<String, dynamic>;
        _pastorNames[pastorId] = data['displayName'] ?? data['email'] ?? 'Desconocido';
      } else {
        _pastorNames[pastorId] = 'Desconocido';
      }
    } catch (e) {
      print('❌ Error al cargar nombre de pastor: $e');
      _pastorNames[pastorId] = 'Desconocido';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No disponible';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.displayName ?? 'Información del Usuario'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null 
              ? const Center(child: Text('Usuario no encontrado'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del usuario
                      _buildUserInfoCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Estadísticas generales
                      _buildStatsCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Ministerios con servicios
                      const Text(
                        'Ministerios',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF673AB7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      ..._buildMinistryCards(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _user?.photoUrl != null
                      ? NetworkImage(_user!.photoUrl!)
                      : null,
                  child: _user?.photoUrl == null
                      ? Text(
                          _user?.name?[0] ?? _user?.email[0] ?? '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold, 
                            color: Color(0xFF673AB7),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.displayName ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF673AB7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Teléfono (si existe)
          if (_user?.phone != null)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                leading: Icon(Icons.phone, color: Colors.grey.shade600),
                title: Text(
                  _user!.phone!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                dense: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Estadísticas Generales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF673AB7),
              ),
            ),
          ),
          // Stats
          Divider(height: 1, color: Colors.grey.shade200),
          _buildStatRow(
            icon: Icons.work,
            label: 'Total de servicios realizados',
            value: _totalConfirmedServices.toString(),
            iconColor: const Color(0xFF42A5F5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMinistryCards() {
    if (_workAssignmentsByMinistry.isEmpty) {
      return [
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'No ha realizado servicios confirmados',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    List<Widget> ministryCards = [];
    
    // Para cada ministerio con asignaciones
    _workAssignmentsByMinistry.forEach((ministryId, assignments) {
      // Buscar el ministerio en la lista de ministerios del usuario
      final ministry = _ministries.firstWhere(
        (m) => m.id == ministryId,
        orElse: () => Ministry(
          id: ministryId,
          name: 'Ministerio $ministryId',
          description: '',
          imageUrl: '',
          adminIds: [],
          memberIds: [],
          pendingRequests: {},
          rejectedRequests: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      // Crear tarjeta para este ministerio
      final card = Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE1BEE7),
            child: const Icon(Icons.people_alt, color: Color(0xFF673AB7)),
          ),
          title: Text(
            ministry.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF673AB7),
            ),
          ),
          subtitle: Text('${assignments.length} servicios realizados'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Servicios Realizados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF673AB7),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final timeSlot = _timeSlots[assignment.timeSlotId];
                final pastorName = _pastorNames[assignment.invitedBy] ?? 'Desconocido';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Color(0xFF673AB7)),
                            const SizedBox(width: 8),
                            Text(
                              'Rol: ${assignment.role}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (timeSlot != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.event_note, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Servicio: ${timeSlot.name}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Fecha: ${_formatDate(timeSlot.startTime)}'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_pin, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Asignado por: $pastorName'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Estado: Confirmado',
                              style: TextStyle(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
      
      ministryCards.add(card);
    });
    
    return ministryCards;
  }
} 