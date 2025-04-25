import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/time_slot.dart';
import '../../../models/ministry_role.dart';
import '../../../services/ministry_role_service.dart';

/// Clase que gestiona las funciones relacionadas con roles para una franja horaria
class RoleManager {
  final TimeSlot timeSlot;
  final BuildContext context;

  RoleManager({
    required this.timeSlot, 
    required this.context,
  });
  
  /// Método para normalizar el ID del ministerio desde diferentes formatos
  String normalizeId(dynamic id) {
    if (id is DocumentReference) {
      return id.id;
    } else if (id is String) {
      // Si es una ruta completa como "/ministries/abc123", extraer solo el ID
      if (id.contains('/')) {
        final parts = id.split('/');
        return parts.last;
      }
      return id;
    }
    return id.toString();
  }

  /// Crea un nuevo rol en una franja horaria
  Future<void> createRole({
    required dynamic ministryId,
    required String ministryName,
    required String roleName,
    required int capacity,
    required bool isTemporary,
    required bool saveAsPredefined,
  }) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final String ministryIdStr = normalizeId(ministryId);
      
      // 1. Si es necesario, guardar el rol en ministry_roles para futura referencia
      String? roleId;
      
      if (!isTemporary && saveAsPredefined) {
        final MinistryRoleService roleService = MinistryRoleService();
        final savedRole = await roleService.createRole(
          ministryIdStr,
          roleName,
        );
        if (savedRole != null) {
          roleId = savedRole.id;
        }
      }
      
      // 2. Guardar el rol disponible para esta franja horaria
      await FirebaseFirestore.instance.collection('available_roles').add({
        'timeSlotId': timeSlot.id,
        'ministryId': ministryId,
        'ministryName': ministryName,
        'role': roleName,
        'roleId': roleId, // Guardar referencia al rol en ministry_roles
        'capacity': capacity,
        'current': 0,
        'isTemporary': isTemporary,
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
      
      // Cerrar el indicador de carga
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol "$roleName" creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar el indicador de carga
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear rol: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Actualiza el contador de roles
  Future<void> updateRoleCounter(
    String roleId, 
    int increment
  ) async {
    try {
      final roleDoc = await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .get();
      
      if (!roleDoc.exists) {
        return;
      }
      
      final roleData = roleDoc.data();
      int currentCount = roleData?['current'] ?? 0;
      int newCount = currentCount + increment;
      
      // Asegurar que no sea negativo
      if (newCount < 0) newCount = 0;
      
      await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .update({'current': newCount});
    } catch (e) {
      debugPrint('Error al actualizar contador de rol: $e');
    }
  }
} 