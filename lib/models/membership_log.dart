import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para registrar el historial de pertenencia a ministerios y grupos
class MembershipLog {
  final String id;
  final String userId;           // Usuario afectado
  final String entityId;         // ID del ministerio o grupo
  final String entityType;       // 'ministry' o 'group'
  final String entityName;       // Nombre del ministerio o grupo (para facilitar consultas)
  final String actionType;       // 'join' o 'leave'
  final String initiatedBy;      // 'user' (voluntario) o 'admin' (forzado)
  final String actorId;          // ID del usuario que realizó la acción (puede ser el mismo userId o un admin)
  final String? reason;          // Razón opcional de la entrada/salida
  final String? roleInEntity;    // Rol en el grupo/ministerio (member, admin)
  final DateTime timestamp;      // Cuándo ocurrió
  final Map<String, dynamic>? additionalData; // Datos adicionales que puedan ser útiles

  MembershipLog({
    required this.id,
    required this.userId,
    required this.entityId,
    required this.entityType,
    required this.entityName,
    required this.actionType,
    required this.initiatedBy,
    required this.actorId,
    this.reason,
    this.roleInEntity,
    required this.timestamp,
    this.additionalData,
  });

  factory MembershipLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MembershipLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      entityId: data['entityId'] ?? '',
      entityType: data['entityType'] ?? '',
      entityName: data['entityName'] ?? '',
      actionType: data['actionType'] ?? '',
      initiatedBy: data['initiatedBy'] ?? '',
      actorId: data['actorId'] ?? '',
      reason: data['reason'],
      roleInEntity: data['roleInEntity'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'entityId': entityId, 
      'entityType': entityType,
      'entityName': entityName,
      'actionType': actionType,
      'initiatedBy': initiatedBy,
      'actorId': actorId,
      'reason': reason,
      'roleInEntity': roleInEntity,
      'timestamp': Timestamp.fromDate(timestamp),
      'additionalData': additionalData,
    };
  }
  
  /// Crear un registro para una entrada a un grupo/ministerio
  static MembershipLog createJoinLog({
    required String userId,
    required String entityId,
    required String entityType,
    required String entityName,
    required String initiatedBy,
    required String actorId,
    String? reason,
    String? roleInEntity,
    Map<String, dynamic>? additionalData,
  }) {
    return MembershipLog(
      id: '', // Se asignará al guardar
      userId: userId,
      entityId: entityId,
      entityType: entityType,
      entityName: entityName,
      actionType: 'join',
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      roleInEntity: roleInEntity ?? 'member',
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
  }
  
  /// Crear un registro para una salida de un grupo/ministerio
  static MembershipLog createLeaveLog({
    required String userId,
    required String entityId,
    required String entityType,
    required String entityName,
    required String initiatedBy,
    required String actorId,
    String? reason,
    String? roleInEntity,
    Map<String, dynamic>? additionalData,
  }) {
    return MembershipLog(
      id: '', // Se asignará al guardar
      userId: userId,
      entityId: entityId,
      entityType: entityType,
      entityName: entityName,
      actionType: 'leave',
      initiatedBy: initiatedBy,
      actorId: actorId,
      reason: reason,
      roleInEntity: roleInEntity,
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
  }
  
  /// Crear un registro para un cambio de rol en un grupo/ministerio
  static MembershipLog createRoleChangeLog({
    required String userId,
    required String entityId,
    required String entityType,
    required String entityName,
    required String actorId,
    required String newRole,
    String? previousRole,
    String? reason,
    Map<String, dynamic>? additionalData,
  }) {
    final Map<String, dynamic> roleData = {
      'previousRole': previousRole,
      'newRole': newRole,
    };
    
    if (additionalData != null) {
      roleData.addAll(additionalData);
    }
    
    return MembershipLog(
      id: '', // Se asignará al guardar
      userId: userId,
      entityId: entityId,
      entityType: entityType,
      entityName: entityName,
      actionType: 'role_change',
      initiatedBy: 'admin', // Los cambios de rol son siempre por admin
      actorId: actorId,
      reason: reason,
      roleInEntity: newRole,
      timestamp: DateTime.now(),
      additionalData: roleData,
    );
  }
} 