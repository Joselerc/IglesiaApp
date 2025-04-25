import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_stats.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para generar estadísticas de usuarios
  Future<List<UserStats>> generateUserStats({
    String? ministryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      // Mapa para almacenar las estadísticas de los usuarios
      Map<String, Map<String, dynamic>> userStatsMap = {};
      
      // Primero, cargar todos los usuarios
      Query usersQuery = _firestore.collection('users');
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Filtrar por nombre (aproximado)
        usersQuery = usersQuery
            .orderBy('displayName')
            .startAt([searchQuery])
            .endAt([searchQuery + '\uf8ff']);
      }
      
      final usersSnapshot = await usersQuery.get();
      
      // Inicializar las estadísticas para cada usuario
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userId = userDoc.id;
        
        userStatsMap[userId] = {
          'userId': userId,
          'userName': userData['displayName'] ?? 'Usuário sem nome',
          'userPhotoUrl': userData['photoUrl'] ?? '',
          'ministry': '', // Se llenará después si es necesario
          'totalInvitations': 0,
          'totalAttendances': 0,
          'totalAbsences': 0,
          'acceptedInvitations': 0,
          'rejectedInvitations': 0,
          'pendingInvitations': 0,
          'cancelledInvitations': 0,
        };
      }
      
      // Si se especifica un ministerio, filtrar usuarios por ese ministerio
      if (ministryId != null && ministryId != 'all_ministries') {
        // Limpiar el ID del ministerio si viene como ruta
        final cleanMinistryId = ministryId.startsWith('/ministries/') 
            ? ministryId.substring('/ministries/'.length) 
            : ministryId;
        
        try {
          // Obtener miembros del ministerio
          final ministryDoc = await _firestore.collection('ministries').doc(cleanMinistryId).get();
          
          if (ministryDoc.exists) {
            final ministryData = ministryDoc.data() as Map<String, dynamic>;
            final ministryName = ministryData['name'] ?? 'Ministério';
            
            // Verificar si hay campo de miembros
            if (ministryData.containsKey('members') && ministryData['members'] is List) {
              final members = ministryData['members'] as List<dynamic>;
              
              // Nuevo mapa filtrado
              Map<String, Map<String, dynamic>> filteredMap = {};
              
              // Procesar cada miembro
              for (var member in members) {
                String memberId = '';
                
                if (member is DocumentReference) {
                  memberId = member.id;
                } else if (member is String && member.startsWith('/users/')) {
                  memberId = member.substring('/users/'.length);
                } else if (member is String) {
                  memberId = member;
                }
                
                if (memberId.isNotEmpty && userStatsMap.containsKey(memberId)) {
                  // Agregar al mapa filtrado y actualizar el nombre del ministerio
                  filteredMap[memberId] = userStatsMap[memberId]!;
                  filteredMap[memberId]!['ministry'] = ministryName;
                }
              }
              
              // Reemplazar el mapa original con el filtrado
              userStatsMap = filteredMap;
            }
          }
        } catch (e) {
          debugPrint('Error al filtrar por ministerio: $e');
        }
      }
      
      // Si el mapa de usuarios quedó vacío, retornar lista vacía
      if (userStatsMap.isEmpty) {
        return [];
      }
      
      // Ahora, obtener las estadísticas de invitaciones
      Query invitesQuery = _firestore.collection('work_invites');
      
      // Aplicar filtro de fecha si es necesario
      if (startDate != null || endDate != null) {
        // Primero, obtener los cultos en el rango de fecha
        Query cultsQuery = _firestore.collection('cults');
        
        if (startDate != null) {
          cultsQuery = cultsQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        
        if (endDate != null) {
          // Ajustar la fecha final para incluir todo el día
          final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
          cultsQuery = cultsQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate));
        }
        
        final cultsSnapshot = await cultsQuery.get();
        final cultIds = cultsSnapshot.docs.map((doc) => doc.id).toList();
        
        // Si no hay cultos en el rango de fechas, retornar usuarios con estadísticas en cero
        if (cultIds.isEmpty) {
          debugPrint('No hay cultos en el rango de fechas seleccionado. Mostrando usuarios con estadísticas en cero.');
          // Convertir el mapa a lista de UserStats (con valores en cero)
          return _convertToUserStats(userStatsMap);
        }
        
        // Procesar invitaciones para cada culto (en lotes de 10 para respetar límites de Firestore)
        for (int i = 0; i < cultIds.length; i += 10) {
          final end = (i + 10 < cultIds.length) ? i + 10 : cultIds.length;
          final batch = cultIds.sublist(i, end);
          
          final batchInvitesQuery = await _firestore
              .collection('work_invites')
              .where('entityId', whereIn: batch)
              .where('entityType', isEqualTo: 'cult')
              .get();
          
          // Procesar invitaciones
          for (var inviteDoc in batchInvitesQuery.docs) {
            _processInvitation(inviteDoc.data() as Map<String, dynamic>, userStatsMap);
          }
        }
        
        // Obtener los time_slots para estos cultos
        List<String> timeSlotIds = [];
        
        for (var cultId in cultIds) {
          final timeSlotsQuery = await _firestore
              .collection('time_slots')
              .where('entityId', isEqualTo: cultId)
              .where('entityType', isEqualTo: 'cult')
              .get();
          
          timeSlotIds.addAll(timeSlotsQuery.docs.map((doc) => doc.id).toList());
        }
        
        // Si hay time_slots, procesar asignaciones para contar asistencias/ausencias
        if (timeSlotIds.isNotEmpty) {
          for (int i = 0; i < timeSlotIds.length; i += 10) {
            final end = (i + 10 < timeSlotIds.length) ? i + 10 : timeSlotIds.length;
            final batch = timeSlotIds.sublist(i, end);
            
            final assignmentsQuery = await _firestore
                .collection('work_assignments')
                .where('timeSlotId', whereIn: batch)
                .where('isActive', isEqualTo: true)
                .get();
            
            // Procesar asignaciones
            for (var assignmentDoc in assignmentsQuery.docs) {
              _processAssignment(assignmentDoc.data() as Map<String, dynamic>, userStatsMap);
            }
          }
        }
      } else {
        // Si no hay filtro de fecha, obtener todas las invitaciones (con límite para evitar problemas)
        final invitesSnapshot = await _firestore
            .collection('work_invites')
            .where('entityType', isEqualTo: 'cult')
            .limit(1000) // Límite razonable
            .get();
        
        // Procesar invitaciones
        for (var inviteDoc in invitesSnapshot.docs) {
          _processInvitation(inviteDoc.data() as Map<String, dynamic>, userStatsMap);
        }
        
        // Obtener asignaciones para contar asistencias/ausencias
        final assignmentsSnapshot = await _firestore
            .collection('work_assignments')
            .where('isActive', isEqualTo: true)
            .limit(1000) // Límite razonable
            .get();
        
        // Procesar asignaciones
        for (var assignmentDoc in assignmentsSnapshot.docs) {
          _processAssignment(assignmentDoc.data() as Map<String, dynamic>, userStatsMap);
        }
      }
      
      // Convertir el mapa a lista de UserStats
      return _convertToUserStats(userStatsMap);
    } catch (e) {
      debugPrint('Error al generar estadísticas de usuarios: $e');
      return [];
    }
  }

  // Método para procesar una invitación
  void _processInvitation(Map<String, dynamic> data, Map<String, Map<String, dynamic>> userStatsMap) {
    try {
      // Obtener el ID del usuario
      String userId = '';
      
      if (data['userId'] is String && data['userId'].startsWith('/users/')) {
        userId = data['userId'].substring('/users/'.length);
      } else if (data['userId'] is String) {
        userId = data['userId'];
      } else if (data['userId'] is DocumentReference) {
        userId = data['userId'].id;
      }
      
      if (userId.isEmpty || !userStatsMap.containsKey(userId)) {
        return;
      }
      
      // Incrementar contador de invitaciones totales
      userStatsMap[userId]!['totalInvitations'] = 
          (userStatsMap[userId]!['totalInvitations'] as int) + 1;
      
      // Verificar el estado de la invitación
      final status = data['status'] as String? ?? 'pending';
      final isRejected = data['isRejected'] as bool? ?? false;
      
      if (status == 'accepted' || status == 'confirmed') {
        userStatsMap[userId]!['acceptedInvitations'] = 
            (userStatsMap[userId]!['acceptedInvitations'] as int) + 1;
      } else if (status == 'rejected' || isRejected) {
        userStatsMap[userId]!['rejectedInvitations'] = 
            (userStatsMap[userId]!['rejectedInvitations'] as int) + 1;
      } else if (status == 'pending') {
        userStatsMap[userId]!['pendingInvitations'] = 
            (userStatsMap[userId]!['pendingInvitations'] as int) + 1;
      } else if (status == 'cancelled') {
        userStatsMap[userId]!['cancelledInvitations'] = 
            (userStatsMap[userId]!['cancelledInvitations'] as int) + 1;
      }
      
      // Si hay información de ministerio en la invitación, actualizarla
      if (data.containsKey('ministryName') && data['ministryName'] is String &&
          data['ministryName'].isNotEmpty && 
          (userStatsMap[userId]!['ministry'] as String).isEmpty) {
        userStatsMap[userId]!['ministry'] = data['ministryName'];
      }
    } catch (e) {
      debugPrint('Error al procesar invitación: $e');
    }
  }

  // Método para procesar una asignación de trabajo (work_assignment)
  void _processAssignment(Map<String, dynamic> data, Map<String, Map<String, dynamic>> userStatsMap) {
    try {
      // Obtener el ID del usuario
      String userId = '';
      
      if (data['userId'] is String && data['userId'].startsWith('/users/')) {
        userId = data['userId'].substring('/users/'.length);
      } else if (data['userId'] is String) {
        userId = data['userId'];
      } else if (data['userId'] is DocumentReference) {
        userId = data['userId'].id;
      }
      
      if (userId.isEmpty || !userStatsMap.containsKey(userId)) {
        return;
      }
      
      // Verificar asistencia o ausencia
      final isAttendanceConfirmed = data['isAttendanceConfirmed'] as bool? ?? false;
      final didNotAttend = data['didNotAttend'] as bool? ?? false;
      
      if (isAttendanceConfirmed) {
        userStatsMap[userId]!['totalAttendances'] = 
            (userStatsMap[userId]!['totalAttendances'] as int) + 1;
      }
      
      if (didNotAttend) {
        userStatsMap[userId]!['totalAbsences'] = 
            (userStatsMap[userId]!['totalAbsences'] as int) + 1;
      }
      
      // Si hay información de ministerio en la asignación, actualizarla
      if (data.containsKey('ministryName') && data['ministryName'] is String &&
          data['ministryName'].isNotEmpty && 
          (userStatsMap[userId]!['ministry'] as String).isEmpty) {
        userStatsMap[userId]!['ministry'] = data['ministryName'];
      }
    } catch (e) {
      debugPrint('Error al procesar asignación: $e');
    }
  }

  // Método para convertir el mapa a lista de UserStats
  List<UserStats> _convertToUserStats(Map<String, Map<String, dynamic>> userStatsMap) {
    return userStatsMap.values.map((data) => UserStats(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userPhotoUrl: data['userPhotoUrl'] as String,
      ministry: data['ministry'] as String,
      totalInvitations: data['totalInvitations'] as int,
      totalAttendances: data['totalAttendances'] as int,
      totalAbsences: data['totalAbsences'] as int,
      acceptedInvitations: data['acceptedInvitations'] as int,
      rejectedInvitations: data['rejectedInvitations'] as int,
      pendingInvitations: data['pendingInvitations'] as int,
      cancelledInvitations: data['cancelledInvitations'] as int,
    )).toList();
  }

  // Método para obtener los ministerios disponibles
  Future<List<Map<String, dynamic>>> getAvailableMinistries() async {
    try {
      List<Map<String, dynamic>> ministries = [
        {
          'id': 'all_ministries',
          'name': 'Todos os Ministérios',
        }
      ];
      
      final ministriesSnapshot = await _firestore.collection('ministries').get();
      
      for (var doc in ministriesSnapshot.docs) {
        final data = doc.data();
        ministries.add({
          'id': doc.id,
          'name': data['name'] ?? 'Ministério sem nome',
        });
      }
      
      return ministries;
    } catch (e) {
      debugPrint('Error al obtener ministerios: $e');
      return [
        {
          'id': 'all_ministries',
          'name': 'Todos os Ministérios',
        }
      ];
    }
  }
} 