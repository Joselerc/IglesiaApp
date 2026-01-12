import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/ministry.dart';
import '../../models/ministry_attendance.dart';
import '../../models/work_assignment.dart';
import '../../models/time_slot.dart';
import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = true;
  UserModel? _user;
  String _userDocId = '';
  List<Ministry> _ministries = [];
  List<Group> _groups = [];
  Map<String, List<WorkAssignment>> _workAssignmentsByMinistry = {};
  Map<String, TimeSlot> _timeSlots = {};
  Map<String, String> _pastorNames = {};
  Map<String, List<MinistryAttendance>> _attendanceByMinistry = {};
  Map<String, List<dynamic>> _attendanceByGroup = {};
  
  // Estadísticas generales
  int _totalServices = 0;
  int _totalMinistryEvents = 0;
  int _totalGroupEvents = 0;
  DateTime? _lastMinistryDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Cargar información del usuario
      await _fetchUserInfo();
      
      // 2. Cargar ministerios a los que pertenece
      await _fetchUserMinistries();
      
      // 3. Cargar grupos a los que pertenece
      await _fetchUserGroups();
      
      // 4. Para cada ministerio, cargar trabajos/servicios
      await _fetchUserWorkAssignments();
      
      // 5. Cargar asistencias a eventos de ministerio
      await _fetchMinistryAttendances();
      
      // 6. Cargar asistencias a eventos de grupo
      await _fetchGroupAttendances();
      
      // Calcular estadísticas
      _calculateStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserInfo() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userId)
        .get();
        
    if (userDoc.docs.isNotEmpty) {
      final userData = userDoc.docs.first.data();
      // Importante: almacenar el ID correcto del documento
      _userDocId = userDoc.docs.first.id;
      _user = UserModel.fromMap({...userData, 'id': _userDocId});
      
      // Añadir log para depurar
      print('✅ Usuario encontrado. ID: $_userDocId, Email: ${_user?.email}');
    }
  }

  Future<void> _fetchUserMinistries() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    final userPath = 'users/$_userDocId';
    
    print('🔍 Buscando ministerios para usuario con path: $userPath');
    
    final ministryDocs = await FirebaseFirestore.instance
        .collection('ministries')
        .get();
    
    print('📊 Encontrados ${ministryDocs.docs.length} ministerios para revisar');
    
    for (var doc in ministryDocs.docs) {
      final data = doc.data();
      print('Revisando ministerio: ${doc.id}');
      
      // Obtener miembros y administradores
      final List<dynamic> members = data['members'] ?? [];
      final List<dynamic> admins = data['ministrieAdmin'] ?? [];
      
      print('📋 Ministerio ${doc.id} - miembros: ${members.length}, admins: ${admins.length}');
      
      // Verificar si el usuario está en la lista de miembros o administradores
      bool isInMembers = false;
      bool isInAdmins = false;
      
      // Revisar miembros
      for (var member in members) {
        String memberPath = '';
        if (member is DocumentReference) {
          memberPath = member.path;
        } else if (member is String) {
          memberPath = member;
        }
        
        if (memberPath.contains(_userDocId)) {
          isInMembers = true;
          print('✅ Usuario encontrado como miembro en path: $memberPath');
          break;
        }
      }
      
      // Revisar administradores
      for (var admin in admins) {
        String adminPath = '';
        if (admin is DocumentReference) {
          adminPath = admin.path;
        } else if (admin is String) {
          adminPath = admin;
        }
        
        if (adminPath.contains(_userDocId)) {
          isInAdmins = true;
          print('✅ Usuario encontrado como admin en path: $adminPath');
          break;
        }
      }
      
      if (isInMembers || isInAdmins) {
        print('✅ Añadiendo ministerio ${doc.id} a la lista');
        final ministry = Ministry.fromFirestore(doc);
        _ministries.add(ministry);
      }
    }
    
    print('📊 Total ministerios encontrados para el usuario: ${_ministries.length}');
  }

  Future<void> _fetchUserGroups() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    final userPath = 'users/$_userDocId';
    
    print('🔍 Buscando grupos para usuario con path: $userPath');
    
    final groupDocs = await FirebaseFirestore.instance
        .collection('groups')
        .get();
    
    print('📊 Encontrados ${groupDocs.docs.length} grupos para revisar');
    
    for (var doc in groupDocs.docs) {
      final data = doc.data();
      print('Revisando grupo: ${doc.id}');
      
      // Obtener miembros y administradores
      final List<dynamic> members = data['members'] ?? [];
      final List<dynamic> admins = data['groupAdmin'] ?? [];
      
      print('📋 Grupo ${doc.id} - miembros: ${members.length}, admins: ${admins.length}');
      
      // Verificar si el usuario está en la lista de miembros o administradores
      bool isInMembers = false;
      bool isInAdmins = false;
      
      // Revisar miembros
      for (var member in members) {
        String memberPath = '';
        if (member is DocumentReference) {
          memberPath = member.path;
        } else if (member is String) {
          memberPath = member;
        }
        
        if (memberPath.contains(_userDocId)) {
          isInMembers = true;
          print('✅ Usuario encontrado como miembro en path: $memberPath');
          break;
        }
      }
      
      // Revisar administradores
      for (var admin in admins) {
        String adminPath = '';
        if (admin is DocumentReference) {
          adminPath = admin.path;
        } else if (admin is String) {
          adminPath = admin;
        }
        
        if (adminPath.contains(_userDocId)) {
          isInAdmins = true;
          print('✅ Usuario encontrado como admin en path: $adminPath');
          break;
        }
      }
      
      if (isInMembers || isInAdmins) {
        print('✅ Añadiendo grupo ${doc.id} a la lista');
        final group = Group.fromFirestore(doc);
        _groups.add(group);
      }
    }
    
    print('📊 Total grupos encontrados para el usuario: ${_groups.length}');
  }

  Future<void> _fetchUserWorkAssignments() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    final userPath = 'users/$_userDocId';
    
    print('🔍 Buscando asignaciones para usuario con path: $userPath');
    print('🔍 ID de usuario (_userDocId): $_userDocId');
    print('🔍 Email del usuario: ${_user?.email}');
    
    // Verificar estructura real de workAssignments y BUSCAR ESPECÍFICAMENTE ESTE USUARIO
    print('🔍 BUSCANDO ESPECÍFICAMENTE PARA USUARIO CON ID: $_userDocId (6Klg0qBn9zX4aHzAABHsiNfVXyv1)');
    
    final testAssignments = await FirebaseFirestore.instance
        .collection('work_assignments')
        .limit(50)
        .get();
    
    if (testAssignments.docs.isNotEmpty) {
      print('📌 MUESTRAS DE DATOS DE WORK ASSIGNMENTS (${testAssignments.docs.length} docs):');
      int contador = 0;
      
      testAssignments.docs.forEach((doc) {
        final data = doc.data();
        final userRef = data['userId'];
        
        // Mostrar detalles completos de cada userId para analizar formatos
        print('------- Documento ${doc.id} -------');
        print('  userId tipo: ${userRef?.runtimeType}');
        if (userRef is DocumentReference) {
          print('  userId path completo: ${userRef.path}');
          print('  userId solo ID: ${userRef.id}');
        } else if (userRef is String) {
          print('  userId como string: $userRef');
        } else {
          print('  userId formato desconocido: $userRef');
        }
        
        // Verificar coincidencia con este usuario específico
        bool coincideUsuario = false;
        String coincidenciaDetalle = '';
        
        if (userRef is DocumentReference && userRef.id == '6Klg0qBn9zX4aHzAABHsiNfVXyv1') {
          coincideUsuario = true;
          coincidenciaDetalle = 'Por DocumentReference.id';
        } else if (userRef is String) {
          if (userRef == '6Klg0qBn9zX4aHzAABHsiNfVXyv1') {
            coincideUsuario = true;
            coincidenciaDetalle = 'Por ID exacto';
          } else if (userRef == '/users/6Klg0qBn9zX4aHzAABHsiNfVXyv1') {
            coincideUsuario = true;
            coincidenciaDetalle = 'Por path completo';
          } else if (userRef.contains('6Klg0qBn9zX4aHzAABHsiNfVXyv1')) {
            coincideUsuario = true;
            coincidenciaDetalle = 'Por substring';
          }
        }
        
        if (coincideUsuario) {
          contador++;
          print('⭐⭐⭐ COINCIDENCIA ENCONTRADA PARA ESTE USUARIO ⭐⭐⭐');
          print('  Método de coincidencia: $coincidenciaDetalle');
          print('  ministryId: ${data['ministryId']}');
          print('  status: ${data['status']}');
          print('  role: ${data['role']}');
        }
      });
      
      print('🔢 Total de asignaciones encontradas para este usuario: $contador');
    } else {
      print('❌ No se encontraron workAssignments en la colección');
    }
    
    // Intentar con todos los ministerios en una sola consulta
    try {
      // Obtener todos los ministerios a los que pertenece el usuario
      print('📋 Ministerios del usuario: ${_ministries.map((m) => "${m.id}:${m.name}").join(', ')}');
    
      final allAssignmentDocs = await FirebaseFirestore.instance
          .collection('work_assignments')
          .get();
      
      print('📊 Encontrados ${allAssignmentDocs.docs.length} assignments en total para verificar');
      
      // Crear contador para estadísticas
      int totalMatchesFound = 0;
      int confirmedAssignmentsFound = 0;
      
      // Mapa para guardar las asignaciones por ministerio
      Map<String, List<WorkAssignment>> foundAssignments = {};
      
      for (var doc in allAssignmentDocs.docs) {
        final data = doc.data();
        final ministryRef = data['ministryId'];
        final userRef = data['userId'];
        final status = data['status'] as String?;
        
        // Intentar diferentes formatos para verificar si es este usuario
        bool isUserAssignment = false;
        
        if (userRef is DocumentReference && userRef.id == _userDocId) {
          isUserAssignment = true;
          print('✅ Coincidencia por DocumentReference ID');
        } else if (userRef is String) {
          // Probar diferentes formatos de string
          if (userRef == _userDocId) {
            isUserAssignment = true;
            print('✅ Coincidencia exacta por ID');
          } else if (userRef == '/users/$_userDocId') {
            isUserAssignment = true;
            print('✅ Coincidencia por path completo');
          } else if (userRef.endsWith(_userDocId)) {
            isUserAssignment = true;
            print('✅ Coincidencia por substring (final)');
          } else if (userRef.contains(_userDocId)) {
            isUserAssignment = true;
            print('✅ Coincidencia por substring (cualquier parte)');
          } else {
            // Último recurso: buscar por email
            if (_user?.email != null && userRef == _user!.email) {
              isUserAssignment = true;
              print('✅ Coincidencia por email');
            }
          }
        }
        
        // Analizar detalladamente el campo status
        print('🔍 ANÁLISIS DE STATUS para documento ${doc.id}:');
        print('  - status como string: "$status"');
        print('  - status tipo: ${status?.runtimeType}');
        print('  - status longitud: ${status?.length}');
        print('  - status trim: "${status?.trim()}"');
        print('  - status lowercase: "${status?.toLowerCase()}"');
        
        // Comparaciones detalladas - esto nos dará pistas sobre caracteres ocultos o espacios
        print('  - ¿status == "confirmed"? ${status == "confirmed"}');
        print('  - ¿status.trim() == "confirmed"? ${status?.trim() == "confirmed"}');
        print('  - ¿status.toLowerCase() == "confirmed"? ${status?.toLowerCase() == "confirmed"}');
        
        // Solo considerar assignments con status "confirmed" o "confirmado"
        bool isConfirmed = false;
        
        // Verificación flexible con trim y lowercase para evitar problemas de formato
        String statusNormalizado = status?.trim().toLowerCase() ?? '';
        
        if (statusNormalizado == 'confirmed' || statusNormalizado == 'confirmado') {
          isConfirmed = true;
          print('✅ Documento CONFIRMADO: status=$status (normalizado: $statusNormalizado)');
        } else {
          print('⚠️ Se omite documento con status=$status - NO ESTÁ CONFIRMADO');
          continue;
        }
        
        if (isUserAssignment) {
          totalMatchesFound++;
          if (isConfirmed) {
            confirmedAssignmentsFound++;
            
            // Intentar identificar el ministerio
            String? ministryId;
            if (ministryRef is DocumentReference) {
              ministryId = ministryRef.id;
              print('🏛️ Assignment para ministerio con ID: $ministryId');
              
              // Verificar si está en la lista de ministerios del usuario
              bool isInUserMinistries = _ministries.any((m) => m.id == ministryId);
              print('¿Está en la lista de ministerios del usuario?: $isInUserMinistries');
              
              // Verificar si es el ministerio de Cantores
              FirebaseFirestore.instance.collection('ministries').doc(ministryId).get().then((doc) {
                if (doc.exists) {
                  final name = doc.data()?['name'];
                  print('📋 Ministerio name: $name');
                  if (name == 'Cantores') {
                    print('🎵 ESTE ES EL MINISTERIO CANTORES 🎵');
                    print('🎵 ¿Asignación confirmada? $isConfirmed');
                    print('🎵 Rol en la asignación: ${data['role']}');
                  }
                }
              });
            } else if (ministryRef is String) {
              ministryId = ministryRef;
              print('🏛️ Ministry reference as string: $ministryId');
              
              // Intentar extraer ID si es un path
              if (ministryRef.startsWith('/ministries/')) {
                final extractedId = ministryRef.substring('/ministries/'.length);
                print('ID extraído: $extractedId');
                ministryId = extractedId;
              }
            }
            
            if (ministryId != null) {
              // Agregar a las asignaciones encontradas
              final assignment = WorkAssignment.fromFirestore(doc);
              
              if (!foundAssignments.containsKey(ministryId)) {
                foundAssignments[ministryId] = [];
                print('🆕 Creando nueva entrada para ministerio $ministryId');
              }
              
              foundAssignments[ministryId]!.add(assignment);
              print('➕ Agregando assignment ${doc.id} al ministerio $ministryId (total: ${foundAssignments[ministryId]!.length})');
              
              // Verificación especial para Cantores
              FirebaseFirestore.instance.collection('ministries').doc(ministryId).get().then((ministryDoc) {
                if (ministryDoc.exists && ministryDoc.data()?['name'] == 'Cantores') {
                  print('🎵 CANTORES: Agregada asignación ${doc.id}, rol: ${assignment.role}');
                }
              });
              
              // Cargar información de time slot
              if (!_timeSlots.containsKey(assignment.timeSlotId)) {
                await _fetchTimeSlot(assignment.timeSlotId);
              }
              
              // Cargar nombre del pastor que asignó
              if (!_pastorNames.containsKey(assignment.invitedBy)) {
                await _fetchPastorName(assignment.invitedBy);
              }
            }
          }
        }
      }
      
      print('📊 RESULTADO FINAL:');
      print('- Total coincidencias encontradas: $totalMatchesFound');
      print('- Asignaciones confirmadas encontradas: $confirmedAssignmentsFound');
      print('- Ministerios con asignaciones: ${foundAssignments.keys.join(', ')}');
      
      // Actualizar el total de servicios realizados
      _totalServices = confirmedAssignmentsFound;
      
      // Actualizar el mapa de asignaciones
      if (foundAssignments.isNotEmpty) {
        print('👉 Actualizando _workAssignmentsByMinistry con ${foundAssignments.length} ministerios');
        _workAssignmentsByMinistry = foundAssignments;
      } else {
        print('⚠️ No se encontraron asignaciones confirmadas para este usuario');
      }
    } catch (e) {
      print('❌ Error al buscar asignaciones para todos los ministerios: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _fetchTimeSlot(String timeSlotId) async {
    try {
      print('🔍 Buscando timeSlot con ID: $timeSlotId');
      
      // Intentar primero con el nombre de colección correcto
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('time_slots')
          .doc(timeSlotId)
          .get();
      
      if (timeSlotDoc.exists) {
        final timeSlotData = timeSlotDoc.data();
        print('✅ TimeSlot encontrado en time_slots: $timeSlotData');
        
        _timeSlots[timeSlotId] = TimeSlot.fromFirestore(timeSlotDoc);
        
        // Mostrar información del evento al que pertenece este timeSlot
        final entityId = timeSlotData?['entityId'];
        final entityType = timeSlotData?['entityType'];
        
        print('📋 TimeSlot para: $entityType con ID: $entityId');
        
        if (entityType == 'ministry' && entityId != null) {
          // Intentar obtener nombre del ministerio
          try {
            String ministryId;
            if (entityId is DocumentReference) {
              ministryId = entityId.id;
            } else if (entityId is String && entityId.startsWith('/ministries/')) {
              ministryId = entityId.substring('/ministries/'.length);
            } else {
              ministryId = entityId.toString();
            }
            
            final ministryDoc = await FirebaseFirestore.instance
                .collection('ministries')
                .doc(ministryId)
                .get();
                
            if (ministryDoc.exists) {
              final name = ministryDoc.data()?['name'];
              print('🏛️ Ministerio del timeSlot: $name');
            }
          } catch (e) {
            print('Error al obtener ministerio del timeSlot: $e');
          }
        }
      } else {
        // Si no se encuentra en time_slots, intentar con timeSlots (forma antigua)
        print('⚠️ TimeSlot no encontrado en time_slots, buscando en timeSlots...');
        final oldTimeSlotDoc = await FirebaseFirestore.instance
            .collection('timeSlots')
            .doc(timeSlotId)
            .get();
            
        if (oldTimeSlotDoc.exists) {
          final timeSlotData = oldTimeSlotDoc.data();
          print('✅ TimeSlot encontrado en timeSlots: $timeSlotData');
          
          _timeSlots[timeSlotId] = TimeSlot.fromFirestore(oldTimeSlotDoc);
        } else {
          print('⚠️ TimeSlot no encontrado en ninguna colección: $timeSlotId');
        }
      }
    } catch (e) {
      print('❌ Error fetching time slot: $e');
    }
  }

  Future<void> _fetchPastorName(String pastorId) async {
    try {
      final pastorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(pastorId)
          .get();
      
      if (pastorDoc.exists) {
        final data = pastorDoc.data() as Map<String, dynamic>;
        final pastorName = data['displayName'] ?? data['email'] ?? AppLocalizations.of(context)!.unknown;
        _pastorNames[pastorId] = pastorName;
      } else {
        _pastorNames[pastorId] = AppLocalizations.of(context)!.unknown;
      }
    } catch (e) {
      print('Error fetching pastor name: $e');
      _pastorNames[pastorId] = AppLocalizations.of(context)!.unknown;
    }
  }

  Future<void> _fetchMinistryAttendances() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    print('🔍 Buscando asistencias a ministerios para usuario: $_userDocId');
    
    try {
      // Consultar asistencias en la colección event_attendance para eventos de ministerios
      final attendanceDocs = await FirebaseFirestore.instance
          .collection('event_attendance')
          .where('eventType', isEqualTo: 'ministry')
          .where('userId', isEqualTo: _userDocId)
          .get();
      
      print('📊 Encontradas ${attendanceDocs.docs.length} asistencias a ministerios');
      
      // Agrupar las asistencias por ministerio
      Map<String, List<MinistryAttendance>> ministryAttendances = {};
      
      // Si no hay asistencias en event_attendance, intentar con ministryAttendances (colección antigua)
      if (attendanceDocs.docs.isEmpty) {
        print('⚠️ No se encontraron asistencias en event_attendance, intentando con ministryAttendances...');
        
        final oldAttendanceDocs = await FirebaseFirestore.instance
            .collection('ministryAttendances')
            .where('userId', isEqualTo: _userDocId)
            .get();
            
        print('📊 Encontradas ${oldAttendanceDocs.docs.length} asistencias antiguas');
        
        for (var doc in oldAttendanceDocs.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final taskId = data['taskId'] as String?;
          
          if (taskId != null) {
            // Intentar encontrar a qué ministerio pertenece este taskId
            final timeSlotDoc = await FirebaseFirestore.instance
                .collection('timeSlots')
                .doc(taskId)
                .get();
                
            if (timeSlotDoc.exists) {
              final timeSlotData = timeSlotDoc.data();
              final entityId = timeSlotData?['entityId'] as String?;
              final entityType = timeSlotData?['entityType'] as String?;
              
              if (entityId != null && entityType == 'ministry' && _ministries.any((m) => m.id == entityId)) {
                final attendance = MinistryAttendance(
                  taskId: taskId,
                  userId: data['userId'] ?? '',
                  status: data['status'] ?? '',
                  reason: data['reason'],
                  date: (data['date'] as Timestamp).toDate(),
                );
                
                if (!ministryAttendances.containsKey(entityId)) {
                  ministryAttendances[entityId] = [];
                }
                
                ministryAttendances[entityId]!.add(attendance);
              }
            }
          }
        }
      } else {
        // Procesar las asistencias de event_attendance
        for (var doc in attendanceDocs.docs) {
          final data = doc.data();
          final entityId = data['entityId'] as String?;
          final eventId = data['eventId'] as String?;
          final attended = data['attended'] as bool?;
          
          if (entityId != null && eventId != null && _ministries.any((m) => m.id == entityId)) {
            // Crear un objeto MinistryAttendance (simplificado)
            final attendance = MinistryAttendance(
              taskId: eventId,
              userId: _userDocId,
              status: attended == true ? 'attended' : 'missed',
              date: (data['verificationDate'] as Timestamp).toDate(),
            );
            
            if (!ministryAttendances.containsKey(entityId)) {
              ministryAttendances[entityId] = [];
            }
            
            ministryAttendances[entityId]!.add(attendance);
          }
        }
      }
      
      // Actualizar el mapa de asistencias por ministerio
      _attendanceByMinistry = ministryAttendances;
      
    } catch (e) {
      print('❌ Error al buscar asistencias a ministerios: $e');
    }
  }

  Future<void> _fetchGroupAttendances() async {
    if (_user == null || _userDocId.isEmpty) return;
    
    print('🔍 Buscando asistencias a eventos de grupo para usuario: $_userDocId');
    
    try {
      // Consultar asistencias en la colección event_attendance para eventos de grupos
      final attendanceDocs = await FirebaseFirestore.instance
          .collection('event_attendance')
          .where('eventType', isEqualTo: 'group')
          .where('userId', isEqualTo: _userDocId)
          .get();
      
      print('📊 Encontradas ${attendanceDocs.docs.length} asistencias a grupos');
      
      // Agrupar las asistencias por grupo
      Map<String, List<dynamic>> groupAttendances = {};
      
      // Si no hay asistencias en event_attendance, intentar con eventAttendances (colección antigua)
      if (attendanceDocs.docs.isEmpty) {
        print('⚠️ No se encontraron asistencias en event_attendance, intentando con eventAttendances...');
        
        final oldAttendanceDocs = await FirebaseFirestore.instance
            .collection('eventAttendances')
            .where('userId', isEqualTo: _userDocId)
            .get();
            
        print('📊 Encontradas ${oldAttendanceDocs.docs.length} asistencias antiguas');
        
        for (var doc in oldAttendanceDocs.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final eventId = data['eventId'] as String?;
          
          if (eventId != null) {
            // Intentar encontrar a qué grupo pertenece este eventId
            final eventDoc = await FirebaseFirestore.instance
                .collection('groupEvents')
                .doc(eventId)
                .get();
                
            if (eventDoc.exists) {
              final eventData = eventDoc.data();
              final groupIdRef = eventData?['groupId'];
              String? groupId;
              
              if (groupIdRef is DocumentReference) {
                groupId = groupIdRef.id;
              } else if (groupIdRef is String) {
                groupId = groupIdRef;
              }
              
              if (groupId != null && _groups.any((g) => g.id == groupId)) {
                final attendance = {
                  'eventId': eventId,
                  'userId': data['userId'] ?? '',
                  'status': data['status'] ?? '',
                  'date': (data['date'] as Timestamp).toDate(),
                };
                
                if (!groupAttendances.containsKey(groupId)) {
                  groupAttendances[groupId] = [];
                }
                
                groupAttendances[groupId]!.add(attendance);
              }
            }
          }
        }
      } else {
        // Procesar las asistencias de event_attendance
        for (var doc in attendanceDocs.docs) {
          final data = doc.data();
          final entityId = data['entityId'] as String?;
          final eventId = data['eventId'] as String?;
          final attended = data['attended'] as bool?;
          
          if (entityId != null && eventId != null && _groups.any((g) => g.id == entityId)) {
            // Crear un objeto de asistencia
            final attendance = {
              'eventId': eventId,
              'userId': _userDocId,
              'status': attended == true ? 'attended' : 'missed',
              'date': (data['verificationDate'] as Timestamp).toDate(),
            };
            
            if (!groupAttendances.containsKey(entityId)) {
              groupAttendances[entityId] = [];
            }
            
            groupAttendances[entityId]!.add(attendance);
          }
        }
      }
      
      // Actualizar el mapa de asistencias por grupo
      _attendanceByGroup = groupAttendances;
      
    } catch (e) {
      print('❌ Error al buscar asistencias a grupos: $e');
    }
  }

  void _calculateStats() {
    // Verificar el contador de servicios
    print('📊 STATS - Contador de serviços: $_totalServices');
    
    // Verificar ministerios con asignaciones
    print('📊 STATS - Ministerios em _workAssignmentsByMinistry:');
    _workAssignmentsByMinistry.forEach((ministryId, assignments) {
      print('  - Ministerio $ministryId: ${assignments.length} asignaciones');
      
      // Verificar si es Cantores
      final ministry = _ministries.firstWhere(
        (m) => m.id == ministryId,
        orElse: () => Ministry(id: '', name: '', description: '', imageUrl: '', adminIds: [], memberIds: [], pendingRequests: {}, rejectedRequests: {}, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
      
      if (ministry.name == 'Cantores') {
        print('🎵 STATS - CANTORES tem ${assignments.length} asignaciones');
        for (var assignment in assignments) {
          print('    - Role: ${assignment.role}, Status: ${assignment.status}');
        }
      }
    });
    
    // Contar total de eventos de ministerio asistidos
    _totalMinistryEvents = 0;
    _attendanceByMinistry.forEach((_, attendances) {
      _totalMinistryEvents += attendances.where((a) => a.status == 'attended').length;
    });
    
    // Contar total de eventos de grupo asistidos
    _totalGroupEvents = 0;
    _attendanceByGroup.forEach((_, attendances) {
      _totalGroupEvents += attendances.where((a) => a['status'] == 'attended').length;
    });
    
    // Recopilar todas las fechas relevantes
    List<DateTime> allDates = [];
    
    // Añadir fechas de serviços
    _workAssignmentsByMinistry.forEach((_, assignments) {
      for (var assignment in assignments) {
        final timeSlot = _timeSlots[assignment.timeSlotId];
        if (timeSlot != null) {
          allDates.add(timeSlot.startTime);
        }
      }
    });
    
    // Añadir fechas de eventos de ministerio asistidos
    _attendanceByMinistry.forEach((_, attendances) {
      for (var attendance in attendances) {
        if (attendance.status == 'attended') {
          allDates.add(attendance.date);
        }
      }
    });
    
    // Encontrar la data mais recente
    if (allDates.isNotEmpty) {
      allDates.sort((a, b) => b.compareTo(a)); // Ordenar de mais recente a mais antigo
      _lastMinistryDate = allDates.first;
    } else {
      _lastMinistryDate = null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Não disponível';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.displayName ?? AppLocalizations.of(context)!.userDetails),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null 
              ? Center(child: Text(AppLocalizations.of(context)!.userNotFound))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del usuario
                      _buildUserInfoCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Estadísticas generales
                      _buildStatsCard(),
                      
                      const SizedBox(height: 20),
                      
                      // Ministerios
                      Text(
                        AppLocalizations.of(context)!.ministries,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      ..._buildMinistryCards(),
                      
                      const SizedBox(height: 20),
                      
                      // Grupos
                      Text(
                        AppLocalizations.of(context)!.groups,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      ..._buildGroupCards(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserInfoCard() {
    List<Widget> infoRows = [];

    // Teléfono
    if (_user?.phone != null && _user!.phone!.isNotEmpty) {
      infoRows.add(_buildInfoRow(icon: Icons.phone, text: _user!.phone!));
    }
    // Género
    if (_user?.gender != null && _user!.gender!.isNotEmpty) {
      infoRows.add(_buildInfoRow(icon: Icons.person_outline, text: _user!.gender!));
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  Colors.white,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Avatar más grande
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: _user?.photoUrl != null
                      ? NetworkImage(_user!.photoUrl!)
                      : null,
                  child: _user?.photoUrl == null
                      ? Text(
                          _user?.name?[0] ?? _user?.email[0] ?? '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold, 
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.displayName ?? AppLocalizations.of(context)!.noName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filas de información construidas dinámicamente
          ...infoRows,
        ],
      ),
    );
  }

  // Nuevo Helper para construir filas de información consistentes
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        title: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        dense: true,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  Colors.white,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(
              AppLocalizations.of(context)!.generalStatistics,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          // Stats con divisores como en la captura
          Divider(height: 1, color: Colors.grey.shade200),
          _buildStatRow(
            icon: Icons.work,
            label: AppLocalizations.of(context)!.totalServicesPerformed,
            value: _totalServices.toString(),
            iconColor: const Color(0xFF42A5F5),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildStatRow(
            icon: Icons.event,
            label: AppLocalizations.of(context)!.ministryEventsAttended,
            value: _totalMinistryEvents.toString(),
            iconColor: const Color(0xFF66BB6A),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildStatRow(
            icon: Icons.groups,
            label: AppLocalizations.of(context)!.groupEventsAttended,
            value: _totalGroupEvents.toString(),
            iconColor: AppColors.primary,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMinistryCards() {
    print('🏛️ Construyendo ministerios: ${_ministries.length} ministerios disponibles');
    print('🏛️ Ministerios con asignaciones: ${_workAssignmentsByMinistry.keys.length}');
    
    if (_ministries.isEmpty) {
      print('⚠️ No hay ministerios disponibles para mostrar');
      return [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.userNotInAnyMinistry,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _ministries.map((ministry) {
      // Obtener trabajos para este ministerio (ya filtrados por status "confirmed")
      final assignments = _workAssignmentsByMinistry[ministry.id] ?? [];

      // Obtener trabajos para este ministerio y ordenarlos por fecha (más reciente primero)
      final List<WorkAssignment> sortedAssignments = List.from(assignments);
      sortedAssignments.sort((a, b) {
        final TimeSlot? timeSlotA = _timeSlots[a.timeSlotId];
        final TimeSlot? timeSlotB = _timeSlots[b.timeSlotId];
        
        if (timeSlotA == null && timeSlotB == null) return 0;
        if (timeSlotA == null) return 1;
        if (timeSlotB == null) return -1;
        
        return timeSlotB.startTime.compareTo(timeSlotA.startTime); // Orden descendente (más reciente primero)
      });
      
      // Obtener asistencias para este ministerio
      final attendances = _attendanceByMinistry[ministry.id] ?? [];
      
      // Filtrar solo asistencias confirmadas (status "attended")
      final confirmedAttendances = attendances.where((a) => a.status.toLowerCase() == 'attended').toList();

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Icon(Icons.people_alt, color: AppColors.primary),
          ),
          title: Text(
            ministry.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          subtitle: Text('${AppLocalizations.of(context)!.servicesPerformed}: ${assignments.length}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            // Servicios realizados
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.servicesPerformed,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            sortedAssignments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(AppLocalizations.of(context)!.noConfirmedServicesInMinistry),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedAssignments.length,
                    itemBuilder: (context, index) {
                      final assignment = sortedAssignments[index];
                      final timeSlot = _timeSlots[assignment.timeSlotId];
                      final pastorName = _pastorNames[assignment.invitedBy] ?? 'Desconhecido';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mostrar fecha arriba para mejor visibilidad
                              if (timeSlot != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Data: ${_formatDate(timeSlot.startTime)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.role(assignment.role),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (timeSlot != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.event_note, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.service(timeSlot.name)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.church, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    FutureBuilder<String>(
                                      future: _getCultName(timeSlot.entityId, timeSlot.entityType),
                                      builder: (context, snapshot) {
                                        return Text(AppLocalizations.of(context)!.cult(snapshot.data ?? AppLocalizations.of(context)!.notAvailable));
                                      },
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(context)!.assignedBy(pastorName)),
                                ],
                              ),
                              const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.statusConfirmed,
                                    style: TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            
            const SizedBox(height: 16),
            
            // Eventos asistidos
Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppLocalizations.of(context)!.eventsAttended,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            confirmedAttendances.isEmpty
                ? Text(AppLocalizations.of(context)!.notAttendedMinistryEvents)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: confirmedAttendances.length,
                    itemBuilder: (context, index) {
                      final attendance = confirmedAttendances[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: _getEventTitle(attendance.taskId),
                                      builder: (context, snapshot) {
                                        return Text(
                                          AppLocalizations.of(context)!.event(snapshot.data ?? AppLocalizations.of(context)!.notAvailable),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${AppLocalizations.of(context)!.date} ${_formatDate(attendance.date)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.statusPresent,
                                    style: TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              if (attendance.reason != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('${AppLocalizations.of(context)!.reason}: ${attendance.reason ?? ''}'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildGroupCards() {
    if (_groups.isEmpty) {
      return [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.userNotInAnyGroup,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _groups.map((group) {
      // Obtener asistencias a eventos de este grupo
      final attendances = _attendanceByGroup[group.id] ?? [];
      
      // Filtrar solo asistencias confirmadas (status "attended")
      final confirmedAttendances = attendances.where((a) => 
          a['status'] != null && a['status'].toString().toLowerCase() == 'attended').toList();

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ExpansionTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9), // Verde claro
            child: Icon(Icons.group, color: Color(0xFF43A047)),
          ),
          title: Text(
            group.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF43A047),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.description),
              Text('${AppLocalizations.of(context)!.eventsAttended}: ${confirmedAttendances.length}'),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            // Eventos asistidos
Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppLocalizations.of(context)!.eventsAttended,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF43A047),
                ),
              ),
            ),
            confirmedAttendances.isEmpty
                ? Text(AppLocalizations.of(context)!.notAttendedGroupEvents)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: confirmedAttendances.length,
                    itemBuilder: (context, index) {
                      final attendance = confirmedAttendances[index];
                      final date = attendance['date'] as DateTime;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.event, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: _getEventTitle(attendance['eventId']),
                                      builder: (context, snapshot) {
                                        return Text(
                                          AppLocalizations.of(context)!.event(snapshot.data ?? AppLocalizations.of(context)!.notAvailable),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${AppLocalizations.of(context)!.date} ${_formatDate(date)}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.statusPresent,
                                    style: TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      );
    }).toList();
  }

  Future<String> _getEventTitle(String eventId) async {
    try {
      print('🔍 Buscando título de evento: $eventId');
      
      // Primero buscamos en eventos de grupo
      final groupEventDoc = await FirebaseFirestore.instance
          .collection('group_events')
          .doc(eventId)
          .get();
      
      if (groupEventDoc.exists) {
        final data = groupEventDoc.data();
        if (data != null) {
          print('✅ Encontrado en group_events con datos: $data');
          // Verificar diferentes campos posibles para el título
          final title = data['title'] ?? data['name'] ?? data['description'];
          if (title != null) {
            return title.toString();
          }
        }
      } else {
        print('❌ No encontrado en group_events');
      }
      
      // Si no encontramos en eventos de grupo, buscamos en eventos de ministerio
      final ministryEventDoc = await FirebaseFirestore.instance
          .collection('ministry_events')
          .doc(eventId)
          .get();
      
      if (ministryEventDoc.exists) {
        final data = ministryEventDoc.data();
        if (data != null) {
          print('✅ Encontrado en ministryEvents con datos: $data');
          final title = data['title'] ?? data['name'] ?? data['description'];
          if (title != null) {
            return title.toString();
          }
        }
      } else {
        print('❌ No encontrado en ministryEvents');
      }
      
      // Si no encontramos en ninguno, intentamos con varios formatos de ID
      // puede ser que el ID tenga un formato como "/group_events/eventId"
      if (eventId.contains('/')) {
        final parts = eventId.split('/');
        final lastPart = parts.last;
        final collectionPart = parts.length > 1 ? parts[parts.length - 2] : '';
        
        print('🔍 Probando con ID extraído de path: $lastPart, colección: $collectionPart');
        
        // Intentar con el ID extraído según la colección en el path
        if (collectionPart == 'group_events') {
          final extractedIdDoc = await FirebaseFirestore.instance
              .collection('group_events')
              .doc(lastPart)
              .get();
            
          if (extractedIdDoc.exists) {
            final data = extractedIdDoc.data();
            if (data != null) {
              print('✅ Encontrado en group_events con ID extraído con datos: $data');
              final title = data['title'] ?? data['name'] ?? data['description'];
              if (title != null) {
                return title.toString();
              }
            }
          }
        } else if (collectionPart == 'ministry_events') {
          final extractedIdMinistryDoc = await FirebaseFirestore.instance
              .collection('ministry_events')
              .doc(lastPart)
              .get();
            
          if (extractedIdMinistryDoc.exists) {
            final data = extractedIdMinistryDoc.data();
            if (data != null) {
              print('✅ Encontrado en ministry_events con ID extraído con datos: $data');
              final title = data['title'] ?? data['name'] ?? data['description'];
              if (title != null) {
                return title.toString();
              }
            }
          }
        } else {
          // Intentar con ambas colecciones si no podemos determinar de cuál viene
          final extractedIdDoc = await FirebaseFirestore.instance
              .collection('group_events')
              .doc(lastPart)
              .get();
            
          if (extractedIdDoc.exists) {
            final data = extractedIdDoc.data();
            if (data != null) {
              print('✅ Encontrado en group_events con ID extraído con datos: $data');
              final title = data['title'] ?? data['name'] ?? data['description'];
              if (title != null) {
                return title.toString();
              }
            }
          }
            
          final extractedIdMinistryDoc = await FirebaseFirestore.instance
              .collection('ministry_events')
              .doc(lastPart)
              .get();
              
          if (extractedIdMinistryDoc.exists) {
            final data = extractedIdMinistryDoc.data();
            if (data != null) {
              print('✅ Encontrado en ministry_events con ID extraído con datos: $data');
              final title = data['title'] ?? data['name'] ?? data['description'];
              if (title != null) {
                return title.toString();
              }
            }
          }
        }
      }
      
      // Como último recurso, buscamos en timeSlots
      final timeSlotDoc = await FirebaseFirestore.instance
          .collection('timeSlots')
          .doc(eventId)
          .get();
      
      if (timeSlotDoc.exists) {
        final data = timeSlotDoc.data();
        if (data != null) {
          print('✅ Encontrado en timeSlots con datos: $data');
          final name = data['name'];
          if (name != null) {
            return name.toString();
          }
        }
      } else {
        print('❌ No encontrado en timeSlots');
      }
      
      // Si llegamos aquí, intentamos con una última colección posible
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      
      if (eventDoc.exists) {
        final data = eventDoc.data();
        if (data != null) {
          print('✅ Encontrado en events con datos: $data');
          final title = data['title'] ?? data['name'] ?? data['description'];
          if (title != null) {
            return title.toString();
          }
        }
      } else {
        print('❌ No encontrado en events');
      }
      
      // Si después de todos los intentos no encontramos nada, retornamos N/D
      print('⚠️ No se pudo encontrar título para el evento: $eventId');
      return 'N/D';
    } catch (e) {
      print('❌ Error al obtener título de evento: $e');
      return 'N/D';
    }
  }
  
  Future<String> _getCultName(String entityId, String entityType) async {
    try {
      print('🔍 Buscando información de culto - tipo: $entityType, id: $entityId');
      
      if (entityType == 'ministry') {
        // Si el tipo es ministerio, obtener nombre del ministerio
        final ministryDoc = await FirebaseFirestore.instance
            .collection('ministries')
            .doc(entityId)
            .get();
        
        if (ministryDoc.exists) {
          final data = ministryDoc.data();
          if (data != null && data['name'] != null) {
            return data['name'] as String;
          }
        }
      } else if (entityType == 'cult' || entityType == 'service') {
        // Si es un culto o servicio, obtener el título del culto
        final cultDoc = await FirebaseFirestore.instance
            .collection('cults')
            .doc(entityId)
            .get();
        
        if (cultDoc.exists) {
          final data = cultDoc.data();
          if (data != null) {
            final title = data['title'] ?? data['name'] ?? data['description'];
            if (title != null) {
              return title.toString();
            }
          }
        }
      } else {
        // Intenta buscar directamente en timeSlots para cualquier otro tipo
        final timeSlotDoc = await FirebaseFirestore.instance
            .collection('timeSlots')
            .doc(entityId)
            .get();
        
        if (timeSlotDoc.exists) {
          final data = timeSlotDoc.data();
          if (data != null && data['name'] != null) {
            return data['name'] as String;
          }
        }
      }
      
      return 'N/D';
    } catch (e) {
      print('❌ Error al obtener nombre del culto: $e');
      return 'N/D';
    }
  }
} 
