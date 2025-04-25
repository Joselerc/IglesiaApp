import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/event_attendance.dart';
import '../models/user_attendance_stats.dart';
import '../models/user_work_stats.dart';

class EventAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'event_attendance';

  // Método para verificar si un usuario es líder de un grupo o ministerio
  Future<bool> isUserLeader({
    required String entityId,
    required String entityType, // 'ministry' o 'group'
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final collection = entityType == 'ministry' ? 'ministries' : 'groups';
      final doc = await _firestore.collection(collection).doc(entityId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      
      // Usar el campo correcto según el tipo de entidad
      final String adminField = entityType == 'ministry' ? 'ministrieAdmin' : 'groupAdmin';
      
      // Verificar si el campo existe y es una lista
      if (!data.containsKey(adminField) || !(data[adminField] is List)) {
        return false;
      }
      
      final List<dynamic> admins = data[adminField];
      
      // Buscar si el usuario está en la lista de administradores
      for (var admin in admins) {
        String adminId = '';
        
        // Si es una referencia de documento, extraer el ID
        if (admin is DocumentReference) {
          adminId = admin.id;
        } else {
          adminId = admin.toString();
        }
        
        if (adminId == currentUser.uid) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error al verificar si es líder: $e');
      return false;
    }
  }

  // Método para marcar la asistencia real de un usuario a un evento
  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String eventType,
    required String entityId,
    required bool attended,
    String? notes,
    bool wasExpected = true,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Usuario no autenticado');

    // Verificar si el usuario actual es líder
    final isLeader = await isUserLeader(
      entityId: entityId,
      entityType: eventType,
    );

    if (!isLeader) {
      throw Exception('No tienes permisos para gestionar la asistencia');
    }

    // Crear o actualizar registro de asistencia
    final docId = '${eventId}_${userId}';
    
    await _firestore.collection(_collection).doc(docId).set({
      'eventId': eventId,
      'userId': userId,
      'eventType': eventType,
      'entityId': entityId,
      'attended': attended,
      'verificationDate': FieldValue.serverTimestamp(),
      'verifiedBy': currentUser.uid,
      'notes': notes,
      'wasExpected': wasExpected,
    }, SetOptions(merge: true));
  }

  // Obtener la asistencia de un evento específico
  Stream<List<EventAttendance>> getEventAttendance(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventAttendance.fromFirestore(doc))
          .toList();
    });
  }

  // Obtener eventos liderados por el usuario actual (de sus grupos/ministerios)
  Future<List<Map<String, dynamic>>> getUserLedEvents() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<Map<String, dynamic>> results = [];

    try {
      // Cargar todos los ministerios primero
      final ministries = await _firestore.collection('ministries').get();
      
      // Filtrar los ministerios donde el usuario es admin manualmente
      for (var ministry in ministries.docs) {
        final ministryData = ministry.data();
        final String adminField = 'ministrieAdmin';
        
        if (ministryData.containsKey(adminField) && ministryData[adminField] is List) {
          bool isAdmin = false;
          final List<dynamic> admins = ministryData[adminField];
          
          for (var admin in admins) {
            String adminId = '';
            
            // Si es una referencia de documento, extraer el ID
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          // Si es admin, cargar los eventos
          if (isAdmin) {
            final ministryEvents = await _firestore
                .collection('ministry_events')
                .where('ministryId', isEqualTo: _firestore.collection('ministries').doc(ministry.id))
                .orderBy('date', descending: true)
                .get();

            for (var event in ministryEvents.docs) {
              final eventData = event.data();
              results.add({
                'id': event.id,
                'title': eventData['title'] ?? 'Sin título',
                'date': (eventData['date'] as Timestamp).toDate(),
                'entityId': ministry.id,
                'entityName': ministryData['name'] ?? 'Ministerio',
                'entityType': 'ministry',
                'imageUrl': eventData['imageUrl'] ?? '',
              });
            }
          }
        }
      }

      // Cargar todos los grupos primero
      final groups = await _firestore.collection('groups').get();
      
      // Filtrar los grupos donde el usuario es admin manualmente
      for (var group in groups.docs) {
        final groupData = group.data();
        final String adminField = 'groupAdmin';
        
        if (groupData.containsKey(adminField) && groupData[adminField] is List) {
          bool isAdmin = false;
          final List<dynamic> admins = groupData[adminField];
          
          for (var admin in admins) {
            String adminId = '';
            
            // Si es una referencia de documento, extraer el ID
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          // Si es admin, cargar los eventos
          if (isAdmin) {
            final groupEvents = await _firestore
                .collection('group_events')
                .where('groupId', isEqualTo: _firestore.collection('groups').doc(group.id))
                .orderBy('date', descending: true)
                .get();

            for (var event in groupEvents.docs) {
              final eventData = event.data();
              results.add({
                'id': event.id,
                'title': eventData['title'] ?? 'Sin título',
                'date': (eventData['date'] as Timestamp).toDate(),
                'entityId': group.id,
                'entityName': groupData['name'] ?? 'Grupo',
                'entityType': 'group',
                'imageUrl': eventData['imageUrl'] ?? '',
              });
            }
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error al obtener eventos liderados: $e');
      return [];
    }
  }

  // Generar estadísticas de trabajo para usuarios de ministerios
  Future<List<UserWorkStats>> generateWorkStats({
    required String ministryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 Generando estadísticas de trabajo para ministerio: $ministryId');
      
      // Si es 'all', generar estadísticas para todos los ministerios del líder
      final bool isAllMinistries = ministryId == 'all_ministries';
      
      // Lista de IDs de ministerios a consultar
      List<String> ministryIds = [];
      
      if (isAllMinistries) {
        // Obtener todos los ministerios donde el usuario es líder
        final currentUser = _auth.currentUser;
        if (currentUser == null) return [];
        
        final ministries = await _firestore.collection('ministries').get();
        
        // Filtrar ministerios donde es líder
        for (var ministry in ministries.docs) {
          final data = ministry.data();
          final String adminField = 'ministrieAdmin';
          
          if (data.containsKey(adminField) && data[adminField] is List) {
            final List<dynamic> admins = data[adminField];
            bool isAdmin = false;
            
            for (var admin in admins) {
              String adminId = '';
              if (admin is DocumentReference) {
                adminId = admin.id;
              } else {
                adminId = admin.toString();
              }
              
              if (adminId == currentUser.uid) {
                isAdmin = true;
                break;
              }
            }
            
            if (isAdmin) {
              ministryIds.add(ministry.id);
            }
          }
        }
      } else {
        // Solo usar el ministerio especificado
        ministryIds.add(ministryId);
      }
      
      // Si no hay ministerios, retornar lista vacía
      if (ministryIds.isEmpty) {
        debugPrint('⚠️ No se encontraron ministerios para las estadísticas de trabajo');
        return [];
      }
      
      debugPrint('📋 Ministerios encontrados para estadísticas: ${ministryIds.length}');
      
      // Obtener a todos los miembros de los ministerios utilizando _getMemberIdsForEntity
      Set<String> allMemberIds = {};
      
      for (var minId in ministryIds) {
        // Usar nuestro método auxiliar para obtener todos los miembros del ministerio
        List<String> ministryMembers = await _getMemberIdsForEntity(minId, 'ministry');
        
        // Agregar los miembros al conjunto total
        for (var memberId in ministryMembers) {
          allMemberIds.add(memberId);
        }
      }
      
      debugPrint('📋 Total de miembros encontrados en todos los ministerios: ${allMemberIds.length}');
      
      // Si no hay miembros, retornar lista vacía
      if (allMemberIds.isEmpty) {
        debugPrint('⚠️ No se encontraron miembros en los ministerios');
        return [];
      }
      
      // Preparar mapa para estadísticas de usuarios
      Map<String, Map<String, dynamic>> userStats = {};
      
      // Inicializar estadísticas para cada miembro
      for (var userId in allMemberIds) {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};
        
        userStats[userId] = {
          'userId': userId,
          'userName': userData['displayName'] ?? 'Usuario',
          'userPhotoUrl': userData['photoUrl'] ?? '',
          'totalInvitations': 0,
          'acceptedJobs': 0,
          'rejectedJobs': 0,
          'pendingJobs': 0,
          'lastWorkDate': null,
          'recentJobIds': <String>[],
        };
      }
      
      // Consulta base para horarios de trabajo
      Query workSchedulesQuery = _firestore.collection('work_schedules');
      
      // Filtrar por ministerio(s)
      if (ministryIds.length == 1) {
        workSchedulesQuery = workSchedulesQuery.where('ministryId', isEqualTo: ministryIds.first);
      } else {
        workSchedulesQuery = workSchedulesQuery.where('ministryId', whereIn: ministryIds);
      }
      
      // Aplicar filtros de fecha si están presentes
      if (startDate != null) {
        workSchedulesQuery = workSchedulesQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        workSchedulesQuery = workSchedulesQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Ejecutar consulta de horarios
      final scheduleSnapshot = await workSchedulesQuery.get();
      debugPrint('📋 Total de horarios de trabajo encontrados: ${scheduleSnapshot.docs.length}');
      
      // Procesar cada horario de trabajo
      for (var scheduleDoc in scheduleSnapshot.docs) {
        final data = scheduleDoc.data() as Map<String, dynamic>;
        
        // Obtener workers status
        final Map<String, dynamic> rawWorkersStatus = data['workersStatus'] ?? {};
        
        // Procesar cada trabajador
        for (var entry in rawWorkersStatus.entries) {
          final String userPath = entry.key;
          final String userId = userPath.split('/').last;
          final String status = entry.value;
          
          // Si este usuario está en nuestro conjunto de miembros
          if (userStats.containsKey(userId)) {
            userStats[userId]!['totalInvitations'] = (userStats[userId]!['totalInvitations'] as int) + 1;
            
            if (status == 'accepted') {
              userStats[userId]!['acceptedJobs'] = (userStats[userId]!['acceptedJobs'] as int) + 1;
              
              // Obtener fecha del trabajo
              final workDate = (data['date'] as Timestamp).toDate();
              
              // Actualizar última fecha de trabajo
              final currentLastWorkDate = userStats[userId]!['lastWorkDate'] as DateTime?;
              if (currentLastWorkDate == null || workDate.isAfter(currentLastWorkDate)) {
                userStats[userId]!['lastWorkDate'] = workDate;
              }
              
              // Agregar a trabajos recientes
              (userStats[userId]!['recentJobIds'] as List<String>).add(scheduleDoc.id);
              if ((userStats[userId]!['recentJobIds'] as List<String>).length > 5) {
                (userStats[userId]!['recentJobIds'] as List<String>).removeAt(0);
              }
            } else if (status == 'rejected') {
              userStats[userId]!['rejectedJobs'] = (userStats[userId]!['rejectedJobs'] as int) + 1;
            } else if (status == 'pending') {
              userStats[userId]!['pendingJobs'] = (userStats[userId]!['pendingJobs'] as int) + 1;
            }
          }
        }
      }
      
      // Convertir el mapa a lista de UserWorkStats
      List<UserWorkStats> result = [];
      for (var entry in userStats.entries) {
        final stats = entry.value;
        final totalInvitations = stats['totalInvitations'] as int;
        final acceptedJobs = stats['acceptedJobs'] as int;
        
        // Incluir solo usuarios que tienen al menos una invitación
        if (totalInvitations > 0) {
          // Calcular tasa de aceptación
          final acceptanceRate = acceptedJobs > 0 ? (acceptedJobs / totalInvitations) * 100 : 0.0;
          
          result.add(UserWorkStats(
            userId: stats['userId'] as String,
            userName: stats['userName'] as String,
            userPhotoUrl: stats['userPhotoUrl'] as String,
            totalInvitations: totalInvitations,
            acceptedJobs: acceptedJobs,
            rejectedJobs: stats['rejectedJobs'] as int,
            pendingJobs: stats['pendingJobs'] as int,
            acceptanceRate: acceptanceRate,
            lastWorkDate: stats['lastWorkDate'] as DateTime? ?? DateTime(2000),
            recentJobIds: stats['recentJobIds'] as List<String>?,
          ));
        }
      }
      
      debugPrint('✅ Total de estadísticas de trabajo generadas: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Error al generar estadísticas de trabajo: $e');
      return [];
    }
  }

  // Generar estadísticas de asistencia para un grupo/ministerio
  Future<List<UserAttendanceStats>> generateAttendanceStats({
    required String entityId,
    required String entityType,
    DateTime? startDate,
    DateTime? endDate,
    bool showOnlyMembers = true,
  }) async {
    try {
      // Casos especiales para estadísticas generales
      if (entityType == 'all') {
        return await _generateGeneralStats(startDate, endDate);
      } else if (entityType == 'all_ministries') {
        return await _generateMinistryStats(startDate, endDate);
      } else if (entityType == 'all_groups') {
        return await _generateGroupStats(startDate, endDate);
      }
      
      debugPrint('🔍 Generando estadísticas para ${entityType} con ID: ${entityId}');
      
      // Obtener los miembros de la entidad
      final collection = entityType == 'ministry' ? 'ministries' : 'groups';
      final entityDoc = await _firestore.collection(collection).doc(entityId).get();
      
      if (!entityDoc.exists) {
        debugPrint('❌ La entidad no existe');
        return [];
      }
      
      final data = entityDoc.data()!;
      debugPrint('📋 Datos de la entidad: ${data['name']}');
      
      // Lista para almacenar IDs de miembros
      List<String> memberIdsList = [];
      
      // Verificar diferentes campos posibles para miembros
      List<String> possibleMemberFields = [
        'memberIds',
        'members',
        'membersIds',
        'groupMembers',
        'ministryMembers'
      ];
      
      // Buscar en colecciones específicas primero (método más preciso)
      try {
        // Para ministerios
        if (entityType == 'ministry') {
          final ministryMembersSnapshot = await _firestore
              .collection('ministry_members')
              .where('ministryId', isEqualTo: entityId)
              .get();
          
          if (ministryMembersSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Encontrados ${ministryMembersSnapshot.docs.length} miembros en ministry_members');
            
            for (var doc in ministryMembersSnapshot.docs) {
              final userId = doc.data()['userId'] as String?;
              if (userId != null && !memberIdsList.contains(userId)) {
                memberIdsList.add(userId);
              }
            }
          }
        } 
        // Para grupos
        else if (entityType == 'group') {
          final groupMembersSnapshot = await _firestore
              .collection('group_members')
              .where('groupId', isEqualTo: entityId)
              .get();
          
          if (groupMembersSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Encontrados ${groupMembersSnapshot.docs.length} miembros en group_members');
            
            for (var doc in groupMembersSnapshot.docs) {
              final userId = doc.data()['userId'] as String?;
              if (userId != null && !memberIdsList.contains(userId)) {
                memberIdsList.add(userId);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error al buscar en colecciones específicas: $e');
      }
      
      // Si no se encontraron miembros en las colecciones específicas, 
      // buscar en campos directos de la entidad
      if (memberIdsList.isEmpty) {
        debugPrint('🔍 Buscando en campos directos del documento');
        
        for (var field in possibleMemberFields) {
          if (data.containsKey(field)) {
            final membersData = data[field];
            
            if (membersData is List) {
              debugPrint('✅ Campo encontrado: $field con ${membersData.length} elementos');
              
              // Recorrer la lista y extraer IDs
              for (var member in membersData) {
                String memberId = '';
                
                // Manejar diferentes formatos (DocumentReference o String)
                if (member is DocumentReference) {
                  memberId = member.id;
                } else {
                  memberId = member.toString();
                }
                
                if (!memberIdsList.contains(memberId)) {
                  memberIdsList.add(memberId);
                }
              }
              
              break; // Usar el primer campo encontrado
            }
          }
        }
      }
      
      debugPrint('📋 Total de IDs de miembros encontrados: ${memberIdsList.length}');
      
      // Si no se encontraron miembros después de buscar en todos lados, mostrar advertencia
      if (memberIdsList.isEmpty) {
        debugPrint('⚠️ No se encontraron miembros después de revisar todos los campos');
      }
      
      // Preparar mapa para estadísticas de usuarios
      Map<String, Map<String, dynamic>> userStats = {};
      
      // Si solo queremos mostrar miembros, inicializar estadísticas solo para miembros
      if (showOnlyMembers) {
        // Inicializar estadísticas para cada miembro
        for (var userId in memberIdsList) {
          // Obtener datos del usuario
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data() ?? {};
          
          userStats[userId] = {
            'userId': userId,
            'userName': userData['displayName'] ?? 'Usuario',
            'userPhotoUrl': userData['photoUrl'] ?? '',
            'totalEvents': 0,
            'eventsAttended': 0,
            'lastAttendance': null,
            'recentEventIds': <String>[],
          };
        }
      }
      
      // Consulta base para eventos
      Query eventsQuery;
      if (entityType == 'ministry') {
        eventsQuery = _firestore
            .collection('ministry_events')
            .where('ministryId', isEqualTo: _firestore.collection('ministries').doc(entityId));
      } else {
        eventsQuery = _firestore
            .collection('group_events')
            .where('groupId', isEqualTo: _firestore.collection('groups').doc(entityId));
      }
      
      // Aplicar filtros de fecha si están presentes
      if (startDate != null) {
        eventsQuery = eventsQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        eventsQuery = eventsQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Ejecutar consulta de eventos
      final eventsSnapshot = await eventsQuery.get();
      debugPrint('📋 Total de eventos encontrados: ${eventsSnapshot.docs.length}');
      
      // Obtener asistencia para cada evento
      for (var eventDoc in eventsSnapshot.docs) {
        final eventId = eventDoc.id;
        
        // Obtener registros de asistencia para este evento
        final attendanceSnapshot = await _firestore
            .collection(_collection)
            .where('eventId', isEqualTo: eventId)
            .get();
        
        // Procesar asistencia
        for (var attendanceDoc in attendanceSnapshot.docs) {
          final attendance = EventAttendance.fromFirestore(attendanceDoc);
          final userId = attendance.userId;
          
          // Si queremos mostrar solo miembros, verificar que el usuario esté en la lista
          if (showOnlyMembers) {
            // Si este usuario es miembro, actualizar sus estadísticas
            if (userStats.containsKey(userId)) {
              userStats[userId]!['totalEvents'] = (userStats[userId]!['totalEvents'] as int) + 1;
              
              if (attendance.attended) {
                userStats[userId]!['eventsAttended'] = (userStats[userId]!['eventsAttended'] as int) + 1;
                
                // Actualizar última fecha de asistencia
                final currentLastAttendance = userStats[userId]!['lastAttendance'] as DateTime?;
                if (currentLastAttendance == null || 
                    attendance.verificationDate.isAfter(currentLastAttendance)) {
                  userStats[userId]!['lastAttendance'] = attendance.verificationDate;
                }
                
                // Agregar a eventos recientes
                (userStats[userId]!['recentEventIds'] as List<String>).add(eventId);
                if ((userStats[userId]!['recentEventIds'] as List<String>).length > 5) {
                  (userStats[userId]!['recentEventIds'] as List<String>).removeAt(0);
                }
              }
            }
          } else {
            // Si no hay restricción de miembros, inicializar estadísticas para este usuario si no existe
            if (!userStats.containsKey(userId)) {
              // Obtener datos del usuario
              final userDoc = await _firestore.collection('users').doc(userId).get();
              final userData = userDoc.data() ?? {};
              
              userStats[userId] = {
                'userId': userId,
                'userName': userData['displayName'] ?? 'Usuario',
                'userPhotoUrl': userData['photoUrl'] ?? '',
                'totalEvents': 0,
                'eventsAttended': 0,
                'lastAttendance': null,
                'recentEventIds': <String>[],
              };
            }
            
            // Actualizar estadísticas
            userStats[userId]!['totalEvents'] = (userStats[userId]!['totalEvents'] as int) + 1;
            
            if (attendance.attended) {
              userStats[userId]!['eventsAttended'] = (userStats[userId]!['eventsAttended'] as int) + 1;
              
              // Actualizar última fecha de asistencia
              final currentLastAttendance = userStats[userId]!['lastAttendance'] as DateTime?;
              if (currentLastAttendance == null || 
                  attendance.verificationDate.isAfter(currentLastAttendance)) {
                userStats[userId]!['lastAttendance'] = attendance.verificationDate;
              }
              
              // Agregar a eventos recientes
              (userStats[userId]!['recentEventIds'] as List<String>).add(eventId);
              if ((userStats[userId]!['recentEventIds'] as List<String>).length > 5) {
                (userStats[userId]!['recentEventIds'] as List<String>).removeAt(0);
              }
            }
          }
        }
      }
      
      // Convertir el mapa a lista de UserAttendanceStats
      List<UserAttendanceStats> result = [];
      for (var entry in userStats.entries) {
        final stats = entry.value;
        final totalEvents = stats['totalEvents'] as int;
        final eventsAttended = stats['eventsAttended'] as int;
        
        // Calcular tasa de asistencia
        final attendanceRate = totalEvents > 0 ? (eventsAttended / totalEvents) * 100 : 0.0;
        
        result.add(UserAttendanceStats(
          userId: stats['userId'] as String,
          userName: stats['userName'] as String,
          userPhotoUrl: stats['userPhotoUrl'] as String,
          totalEvents: totalEvents,
          eventsAttended: eventsAttended,
          attendanceRate: attendanceRate,
          lastAttendance: stats['lastAttendance'] as DateTime? ?? DateTime(2000),
          recentEventIds: stats['recentEventIds'] as List<String>?,
        ));
      }
      
      debugPrint('✅ Total de estadísticas generadas: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Error al generar estadísticas: $e');
      return [];
    }
  }
  
  // Método para generar estadísticas generales de todos los grupos y ministerios
  Future<List<UserAttendanceStats>> _generateGeneralStats(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      debugPrint('🔍 Generando estadísticas generales de todos los grupos y ministerios');
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];
      
      // Obtener todos los grupos y ministerios donde el usuario es líder
      final ministries = await _firestore.collection('ministries').get();
      final groups = await _firestore.collection('groups').get();
      
      List<Map<String, dynamic>> ledEntities = [];
      
      // Filtrar ministerios donde es líder
      for (var ministry in ministries.docs) {
        final data = ministry.data();
        final String adminField = 'ministrieAdmin';
        
        if (data.containsKey(adminField) && data[adminField] is List) {
          final List<dynamic> admins = data[adminField];
          bool isAdmin = false;
          
          for (var admin in admins) {
            String adminId = '';
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          if (isAdmin) {
            // Recolectar los IDs de miembros usando la nueva lógica
            List<String> memberIds = await _getMemberIdsForEntity(ministry.id, 'ministry');
            
            ledEntities.add({
              'id': ministry.id,
              'type': 'ministry',
              'memberIds': memberIds,
              'name': data['name'] ?? 'Ministerio sin nombre',
            });
          }
        }
      }
      
      // Filtrar grupos donde es líder
      for (var group in groups.docs) {
        final data = group.data();
        final String adminField = 'groupAdmin';
        
        if (data.containsKey(adminField) && data[adminField] is List) {
          final List<dynamic> admins = data[adminField];
          bool isAdmin = false;
          
          for (var admin in admins) {
            String adminId = '';
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          if (isAdmin) {
            // Recolectar los IDs de miembros usando la nueva lógica
            List<String> memberIds = await _getMemberIdsForEntity(group.id, 'group');
            
            ledEntities.add({
              'id': group.id,
              'type': 'group',
              'memberIds': memberIds,
              'name': data['name'] ?? 'Grupo sin nombre',
            });
          }
        }
      }
      
      // Si no lidera ninguna entidad, retornar lista vacía
      if (ledEntities.isEmpty) {
        debugPrint('⚠️ No se encontraron entidades lideradas por el usuario');
        return [];
      }
      
      // Recopilar todos los miembros únicos
      Set<String> allMemberIds = {};
      Map<String, String> memberEntityNames = {}; // Para guardar a qué entidades pertenece cada usuario
      
      for (var entity in ledEntities) {
        final entityType = (entity['type'] == 'ministry') ? 'Min: ' : 'Grp: ';
        final entityName = entityType + (entity['name'] as String);
        
        for (var memberId in entity['memberIds']) {
          String id = memberId.toString();
          allMemberIds.add(id);
          
          // Guardar o actualizar el nombre de la entidad a la que pertenece
          if (memberEntityNames.containsKey(id)) {
            memberEntityNames[id] = "${memberEntityNames[id]}, $entityName";
          } else {
            memberEntityNames[id] = entityName;
          }
        }
      }
      
      debugPrint('📋 Total de miembros encontrados: ${allMemberIds.length}');
      
      // Preparar mapa para estadísticas de usuarios
      Map<String, Map<String, dynamic>> userStats = {};
      
      // Inicializar estadísticas para cada miembro
      for (var userId in allMemberIds) {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};
        
        userStats[userId] = {
          'userId': userId,
          'userName': userData['displayName'] ?? 'Usuario',
          'userPhotoUrl': userData['photoUrl'] ?? '',
          'totalEvents': 0,
          'eventsAttended': 0,
          'lastAttendance': null,
          'recentEventIds': <String>[],
          'entityName': memberEntityNames[userId] ?? '',
        };
      }
      
      // Recorrer cada entidad y obtener sus eventos
      for (var entity in ledEntities) {
        // Consulta de eventos
        Query eventsQuery;
        if (entity['type'] == 'ministry') {
          eventsQuery = _firestore
              .collection('ministry_events')
              .where('ministryId', isEqualTo: _firestore.collection('ministries').doc(entity['id']));
        } else {
          eventsQuery = _firestore
              .collection('group_events')
              .where('groupId', isEqualTo: _firestore.collection('groups').doc(entity['id']));
        }
        
        // Aplicar filtros de fecha si están presentes
        if (startDate != null) {
          eventsQuery = eventsQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        
        if (endDate != null) {
          eventsQuery = eventsQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }
        
        // Ejecutar consulta de eventos
        final eventsSnapshot = await eventsQuery.get();
        
        // Obtener asistencia para cada evento
        for (var eventDoc in eventsSnapshot.docs) {
          final eventId = eventDoc.id;
          
          // Obtener registros de asistencia para este evento
          final attendanceSnapshot = await _firestore
              .collection(_collection)
              .where('eventId', isEqualTo: eventId)
              .get();
          
          // Procesar asistencia
          for (var attendanceDoc in attendanceSnapshot.docs) {
            final attendance = EventAttendance.fromFirestore(attendanceDoc);
            final userId = attendance.userId;
            
            // Si este usuario está en nuestro conjunto de miembros
            if (userStats.containsKey(userId)) {
              userStats[userId]!['totalEvents'] = (userStats[userId]!['totalEvents'] as int) + 1;
              
              if (attendance.attended) {
                userStats[userId]!['eventsAttended'] = (userStats[userId]!['eventsAttended'] as int) + 1;
                
                // Actualizar última fecha de asistencia
                final currentLastAttendance = userStats[userId]!['lastAttendance'] as DateTime?;
                if (currentLastAttendance == null || 
                    attendance.verificationDate.isAfter(currentLastAttendance)) {
                  userStats[userId]!['lastAttendance'] = attendance.verificationDate;
                }
                
                // Agregar a eventos recientes
                (userStats[userId]!['recentEventIds'] as List<String>).add(eventId);
                if ((userStats[userId]!['recentEventIds'] as List<String>).length > 5) {
                  (userStats[userId]!['recentEventIds'] as List<String>).removeAt(0);
                }
              }
            }
          }
        }
      }
      
      // Convertir el mapa a lista de UserAttendanceStats
      List<UserAttendanceStats> result = [];
      for (var entry in userStats.entries) {
        final stats = entry.value;
        final totalEvents = stats['totalEvents'] as int;
        final eventsAttended = stats['eventsAttended'] as int;
        
        // Calcular tasa de asistencia
        final attendanceRate = totalEvents > 0 ? (eventsAttended / totalEvents) * 100 : 0.0;
        
        result.add(UserAttendanceStats(
          userId: stats['userId'] as String,
          userName: stats['userName'] as String,
          userPhotoUrl: stats['userPhotoUrl'] as String,
          totalEvents: totalEvents,
          eventsAttended: eventsAttended,
          attendanceRate: attendanceRate,
          lastAttendance: stats['lastAttendance'] as DateTime? ?? DateTime(2000),
          recentEventIds: stats['recentEventIds'] as List<String>?,
          entityName: stats['entityName'] as String? ?? '',
        ));
      }
      
      debugPrint('✅ Total de estadísticas generadas: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Error al generar estadísticas generales: $e');
      return [];
    }
  }

  // Método para generar estadísticas específicas de todos los ministerios
  Future<List<UserAttendanceStats>> _generateMinistryStats(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      debugPrint('🔍 Generando estadísticas para todos los ministerios');
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];
      
      // Obtener todos los ministerios donde el usuario es líder
      final ministries = await _firestore.collection('ministries').get();
      
      List<Map<String, dynamic>> ledEntities = [];
      
      // Filtrar ministerios donde es líder
      for (var ministry in ministries.docs) {
        final data = ministry.data();
        final String adminField = 'ministrieAdmin';
        
        if (data.containsKey(adminField) && data[adminField] is List) {
          final List<dynamic> admins = data[adminField];
          bool isAdmin = false;
          
          for (var admin in admins) {
            String adminId = '';
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          if (isAdmin) {
            // Recolectar los IDs de miembros usando la nueva lógica
            List<String> memberIds = await _getMemberIdsForEntity(ministry.id, 'ministry');
            
            ledEntities.add({
              'id': ministry.id,
              'type': 'ministry',
              'memberIds': memberIds,
              'name': data['name'] ?? 'Ministerio sin nombre',
            });
          }
        }
      }
      
      // Si no lidera ningún ministerio, retornar lista vacía
      if (ledEntities.isEmpty) {
        debugPrint('⚠️ No se encontraron ministerios liderados por el usuario');
        return [];
      }
      
      // Recopilar todos los miembros únicos de ministerios
      Set<String> allMemberIds = {};
      Map<String, String> memberEntityNames = {}; // Para guardar a qué ministerio(s) pertenece cada usuario
      
      for (var entity in ledEntities) {
        final entityName = entity['name'] as String;
        for (var memberId in entity['memberIds']) {
          String id = memberId.toString();
          allMemberIds.add(id);
          
          // Guardar o actualizar el nombre de la entidad a la que pertenece
          if (memberEntityNames.containsKey(id)) {
            memberEntityNames[id] = "${memberEntityNames[id]}, $entityName";
          } else {
            memberEntityNames[id] = entityName;
          }
        }
      }
      
      // Preparar mapa para estadísticas de usuarios
      Map<String, Map<String, dynamic>> userStats = {};
      
      // Inicializar estadísticas para cada miembro
      for (var userId in allMemberIds) {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};
        
        userStats[userId] = {
          'userId': userId,
          'userName': userData['displayName'] ?? 'Usuario',
          'userPhotoUrl': userData['photoUrl'] ?? '',
          'totalEvents': 0,
          'eventsAttended': 0,
          'lastAttendance': null,
          'recentEventIds': <String>[],
          'entityName': memberEntityNames[userId] ?? '',
        };
      }
      
      debugPrint('📋 Miembros encontrados en ministerios: ${allMemberIds.length}');
      
      // Recorrer cada ministerio y obtener sus eventos
      for (var entity in ledEntities) {
        // Consulta de eventos
        Query eventsQuery = _firestore
            .collection('ministry_events')
            .where('ministryId', isEqualTo: _firestore.collection('ministries').doc(entity['id']));
        
        // Aplicar filtros de fecha si están presentes
        if (startDate != null) {
          eventsQuery = eventsQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        
        if (endDate != null) {
          eventsQuery = eventsQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }
        
        // Ejecutar consulta de eventos
        final eventsSnapshot = await eventsQuery.get();
        
        // Obtener asistencia para cada evento
        for (var eventDoc in eventsSnapshot.docs) {
          final eventId = eventDoc.id;
          
          // Obtener registros de asistencia para este evento
          final attendanceSnapshot = await _firestore
              .collection(_collection)
              .where('eventId', isEqualTo: eventId)
              .get();
          
          // Procesar asistencia
          for (var attendanceDoc in attendanceSnapshot.docs) {
            final attendance = EventAttendance.fromFirestore(attendanceDoc);
            final userId = attendance.userId;
            
            // Si este usuario está en nuestro conjunto de miembros
            if (userStats.containsKey(userId)) {
              userStats[userId]!['totalEvents'] = (userStats[userId]!['totalEvents'] as int) + 1;
              
              if (attendance.attended) {
                userStats[userId]!['eventsAttended'] = (userStats[userId]!['eventsAttended'] as int) + 1;
                
                // Actualizar última fecha de asistencia
                final currentLastAttendance = userStats[userId]!['lastAttendance'] as DateTime?;
                if (currentLastAttendance == null || 
                    attendance.verificationDate.isAfter(currentLastAttendance)) {
                  userStats[userId]!['lastAttendance'] = attendance.verificationDate;
                }
                
                // Agregar a eventos recientes
                (userStats[userId]!['recentEventIds'] as List<String>).add(eventId);
                if ((userStats[userId]!['recentEventIds'] as List<String>).length > 5) {
                  (userStats[userId]!['recentEventIds'] as List<String>).removeAt(0);
                }
              }
            }
          }
        }
      }
      
      // Convertir el mapa a lista de UserAttendanceStats
      List<UserAttendanceStats> result = [];
      for (var entry in userStats.entries) {
        final stats = entry.value;
        final totalEvents = stats['totalEvents'] as int;
        final eventsAttended = stats['eventsAttended'] as int;
        
        // Calcular tasa de asistencia
        final attendanceRate = totalEvents > 0 ? (eventsAttended / totalEvents) * 100 : 0.0;
        
        result.add(UserAttendanceStats(
          userId: stats['userId'] as String,
          userName: stats['userName'] as String,
          userPhotoUrl: stats['userPhotoUrl'] as String,
          totalEvents: totalEvents,
          eventsAttended: eventsAttended,
          attendanceRate: attendanceRate,
          lastAttendance: stats['lastAttendance'] as DateTime? ?? DateTime(2000),
          recentEventIds: stats['recentEventIds'] as List<String>?,
          entityName: stats['entityName'] as String? ?? '',
        ));
      }
      
      debugPrint('✅ Total de estadísticas generadas: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Error al generar estadísticas de ministerios: $e');
      return [];
    }
  }
  
  // Método para generar estadísticas específicas de todos los grupos
  Future<List<UserAttendanceStats>> _generateGroupStats(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      debugPrint('🔍 Generando estadísticas para todos los grupos');
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];
      
      // Obtener todos los grupos donde el usuario es líder
      final groups = await _firestore.collection('groups').get();
      
      List<Map<String, dynamic>> ledEntities = [];
      
      // Filtrar grupos donde es líder
      for (var group in groups.docs) {
        final data = group.data();
        final String adminField = 'groupAdmin';
        
        if (data.containsKey(adminField) && data[adminField] is List) {
          final List<dynamic> admins = data[adminField];
          bool isAdmin = false;
          
          for (var admin in admins) {
            String adminId = '';
            if (admin is DocumentReference) {
              adminId = admin.id;
            } else {
              adminId = admin.toString();
            }
            
            if (adminId == currentUser.uid) {
              isAdmin = true;
              break;
            }
          }
          
          if (isAdmin) {
            // Recolectar los IDs de miembros usando la nueva lógica
            List<String> memberIds = await _getMemberIdsForEntity(group.id, 'group');
            
            ledEntities.add({
              'id': group.id,
              'type': 'group',
              'memberIds': memberIds,
              'name': data['name'] ?? 'Grupo sin nombre',
            });
          }
        }
      }
      
      // Si no lidera ningún grupo, retornar lista vacía
      if (ledEntities.isEmpty) {
        debugPrint('⚠️ No se encontraron grupos liderados por el usuario');
        return [];
      }
      
      // Recopilar todos los miembros únicos de grupos
      Set<String> allMemberIds = {};
      Map<String, String> memberEntityNames = {}; // Para guardar a qué grupo(s) pertenece cada usuario
      
      for (var entity in ledEntities) {
        final entityName = entity['name'] as String;
        for (var memberId in entity['memberIds']) {
          String id = memberId.toString();
          allMemberIds.add(id);
          
          // Guardar o actualizar el nombre de la entidad a la que pertenece
          if (memberEntityNames.containsKey(id)) {
            memberEntityNames[id] = "${memberEntityNames[id]}, $entityName";
          } else {
            memberEntityNames[id] = entityName;
          }
        }
      }
      
      // Preparar mapa para estadísticas de usuarios
      Map<String, Map<String, dynamic>> userStats = {};
      
      debugPrint('📋 Miembros encontrados en grupos: ${allMemberIds.length}');
      
      // Inicializar estadísticas para cada miembro
      for (var userId in allMemberIds) {
        // Obtener datos del usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};
        
        userStats[userId] = {
          'userId': userId,
          'userName': userData['displayName'] ?? 'Usuario',
          'userPhotoUrl': userData['photoUrl'] ?? '',
          'totalEvents': 0,
          'eventsAttended': 0,
          'lastAttendance': null,
          'recentEventIds': <String>[],
          'entityName': memberEntityNames[userId] ?? '',
        };
      }
      
      // Recorrer cada grupo y obtener sus eventos
      for (var entity in ledEntities) {
        // Consulta de eventos
        Query eventsQuery = _firestore
            .collection('group_events')
            .where('groupId', isEqualTo: _firestore.collection('groups').doc(entity['id']));
        
        // Aplicar filtros de fecha si están presentes
        if (startDate != null) {
          eventsQuery = eventsQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
        }
        
        if (endDate != null) {
          eventsQuery = eventsQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
        }
        
        // Ejecutar consulta de eventos
        final eventsSnapshot = await eventsQuery.get();
        
        // Obtener asistencia para cada evento
        for (var eventDoc in eventsSnapshot.docs) {
          final eventId = eventDoc.id;
          
          // Obtener registros de asistencia para este evento
          final attendanceSnapshot = await _firestore
              .collection(_collection)
              .where('eventId', isEqualTo: eventId)
              .get();
          
          // Procesar asistencia
          for (var attendanceDoc in attendanceSnapshot.docs) {
            final attendance = EventAttendance.fromFirestore(attendanceDoc);
            final userId = attendance.userId;
            
            // Si este usuario está en nuestro conjunto de miembros
            if (userStats.containsKey(userId)) {
              userStats[userId]!['totalEvents'] = (userStats[userId]!['totalEvents'] as int) + 1;
              
              if (attendance.attended) {
                userStats[userId]!['eventsAttended'] = (userStats[userId]!['eventsAttended'] as int) + 1;
                
                // Actualizar última fecha de asistencia
                final currentLastAttendance = userStats[userId]!['lastAttendance'] as DateTime?;
                if (currentLastAttendance == null || 
                    attendance.verificationDate.isAfter(currentLastAttendance)) {
                  userStats[userId]!['lastAttendance'] = attendance.verificationDate;
                }
                
                // Agregar a eventos recientes
                (userStats[userId]!['recentEventIds'] as List<String>).add(eventId);
                if ((userStats[userId]!['recentEventIds'] as List<String>).length > 5) {
                  (userStats[userId]!['recentEventIds'] as List<String>).removeAt(0);
                }
              }
            }
          }
        }
      }
      
      // Convertir el mapa a lista de UserAttendanceStats
      List<UserAttendanceStats> result = [];
      for (var entry in userStats.entries) {
        final stats = entry.value;
        final totalEvents = stats['totalEvents'] as int;
        final eventsAttended = stats['eventsAttended'] as int;
        
        // Calcular tasa de asistencia
        final attendanceRate = totalEvents > 0 ? (eventsAttended / totalEvents) * 100 : 0.0;
        
        result.add(UserAttendanceStats(
          userId: stats['userId'] as String,
          userName: stats['userName'] as String,
          userPhotoUrl: stats['userPhotoUrl'] as String,
          totalEvents: totalEvents,
          eventsAttended: eventsAttended,
          attendanceRate: attendanceRate,
          lastAttendance: stats['lastAttendance'] as DateTime? ?? DateTime(2000),
          recentEventIds: stats['recentEventIds'] as List<String>?,
          entityName: stats['entityName'] as String? ?? '',
        ));
      }
      
      debugPrint('✅ Total de estadísticas generadas: ${result.length}');
      return result;
    } catch (e) {
      debugPrint('❌ Error al generar estadísticas de grupos: $e');
      return [];
    }
  }

  // Obtener usuarios que se pueden agregar a un evento (miembros del grupo/ministerio)
  Future<List<Map<String, dynamic>>> getPotentialAttendees({
    required String entityId,
    required String entityType,
    required String eventId,
  }) async {
    try {
      debugPrint('🔍 Obteniendo miembros para ${entityType} con ID: ${entityId}');
      
      // Obtener miembros de la entidad
      final collection = entityType == 'ministry' ? 'ministries' : 'groups';
      final entityDoc = await _firestore.collection(collection).doc(entityId).get();
      
      if (!entityDoc.exists) {
        debugPrint('❌ La entidad no existe');
        return [];
      }
      
      final data = entityDoc.data()!;
      debugPrint('📋 Datos de la entidad: ${data['name']}');
      
      // Lista para almacenar IDs de miembros
      List<String> memberIdsList = [];
      
      // Verificar diferentes campos posibles para miembros
      List<String> possibleMemberFields = [
        'memberIds',
        'members',
        'membersIds',
        'groupMembers',
        'ministryMembers'
      ];
      
      // Buscar en colecciones específicas primero (método más preciso)
      try {
        // Para ministerios
        if (entityType == 'ministry') {
          final ministryMembersSnapshot = await _firestore
              .collection('ministry_members')
              .where('ministryId', isEqualTo: entityId)
              .get();
          
          if (ministryMembersSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Encontrados ${ministryMembersSnapshot.docs.length} miembros en ministry_members');
            
            for (var doc in ministryMembersSnapshot.docs) {
              final userId = doc.data()['userId'] as String?;
              if (userId != null && !memberIdsList.contains(userId)) {
                memberIdsList.add(userId);
              }
            }
          }
        } 
        // Para grupos
        else if (entityType == 'group') {
          final groupMembersSnapshot = await _firestore
              .collection('group_members')
              .where('groupId', isEqualTo: entityId)
              .get();
          
          if (groupMembersSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Encontrados ${groupMembersSnapshot.docs.length} miembros en group_members');
            
            for (var doc in groupMembersSnapshot.docs) {
              final userId = doc.data()['userId'] as String?;
              if (userId != null && !memberIdsList.contains(userId)) {
                memberIdsList.add(userId);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error al buscar en colecciones específicas: $e');
      }
      
      // Si no se encontraron miembros en las colecciones específicas, 
      // buscar en campos directos de la entidad
      if (memberIdsList.isEmpty) {
        debugPrint('🔍 Buscando en campos directos del documento');
        
        for (var field in possibleMemberFields) {
          if (data.containsKey(field)) {
            final membersData = data[field];
            
            if (membersData is List) {
              debugPrint('✅ Campo encontrado: $field con ${membersData.length} elementos');
              
              // Recorrer la lista y extraer IDs
              for (var member in membersData) {
                String memberId = '';
                
                // Manejar diferentes formatos (DocumentReference o String)
                if (member is DocumentReference) {
                  memberId = member.id;
                } else {
                  memberId = member.toString();
                }
                
                if (!memberIdsList.contains(memberId)) {
                  memberIdsList.add(memberId);
                }
              }
              
              break; // Usar el primer campo encontrado
            }
          }
        }
      }
      
      debugPrint('📋 Total de IDs de miembros encontrados: ${memberIdsList.length}');
      
      // Si no se encontraron miembros después de buscar en todos lados, mostrar advertencia
      if (memberIdsList.isEmpty) {
        debugPrint('⚠️ No se encontraron miembros después de revisar todos los campos');
      }
      
      List<Map<String, dynamic>> members = [];
      
      // Obtener datos de cada miembro
      for (var memberId in memberIdsList) {
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          
          // Verificar si ya existe registro de asistencia
          final attendanceDoc = await _firestore
              .collection(_collection)
              .doc('${eventId}_${memberId}')
              .get();
          
          members.add({
            'id': memberId,
            'name': userData['displayName'] ?? 'Usuario',
            'photoUrl': userData['photoUrl'] ?? '',
            'hasAttendanceRecord': attendanceDoc.exists,
            'attended': attendanceDoc.exists ? (attendanceDoc.data()?['attended'] ?? false) : false,
          });
        }
      }
      
      // Ordenar por nombre
      members.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      
      debugPrint('✅ Total de miembros procesados: ${members.length}');
      return members;
    } catch (e) {
      debugPrint('❌ Error al obtener potenciales asistentes: $e');
      return [];
    }
  }
  
  // Método para buscar usuarios en general (para agregar asistentes externos)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Buscar por displayName
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('displayName')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(10)
          .get();
      
      List<Map<String, dynamic>> results = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        results.add({
          'id': doc.id,
          'name': data['displayName'] ?? 'Usuario',
          'photoUrl': data['photoUrl'] ?? '',
          'email': data['email'] ?? '',
        });
      }
      
      return results;
    } catch (e) {
      debugPrint('Error al buscar usuarios: $e');
      return [];
    }
  }
  
  // Método para obtener usuarios recientes
  Future<List<Map<String, dynamic>>> getRecentUsers(int limit) async {
    try {
      // Obtener los usuarios más recientes
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      if (usersSnapshot.docs.isEmpty) {
        // Si no hay usuarios con createdAt, intentar con otra consulta
        return await _getDefaultUsers(limit);
      }
      
      List<Map<String, dynamic>> results = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        results.add({
          'id': doc.id,
          'name': data['displayName'] ?? 'Usuario',
          'photoUrl': data['photoUrl'] ?? '',
          'email': data['email'] ?? '',
        });
      }
      
      return results;
    } catch (e) {
      debugPrint('Error al obtener usuarios recientes: $e');
      // En caso de error, intentar con la consulta alternativa
      return await _getDefaultUsers(limit);
    }
  }
  
  // Método auxiliar para obtener usuarios cuando el método principal falla
  Future<List<Map<String, dynamic>>> _getDefaultUsers(int limit) async {
    try {
      // Consulta alternativa: simplemente obtener los primeros usuarios por displayName
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('displayName')
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> results = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        results.add({
          'id': doc.id,
          'name': data['displayName'] ?? 'Usuario',
          'photoUrl': data['photoUrl'] ?? '',
          'email': data['email'] ?? '',
        });
      }
      
      return results;
    } catch (e) {
      debugPrint('Error al obtener usuarios predeterminados: $e');
      return [];
    }
  }

  // Método auxiliar para obtener los IDs de miembros para una entidad (grupo o ministerio)
  Future<List<String>> _getMemberIdsForEntity(String entityId, String entityType) async {
    List<String> memberIdsList = [];
    
    try {
      // Obtener el documento de la entidad
      final collection = entityType == 'ministry' ? 'ministries' : 'groups';
      final entityDoc = await _firestore.collection(collection).doc(entityId).get();
      
      if (!entityDoc.exists) {
        debugPrint('❌ La entidad con ID $entityId no existe');
        return [];
      }
      
      final data = entityDoc.data()!;
      
      // Verificar diferentes campos posibles para miembros
      List<String> possibleMemberFields = [
        'memberIds',
        'members',
        'membersIds',
        'groupMembers',
        'ministryMembers'
      ];
      
      // Buscar en colecciones específicas primero (método más preciso)
      try {
        // Para ministerios
        if (entityType == 'ministry') {
          final ministryMembersSnapshot = await _firestore
              .collection('ministry_members')
              .where('ministryId', isEqualTo: entityId)
              .get();
          
          if (ministryMembersSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Encontrados ${ministryMembersSnapshot.docs.length} miembros en ministry_members para $entityId');
            
            for (var doc in ministryMembersSnapshot.docs) {
              final userId = doc.data()['userId'] as String?;
              if (userId != null && !memberIdsList.contains(userId)) {
                memberIdsList.add(userId);
              }
            }
          }
        } 
        // Para grupos
        else if (entityType == 'group') {
          final groupMembersSnapshot = await _firestore
              .collection('group_members')
              .where('groupId', isEqualTo: entityId)
              .get();
          
          if (groupMembersSnapshot.docs.isNotEmpty) {
            debugPrint('✅ Encontrados ${groupMembersSnapshot.docs.length} miembros en group_members para $entityId');
            
            for (var doc in groupMembersSnapshot.docs) {
              final userId = doc.data()['userId'] as String?;
              if (userId != null && !memberIdsList.contains(userId)) {
                memberIdsList.add(userId);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error al buscar en colecciones específicas: $e');
      }
      
      // Si no se encontraron miembros en las colecciones específicas, 
      // buscar en campos directos de la entidad
      if (memberIdsList.isEmpty) {
        debugPrint('🔍 Buscando en campos directos del documento para $entityId');
        
        for (var field in possibleMemberFields) {
          if (data.containsKey(field)) {
            final membersData = data[field];
            
            if (membersData is List) {
              debugPrint('✅ Campo encontrado: $field con ${membersData.length} elementos');
              
              // Recorrer la lista y extraer IDs
              for (var member in membersData) {
                String memberId = '';
                
                // Manejar diferentes formatos (DocumentReference o String)
                if (member is DocumentReference) {
                  memberId = member.id;
                } else {
                  memberId = member.toString();
                }
                
                if (!memberIdsList.contains(memberId)) {
                  memberIdsList.add(memberId);
                }
              }
              
              break; // Usar el primer campo encontrado
            }
          }
        }
      }
      
      if (memberIdsList.isEmpty) {
        debugPrint('⚠️ No se encontraron miembros para la entidad $entityId');
      } else {
        debugPrint('📋 Total de miembros encontrados para $entityId: ${memberIdsList.length}');
      }
      
      return memberIdsList;
    } catch (e) {
      debugPrint('❌ Error al obtener miembros para la entidad $entityId: $e');
      return [];
    }
  }
} 