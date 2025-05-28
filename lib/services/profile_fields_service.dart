import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_field.dart';
import '../models/profile_field_response.dart';

class ProfileFieldsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todos los campos de perfil activos
  Stream<List<ProfileField>> getActiveProfileFields() {
    return _firestore
        .collection('profileFields')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProfileField.fromFirestore(doc))
              .toList();
        });
  }

  // Obtener todos los campos de perfil (para administradores)
  Stream<List<ProfileField>> getAllProfileFields() {
    return _firestore
        .collection('profileFields')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProfileField.fromFirestore(doc))
              .toList();
        });
  }

  // Crear un nuevo campo de perfil
  Future<void> createProfileField(ProfileField field) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Los permisos ya se verifican en la pantalla ProfileFieldsAdminScreen
    // antes de llamar a este método.

    await _firestore.collection('profileFields').add(field.toMap());
  }

  // Actualizar un campo de perfil
  Future<void> updateProfileField(ProfileField field) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Los permisos ya se verifican en la pantalla ProfileFieldsAdminScreen

    await _firestore
        .collection('profileFields')
        .doc(field.id)
        .update(field.toMap());
  }

  // Eliminar un campo de perfil
  Future<void> deleteProfileField(String fieldId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    // Los permisos ya se verifican en la pantalla ProfileFieldsAdminScreen

    await _firestore.collection('profileFields').doc(fieldId).delete();
  }

  // Obtener las respuestas de un usuario
  Stream<List<ProfileFieldResponse>> getUserResponses(String userId) {
    print('Obteniendo respuestas para usuario: $userId');
    return _firestore
        .collection('profileFieldResponses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final responses = snapshot.docs
              .map((doc) => ProfileFieldResponse.fromFirestore(doc))
              .toList();
              
          print('Respuestas encontradas: ${responses.length}');
          for (final response in responses) {
            print('Respuesta: campo=${response.fieldId}, valor=${response.value}');
          }
          
          return responses;
        });
  }

  // Guardar la respuesta de un usuario
  Future<void> saveUserResponse(ProfileFieldResponse response) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    print('Guardando respuesta en el servicio:');
    print('Usuario: ${response.userId}');
    print('Campo: ${response.fieldId}');
    print('Valor: ${response.value} (${response.value.runtimeType})');

    try {
      // Verificar si ya existe una respuesta para este campo
      final querySnapshot = await _firestore
          .collection('profileFieldResponses')
          .where('userId', isEqualTo: response.userId)
          .where('fieldId', isEqualTo: response.fieldId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Actualizar la respuesta existente
        final docId = querySnapshot.docs.first.id;
        print('Actualizando respuesta existente con ID: $docId');
        await _firestore
            .collection('profileFieldResponses')
            .doc(docId)
            .update(response.toMap());
        print('✅ Respuesta actualizada en Firestore: ${response.value}');
      } else {
        // Crear una nueva respuesta
        print('Creando nueva respuesta en Firestore');
        final docRef = await _firestore.collection('profileFieldResponses').add(response.toMap());
        print('✅ Nueva respuesta creada en Firestore con ID: ${docRef.id}, valor: ${response.value}');
      }

      // Actualizar el estado de completado en el perfil del usuario
      await _updateUserCompletionStatus(response.userId);
      return;
    } catch (e) {
      print('❌ Error guardando respuesta en Firestore: $e');
      throw e;
    }
  }

  // Verificar si un usuario ha completado todos los campos requeridos
  Future<bool> hasCompletedRequiredFields(String userId) async {
    print('Verificando campos requeridos para el usuario: $userId');
    
    // Obtener todos los campos requeridos
    final requiredFieldsSnapshot = await _firestore
        .collection('profileFields')
        .where('isActive', isEqualTo: true)
        .where('isRequired', isEqualTo: true)
        .get();

    final requiredFieldIds = requiredFieldsSnapshot.docs.map((doc) => doc.id).toList();
    
    print('Campos requeridos encontrados: ${requiredFieldIds.length}');
    print('IDs de campos requeridos: $requiredFieldIds');
    
    if (requiredFieldIds.isEmpty) {
      print('No hay campos requeridos - usuario considerado como completo');
      return true; // No hay campos requeridos
    }

    // Obtener las respuestas del usuario
    final responsesSnapshot = await _firestore
        .collection('profileFieldResponses')
        .where('userId', isEqualTo: userId)
        .get();

    print('Respuestas encontradas: ${responsesSnapshot.docs.length}');
    
    // Verificar si hay respuestas
    if (responsesSnapshot.docs.isEmpty && requiredFieldIds.isNotEmpty) {
      print('No hay respuestas para campos requeridos - usuario incompleto');
      return false;
    }

    final respondedFieldIds = responsesSnapshot.docs
        .map((doc) {
          final data = doc.data();
          final fieldId = data['fieldId'] as String?;
          final value = data['value'];
          print('Respuesta encontrada - Campo: $fieldId, Valor: $value');
          return fieldId;
        })
        .where((fieldId) => fieldId != null)
        .cast<String>()
        .toList();
    
    print('IDs de campos respondidos: $respondedFieldIds');

    // Verificar si todos los campos requeridos tienen respuesta
    for (final fieldId in requiredFieldIds) {
      if (!respondedFieldIds.contains(fieldId)) {
        print('Campo requerido no respondido: $fieldId');
        return false;
      }
      
      // Verificar que la respuesta no esté vacía
      final response = responsesSnapshot.docs.firstWhere(
        (doc) => doc.data()['fieldId'] == fieldId,
        orElse: () => throw Exception('No se encontró respuesta para el campo $fieldId'),
      );
      
      final value = response.data()['value'];
      if (value == null || (value is String && value.isEmpty)) {
        print('Campo requerido con respuesta vacía: $fieldId');
        return false;
      }
    }

    print('Todos los campos requeridos han sido respondidos correctamente');
    return true;
  }

  // Actualizar el estado de completado en el perfil del usuario
  Future<void> _updateUserCompletionStatus(String userId) async {
    final hasCompleted = await hasCompletedRequiredFields(userId);
    
    print('Actualizando estado de completado del usuario $userId: $hasCompleted');
    
    await _firestore.collection('users').doc(userId).update({
      'hasCompletedAdditionalFields': hasCompleted,
      'additionalFieldsLastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene todos los campos de perfil requeridos
  Future<List<ProfileField>> getRequiredProfileFields() async {
    final snapshot = await _firestore
        .collection('profileFields')
        .where('isActive', isEqualTo: true)
        .where('isRequired', isEqualTo: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ProfileField.fromFirestore(doc))
        .toList();
  }
} 