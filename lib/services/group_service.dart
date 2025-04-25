import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import './membership_log_service.dart';
import './membership_request_service.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MembershipLogService _logService = MembershipLogService();
  final MembershipRequestService _requestService = MembershipRequestService();

  /// Obtiene todos los grupos
  Stream<List<Group>> getGroups() {
    return _firestore
        .collection('groups')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList());
  }
  
  /// Obtiene un grupo por su ID
  Future<Group?> getGroupById(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return Group.fromFirestore(doc);
  }
  
  /// Obtiene los grupos a los que pertenece un usuario
  Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: _firestore.doc('users/$userId'))
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList());
  }
  
  /// Añade un usuario a un grupo
  Future<void> addUserToGroup(String userId, String groupId, {bool isAdmin = false, String? reason}) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    // Evitar duplicados
    if (group.memberIds.contains(userId)) {
      return; // El usuario ya es miembro
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    final bool isSelfJoin = actorId == userId;
    
    final initiatedBy = isSelfJoin ? 'user' : 'admin';
    
    // Añadir a la colección adecuada según el rol
    if (isAdmin) {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
        'groupAdmin': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
      });
    } else {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
      });
    }
    
    // Si hay solicitudes pendientes, eliminarlas
    if (group.pendingRequests.containsKey(userId)) {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequests.$userId': FieldValue.delete(),
      });
    }
    
    // Registrar la entrada
    await _logService.logGroupJoin(
      userId: userId,
      group: group,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      role: isAdmin ? 'admin' : 'member',
    );
  }
  
  /// Elimina un usuario de un grupo
  Future<void> removeUserFromGroup(String userId, String groupId, {String? reason}) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    final bool isSelfRemoval = actorId == userId;
    
    final initiatedBy = isSelfRemoval ? 'user' : 'admin';
    
    // Registrar la salida antes de eliminar (para capturar el rol actual)
    await _logService.logGroupLeave(
      userId: userId,
      group: group,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
    );
    
    // Eliminar de la colección de miembros
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([_firestore.doc('users/$userId')]),
    });
    
    // Si es admin, también eliminar de la colección de admins
    if (group.adminIds.contains(userId)) {
      await _firestore.collection('groups').doc(groupId).update({
        'groupAdmin': FieldValue.arrayRemove([_firestore.doc('users/$userId')]),
      });
    }
  }
  
  /// Promueve a un usuario a administrador del grupo
  Future<void> promoteToAdmin(String userId, String groupId, {String? reason}) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    // Verificar que el usuario es miembro
    if (!group.memberIds.contains(userId)) {
      throw Exception('El usuario no es miembro del grupo');
    }
    
    // Evitar promover si ya es admin
    if (group.adminIds.contains(userId)) {
      return; // Ya es admin
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Agregar a la colección de admins
    await _firestore.collection('groups').doc(groupId).update({
      'groupAdmin': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
    });
    
    // Registrar cambio de rol
    await _logService.logGroupRoleChange(
      userId: userId,
      group: group,
      actorId: actorId,
      newRole: 'admin',
      previousRole: 'member',
      reason: reason,
    );
  }
  
  /// Degrada a un administrador a miembro regular del grupo
  Future<void> demoteToMember(String userId, String groupId, {String? reason}) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    // Verificar que el usuario es admin
    if (!group.adminIds.contains(userId)) {
      return; // No es admin, nada que hacer
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Eliminar de la colección de admins
    await _firestore.collection('groups').doc(groupId).update({
      'groupAdmin': FieldValue.arrayRemove([_firestore.doc('users/$userId')]),
    });
    
    // Registrar cambio de rol
    await _logService.logGroupRoleChange(
      userId: userId,
      group: group,
      actorId: actorId,
      newRole: 'member',
      previousRole: 'admin',
      reason: reason,
    );
  }
  
  /// Solicita unirse a un grupo
  Future<void> requestToJoin(String groupId, {String? message}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final userId = currentUser.uid;
    
    // Verificar que el grupo existe
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    // Verificar que el usuario no es ya miembro
    if (group.memberIds.contains(userId)) {
      throw Exception('Ya eres miembro de este grupo');
    }
    
    // Verificar que no tiene una solicitud pendiente
    if (group.pendingRequests.containsKey(userId)) {
      throw Exception('Ya tienes una solicitud pendiente para este grupo');
    }
    
    // Añadir solicitud pendiente a la colección de grupos (para mantener compatibilidad)
    await _firestore.collection('groups').doc(groupId).update({
      'pendingRequests.$userId': Timestamp.now(),
    });
    
    // Registrar la solicitud en el nuevo servicio de solicitudes
    await _requestService.logRequest(
      userId: userId,
      entityId: groupId,
      entityType: 'group',
      entityName: group.name,
      message: message,
    );
  }
  
  /// Acepta una solicitud pendiente
  Future<void> acceptJoinRequest(String userId, String groupId, {String? reason}) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    // Verificar que el usuario tiene una solicitud pendiente
    if (!group.pendingRequests.containsKey(userId)) {
      throw Exception('El usuario no tiene una solicitud pendiente');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Buscar la solicitud en la colección de solicitudes
    final requestDoc = await _requestService.findRequest(userId, groupId, 'group');
    if (requestDoc != null) {
      await _requestService.markRequestAsAccepted(
        requestId: requestDoc.id,
        actorId: actorId,
        reason: reason,
      );
    }
    
    // Añadir usuario como miembro
    await addUserToGroup(userId, groupId, reason: reason);
  }
  
  /// Rechaza una solicitud pendiente
  Future<void> rejectJoinRequest(String userId, String groupId, {String? reason}) async {
    final group = await getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado');
    }
    
    // Verificar que el usuario tiene una solicitud pendiente
    if (!group.pendingRequests.containsKey(userId)) {
      throw Exception('El usuario no tiene una solicitud pendiente');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Buscar la solicitud en la colección de solicitudes
    final requestDoc = await _requestService.findRequest(userId, groupId, 'group');
    if (requestDoc != null) {
      await _requestService.markRequestAsRejected(
        requestId: requestDoc.id,
        actorId: actorId,
        reason: reason,
      );
    }
    
    // Eliminar solicitud pendiente y añadir a rechazadas
    final requestData = group.pendingRequests[userId];
    await _firestore.collection('groups').doc(groupId).update({
      'pendingRequests.$userId': FieldValue.delete(),
      'rejectedRequests.$userId': {
        'timestamp': FieldValue.serverTimestamp(),
        'rejectedBy': actorId,
        'originalRequest': requestData,
        'reason': reason,
      },
    });
  }
  
  /// Obtiene estadísticas de miembros del grupo
  Future<Map<String, dynamic>> getGroupMemberStats(String groupId) async {
    return await _logService.getGroupMembershipStats(groupId);
  }
  
  // Método para registrar la salida de un miembro (voluntaria)
  Future<void> recordMemberExit(String userId, String groupId, {String? reason}) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
      final groupDoc = await groupRef.get();
      
      if (!userDoc.exists || !groupDoc.exists) {
        throw Exception('Usuario o grupo no existe');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final groupData = groupDoc.data() as Map<String, dynamic>;
      
      // Obtener la fecha en que el usuario se unió al grupo (si está disponible)
      DateTime? joinDate;
      try {
        final membershipQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('userId', isEqualTo: userId)
            .where('entityId', isEqualTo: groupId)
            .where('entityType', isEqualTo: 'group')
            .where('status', isEqualTo: 'accepted')
            .get();
            
        if (membershipQuery.docs.isNotEmpty) {
          final membershipData = membershipQuery.docs.first.data();
          joinDate = membershipData['responseTimestamp'] != null 
              ? (membershipData['responseTimestamp'] as Timestamp).toDate()
              : null;
        }
      } catch (e) {
        print('Error al obtener fecha de unión: $e');
      }
      
      // Crear registro de salida
      await FirebaseFirestore.instance.collection('member_exits').add({
        'userId': userId,
        'userName': userData['name'] ?? 'Usuario desconocido',
        'userEmail': userData['email'] ?? '',
        'userPhotoUrl': userData['photoUrl'] ?? '',
        'entityId': groupId,
        'entityType': 'group',
        'entityName': groupData['name'] ?? 'Grupo',
        'exitType': 'voluntary', // Salida voluntaria
        'exitTimestamp': FieldValue.serverTimestamp(),
        'exitReason': reason,
        'joinTimestamp': joinDate != null ? Timestamp.fromDate(joinDate) : null,
      });
      
      // Eliminar al miembro del grupo
      await groupRef.update({
        'members': FieldValue.arrayRemove([userRef]),
      });
      
    } catch (e) {
      print('Error al registrar salida: $e');
      throw Exception('Error al registrar salida: $e');
    }
  }
  
  // Método para registrar cuando un administrador elimina a un miembro
  Future<void> removeMember(String userId, String groupId, String adminId, {String? reason}) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
      final groupDoc = await groupRef.get();
      
      if (!userDoc.exists || !groupDoc.exists) {
        throw Exception('Usuario o grupo no existe');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final groupData = groupDoc.data() as Map<String, dynamic>;
      
      // Obtener la fecha en que el usuario se unió al grupo (si está disponible)
      DateTime? joinDate;
      try {
        final membershipQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('userId', isEqualTo: userId)
            .where('entityId', isEqualTo: groupId)
            .where('entityType', isEqualTo: 'group')
            .where('status', isEqualTo: 'accepted')
            .get();
            
        if (membershipQuery.docs.isNotEmpty) {
          final membershipData = membershipQuery.docs.first.data();
          joinDate = membershipData['responseTimestamp'] != null 
              ? (membershipData['responseTimestamp'] as Timestamp).toDate()
              : null;
        }
      } catch (e) {
        print('Error al obtener fecha de unión: $e');
      }
      
      // Crear registro de eliminación
      await FirebaseFirestore.instance.collection('member_exits').add({
        'userId': userId,
        'userName': userData['name'] ?? 'Usuario desconocido',
        'userEmail': userData['email'] ?? '',
        'userPhotoUrl': userData['photoUrl'] ?? '',
        'entityId': groupId,
        'entityType': 'group',
        'entityName': groupData['name'] ?? 'Grupo',
        'exitType': 'removed', // Eliminado por administrador
        'exitTimestamp': FieldValue.serverTimestamp(),
        'exitReason': reason,
        'joinTimestamp': joinDate != null ? Timestamp.fromDate(joinDate) : null,
        'removedById': adminId,
      });
      
      // Eliminar al miembro del grupo
      await groupRef.update({
        'members': FieldValue.arrayRemove([userRef]),
      });
      
    } catch (e) {
      print('Error al eliminar miembro: $e');
      throw Exception('Error al eliminar miembro: $e');
    }
  }
} 