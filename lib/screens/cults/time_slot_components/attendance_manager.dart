import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/time_slot.dart';
import '../../../services/work_schedule_service.dart';

/// Clase que gestiona las funciones de asistencia para una franja horaria
class AttendanceManager {
  final TimeSlot timeSlot;
  final BuildContext context;

  AttendanceManager({
    required this.timeSlot, 
    required this.context,
  });

  /// Confirma la asistencia de un usuario
  Future<void> confirmAttendance(
    String assignmentId, 
    String userId, 
    String userName,
    bool changeAttendee,
  ) async {
    try {
      debugPrint('🔎 DIAGNÓSTICO: Iniciando confirmación de asistencia para usuario $userName (id: $userId)');
      debugPrint('🔎 DIAGNÓSTICO: AssignmentId: $assignmentId, changeAttendee: $changeAttendee');
      
      // Primero obtener la asignación para conseguir el rol
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        debugPrint('❌ DIAGNÓSTICO: La asignación no existe');
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      debugPrint('📋 DIAGNÓSTICO: Datos de asignación completos: ${assignmentData.toString()}');
      
      // Usar 'role' en lugar de 'roleId'
      final String role = assignmentData['role'] as String? ?? '';
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      
      // Obtener ministryId de manera segura
      String ministryId = '';
      final dynamic ministryIdRaw = assignmentData['ministryId'];
      if (ministryIdRaw is DocumentReference) {
        ministryId = ministryIdRaw.id;
      } else if (ministryIdRaw is String) {
        ministryId = ministryIdRaw.contains('/') 
            ? ministryIdRaw.split('/').last 
            : ministryIdRaw;
      } else {
        ministryId = ministryIdRaw.toString();
      }
      
      debugPrint('📝 Confirmando asistencia para: $userName (role: $role, ministryId: $ministryId, wasConfirmed: $wasConfirmed)');
      
      // Actualizar la asignación
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': true,
            'attendedBy': changeAttendee ? null : FirebaseFirestore.instance.collection('users').doc(userId),
            'attendanceConfirmedAt': FieldValue.serverTimestamp(),
            'attendanceConfirmedBy': FirebaseAuth.instance.currentUser?.uid,
            'status': 'confirmed', // Actualizar estado para que se vea en las otras tabs
          });
      
