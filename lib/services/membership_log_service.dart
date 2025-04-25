import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membership_log.dart';
import '../models/ministry.dart';
import '../models/group.dart';

class MembershipLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'membership_logs';

  /// Registra una entrada a un ministerio
  Future<void> logMinistryJoin({
    required String userId,
    required Ministry ministry,
    required String initiatedBy, // 'user' o 'admin'
    required String actorId,    // ID del que realiza la acción
    String? reason,
    String? role,
  }) async {
    final log = MembershipLog.createJoinLog(
      userId: userId,
      entityId: ministry.id,
      entityType: 'ministry',
      entityName: ministry.name,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      roleInEntity: role ?? (ministry.adminIds.contains(userId) ? 'admin' : 'member'),
    );
    
    await _firestore.collection(_collectionPath).add(log.toMap());
  }

  /// Registra una salida de un ministerio
  Future<void> logMinistryLeave({
    required String userId,
    required Ministry ministry,
    required String initiatedBy, // 'user' (salida voluntaria) o 'admin' (expulsión)
    required String actorId,    // ID del que realiza la acción
    String? reason,
  }) async {
    // Determinar el rol que tenía antes de salir
    String? previousRole;
    if (ministry.adminIds.contains(userId)) {
      previousRole = 'admin';
    } else if (ministry.memberIds.contains(userId)) {
      previousRole = 'member';
    }
    
    final log = MembershipLog.createLeaveLog(
      userId: userId,
      entityId: ministry.id,
      entityType: 'ministry',
      entityName: ministry.name,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      roleInEntity: previousRole,
    );
    
    await _firestore.collection(_collectionPath).add(log.toMap());
  }

  /// Registra un cambio de rol en un ministerio
  Future<void> logMinistryRoleChange({
    required String userId,
    required Ministry ministry,
    required String actorId,
    required String newRole,
    String? previousRole,
    String? reason,
  }) async {
    // Si no se proporciona el rol anterior, intentar determinarlo
    if (previousRole == null) {
      if (ministry.adminIds.contains(userId)) {
        previousRole = 'admin';
      } else if (ministry.memberIds.contains(userId)) {
        previousRole = 'member';
      }
    }
    
    final log = MembershipLog.createRoleChangeLog(
      userId: userId,
      entityId: ministry.id,
      entityType: 'ministry',
      entityName: ministry.name,
      actorId: actorId,
      newRole: newRole,
      previousRole: previousRole,
      reason: reason,
    );
    
    await _firestore.collection(_collectionPath).add(log.toMap());
  }

  /// Registra una entrada a un grupo
  Future<void> logGroupJoin({
    required String userId,
    required Group group,
    required String initiatedBy, // 'user' o 'admin'
    required String actorId,    // ID del que realiza la acción
    String? reason,
    String? role,
  }) async {
    final log = MembershipLog.createJoinLog(
      userId: userId,
      entityId: group.id,
      entityType: 'group',
      entityName: group.name,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      roleInEntity: role ?? (group.adminIds.contains(userId) ? 'admin' : 'member'),
    );
    
    await _firestore.collection(_collectionPath).add(log.toMap());
  }

  /// Registra una salida de un grupo
  Future<void> logGroupLeave({
    required String userId,
    required Group group,
    required String initiatedBy, // 'user' (salida voluntaria) o 'admin' (expulsión)
    required String actorId,    // ID del que realiza la acción
    String? reason,
  }) async {
    // Determinar el rol que tenía antes de salir
    String? previousRole;
    if (group.adminIds.contains(userId)) {
      previousRole = 'admin';
    } else if (group.memberIds.contains(userId)) {
      previousRole = 'member';
    }
    
    final log = MembershipLog.createLeaveLog(
      userId: userId,
      entityId: group.id,
      entityType: 'group',
      entityName: group.name,
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      roleInEntity: previousRole,
    );
    
    await _firestore.collection(_collectionPath).add(log.toMap());
  }

  /// Registra un cambio de rol en un grupo
  Future<void> logGroupRoleChange({
    required String userId,
    required Group group,
    required String actorId,
    required String newRole,
    String? previousRole,
    String? reason,
  }) async {
    // Si no se proporciona el rol anterior, intentar determinarlo
    if (previousRole == null) {
      if (group.adminIds.contains(userId)) {
        previousRole = 'admin';
      } else if (group.memberIds.contains(userId)) {
        previousRole = 'member';
      }
    }
    
    final log = MembershipLog.createRoleChangeLog(
      userId: userId,
      entityId: group.id,
      entityType: 'group',
      entityName: group.name,
      actorId: actorId,
      newRole: newRole,
      previousRole: previousRole,
      reason: reason,
    );
    
    await _firestore.collection(_collectionPath).add(log.toMap());
  }
  
  /// Obtiene los registros de un usuario en un ministerio específico
  Stream<List<MembershipLog>> getUserMinistryLogs(String userId, String ministryId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('entityId', isEqualTo: ministryId)
        .where('entityType', isEqualTo: 'ministry')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MembershipLog.fromFirestore(doc)).toList());
  }
  
  /// Obtiene los registros de un usuario en un grupo específico
  Stream<List<MembershipLog>> getUserGroupLogs(String userId, String groupId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .where('entityId', isEqualTo: groupId)
        .where('entityType', isEqualTo: 'group')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MembershipLog.fromFirestore(doc)).toList());
  }
  
  /// Obtiene todos los registros de un usuario (ministerios y grupos)
  Stream<List<MembershipLog>> getAllUserLogs(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MembershipLog.fromFirestore(doc)).toList());
  }
  
  /// Obtiene los registros de todos los miembros de un ministerio
  Stream<List<MembershipLog>> getMinistryLogs(String ministryId) {
    return _firestore
        .collection(_collectionPath)
        .where('entityId', isEqualTo: ministryId)
        .where('entityType', isEqualTo: 'ministry')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MembershipLog.fromFirestore(doc)).toList());
  }
  
  /// Obtiene los registros de todos los miembros de un grupo
  Stream<List<MembershipLog>> getGroupLogs(String groupId) {
    return _firestore
        .collection(_collectionPath)
        .where('entityId', isEqualTo: groupId)
        .where('entityType', isEqualTo: 'group')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MembershipLog.fromFirestore(doc)).toList());
  }
  
  /// Obtiene estadísticas básicas de membresía para un ministerio
  Future<Map<String, dynamic>> getMinistryMembershipStats(String ministryId) async {
    final logs = await _firestore
        .collection(_collectionPath)
        .where('entityId', isEqualTo: ministryId)
        .where('entityType', isEqualTo: 'ministry')
        .get();
        
    final joinLogs = logs.docs.where((doc) => (doc.data()['actionType'] as String) == 'join').length;
    final leaveLogs = logs.docs.where((doc) => (doc.data()['actionType'] as String) == 'leave').length;
    final roleChangeLogs = logs.docs.where((doc) => (doc.data()['actionType'] as String) == 'role_change').length;
    
    // Calcular por tipo de iniciador (voluntario vs. forzado)
    final voluntaryJoins = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'join' && 
        (doc.data()['initiatedBy'] as String) == 'user').length;
        
    final voluntaryLeaves = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'leave' && 
        (doc.data()['initiatedBy'] as String) == 'user').length;
        
    final adminJoins = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'join' && 
        (doc.data()['initiatedBy'] as String) == 'admin').length;
        
    final adminLeaves = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'leave' && 
        (doc.data()['initiatedBy'] as String) == 'admin').length;
    
    return {
      'totalJoins': joinLogs,
      'totalLeaves': leaveLogs,
      'roleChanges': roleChangeLogs,
      'voluntaryJoins': voluntaryJoins,
      'voluntaryLeaves': voluntaryLeaves,
      'adminJoins': adminJoins,
      'adminLeaves': adminLeaves,
      'currentMemberCount': joinLogs - leaveLogs, // Aproximación básica
    };
  }
  
  /// Obtiene estadísticas básicas de membresía para un grupo
  Future<Map<String, dynamic>> getGroupMembershipStats(String groupId) async {
    final logs = await _firestore
        .collection(_collectionPath)
        .where('entityId', isEqualTo: groupId)
        .where('entityType', isEqualTo: 'group')
        .get();
        
    final joinLogs = logs.docs.where((doc) => (doc.data()['actionType'] as String) == 'join').length;
    final leaveLogs = logs.docs.where((doc) => (doc.data()['actionType'] as String) == 'leave').length;
    final roleChangeLogs = logs.docs.where((doc) => (doc.data()['actionType'] as String) == 'role_change').length;
    
    // Calcular por tipo de iniciador (voluntario vs. forzado)
    final voluntaryJoins = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'join' && 
        (doc.data()['initiatedBy'] as String) == 'user').length;
        
    final voluntaryLeaves = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'leave' && 
        (doc.data()['initiatedBy'] as String) == 'user').length;
        
    final adminJoins = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'join' && 
        (doc.data()['initiatedBy'] as String) == 'admin').length;
        
    final adminLeaves = logs.docs.where((doc) => 
        (doc.data()['actionType'] as String) == 'leave' && 
        (doc.data()['initiatedBy'] as String) == 'admin').length;
    
    return {
      'totalJoins': joinLogs,
      'totalLeaves': leaveLogs,
      'roleChanges': roleChangeLogs,
      'voluntaryJoins': voluntaryJoins,
      'voluntaryLeaves': voluntaryLeaves,
      'adminJoins': adminJoins,
      'adminLeaves': adminLeaves,
      'currentMemberCount': joinLogs - leaveLogs, // Aproximación básica
    };
  }
} 