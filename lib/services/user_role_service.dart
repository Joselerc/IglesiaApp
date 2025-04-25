import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Actualizar el rol de un usuario
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      print('Erro ao atualizar papel do usuário: $e');
      rethrow; // Reenviar el error para manejarlo en la UI
    }
  }

  // Verificar si un usuario tiene rol de pastor
  Future<bool> isUserPastor(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data != null && data['role'] == 'pastor';
      }
      return false;
    } catch (e) {
      print('Erro ao verificar papel do usuário: $e');
      return false;
    }
  }

  // Obtener roles disponibles
  List<String> getAvailableRoles() {
    return ['user', 'pastor', 'admin'];
  }
} 