import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ministry_availability.dart';

class MinistryAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ministry_availability';

  // Obtener la disponibilidad de un usuario en un ministerio
  Stream<MinistryAvailability?> getUserAvailability(String userId, String ministryId) {
    return _firestore
        .collection(_collection)
        .doc('${userId}_${ministryId}')
        .snapshots()
        .map((doc) => doc.exists ? MinistryAvailability.fromFirestore(doc) : null);
  }

  // Guardar o actualizar la disponibilidad de un usuario
  Future<void> saveAvailability(MinistryAvailability availability) async {
    final docId = '${availability.userId}_${availability.ministryId}';
    await _firestore
        .collection(_collection)
        .doc(docId)
        .set(availability.toFirestore());
  }

  // Obtener usuarios disponibles para una franja horaria específica
  Future<List<String>> getAvailableUsers(String ministryId, String day, String timeSlot) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('ministryId', isEqualTo: ministryId)
        .get();

    final availableUsers = <String>[];
    
    for (var doc in querySnapshot.docs) {
      final availability = MinistryAvailability.fromFirestore(doc);
      if (availability.weeklyAvailability[day]?.contains(timeSlot) ?? false) {
        availableUsers.add(availability.userId);
      }
    }

    return availableUsers;
  }

  // Obtener la disponibilidad de todos los usuarios de un ministerio
  Stream<List<MinistryAvailability>> getMinistryAvailabilities(String ministryId) {
    return _firestore
        .collection(_collection)
        .where('ministryId', isEqualTo: ministryId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MinistryAvailability.fromFirestore(doc))
            .toList());
  }

  // Eliminar la disponibilidad de un usuario
  Future<void> deleteAvailability(String userId, String ministryId) async {
    await _firestore
        .collection(_collection)
        .doc('${userId}_${ministryId}')
        .delete();
  }

  // Verificar si un usuario está disponible en un momento específico
  Future<bool> isUserAvailable(String userId, String ministryId, String day, String timeSlot) async {
    final doc = await _firestore
        .collection(_collection)
        .doc('${userId}_${ministryId}')
        .get();

    if (!doc.exists) return false;

    final availability = MinistryAvailability.fromFirestore(doc);
    return availability.weeklyAvailability[day]?.contains(timeSlot) ?? false;
  }
} 