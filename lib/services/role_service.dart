import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _rolesCollection = FirebaseFirestore.instance.collection('roles'); // Colección para Roles

  // Obtener un stream de todos los roles ordenados por nombre
  Stream<List<Role>> getRoles() {
    return _rolesCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Role.fromFirestore(doc))
            .toList())
        .handleError((error) {
           print("Error al obtener roles: $error");
           return <Role>[];
         });
  }
  
   // Obtener un rol específico por su ID
  Future<Role?> getRoleById(String roleId) async {
    try {
      final doc = await _rolesCollection.doc(roleId).get();
      if (doc.exists) {
        return Role.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print("Error al obtener rol por ID $roleId: $e");
      return null;
    }
  }

  // Obtener el rol por defecto para nuevos usuarios
  Future<String?> getDefaultRoleId() async {
    try {
      // Buscar un rol con nombre 'member' o algo similar
      final querySnapshot = await _rolesCollection
          .where('name', isEqualTo: 'Membro')
          .limit(1)
          .get();
      
      // Si encontramos uno con ese nombre, devolverlo
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      
      // Si no, buscar uno que contenga "membro" o "miembro" (case insensitive)
      final backupQuery = await _rolesCollection
          .orderBy('name')
          .get();
      
      for (var doc in backupQuery.docs) {
        final roleName = (doc.data() as Map<String, dynamic>)['name'] as String? ?? '';
        if (roleName.toLowerCase().contains('membro') || 
            roleName.toLowerCase().contains('miembro') ||
            roleName.toLowerCase().contains('member')) {
          return doc.id;
        }
      }
      
      // Si aún no hay coincidencias, devolver el primer rol (si hay alguno)
      if (backupQuery.docs.isNotEmpty) {
        return backupQuery.docs.first.id;
      }
      
      return null; // No hay roles en la base de datos
    } catch (e) {
      print("Error al obtener rol por defecto: $e");
      return null;
    }
  }

  // Añadir un nuevo rol
  Future<String?> addRole(Role role) async {
    try {
      // Asegurarnos de no incluir el ID al crear, Firestore lo genera
      final data = role.toFirestore(); 
      DocumentReference docRef = await _rolesCollection.add(data);
      return docRef.id;
    } catch (e) {
      print("Error al añadir rol: $e");
      return null;
    }
  }

  // Actualizar un rol existente
  Future<bool> updateRole(Role role) async {
    try {
      final data = role.toFirestore();
      // Añadir o actualizar un timestamp si lo usas
      // data['updatedAt'] = FieldValue.serverTimestamp(); 
      await _rolesCollection.doc(role.id).update(data);
      return true;
    } catch (e) {
      print("Error al actualizar rol ${role.id}: $e");
      return false;
    }
  }

  // Eliminar un rol
  Future<bool> deleteRole(String roleId) async {
    try {
      await _rolesCollection.doc(roleId).delete();
      // IMPORTANTE: Considerar qué hacer con los usuarios que tenían este rol.
      // Podrías necesitar una Cloud Function o lógica adicional para reasignarles
      // un rol por defecto o marcarlos como sin rol.
      return true;
    } catch (e) {
      print("Error al eliminar rol $roleId: $e");
      return false;
    }
  }
} 