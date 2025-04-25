// Este archivo contiene correcciones para time_slot_detail_screen.dart
// 
// IMPORTANTE: El archivo time_slot_detail_screen.dart tiene errores estructurales 
// graves que son difíciles de corregir con ediciones parciales.
//
// PROBLEMA:
// 1. Hay un llaves de cierre "}" incorrectas en los métodos _confirmAttendance y _unconfirmAttendance
// 2. Esto causa que los métodos no estén correctamente definidos, provocando errores de compilación
//
// SOLUCIÓN:
// Reemplaza completamente los métodos _confirmAttendance y _unconfirmAttendance en
// church_app_br - cultos/lib/screens/cults/time_slot_detail_screen.dart
// con las versiones que se muestran a continuación.
//
// Método _confirmAttendance corregido:
/*
  // Confirmar asistencia con el usuario original asignado
  Future<void> _confirmAttendance(
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
          widget.timeSlot.id, 
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
*/

// Método _unconfirmAttendance corregido:
/*
  // Desconfirmar una asistencia previamente confirmada
  Future<void> _unconfirmAttendance(
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
          widget.timeSlot.id, 
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
*/

// Método _changeAttendee corregido:
/*
  // Cambiar el asistente
  Future<void> _changeAttendee(
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
          widget.timeSlot.id, 
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
*/

// Consejos de implementación:
// 1. Abre el archivo time_slot_detail_screen.dart
// 2. Busca el método _confirmAttendance existente
// 3. Reemplázalo completamente con la versión corregida
// 4. Busca el método _unconfirmAttendance existente o encuentra un lugar después de _confirmAttendance
// 5. Reemplázalo o agrega la versión corregida
//
// También revisa si el método _changeAttendee tiene problemas similares. 