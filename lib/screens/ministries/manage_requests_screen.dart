import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ministry.dart';
import '../../services/ministry_service.dart';
import '../../services/membership_request_service.dart';
import '../../theme/app_colors.dart';

class ManageRequestsScreen extends StatefulWidget {
  final Ministry ministry;

  const ManageRequestsScreen({
    super.key,
    required this.ministry,
  });

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> with SingleTickerProviderStateMixin {
  final MinistryService _ministryService = MinistryService();
  final MembershipRequestService _requestService = MembershipRequestService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingRequests = [];
  int _totalRequests = 0;
  int _acceptedRequests = 0;
  int _rejectedRequests = 0;
  int _exitedMembers = 0;
  late TabController _tabController;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPendingRequests();
    _loadStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _requestService.getRequestStats(
        widget.ministry.id, 
        'ministry'
      );
      
      // Obtener la cantidad de usuarios que han salido del ministerio
      final exitsSnapshot = await FirebaseFirestore.instance
          .collection('member_exits')
          .where('entityId', isEqualTo: widget.ministry.id)
          .where('entityType', isEqualTo: 'ministry')
          .count()
          .get();
      
      final exitCount = exitsSnapshot.count ?? 0;
      
      if (mounted) {
        setState(() {
          _totalRequests = stats['totalRequests'];
          _acceptedRequests = stats['acceptedRequests'];
          _rejectedRequests = stats['rejectedRequests'];
          _exitedMembers = exitCount;
        });
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = <Map<String, dynamic>>[];
      
      // Usar el nuevo servicio para obtener las solicitudes pendientes
      final snapshot = await _requestService.getPendingRequests(
        widget.ministry.id, 
        'ministry'
      ).first;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
          
          requests.add({
          'id': doc.id,
          'userId': data['userId'],
          'name': data['userName'] ?? 'Usuario desconocido',
          'email': data['userEmail'] ?? 'Sin email',
          'photoUrl': data['userPhotoUrl'],
          'requestDate': (data['requestTimestamp'] as Timestamp).toDate(),
          'message': data['message'],
        });
      }
      
      // Ordenar por fecha (más reciente primero)
      requests.sort((a, b) => 
        (b['requestDate'] as DateTime).compareTo(a['requestDate'] as DateTime)
      );
      
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptRequest(String userId, String requestId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Aceptar solicitud en el ministerio
      await _ministryService.acceptJoinRequest(userId, widget.ministry.id);
      
      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((request) => request['userId'] == userId);
          _acceptedRequests++;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud aceptada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(String userId, String requestId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Rechazar solicitud en el ministerio
      await _ministryService.rejectJoinRequest(userId, widget.ministry.id);
      
      // Actualizar la lista localmente
      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((req) => req['userId'] == userId);
          _rejectedRequests++;
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud rechazada'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addUserToMinistry(String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }
      
      // Obtener información del usuario actual (admin)
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final adminName = adminDoc.exists 
          ? (adminDoc.data()?['name'] ?? 'Administrador') 
          : 'Administrador';
      
      // Obtener información del usuario que se va a añadir
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? userData['displayName'] ?? 'Usuario';
      final userEmail = userData['email'] ?? '';
      final userPhotoUrl = userData['photoUrl'] ?? '';
      
      print('Añadiendo usuario: $userId - $userName - $userEmail');
      
      // Agregar el usuario al ministerio
      await _ministryService.addUserToMinistry(userId, widget.ministry.id);
      
      // Registrar en la colección membership_requests que fue añadido directamente
      await FirebaseFirestore.instance.collection('membership_requests').add({
        'userId': userId,
        'entityId': widget.ministry.id,
        'entityType': 'ministry',
        'requestTimestamp': FieldValue.serverTimestamp(),
        'responseTimestamp': FieldValue.serverTimestamp(),
        'status': 'accepted',
        'addedBy': currentUser.uid,
        'addedByName': adminName,
        'directAdd': true,
        'userName': userName,
        'userEmail': userEmail,
        'userPhotoUrl': userPhotoUrl,
      });
      
      // Incrementar contador de aceptados sólo si el widget sigue montado
      if (mounted) {
        setState(() {
          _acceptedRequests++;
        });
      }
      
    } catch (e) {
      print('Error al añadir usuario: $e');
      throw Exception('Error al añadir usuario: $e');
    }
  }

  void _showAddUsersModal() {
    if (!mounted) return;
    
    final selectedUsers = <String>{};
    List<Map<String, dynamic>> allUsers = [];
    List<Map<String, dynamic>> filteredUsers = [];
    
    // Obtener los IDs de miembros actuales para excluirlos
    final memberIds = widget.ministry.memberIds;
    
    print('Ministerio miembros actuales: ${memberIds.length}');
    print('IDs de miembros del ministerio: $memberIds');
    
    // Mostrar carga
    setState(() {
      _isLoading = true;
    });
    
    // Obtener todos los usuarios
    FirebaseFirestore.instance.collection('users').get().then((snapshot) {
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;
      
      // Limpiar loading
      setState(() {
        _isLoading = false;
      });
      
      // Filtrar usuarios
      for (var doc in snapshot.docs) {
        // Comprobar si el usuario ya es miembro
        final isMember = memberIds.contains(doc.id);
        
        if (isMember) {
          print('Usuario ministerio ${doc.id} (${doc['name'] ?? 'sin nombre'}) es miembro');
        }
        
        // Añadir todos los usuarios, pero marcar los que ya son miembros
        allUsers.add({
          'id': doc.id,
          'name': doc['name'] ?? doc['displayName'] ?? 'Usuario sin nombre',
          'email': doc['email'] ?? '',
          'photoUrl': doc['photoUrl'] ?? '',
          'isMember': isMember,
        });
      }
      
      // Inicializar la lista filtrada con solo los usuarios que NO son miembros
      filteredUsers = allUsers.where((user) => !(user['isMember'] as bool))
          .toList()
          .cast<Map<String, dynamic>>();
      
      print('Total de usuarios: ${allUsers.length}');
      print('Usuarios filtrados (no miembros): ${filteredUsers.length}');
      
      // Mostrar modal solo si el widget sigue montado
      if (mounted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                // Variables para búsqueda y filtrado
                String searchQuery = '';
                bool showOnlyNonMembers = true; // Por defecto, mostrar solo los que no son miembros
                
                // Función para filtrar usuarios
                void filterUsers(String query) {
                  setModalState(() {
                    searchQuery = query;
                    
                    // Primero, decidir si aplicamos el filtro de membresía
                    List<Map<String, dynamic>> baseList = showOnlyNonMembers
                        ? allUsers.where((user) => !(user['isMember'] as bool))
                            .toList()
                            .cast<Map<String, dynamic>>()
                        : List<Map<String, dynamic>>.from(allUsers);
                    
                    // Luego, aplicar filtro de búsqueda si hay una consulta
                    if (query.isNotEmpty) {
                      filteredUsers = baseList
                          .where((user) =>
                            user['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                            user['email'].toString().toLowerCase().contains(query.toLowerCase())
                          )
                          .toList()
                          .cast<Map<String, dynamic>>();
                    } else {
                      filteredUsers = baseList;
                    }
                    
                    print('Filtrados ministerio: ${filteredUsers.length} usuarios (solo no miembros: $showOnlyNonMembers)');
                  });
                }
                
                return Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera y botón de cerrar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Adicionar usuários',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      
                      // Campo de búsqueda
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Buscar usuários...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        controller: TextEditingController(text: searchQuery),
                        onChanged: filterUsers,
                      ),
                      
                      // Opciones de filtro
                      Row(
                        children: [
                          Checkbox(
                            value: showOnlyNonMembers,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setModalState(() {
                                showOnlyNonMembers = value ?? true;
                                filterUsers(searchQuery);
                              });
                            },
                          ),
                          const Text('Mostrar solo usuarios que no son miembros'),
                        ],
                      ),
                      
                      // Contador de seleccionados
                      Text(
                        'Usuários selecionados: ${selectedUsers.length}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Lista de usuarios
                      Expanded(
                        child: filteredUsers.isEmpty
                          ? Center(
                              child: Text('Nenhum usuário encontrado',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isSelected = selectedUsers.contains(user['id']);
                              final isMember = user['isMember'] as bool;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                                      ? NetworkImage(user['photoUrl'])
                                      : null,
                                    child: user['photoUrl'] == null || user['photoUrl'].isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user['name'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isMember)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            'Membro',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    user['email'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isMember
                                    ? Icon(Icons.check_circle, color: AppColors.primary)
                                    : Checkbox(
                                        value: isSelected,
                                        activeColor: AppColors.primary,
                                        onChanged: (value) {
                                          setModalState(() {
                                            if (value == true) {
                                              selectedUsers.add(user['id']);
                                            } else {
                                              selectedUsers.remove(user['id']);
                                            }
                                          });
                                        },
                                      ),
                                  onTap: isMember
                                    ? null // No hacer nada si ya es miembro
                                    : () {
                                        setModalState(() {
                                          if (isSelected) {
                                            selectedUsers.remove(user['id']);
                                          } else {
                                            selectedUsers.add(user['id']);
                                          }
                                        });
                                      },
                                  // Color gris claro de fondo para los que ya son miembros
                                  tileColor: isMember ? Colors.grey[100] : null,
                                ),
                              );
                            },
                          ),
                      ),
                      
                      // Botón de acción
                      Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                        child: ElevatedButton(
                          onPressed: selectedUsers.isEmpty
                            ? null
                            : () async {
                                // Cerrar el modal
                                Navigator.pop(context);
                                
                                // Verificar si el widget sigue montado
                                if (!mounted) return;
                                
                                // Mostrar indicador de carga
                                setState(() {
                                  _isLoading = true;
                                });
                                
                                try {
                                  // Añadir usuarios seleccionados al ministerio
                                  for (var userId in selectedUsers) {
                                    if (mounted) { // Verificar antes de cada operación
                                      await _addUserToMinistry(userId);
                                    }
                                  }
                                  
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${selectedUsers.length} usuários adicionados ao ministério'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    
                                    // Recargar datos
                                    _loadPendingRequests();
                                    _loadStats();
                                  }
                                } catch (e) {
                                  print('Error al procesar la adición de usuarios: $e');
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text('Adicionar usuários selecionados'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }
    }).catchError((e) {
      // Verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ao carregar usuários: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Miembros'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.visibility_off : Icons.bar_chart),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
            tooltip: _showStats ? 'Ocultar estadísticas' : 'Ver estadísticas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPendingRequests();
              _loadStats();
            },
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Aceitadas'),
            Tab(text: 'Rejeitadas'),
            Tab(text: 'Saídas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Panel de estadísticas (visible/oculto)
                if (_showStats)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      children: [
                        const Text(
                          'Estadísticas de solicitudes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              'Total',
                              _totalRequests,
                              AppColors.primary,
                              Icons.people_outline,
                            ),
                            _buildStatCard(
                              'Aceitas',
                              _acceptedRequests,
                              Colors.green,
                              Icons.check_circle_outline,
                            ),
                            _buildStatCard(
                              'Rejeitadas',
                              _rejectedRequests,
                              Colors.orange,
                              Icons.cancel_outlined,
                            ),
                            _buildStatCard(
                              'Saídas',
                              _exitedMembers,
                              Colors.red,
                              Icons.exit_to_app,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                // Contenido de las pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña "Pendientes"
                      _buildPendingRequestsTab(),
                      
                      // Pestaña "Aceptadas"
                      _buildRequestsHistoryTab('accepted'),
                      
                      // Pestaña "Rechazadas"
                      _buildRequestsHistoryTab('rejected'),
                      
                      // Pestaña "Saídas"
                      _buildExitedMembersTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUsersModal,
        tooltip: 'Añadir usuarios',
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Não há solicitações pendentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Todo al día!',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppColors.primary,
      child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Mostrar más detalles si es necesario
              },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                          children: [
                            // Foto de perfil
                            CircleAvatar(
                              radius: 24,
                          backgroundColor: Colors.grey[200],
                              backgroundImage: request['photoUrl'] != null
                                  ? NetworkImage(request['photoUrl'])
                                  : null,
                              child: request['photoUrl'] == null
                              ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            
                            // Información del usuario
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request['email'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(request['requestDate']),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Mensaje si existe
                    if (request['message'] != null && request['message'].toString().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mensaje:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Botones de acción
                            Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                        TextButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Rechazar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _rejectRequest(request['userId'], request['id']),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                          label: const Text('Aceptar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _acceptRequest(request['userId'], request['id']),
                                ),
                              ],
                            ),
                          ],
                ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  Widget _buildRequestsHistoryTab(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('membership_requests')
          .where('entityId', isEqualTo: widget.ministry.id)
          .where('entityType', isEqualTo: 'ministry')
          .where('status', isEqualTo: status)
          .orderBy('requestTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'accepted' ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Não há solicitações ${status == 'accepted' ? 'aceitas' : 'rejeitadas'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
      ),
    );
  }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final DateTime requestDate = (data['requestTimestamp'] as Timestamp).toDate();
            final DateTime? responseDate = data['responseTimestamp'] != null 
                ? (data['responseTimestamp'] as Timestamp).toDate() 
                : null;
                
            final Duration? responseTime = responseDate != null 
                ? responseDate.difference(requestDate) 
                : null;

            // Verificar si fue añadido directamente
            final bool isDirectAdd = data['directAdd'] == true;
            final String addedByName = data['addedByName'] as String? ?? 'Administrador';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Foto de perfil
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: data['userPhotoUrl'] != null && data['userPhotoUrl'].toString().isNotEmpty
                              ? NetworkImage(data['userPhotoUrl'])
                              : null,
                          child: data['userPhotoUrl'] == null || data['userPhotoUrl'].toString().isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        
                        // Información del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Usuario',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                data['userEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Indicador de estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'accepted' ? Colors.green[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: status == 'accepted' ? Colors.green : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status == 'accepted' ? 'Aceptada' : 'Rechazada',
                            style: TextStyle(
                              color: status == 'accepted' ? Colors.green[800] : Colors.orange[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Información de fechas
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (isDirectAdd) 
                            Row(
                              children: [
                                const Icon(Icons.person_add, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Adicionado por: $addedByName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Solicitado: ${DateFormat('dd/MM/yyyy HH:mm').format(requestDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          if (responseDate != null)
                            Row(
                              children: [
                                Icon(
                                  status == 'accepted' ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: status == 'accepted' ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    isDirectAdd 
                                      ? 'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(responseDate)}'
                                      : '${status == 'accepted' ? 'Aceptado' : 'Rechazado'}: ${DateFormat('dd/MM/yyyy HH:mm').format(responseDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: status == 'accepted' ? Colors.green[700] : Colors.orange[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                          if (responseTime != null && !isDirectAdd)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Tiempo de respuesta: ${_formatDuration(responseTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Mensaje de solicitud si existe y no fue añadido directamente
                    if (!isDirectAdd && data['message'] != null && data['message'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mensaje:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                data['message'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Razón de aceptación/rechazo si existe
                    if (data['responseReason'] != null && data['responseReason'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Razón:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: status == 'accepted' ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: status == 'accepted' ? Colors.green[200]! : Colors.orange[200]!,
                                ),
                              ),
                              child: Text(
                                data['responseReason'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: status == 'accepted' ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
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
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'día' : 'días'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hora' : 'horas'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'segundo' : 'segundos'}';
    }
  }

  Widget _buildExitedMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('member_exits')
          .where('entityId', isEqualTo: widget.ministry.id)
          .where('entityType', isEqualTo: 'ministry')
          .orderBy('exitTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.exit_to_app,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum membro saiu do ministério',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final DateTime exitDate = (data['exitTimestamp'] as Timestamp).toDate();
            final DateTime? joinDate = data['joinTimestamp'] != null 
                ? (data['joinTimestamp'] as Timestamp).toDate() 
                : null;
            
            // Calcular el tiempo que el usuario estuvo en el ministerio
            final Duration? membershipDuration = joinDate != null
                ? exitDate.difference(joinDate)
                : null;
            
            // Determinar si el usuario salió voluntariamente o fue eliminado
            final bool isVoluntaryExit = data['exitType'] == 'voluntary';
            final String removedById = data['removedById'] ?? '';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Foto de perfil
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: data['userPhotoUrl'] != null
                              ? NetworkImage(data['userPhotoUrl'])
                              : null,
                          child: data['userPhotoUrl'] == null
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        
                        // Información del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Usuário',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                data['userEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Saiu em: ${DateFormat('dd/MM/yyyy HH:mm').format(exitDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Indicador del tipo de salida
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVoluntaryExit ? Colors.orange[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isVoluntaryExit ? Colors.orange : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isVoluntaryExit ? 'Saída voluntária' : 'Removido',
                            style: TextStyle(
                              color: isVoluntaryExit ? Colors.orange[800] : Colors.red[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Información detallada
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (joinDate != null)
                            Row(
                              children: [
                                const Icon(Icons.login, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Entrou em: ${DateFormat('dd/MM/yyyy').format(joinDate)}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          
                          if (membershipDuration != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tempo no ministério: ${_formatDuration(membershipDuration)}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          if (!isVoluntaryExit && removedById.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(removedById)
                                  .get(),
                              builder: (context, snapshot) {
                                String adminName = 'Administrador';
                                
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final adminData = snapshot.data!.data() as Map<String, dynamic>;
                                  adminName = adminData['name'] ?? 'Administrador';
                                }
                                
                                return Row(
                                  children: [
                                    const Icon(Icons.person_remove, size: 16, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Removido por: $adminName',
                                        style: const TextStyle(fontSize: 14, color: Colors.red),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Razón de salida si existe
                    if (data['exitReason'] != null && data['exitReason'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motivo:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              width: double.infinity,
                              child: Text(
                                data['exitReason'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
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
  }
}

// Necesario para la pestaña de historial
final FirebaseFirestore _firestore = FirebaseFirestore.instance; 