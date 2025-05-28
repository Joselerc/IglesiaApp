import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/time_slot.dart';
import '../models/work_assignment.dart';
import '../models/work_invite.dart';
import '../services/notification_service.dart';
import 'dart:math';

class WorkScheduleService {
  static final WorkScheduleService _instance = WorkScheduleService._internal();
  factory WorkScheduleService() => _instance;
  WorkScheduleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // =========== MÉTODOS PARA FRANJAS HORARIAS ===========

  // Crear una nueva franja horaria
  Future<String> createTimeSlot({
    required String entityId,
    required String entityType,
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    String description = '',
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Validar tiempos
      if (startTime.isAfter(endTime)) {
        throw Exception('A hora de início deve ser anterior à hora de término');
      }

      // Crear documento de franja horaria
      final timeSlotData = {
        'entityId': entityId,
        'entityType': entityType,
        'name': name,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'description': description,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'createdBy': _firestore.collection('users').doc(currentUser.uid),
      };

      final docRef = await _firestore.collection('time_slots').add(timeSlotData);
      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao criar faixa horária: $e');
      throw Exception('Erro ao criar faixa horária: $e');
    }
  }

  // Obtener franjas horarias por entidad
  Stream<List<TimeSlot>> getTimeSlotsByEntity(String entityId, String entityType) {
    return _firestore
        .collection('time_slots')
        .where('entityId', isEqualTo: entityId)
        .where('entityType', isEqualTo: entityType)
        .where('isActive', isEqualTo: true)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TimeSlot.fromFirestore(doc))
              .toList();
        });
  }

  // Actualizar una franja horaria
  Future<void> updateTimeSlot(String timeSlotId, {
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['isActive'] = isActive;
      
      if (startTime != null) {
        updateData['startTime'] = Timestamp.fromDate(startTime);
        
        // Si se actualiza la hora de inicio, verificar si hay conflictos con asignaciones
        final assignmentsSnapshot = await _firestore
            .collection('work_assignments')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('isActive', isEqualTo: true)
            .get();
        
        if (assignmentsSnapshot.docs.isNotEmpty) {
          // Actualizar el estado de las asignaciones a 'pending' para que los usuarios vuelvan a confirmar
          for (var doc in assignmentsSnapshot.docs) {
            await _firestore
                .collection('work_assignments')
                .doc(doc.id)
                .update({
                  'status': 'pending',
                });
                
            // Actualizar también la invitación para notificar al usuario
            await _updateWorkInviteAfterTimeChange(doc.id, startTime, endTime);
          }
        }
      }
      
      if (endTime != null) {
        updateData['endTime'] = Timestamp.fromDate(endTime);
      }

      await _firestore
          .collection('time_slots')
          .doc(timeSlotId)
          .update(updateData);
    } catch (e) {
      debugPrint('Erro ao atualizar faixa horária: $e');
      throw Exception('Erro ao atualizar faixa horária: $e');
    }
  }

  // Eliminar una franja horaria (marcar como inactiva)
  Future<void> deleteTimeSlot(String timeSlotId) async {
    try {
      // Marcar la franja horaria como inactiva
      await _firestore
          .collection('time_slots')
          .doc(timeSlotId)
          .update({
            'isActive': false,
          });
      
      // Marcar todas las asignaciones de trabajo asociadas como inactivas
      final assignmentsSnapshot = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('isActive', isEqualTo: true)
          .get();
      
      for (var doc in assignmentsSnapshot.docs) {
        await _firestore
            .collection('work_assignments')
            .doc(doc.id)
            .update({
              'isActive': false,
            });
      }
    } catch (e) {
      debugPrint('Erro ao excluir faixa horária: $e');
      throw Exception('Erro ao excluir faixa horária: $e');
    }
  }

  // =========== MÉTODOS PARA ASIGNACIONES DE TRABAJO ===========

  // Crear una nueva asignación de trabajo
  Future<String> createWorkAssignment({
    required String timeSlotId,
    required dynamic ministryId,
    required String userId,
    required String role,
    int capacity = 1,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verificar que la franja horaria existe y está activa
      final timeSlotDoc = await _firestore
          .collection('time_slots')
          .doc(timeSlotId)
          .get();
          
      if (!timeSlotDoc.exists) {
        throw Exception('A faixa horária não existe');
      }
      
      final timeSlotData = timeSlotDoc.data()!;
      if (timeSlotData['isActive'] == false) {
        throw Exception('A faixa horária não está ativa');
      }
      
      // Normalizar el ministryId a un string
      final String ministryIdStr = _normalizeId(ministryId);
      // Crear la referencia al ministerio
      final ministryRef = _firestore.collection('ministries').doc(ministryIdStr);
      
      debugPrint('Criando atribuição para timeSlotId: $timeSlotId, ministryId: $ministryIdStr, userId: $userId, role: $role');

      // Usar una transacción para evitar condiciones de carrera
      return await _firestore.runTransaction<String>(
        (transaction) async {
          // 1. Buscar todas las asignaciones existentes para este usuario en esta franja horaria
          final userRef = _firestore.collection('users').doc(userId);
      final existingAssignmentSnapshot = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
              .where('userId', isEqualTo: userRef)
          .get();
          
          debugPrint('⚙️ Encontradas ${existingAssignmentSnapshot.docs.length} atribuições para este usuário');
          
          // 2. Encontrar si hay asignaciones activas no rechazadas PARA EL MISMO MINISTERIO
          bool hasActiveAssignment = false;
          DocumentSnapshot? rejectedAssignment;
          
          for (var doc in existingAssignmentSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            final isActive = data['isActive'] as bool? ?? false;
            final docRole = data['role'] as String? ?? '';
            
            // Extraer ministryId del documento actual
            final docMinistryId = _normalizeId(data['ministryId']);
            
            // Solo considerar como asignación activa si es el mismo ministerio y rol
            if (isActive && status != 'rejected' && docRole == role && docMinistryId == ministryIdStr) {
              hasActiveAssignment = true;
              debugPrint('⚠️ Já existe uma atribuição ativa não rejeitada para este ministério e função: ${doc.id} com status $status');
              break;
            }
            
            // Guardar referencia a asignación rechazada si existe (mismo ministerio y rol)
            if (isActive && status == 'rejected' && docRole == role && docMinistryId == ministryIdStr) {
                rejectedAssignment = doc;
                debugPrint('✅ Encontrada atribuição rejeitada para reativar: ${doc.id}');
            }
          }
          
          // 3. Buscar invitaciones rechazadas
          final invitesSnapshot = await _firestore
              .collection('work_invites')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .where('userId', isEqualTo: userRef)
              .get();
          
          DocumentSnapshot? rejectedInvite;
          
          for (var doc in invitesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Verificar si la invitación está rechazada
            final bool isRejected = data['isRejected'] == true || data['status'] == 'rejected';
            
            // Solo procesar invitaciones rechazadas
            if (!isRejected) continue;
            
            // Extraer ministryId de la invitación
            final docMinistryId = _normalizeId(data['ministryId']);
            final docRole = data['role'] as String? ?? '';
            
            // Verificar que coincida el ministerio y el rol
            if (docMinistryId == ministryIdStr && docRole == role) {
              rejectedInvite = doc;
              debugPrint('✅ Encontrado convite rejeitado para reativar: ${doc.id}');
              break;
            }
          }
          
          if (hasActiveAssignment) {
            throw Exception('Já existe uma atribuição ativa para este usuário nesta função');
          }
          
          // 4. CASO: Hay una asignación rechazada para reactivar
          if (rejectedAssignment != null) {
            debugPrint('🔄 Reativando atribuição rejeitada: ${rejectedAssignment.id}');
            
            transaction.update(rejectedAssignment.reference, {
              'status': 'pending',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            // Si también hay una invitación rechazada, reactivarla
            if (rejectedInvite != null) {
              debugPrint('🔄 Reativando convite rejeitado: ${rejectedInvite.id}');
              
              transaction.update(rejectedInvite.reference, {
                'status': 'pending',
                'isRejected': false,
                'isVisible': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              // Crear nueva invitación si no se encontró una rechazada
              final startTime = (timeSlotData['startTime'] as Timestamp).toDate();
              final endTime = (timeSlotData['endTime'] as Timestamp).toDate();
              final cultId = timeSlotData['entityId'];
              
              // Obtener info del ministerio
              final ministryDoc = await _firestore.collection('ministries').doc(ministryIdStr).get();
              String ministryName = 'Ministério';
              if (ministryDoc.exists) {
                ministryName = ministryDoc.data()!['name'] ?? 'Ministério';
              }
              
              final inviteData = {
                'assignmentId': rejectedAssignment.id,
                'timeSlotId': timeSlotId,
                'entityId': cultId,
                'entityType': 'cult',
                'userId': userRef,
                'ministryId': _firestore.collection('ministries').doc(ministryIdStr),
                'ministryName': ministryName,
                'role': role,
                'status': 'pending',
                'isRead': false,
                'isActive': true,
                'isVisible': true,
                'startTime': Timestamp.fromDate(startTime),
                'endTime': Timestamp.fromDate(endTime),
                'createdAt': FieldValue.serverTimestamp(),
                'sentBy': _firestore.collection('users').doc(currentUser.uid),
              };
              
              final inviteRef = _firestore.collection('work_invites').doc();
              transaction.set(inviteRef, inviteData);
            }
            
            // Enviar notificación
            // (No podemos enviar notificación dentro de una transacción, lo haremos después)
            
            return rejectedAssignment.id;
          }
          
          // 5. CASO: No hay asignación rechazada, pero sí invitación
          else if (rejectedInvite != null) {
            debugPrint('🔄 Reativando apenas o convite rejeitado: ${rejectedInvite.id}');
            
            // Reactivar la invitación
            transaction.update(rejectedInvite.reference, {
              'status': 'pending',
              'isRejected': false,
              'isVisible': true,
              'updatedAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'isRead': false,
              'respondedAt': null,
            });
            
            // Crear nueva asignación
      final assignmentData = {
        'timeSlotId': timeSlotId,
        'ministryId': _firestore.collection('ministries').doc(ministryIdStr),
              'userId': userRef,
        'role': role,
        'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
        'invitedBy': _firestore.collection('users').doc(currentUser.uid),
        'isActive': true,
      };
      
      if (notes != null) {
        assignmentData['notes'] = notes;
      }
      
            final assignmentRef = _firestore.collection('work_assignments').doc();
            transaction.set(assignmentRef, assignmentData);
            
            // Actualizar el ID de asignación en la invitación
            transaction.update(rejectedInvite.reference, {
              'assignmentId': assignmentRef.id,
            });
            
            return assignmentRef.id;
          }
          
          // 6. CASO: No hay nada que reactivar, crear todo nuevo
          else {
            debugPrint('🆕 Criando nova atribuição e convite');
            
            // Verificar si el rol está lleno
            final bool isFull = await isRoleFull(timeSlotId, ministryIdStr, role);
            
            // Crear asignación
            final assignmentData = {
              'timeSlotId': timeSlotId,
              'ministryId': _firestore.collection('ministries').doc(ministryIdStr),
              'userId': userRef,
              'role': role,
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
              'invitedBy': _firestore.collection('users').doc(currentUser.uid),
              'isActive': true,
              'isConfirmed': false,
            };
            
            if (notes != null) {
              assignmentData['notes'] = notes;
            }
            
            final assignmentRef = _firestore.collection('work_assignments').doc();
            transaction.set(assignmentRef, assignmentData);
            
            // Crear invitación
      final startTime = (timeSlotData['startTime'] as Timestamp).toDate();
      final endTime = (timeSlotData['endTime'] as Timestamp).toDate();
            final cultId = timeSlotData['entityId'];
            
            // Obtener info del ministerio
            final ministryDoc = await _firestore.collection('ministries').doc(ministryIdStr).get();
            String ministryName = 'Ministério';
            if (ministryDoc.exists) {
              ministryName = ministryDoc.data()!['name'] ?? 'Ministério';
            }
            
      final inviteData = {
              'assignmentId': assignmentRef.id,
              'timeSlotId': timeSlotId,
        'entityId': cultId,
        'entityType': 'cult',
              'userId': userRef,
        'ministryId': _firestore.collection('ministries').doc(ministryIdStr),
        'ministryName': ministryName,
        'role': role,
        'status': 'pending',
        'isRead': false,
        'isActive': true,
              'isVisible': !isFull,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
              'createdAt': FieldValue.serverTimestamp(),
        'sentBy': _firestore.collection('users').doc(currentUser.uid),
      };
      
            final inviteRef = _firestore.collection('work_invites').doc();
            transaction.set(inviteRef, inviteData);
            
            return assignmentRef.id;
          }
        },
        timeout: const Duration(seconds: 30),
      ).then((assignmentId) async {
        // Enviar notificación fuera de la transacción
      await _notificationService.sendNotification(
        userId: userId,
          title: 'Novo convite de serviço',
          body: 'Você foi convidado para servir como $role',
        data: {
            'assignmentId': assignmentId,
          'status': 'pending',
        },
      );
      
        return assignmentId;
      });
    } catch (e) {
      debugPrint('Erro ao criar atribuição de trabalho: $e');
      rethrow;
    }
  }

  // Método privado para crear la invitación de trabajo
  Future<void> _createWorkInviteForAssignment(
    String assignmentId, 
    String userId, 
    DocumentSnapshot timeSlotDoc,
    String ministryId,
    String role
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      final timeSlotData = timeSlotDoc.data() as Map<String, dynamic>;
      final entityId = timeSlotData['entityId'] as String;
      final entityType = timeSlotData['entityType'] as String;
      
      // Obtener información adicional según el tipo de entidad
      String entityName = '';
      DateTime date = (timeSlotData['startTime'] as Timestamp).toDate();
      
      if (entityType == 'cult') {
        final cultDoc = await _firestore.collection('cults').doc(entityId).get();
        if (cultDoc.exists) {
          final cultData = cultDoc.data() as Map<String, dynamic>;
          entityName = cultData['name'] as String;
          date = (cultData['date'] as Timestamp).toDate();
        }
      } else if (entityType == 'event') {
        final eventDoc = await _firestore.collection('events').doc(entityId).get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          entityName = eventData['title'] as String;
          date = (eventData['date'] as Timestamp).toDate();
        }
      }
      
      // Obtener información del ministerio
      String ministryName = '';
      final ministryDoc = await _firestore.collection('ministries').doc(ministryId).get();
      if (ministryDoc.exists) {
        final ministryData = ministryDoc.data() as Map<String, dynamic>;
        ministryName = ministryData['name'] as String;
      }
      
      // Crear la invitación
      final inviteData = {
        'assignmentId': assignmentId,
        'userId': _firestore.collection('users').doc(userId),
        'entityId': entityId,
        'entityType': entityType,
        'entityName': entityName,
        'date': Timestamp.fromDate(date),
        'startTime': timeSlotData['startTime'],
        'endTime': timeSlotData['endTime'],
        'ministryId': _firestore.collection('ministries').doc(ministryId),
        'ministryName': ministryName,
        'role': role,
        'status': 'pending',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'sentBy': _firestore.collection('users').doc(currentUser.uid),
      };
      
      await _firestore.collection('work_invites').add(inviteData);
      
      // Enviar notificación al usuario
      await _notificationService.sendNotification(
        userId: userId,
        title: 'Novo convite de trabalho',
        body: 'Você foi convidado para participar em $entityName como $role',
        data: {
          'entityId': entityId,
          'entityType': entityType,
        },
      );
    } catch (e) {
      debugPrint('Erro ao criar convite de trabalho: $e');
    }
  }

  // Método privado para actualizar invitaciones después de cambios en los horarios
  Future<void> _updateWorkInviteAfterTimeChange(
    String assignmentId, 
    DateTime? newStartTime,
    DateTime? newEndTime
  ) async {
    try {
      // Buscar invitaciones existentes para esta asignación
      final invitesSnapshot = await _firestore
          .collection('work_invites')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('status', isEqualTo: 'pending')
          .get();
          
      for (var doc in invitesSnapshot.docs) {
        final updateData = <String, dynamic>{
          'status': 'pending', // Volver a poner en pendiente
          'isRead': false, // Marcar como no leída para que aparezca como nueva
        };
        
        if (newStartTime != null) {
          updateData['startTime'] = Timestamp.fromDate(newStartTime);
        }
        
        if (newEndTime != null) {
          updateData['endTime'] = Timestamp.fromDate(newEndTime);
        }
        
        await _firestore
            .collection('work_invites')
            .doc(doc.id)
            .update(updateData);
            
        // Enviar notificación sobre el cambio
        final inviteData = doc.data();
        final userId = inviteData['userId'].id;
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Alterações no convite de trabalho',
          body: 'O horário do seu trabalho foi modificado. Por favor, confirme novamente sua disponibilidade.',
          data: {
            'inviteId': doc.id,
          },
        );
      }
    } catch (e) {
      debugPrint('Erro ao atualizar convite de trabalho: $e');
    }
  }

  // Obtener asignaciones por franja horaria
  Stream<List<WorkAssignment>> getAssignmentsByTimeSlot(String timeSlotId) {
    return _firestore
        .collection('work_assignments')
        .where('timeSlotId', isEqualTo: timeSlotId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkAssignment.fromFirestore(doc))
              .toList();
        });
  }

  // Obtener todas las asignaciones de un usuario
  Stream<List<WorkAssignment>> getUserAssignments(String userId) {
    return _firestore
        .collection('work_assignments')
        .where('userId', isEqualTo: _firestore.collection('users').doc(userId))
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkAssignment.fromFirestore(doc))
              .toList();
        });
  }

  // Actualizar el estado de una asignación
  Future<void> updateAssignmentStatus(String invitationId, String status) async {
    try {
      debugPrint('Atualizando status do convite $invitationId para $status');
      
      // Obtener la invitación
      final inviteDoc = await _firestore.collection('work_invites').doc(invitationId).get();
      
      if (!inviteDoc.exists) {
        debugPrint('Erro: convite não encontrado');
        return;
      }
      
      final inviteData = inviteDoc.data()!;
      final String timeSlotId = inviteData['timeSlotId'];
      final ministryId = inviteData['ministryId'];
      final String role = inviteData['role'];
      
      // Manejar userId correctamente - puede ser una referencia o un string
      final userIdValue = inviteData['userId'];
      DocumentReference userRef;
      String userIdString;
      
      if (userIdValue is DocumentReference) {
        userRef = userIdValue;
        userIdString = userIdValue.id;
      } else if (userIdValue is String) {
        userIdString = userIdValue;
        userRef = _firestore.collection('users').doc(userIdValue);
      } else {
        // Caso de fallback por si es un mapa o algún otro tipo
        debugPrint('⚠️ userId tem um formato inesperado: ${userIdValue.runtimeType}');
        userIdString = userIdValue.toString();
        userRef = _firestore.collection('users').doc(userIdString);
      }
      
      debugPrint('📋 Processando convite: userId=$userIdString, timeSlotId=$timeSlotId, role=$role');
      
      // Obtener ID ministryId como string (puede ser referencia o string directo)
      String ministryIdString;
      DocumentReference ministryRef;
      
      if (ministryId is DocumentReference) {
        ministryRef = ministryId;
        ministryIdString = ministryId.id;
      } else if (ministryId is String) {
        ministryIdString = ministryId;
        ministryRef = _firestore.collection('ministries').doc(ministryId);
      } else {
        // Suponemos que es un mapa con ruta o algún otro formato
        debugPrint('⚠️ ministryId tem um formato inesperado: ${ministryId.runtimeType}');
        ministryIdString = ministryId.toString().contains('/') ? 
                           ministryId.toString().split('/').last :
                           ministryId.toString();
        ministryRef = _firestore.collection('ministries').doc(ministryIdString);
      }
      
      // Obtener el estado anterior para comparar
      final String previousStatus = inviteData['status'] ?? 'pending';
      
      // Preparar los datos a actualizar
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'respondedAt': FieldValue.serverTimestamp(),
      };
      
      if (status == 'accepted') {
        // Si es aceptada, ocultar para el usuario pero mantener activa en el sistema
        updateData['isVisible'] = false;
        updateData['isActive'] = true;
        // Asegurarse de que no está marcada como rechazada
        updateData['isRejected'] = false;
      } else if (status == 'rejected') {
        // Si es rechazada, mantenerla activa para el sistema pero invisible para el usuario
        updateData['isActive'] = true;      // Mantener activa para poder mostrarla al administrador
        updateData['isVisible'] = false;    // Ocultar para el usuario, ya que la rechazó
        updateData['isRejected'] = true;    // Marcar explícitamente como rechazada
        
        // Registrar en logs para depuración
        debugPrint('🚫 Marcando convite como rejeitado: isRejected=true, status=rejected, isVisible=false');
      }
      
      // Actualizar el estado de la invitación
      await _firestore.collection('work_invites').doc(invitationId).update(updateData);
      
      debugPrint('✅ Status do convite atualizado corretamente para $status');
      
      // Si se acepta, actualizar la asignación existente (en lugar de crear una nueva)
      if (status == 'accepted') {
        // Verificar si existe una asignación asociada a esta invitación
        final String? assignmentId = inviteData['assignmentId'];
        
        if (assignmentId != null && assignmentId.isNotEmpty) {
          // Actualizar la asignación existente
          await _firestore.collection('work_assignments').doc(assignmentId).update({
            'status': 'accepted',
            'updatedAt': FieldValue.serverTimestamp(),
            'respondedAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'isConfirmed': false,
          });
          
          debugPrint('✅ Atribuição existente atualizada para aceita: $assignmentId');
        } else {
          // Si no existe, crear una nueva (caso raro, pero por si acaso)
        final newAssignmentRef = await _firestore.collection('work_assignments').add({
          'userId': userRef,
          'timeSlotId': timeSlotId,
          'ministryId': ministryRef,
          'role': role,
          'status': 'accepted',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
            'isConfirmed': false,
        });
        
          debugPrint('✅ Nova atribuição criada: ${newAssignmentRef.id}');
        }
        
        // Incrementar contador de rol solo si antes no estaba aceptada
        if (previousStatus != 'accepted') {
        await updateRoleCounter(timeSlotId, ministryIdString, role, true);
        }
        
        // Verificar si el rol está lleno después de esta aceptación
        bool isFull = await isRoleFull(timeSlotId, ministryIdString, role);
        
        if (isFull) {
          debugPrint('🔄 A função $role está cheia. Ocultando convites pendentes...');
          
          // Ocultar todas las invitaciones pendientes para este rol
          final pendingInvites = await _firestore
              .collection('work_invites')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .where('ministryId', isEqualTo: ministryRef)
              .where('role', isEqualTo: role)
              .where('status', isEqualTo: 'pending')
              .where('isActive', isEqualTo: true)
              .get();
          
          final batch = _firestore.batch();
          for (var doc in pendingInvites.docs) {
            if (doc.id != invitationId) { // No afectar la que acabamos de actualizar
              batch.update(doc.reference, {
                'isVisible': false,
                'status': 'cancelled',
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
          
          await batch.commit();
          debugPrint('✅ ${pendingInvites.docs.length - 1} convites pendentes foram ocultados');
        }
      } else if (status == 'rejected') {
        // Verificar si existe una asignación asociada a esta invitación
        final String? assignmentId = inviteData['assignmentId'];
        
        // Si la invitación estaba previamente aceptada, actualizar el contador
        if (previousStatus == 'accepted') {
          debugPrint('🔻 Convite alterado de aceito para rejeitado, atualizando contador');
          await updateRoleCounter(timeSlotId, ministryIdString, role, false);
        }
        
        if (assignmentId != null && assignmentId.isNotEmpty) {
          debugPrint('🔍 Verificando atribuição associada: $assignmentId');
          
          // Actualizar la asignación existente a rechazada
          final assignmentDoc = await _firestore.collection('work_assignments').doc(assignmentId).get();
          
          if (assignmentDoc.exists) {
            await _firestore.collection('work_assignments').doc(assignmentId).update({
              'status': 'rejected',
              'updatedAt': FieldValue.serverTimestamp(),
              'isActive': false,  // Marcar como inactiva para que no aparezca en las listas
            });
            
            debugPrint('✅ Atribuição marcada como rejeitada: $assignmentId');
          } else {
            debugPrint('⚠️ Não foi encontrada a atribuição associada: $assignmentId');
          }
        }
      }
      
      debugPrint('✅ Processo de atualização de convite completado com sucesso');
    } catch (e) {
      debugPrint('Erro ao atualizar status do convite: $e');
      throw Exception('Erro ao atualizar status do convite: $e');
    }
  }

  // =========== MÉTODOS PARA INVITACIONES DE TRABAJO ===========

  // Obtener invitaciones para un usuario
  Stream<List<WorkInvite>> getUserInvites(String userId) {
    return _firestore
        .collection('work_invites')
        .where('userId', isEqualTo: _firestore.collection('users').doc(userId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WorkInvite.fromFirestore(doc))
              .toList();
        });
  }

  // Marcar una invitación como leída
  Future<void> markInviteAsRead(String inviteId) async {
    try {
      await _firestore
          .collection('work_invites')
          .doc(inviteId)
          .update({
            'isRead': true,
          });
    } catch (e) {
      debugPrint('Erro ao marcar convite como lido: $e');
      rethrow;
    }
  }

  // Responder a una invitación
  Future<void> respondToInvite(String inviteId, String status) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Obtener la invitación
      final inviteDoc = await _firestore
          .collection('work_invites')
          .doc(inviteId)
          .get();
          
      if (!inviteDoc.exists) {
        throw Exception('O convite não existe');
      }
      
      final inviteData = inviteDoc.data()!;
      final inviteUserId = inviteData['userId'].id;
      
      if (inviteUserId != currentUser.uid) {
        throw Exception('Você não tem permissão para responder a este convite');
      }
      
      // Actualizar la invitación
      await _firestore
          .collection('work_invites')
          .doc(inviteId)
          .update({
            'status': status,
            'isRead': true,
            'respondedAt': Timestamp.fromDate(DateTime.now()),
          });
          
      // Actualizar también la asignación correspondiente
      final assignmentId = inviteData['assignmentId'];
      await _firestore
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'status': status,
            'respondedAt': Timestamp.fromDate(DateTime.now()),
          });
          
      // Notificar al creador de la invitación
      final sentById = inviteData['sentBy'].id;
      await _notificationService.sendNotification(
        userId: sentById,
        title: 'Respuesta a invitación',
        body: 'Un usuario ha ${status == 'accepted' ? 'aceptado' : 'rechazado'} tu invitación de trabajo',
        data: {
          'inviteId': inviteId,
          'status': status,
        },
      );
    } catch (e) {
      debugPrint('Error al responder a invitación: $e');
              throw Exception('Erro ao responder ao convite: $e');
    }
  }

  // =========== MÉTODOS PARA DUPLICAR CULTOS Y FRANJAS HORARIAS ===========
  
  // Duplicar un culto con sus franjas horarias y asignaciones
  Future<String> duplicateCult({
    required String sourceCultId,
    required String newCultId,
    required DateTime newCultDate,
    Map<String, bool>? options,
    Map<String, dynamic>? additionalOptions,
  }) async {
    try {
      debugPrint('Iniciando duplicação do culto: $sourceCultId para o novo culto: $newCultId');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Valores predeterminados para las opciones si no se proporcionan
      final duplicateOptions = options ?? {
        'duplicateAnnouncements': true,
        'duplicateSongs': true,
        'duplicateTimeSlots': true,
        'duplicateMinistries': true,
        'duplicateUsers': true,
      };
      
      // Valores adicionales con defaults
      final addOptions = additionalOptions ?? {};
      final int announcementDaysInAdvance = addOptions['announcementDaysInAdvance'] ?? 7;
      
      debugPrint('Opções de duplicação: $duplicateOptions');
      debugPrint('Opções adicionais: $addOptions');
      
      // Duplicar anuncios si está habilitado
      if (duplicateOptions['duplicateAnnouncements'] == true) {
        await _duplicateAnnouncements(
          sourceCultId, 
          newCultId, 
          newCultDate, 
          announcementDaysInAdvance
        );
      }
      
      // Duplicar canciones si está habilitado
      if (duplicateOptions['duplicateSongs'] == true) {
        await _duplicateSongs(sourceCultId, newCultId);
      }
      
      // Verificar si debemos duplicar las franjas horarias
      if (duplicateOptions['duplicateTimeSlots'] != true) {
        debugPrint('As faixas horárias não serão duplicadas conforme as opções selecionadas');
        return newCultId;
      }
      
      // Obtener todas las franjas horarias del culto original
      debugPrint('Buscando faixas horárias do culto original: $sourceCultId');
      final timeSlotsSnapshot = await _firestore
          .collection('time_slots')
          .where('entityId', isEqualTo: sourceCultId)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Encontradas ${timeSlotsSnapshot.docs.length} faixas horárias para duplicar');
      
      // Mapeo de IDs de franjas horarias antiguos a nuevos
      Map<String, String> timeSlotIdMap = {};
      
      // Duplicar cada franja horaria
      for (final doc in timeSlotsSnapshot.docs) {
        final data = doc.data();
        
        // Calcular nuevas horas de inicio y fin basadas en la fecha del nuevo culto
        DateTime originalStart = data['startTime'].toDate();
        DateTime originalEnd = data['endTime'].toDate();
        
        // Mantener la misma hora pero usar la nueva fecha
        DateTime newStartTime = DateTime(
          newCultDate.year,
          newCultDate.month,
          newCultDate.day,
          originalStart.hour,
          originalStart.minute,
        );
        
        DateTime newEndTime = DateTime(
          newCultDate.year,
          newCultDate.month,
          newCultDate.day,
          originalEnd.hour,
          originalEnd.minute,
        );
        
        // Crear nueva franja horaria
        final newTimeSlotData = {
          'entityId': newCultId,
          'entityType': 'cult',
          'name': data['name'],
          'startTime': Timestamp.fromDate(newStartTime),
          'endTime': Timestamp.fromDate(newEndTime),
          'description': data['description'],
          'isActive': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'createdBy': _firestore.collection('users').doc(currentUser.uid),
        };
        
        debugPrint('Dados da nova faixa horária: $newTimeSlotData');
        final newTimeSlotRef = await _firestore.collection('time_slots').add(newTimeSlotData);
        debugPrint('Nova faixa horária criada com ID: ${newTimeSlotRef.id}');
        
        // Guardar mapeo de ID antiguo a nuevo
        timeSlotIdMap[doc.id] = newTimeSlotRef.id;
        
        // Obtener asignaciones para esta franja horaria si está habilitada la opción
        if (duplicateOptions['duplicateMinistries'] == true) {
          debugPrint('Duplicando ministérios e funções para a faixa horária ${doc.id} -> ${newTimeSlotRef.id}');
          
          // Primero duplicar los roles disponibles (ministerios y roles específicos)
          await _duplicateAvailableRoles(
            sourceTimeSlotId: doc.id,
            newTimeSlotId: newTimeSlotRef.id
          );
          
          // Luego duplicar las asignaciones de personas
        await _duplicateAssignmentsForTimeSlot(
          sourceTimeSlotId: doc.id,
          newTimeSlotId: newTimeSlotRef.id,
          newCultDate: newCultDate,
            duplicateUsers: duplicateOptions['duplicateUsers'] == true,
        );
        }
      }
      
      debugPrint('Duplicação do culto completada com sucesso');
      return newCultId;
    } catch (e) {
      debugPrint('Erro ao duplicar culto: $e');
      rethrow;
    }
  }
  
  // Duplicar roles disponibles de una franja horaria (ministerios y roles específicos)
  Future<void> _duplicateAvailableRoles({
    required String sourceTimeSlotId,
    required String newTimeSlotId,
  }) async {
    try {
      debugPrint('Iniciando duplicação de funções disponíveis. SourceTimeSlot: $sourceTimeSlotId -> NewTimeSlot: $newTimeSlotId');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Obtener todos los roles disponibles de la franja horaria original
      debugPrint('Buscando roles disponibles para la franja original');
      final rolesSnapshot = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: sourceTimeSlotId)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Encontrados ${rolesSnapshot.docs.length} roles disponibles para duplicar');
      
      // Crear nuevos roles disponibles para la nueva franja horaria
      for (final doc in rolesSnapshot.docs) {
        final data = doc.data();
        debugPrint('Procesando rol disponible: ${doc.id}');
        
        // Preparar datos para el nuevo rol disponible
        final newRoleData = Map<String, dynamic>.from(data);
        
        // Actualizar campos específicos
        newRoleData['timeSlotId'] = newTimeSlotId;
        newRoleData['createdAt'] = Timestamp.fromDate(DateTime.now());
        newRoleData['createdBy'] = _firestore.collection('users').doc(currentUser.uid);
        
        // Asegurar que current sea 0 en el nuevo rol
        newRoleData['current'] = 0;
        
        // Crear el nuevo rol disponible
        final newRoleRef = await _firestore.collection('available_roles').add(newRoleData);
        debugPrint('Nuevo rol disponible creado con ID: ${newRoleRef.id}');
      }
      
      debugPrint('Duplicación de roles disponibles completada exitosamente');
    } catch (e) {
      debugPrint('Error al duplicar roles disponibles: $e');
      rethrow;
    }
  }
  
  // Duplicar asignaciones de una franja horaria
  Future<void> _duplicateAssignmentsForTimeSlot({
    required String sourceTimeSlotId,
    required String newTimeSlotId,
    required DateTime newCultDate,
    required bool duplicateUsers,
  }) async {
    try {
      debugPrint('Iniciando duplicación de asignaciones. SourceTimeSlot: $sourceTimeSlotId -> NewTimeSlot: $newTimeSlotId');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Obtener todas las asignaciones de la franja horaria original
      debugPrint('Buscando asignaciones para la franja original');
      final assignmentsSnapshot = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: sourceTimeSlotId)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Encontradas ${assignmentsSnapshot.docs.length} asignaciones para duplicar');
      
      // Crear nuevas asignaciones para la nueva franja horaria
      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        debugPrint('Procesando asignación: ${doc.id}');
        
        // Solo duplicar asignaciones aceptadas
        if (data['status'] == 'accepted') {
          // Preparar datos para la nueva asignación
          debugPrint('Duplicando asignación aceptada: ${doc.id}');
          
          // Verificar el tipo de userId y ministryId
          var userId = data['userId'];
          var ministryId = data['ministryId'];
          
          if (userId != null) {
            debugPrint('userId es de tipo: ${userId.runtimeType}');
          } else {
            debugPrint('userId es null');
          }
          
          if (ministryId != null) {
            debugPrint('ministryId es de tipo: ${ministryId.runtimeType}');
          } else {
            debugPrint('ministryId es null');
          }
          
          final newAssignmentData = {
            'timeSlotId': newTimeSlotId,
            'ministryId': data['ministryId'],
            'userId': duplicateUsers ? data['userId'] : null,
            'role': data['role'],
            'status': duplicateUsers ? 'pending' : 'vacant', // Si no duplicamos usuarios, marcarlo como vacante
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'invitedBy': _firestore.collection('users').doc(currentUser.uid),
            'isActive': true,
            'isConfirmed': false,
          };
          
          debugPrint('Datos de nueva asignación: $newAssignmentData');
          final newAssignmentRef = await _firestore.collection('work_assignments').add(newAssignmentData);
          debugPrint('Nueva asignación creada con ID: ${newAssignmentRef.id}');
          
          // Crear invitación solo si estamos duplicando usuarios
          if (duplicateUsers && data['userId'] != null) {
            try {
              final userId = data['userId'].id;
              final ministryId = data['ministryId'].id;
              debugPrint('Creando invitación para usuario: $userId, ministerio: $ministryId');
              
          await _createInviteForDuplicatedAssignment(
            assignmentId: newAssignmentRef.id,
                userId: userId,
                ministryId: ministryId,
            role: data['role'],
            newCultDate: newCultDate,
            timeSlotId: newTimeSlotId,
          );
              
              debugPrint('Invitación creada exitosamente');
            } catch (e) {
              debugPrint('Error al crear invitación: $e');
            }
          }
        } else {
          debugPrint('Omitiendo asignación no aceptada: ${doc.id}');
        }
      }
      
      debugPrint('Duplicación de asignaciones completada exitosamente');
    } catch (e) {
      debugPrint('Error al duplicar asignaciones: $e');
      rethrow;
    }
  }
  
  // Crear invitación para una asignación duplicada
  Future<void> _createInviteForDuplicatedAssignment({
    required String assignmentId,
    required String userId,
    required String ministryId,
    required String role,
    required DateTime newCultDate,
    required String timeSlotId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Obtener detalles de la franja horaria
      final timeSlotDoc = await _firestore.collection('time_slots').doc(timeSlotId).get();
      final timeSlotData = timeSlotDoc.data() as Map<String, dynamic>;
      
      // Obtener detalles del culto
      final cultId = timeSlotData['entityId'];
      final cultDoc = await _firestore.collection('cults').doc(cultId).get();
      final cultData = cultDoc.data() as Map<String, dynamic>;
      
      // Obtener detalles del ministerio
      final ministryDoc = await _firestore.collection('ministries').doc(ministryId).get();
      final ministryData = ministryDoc.data() as Map<String, dynamic>;
      
      // Crear invitación
      final inviteData = {
        'assignmentId': assignmentId,
        'userId': _firestore.collection('users').doc(userId),
        'entityId': cultId,
        'entityType': 'cult',
        'entityName': cultData['name'],
        'date': Timestamp.fromDate(newCultDate),
        'startTime': timeSlotData['startTime'],
        'endTime': timeSlotData['endTime'],
        'ministryId': _firestore.collection('ministries').doc(ministryId),
        'ministryName': ministryData['name'],
        'role': role,
        'status': 'pending',
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'sentBy': _firestore.collection('users').doc(currentUser.uid),
      };
      
      await _firestore.collection('work_invites').add(inviteData);
      
      // Enviar notificación al usuario
      await _notificationService.sendNotification(
        userId: userId,
        title: 'Nueva invitación de trabajo',
        body: 'Has sido invitado a participar en ${cultData['name']} como $role',
        data: {
          'entityId': cultId,
          'entityType': 'cult',
        },
      );
    } catch (e) {
      debugPrint('Error al crear invitación para asignación duplicada: $e');
      rethrow;
    }
  }

  // Método mejorado para eliminar asignaciones de trabajo por franja horaria y ministerio
  Future<void> deleteWorkAssignmentsByMinistry({
    required String timeSlotId,
    required String ministryId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      debugPrint('Excluindo ministério: $ministryId da faixa horária: $timeSlotId');
      
      // Referencia al ministerio
      final ministryRef = _firestore.collection('ministries').doc(ministryId);
      
      // 1. Obtener todas las asignaciones activas para esta franja y ministerio
      final assignmentsSnapshot = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Encontradas ${assignmentsSnapshot.docs.length} atribuições para excluir');
      
      // Iniciar un batch para todas las operaciones
      final batch = _firestore.batch();
      
      // Lista de IDs de asignaciones para luego buscar invitaciones
      final assignmentIds = <String>[];
      
      // Recolectar información sobre roles para actualizar contadores
      final Map<String, int> rolesCountsToUpdate = {};
      
      // 2. Marcar cada asignación como inactiva
      for (var doc in assignmentsSnapshot.docs) {
        assignmentIds.add(doc.id);
        final assignmentData = doc.data();
        final String role = assignmentData['role'] ?? '';
        final String status = assignmentData['status'] ?? '';
        
        // Si la asignación está aceptada, registrarla para actualizar contador
        if (status == 'accepted') {
          rolesCountsToUpdate[role] = (rolesCountsToUpdate[role] ?? 0) + 1;
        }
        
        batch.update(doc.reference, {
          'isActive': false,
          'status': 'cancelled',
          'updatedAt': Timestamp.now(),
          'deletedAt': Timestamp.now(),
          'deletedBy': _firestore.collection('users').doc(currentUser.uid),
        });
        debugPrint('Adicionando atribuição para excluir: ${doc.id}');
      }
      
      // 3. ELIMINAR los roles disponibles para este ministerio y franja
      // Buscar roles donde el ministryId es una referencia (formato antiguo)
      final availableRolesSnapshotRef = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .get();
          
      // Buscar roles donde el ministryId es un string (formato nuevo)
      final availableRolesSnapshotString = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryId)
          .get();
          
      // Buscar roles donde el ministryId está en formato de ruta completa "/ministries/X"
      final ministryIdPath = '/ministries/${ministryId}';
      final availableRolesSnapshotPath = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryIdPath)
          .get();
          
      final totalRoles = availableRolesSnapshotRef.docs.length + 
                          availableRolesSnapshotString.docs.length + 
                          availableRolesSnapshotPath.docs.length;
                          
      debugPrint('Encontradas $totalRoles funções disponíveis para excluir:');
      debugPrint('- ${availableRolesSnapshotRef.docs.length} com referência');
      debugPrint('- ${availableRolesSnapshotString.docs.length} com string simples');
      debugPrint('- ${availableRolesSnapshotPath.docs.length} com caminho completo');
      
      // ELIMINAR roles con referencias
      for (var doc in availableRolesSnapshotRef.docs) {
        batch.delete(doc.reference);
        debugPrint('🗑️ Excluindo função (ref): ${doc.id}');
      }
      
      // ELIMINAR roles con strings
      for (var doc in availableRolesSnapshotString.docs) {
        batch.delete(doc.reference);
        debugPrint('🗑️ Excluindo função (string): ${doc.id}');
      }
      
      // ELIMINAR roles con ruta completa
      for (var doc in availableRolesSnapshotPath.docs) {
        batch.delete(doc.reference);
        debugPrint('🗑️ Excluindo função (path): ${doc.id}');
      }
      
      // 4. Buscar invitaciones relacionadas con estas asignaciones
      for (final assignmentId in assignmentIds) {
        final invitesSnapshot = await _firestore
            .collection('work_invites')
            .where('assignmentId', isEqualTo: assignmentId)
            .get();
        
        // Marcar cada invitación como inactiva
        for (var doc in invitesSnapshot.docs) {
          batch.update(doc.reference, {
            'isActive': false,
            'status': 'cancelled',
            'updatedAt': Timestamp.now(),
            'deletedAt': Timestamp.now(),
            'deletedBy': _firestore.collection('users').doc(currentUser.uid),
          });
          debugPrint('Adicionando convite para excluir: ${doc.id}');
          
          // 5. Enviar notificación a los usuarios afectados
          try {
            final inviteData = doc.data();
            final userId = inviteData['userId'].id;
            
            await _notificationService.sendNotification(
              userId: userId,
              title: 'Atribuição cancelada',
              body: 'Sua atribuição foi cancelada porque o ministério foi removido da faixa horária',
              data: {
                'inviteId': doc.id,
                'status': 'cancelled',
              },
            );
          } catch (e) {
            debugPrint('Erro ao enviar notificação: $e');
          }
        }
      }
      
      // 5. Buscar y eliminar también las invitaciones vinculadas directamente al ministerio
      final ministryInvitesSnapshot = await _firestore
          .collection('work_invites')
          .where('ministryId', isEqualTo: ministryRef)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('Encontrados ${ministryInvitesSnapshot.docs.length} convites para o ministério, filtrando os relevantes...');
      
      // Obtener la información de la franja horaria para comparar
      final timeSlotDoc = await _firestore
          .collection('time_slots')
          .doc(timeSlotId)
          .get();
      
      if (timeSlotDoc.exists) {
        final timeSlotData = timeSlotDoc.data() as Map<String, dynamic>;
        final timeSlotStartTime = (timeSlotData['startTime'] as Timestamp).toDate();
        final timeSlotEndTime = (timeSlotData['endTime'] as Timestamp).toDate();
        
        // Invitaciones relevantes a esta franja
        int invitesAffected = 0;
        
        for (var doc in ministryInvitesSnapshot.docs) {
          final inviteData = doc.data();
          
          // Verificar si la invitación corresponde a esta franja horaria
          final inviteStartTime = (inviteData['startTime'] as Timestamp).toDate();
          final inviteEndTime = (inviteData['endTime'] as Timestamp).toDate();
          
          // Si corresponde a la misma franja horaria
          if (inviteStartTime.isAtSameMomentAs(timeSlotStartTime) && 
              inviteEndTime.isAtSameMomentAs(timeSlotEndTime)) {
            
            invitesAffected++;
            final String role = inviteData['role'] ?? '';
            final String status = inviteData['status'] ?? '';
            
            // Si la invitación está aceptada, registrarla para actualizar contador
            if (status == 'accepted') {
              rolesCountsToUpdate[role] = (rolesCountsToUpdate[role] ?? 0) + 1;
            }
            
            batch.update(doc.reference, {
              'isActive': false,
              'status': 'cancelled',
              'updatedAt': Timestamp.now(),
              'deletedAt': Timestamp.now(),
              'deletedBy': _firestore.collection('users').doc(currentUser.uid),
            });
            debugPrint('Adicionando convite ministerial para excluir: ${doc.id}');
            
            try {
              final userId = inviteData['userId'].id;
              
              await _notificationService.sendNotification(
                userId: userId,
                title: 'Convite cancelado',
                body: 'Seu convite foi cancelado porque o ministério foi removido da faixa horária',
                data: {
                  'inviteId': doc.id,
                  'status': 'cancelled',
                },
              );
            } catch (e) {
              debugPrint('Erro ao enviar notificação: $e');
            }
          }
        }
        
        debugPrint('Serão excluídos $invitesAffected convites relacionados a este ministério e faixa');
      }
      
      // 6. Ejecutar todas las operaciones en un batch
      await batch.commit();
      debugPrint('Batch completado com sucesso');
      
      // 7. Actualizar contadores de roles si es necesario 
      // (fuera del batch porque puede requerir varias llamadas a Firestore)
      if (rolesCountsToUpdate.isNotEmpty) {
        debugPrint('⚠️ Atualizando contadores para ${rolesCountsToUpdate.length} funções afetadas:');
        rolesCountsToUpdate.forEach((role, count) {
          debugPrint('  - $role: $count atribuições excluídas');
        });
      }
    } catch (e) {
      debugPrint('Erro ao excluir atribuições: $e');
      throw Exception('Erro ao excluir atribuições: $e');
    }
  }

  // Nuevo método para eliminar una asignación individual
  Future<void> deleteWorkAssignment(String assignmentId) async {
    try {
      // Verificar que el usuario actual tiene permisos (pastor o creador de la asignación)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Obtener la asignación
      final assignmentDoc = await _firestore
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        throw Exception('A atribuição não existe');
      }
      
      final assignmentData = assignmentDoc.data()!;
      final String timeSlotId = assignmentData['timeSlotId'];
      final dynamic ministryId = assignmentData['ministryId'];
      final String role = assignmentData['role'];
      
      // Extraer ministryId como string
      String ministryIdStr;
      if (ministryId is DocumentReference) {
        ministryIdStr = ministryId.id;
      } else if (ministryId is String) {
        ministryIdStr = ministryId;
      } else {
        ministryIdStr = ministryId.toString();
        if (ministryIdStr.contains('/')) {
          ministryIdStr = ministryIdStr.split('/').last;
        }
      }
      
      final String status = assignmentData['status'] ?? '';
      
      // Marcar la asignación como inactiva
      await _firestore
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isActive': false,
            'updatedAt': Timestamp.now(),
            'deletedAt': Timestamp.now(),
            'deletedBy': _firestore.collection('users').doc(currentUser.uid),
          });
      
      // Si la asignación estaba aceptada, actualizar el contador de roles
      if (status == 'accepted') {
        debugPrint('📊 Atualizando contador porque uma atribuição aceita foi excluída');
        await updateRoleCounter(timeSlotId, ministryIdStr, role, false);
      }
      
      // Buscar y actualizar la invitación correspondiente
      final invitesSnapshot = await _firestore
          .collection('work_invites')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();
          
      for (var doc in invitesSnapshot.docs) {
        await _firestore
            .collection('work_invites')
            .doc(doc.id)
            .update({
              'status': 'cancelled',
              'isActive': false,
              'updatedAt': Timestamp.now(),
              'deletedAt': Timestamp.now(),
              'deletedBy': _firestore.collection('users').doc(currentUser.uid),
            });
            
        // Enviar notificación al usuario
        final inviteData = doc.data();
        final userId = inviteData['userId'].id;
        
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Convite cancelado',
          body: 'Seu convite para participar em um evento foi cancelado',
          data: {
            'inviteId': doc.id,
            'status': 'cancelled',
          },
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar asignación: $e');
      throw Exception('Error al eliminar asignación: $e');
    }
  }
  
  // Método para eliminar una invitación directamente
  Future<void> deleteWorkInvite(String inviteId) async {
    try {
      // Verificar que el usuario actual tiene permisos
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      debugPrint('Eliminando invitación: $inviteId');
      
      // Obtener la invitación
      final inviteDoc = await _firestore
          .collection('work_invites')
          .doc(inviteId)
          .get();
          
      if (!inviteDoc.exists) {
        debugPrint('La invitación no existe: $inviteId');
        throw Exception('La invitación no existe');
      }
      
      final inviteData = inviteDoc.data()!;
      debugPrint('Datos de invitación: ${inviteData.toString()}');
      
      // Extraer datos necesarios
      final String timeSlotId = inviteData['timeSlotId'];
      final dynamic ministryId = inviteData['ministryId'];
      final String role = inviteData['role'];
      final String status = inviteData['status'] ?? '';
      
      // Extraer ministryId como string
      String ministryIdStr;
      if (ministryId is DocumentReference) {
        ministryIdStr = ministryId.id;
      } else if (ministryId is String) {
        ministryIdStr = ministryId;
      } else {
        ministryIdStr = ministryId.toString();
        if (ministryIdStr.contains('/')) {
          ministryIdStr = ministryIdStr.split('/').last;
        }
      }
      
      // Marcar la invitación como cancelada e inactiva
      await _firestore
          .collection('work_invites')
          .doc(inviteId)
          .update({
            'status': 'cancelled',
            'isActive': false,
            'updatedAt': Timestamp.now(),
            'deletedAt': Timestamp.now(),
            'deletedBy': _firestore.collection('users').doc(currentUser.uid),
          });
      
      debugPrint('Invitación marcada como inactiva y cancelada: $inviteId');
      
      // Si hay una asignación asociada, también marcarla como inactiva
      if (inviteData.containsKey('assignmentId') && 
          inviteData['assignmentId'] != null && 
          inviteData['assignmentId'].toString().isNotEmpty) {
          
        final assignmentId = inviteData['assignmentId'];
        debugPrint('Eliminando asignación relacionada: $assignmentId');
        
        final assignmentDoc = await _firestore
            .collection('work_assignments')
            .doc(assignmentId)
            .get();
            
        if (assignmentDoc.exists) {
          final assignmentData = assignmentDoc.data()!;
          final String assignmentStatus = assignmentData['status'] ?? '';
          
          await _firestore
              .collection('work_assignments')
              .doc(assignmentId)
              .update({
                'isActive': false,
                'status': 'cancelled',
                'updatedAt': Timestamp.now(),
                'deletedAt': Timestamp.now(),
                'deletedBy': _firestore.collection('users').doc(currentUser.uid),
              });
              
          // Si la asignación estaba aceptada, actualizar el contador
          if (assignmentStatus == 'accepted' || status == 'accepted') {
            debugPrint('📊 Actualizando contador porque se eliminó una invitación aceptada');
            await updateRoleCounter(timeSlotId, ministryIdStr, role, false);
          }
          
          debugPrint('Asignación relacionada eliminada correctamente: $assignmentId');
        } else {
          debugPrint('La asignación relacionada no existe: $assignmentId');
        }
      } else {
        debugPrint('No hay asignación relacionada con esta invitación');
        
        // Si la invitación estaba aceptada, actualizar el contador de todas formas
        if (status == 'accepted') {
          debugPrint('📊 Actualizando contador porque se eliminó una invitación aceptada sin asignación');
          await updateRoleCounter(timeSlotId, ministryIdStr, role, false);
        }
      }
      
      // Enviar notificación al usuario
      final userId = inviteData['userId'].id;
      await _notificationService.sendNotification(
        userId: userId,
        title: 'Invitación cancelada',
        body: 'Tu invitación para participar en un evento ha sido cancelada',
        data: {
          'inviteId': inviteId,
          'status': 'cancelled',
        },
      );
      
      debugPrint('Proceso de eliminación de invitación completado: $inviteId');
    } catch (e) {
      debugPrint('Error al eliminar invitación: $e');
      throw Exception('Error al eliminar invitación: $e');
    }
  }

  // ======== NUEVOS MÉTODOS PARA GESTIONAR VISIBILIDAD DE INVITACIONES ========

  // Verificar si un rol está lleno (current >= capacity)
  Future<bool> isRoleFull(String timeSlotId, String ministryId, String role) async {
    try {
      debugPrint('Verificando si el rol "$role" está lleno');
      
      // Crear una referencia al documento del ministerio
      final ministryRef = _firestore.collection('ministries').doc(ministryId);
      
      // Buscar el rol en available_roles con la referencia del documento
      final rolesSnapshot = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Si no encontramos el rol, asumimos que no está lleno
      if (rolesSnapshot.docs.isEmpty) {
        debugPrint('No se encontró el rol "$role" - asumiendo que no está lleno');
        return false;
      }
      
      // Verificar capacidad vs asignaciones actuales
      final roleDoc = rolesSnapshot.docs.first;
      final roleData = roleDoc.data();
      final int capacity = roleData['capacity'] ?? 1;
      final int current = roleData['current'] ?? 0;
      
      debugPrint('Rol "$role": capacidad $capacity, ocupación actual $current');
      
      // El rol está lleno si current >= capacity
      return current >= capacity;
    } catch (e) {
      debugPrint('Error al verificar si el rol está lleno: $e');
      return false; // En caso de error, asumimos que no está lleno
    }
  }
  
  // Actualizar visibilidad de invitaciones basado en capacidad de rol
  Future<void> updateInvitationsVisibility(
      String timeSlotId, String ministryId, String role) async {
    try {
      // Verificar si el rol está lleno
      final bool isFull = await isRoleFull(timeSlotId, ministryId, role);
      debugPrint('Actualizando visibilidad de invitaciones. El rol está ${isFull ? "lleno" : "disponible"}');

      // Obtener referencia para ministryId (puede ser DocumentReference o String)
      final ministryRef = _firestore.collection('ministries').doc(ministryId);
      
      // Buscar todas las invitaciones pendientes para este rol, horario y ministerio
      final invitationsQuery = await _firestore
          .collection('work_invites')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('role', isEqualTo: role)
          .where('status', whereIn: ['pending', 'seen'])
          .where('isActive', isEqualTo: true)
          .get();

      // Si no hay invitaciones, terminar
      if (invitationsQuery.docs.isEmpty) {
        debugPrint('No se encontraron invitaciones pendientes para actualizar');
        return;
      }
      
      debugPrint('Actualizando ${invitationsQuery.docs.length} invitaciones pendientes');
      
      // Usar batch para actualizar todas las invitaciones de una vez
      final batch = _firestore.batch();
      
      for (final doc in invitationsQuery.docs) {
        batch.update(doc.reference, {'isVisible': !isFull});
        debugPrint('Marcando invitación ${doc.id} como ${!isFull ? "visible" : "no visible"}');
      }
      
      // Ejecutar todas las actualizaciones en una operación
      await batch.commit();
      debugPrint('Visibilidad de invitaciones actualizada correctamente');
      
      // Actualizar el contador en available_roles para asegurar consistencia
      final rolesSnapshot = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (rolesSnapshot.docs.isNotEmpty) {
        final roleDocRef = rolesSnapshot.docs.first.reference;
        final roleData = rolesSnapshot.docs.first.data();
        final int capacity = roleData['capacity'] ?? 1;
        
        // Contar asignaciones aceptadas para este rol para asegurar que el contador es correcto
        final assignmentsQuery = await _firestore
            .collection('work_assignments')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('ministryId', isEqualTo: ministryRef)
            .where('role', isEqualTo: role)
            .where('status', isEqualTo: 'accepted')
            .where('isActive', isEqualTo: true)
            .get();
        
        final int currentAccepted = assignmentsQuery.docs.length;
        
        // Actualizar el contador si es diferente al actual
        if (roleData['current'] != currentAccepted) {
          await roleDocRef.update({'current': currentAccepted});
          debugPrint('Contador de rol corregido: ${roleData['current']} → $currentAccepted');
        }
      }
    } catch (e) {
      debugPrint('Error al actualizar visibilidad de invitaciones: $e');
    }
  }
  
  // Actualizar contador de roles cuando se acepta o rechaza una asignación
  Future<void> updateRoleCounter(String timeSlotId, String ministryId, String role, bool increase) async {
    try {
      debugPrint('⚠️ DIAGNÓSTICO: updateRoleCounter iniciado con: timeSlotId=$timeSlotId, ministryId=$ministryId, role=$role, increase=$increase');
      
      // Crear una referencia al documento del ministerio
      final ministryRef = _firestore.collection('ministries').doc(ministryId);
      debugPrint('⚠️ DIAGNÓSTICO: Creada referencia al ministerio: ${ministryRef.path}');
      
      // Buscar el rol en available_roles con la referencia del documento
      final rolesSnapshot = await _firestore
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();
      
      debugPrint('⚠️ DIAGNÓSTICO: Búsqueda con referencia encontró ${rolesSnapshot.docs.length} documentos');
      
      if (rolesSnapshot.docs.isEmpty) {
        debugPrint('❌ DIAGNÓSTICO: No se encontró el rol usando referencia. Intentando con string...');
        
        // Intento de fallback con string (aunque no debería ser necesario)
        final rolesSnapshotFallback = await _firestore
            .collection('available_roles')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('ministryId', isEqualTo: ministryId)
            .where('role', isEqualTo: role)
            .where('isActive', isEqualTo: true)
            .get();
            
        debugPrint('⚠️ DIAGNÓSTICO: Búsqueda con string encontró ${rolesSnapshotFallback.docs.length} documentos');
        
        if (rolesSnapshotFallback.docs.isEmpty) {
          debugPrint('❌ DIAGNÓSTICO: No se encontró el rol ni con string. Creando nuevo rol...');
          
          // Si no existe el rol, crearlo con valores por defecto
          final newRoleData = {
            'timeSlotId': timeSlotId,
            'ministryId': ministryRef,
            'role': role,
            'capacity': 1,
            'current': increase ? 1 : 0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          debugPrint('⚠️ DIAGNÓSTICO: Datos para nuevo rol: $newRoleData');
          final newRoleRef = await _firestore.collection('available_roles').add(newRoleData);
          debugPrint('✅ DIAGNÓSTICO: Rol creado correctamente con ID: ${newRoleRef.id}');
          
          // Actualizar visibilidad de invitaciones
          await updateInvitationsVisibility(timeSlotId, ministryId, role);
          return;
        }
        
        // Si se encontró con string, migrarlo a referencia
        final roleDocRef = rolesSnapshotFallback.docs.first.reference;
        final roleData = rolesSnapshotFallback.docs.first.data();
        final int capacity = roleData['capacity'] ?? 1;
        final int currentValue = roleData['current'] ?? 0;
        
        debugPrint('⚠️ DIAGNÓSTICO: Rol encontrado con string - ID: ${roleDocRef.id}, current: $currentValue, capacity: $capacity');
        
        // Calcular el nuevo valor basado en el conteo real y el parámetro increase
        final int newValue = increase ? currentValue + 1 : max(0, currentValue - 1);
        debugPrint('⚠️ DIAGNÓSTICO: Nuevo valor calculado: $newValue (currentValue=$currentValue, increase=$increase)');
        
        // Actualizar para usar referencia en lugar de string y el nuevo valor del contador
        final Map<String, dynamic> updateData = {
          'ministryId': ministryRef,
          'current': newValue,
        };
        
        debugPrint('⚠️ DIAGNÓSTICO: Actualizando rol con datos: $updateData');
        await roleDocRef.update(updateData);
        debugPrint('⚠️ DIAGNÓSTICO: Rol migrado de string a referencia y contador actualizado a $newValue');
        
        // Actualizar visibilidad de invitaciones
        await updateInvitationsVisibility(timeSlotId, ministryId, role);
        return;
      }
      
      final roleDocRef = rolesSnapshot.docs.first.reference;
      final roleData = rolesSnapshot.docs.first.data();
      final int capacity = roleData['capacity'] ?? 1;
      final int currentValue = roleData['current'] ?? 0;
      
      debugPrint('⚠️ DIAGNÓSTICO: Rol encontrado con referencia - ID: ${roleDocRef.id}, current: $currentValue, capacity: $capacity');
      
      // Calcular el nuevo valor basado en el parámetro increase
      final int newValue = increase ? currentValue + 1 : max(0, currentValue - 1);
      debugPrint('⚠️ DIAGNÓSTICO: Nuevo valor calculado: $newValue (currentValue=$currentValue, increase=$increase)');
      
      // Verificar si el valor actual está sincronizado con la realidad
      debugPrint('⚠️ DIAGNÓSTICO: Contando asignaciones activas para validar el contador...');
      final int actualCount = await _countActiveAssignments(timeSlotId, ministryId, role);
      debugPrint('⚠️ DIAGNÓSTICO: Conteo real de asignaciones: $actualCount');
      
      // Si hay una gran discrepancia, usar el conteo real en lugar del cálculo incremental
      // Esto actuará como una corrección si los contadores se han desincronizado
      final int finalValue;
      if ((actualCount - newValue).abs() > 1) {
        debugPrint('⚠️ DIAGNÓSTICO: Discrepancia detectada (${(actualCount - newValue).abs()}) entre contador calculado ($newValue) y conteo real ($actualCount). Usando conteo real.');
        finalValue = actualCount;
      } else {
        debugPrint('⚠️ DIAGNÓSTICO: Usando valor calculado: $newValue');
        finalValue = newValue;
      }
      
      // Actualizar el contador
      debugPrint('⚠️ DIAGNÓSTICO: Actualizando contador en Firestore a $finalValue');
      await roleDocRef.update({'current': finalValue});
      
      // Verificar que la actualización se realizó correctamente
      final verificationDoc = await roleDocRef.get();
      if (verificationDoc.exists) {
        final int verifiedValue = verificationDoc.data()?['current'] ?? 0;
        debugPrint('⚠️ DIAGNÓSTICO: Verificación después de actualizar: valor actual = $verifiedValue');
        if (verifiedValue != finalValue) {
          debugPrint('❌ DIAGNÓSTICO: ERROR: El valor verificado ($verifiedValue) no coincide con el valor esperado ($finalValue)');
        } else {
          debugPrint('✅ DIAGNÓSTICO: Contador actualizado correctamente');
        }
      }
      
      debugPrint('✅ DIAGNÓSTICO: Contador de rol actualizado: $currentValue → $finalValue (capacidad: $capacity)');
      
      // Verificar si el estado de "lleno" ha cambiado
      final bool wasFull = currentValue >= capacity;
      final bool isFull = finalValue >= capacity;
      
      // Si el estado de "lleno" cambió, actualizar todas las invitaciones
      if (wasFull != isFull) {
        debugPrint('⚠️ DIAGNÓSTICO: ¡CAMBIO IMPORTANTE! El rol estaba ${wasFull ? "lleno" : "disponible"} y ahora está ${isFull ? "lleno" : "disponible"}');
        await updateInvitationsVisibility(timeSlotId, ministryId, role);
      } else {
        // Si no cambió el estado pero es relevante, actualizar de todas formas
        if (isFull) {
          // Si está lleno, asegurar que todas las invitaciones estén ocultas
          debugPrint('⚠️ DIAGNÓSTICO: Rol lleno, asegurando que invitaciones estén ocultas');
          await updateInvitationsVisibility(timeSlotId, ministryId, role);
        } else if (!isFull) {
          // Si hay espacio, asegurar que las invitaciones estén visibles
          debugPrint('⚠️ DIAGNÓSTICO: Rol con espacio, asegurando que invitaciones sean visibles');
          await updateInvitationsVisibility(timeSlotId, ministryId, role);
        }
      }
    } catch (e) {
      debugPrint('❌ DIAGNÓSTICO: Error al actualizar contador de rol: $e');
    }
  }
  
  // Método para contar el número actual de asignaciones activas para un rol
  Future<int> _countActiveAssignments(String timeSlotId, String ministryId, String role) async {
    try {
      debugPrint('📊 DIAGNÓSTICO: Iniciando conteo de asignaciones para timeSlotId=$timeSlotId, ministryId=$ministryId, role=$role');
      
      // Crear referencia al ministerio
      final ministryRef = _firestore.collection('ministries').doc(ministryId);
      debugPrint('📊 DIAGNÓSTICO: Referencia al ministerio: ${ministryRef.path}');
      
      // Buscar asignaciones que cumplan con los criterios usando referencia
      debugPrint('📊 DIAGNÓSTICO: Buscando asignaciones con referencia...');
      final assignmentsQueryRef = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'accepted')
          .get();
          
      debugPrint('📊 DIAGNÓSTICO: Asignaciones con referencia encontradas: ${assignmentsQueryRef.docs.length}');
      
      // También buscar con ministryId como string
      debugPrint('📊 DIAGNÓSTICO: Buscando asignaciones con string...');
      final assignmentsQueryStr = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      debugPrint('📊 DIAGNÓSTICO: Asignaciones con string encontradas: ${assignmentsQueryStr.docs.length}');
      
      // También buscar con el formato "/ministries/ID"
      final ministryPath = '/ministries/${ministryId}';
      debugPrint('📊 DIAGNÓSTICO: Buscando asignaciones con ruta completa: $ministryPath');
      final assignmentsQueryPath = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryPath)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      debugPrint('📊 DIAGNÓSTICO: Asignaciones con ruta completa encontradas: ${assignmentsQueryPath.docs.length}');
      
      // IMPORTANTE: También búsqueda de asignaciones confirmadas
      debugPrint('📊 DIAGNÓSTICO: Buscando asignaciones CONFIRMADAS (no solo aceptadas)...');
      final confirmedAssignmentsRef = await _firestore
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: timeSlotId)
          .where('ministryId', isEqualTo: ministryRef)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .where('isAttendanceConfirmed', isEqualTo: true)
          .get();
      
      debugPrint('📊 DIAGNÓSTICO: Asignaciones CONFIRMADAS encontradas: ${confirmedAssignmentsRef.docs.length}');
          
      // Contar el total de todas las búsquedas
      final int count = assignmentsQueryRef.docs.length + 
                        assignmentsQueryStr.docs.length + 
                        assignmentsQueryPath.docs.length;
                        
      debugPrint('📊 DIAGNÓSTICO: Conteo total de asignaciones ACEPTADAS: $count');
      
      if (count == 0) {
        debugPrint('📊 DIAGNÓSTICO: ¡No se encontraron asignaciones aceptadas! Verificando si hay IDs duplicados entre las búsquedas...');
      } else {
        // Verificar si hay IDs duplicados entre las diferentes búsquedas
        final allDocIds = [
          ...assignmentsQueryRef.docs.map((doc) => doc.id),
          ...assignmentsQueryStr.docs.map((doc) => doc.id),
          ...assignmentsQueryPath.docs.map((doc) => doc.id),
        ];
        
        final uniqueDocIds = Set<String>.from(allDocIds);
        if (allDocIds.length != uniqueDocIds.length) {
          debugPrint('⚠️ DIAGNÓSTICO: ¡Atención! Hay ${allDocIds.length - uniqueDocIds.length} IDs duplicados en las búsquedas');
        }
        
        // Verificar que las asignaciones encontradas tengan los datos correctos
        debugPrint('📊 DIAGNÓSTICO: Ejemplos de asignaciones encontradas:');
        for (int i = 0; i < min(2, assignmentsQueryRef.docs.length); i++) {
          final doc = assignmentsQueryRef.docs[i];
          final data = doc.data();
          debugPrint('- Asignación REF ${i+1}: id=${doc.id}, role=${data['role']}, status=${data['status']}, isConfirmed=${data['isAttendanceConfirmed']}');
        }
        
        for (int i = 0; i < min(2, assignmentsQueryStr.docs.length); i++) {
          final doc = assignmentsQueryStr.docs[i];
          final data = doc.data();
          debugPrint('- Asignación STR ${i+1}: id=${doc.id}, role=${data['role']}, status=${data['status']}, isConfirmed=${data['isAttendanceConfirmed']}');
        }
      }
      
      return count;
    } catch (e) {
      debugPrint('❌ DIAGNÓSTICO: Error al contar asignaciones activas: $e');
      return 0; // En caso de error, devolver 0 como valor seguro
    }
  }

  // Método de migración para actualizar invitaciones existentes
  Future<void> migrateExistingInvitations() async {
    try {
      debugPrint('Iniciando migración de invitaciones existentes...');
      
      // Obtener todas las invitaciones pendientes que no tengan el campo isVisible
      final invitesSnapshot = await _firestore
          .collection('work_invites')
          .where('isActive', isEqualTo: true)
          .where('status', whereIn: ['pending', 'seen'])
          .get();
      
      debugPrint('Encontradas ${invitesSnapshot.docs.length} invitaciones para revisar');
      
      // Organizar invitaciones por rol para realizar menos consultas
      final Map<String, List<DocumentReference>> invitationsByRole = {};
      
      for (var doc in invitesSnapshot.docs) {
        final data = doc.data();
        
        // Si ya tiene isVisible definido, no necesitamos actualizarlo
        if (data.containsKey('isVisible')) continue;
        
        final String timeSlotId = data['timeSlotId'];
        final DocumentReference ministryRef = data['ministryId'];
        final String role = data['role'];
        
        // Clave única para cada combinación de timeSlot, ministry y role
        final String key = '${timeSlotId}_${ministryRef.id}_$role';
        
        if (!invitationsByRole.containsKey(key)) {
          invitationsByRole[key] = [];
        }
        
        invitationsByRole[key]!.add(doc.reference);
      }
      
      debugPrint('Procesando ${invitationsByRole.length} grupos diferentes de roles');
      
      // Procesar cada grupo de invitaciones por rol
      for (var entry in invitationsByRole.entries) {
        final parts = entry.key.split('_');
        final String timeSlotId = parts[0];
        final String ministryId = parts[1];
        final String role = parts[2];
        
        // Verificar si el rol está lleno
        final bool isFull = await isRoleFull(timeSlotId, ministryId, role);
        debugPrint('Rol $role: ${isFull ? "lleno" : "disponible"}');
        
        // Actualizar todas las invitaciones del grupo
        final batch = _firestore.batch();
        
        for (var docRef in entry.value) {
          batch.update(docRef, {'isVisible': !isFull});
        }
        
        await batch.commit();
        debugPrint('Actualizadas ${entry.value.length} invitaciones para el rol $role');
      }
      
      debugPrint('Migración de invitaciones completada con éxito');
    } catch (e) {
      debugPrint('Error durante la migración de invitaciones: $e');
    }
  }

  // Método para eliminar invitaciones para un ministerio y franja horaria
  Future<void> deleteInvitationsForMinistryAndRole({
    required String timeSlotId,
    required String ministryId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      debugPrint('Eliminando invitaciones para ministerio: $ministryId en franja: $timeSlotId');
      
      // Referencia al ministerio para búsquedas con referencias
      final ministryRef = _firestore.collection('ministries').doc(ministryId);
      
      // Buscar invitaciones con diferentes formatos de ministryId en un solo batch
      final List<QuerySnapshot> invitationSnapshots = await Future.wait([
        // 1. Buscar por referencia de documento
        _firestore
            .collection('work_invites')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('ministryId', isEqualTo: ministryRef)
            .where('isActive', isEqualTo: true)
            .get(),
        
        // 2. Buscar por ID simple
        _firestore
            .collection('work_invites')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('ministryId', isEqualTo: ministryId)
            .where('isActive', isEqualTo: true)
            .get(),
        
        // 3. Buscar por ruta completa
        _firestore
            .collection('work_invites')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('ministryId', isEqualTo: '/ministries/$ministryId')
            .where('isActive', isEqualTo: true)
            .get(),
      ]);
      
      // Combinar todos los documentos encontrados
      final List<QueryDocumentSnapshot> allInvitations = [];
      for (final snapshot in invitationSnapshots) {
        allInvitations.addAll(snapshot.docs);
      }
      
      debugPrint('Se encontraron ${allInvitations.length} invitaciones para eliminar');
      
      if (allInvitations.isEmpty) {
        debugPrint('No hay invitaciones para eliminar');
        return;
      }
      
      // Actualizar todas las invitaciones en un batch
      final batch = _firestore.batch();
      
      for (final doc in allInvitations) {
        batch.update(doc.reference, {
          'isActive': false,
          'isVisible': false,
          'status': 'cancelled',
          'updatedAt': Timestamp.now(),
          'deletedAt': Timestamp.now(),
          'deletedBy': _firestore.collection('users').doc(currentUser.uid),
          'notes': 'Eliminado por eliminación del ministerio',
        });
        
        try {
          // Normalizar el userId para la notificación
          final data = doc.data() as Map<String, dynamic>;
          final String userId = _normalizeId(data['userId']);
          
          if (userId.isNotEmpty) {
            await _notificationService.sendNotification(
              userId: userId,
              title: 'Invitación cancelada',
              body: 'Tu invitación ha sido cancelada porque el ministerio ha sido eliminado',
              data: {
                'inviteId': doc.id,
                'status': 'cancelled',
              },
            );
          }
        } catch (e) {
          debugPrint('Error al enviar notificación: $e');
        }
      }
      
      // Ejecutar el batch
        await batch.commit();
      debugPrint('Invitaciones eliminadas correctamente');
      
    } catch (e) {
      debugPrint('Error al eliminar invitaciones: $e');
      throw Exception('Error al eliminar invitaciones: $e');
    }
  }
  
  // Método auxiliar para normalizar IDs, independientemente del tipo
  String _normalizeId(dynamic id) {
    if (id == null) return '';
    
    if (id is DocumentReference) {
      return id.id;
    } else if (id is String) {
      // Si es una ruta completa como '/ministries/abc123', extraer solo el ID
      if (id.contains('/')) {
        return id.split('/').last;
      }
      return id;
    } else {
      // Último recurso: convertir a string y ver si tiene formato de ruta
      final str = id.toString();
      if (str.contains('/')) {
        return str.split('/').last;
      }
      return str;
    }
  }

  // Método para confirmar asistencia (para pastores)
  Future<void> confirmAttendance(String assignmentId, bool didAttend) async {
    try {
      // Verificar que el usuario actual tiene permisos de pastor
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Verificar si el usuario es pastor (opcional, se puede implementar mejor control de acceso)
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      
      if (userData == null || userData['role'] != 'pastor') {
        throw Exception('No tienes permisos para confirmar asistencia');
      }
      
      // Obtener la asignación
      final assignmentDoc = await _firestore.collection('work_assignments').doc(assignmentId).get();
      
      if (!assignmentDoc.exists) {
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data()!;
      
      // Preparar datos a actualizar
      final Map<String, dynamic> updateData = {
        'isConfirmed': true,
        'didAttend': didAttend,
        'confirmedAt': FieldValue.serverTimestamp(),
        'confirmedBy': _firestore.collection('users').doc(currentUser.uid),
      };
      
      // Actualizar la asignación
      await _firestore.collection('work_assignments').doc(assignmentId).update(updateData);
      
      debugPrint('✅ Asistencia confirmada: didAttend=$didAttend, assignmentId=$assignmentId');
      
      // Actualizar estadísticas del usuario (esto se podría implementar en un futuro)
      // await _updateUserAttendanceStats(...);
      
      // Enviar notificación al usuario si es necesario
      final userId = assignmentData['userId'] is DocumentReference 
          ? assignmentData['userId'].id 
          : assignmentData['userId'];
          
      if (userId != null) {
        await _notificationService.sendNotification(
          userId: userId,
          title: didAttend ? 'Asistencia confirmada' : 'Ausencia registrada',
          body: didAttend 
              ? 'Tu asistencia ha sido confirmada por un pastor. ¡Gracias por tu servicio!' 
              : 'Se ha registrado tu ausencia en la asignación.',
          data: {
            'assignmentId': assignmentId,
            'didAttend': didAttend.toString(),
          },
        );
      }
      
    } catch (e) {
      debugPrint('Error al confirmar asistencia: $e');
      rethrow;
    }
  }

  // Duplicar canciones de un culto
  Future<void> _duplicateSongs(String sourceCultId, String newCultId) async {
    try {
      debugPrint('Iniciando duplicación de canciones del culto: $sourceCultId al nuevo culto: $newCultId');
      
      // Obtener todas las canciones del culto original
      final songsSnapshot = await _firestore
          .collection('cult_songs')
          .where('cultId', isEqualTo: sourceCultId)
          .get();
      
      debugPrint('Encontradas ${songsSnapshot.docs.length} canciones para duplicar');
      
      // Crear nuevas canciones para el nuevo culto
      for (final doc in songsSnapshot.docs) {
        final data = doc.data();
        debugPrint('Duplicando canción: ${doc.id}');
        
        // Crear nueva canción excluyendo id
        final newSongData = {
          'cultId': newCultId,
          'songId': data['songId'],
          'title': data['title'],
          'order': data['order'],
          'createdAt': Timestamp.now(),
          'createdBy': _firestore.collection('users').doc(_auth.currentUser!.uid),
          'isActive': true,
        };
        
        // Si hay campos adicionales en el original, copiarlos también
        data.forEach((key, value) {
          if (!['cultId', 'createdAt', 'createdBy', 'id', 'isActive'].contains(key)) {
            if (!newSongData.containsKey(key)) {
              newSongData[key] = value;
            }
          }
        });
        
        // Crear la nueva canción
        final newSongRef = await _firestore.collection('cult_songs').add(newSongData);
        debugPrint('Nueva canción creada con ID: ${newSongRef.id}');
      }
      
      debugPrint('Duplicación de canciones completada exitosamente');
    } catch (e) {
      debugPrint('Error al duplicar canciones: $e');
      // No lanzamos la excepción para que el proceso de duplicación pueda continuar
    }
  }

  // Nuevo método para duplicar anuncios
  Future<void> _duplicateAnnouncements(
    String sourceCultId,
    String newCultId, 
    DateTime newCultDate,
    int daysInAdvance
  ) async {
    try {
      debugPrint('Iniciando duplicación de anuncios del culto: $sourceCultId al nuevo culto: $newCultId');
      debugPrint('Días de antelación para mostrar anuncios: $daysInAdvance');
      
      // Obtener anuncios del culto original
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('cultId', isEqualTo: sourceCultId)
          .where('type', isEqualTo: 'cult')
          .get();
      
      if (announcementsSnapshot.docs.isEmpty) {
        debugPrint('No se encontraron anuncios para duplicar');
        return;
      }
      
      debugPrint('Encontrados ${announcementsSnapshot.docs.length} anuncios para duplicar');
      
      // Calcular la fecha de inicio del anuncio (fecha del culto - días de antelación)
      DateTime startDate = newCultDate.subtract(Duration(days: daysInAdvance));
      debugPrint('Fecha de inicio calculada para anuncios: $startDate');
      
      // Duplicar cada anuncio
      for (final doc in announcementsSnapshot.docs) {
        final data = doc.data();
        debugPrint('Duplicando anuncio: ${doc.id}');
        
        // Crear nuevo anuncio basado en el original
        final newAnnouncementData = {
          'title': data['title'],
          'description': data['description'],
          'imageUrl': data['imageUrl'],
          'date': Timestamp.fromDate(newCultDate), // La fecha en que expira es la fecha del culto
          'startDate': Timestamp.fromDate(startDate), // Nueva fecha de inicio calculada
          'createdAt': Timestamp.now(),
          'createdBy': _firestore.collection('users').doc(_auth.currentUser!.uid),
          'isActive': true,
          'type': 'cult',
          'cultId': newCultId,
          'serviceId': data['serviceId'],
        };
        
        // Copiar localización si existe
        if (data.containsKey('location') && data['location'] != null) {
          newAnnouncementData['location'] = data['location'];
        }
        
        // Copiar ID de localización si existe
        if (data.containsKey('locationId') && data['locationId'] != null) {
          newAnnouncementData['locationId'] = data['locationId'];
        }
        
        // Crear el nuevo anuncio
        final newAnnouncementRef = await _firestore.collection('announcements').add(newAnnouncementData);
        debugPrint('Nuevo anuncio creado con ID: ${newAnnouncementRef.id}');
      }
      
      debugPrint('Duplicación de anuncios completada exitosamente');
    } catch (e) {
      debugPrint('Error al duplicar anuncios: $e');
      // No lanzamos excepción para permitir que el proceso continúe
    }
  }

  // =========== MÉTODOS PARA ELIMINAR CULTOS Y DATOS RELACIONADOS ===========

  // Eliminar un culto y todos sus datos relacionados
  Future<void> deleteCult(String cultId) async {
    try {
      debugPrint('Iniciando eliminación del culto: $cultId y sus datos relacionados');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // 1. Obtener todas las franjas horarias del culto
      final timeSlotSnapshot = await _firestore
          .collection('time_slots')
          .where('entityId', isEqualTo: cultId)
          .where('entityType', isEqualTo: 'cult')
          .get();
      
      // 2. Para cada franja horaria, eliminar sus asignaciones, invitaciones y roles disponibles
      for (final timeSlotDoc in timeSlotSnapshot.docs) {
        final timeSlotId = timeSlotDoc.id;
        debugPrint('Eliminando datos relacionados con la franja horaria: $timeSlotId');
        
        // 2.1 Eliminar asignaciones
        final assignmentsSnapshot = await _firestore
            .collection('work_assignments')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .get();
        
        for (final assignmentDoc in assignmentsSnapshot.docs) {
          await assignmentDoc.reference.delete();
        }
        
        // 2.2 Eliminar invitaciones
        final invitesSnapshot = await _firestore
            .collection('work_invites')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .get();
        
        for (final inviteDoc in invitesSnapshot.docs) {
          await inviteDoc.reference.delete();
        }
        
        // 2.3 Eliminar roles disponibles
        final availableRolesSnapshot = await _firestore
            .collection('available_roles')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .get();
        
        for (final roleDoc in availableRolesSnapshot.docs) {
          await roleDoc.reference.delete();
        }
        
        // 2.4 Eliminar la franja horaria
        await timeSlotDoc.reference.delete();
      }
      
      // 3. Eliminar anuncios del culto
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('cultId', isEqualTo: cultId)
          .where('type', isEqualTo: 'cult')
          .get();
      
      for (final announcementDoc in announcementsSnapshot.docs) {
        await announcementDoc.reference.delete();
      }
      
      // 4. Eliminar canciones del culto
      final songsSnapshot = await _firestore
          .collection('cult_songs')
          .where('cultId', isEqualTo: cultId)
          .get();
      
      for (final songDoc in songsSnapshot.docs) {
        await songDoc.reference.delete();
      }
      
      // 5. Desasignar oraciones del culto
      final prayersSnapshot = await _firestore
          .collection('prayers')
          .where('cultRef', isEqualTo: _firestore.collection('cults').doc(cultId))
          .get();
      
      for (final prayerDoc in prayersSnapshot.docs) {
        await prayerDoc.reference.update({
          'cultRef': FieldValue.delete(),
          'assignedToCultAt': FieldValue.delete(),
          'assignedToCultBy': FieldValue.delete(),
          'cultName': FieldValue.delete(),
        });
      }
      
      // 6. Finalmente, eliminar el culto
      await _firestore.collection('cults').doc(cultId).delete();
      
      debugPrint('Culto y todos sus datos relacionados eliminados correctamente');
    } catch (e) {
      debugPrint('Error al eliminar culto: $e');
      rethrow;
    }
  }
} 