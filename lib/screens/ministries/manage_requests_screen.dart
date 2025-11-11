import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ministry.dart';
import '../../services/ministry_service.dart';
import '../../services/membership_request_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

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
      debugPrint('Erro carregando estatísticas: $e');
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
      debugPrint('Erro carregando solicitações pendentes: $e');
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
            content: Text('Solicitação aceita corretamente'),
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
            content: Text('Erro: ${e.toString()}'),
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
          content: Text('Solicitação rejeitada'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
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
        throw Exception('Não há usuário autenticado');
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
        throw Exception('Usuário não encontrado');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? userData['displayName'] ?? 'Usuário';
      final userEmail = userData['email'] ?? '';
      final userPhotoUrl = userData['photoUrl'] ?? '';
      
      print('Adicionando usuário: $userId - $userName - $userEmail');
      
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
      print('Erro ao adicionar usuário: $e');
      throw Exception('Erro ao adicionar usuário: $e');
    }
  }

  void _showAddUsersModal() {
    if (!mounted) return;
    
    final selectedUsers = <String>{};
    List<Map<String, dynamic>> allUsers = [];
    List<Map<String, dynamic>> filteredUsers = [];
    
    // Obtener los IDs de miembros actuales para excluirlos
    final memberIds = widget.ministry.memberIds;
    
    print('Ministerio membros atuais: ${memberIds.length}');
    print('IDs de membros do ministério: $memberIds');
    
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
        
        // Obtener datos del documento de forma segura
        final userData = doc.data() as Map<String, dynamic>?;
        if (userData == null) continue;
        
        final userName = userData['name'] ?? userData['displayName'] ?? 'Usuário sem nome';
        
        if (isMember) {
          print('Usuário ministério ${doc.id} ($userName) é membro');
        }
        
        // Añadir todos los usuarios, pero marcar los que ya son miembros
        allUsers.add({
          'id': doc.id,
          'name': userName,
          'email': userData['email'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'isMember': isMember,
        });
      }
      
      // Inicializar la lista filtrada con TODOS los usuarios al principio
      filteredUsers = List<Map<String, dynamic>>.from(allUsers);
      
      print('Total de usuários: ${allUsers.length}');
      print('Usuários filtrados (não membros): ${filteredUsers.length}');
      
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
            // Variables para búsqueda y filtrado fuera del StatefulBuilder
            String searchQuery = '';
            bool showOnlyNonMembers = false; // Cambiar a false por defecto
            
            // Inicializar la lista filtrada con TODOS los usuarios al principio
            filteredUsers = List<Map<String, dynamic>>.from(allUsers);
            
            return StatefulBuilder(
              builder: (context, setModalState) {
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
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
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
                        onChanged: filterUsers,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Opciones de filtro
                      Row(
                        children: [
                          Checkbox(
                            value: showOnlyNonMembers,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setModalState(() {
                                showOnlyNonMembers = value ?? false;
                                filterUsers(searchQuery);
                              });
                            },
                          ),
                          const Text('Mostrar só usuários que não são membros'),
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
                        padding: const EdgeInsets.only(top: 16),
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
                                  print('Erro ao processar a adição de usuários: $e');
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erro: $e'),
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
          content: Text('Erro ao carregar usuários: $e'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.memberManagement),
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
            tooltip: _showStats ? AppLocalizations.of(context)!.hideStatistics : AppLocalizations.of(context)!.viewStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPendingRequests();
              _loadStats();
            },
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.pending),
            Tab(text: AppLocalizations.of(context)!.approved),
            Tab(text: AppLocalizations.of(context)!.rejected),
            Tab(text: AppLocalizations.of(context)!.exits),
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
                        Text(
                          AppLocalizations.of(context)!.requestStatistics,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              AppLocalizations.of(context)!.total,
                              _totalRequests,
                              AppColors.primary,
                              Icons.people_outline,
                            ),
                            _buildStatCard(
                              AppLocalizations.of(context)!.approved,
                              _acceptedRequests,
                              Colors.green,
                              Icons.check_circle_outline,
                            ),
                            _buildStatCard(
                              AppLocalizations.of(context)!.rejected,
                              _rejectedRequests,
                              Colors.orange,
                              Icons.cancel_outlined,
                            ),
                            _buildStatCard(
                              AppLocalizations.of(context)!.exits,
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
        tooltip: 'Adicionar usuários',
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
                      Text(
                        AppLocalizations.of(context)!.noPendingRequests,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.allUpToDate,
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
                              '${AppLocalizations.of(context)!.message}:',
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
                          label: Text(AppLocalizations.of(context)!.reject),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _rejectRequest(request['userId'], request['id']),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                          label: Text(AppLocalizations.of(context)!.accept),
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
                  status == 'accepted' 
                    ? AppLocalizations.of(context)!.noApprovedRequests 
                    : AppLocalizations.of(context)!.noRejectedRequests,
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
                            status == 'accepted' 
                              ? AppLocalizations.of(context)!.accepted 
                              : AppLocalizations.of(context)!.rejected,
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
                                    '${AppLocalizations.of(context)!.addedBy}: $addedByName',
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
                                    '${AppLocalizations.of(context)!.requested}: ${DateFormat('dd/MM/yyyy HH:mm').format(requestDate)}',
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
                                      ? '${AppLocalizations.of(context)!.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(responseDate)}'
                                      : '${status == 'accepted' ? AppLocalizations.of(context)!.accepted : AppLocalizations.of(context)!.rejected}: ${DateFormat('dd/MM/yyyy HH:mm').format(responseDate)}',
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
                                      '${AppLocalizations.of(context)!.responseTime}: ${_formatDuration(responseTime)}',
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
                              '${AppLocalizations.of(context)!.message}:',
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
                              '${AppLocalizations.of(context)!.reason}:',
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
      return '${duration.inDays} ${duration.inDays == 1 ? 'dia' : 'dias'}';
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
                Text(
                  AppLocalizations.of(context)!.noExitsRecorded,
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
                                      '${AppLocalizations.of(context)!.exitedOn}: ${DateFormat('dd/MM/yyyy HH:mm').format(exitDate)}',
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
                            isVoluntaryExit 
                              ? AppLocalizations.of(context)!.voluntaryExit 
                              : AppLocalizations.of(context)!.removed,
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
                                        '${AppLocalizations.of(context)!.removedBy}: $adminName',
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
                              '${AppLocalizations.of(context)!.reason}:',
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