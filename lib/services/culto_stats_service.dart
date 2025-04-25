import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_service_stats.dart';
import '../models/work_assignment.dart';

class CultoStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para verificar si un usuario es líder de un ministerio
  Future<bool> isUserLeader({
    required String ministryId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // Si el ministryId es un path, extraer solo el ID
      String cleanMinistryId = ministryId;
      if (ministryId.startsWith('/ministries/')) {
        cleanMinistryId = ministryId.substring('/ministries/'.length);
      }
      
      final doc = await _firestore.collection('ministries').doc(cleanMinistryId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      
      final String adminField = 'ministrieAdmin';
      
      if (!data.containsKey(adminField) || !(data[adminField] is List)) {
        return false;
      }
      
      final List<dynamic> admins = data[adminField];
      
      for (var admin in admins) {
        String adminId = '';
        
        if (admin is DocumentReference) {
          adminId = admin.id;
        } else if (admin is String && admin.startsWith('/users/')) {
          adminId = admin.substring('/users/'.length);
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

  // Generar estadísticas de servicios para usuarios de ministerios
  Future<List<UserServiceStats>> generateServiceStats({
    required String ministryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 Generando estadísticas de servicios para ministerio: $ministryId');
      
      // Si es 'all', generar estadísticas para todos los ministerios
      final bool isAllMinistries = ministryId == 'all_ministries';
      
      // Lista de IDs de ministerios a consultar
      List<String> ministryIds = [];
      
      if (isAllMinistries) {
        // Obtener todos los ministerios disponibles
        final ministries = await _firestore.collection('ministries').get();
        ministryIds = ministries.docs.map((doc) => doc.id).toList();
      } else {
        // Limpiar ministryId si es un path
        String cleanMinistryId = ministryId;
        if (ministryId.startsWith('/ministries/')) {
          cleanMinistryId = ministryId.substring('/ministries/'.length);
        }
        // Solo usar el ministerio especificado
        ministryIds.add(cleanMinistryId);
      }
      
      // Si no hay ministerios, retornar lista vacía
      if (ministryIds.isEmpty) {
        debugPrint('⚠️ No se encontraron ministerios para las estadísticas de servicios');
        return [];
      }
      
      debugPrint('📋 Ministerios encontrados para estadísticas: ${ministryIds.length}');
      
      // Obtener todos los miembros de los ministerios seleccionados
      Map<String, Map<String, dynamic>> userStats = {};
      
      // Primero, obtener todos los usuarios que pertenecen a los ministerios seleccionados
      for (var minId in ministryIds) {
        // Obtener datos del ministerio
        final ministryDoc = await _firestore.collection('ministries').doc(minId).get();
        if (!ministryDoc.exists) continue;
        
        final ministryData = ministryDoc.data()!;
        
        // Buscar miembros en el campo 'members' (puede ser una lista de referencias o IDs)
        if (ministryData.containsKey('members') && ministryData['members'] is List) {
          final List<dynamic> members = ministryData['members'];
          
          for (var member in members) {
            String memberId = '';
            
            if (member is DocumentReference) {
              memberId = member.id;
            } else if (member is String && member.startsWith('/users/')) {
              memberId = member.substring('/users/'.length);
            } else if (member is String) {
              memberId = member;
            }
            
            // Si encontramos un ID válido y no está ya en nuestro mapa, agregar
            if (memberId.isNotEmpty && !userStats.containsKey(memberId)) {
              // Obtener datos del usuario
              final userDoc = await _firestore.collection('users').doc(memberId).get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                
                userStats[memberId] = {
                  'userId': memberId,
                  'userName': userData['displayName'] ?? 'Usuario',
                  'userPhotoUrl': userData['photoUrl'] ?? '',
                  'totalAssignments': 0,
                  'confirmedAssignments': 0,
                  'acceptedAssignments': 0,
                  'rejectedAssignments': 0,
                  'pendingAssignments': 0,
                  'cancelledAssignments': 0,
                  'lastServiceDate': DateTime(2000),
                  'recentAssignmentIds': <String>[],
                };
              }
            }
          }
        }
        
        // También buscar en ministry_members para más completo
        final ministryMembersQuery = await _firestore
            .collection('ministry_members')
            .where('ministryId', isEqualTo: minId)
            .get();
        
        for (var memberDoc in ministryMembersQuery.docs) {
          final memberData = memberDoc.data();
          String memberId = '';
          
          if (memberData.containsKey('userId')) {
            final userIdField = memberData['userId'];
            if (userIdField is String && userIdField.startsWith('/users/')) {
              memberId = userIdField.substring('/users/'.length);
            } else if (userIdField is String) {
              memberId = userIdField;
            }
          }
          
          if (memberId.isNotEmpty && !userStats.containsKey(memberId)) {
            // Obtener datos del usuario
            final userDoc = await _firestore.collection('users').doc(memberId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              
              userStats[memberId] = {
                'userId': memberId,
                'userName': userData['displayName'] ?? 'Usuario',
                'userPhotoUrl': userData['photoUrl'] ?? '',
                'totalAssignments': 0,
                'confirmedAssignments': 0,
                'acceptedAssignments': 0,
                'rejectedAssignments': 0,
                'pendingAssignments': 0,
                'cancelledAssignments': 0,
                'lastServiceDate': DateTime(2000),
                'recentAssignmentIds': <String>[],
              };
            }
          }
        }
      }
      
      // Ahora, obtener todos los usuarios (para asegurarnos de tener un conjunto completo)
      final usersQuery = await _firestore.collection('users').get();
      for (var userDoc in usersQuery.docs) {
        final userId = userDoc.id;
        if (!userStats.containsKey(userId)) {
          final userData = userDoc.data();
          
          userStats[userId] = {
            'userId': userId,
            'userName': userData['displayName'] ?? 'Usuario',
            'userPhotoUrl': userData['photoUrl'] ?? '',
            'totalAssignments': 0,
            'confirmedAssignments': 0,
            'acceptedAssignments': 0,
            'rejectedAssignments': 0,
            'pendingAssignments': 0,
            'cancelledAssignments': 0,
            'lastServiceDate': DateTime(2000),
            'recentAssignmentIds': <String>[],
          };
        }
      }
      
      // Si no hay miembros, retornar lista vacía
      if (userStats.isEmpty) {
        debugPrint('⚠️ No se encontraron miembros en los ministerios seleccionados');
        return [];
      }
      
      debugPrint('📊 Total de usuarios encontrados: ${userStats.length}');
      
      // Ahora consultar work_assignments para estos usuarios
      if (isAllMinistries) {
        // Si son todos los ministerios, hacer una única consulta para evitar duplicados
        debugPrint('🔍 Consultando asignaciones para todos los ministerios');
        
        Query query = _firestore.collection('work_assignments');
        
        // Ejecutar la consulta para todos los ministerios
        final snapshot = await query.get();
        debugPrint('📋 Total de asignaciones encontradas: ${snapshot.docs.length}');
        
        // Procesar asignaciones
        int processedCount = 0;
        for (var doc in snapshot.docs) {
          final result = _processAssignment(doc, userStats);
          if (result) processedCount++;
        }
        debugPrint('📊 Asignaciones procesadas correctamente: $processedCount');
      } else {
        // Si es un ministerio específico, consultar solo sus asignaciones
        // Crear el path completo del ministerio para la consulta
        final String ministryPath = '/ministries/${ministryIds[0]}';
        
        debugPrint('🔍 Consultando asignaciones para ministerio: ${ministryIds[0]} (path: $ministryPath)');
        
        Query query = _firestore.collection('work_assignments');
        
        // Probar diferentes formatos de ministryId para encontrar las asignaciones
        try {
          // Primero intentar con el path completo
          final pathQuery = _firestore.collection('work_assignments')
              .where('ministryId', isEqualTo: ministryPath);
          final pathSnapshot = await pathQuery.get();
          debugPrint('📋 Asignaciones encontradas con path completo: ${pathSnapshot.docs.length}');
          
          // Si no hay resultados, intentar con solo el ID
          if (pathSnapshot.docs.isEmpty) {
            final idQuery = _firestore.collection('work_assignments')
                .where('ministryId', isEqualTo: ministryIds[0]);
            final idSnapshot = await idQuery.get();
            debugPrint('📋 Asignaciones encontradas con ID simple: ${idSnapshot.docs.length}');
            
            // Usar la consulta que dio resultados
            if (idSnapshot.docs.isNotEmpty) {
              query = idQuery;
            } else {
              // Si ninguna dio resultados, registrar y seguir intentando
              debugPrint('⚠️ No se encontraron asignaciones para el ministerio ${ministryIds[0]}');
              
              // Imprimimos algunos datos para depurar
              final testQuery = await _firestore.collection('work_assignments').limit(5).get();
              if (testQuery.docs.isNotEmpty) {
                debugPrint('🔍 Ejemplo de documento encontrado:');
                final exampleDoc = testQuery.docs.first;
                final data = exampleDoc.data();
                debugPrint('- ministryId: ${data['ministryId']}');
                debugPrint('- userId: ${data['userId']}');
                debugPrint('- status: ${data['status']}');
              }
            }
          } else {
            // Usar la query con path completo, que dio resultados
            query = pathQuery;
          }
        } catch (e) {
          debugPrint('❌ Error al consultar asignaciones: $e');
        }
        
        // Ejecutar consulta normal
        final snapshot = await query.get();
        debugPrint('📋 Total de asignaciones para ministerio ${ministryIds[0]}: ${snapshot.docs.length}');
        
        // Procesar asignaciones
        int processedCount = 0;
        for (var doc in snapshot.docs) {
          final result = _processAssignment(doc, userStats);
          if (result) processedCount++;
        }
        debugPrint('📊 Asignaciones procesadas correctamente: $processedCount');
      }
      
      // Convertir el mapa a lista de UserServiceStats
      return _convertToUserServiceStats(userStats);
    } catch (e) {
      debugPrint('❌ Error al generar estadísticas de servicios: $e');
      return [];
    }
  }
  
  // Método auxiliar para procesar una asignación individual
  bool _processAssignment(QueryDocumentSnapshot doc, Map<String, Map<String, dynamic>> userStats) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // Extraer userId que puede ser un string con path completo
      String userId = '';
      final userRef = data['userId'];
      
      debugPrint('🔍 Procesando asignación ${doc.id}:');
      debugPrint('- userRef: $userRef (${userRef.runtimeType})');
      
      if (userRef is String && userRef.startsWith('/users/')) {
        userId = userRef.substring('/users/'.length);
      } else if (userRef is String) {
        userId = userRef;
      } else if (userRef is DocumentReference) {
        userId = userRef.id;
      }
      
      debugPrint('- userId extraído: $userId');
      
      if (userId.isEmpty) {
        debugPrint('⚠️ No se pudo determinar el userId para la asignación ${doc.id}');
        return false;
      }
      
      // Si este usuario no está en nuestro mapa, agregarlo
      if (!userStats.containsKey(userId)) {
        debugPrint('⚠️ Usuario $userId no encontrado en el mapa de usuarios');
        // Intentar obtener datos del usuario
        _firestore.collection('users').doc(userId).get().then((userDoc) {
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            
            userStats[userId] = {
              'userId': userId,
              'userName': userData['displayName'] ?? 'Usuario',
              'userPhotoUrl': userData['photoUrl'] ?? '',
              'totalAssignments': 0,
              'confirmedAssignments': 0,
              'acceptedAssignments': 0,
              'rejectedAssignments': 0,
              'pendingAssignments': 0,
              'cancelledAssignments': 0,
              'lastServiceDate': DateTime(2000),
              'recentAssignmentIds': <String>[],
            };
          }
        });
        
        // Mientras tanto, crear un objeto temporal
        userStats[userId] = {
          'userId': userId,
          'userName': 'Usuario $userId',
          'userPhotoUrl': '',
          'totalAssignments': 0,
          'confirmedAssignments': 0,
          'acceptedAssignments': 0,
          'rejectedAssignments': 0,
          'pendingAssignments': 0,
          'cancelledAssignments': 0,
          'lastServiceDate': DateTime(2000),
          'recentAssignmentIds': <String>[],
        };
      }
      
      // Incrementar total de asignaciones
      userStats[userId]!['totalAssignments'] = (userStats[userId]!['totalAssignments'] as int) + 1;
      
      // Procesar según el status
      final String status = data['status'] ?? 'pending';
      debugPrint('- status: $status');
      
      // Contar confirmados solo si status es "confirmed"
      if (status == 'confirmed') {
        userStats[userId]!['confirmedAssignments'] = (userStats[userId]!['confirmedAssignments'] as int) + 1;
        debugPrint('  ✅ Asignación confirmada contabilizada');
        
        // Actualizar última fecha de servicio
        final String timeSlotId = data['timeSlotId'] ?? '';
        if (timeSlotId.isNotEmpty) {
          _firestore.collection('time_slots').doc(timeSlotId).get().then((timeSlotDoc) {
            if (timeSlotDoc.exists) {
              final timeSlotData = timeSlotDoc.data()!;
              if (timeSlotData.containsKey('date')) {
                final serviceDate = (timeSlotData['date'] as Timestamp).toDate();
                
                final currentLastDate = userStats[userId]!['lastServiceDate'] as DateTime?;
                if (currentLastDate == null || serviceDate.isAfter(currentLastDate)) {
                  userStats[userId]!['lastServiceDate'] = serviceDate;
                }
              }
            }
          });
        }
        
        // Agregar a trabajos recientes
        (userStats[userId]!['recentAssignmentIds'] as List<String>).add(doc.id);
        if ((userStats[userId]!['recentAssignmentIds'] as List<String>).length > 5) {
          (userStats[userId]!['recentAssignmentIds'] as List<String>).removeAt(0);
        }
      }
      
      // Actualizar contadores basados en status
      if (status == 'accepted') {
        userStats[userId]!['acceptedAssignments'] = (userStats[userId]!['acceptedAssignments'] as int) + 1;
        debugPrint('  ✅ Asignación aceptada contabilizada');
      } else if (status == 'rejected') {
        userStats[userId]!['rejectedAssignments'] = (userStats[userId]!['rejectedAssignments'] as int) + 1;
        debugPrint('  ✅ Asignación rechazada contabilizada');
      } else if (status == 'pending') {
        userStats[userId]!['pendingAssignments'] = (userStats[userId]!['pendingAssignments'] as int) + 1;
        debugPrint('  ✅ Asignación pendiente contabilizada');
      } else if (status == 'cancelled') {
        userStats[userId]!['cancelledAssignments'] = (userStats[userId]!['cancelledAssignments'] as int) + 1;
        debugPrint('  ✅ Asignación cancelada contabilizada');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error al procesar asignación ${doc.id}: $e');
      return false;
    }
  }
  
  // Método para aplicar filtro de fecha a las estadísticas
  Future<void> _applyDateFilter(Map<String, Map<String, dynamic>> userStats, DateTime? startDate, DateTime? endDate) async {
    if (startDate == null && endDate == null) return;
    
    // Obtener los time_slots que están en el rango de fechas
    Query timeSlotQuery = _firestore.collection('time_slots');
    
    if (startDate != null) {
      timeSlotQuery = timeSlotQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    
    if (endDate != null) {
      timeSlotQuery = timeSlotQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    final timeSlotDocs = await timeSlotQuery.get();
    final timeSlotIds = timeSlotDocs.docs.map((doc) => doc.id).toList();
    
    if (timeSlotIds.isEmpty) {
      // Si no hay time_slots en el rango, vaciar todas las estadísticas
      userStats.clear();
      return;
    }
    
    // Para cada usuario, recalcular sus estadísticas basadas solo en los time_slots filtrados
    for (var userId in userStats.keys.toList()) {
      final recentIds = userStats[userId]!['recentAssignmentIds'] as List<String>;
      
      // Comprobar si alguna de las asignaciones recientes está en los time_slots filtrados
      bool hasValidAssignment = false;
      
      for (var assignmentId in recentIds) {
        final assignmentDoc = await _firestore.collection('work_assignments').doc(assignmentId).get();
        if (assignmentDoc.exists) {
          final data = assignmentDoc.data()!;
          final timeSlotId = data['timeSlotId'] as String?;
          
          if (timeSlotId != null && timeSlotIds.contains(timeSlotId)) {
            hasValidAssignment = true;
            break;
          }
        }
      }
      
      // Si el usuario no tiene asignaciones válidas en el rango de fechas, eliminarlo
      if (!hasValidAssignment) {
        userStats.remove(userId);
      }
    }
  }
  
  // Método auxiliar para procesar asignaciones
  void _processAssignments(List<QueryDocumentSnapshot> assignments, Map<String, Map<String, dynamic>> userStats) {
    for (var doc in assignments) {
      try {
        final assignment = WorkAssignment.fromFirestore(doc);
        
        // Verificar si el usuario está en nuestro conjunto de miembros
        if (userStats.containsKey(assignment.userId)) {
          userStats[assignment.userId]!['totalAssignments'] = 
              (userStats[assignment.userId]!['totalAssignments'] as int) + 1;
          
          if (assignment.status == 'confirmed' || 
              (assignment.status == 'accepted' && assignment.isAttendanceConfirmed)) {
            userStats[assignment.userId]!['confirmedAssignments'] = 
                (userStats[assignment.userId]!['confirmedAssignments'] as int) + 1;
                
            // Actualizar última fecha de servicio si es necesario
            // Esto requiere consultar el timeSlot para obtener la fecha
            _firestore.collection('time_slots').doc(assignment.timeSlotId).get().then((timeSlotDoc) {
              if (timeSlotDoc.exists) {
                final timeSlotData = timeSlotDoc.data()!;
                final serviceDate = (timeSlotData['date'] as Timestamp).toDate();
                
                final currentLastDate = userStats[assignment.userId]!['lastServiceDate'] as DateTime?;
                if (currentLastDate == null || serviceDate.isAfter(currentLastDate)) {
                  userStats[assignment.userId]!['lastServiceDate'] = serviceDate;
                }
              }
            });
            
            // Agregar a trabajos recientes
            (userStats[assignment.userId]!['recentAssignmentIds'] as List<String>).add(doc.id);
            if ((userStats[assignment.userId]!['recentAssignmentIds'] as List<String>).length > 5) {
              (userStats[assignment.userId]!['recentAssignmentIds'] as List<String>).removeAt(0);
            }
          } 
          
          if (assignment.status == 'accepted') {
            userStats[assignment.userId]!['acceptedAssignments'] = 
                (userStats[assignment.userId]!['acceptedAssignments'] as int) + 1;
          } else if (assignment.status == 'rejected') {
            userStats[assignment.userId]!['rejectedAssignments'] = 
                (userStats[assignment.userId]!['rejectedAssignments'] as int) + 1;
          } else if (assignment.status == 'pending') {
            userStats[assignment.userId]!['pendingAssignments'] = 
                (userStats[assignment.userId]!['pendingAssignments'] as int) + 1;
          }
        }
      } catch (e) {
        debugPrint('Error al procesar asignación ${doc.id}: $e');
      }
    }
  }
  
  // Método auxiliar para convertir mapa a lista de UserServiceStats
  List<UserServiceStats> _convertToUserServiceStats(Map<String, Map<String, dynamic>> userStats) {
    List<UserServiceStats> result = [];
    
    for (var entry in userStats.entries) {
      final stats = entry.value;
      final totalAssignments = stats['totalAssignments'] as int;
      final confirmedAssignments = stats['confirmedAssignments'] as int;
      
      // Calcular tasa de confirmación
      final confirmationRate = totalAssignments > 0 
          ? (confirmedAssignments / totalAssignments) * 100 
          : 0.0;
      
      result.add(UserServiceStats(
        userId: stats['userId'] as String,
        userName: stats['userName'] as String,
        userPhotoUrl: stats['userPhotoUrl'] as String,
        totalAssignments: totalAssignments,
        confirmedAssignments: confirmedAssignments,
        acceptedAssignments: stats['acceptedAssignments'] as int,
        rejectedAssignments: stats['rejectedAssignments'] as int,
        pendingAssignments: stats['pendingAssignments'] as int,
        cancelledAssignments: stats['cancelledAssignments'] as int? ?? 0,
        confirmationRate: confirmationRate,
        lastServiceDate: stats['lastServiceDate'] as DateTime? ?? DateTime(2000),
        recentAssignmentIds: stats['recentAssignmentIds'] as List<String>?,
      ));
    }
    
    return result;
  }
  
  // Método para consultar asignaciones en lotes (para manejar límites de Firestore)
  Future<List<QueryDocumentSnapshot>> _fetchAssignmentsInBatches(
    Query baseQuery, 
    String fieldName, 
    List<String> values
  ) async {
    List<QueryDocumentSnapshot> allResults = [];
    
    // Dividir los valores en lotes de 10 (límite de Firestore para whereIn)
    for (int i = 0; i < values.length; i += 10) {
      final end = i + 10 < values.length ? i + 10 : values.length;
      final batch = values.sublist(i, end);
      
      // Aplicar el filtro para este lote
      final query = baseQuery.where(fieldName, whereIn: batch);
      final snapshot = await query.get();
      allResults.addAll(snapshot.docs);
    }
    
    return allResults;
  }
} 