import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String? address; // Campo para la dirección completa
  final String imageUrl;
  final DocumentReference ministryId;
  final DocumentReference createdBy;
  final DateTime createdAt;
  final bool isActive;
  final List<DocumentReference> attendees;

  MinistryEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endDate,
    required this.location,
    this.address,
    required this.imageUrl,
    required this.ministryId,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
    required this.attendees,
  });

  factory MinistryEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Verificar y convertir los campos seguros
    final id = doc.id;
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final location = data['location'] ?? '';
    final address = data['address']; // Leer dirección completa
    final imageUrl = data['imageUrl'] ?? '';
    final isActive = data['isActive'] ?? true;
    
    // Manejar referencias que podrían ser nulas o venir como strings
    DocumentReference ministryIdRef;
    if (data['ministryId'] is DocumentReference) {
      ministryIdRef = data['ministryId'];
    } else if (data['ministryId'] is String) {
      // Convertir string en formato de ruta a DocumentReference
      final String path = data['ministryId'];
      ministryIdRef = FirebaseFirestore.instance.doc(path);
    } else {
      // Valor predeterminado si es nulo o de un tipo no esperado
      ministryIdRef = FirebaseFirestore.instance.collection('ministries').doc('placeholder');
    }
    
    // Manejar la referencia createdBy
    DocumentReference createdByRef;
    if (data['createdBy'] is DocumentReference) {
      createdByRef = data['createdBy'];
    } else if (data['creatorId'] is DocumentReference) {
      createdByRef = data['creatorId'];
    } else if (data['createdBy'] is String && (data['createdBy'] as String).isNotEmpty) {
      createdByRef = FirebaseFirestore.instance.collection('users').doc(data['createdBy']);
    } else if (data['creatorId'] is String && (data['creatorId'] as String).isNotEmpty) {
      createdByRef = FirebaseFirestore.instance.collection('users').doc(data['creatorId']);
    } else {
      createdByRef = FirebaseFirestore.instance.collection('users').doc('placeholder');
    }
    
    // Manejar la lista de attendees
    List<DocumentReference> attendeesList = [];
    if (data['attendees'] != null) {
      try {
        attendeesList = List<DocumentReference>.from(data['attendees']);
      } catch (e) {
        // Si hay un error, simplemente usar una lista vacía
        print('Error al convertir attendees: $e');
      }
    }
    
    // Manejar timestamp de createdAt
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return MinistryEvent(
      id: id,
      title: title,
      description: description,
      date: date,
      endDate: endDate,
      location: location,
      address: address,
      imageUrl: imageUrl,
      ministryId: ministryIdRef,
      createdBy: createdByRef,
      createdAt: createdAt,
      isActive: isActive,
      attendees: attendeesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'address': address,
      'imageUrl': imageUrl,
      'ministryId': ministryId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'attendees': attendees,
    };
  }
} 