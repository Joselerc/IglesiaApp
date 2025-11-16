import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/cult.dart';
import '../../../models/time_slot.dart';
import '../../../services/work_schedule_service.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class UserData {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  
  UserData({
    required this.id,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });
  
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      id: doc.id,
      displayName: data['displayName'] ?? 'Usuario',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }
}

class RejectedInviteInfo {
  final String userId;
  final String invitationId;
  
  RejectedInviteInfo({required this.userId, required this.invitationId});
}

class AssignPersonModal extends StatefulWidget {
  final TimeSlot timeSlot;
  final Cult cult;
  final dynamic ministryId;
  final String ministryName;
  final bool isTemporary;
  final String? predefinedRole;
  final String? roleId;
  
  const AssignPersonModal({
    Key? key,
    required this.timeSlot,
    required this.cult,
    required this.ministryId,
    required this.ministryName,
    required this.isTemporary,
    this.predefinedRole,
    this.roleId,
  }) : super(key: key);

  @override
  State<AssignPersonModal> createState() => _AssignPersonModalState();
}

class _AssignPersonModalState extends State<AssignPersonModal> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  bool _isLoadingUsers = true;
  bool _isAssigning = false;
  bool _isCreatingRoleOnly = false;
  bool _showAllUsers = false;
  
  List<UserData> _users = [];
  List<UserData> _filteredUsers = [];
  List<String> _selectedUserIds = [];
  List<String> _alreadyInvitedUserIds = [];
  List<String> _savedRoles = [];
  Map<String, Map<String, dynamic>> _roleDetails = {};
  
  int _selectedCapacity = 1;
  
  Map<String, RejectedInviteInfo> _rejectedUserIds = {};
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadSavedRoles();
    
    if (widget.predefinedRole != null) {
      _roleController.text = widget.predefinedRole!;
      _isCreatingRoleOnly = false;
      _loadExistingInvitations();
      _loadRejectedInvitations();
    }
    
    _searchController.addListener(_filterUsers);
    
    // Inicializar capacidad por defecto
    _selectedCapacity = 1;
    _capacityController.text = "1";
  }
  
  @override
  void dispose() {
    _roleController.dispose();
    _searchController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
  
  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.displayName.toLowerCase().contains(query) || 
                 user.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }
  
  bool _isUserAlreadyInvited(String userId) {
    return _alreadyInvitedUserIds.contains(userId);
  }
  
  void _filterAlreadyInvitedUsers() {
    setState(() {
      _selectedUserIds.removeWhere((userId) => 
        _isUserAlreadyInvited(userId) && !_hasUserRejectedInvitation(userId)
      );
    });
  }
  
  Future<void> _loadSavedRoles() async {
    setState(() {
      _isLoadingUsers = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('available_roles')
          .where('ministryId', isEqualTo: widget.ministryId)
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('isActive', isEqualTo: true)
          .get();
      
      final roles = <String>[];
      final Map<String, Map<String, dynamic>> roleDetails = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] as String;
        roles.add(role);
        
        roleDetails[role] = {
          'capacity': data['capacity'] ?? 1,
          'current': data['current'] ?? 0,
          'id': doc.id
        };
      }
      
      if (mounted) {
        setState(() {
          _savedRoles = roles;
          _roleDetails = roleDetails;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
        debugPrint('Erro ao carregar papéis salvos: $e');
      }
    }
  }
  
  Future<void> _saveRole(String role, int capacity) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      if (_savedRoles.contains(role)) return;
      
      await FirebaseFirestore.instance.collection('available_roles').add({
        'timeSlotId': widget.timeSlot.id,
        'ministryId': widget.ministryId,
        'ministryName': widget.ministryName,
        'role': role,
        'capacity': capacity,
        'current': 0,
        'isTemporary': widget.isTemporary,
        'createdAt': Timestamp.now(),
        'isActive': true
      });
      
      setState(() {
        _savedRoles.add(role);
      });
    } catch (e) {
      debugPrint('Erro ao salvar papel: $e');
    }
  }
  
  Future<void> _updateRoleCapacity(String roleId, int newCapacity) async {
    try {
      await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .update({
            'capacity': newCapacity
          });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.capacityUpdatedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar capacidade: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _showCapacityDialog(String role) {
    final details = _roleDetails[role];
    if (details == null) return;
    
    _capacityController.text = details['capacity'].toString();
    _selectedCapacity = details['capacity'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editCapacityFor(role)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.capacity,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.currentlyAssigned(details['current'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final newCapacity = int.tryParse(_capacityController.text.trim());
              if (newCapacity == null || newCapacity < details['current']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.invalidCapacityOrLessThanAssigned),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              _updateRoleCapacity(details['id'], newCapacity);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    
    try {
      // Caso especial para ministerio temporal o sin ID
      bool isEmptyOrTemporary = widget.isTemporary;
      if (widget.ministryId is String) {
        isEmptyOrTemporary = isEmptyOrTemporary || (widget.ministryId as String).isEmpty;
      } else if (widget.ministryId == null) {
        isEmptyOrTemporary = true;
      }
      
      // Si es temporal o no tiene ID, cargar todos los usuarios
      if (isEmptyOrTemporary) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
            
        final allUsers = snapshot.docs
            .map((doc) => UserData.fromFirestore(doc))
            .toList();
        
        setState(() {
          _users = allUsers;
          _filteredUsers = allUsers;
          _isLoadingUsers = false;
        });
        return;
      }
      
      // Normalizar el ministryId a string, independientemente de su tipo actual
      String ministryIdStr = _normalizeId(widget.ministryId);
      debugPrint('🔍 Cargando ministerio con ID normalizado: $ministryIdStr');
      
      // Obtener el documento del ministerio
      final ministryDoc = await FirebaseFirestore.instance
          .collection('ministries')
          .doc(ministryIdStr)
          .get();
      
      if (!ministryDoc.exists) {
        debugPrint('❌ El ministerio no existe');
        setState(() {
          _isLoadingUsers = false;
        });
        return;
      }
      
      // Extraer miembros del ministerio
      final ministryData = ministryDoc.data();
      if (ministryData == null) {
        debugPrint('❌ Datos del ministerio nulos');
        setState(() {
          _isLoadingUsers = false;
        });
        return;
      }
      
      // Extraer miembros - pueden estar en 'members' como referencias o en 'memberIds' como strings
      List<String> memberIds = [];
      
      if (ministryData.containsKey('members') && ministryData['members'] != null) {
        // 'members' suele tener referencias de documentos
        final members = ministryData['members'] as List<dynamic>;
        for (var member in members) {
          String memberId = _normalizeId(member);
          if (memberId.isNotEmpty) {
            memberIds.add(memberId);
          }
        }
        debugPrint('✅ Extraídos ${memberIds.length} IDs de miembros del campo "members"');
      } 
      else if (ministryData.containsKey('memberIds') && ministryData['memberIds'] != null) {
        // 'memberIds' suele tener strings directamente
        memberIds = List<String>.from(ministryData['memberIds']);
        debugPrint('✅ Extraídos ${memberIds.length} IDs de miembros del campo "memberIds"');
      }
      
      if (memberIds.isEmpty) {
        debugPrint('❌ El ministerio no tiene miembros');
        setState(() {
          _users = [];
          _filteredUsers = [];
          _isLoadingUsers = false;
        });
        return;
      }
      
      // Cargar usuarios a partir de los IDs normalizados
      final List<UserData> ministryUsers = [];
      
      for (final userId in memberIds) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
              
          if (userDoc.exists) {
            ministryUsers.add(UserData.fromFirestore(userDoc));
            debugPrint('✅ Usuario añadido: ${userDoc.id}');
          }
        } catch (e) {
          debugPrint('❌ Error al cargar usuario: $e');
        }
      }
      
      debugPrint('✅ Total de usuarios cargados: ${ministryUsers.length}');
      
      setState(() {
        _users = ministryUsers;
        _filteredUsers = ministryUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint('❌ Error general: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }
  
  // Método auxiliar para normalizar IDs, independientemente del tipo
  String _normalizeId(dynamic id) {
    if (id == null) return '';
    
    if (id is DocumentReference) {
      return id.id;
    } else if (id is String) {
      // Si es una ruta completa como '/users/abc123', extraer solo el ID
      if (id.contains('/')) {
        return id.split('/').last;
      }
      return id;
    } else {
      // Último recurso: convertir a string y ver si tiene formato de ruta
      final str = id.toString();
      if (str.contains('/')) {
        return str.split('/').last;
      }
      return str;
    }
  }
  
  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _showAllUsers = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
          
      List<UserData> allUsers = [];
      for (var doc in snapshot.docs) {
        try {
          allUsers.add(UserData.fromFirestore(doc));
        } catch (e) {
          debugPrint('Error al convertir usuario: $e');
        }
      }
      
      setState(() {
        _users = allUsers;
        _filteredUsers = allUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint('Error al cargar todos los usuarios: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }
  
  Future<void> _loadExistingInvitations() async {
    try {
      debugPrint('Cargando invitaciones para timeSlot: ${widget.timeSlot.id}, rol: ${widget.predefinedRole}');
      
      final invitedIds = <String>[];
      String ministryIdStr = _normalizeId(widget.ministryId);
      
      // Cargar asignaciones activas
      final assignmentsSnapshot = await FirebaseFirestore.instance
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('role', isEqualTo: widget.predefinedRole)
          .where('isActive', isEqualTo: true)
          .get();
          
      debugPrint('Encontradas ${assignmentsSnapshot.docs.length} asignaciones activas');
      
      // Procesar asignaciones activas
      for (var doc in assignmentsSnapshot.docs) {
        try {
          final data = doc.data();
          
          // Extraer ministryId y userId como strings
          final String docMinistryId = _normalizeId(data['ministryId']);
          
          // Verificar que coincida el ministerio
          if (docMinistryId != ministryIdStr) {
            debugPrint('Ministerio no coincide: $docMinistryId ≠ $ministryIdStr');
            continue;
          }
          
          // Extraer userId
          final String userIdStr = _normalizeId(data['userId']);
          
          if (userIdStr.isNotEmpty) {
            debugPrint('Usuario ya invitado: $userIdStr');
            invitedIds.add(userIdStr);
          }
        } catch (e) {
          debugPrint('Error procesando documento: $e');
        }
      }
      
      // Cargar también las invitaciones pendientes activas (no aceptadas aún)
      final pendingInvitesSnapshot = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('role', isEqualTo: widget.predefinedRole)
          .where('status', isEqualTo: 'pending')
          .where('isActive', isEqualTo: true)
          .get();
          
      debugPrint('Encontradas ${pendingInvitesSnapshot.docs.length} invitaciones pendientes');
      
      // Procesar invitaciones pendientes
      for (var doc in pendingInvitesSnapshot.docs) {
        try {
          final data = doc.data();
          
          // Extraer ministryId y verificar coincidencia
          final String docMinistryId = _normalizeId(data['ministryId']);
          
          // Verificar que coincida el ministerio
          if (docMinistryId != ministryIdStr) {
            debugPrint('Ministerio no coincide en invitación: $docMinistryId ≠ $ministryIdStr');
            continue;
          }
          
          // Extraer userId
          final String userIdStr = _normalizeId(data['userId']);
          
          if (userIdStr.isNotEmpty) {
            debugPrint('Usuario con invitación pendiente: $userIdStr');
            invitedIds.add(userIdStr);
        }
      } catch (e) {
          debugPrint('Error procesando invitación: $e');
        }
      }
      
          setState(() {
        _alreadyInvitedUserIds = invitedIds;
        _filterAlreadyInvitedUsers();
        debugPrint('RESULTADO FINAL: ${_alreadyInvitedUserIds.length} invitaciones activas para este ministerio y rol');
      });
    } catch (e) {
      debugPrint('Error al cargar invitaciones existentes: $e');
    }
  }
  
  Future<void> _loadRejectedInvitations() async {
    try {
      debugPrint('Cargando invitaciones rechazadas para rol ${widget.predefinedRole}');
      
      // Normalizar ministryId una sola vez
      final String ministryIdStr = _normalizeId(widget.ministryId);
      
      debugPrint('Buscando invitaciones rechazadas para ministryId: $ministryIdStr, timeSlotId: ${widget.timeSlot.id}, role: ${widget.predefinedRole}');
      
      // Buscar todas las invitaciones para este timeSlot sin filtrar por isActive
      // para asegurar que encontramos todas las invitaciones rechazadas
      final allInvitationsQuery = await FirebaseFirestore.instance
          .collection('work_invites')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .get();
      
      debugPrint('Encontradas ${allInvitationsQuery.docs.length} invitaciones totales para este timeSlot');
      
      final rejectedUsers = <String, RejectedInviteInfo>{};
      
      // Procesar todas las invitaciones y filtrar las rechazadas
      for (var doc in allInvitationsQuery.docs) {
        try {
          final data = doc.data();
          
          // Verificar que la invitación no haya sido eliminada
          if (data.containsKey('deletedAt')) {
            debugPrint('Ignorando invitación eliminada: ${doc.id}');
            continue;
          }
          
          // Extraer role y verificar que sea el rol que nos interesa
          final String role = data['role'] as String? ?? '';
          if (widget.predefinedRole != null && role != widget.predefinedRole) {
            continue;
          }
          
          // Verificar si la invitación está rechazada (por cualquiera de los dos métodos)
          final bool isRejectedByFlag = data['isRejected'] == true;
          final bool isRejectedByStatus = data['status'] == 'rejected';
          
          if (!isRejectedByFlag && !isRejectedByStatus) {
            continue; // No está rechazada, ignorar
          }
          
          debugPrint('Invitación rechazada encontrada: ${doc.id} (isRejected=$isRejectedByFlag, status=${data['status']})');
          
          // Extraer ministryId y verificar coincidencia
          final String docMinistryId = _normalizeId(data['ministryId']);
          
          // Verificar que coincida el ministerio
          if (docMinistryId != ministryIdStr) {
            debugPrint('Ministerio no coincide: $docMinistryId vs $ministryIdStr');
            continue;
          }
          
          // Extraer userId normalizado
          final String userId = _normalizeId(data['userId']);
          
          if (userId.isEmpty) {
            debugPrint('userId vacío, ignorando invitación');
            continue;
          }
          
          // Determinar si esta invitación es más reciente que otra ya registrada
          bool shouldAdd = true;
          if (rejectedUsers.containsKey(userId)) {
            // Si ya existe, verificar si la actual es más reciente
            if (data.containsKey('updatedAt')) {
              final Timestamp? currentTimestamp = data['updatedAt'] as Timestamp?;
              
              // Obtener la invitación existente para comparar
              final existingInviteId = rejectedUsers[userId]!.invitationId;
              final existingInviteDoc = await FirebaseFirestore.instance
                  .collection('work_invites')
                  .doc(existingInviteId)
                  .get();
                  
              if (existingInviteDoc.exists) {
                final existingData = existingInviteDoc.data() as Map<String, dynamic>;
                final Timestamp? existingTimestamp = existingData['updatedAt'] as Timestamp?;
                
                if (currentTimestamp != null && existingTimestamp != null) {
                  // Solo reemplazar si la actual es más reciente
                  shouldAdd = currentTimestamp.compareTo(existingTimestamp) > 0;
                }
              }
            }
          }
          
          if (shouldAdd) {
            // Registrar el usuario como rechazado
            rejectedUsers[userId] = RejectedInviteInfo(
              userId: userId,
              invitationId: doc.id
            );
            
            debugPrint('✅ Usuario rechazado registrado: $userId (invitación: ${doc.id})');
          }
        } catch (e) {
          debugPrint('Error procesando invitación: $e');
        }
      }
      
      setState(() {
        _rejectedUserIds = rejectedUsers;
        debugPrint('Total de usuarios con rechazos: ${_rejectedUserIds.length}');
      });
    } catch (e) {
      debugPrint('Error cargando invitaciones rechazadas: $e');
    }
  }
  
  bool _hasUserRejectedInvitation(String userId) {
    return _rejectedUserIds.containsKey(userId);
  }
  
  Future<void> _assignPerson() async {
    _filterAlreadyInvitedUsers();
    
    final String role = _roleController.text.trim();
    
    // Validación del rol cuando no hay uno predefinido
    if (widget.predefinedRole == null && role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.roleNameRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Caso especial: solo crear rol sin asignar personas
    if (_isCreatingRoleOnly) {
      if (widget.predefinedRole != null) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.roleAlreadyExists),
          backgroundColor: Colors.orange,
        ),
        );
        return;
      }
      
      setState(() {
        _isAssigning = true;
      });
      
      try {
        // Usar el método _saveRole para crear solo el rol
        await _saveRole(role, _selectedCapacity);
        
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.roleCreatedSuccessfully(role)),
          backgroundColor: Colors.green,
        ),
        );
        
        debugPrint('Rol creado sin asignar personas. Cerrando modal...');
        Navigator.of(context).pop(true);
      } catch (e) {
        debugPrint('Error al crear rol: $e');
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorCreatingRole(e.toString())),
          backgroundColor: Colors.red,
        ),
        );
      } finally {
        setState(() {
          _isAssigning = false;
        });
      }
      return;
    }
    
    // Validación de usuarios seleccionados cuando se quiere asignar personas
    debugPrint('Asignando ${_selectedUserIds.length} personas al rol ${widget.predefinedRole ?? role}');
    
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noPersonSelected),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isAssigning = true;
    });
    
    try {
      // Para rol predefinido, crear asignaciones con ese rol
      if (widget.predefinedRole != null && widget.predefinedRole!.isNotEmpty) {
        for (String userId in _selectedUserIds) {
          if (_isUserAlreadyInvited(userId) && !_hasUserRejectedInvitation(userId)) {
            debugPrint('Saltando usuario ya invitado: $userId');
            continue;
          }
          
          // Si ha rechazado la invitación, primero eliminar la invitación rechazada
          if (_hasUserRejectedInvitation(userId)) {
            final rejectedInfo = _rejectedUserIds[userId];
            if (rejectedInfo != null) {
              debugPrint('Procesando invitación rechazada: ${rejectedInfo.invitationId} para usuario $userId');
              try {
                // En lugar de eliminar la invitación, la marcamos como inactiva y no visible
                // para mantener el historial pero permitir nuevas invitaciones
                await FirebaseFirestore.instance
                    .collection('work_invites')
                    .doc(rejectedInfo.invitationId)
                    .update({
                      'isActive': false,
                      'isVisible': false,
                      'updatedAt': Timestamp.now(),
                      'notes': 'Invitación rechazada reemplazada por una nueva invitación',
                    });
                
                debugPrint('✅ Invitación rechazada marcada como inactiva: ${rejectedInfo.invitationId}');
              } catch (e) {
                debugPrint('Error al procesar invitación rechazada: $e');
                // Continuar con la creación de la nueva invitación incluso si hay error
              }
            }
          }
          
          // Crear nueva invitación
          // Usar claves fijas que se traducirán al mostrar la notificación
          await WorkScheduleService().createWorkAssignment(
            timeSlotId: widget.timeSlot.id,
            userId: userId,
            ministryId: widget.ministryId,
            role: widget.predefinedRole!,
            notificationTitle: 'NEW_SERVICE_INVITATION',
            notificationMessage: 'INVITED_TO_SERVE_AS:${widget.predefinedRole!}',
          );
        }
      } 
      // Para rol nuevo, primero guardar el rol y luego asignar personas
      else {
        // Guardar el rol nuevo en available_roles si no existe
        if (!_savedRoles.contains(role)) {
          await _saveRole(role, _selectedCapacity);
          debugPrint('✅ Rol nuevo guardado: $role con capacidad: $_selectedCapacity');
        }
        
        for (String userId in _selectedUserIds) {
          if (_isUserAlreadyInvited(userId) && !_hasUserRejectedInvitation(userId)) {
            debugPrint('Saltando usuario ya invitado: $userId');
            continue;
          }
          
          // Si ha rechazado la invitación, primero eliminar la invitación rechazada
          if (_hasUserRejectedInvitation(userId)) {
            final rejectedInfo = _rejectedUserIds[userId];
            if (rejectedInfo != null) {
              debugPrint('Procesando invitación rechazada: ${rejectedInfo.invitationId} para usuario $userId');
              try {
                // En lugar de eliminar la invitación, la marcamos como inactiva y no visible
                // para mantener el historial pero permitir nuevas invitaciones
                await FirebaseFirestore.instance
                    .collection('work_invites')
                    .doc(rejectedInfo.invitationId)
                    .update({
                      'isActive': false,
                      'isVisible': false,
                      'updatedAt': Timestamp.now(),
                      'notes': 'Invitación rechazada reemplazada por una nueva invitación',
                    });
                
                debugPrint('✅ Invitación rechazada marcada como inactiva: ${rejectedInfo.invitationId}');
              } catch (e) {
                debugPrint('Error al procesar invitación rechazada: $e');
                // Continuar con la creación de la nueva invitación incluso si hay error
              }
            }
          }
      
          // Crear invitación con el nuevo rol
          // Usar claves fijas que se traducirán al mostrar la notificación
          await WorkScheduleService().createWorkAssignment(
            timeSlotId: widget.timeSlot.id,
            userId: userId,
            ministryId: widget.ministryId,
            role: role,
            notificationTitle: 'NEW_SERVICE_INVITATION',
            notificationMessage: 'INVITED_TO_SERVE_AS:$role',
          );
        }
      }
        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.peopleAssignedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      
      debugPrint('Asignación completada. Cerrando modal...');
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error al asignar personas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorAssigningPeople(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAssigning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.assignRoleIn(widget.ministryName),
                      style: const TextStyle(
                        fontSize: 20,
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
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.predefinedRole == null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.roleToPerform,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _roleController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.enterRoleExample,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: const Icon(Icons.work),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.roleCapacity,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _capacityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.numberOfPeople,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: const Icon(Icons.people),
                                    ),
                                    onChanged: (value) {
                                      final capacity = int.tryParse(value);
                                      if (capacity != null && capacity > 0) {
                                        setState(() {
                                          _selectedCapacity = capacity;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: _selectedCapacity > 1 ? () {
                                          setState(() {
                                            _selectedCapacity--;
                                            _capacityController.text = _selectedCapacity.toString();
                                          });
                                        } : null,
                                      ),
                                      Text(
                                        _selectedCapacity.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          setState(() {
                                            _selectedCapacity++;
                                            _capacityController.text = _selectedCapacity.toString();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      if (_savedRoles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.savedRoles,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _savedRoles.map((role) {
                                  final roleDetails = _roleDetails[role];
                                  final bool isUsed = roleDetails != null && roleDetails['current'] > 0;
                                  
                                  return GestureDetector(
                                    onTap: () => _showCapacityDialog(role),
                                    child: Tooltip(
                                      message: AppLocalizations.of(context)!.tapToEditCapacity,
                                      child: Chip(
                                        label: Text('$role ${roleDetails != null ? "(${roleDetails['current']}/${roleDetails['capacity']})" : ""}'),
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    deleteIcon: isUsed ? null : const Icon(Icons.close, size: 18),
                                    onDeleted: isUsed ? null : () => _confirmDeleteRole(role),
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    deleteButtonTooltipMessage: AppLocalizations.of(context)!.deleteRole,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isCreatingRoleOnly,
                              onChanged: (value) {
                                setState(() {
                                  _isCreatingRoleOnly = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.createRoleWithoutAssigningPerson,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.roleToAssign,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.work, color: Colors.indigo),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.predefinedRole!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (!_isCreatingRoleOnly) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.selectPerson,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.searchPerson,
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      _buildUserList(),
                    ],
                    
                    if (!_isCreatingRoleOnly && _selectedUserIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          AppLocalizations.of(context)!.selectedPeople(_selectedUserIds.length),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isAssigning ? null : _assignPerson,
                icon: Icon(
                  _isCreatingRoleOnly ? Icons.add_task : Icons.person_add,
                  color: Colors.white,
                ),
                label: Text(
                  _isCreatingRoleOnly 
                    ? AppLocalizations.of(context)!.createRoleOnly 
                    : widget.predefinedRole != null 
                      ? AppLocalizations.of(context)!.assignPerson 
                      : AppLocalizations.of(context)!.assignRoleAndPerson,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoadingUsers) {
      return const Center(
        heightFactor: 3,
        child: CircularProgressIndicator(),
      );
    }
    
    if (_users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noUsersInMinistry,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _loadAllUsers();
              },
              icon: const Icon(Icons.people),
              label: Text(AppLocalizations.of(context)!.viewAllUsers),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 400,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showAllUsers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                  child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.showingAllUsers,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                final bool isAlreadyInvited = _isUserAlreadyInvited(user.id);
                final bool isSelected = _selectedUserIds.contains(user.id);
                final bool isRejected = _hasUserRejectedInvitation(user.id);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? NetworkImage(user.photoUrl) as ImageProvider
                        : const AssetImage('assets/images/profile/default_profile.png'),
                    child: user.photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRejected)
                        Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Tooltip(
                            message: AppLocalizations.of(context)!.userRejectedInvitation,
                            child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          ),
                        ),
                      if (isAlreadyInvited && !isRejected) 
                        Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Tooltip(
                            message: AppLocalizations.of(context)!.userHasActiveInvitation,
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                        ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (isAlreadyInvited && !isRejected)
                            ? null  // Deshabilitar si ya tiene invitación activa
                            : (value) {
                                if (value == true) {
                                  setState(() {
                                    _selectedUserIds.add(user.id);
                                  });
                                } else {
                                  setState(() {
                                    _selectedUserIds.remove(user.id);
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                  enabled: !(isAlreadyInvited && !isRejected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRole(String roleName) {
    final roleDetails = _roleDetails[roleName];
    if (roleDetails == null) return;
    
    final roleId = roleDetails['id'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteRole),
        content: Text(AppLocalizations.of(context)!.sureDeleteRole(roleName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRole(roleId, roleName);
            },
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteRole(String roleId, String roleName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.deletingRole),
            ],
          ),
        ),
      );
      
      await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .update({
            'isActive': false,
            'deletedAt': Timestamp.now(),
          });
      
      Navigator.pop(context);
      
      setState(() {
        _savedRoles.remove(roleName);
        _roleDetails.remove(roleName);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.roleDeletedSuccessfully(roleName)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorDeletingRole(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 