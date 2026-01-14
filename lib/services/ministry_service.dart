import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ministry.dart';
import './membership_log_service.dart';
import './membership_request_service.dart';
import 'package:flutter/foundation.dart';

class MinistryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MembershipLogService _logService = MembershipLogService();
  final MembershipRequestService _requestService = MembershipRequestService();

  // Obtener todos los ministerios
  Stream<List<Ministry>> getMinistries() {
    return _firestore
        .collection('ministries')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Ministry.fromFirestore(doc)).toList());
  }

  // Obtener un ministerio específico
  Future<Ministry?> getMinistryById(String ministryId) async {
    final doc = await _firestore.collection('ministries').doc(ministryId).get();
    if (!doc.exists) return null;
    return Ministry.fromFirestore(doc);
  }

  // Obtener los ministerios a los que pertenece un usuario
  Stream<List<Ministry>> getUserMinistries(String userId) {
    return _firestore
        .collection('ministries')
        .where('members', arrayContains: _firestore.doc('users/$userId'))
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Ministry.fromFirestore(doc)).toList());
  }

  // Añadir un usuario a un ministerio
  Future<void> addUserToMinistry(String userId, String ministryId, {bool isAdmin = false, String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    // Evitar duplicados
    if (ministry.memberIds.contains(userId)) {
      return; // El usuario ya es miembro
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    final bool isSelfJoin = actorId == userId;
    
    final initiatedBy = isSelfJoin ? 'user' : 'admin';
    
    // Añadir a la colección adecuada según el rol
    if (isAdmin) {
      await _firestore.collection('ministries').doc(ministryId).update({
        'members': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
        'ministrieAdmin': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
      });
    } else {
      await _firestore.collection('ministries').doc(ministryId).update({
        'members': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
      });
    }
    
    // Si hay solicitudes pendientes, eliminarlas
    if (ministry.pendingRequests.containsKey(userId)) {
      await _firestore.collection('ministries').doc(ministryId).update({
        'pendingRequests.$userId': FieldValue.delete(),
      });
    }
    
    // Registrar la entrada
    await _logService.logMinistryJoin(
      userId: userId,
      ministry: ministry,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      role: isAdmin ? 'admin' : 'member',
    );
  }

  // Eliminar un usuario de un ministerio
  Future<void> removeUserFromMinistry(String userId, String ministryId, {String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    final bool isSelfRemoval = actorId == userId;
    
    final initiatedBy = isSelfRemoval ? 'user' : 'admin';
    
    // Registrar la salida antes de eliminar (para capturar el rol actual)
    await _logService.logMinistryLeave(
      userId: userId,
      ministry: ministry,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
    );
    
    // Eliminar de la colección de miembros
    await _firestore.collection('ministries').doc(ministryId).update({
      'members': FieldValue.arrayRemove([_firestore.doc('users/$userId')]),
    });
    
    // Si es admin, también eliminar de la colección de admins
    if (ministry.adminIds.contains(userId)) {
      await _firestore.collection('ministries').doc(ministryId).update({
        'ministrieAdmin': FieldValue.arrayRemove([_firestore.doc('users/$userId')]),
      });
    }
  }

  // Promover a un usuario a administrador del ministerio
  Future<void> promoteToAdmin(String userId, String ministryId, {String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    // Verificar que el usuario es miembro
    if (!ministry.memberIds.contains(userId)) {
      throw Exception('El usuario no es miembro del ministerio');
    }
    
    // Evitar promover si ya es admin
    if (ministry.adminIds.contains(userId)) {
      return; // Ya es admin
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Agregar a la colección de admins
    await _firestore.collection('ministries').doc(ministryId).update({
      'ministrieAdmin': FieldValue.arrayUnion([_firestore.doc('users/$userId')]),
    });
    
    // Registrar cambio de rol
    await _logService.logMinistryRoleChange(
      userId: userId,
      ministry: ministry,
      actorId: actorId,
      newRole: 'admin',
      previousRole: 'member',
      reason: reason,
    );
  }

  // Degradar a un administrador a miembro regular del ministerio
  Future<void> demoteToMember(String userId, String ministryId, {String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    // Verificar que el usuario es admin
    if (!ministry.adminIds.contains(userId)) {
      return; // No es admin, nada que hacer
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Eliminar de la colección de admins
    await _firestore.collection('ministries').doc(ministryId).update({
      'ministrieAdmin': FieldValue.arrayRemove([_firestore.doc('users/$userId')]),
    });
    
    // Registrar cambio de rol
    await _logService.logMinistryRoleChange(
      userId: userId,
      ministry: ministry,
      actorId: actorId,
      newRole: 'member',
      previousRole: 'admin',
      reason: reason,
    );
  }

  // Solicitar unirse a un ministerio
  Future<void> requestToJoin(String ministryId, {String? message}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final userId = currentUser.uid;
    
    // Verificar que el ministerio existe
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    // Verificar que el usuario no es ya miembro
    if (ministry.memberIds.contains(userId)) {
      throw Exception('Ya eres miembro de este ministerio');
    }
    
    // Verificar que no tiene una solicitud pendiente
    if (ministry.pendingRequests.containsKey(userId)) {
      throw Exception('Ya tienes una solicitud pendiente para este ministerio');
    }
    
    // Añadir solicitud pendiente a la colección de ministerios (para mantener compatibilidad)
    await _firestore.collection('ministries').doc(ministryId).update({
      'pendingRequests.$userId': Timestamp.now(),
    });
    
    // Registrar la solicitud en el nuevo servicio de solicitudes
    await _requestService.logRequest(
      userId: userId,
      entityId: ministryId,
      entityType: 'ministry',
      entityName: ministry.name,
      message: message,
    );
  }

  // Invitar a un usuario a un ministerio (sin añadirlo directamente)
  Future<void> inviteUserToMinistry(String userId, String ministryId, {String? message}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }

    if (ministry.memberIds.contains(userId)) {
      throw Exception('El usuario ya es miembro del ministerio');
    }

    if (ministry.pendingRequests.containsKey(userId)) {
      throw Exception('El usuario ya tiene una solicitud pendiente');
    }

    await _firestore.collection('ministries').doc(ministryId).update({
      'pendingRequests.$userId': Timestamp.now(),
    });

    final inviterDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final inviterName = inviterDoc.data()?['name'] ?? inviterDoc.data()?['displayName'] ?? 'Administrador';

    await _requestService.logRequest(
      userId: userId,
      entityId: ministryId,
      entityType: 'ministry',
      entityName: ministry.name,
      message: message,
      requestType: 'invite',
      invitedBy: currentUser.uid,
      invitedByName: inviterName,
    );
  }

  // Aceptar una solicitud pendiente
  Future<void> acceptJoinRequest(String userId, String ministryId, {String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    // Verificar que el usuario tiene una solicitud pendiente
    if (!ministry.pendingRequests.containsKey(userId)) {
      throw Exception('El usuario no tiene una solicitud pendiente');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Buscar la solicitud en la colección de solicitudes
    final requestDoc = await _requestService.findRequest(userId, ministryId, 'ministry');
    if (requestDoc != null) {
      await _requestService.markRequestAsAccepted(
        requestId: requestDoc.id,
        actorId: actorId,
        reason: reason,
      );
    }
    
    // Añadir usuario como miembro
    await addUserToMinistry(userId, ministryId, reason: reason);
  }

  // Rechazar una solicitud pendiente
  Future<void> rejectJoinRequest(String userId, String ministryId, {String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    // Verificar que el usuario tiene una solicitud pendiente
    if (!ministry.pendingRequests.containsKey(userId)) {
      throw Exception('El usuario no tiene una solicitud pendiente');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    
    // Buscar la solicitud en la colección de solicitudes
    final requestDoc = await _requestService.findRequest(userId, ministryId, 'ministry');
    if (requestDoc != null) {
      await _requestService.markRequestAsRejected(
        requestId: requestDoc.id,
        actorId: actorId,
        reason: reason,
      );
    }
    
    // Eliminar solicitud pendiente y añadir a rechazadas
    final requestData = ministry.pendingRequests[userId];
    await _firestore.collection('ministries').doc(ministryId).update({
      'pendingRequests.$userId': FieldValue.delete(),
      'rejectedRequests.$userId': {
        'timestamp': FieldValue.serverTimestamp(),
        'rejectedBy': actorId,
        'originalRequest': requestData,
        'reason': reason,
      },
    });
  }

  // Obtener estadísticas de miembros del ministerio
  Future<Map<String, dynamic>> getMinistryMemberStats(String ministryId) async {
    return await _logService.getMinistryMembershipStats(ministryId);
  }

  // Añadir múltiples usuarios a un ministerio
  Future<void> addUsersToMinistry(String ministryId, List<String> userIds, {bool isAdmin = false, String? reason}) async {
    final ministry = await getMinistryById(ministryId);
    if (ministry == null) {
      throw Exception('Ministerio no encontrado');
    }
    
    final currentUser = _auth.currentUser;
    final String actorId = currentUser?.uid ?? 'system';
    final String initiatedBy = 'admin'; // Siempre será admin cuando se añaden múltiples usuarios
    
    // Filtrar usuarios que ya son miembros
    final newUserIds = userIds.where((id) => !ministry.memberIds.contains(id)).toList();
    if (newUserIds.isEmpty) return; // No hay nuevos usuarios para añadir
    
    // Referencias a documentos de usuarios
    final newUserRefs = newUserIds.map((id) => _firestore.doc('users/$id')).toList();
    
    // Añadir usuarios en una sola operación
    if (isAdmin) {
      await _firestore.collection('ministries').doc(ministryId).update({
        'members': FieldValue.arrayUnion(newUserRefs),
        'ministrieAdmin': FieldValue.arrayUnion(newUserRefs),
      });
    } else {
      await _firestore.collection('ministries').doc(ministryId).update({
        'members': FieldValue.arrayUnion(newUserRefs),
      });
    }
    
    // Eliminar solicitudes pendientes si las hay
    for (final userId in newUserIds) {
      if (ministry.pendingRequests.containsKey(userId)) {
        await _firestore.collection('ministries').doc(ministryId).update({
          'pendingRequests.$userId': FieldValue.delete(),
        });
      }
    }
    
    // Registrar la entrada para cada usuario
    for (final userId in newUserIds) {
      await _logService.logMinistryJoin(
        userId: userId,
        ministry: ministry,
        initiatedBy: initiatedBy,
        actorId: actorId,
        reason: reason,
        role: isAdmin ? 'admin' : 'member',
      );
    }
  }

  // Método para registrar la salida de un miembro (voluntaria)
  Future<void> recordMemberExit(String userId, String ministryId, {String? reason}) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final ministryRef = FirebaseFirestore.instance.collection('ministries').doc(ministryId);
      final ministryDoc = await ministryRef.get();
      
      if (!userDoc.exists || !ministryDoc.exists) {
        throw Exception('Usuario o ministerio no existe');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final ministryData = ministryDoc.data() as Map<String, dynamic>;
      
      // Obtener la fecha en que el usuario se unió al ministerio (si está disponible)
      DateTime? joinDate;
      try {
        final membershipQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('userId', isEqualTo: userId)
            .where('entityId', isEqualTo: ministryId)
            .where('entityType', isEqualTo: 'ministry')
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
        'entityId': ministryId,
        'entityType': 'ministry',
        'entityName': ministryData['name'] ?? 'Ministerio',
        'exitType': 'voluntary', // Salida voluntaria
        'exitTimestamp': FieldValue.serverTimestamp(),
        'exitReason': reason,
        'joinTimestamp': joinDate != null ? Timestamp.fromDate(joinDate) : null,
      });
      
      // Eliminar al miembro del ministerio
      await ministryRef.update({
        'members': FieldValue.arrayRemove([userRef]),
      });
      
    } catch (e) {
      print('Error al registrar salida: $e');
      throw Exception('Error al registrar salida: $e');
    }
  }
  
  // Método para registrar cuando un administrador elimina a un miembro
  Future<void> removeMember(String userId, String ministryId, String adminId, {String? reason}) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final ministryRef = FirebaseFirestore.instance.collection('ministries').doc(ministryId);
      final ministryDoc = await ministryRef.get();
      
      if (!userDoc.exists || !ministryDoc.exists) {
        throw Exception('Usuario o ministerio no existe');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final ministryData = ministryDoc.data() as Map<String, dynamic>;
      
      // Obtener la fecha en que el usuario se unió al ministerio (si está disponible)
      DateTime? joinDate;
      try {
        final membershipQuery = await FirebaseFirestore.instance
            .collection('membership_requests')
            .where('userId', isEqualTo: userId)
            .where('entityId', isEqualTo: ministryId)
            .where('entityType', isEqualTo: 'ministry')
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
        'entityId': ministryId,
        'entityType': 'ministry',
        'entityName': ministryData['name'] ?? 'Ministerio',
        'exitType': 'removed', // Eliminado por administrador
        'exitTimestamp': FieldValue.serverTimestamp(),
        'exitReason': reason,
        'joinTimestamp': joinDate != null ? Timestamp.fromDate(joinDate) : null,
        'removedById': adminId,
      });
      
      // Eliminar al miembro del ministerio
      await ministryRef.update({
        'members': FieldValue.arrayRemove([userRef]),
      });
      
    } catch (e) {
      print('Error al eliminar miembro: $e');
      throw Exception('Error al eliminar miembro: $e');
    }
  }

  /// Elimina un ministerio por su ID
  Future<void> deleteMinistry(String ministryId) async {
    try {
      // Primero obtenemos las referencias a los miembros para poder limpiar relaciones
      final ministryDoc = await _firestore.collection('ministries').doc(ministryId).get();
      final ministry = Ministry.fromFirestore(ministryDoc);
      
      // Obtener todos los miembros del ministerio
      final members = ministry.memberIds ?? [];
      
      // Batch para hacer todas las operaciones atómicamente
      final batch = _firestore.batch();
      
      // Eliminar el ministerio
      batch.delete(_firestore.collection('ministries').doc(ministryId));
      
      // Actualizar usuarios que pertenecen al ministerio (quitar la referencia)
      for (String userId in members) {
        batch.update(
          _firestore.collection('users').doc(userId), 
          {'ministryIds': FieldValue.arrayRemove([ministryId])}
        );
      }
      
      // Ejecutar batch
      await batch.commit();
      
      debugPrint('✅ Ministerio $ministryId eliminado con éxito');
    } catch (e) {
      debugPrint('❌ Error al eliminar ministerio $ministryId: $e');
      rethrow;
    }
  }
} 
