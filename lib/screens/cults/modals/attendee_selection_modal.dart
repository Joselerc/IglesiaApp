import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/cult.dart';
import '../../../models/time_slot.dart';
import '../../../theme/app_colors.dart';

class AttendeeSelectionModal extends StatefulWidget {
  final String ministryId;
  final String ministryName;
  final String roleId;
  final String roleName;
  final TimeSlot timeSlot;
  final Cult cult;
  final String? assignmentId;
  final String? originalUserId;
  final String? originalUserName;
  final bool isChangingAttendee;
  final bool multiSelect;
  final Function(List<Map<String, String>> selectedUsers) onConfirmAttendees;

  const AttendeeSelectionModal({
    Key? key,
    required this.ministryId,
    required this.ministryName,
    required this.roleId,
    required this.roleName,
    required this.timeSlot,
    required this.cult,
    this.assignmentId,
    this.originalUserId,
    this.originalUserName,
    required this.isChangingAttendee,
    this.multiSelect = false,
    required this.onConfirmAttendees,
  }) : super(key: key);

  @override
  State<AttendeeSelectionModal> createState() => _AttendeeSelectionModalState();
}

class _AttendeeSelectionModalState extends State<AttendeeSelectionModal> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  TabController? _tabController;
  
  List<DocumentSnapshot> _ministryUsers = [];
  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _filteredMinistryUsers = [];
  List<DocumentSnapshot> _filteredAllUsers = [];
  
  // Para multiselección
  final Set<String> _selectedUserIds = {};
  final Map<String, String> _userNames = {};
  
  // Para usuario único
  DocumentSnapshot? _singleSelectedUser;
  
  // Usuarios ya asignados al rol (para filtrarlos)
  Set<String> _alreadyAssignedUserIds = {};
  
  bool _isLoadingMinistryUsers = true;
  bool _isLoadingAllUsers = true;
  bool _isLoadingAssignments = true;
  bool _showingResults = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExistingAssignments().then((_) {
      _loadMinistryUsers();
      _loadAllUsers();
    });
    
    _searchController.addListener(() {
      _filterUsers();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }
  
  // Cargar asignaciones existentes para evitar duplicados
  Future<void> _loadExistingAssignments() async {
    setState(() {
      _isLoadingAssignments = true;
    });
    
    try {
      debugPrint('Carregando atribuições para timeSlot: ${widget.timeSlot.id}, papel: ${widget.roleName}');
      
      // Consultar por el nombre del rol en lugar del roleId
      final snapshot = await FirebaseFirestore.instance
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('role', isEqualTo: widget.roleName) // Usamos el nombre del rol, no roleId
          .where('isActive', isEqualTo: true)
          .get();
      
      final assignedIds = <String>{};
      
      // Para debug
      debugPrint('Encontradas ${snapshot.docs.length} atribuições para este papel');
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          debugPrint('Processando atribuição: ${doc.id}');
          
          // Si estamos cambiando un asistente, no excluir al usuario original
          if (widget.isChangingAttendee && 
              widget.originalUserId != null && 
              _extractUserId(data['userId']) == widget.originalUserId) {
            debugPrint('Ignorando usuário original: ${widget.originalUserId}');
            continue;
          }
          
          // Obtener userId directamente del documento
          if (data['userId'] != null) {
            String userId = '';
            
            // Si es referencia, extraer ID
            if (data['userId'] is DocumentReference) {
              userId = (data['userId'] as DocumentReference).id;
              debugPrint('userId (DocumentReference): $userId');
            } 
            // Si es string (puede ser path completo o ID directo)
            else if (data['userId'] is String) {
              final String rawUserId = data['userId'] as String;
              userId = rawUserId.contains('/') ? rawUserId.split('/').last : rawUserId;
              debugPrint('userId (String): $userId');
            }
            // Otro caso (no debería ocurrir)
            else {
              userId = data['userId'].toString();
              debugPrint('userId (outro tipo): $userId');
            }
            
            if (userId.isNotEmpty) {
              assignedIds.add(userId);
              debugPrint('Adicionado ID de usuário atribuído: $userId');
            }
          }
          
          // También obtener el attendedBy si existe (para usuarios que fueron sustituidos)
          if (data['attendedBy'] != null) {
            String attendedById = '';
            
            // Si es referencia, extraer ID
            if (data['attendedBy'] is DocumentReference) {
              attendedById = (data['attendedBy'] as DocumentReference).id;
              debugPrint('attendedById (DocumentReference): $attendedById');
            } 
            // Si es string (puede ser path completo o ID directo)
            else if (data['attendedBy'] is String) {
              final String rawAttendedById = data['attendedBy'] as String;
              attendedById = rawAttendedById.contains('/') ? rawAttendedById.split('/').last : rawAttendedById;
              debugPrint('attendedById (String): $attendedById');
            }
            // Otro caso (no debería ocurrir)
            else {
              attendedById = data['attendedBy'].toString();
              debugPrint('attendedById (outro tipo): $attendedById');
            }
            
            if (attendedById.isNotEmpty) {
              assignedIds.add(attendedById);
              debugPrint('Adicionado ID de attendedBy: $attendedById');
            }
          }
        } catch (e) {
          debugPrint('Erro ao processar atribuição: $e');
        }
      }
      
      setState(() {
        _alreadyAssignedUserIds = assignedIds;
        _isLoadingAssignments = false;
      });
      
      debugPrint('Usuários já atribuídos ou confirmados ao papel (total): ${_alreadyAssignedUserIds.length}');
      if (_alreadyAssignedUserIds.isNotEmpty) {
        debugPrint('IDs de usuários filtrados: ${_alreadyAssignedUserIds.join(", ")}');
      }
    } catch (e) {
      debugPrint('Erro ao carregar atribuições: $e');
      setState(() {
        _isLoadingAssignments = false;
      });
    }
  }
  
  String _extractUserInfo(dynamic userValue) {
    if (userValue == null) return 'null';
    if (userValue is DocumentReference) return 'DocumentReference(${userValue.path})';
    return '${userValue.runtimeType}(${userValue.toString()})';
  }
  
  // Método auxiliar para extraer userId de diferentes tipos de datos
  String _extractUserId(dynamic userIdData) {
    if (userIdData == null) return '';
    
    if (userIdData is DocumentReference) {
      return userIdData.id;
    } else if (userIdData is String && userIdData.contains('/')) {
      return userIdData.split('/').last;
    } else {
      return userIdData.toString();
    }
  }
  
  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _showingResults = query.isNotEmpty;
      
      if (query.isEmpty) {
        _filteredMinistryUsers = _ministryUsers;
        _filteredAllUsers = _allUsers;
      } else {
        _filteredMinistryUsers = _ministryUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final displayName = (data['displayName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          
          return displayName.contains(query) || email.contains(query);
        }).toList();
        
        _filteredAllUsers = _allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final displayName = (data['displayName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          
          return displayName.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }
  
  // Método para depurar el tipo de un objeto
  String _getTypeInfo(dynamic obj) {
    if (obj == null) return 'null';
    if (obj is DocumentReference) return 'DocumentReference(${obj.path})';
    return '${obj.runtimeType}(${obj.toString()})';
  }

  // Método modificado de filtrado de usuarios para añadir más logs
  Future<void> _loadMinistryUsers() async {
    setState(() {
      _isLoadingMinistryUsers = true;
    });
    
    try {
      // Obtener todos los miembros del ministerio
      final ministryDoc = await FirebaseFirestore.instance
          .collection('ministries')
          .doc(widget.ministryId)
          .get();
      
      if (!ministryDoc.exists) {
        setState(() {
          _isLoadingMinistryUsers = false;
        });
        return;
      }
      
      final ministryData = ministryDoc.data()!;
      final List<dynamic> memberRefs = ministryData['members'] ?? [];
      
      // Si no hay miembros
      if (memberRefs.isEmpty) {
        setState(() {
          _isLoadingMinistryUsers = false;
        });
        return;
      }
      
      // Extraer IDs de miembros
      final List<String> memberIds = memberRefs
          .map((ref) {
            if (ref is DocumentReference) {
              return ref.id;
            } else if (ref is String && ref.contains('/')) {
              return ref.split('/').last;
            }
            return ref.toString();
          })
          .toList();
      
      debugPrint('Miembros del ministerio (total): ${memberIds.length}');
      
      // Cargar datos de usuarios
      final usersData = await Future.wait(
        memberIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get())
      );
      
      // Filtrar usuarios ya asignados
      final allUsers = usersData.where((doc) => doc.exists).toList();
      debugPrint('Usuarios del ministerio totales: ${allUsers.length}');
      
      final filteredUsers = allUsers.where((doc) {
        final isFiltered = !_alreadyAssignedUserIds.contains(doc.id);
        if (!isFiltered) {
          debugPrint('Usuario filtrado del ministerio: ${doc.id}');
        }
        return isFiltered;
      }).toList();
      
      debugPrint('Usuarios del ministerio después de filtrar: ${filteredUsers.length}');
      
      setState(() {
        _ministryUsers = filteredUsers;
        _filteredMinistryUsers = _ministryUsers;
        _isLoadingMinistryUsers = false;
      });
    } catch (e) {
      debugPrint('Error al cargar miembros del ministerio: $e');
      setState(() {
        _isLoadingMinistryUsers = false;
      });
    }
  }
  
  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoadingAllUsers = true;
    });
    
    try {
      // Cargar todos los usuarios (con límite)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(50) // Incrementamos el límite para tener más usuarios
          .get();
      
      debugPrint('Usuarios totales obtenidos: ${snapshot.docs.length}');
      
      // Filtrar usuarios ya asignados
      final filteredUsers = snapshot.docs.where((doc) {
        final isFiltered = !_alreadyAssignedUserIds.contains(doc.id);
        if (!isFiltered) {
          debugPrint('Usuario filtrado general: ${doc.id}');
        }
        return isFiltered;
      }).toList();
      
      debugPrint('Usuarios generales después de filtrar: ${filteredUsers.length}');
      
      setState(() {
        _allUsers = filteredUsers;
        _filteredAllUsers = _allUsers;
        _isLoadingAllUsers = false;
      });
    } catch (e) {
      debugPrint('Error al cargar todos los usuarios: $e');
      setState(() {
        _isLoadingAllUsers = false;
      });
    }
  }
  
  void _toggleUserSelection(DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    final String displayName = userData['displayName'] ?? 'Usuario';
    
    setState(() {
      if (widget.multiSelect) {
        // Modo multiselección
        if (_selectedUserIds.contains(user.id)) {
          _selectedUserIds.remove(user.id);
          _userNames.remove(user.id);
        } else {
          _selectedUserIds.add(user.id);
          _userNames[user.id] = displayName;
        }
      } else {
        // Modo selección única
        _singleSelectedUser = user;
      }
    });
  }
  
  List<Map<String, String>> _getSelectedUsers() {
    if (widget.multiSelect) {
      return _selectedUserIds.map((id) => {
        'id': id,
        'name': _userNames[id] ?? 'Usuario',
      }).toList();
    } else if (_singleSelectedUser != null) {
      final userData = _singleSelectedUser!.data() as Map<String, dynamic>;
      final String displayName = userData['displayName'] ?? 'Usuario';
      return [{
        'id': _singleSelectedUser!.id,
        'name': displayName,
      }];
    }
    return [];
  }
  
  @override
  Widget build(BuildContext context) {
    final bool hasSelections = widget.multiSelect 
        ? _selectedUserIds.isNotEmpty 
        : _singleSelectedUser != null;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado con título y botón de cierre
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.isChangingAttendee
                            ? 'Alterar participante para "${widget.roleName}"'
                            : 'Registrar participante para "${widget.roleName}"',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                if (widget.isChangingAttendee && widget.originalUserName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Usuário original: ${widget.originalUserName}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                // Si estamos en multiselección, mostrar contador de seleccionados
                if (widget.multiSelect && _selectedUserIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_selectedUserIds.length} usuários selecionados',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Campo de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar usuário...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _showingResults = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                
                // Pestañas: Ministerio / Todos
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Ministério ${widget.ministryName}'),
                    const Tab(text: 'Todos os usuários'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                ),
              ],
            ),
          ),
          
          // Mensaje de cargando asignaciones
          if (_isLoadingAssignments)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Carregando atribuições existentes...'),
                  ],
                ),
              ),
            ),
            
          // Contenido de las pestañas
          if (!_isLoadingAssignments)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña de usuarios del ministerio
                  _isLoadingMinistryUsers
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                      : _filteredMinistryUsers.isEmpty
                          ? const Center(
                              child: Text(
                                'Não foram encontrados usuários disponíveis neste ministério',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : _buildUsersList(_filteredMinistryUsers),
                  
                  // Pestaña de todos los usuarios
                  _isLoadingAllUsers
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                      : _filteredAllUsers.isEmpty
                          ? const Center(
                              child: Text(
                                'Não foram encontrados usuários disponíveis',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : _buildUsersList(_filteredAllUsers),
                ],
              ),
            ),
          
          // Botón de confirmación
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: !hasSelections
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onConfirmAttendees(_getSelectedUsers());
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.isChangingAttendee 
                    ? 'Alterar participante${widget.multiSelect ? "s" : ""}' 
                    : 'Confirmar participante${widget.multiSelect ? "s" : ""}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsersList(List<DocumentSnapshot> users) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final userData = user.data() as Map<String, dynamic>;
        final String displayName = userData['displayName'] ?? 'Usuario';
        final String email = userData['email'] ?? '';
        final String photoUrl = userData['photoUrl'] ?? '';
        
        final bool isSelected = widget.multiSelect
            ? _selectedUserIds.contains(user.id)
            : _singleSelectedUser?.id == user.id;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          elevation: isSelected ? 2 : 1,
          child: InkWell(
            onTap: () => _toggleUserSelection(user),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl) as ImageProvider
                        : const AssetImage('assets/images/user_placeholder.png') as ImageProvider,
                    child: photoUrl.isEmpty
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.multiSelect)
                    Checkbox(
                      value: _selectedUserIds.contains(user.id),
                      onChanged: (_) => _toggleUserSelection(user),
                      activeColor: Theme.of(context).primaryColor,
                    )
                  else if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 