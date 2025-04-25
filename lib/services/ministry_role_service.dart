import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/ministry_role.dart';

class MinistryRoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obtener todos los roles de un ministerio
  Future<List<MinistryRole>> getRolesByMinistry(String ministryId) async {
    try {
      final snapshot = await _firestore
          .collection('ministry_roles')
          .where('ministryId', isEqualTo: ministryId)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MinistryRole.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener roles de ministerio: $e');
      return [];
    }
  }
  
  // Crear un nuevo rol para un ministerio
  Future<MinistryRole?> createRole(String ministryId, String name, {String description = ''}) async {
    try {
      // Verificar si ya existe un rol con el mismo nombre en este ministerio
      final existingRoles = await _firestore
          .collection('ministry_roles')
          .where('ministryId', isEqualTo: ministryId)
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (existingRoles.docs.isNotEmpty) {
        debugPrint('Ya existe un rol con este nombre en el ministerio');
        return MinistryRole.fromFirestore(existingRoles.docs.first);
      }
      
      // Crear nuevo rol
      final roleData = {
        'ministryId': ministryId,
        'name': name,
        'description': description,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await _firestore.collection('ministry_roles').add(roleData);
      final doc = await docRef.get();
      
      return MinistryRole.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error al crear rol de ministerio: $e');
      return null;
    }
  }
  
  // Actualizar un rol existente
  Future<bool> updateRole(String roleId, {String? name, String? description, bool? isActive}) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['isActive'] = isActive;
      
      await _firestore
          .collection('ministry_roles')
          .doc(roleId)
          .update(updateData);
      
      return true;
    } catch (e) {
      debugPrint('Error al actualizar rol de ministerio: $e');
      return false;
    }
  }
  
  // Eliminar un rol (marcándolo como inactivo)
  Future<bool> deleteRole(String roleId) async {
    return await updateRole(roleId, isActive: false);
  }
  
  // Obtener un rol específico por su ID
  Future<MinistryRole?> getRoleById(String roleId) async {
    try {
      final doc = await _firestore
          .collection('ministry_roles')
          .doc(roleId)
          .get();
      
      if (!doc.exists) return null;
      
      return MinistryRole.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error al obtener rol por ID: $e');
      return null;
    }
  }
  
  // Verificar si un rol existe y está activo
  Future<bool> roleExists(String ministryId, String roleName) async {
    try {
      final snapshot = await _firestore
          .collection('ministry_roles')
          .where('ministryId', isEqualTo: ministryId)
          .where('name', isEqualTo: roleName)
          .where('isActive', isEqualTo: true)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar existencia de rol: $e');
      return false;
    }
  }
  
  // Buscar un rol por su nombre o crearlo si no existe
  Future<MinistryRole?> getOrCreateRole(String ministryId, String roleName) async {
    try {
      // Verificar si ya existe un rol con el mismo nombre en este ministerio
      final existingRoles = await _firestore
          .collection('ministry_roles')
          .where('ministryId', isEqualTo: ministryId)
          .where('name', isEqualTo: roleName)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (existingRoles.docs.isNotEmpty) {
        debugPrint('Rol encontrado con nombre "$roleName" en ministerio $ministryId');
        return MinistryRole.fromFirestore(existingRoles.docs.first);
      }
      
      // Si no existe, crear nuevo rol
      debugPrint('Creando nuevo rol "$roleName" en ministerio $ministryId');
      return await createRole(ministryId, roleName);
    } catch (e) {
      debugPrint('Error en getOrCreateRole: $e');
      return null;
    }
  }
} 