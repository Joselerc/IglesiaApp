import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear un evento para un grupo
  Future<String> createGroupEvent({
    required String groupId,
    required String title,
    required String description,
    required DateTime date,
    required DateTime endDate,
    required String location,
    String? address,
    File? imageFile,
    required String creatorId,
  }) async {
    try {
      // Subir imagen si existe
      String imageUrl = '';
      if (imageFile != null) {
        // Comprimir la imagen
        final compressedImage = await ImageService().compressImage(
          imageFile,
          quality: 80,
        );
        
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage
            .ref()
            .child('group_events')
            .child(groupId)
            .child(fileName);
        
        // Crear metadatos
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventType': 'group',
            'groupId': groupId,
            'createdBy': creatorId,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        
        // Subir imagen comprimida o la original si falla la compresión
        await storageRef.putFile(compressedImage ?? imageFile, metadata);
        imageUrl = await storageRef.getDownloadURL();
      }
      
      // Crear documento de evento
      final eventRef = await _firestore.collection('group_events').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'address': address, // Save full address
        'imageUrl': imageUrl,
        'groupId': _firestore.collection('groups').doc(groupId),
        'creatorId': _firestore.collection('users').doc(creatorId),
        'createdAt': FieldValue.serverTimestamp(),
        'attendees': [],
        'interested': [],
      });
      
      return eventRef.id;
    } catch (e) {
      debugPrint('Error al crear evento de grupo: $e');
      throw Exception('Error al crear evento: $e');
    }
  }
  
  // Crear un evento para un ministerio
  Future<String> createMinistryEvent({
    required String ministryId,
    required String title,
    required String description,
    required DateTime date,
    required DateTime endDate,
    required String location,
    String? address,
    File? imageFile,
    required String creatorId,
  }) async {
    try {
      // Subir imagen si existe
      String imageUrl = '';
      if (imageFile != null) {
        // Comprimir la imagen
        final compressedImage = await ImageService().compressImage(
          imageFile,
          quality: 80,
        );
        
        final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage
            .ref()
            .child('ministry_events')
            .child(ministryId)
            .child(fileName);
        
        // Crear metadatos
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventType': 'ministry',
            'ministryId': ministryId,
            'createdBy': creatorId,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        
        // Subir imagen comprimida o la original si falla la compresión
        await storageRef.putFile(compressedImage ?? imageFile, metadata);
        imageUrl = await storageRef.getDownloadURL();
      }
      
      // Crear documento de evento
      final eventRef = await _firestore.collection('ministry_events').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'endDate': Timestamp.fromDate(endDate),
        'location': location,
        'address': address, // Save full address
        'imageUrl': imageUrl,
        'ministryId': _firestore.collection('ministries').doc(ministryId),
        'creatorId': _firestore.collection('users').doc(creatorId),
        'createdAt': FieldValue.serverTimestamp(),
        'attendees': [],
        'interested': [],
      });
      
      return eventRef.id;
    } catch (e) {
      debugPrint('Error al crear evento de ministerio: $e');
      throw Exception('Error al crear evento: $e');
    }
  }
  
  // Marcar asistencia a un evento
  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String eventType,
    required bool attending,
  }) async {
    try {
      final collection = eventType == 'ministry' ? 'ministry_events' : 'group_events';
      final userRef = _firestore.collection('users').doc(userId);
      
      // Actualizar lista de asistentes en el documento del evento
      if (attending) {
        await _firestore.collection(collection).doc(eventId).update({
          'attendees': FieldValue.arrayUnion([userRef]),
          'interested': FieldValue.arrayRemove([userRef]),
        });
      } else {
        await _firestore.collection(collection).doc(eventId).update({
          'attendees': FieldValue.arrayRemove([userRef]),
        });
      }
      
      // Obtener información de la entidad (grupo o ministerio)
      DocumentReference entityRef;
      String entityId;
      
      final eventDoc = await _firestore.collection(collection).doc(eventId).get();
      final eventData = eventDoc.data();
      
      if (eventData == null) {
        throw Exception('Evento no encontrado');
      }
      
      if (eventType == 'ministry') {
        entityRef = eventData['ministryId'] as DocumentReference;
      } else {
        entityRef = eventData['groupId'] as DocumentReference;
      }
      entityId = entityRef.id;
      
      // Crear o actualizar documento en la colección event_attendees
      final attendeeDocId = '${eventId}_${userId}_${eventType}';
      await _firestore.collection('event_attendees').doc(attendeeDocId).set({
        'eventId': eventId,
        'userId': userId,
        'eventType': eventType,
        'entityId': entityId,
        'attending': attending,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error al marcar asistencia: $e');
      throw Exception('Error al actualizar asistencia: $e');
    }
  }
  
  // Marcar interés en un evento
  Future<void> markInterest({
    required String eventId,
    required String userId,
    required String eventType,
    required bool interested,
  }) async {
    try {
      final collection = eventType == 'ministry' ? 'ministry_events' : 'group_events';
      final userRef = _firestore.collection('users').doc(userId);
      
      if (interested) {
        await _firestore.collection(collection).doc(eventId).update({
          'interested': FieldValue.arrayUnion([userRef]),
          'attendees': FieldValue.arrayRemove([userRef]),
        });
      } else {
        await _firestore.collection(collection).doc(eventId).update({
          'interested': FieldValue.arrayRemove([userRef]),
        });
      }
    } catch (e) {
      debugPrint('Error al marcar interés: $e');
      throw Exception('Error al actualizar interés: $e');
    }
  }
  
  // Eliminar un evento
  Future<void> deleteEvent({
    required String eventId,
    required String eventType,
  }) async {
    try {
      final collection = eventType == 'ministry' ? 'ministry_events' : 'group_events';
      
      // Obtener información del evento para encontrar la imagen
      final eventDoc = await _firestore.collection(collection).doc(eventId).get();
      final data = eventDoc.data();
      
      if (data != null && data['imageUrl'] != null && data['imageUrl'] != '') {
        try {
          // Eliminar la imagen de Storage
          final imageRef = _storage.refFromURL(data['imageUrl']);
          await imageRef.delete();
        } catch (e) {
          debugPrint('Error al eliminar imagen de evento: $e');
          // Continuamos aunque falle la eliminación de la imagen
        }
      }
      
      // Eliminar el documento del evento
      await _firestore.collection(collection).doc(eventId).delete();
    } catch (e) {
      debugPrint('Error al eliminar evento: $e');
      throw Exception('Error al eliminar evento: $e');
    }
  }
  
  // Obtener eventos próximos para un usuario
  Stream<QuerySnapshot> getUpcomingEventsForUser(String userId) {
    final now = DateTime.now();
    final userRef = _firestore.collection('users').doc(userId);
    
    // Combinar eventos de grupos y ministerios a los que pertenece el usuario
    // NOTA: Esta es una implementación simplificada, podría requerir una solución más robusta
    return _firestore
        .collectionGroup('group_events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('attendees', arrayContains: userRef)
        .orderBy('date')
        .limit(10)
        .snapshots();
  }
  
  // Añadir recordatorio personal para un evento
  Future<void> addEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String eventType, // 'ministry' o 'group'
    required String entityId, // ID del ministerio o grupo
    required String entityName, // Nombre del ministerio o grupo
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Guardar el recordatorio en Firestore
      await _firestore.collection('event_reminders').add({
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventDate': Timestamp.fromDate(eventDate),
        'eventType': eventType,
        'entityId': entityId,
        'entityName': entityName,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      
      // Enviar notificación de confirmación
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Recordatorio configurado para "$eventTitle"'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Programar recordatorio para 1 día antes del evento
      final reminderDate = eventDate.subtract(const Duration(days: 1));
      if (reminderDate.isAfter(DateTime.now())) {
        if (eventType == 'ministry') {
          await _notificationService.sendMinistryEventReminderNotification(
            ministryId: entityId,
            ministryName: entityName,
            eventId: eventId,
            eventTitle: eventTitle,
            eventDate: eventDate,
            userId: userId,
          );
        } else {
          await _notificationService.sendGroupEventReminderNotification(
            groupId: entityId,
            groupName: entityName,
            eventId: eventId,
            eventTitle: eventTitle,
            eventDate: eventDate,
            userId: userId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error al añadir recordatorio: $e');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Error al configurar recordatorio: $e'),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception('Error al añadir recordatorio: $e');
    }
  }
  
  // Obtener asistentes a un evento con sus detalles
  Future<List<Map<String, dynamic>>> getEventAttendees({
    required String eventId,
    required String eventType, // 'ministry' o 'group'
  }) async {
    try {
      final collection = eventType == 'ministry' ? 'ministry_events' : 'group_events';
      final eventDoc = await _firestore.collection(collection).doc(eventId).get();
      final eventData = eventDoc.data();
      
      if (eventData == null) {
        throw Exception('Evento no encontrado');
      }
      
      List<DocumentReference> attendeesRefs = [];
      if (eventData['attendees'] != null) {
        attendeesRefs = List<DocumentReference>.from(eventData['attendees']);
      }
      
      if (attendeesRefs.isEmpty) {
        return [];
      }
      
      // Obtener información de los usuarios
      List<Map<String, dynamic>> attendees = [];
      for (final userRef in attendeesRefs) {
        final userDoc = await userRef.get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          attendees.add({
            'id': userDoc.id,
            'displayName': userData['displayName'] ?? 'Usuario',
            'photoUrl': userData['photoUrl'] ?? '',
            'email': userData['email'] ?? '',
          });
        }
      }
      
      return attendees;
    } catch (e) {
      debugPrint('Error al obtener asistentes: $e');
      throw Exception('Error al obtener asistentes: $e');
    }
  }
  
  // Verificar si el usuario actual va a asistir a un evento
  Future<bool> isUserAttending({
    required String eventId,
    required String eventType, // 'ministry' o 'group'
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }
      
      // Verificar en la colección event_attendees (la fuente de verdad)
      final attendeeDocId = '${eventId}_${userId}_${eventType}';
      final attendeeDoc = await _firestore.collection('event_attendees').doc(attendeeDocId).get();
      
      if (attendeeDoc.exists) {
        final attendeeData = attendeeDoc.data();
        return attendeeData != null && attendeeData['attending'] == true;
      }
      
      // Si no encontramos en la colección event_attendees, verificamos en el documento del evento
      final collection = eventType == 'ministry' ? 'ministry_events' : 'group_events';
      final eventDoc = await _firestore.collection(collection).doc(eventId).get();
      final eventData = eventDoc.data();
      
      if (eventData == null) {
        return false;
      }
      
      if (eventData['attendees'] == null) {
        return false;
      }
      
      final attendees = List<DocumentReference>.from(eventData['attendees']);
      final userRef = _firestore.collection('users').doc(userId);
      
      return attendees.any((ref) => ref.path == userRef.path);
    } catch (e) {
      debugPrint('Error al verificar asistencia: $e');
      return false;
    }
  }
  
  // Obtener conteo de asistentes
  Future<int> getEventAttendeesCount({
    required String eventId,
    required String eventType, // 'ministry' o 'group'
  }) async {
    try {
      final collection = eventType == 'ministry' ? 'ministry_events' : 'group_events';
      final eventDoc = await _firestore.collection(collection).doc(eventId).get();
      final eventData = eventDoc.data();
      
      if (eventData == null || eventData['attendees'] == null) {
        return 0;
      }
      
      return List<dynamic>.from(eventData['attendees']).length;
    } catch (e) {
      debugPrint('Error al obtener conteo de asistentes: $e');
      return 0;
    }
  }
  
  // Clave global para el acceso al contexto desde cualquier lugar
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
} 