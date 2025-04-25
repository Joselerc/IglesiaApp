import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prayer.dart';
import '../models/cult.dart';
import '../models/private_prayer.dart';
import '../models/predefined_message.dart';
import '../services/notification_service.dart';

class PrayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Verifica si un usuario tiene el rol de pastor
  Future<bool> isPastor(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();
      return userData != null && userData['role'] == 'pastor';
    } catch (e) {
      print('Error al verificar rol de pastor: $e');
      return false;
    }
  }
  
  // Obtiene los cultos futuros para mostrar en el modal de asignación
  Future<List<Cult>> getFutureCults() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final snapshot = await _firestore
          .collection('cults')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('date')
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) => Cult.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error al obtener cultos futuros: $e');
      return [];
    }
  }
  
  // Asigna una oración a un culto
  Future<bool> assignPrayerToCult({
    required String prayerId,
    required String cultId,
    required String cultName,
    required String pastorId,
  }) async {
    try {
      // Verificar si el usuario es pastor
      final hasPastorRole = await isPastor(pastorId);
      if (!hasPastorRole) {
        print('Error: El usuario no tiene permisos de pastor');
        return false;
      }
      
      // Verificar si el culto existe
      final cultDoc = await _firestore.collection('cults').doc(cultId).get();
      if (!cultDoc.exists) {
        print('Error: El culto no existe');
        return false;
      }
      
      // Verificar si la oración existe
      final prayerDoc = await _firestore.collection('prayers').doc(prayerId).get();
      if (!prayerDoc.exists) {
        print('Error: La oración no existe');
        return false;
      }
      
      // Obtener referencia al culto y al pastor
      final cultRef = _firestore.collection('cults').doc(cultId);
      final pastorRef = _firestore.collection('users').doc(pastorId);
      
      // Actualizar la oración con la referencia al culto
      await _firestore.collection('prayers').doc(prayerId).update({
        'cultRef': cultRef,
        'assignedToCultAt': FieldValue.serverTimestamp(),
        'assignedToCultBy': pastorRef,
        'cultName': cultName,
      });
      
      return true;
    } catch (e) {
      print('Error al asignar oración a culto: $e');
      return false;
    }
  }
  
  // Desasigna una oración de un culto
  Future<bool> unassignPrayerFromCult({
    required String prayerId,
    required String pastorId,
  }) async {
    try {
      // Verificar si el usuario es pastor
      final hasPastorRole = await isPastor(pastorId);
      if (!hasPastorRole) {
        print('Error: El usuario no tiene permisos de pastor');
        return false;
      }
      
      // Verificar si la oración existe
      final prayerDoc = await _firestore.collection('prayers').doc(prayerId).get();
      if (!prayerDoc.exists) {
        print('Error: La oración no existe');
        return false;
      }
      
      // Actualizar la oración eliminando la referencia al culto
      await _firestore.collection('prayers').doc(prayerId).update({
        'cultRef': FieldValue.delete(),
        'assignedToCultAt': FieldValue.delete(),
        'assignedToCultBy': FieldValue.delete(),
        'cultName': FieldValue.delete(),
      });
      
      return true;
    } catch (e) {
      print('Error al desasignar oración de culto: $e');
      return false;
    }
  }
  
  // Obtiene todas las oraciones asignadas a un culto específico
  Future<List<Prayer>> getPrayersForCult(String cultId) async {
    try {
      final cultRef = _firestore.collection('cults').doc(cultId);
      
      final snapshot = await _firestore
          .collection('prayers')
          .where('cultRef', isEqualTo: cultRef)
          .orderBy('score', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Prayer.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error al obtener oraciones para el culto: $e');
      return [];
    }
  }

  // Obtener oraciones privadas asignadas a un pastor
  Future<List<PrivatePrayer>> getPastorPrivatePrayers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    
    final pastorRef = _firestore.collection('users').doc(currentUser.uid);
    
    // Obtenemos las oraciones que este pastor debe ver:
    // 1. Todas las oraciones pendientes (no aceptadas)
    // 2. Las oraciones que este pastor ha aceptado
    
    // Query para oraciones pendientes (no aceptadas por ningún pastor)
    final pendingQuery = await _firestore
        .collection('private_prayers')
        .where('isAccepted', isEqualTo: false)
        .get();
    
    // Query para oraciones aceptadas o respondidas por este pastor
    final assignedQuery = await _firestore
        .collection('private_prayers')
        .where('acceptedBy', isEqualTo: pastorRef)
        .get();
    
    // Combinar resultados
    final List<DocumentSnapshot> docs = [
      ...pendingQuery.docs,
      ...assignedQuery.docs,
    ];
    
    // Eliminar duplicados si los hay
    final uniqueDocs = <String, DocumentSnapshot>{};
    for (var doc in docs) {
      uniqueDocs[doc.id] = doc;
    }
    
    return uniqueDocs.values
        .map((doc) => PrivatePrayer.fromFirestore(doc))
        .toList();
  }

  // Obtener mensajes predefinidos del pastor
  Future<List<PredefinedMessage>> getPastorPredefinedMessages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final pastorRef = _firestore.collection('users').doc(user.uid);
      
      final snapshot = await _firestore
          .collection('predefined_messages')
          .where('createdBy', isEqualTo: pastorRef)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PredefinedMessage.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error obteniendo mensajes predefinidos: $e');
      return [];
    }
  }

  // Crear un nuevo mensaje predefinido
  Future<bool> createPredefinedMessage(String content) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final pastorRef = _firestore.collection('users').doc(user.uid);
      
      await _firestore.collection('predefined_messages').add({
        'content': content,
        'createdBy': pastorRef,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      return true;
    } catch (e) {
      print('Error creando mensaje predefinido: $e');
      return false;
    }
  }

  // Eliminar un mensaje predefinido
  Future<bool> deletePredefinedMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final messageRef = _firestore.collection('predefined_messages').doc(messageId);
      final messageDoc = await messageRef.get();
      
      if (!messageDoc.exists) return false;
      
      final messageData = messageDoc.data() as Map<String, dynamic>;
      
      // Verificar que el pastor es el dueño del mensaje
      if (messageData['createdBy'].id != user.uid) return false;
      
      await messageRef.update({'isActive': false});
      
      return true;
    } catch (e) {
      print('Error eliminando mensaje predefinido: $e');
      return false;
    }
  }

  // Obtiene estadísticas de oraciones para el pastor
  Future<Map<String, dynamic>> getPastorPrayerStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('Pastor stats: usuario no autenticado');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'responded': 0,
      };
    }
    
    final pastorRef = _firestore.collection('users').doc(currentUser.uid);
    
    try {
      // Contar TODAS las oraciones privadas (total global)
      final totalCount = await _firestore
          .collection('private_prayers')
          .count()
          .get();
      
      // Contar oraciones pendientes (no aceptadas por ningún pastor - global)
      final pendingCount = await _firestore
          .collection('private_prayers')
          .where('isAccepted', isEqualTo: false)
          .count()
          .get();
      
      // Contar oraciones aceptadas por este pastor pero sin responder
      final acceptedCount = await _firestore
          .collection('private_prayers')
          .where('acceptedBy', isEqualTo: pastorRef)
          .where('isAccepted', isEqualTo: true)
          .where('pastorResponse', isNull: true)
          .count()
          .get();
      
      // Contar oraciones respondidas por este pastor
      final respondedCount = await _firestore
          .collection('private_prayers')
          .where('acceptedBy', isEqualTo: pastorRef)
          .where('pastorResponse', isNull: false)
          .count()
          .get();
      
      print('=== ESTADÍSTICAS PRAYER SERVICE ===');
      print('Total: ${totalCount.count}');
      print('Pendientes: ${pendingCount.count}');
      print('Aceptadas por este pastor: ${acceptedCount.count}');
      print('Respondidas por este pastor: ${respondedCount.count}');
      
      // Asegurar que no haya nulls
      final total = totalCount.count ?? 0;
      final pending = pendingCount.count ?? 0;
      final accepted = acceptedCount.count ?? 0;
      final responded = respondedCount.count ?? 0;
      
      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'responded': responded,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'total': 0,
        'pending': 0,
        'accepted': 0,
        'responded': 0,
      };
    }
  }

  // Acepta una oración privada
  Future<bool> acceptPrivatePrayer(String prayerId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final pastorRef = _firestore.collection('users').doc(currentUser.uid);
      
      await _firestore.collection('private_prayers').doc(prayerId).update({
        'isAccepted': true,
        'acceptedBy': pastorRef,
        'pastorId': pastorRef, // Para mantener compatibilidad
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error aceptando oración: $e');
      return false;
    }
  }
  
  // Responde a una oración privada
  Future<bool> respondPrivatePrayer(String prayerId, String response) async {
    try {
      await _firestore.collection('private_prayers').doc(prayerId).update({
        'pastorResponse': response,
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error respondiendo oración: $e');
      return false;
    }
  }
} 