import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_group.dart';
import 'membership_request_service.dart';

/// Servicio para gestionar la nueva funcionalidad de "Familias".
/// Usa la colección `family_groups` y guarda miembros como DocumentReference
/// (igual que grupos/ministerios) para mantener consistencia.
class FamilyGroupService {
  FamilyGroupService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MembershipRequestService? requestService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _requestService = requestService ?? MembershipRequestService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MembershipRequestService _requestService;

  CollectionReference get _families =>
      _firestore.collection('family_groups');

  DocumentReference _userRef(String userId) =>
      _firestore.doc('/users/$userId');

  /// Familias donde el usuario es miembro (incluye admins).
  Stream<List<FamilyGroup>> streamUserFamilies(String userId) {
    return _families
        .where('members', arrayContains: _userRef(userId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyGroup.fromFirestore(doc))
            .toList());
  }

  /// Todas las familias (para admin iglesia).
  Stream<List<FamilyGroup>> streamAllFamilies() {
    return _families.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => FamilyGroup.fromFirestore(doc)).toList());
  }

  /// Observa una familia puntual.
  Stream<FamilyGroup?> watchFamily(String familyId) {
    return _families.doc(familyId).snapshots().map(
        (doc) => doc.exists ? FamilyGroup.fromFirestore(doc) : null);
  }

  Future<FamilyGroup?> getFamily(String familyId) async {
    final snap = await _families.doc(familyId).get();
    if (!snap.exists) return null;
    return FamilyGroup.fromFirestore(snap);
  }

  /// Crea una nueva familia asignando al creador como admin y miembro activo.
  Future<String> createFamily(
    String name, {
    String? description,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    final now = FieldValue.serverTimestamp();
    final doc = _families.doc();
    await doc.set({
      'name': name,
      'creator': _userRef(user.uid),
      'admins': [_userRef(user.uid)],
      'members': [_userRef(user.uid)],
      'memberRoles': {user.uid: 'admin'},
      'pendingInvites': {},
      'pendingRequests': {},
      'createdAt': now,
      'updatedAt': now,
      'description': description ?? '',
      'photoUrl': photoUrl ?? '',
    });
    return doc.id;
  }

  Future<void> renameFamily(String familyId, String name) async {
    await _families.doc(familyId).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFamilyInfo({
    required String familyId,
    String? name,
    String? description,
    String? photoUrl,
  }) async {
    final update = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
    await _families.doc(familyId).update(update);
  }

  /// Invitar usuarios (solo admin). Registra invitación en Firestore y en membership_requests.
  Future<void> inviteMembers({
    required String familyId,
    required List<String> userIds,
    String role = 'otro',
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) throw Exception('Usuario no autenticado');

    final family = await getFamily(familyId);
    if (family == null) throw Exception('Familia no encontrada');

    // Evitar invitar a miembros/pendientes
    final pendingUpdates = <String, dynamic>{};
    for (final uid in userIds) {
      if (family.memberIds.contains(uid)) continue;
      if (family.pendingInvites.containsKey(uid)) continue;
      pendingUpdates['pendingInvites.$uid'] = {
        'role': role,
        'invitedBy': actor.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };
    }

    if (pendingUpdates.isEmpty) return;

    await _families.doc(familyId).update({
      ...pendingUpdates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final uid in userIds) {
      await _requestService.logRequest(
        userId: uid,
        entityId: familyId,
        entityType: 'family',
        entityName: family.name,
        requestType: 'invite',
        desiredRole: role,
        invitedBy: actor.uid,
      );
    }
  }

  /// Aceptar invitación por parte del invitado.
  Future<void> acceptInvite({
    required String familyId,
    required String userId,
  }) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Familia no encontrada');

    final invite = family.pendingInvites[userId] as Map<String, dynamic>?;
    final role = invite?['role']?.toString() ?? 'otro';

    final updates = <String, dynamic>{
      'members': FieldValue.arrayUnion([_userRef(userId)]),
      'memberRoles.$userId': role,
      'pendingInvites.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _families.doc(familyId).update(updates);

    final requestDoc =
        await _requestService.findRequest(userId, familyId, 'family');
    if (requestDoc != null) {
      await _requestService.markRequestAsAccepted(
        requestId: requestDoc.id,
        actorId: userId,
      );
    }
  }

  Future<void> rejectInvite({
    required String familyId,
    required String userId,
  }) async {
    await _families.doc(familyId).update({
      'pendingInvites.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final requestDoc =
        await _requestService.findRequest(userId, familyId, 'family');
    if (requestDoc != null) {
      await _requestService.markRequestAsRejected(
        requestId: requestDoc.id,
        actorId: userId,
      );
    }
  }

  /// Usuario solicita unirse a una familia con un rol deseado.
  Future<void> requestToJoin({
    required String familyId,
    required String desiredRole,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final family = await getFamily(familyId);
    if (family == null) throw Exception('Familia no encontrada');

    if (family.memberIds.contains(user.uid)) {
      throw Exception('Ya eres miembro de esta familia');
    }
    if (family.pendingRequests.containsKey(user.uid)) {
      throw Exception('Solicitud pendiente ya registrada');
    }

    await _families.doc(familyId).update({
      'pendingRequests.${user.uid}': {
        'role': desiredRole,
        'createdAt': FieldValue.serverTimestamp(),
        if (message != null) 'message': message,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _requestService.logRequest(
      userId: user.uid,
      entityId: familyId,
      entityType: 'family',
      entityName: family.name,
      message: message,
      requestType: 'join',
      desiredRole: desiredRole,
    );
  }

  /// Admin acepta una solicitud de unión.
  Future<void> acceptJoinRequest({
    required String familyId,
    required String userId,
    String? reason,
  }) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Familia no encontrada');

    final pending = family.pendingRequests[userId] as Map<String, dynamic>?;
    if (pending == null) {
      throw Exception('No hay solicitud pendiente');
    }
    final role = pending['role']?.toString() ?? 'otro';

    await _families.doc(familyId).update({
      'members': FieldValue.arrayUnion([_userRef(userId)]),
      'memberRoles.$userId': role,
      'pendingRequests.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final actorId = _auth.currentUser?.uid ?? 'system';
    final requestDoc =
        await _requestService.findRequest(userId, familyId, 'family');
    if (requestDoc != null) {
      await _requestService.markRequestAsAccepted(
        requestId: requestDoc.id,
        actorId: actorId,
        reason: reason,
      );
    }
  }

  Future<void> rejectJoinRequest({
    required String familyId,
    required String userId,
    String? reason,
  }) async {
    await _families.doc(familyId).update({
      'pendingRequests.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final actorId = _auth.currentUser?.uid ?? 'system';
    final requestDoc =
        await _requestService.findRequest(userId, familyId, 'family');
    if (requestDoc != null) {
      await _requestService.markRequestAsRejected(
        requestId: requestDoc.id,
        actorId: actorId,
        reason: reason,
      );
    }
  }

  Future<void> changeRole({
    required String familyId,
    required String userId,
    required String role,
  }) async {
    await _families.doc(familyId).update({
      'memberRoles.$userId': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAdmin({
    required String familyId,
    required String userId,
    required bool isAdmin,
  }) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Familia no encontrada');

    final admins = [...family.adminIds];
    if (isAdmin) {
      if (!admins.contains(userId)) admins.add(userId);
    } else {
      admins.remove(userId);
      if (admins.isEmpty) {
        throw Exception('Debe existir al menos un administrador');
      }
    }

    await _families.doc(familyId).update({
      'admins': admins.map((id) => _userRef(id)).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeMember({
    required String familyId,
    required String userId,
  }) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Familia no encontrada');

    if (family.adminIds.contains(userId) && family.adminIds.length <= 1) {
      throw Exception('Asigna otro admin antes de salir');
    }

    await _families.doc(familyId).update({
      'members': FieldValue.arrayRemove([_userRef(userId)]),
      'admins': FieldValue.arrayRemove([_userRef(userId)]),
      'memberRoles.$userId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveFamily(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    await removeMember(familyId: familyId, userId: user.uid);
  }
}