      // Incrementar el contador del rol solo si no estaba confirmado anteriormente
      if (!wasConfirmed && role.isNotEmpty && ministryId.isNotEmpty) {
        debugPrint('⚙️ DIAGNÓSTICO: Procediendo a incrementar contador (wasConfirmed=$wasConfirmed, role=$role, ministryId=$ministryId)');
        
        // Usar el servicio para actualizar el contador con el rol y ministryId
        await WorkScheduleService().updateRoleCounter(
          timeSlot.id, 
          ministryId, 
          role, 
          true // Incrementar
        );
        
        debugPrint('📊 Contador actualizado para rol $role en ministerio $ministryId');
      } else {
        debugPrint('ℹ️ DIAGNÓSTICO: No se incrementó el contador porque wasConfirmed=$wasConfirmed o role/ministryId está vacío');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asistencia de $userName confirmada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al confirmar asistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al confirmar asistencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Desconfirma la asistencia de un usuario
  Future<void> unconfirmAttendance(
    String assignmentId, 
    String userId, 
    String userName,
  ) async {
    try {
      debugPrint('🔎 DIAGNÓSTICO: Iniciando desconfirmación de asistencia para usuario $userName (id: $userId)');
      debugPrint('🔎 DIAGNÓSTICO: AssignmentId: $assignmentId');
      
      // Primero obtener la asignación para conseguir el rol
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        debugPrint('❌ DIAGNÓSTICO: La asignación no existe');
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      debugPrint('📋 DIAGNÓSTICO: Datos de asignación completos: ${assignmentData.toString()}');
      
      // Usar 'role' en lugar de 'roleId'
      final String role = assignmentData['role'] as String? ?? '';
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      
      // Obtener ministryId de manera segura
      String ministryId = '';
      final dynamic ministryIdRaw = assignmentData['ministryId'];
      if (ministryIdRaw is DocumentReference) {
        ministryId = ministryIdRaw.id;
      } else if (ministryIdRaw is String) {
        ministryId = ministryIdRaw.contains('/') 
            ? ministryIdRaw.split('/').last 
            : ministryIdRaw;
      } else {
        ministryId = ministryIdRaw.toString();
      }
      
      debugPrint('📝 Desconfirmando asistencia para: $userName (role: $role, ministryId: $ministryId, wasConfirmed: $wasConfirmed)');
      
      // Actualizar la asignación
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': false,
            'attendedBy': null, // Eliminar la referencia a quien asistió
            'attendanceConfirmedAt': null,
            'status': 'accepted', // Regresar al estado de aceptado
          });
      
      // Decrementar el contador del rol solo si estaba confirmado anteriormente
      if (wasConfirmed && role.isNotEmpty && ministryId.isNotEmpty) {
        debugPrint('⚙️ DIAGNÓSTICO: Procediendo a decrementar contador (wasConfirmed=$wasConfirmed, role=$role, ministryId=$ministryId)');
        
        // Usar el servicio para actualizar el contador con el rol y ministryId
        await WorkScheduleService().updateRoleCounter(
          timeSlot.id, 
          ministryId, 
          role, 
          false // Decrementar
        );
        
        debugPrint('📊 Contador actualizado para rol $role en ministerio $ministryId');
      } else {
        debugPrint('ℹ️ DIAGNÓSTICO: No se decrementó el contador porque wasConfirmed=$wasConfirmed o role/ministryId está vacío');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asistencia de $userName desconfirmada'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al desconfirmar asistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desconfirmar asistencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Cambia el asistente para una asignación
  Future<void> changeAttendee(
    String assignmentId, 
    String newUserId, 
    String newUserName,
  ) async {
    try {
      // Primero obtener la asignación para verificar si ya estaba confirmada
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      
      // Usar 'role' en lugar de 'roleId'
      final String role = assignmentData['role'] as String? ?? '';
      
      // Obtener ministryId de manera segura
      String ministryId = '';
      final dynamic ministryIdRaw = assignmentData['ministryId'];
      if (ministryIdRaw is DocumentReference) {
        ministryId = ministryIdRaw.id;
      } else if (ministryIdRaw is String) {
        ministryId = ministryIdRaw.contains('/') 
            ? ministryIdRaw.split('/').last 
            : ministryIdRaw;
      } else {
        ministryId = ministryIdRaw.toString();
      }
      
      debugPrint('📝 Cambiando asistente a: $newUserName (role: $role, ministryId: $ministryId, wasConfirmed: $wasConfirmed)');
      
      // Actualizar la asignación a confirmada con el nuevo asistente
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': true,
            'attendedBy': FirebaseFirestore.instance.collection('users').doc(newUserId),
            'attendanceConfirmedAt': FieldValue.serverTimestamp(),
            'attendanceConfirmedBy': FirebaseAuth.instance.currentUser?.uid,
            'status': 'confirmed', // Actualizar estado para que se vea en las otras tabs
          });
      
      // Si no estaba confirmada previamente, incrementar el contador del rol
      if (!wasConfirmed && role.isNotEmpty && ministryId.isNotEmpty) {
        debugPrint('⚙️ DIAGNÓSTICO: Procediendo a incrementar contador (wasConfirmed=$wasConfirmed, role=$role, ministryId=$ministryId)');
        
        // Usar el servicio para actualizar el contador con el rol y ministryId
        await WorkScheduleService().updateRoleCounter(
          timeSlot.id, 
          ministryId, 
          role, 
          true // Incrementar
        );
        
        debugPrint('📊 Contador actualizado para rol $role en ministerio $ministryId');
      } else {
        debugPrint('ℹ️ DIAGNÓSTICO: No se incrementó el contador porque wasConfirmed=$wasConfirmed o role/ministryId está vacío');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asistencia cambiada a $newUserName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error al cambiar asistente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar asistente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 