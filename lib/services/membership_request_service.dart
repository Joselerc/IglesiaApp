import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ministry.dart';
import '../models/group.dart';

/// Servicio para gestionar y registrar las solicitudes de membresía a ministerios y grupos
class MembershipRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _requestsCollectionPath = 'membership_requests';

  /// Registra una nueva solicitud para unirse a un ministerio, grupo o familia
  Future<void> logRequest({
    required String userId,
    required String entityId,
    required String entityType, // 'ministry', 'group' o 'family'
    required String entityName,
    String? message,
    String requestType = 'join', // 'join' | 'invite'
    String? desiredRole, // Para Familias
    String? invitedBy, // Cuando la solicitud viene de un admin
    String? invitedByName, // Nombre del admin/invitador
  }) async {
    // Obtener información del usuario solicitante para guardarla
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    
    final requestData = {
      'userId': userId,
      'entityId': entityId,
      'entityType': entityType,
      'entityName': entityName,
      'status': 'pending', // 'pending', 'accepted', 'rejected'
      'requestTimestamp': FieldValue.serverTimestamp(),
      'message': message,
      'requestType': requestType,
      if (desiredRole != null) 'desiredRole': desiredRole,
      if (invitedBy != null) 'invitedBy': invitedBy,
      if (invitedByName != null) 'invitedByName': invitedByName,
      'userName': userData['name'] ?? userData['displayName'] ?? 'Usuario',
      'userEmail': userData['email'] ?? '',
      'userPhotoUrl': userData['photoUrl'] ?? '',
    };
    
    await _firestore.collection(_requestsCollectionPath).add(requestData);
  }

  /// Actualiza el estado de una solicitud cuando es aceptada
  Future<void> markRequestAsAccepted({
    required String requestId,
    required String actorId,
    String? reason,
  }) async {
    final requestDoc = await _firestore.collection(_requestsCollectionPath).doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('La solicitud no existe');
    }
    
    // Actualizar el estado de la solicitud
    await _firestore.collection(_requestsCollectionPath).doc(requestId).update({
      'status': 'accepted',
      'responseTimestamp': FieldValue.serverTimestamp(),
      'respondedBy': actorId,
      'responseReason': reason,
    });
  }

  /// Actualiza el estado de una solicitud cuando es rechazada
  Future<void> markRequestAsRejected({
    required String requestId,
    required String actorId,
    String? reason,
  }) async {
    final requestDoc = await _firestore.collection(_requestsCollectionPath).doc(requestId).get();
    if (!requestDoc.exists) {
      throw Exception('La solicitud no existe');
    }
    
    // Actualizar el estado de la solicitud
    await _firestore.collection(_requestsCollectionPath).doc(requestId).update({
      'status': 'rejected',
      'responseTimestamp': FieldValue.serverTimestamp(),
      'respondedBy': actorId,
      'responseReason': reason,
    });
  }
  
  /// Obtiene todas las solicitudes pendientes para un ministerio o grupo específico
  Stream<QuerySnapshot> getPendingRequests(String entityId, String entityType) {
    return _firestore
        .collection(_requestsCollectionPath)
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestTimestamp', descending: true)
        .snapshots();
  }
  
  /// Obtiene todas las solicitudes (pendientes, aceptadas, rechazadas) para un ministerio o grupo
  Stream<QuerySnapshot> getAllRequests(String entityId, String entityType) {
    return _firestore
        .collection(_requestsCollectionPath)
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType)
        .orderBy('requestTimestamp', descending: true)
        .snapshots();
  }
  
  /// Obtiene las solicitudes de un usuario específico
  Stream<QuerySnapshot> getUserRequests(String userId) {
    return _firestore
        .collection(_requestsCollectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('requestTimestamp', descending: true)
        .snapshots();
  }
  
  /// Busca una solicitud específica por usuario y entidad
  Future<DocumentSnapshot?> findRequest(String userId, String entityId, String entityType) async {
    final requests = await _firestore
        .collection(_requestsCollectionPath)
        .where('userId', isEqualTo: userId)
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType)
        .get();
        
    if (requests.docs.isEmpty) {
      return null;
    }
    
    return requests.docs.first;
  }
  
  /// Obtiene estadísticas sobre las solicitudes para una entidad específica
  Future<Map<String, dynamic>> getRequestStats(String entityId, String entityType) async {
    final requests = await _firestore
        .collection(_requestsCollectionPath)
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType)
        .get();
        
    final totalRequests = requests.docs.length;
    final pendingRequests = requests.docs.where((doc) => doc.data()['status'] == 'pending').length;
    final acceptedRequests = requests.docs.where((doc) => doc.data()['status'] == 'accepted').length;
    final rejectedRequests = requests.docs.where((doc) => doc.data()['status'] == 'rejected').length;
    
    // Calcular tiempo promedio de respuesta para solicitudes aceptadas/rechazadas
    double avgResponseTimeHours = 0;
    int responseTimeCount = 0;
    
    for (final doc in requests.docs) {
      if (doc.data()['status'] == 'accepted' || doc.data()['status'] == 'rejected') {
        if (doc.data()['requestTimestamp'] != null && doc.data()['responseTimestamp'] != null) {
          final requestTime = (doc.data()['requestTimestamp'] as Timestamp).toDate();
          final responseTime = (doc.data()['responseTimestamp'] as Timestamp).toDate();
          final diffHours = responseTime.difference(requestTime).inHours;
          
          avgResponseTimeHours += diffHours;
          responseTimeCount++;
        }
      }
    }
    
    if (responseTimeCount > 0) {
      avgResponseTimeHours /= responseTimeCount;
    }
    
    return {
      'totalRequests': totalRequests,
      'pendingRequests': pendingRequests,
      'acceptedRequests': acceptedRequests,
      'rejectedRequests': rejectedRequests,
      'avgResponseTimeHours': avgResponseTimeHours,
    };
  }
} 
