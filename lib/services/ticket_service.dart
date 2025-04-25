import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/ticket_registration_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final uuid = Uuid();

  // Referencia a la colección de eventos
  CollectionReference get _eventsCollection => 
      _firestore.collection('events');
  
  // Obtener tickets para un evento específico
  Stream<List<TicketModel>> getTicketsForEvent(String eventId) {
    return _eventsCollection
        .doc(eventId)
        .collection('tickets')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TicketModel.fromFirestore(doc))
            .toList());
  }

  // Crear un nuevo ticket
  Future<String> createTicket(String eventId, TicketModel ticket) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Asegurarse de que el creador se establezca correctamente
      final Map<String, dynamic> ticketData = ticket.toMap();
      
      // Garantizar que se guarde el creador actual
      ticketData['createdBy'] = currentUser.uid;
      
      print('DEBUG: createTicket - Creando ticket con creador: ${currentUser.uid}');
      print('DEBUG: createTicket - Datos a guardar: $ticketData');

      final docRef = await _eventsCollection
          .doc(eventId)
          .collection('tickets')
          .add(ticketData);
      
      print('DEBUG: createTicket - Ticket creado con ID: ${docRef.id}');  
      return docRef.id;
    } catch (e) {
      print('Error al crear el ticket: $e');
      throw e;
    }
  }

  // Eliminar un ticket
  Future<void> deleteTicket(String eventId, String ticketId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Primero verificamos si el usuario es quien creó el ticket
      final ticketDoc = await _eventsCollection
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId)
          .get();
          
      if (!ticketDoc.exists) {
        throw Exception('El ticket no existe');
      }

      final ticketData = ticketDoc.data() as Map<String, dynamic>;
      
      // Verificar si el campo createdBy existe y no está vacío
      final createdBy = ticketData['createdBy'] as String?;
      print('DEBUG: deleteTicket - createdBy en ticket: $createdBy');
      print('DEBUG: deleteTicket - Usuario actual: ${currentUser.uid}');
      print('DEBUG: deleteTicket - ¿Tiene creador asignado?: ${createdBy != null && createdBy.isNotEmpty}');
      
      // Bypass temporal para tickets sin creador asignado
      final bool permitirEliminacion = createdBy == null || 
          createdBy.isEmpty || 
          createdBy == currentUser.uid;
      
      if (!permitirEliminacion) {
        throw Exception('No tienes permiso para eliminar este ticket');
      }

      // Verificamos si hay registros para este ticket
      final registrations = await _eventsCollection
          .doc(eventId)
          .collection('registrations')
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      if (registrations.docs.isNotEmpty) {
        throw Exception('No se puede eliminar el ticket porque ya hay usuarios registrados');
      }

      // Si todo está bien, eliminamos el ticket
      await _eventsCollection
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId)
          .delete();
          
      print('DEBUG: deleteTicket - Ticket eliminado con éxito');
    } catch (e) {
      print('Error al eliminar el ticket: $e');
      throw e;
    }
  }

  // Eliminar un registro de entrada creado por el usuario
  Future<void> deleteMyRegistration(String eventId, String registrationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar si el registro existe y pertenece al usuario actual
      final registrationDoc = await _eventsCollection
          .doc(eventId)
          .collection('registrations')
          .doc(registrationId)
          .get();
          
      if (!registrationDoc.exists) {
        throw Exception('El registro no existe');
      }

      final registrationData = registrationDoc.data() as Map<String, dynamic>;
      if (registrationData['userId'] != currentUser.uid) {
        throw Exception('No tienes permiso para eliminar este registro');
      }

      // Si el registro ya fue utilizado, no permitir eliminarlo
      if (registrationData['isUsed'] == true) {
        throw Exception('No se puede eliminar un registro que ya ha sido utilizado');
      }

      // Si todo está bien, eliminamos el registro
      await _eventsCollection
          .doc(eventId)
          .collection('registrations')
          .doc(registrationId)
          .delete();
    } catch (e) {
      print('Error al eliminar el registro: $e');
      throw e;
    }
  }

  // Registrar un usuario para un ticket
  Future<String> registerForTicket({
    required String ticketId,
    required String eventId,
    required String eventName,
    required String userName,
    required String userEmail,
    required String userPhone,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener información del ticket
      final ticketDoc = await _eventsCollection
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId)
          .get();
          
      if (!ticketDoc.exists) {
        throw Exception('El ticket seleccionado no existe');
      }
      
      final ticketData = ticketDoc.data() as Map<String, dynamic>;
      final ticket = TicketModel.fromFirestore(ticketDoc);
      
      // Verificar si el ticket está disponible (no excede su cantidad)
      if (ticket.quantity != null) {
        // Contar cuántos registros hay para este ticket
        final registrationsCount = await _eventsCollection
            .doc(eventId)
            .collection('registrations')
            .where('ticketId', isEqualTo: ticketId)
            .count()
            .get();
            
        final int currentCount = registrationsCount.count ?? 0;
        final int maxQuantity = ticket.quantity ?? 0;
        
        if (currentCount >= maxQuantity) {
          throw Exception('Ya no hay entradas disponibles para este tipo de ticket');
        }
      }
      
      // Verificar la fecha límite de registro
      final DateTime now = DateTime.now();
      
      if (!ticket.useEventDateAsDeadline && ticket.registrationDeadline != null) {
        if (now.isAfter(ticket.registrationDeadline!)) {
          throw Exception('El plazo para registrarse a este ticket ha expirado');
        }
      }
      
      // Obtener el evento para verificar fecha límite si es necesario
      if (ticket.useEventDateAsDeadline) {
        final eventDoc = await _eventsCollection.doc(eventId).get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          if (eventData['startDate'] != null) {
            final eventDate = (eventData['startDate'] as Timestamp).toDate();
            if (now.isAfter(eventDate)) {
              throw Exception('El evento ya ha comenzado, no es posible registrarse');
            }
          }
        }
      }
      
      // Verificar las restricciones de acceso
      if (ticket.accessRestriction != 'public') {
        bool hasAccess = false;
        
        switch (ticket.accessRestriction) {
          case 'ministry':
            // Verificar si el usuario es miembro del ministerio
            final userMinistries = await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('ministries')
                .get();
            hasAccess = userMinistries.docs.isNotEmpty;
            break;
          
          case 'group':
            // Verificar si el usuario es miembro de algún grupo
            final userGroups = await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('groups')
                .get();
            hasAccess = userGroups.docs.isNotEmpty;
            break;
            
          case 'church':
            // Verificar si el usuario es miembro de la iglesia
            final userDoc = await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              hasAccess = userData['isChurchMember'] == true;
            }
            break;
        }
        
        if (!hasAccess) {
          throw Exception('No tienes acceso a este tipo de entrada. ' +
              'Esta entrada es exclusiva para: ${ticket.accessRestrictionDisplay}');
        }
      }
      
      // Verificar si el usuario ya está registrado para este ticket
      final existingRegistrations = await _eventsCollection
          .doc(eventId)
          .collection('registrations')
          .where('userId', isEqualTo: currentUser.uid)
          .where('ticketId', isEqualTo: ticketId)
          .get();
      
      if (existingRegistrations.docs.isNotEmpty) {
        throw Exception('Ya estás registrado para este ticket');
      }
      
      // Verificar límite de entradas por usuario
      if (ticket.ticketsPerUser > 0) {
        // Contar registros del usuario para este ticket
        final userRegistrationCount = await _eventsCollection
            .doc(eventId)
            .collection('registrations')
            .where('userId', isEqualTo: currentUser.uid)
            .count()
            .get();
            
        final int currentUserCount = userRegistrationCount.count ?? 0;
        
        if (currentUserCount >= ticket.ticketsPerUser) {
          throw Exception('Has alcanzado el límite de ${ticket.ticketsPerUser} entrada(s) para este evento');
        }
      }

      // Generar un código QR único (combinación de IDs)
      final qrCode = '$eventId-$ticketId-${currentUser.uid}-${uuid.v4()}';

      // Crear el registro
      final registration = {
        'eventId': eventId,
        'ticketId': ticketId,
        'userId': currentUser.uid,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'formData': formData,
        'qrCode': qrCode,
        'createdAt': FieldValue.serverTimestamp(),
        'isUsed': false,
      };

      // Guardar en Firestore
      final docRef = await _eventsCollection
          .doc(eventId)
          .collection('registrations')
          .add(registration);
          
      return docRef.id;
    } catch (e) {
      print('Error al registrar para el ticket: $e');
      throw e;
    }
  }

  // Obtener mi registro para un evento específico
  Future<TicketRegistrationModel?> getMyRegistrationForEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final querySnapshot = await _eventsCollection
          .doc(eventId)
          .collection('registrations')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return TicketRegistrationModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error al obtener el registro del ticket: $e');
      return null;
    }
  }

  // Obtener un ticket específico por ID
  Future<TicketModel?> getTicketById(String eventId, String ticketId) async {
    try {
      final doc = await _eventsCollection
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId)
          .get();
          
      if (!doc.exists) {
        return null;
      }
      return TicketModel.fromFirestore(doc);
    } catch (e) {
      print('Error al obtener el ticket: $e');
      return null;
    }
  }

  // Verificar si el usuario actual es el creador del ticket
  Future<bool> isTicketCreator(String eventId, String ticketId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('DEBUG: isTicketCreator - Usuario no autenticado');
        return false;
      }
      
      print('DEBUG: isTicketCreator - Usuario actual ID: ${currentUser.uid}');

      final doc = await _eventsCollection
          .doc(eventId)
          .collection('tickets')
          .doc(ticketId)
          .get();
          
      if (!doc.exists) {
        print('DEBUG: isTicketCreator - Ticket no existe: $ticketId');
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      
      // Verificar si el campo createdBy existe y no está vacío
      final createdBy = data['createdBy'] as String?;
      print('DEBUG: isTicketCreator - Datos del ticket: $data');
      print('DEBUG: isTicketCreator - createdBy en ticket: $createdBy');
      print('DEBUG: isTicketCreator - Usuario actual: ${currentUser.uid}');
      
      // Para tickets antiguos sin creador asignado, consideramos que cualquier usuario puede ser "creador"
      // Esto es un bypass temporal hasta que todos los tickets tengan este campo correctamente
      final bool esCreador = createdBy == null || createdBy.isEmpty || createdBy == currentUser.uid;
      print('DEBUG: isTicketCreator - ¿Es creador? $esCreador');
      
      return esCreador;
    } catch (e) {
      print('Error al verificar el creador del ticket: $e');
      return false;
    }
  }
} 