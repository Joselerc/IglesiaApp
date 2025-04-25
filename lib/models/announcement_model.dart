import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime date;
  final DateTime? startDate; // Nueva propiedad para indicar cuándo debería empezar a mostrarse
  final DateTime createdAt;
  final DocumentReference createdBy;
  final bool isActive;
  final String type; // 'regular', 'cult', etc.
  final String? cultId; // ID del culto asociado (opcional)
  final String? serviceId; // ID del servicio asociado (opcional)
  final String? location; // Localización del evento/culto
  final String? locationId; // ID de la localización guardada (opcional)
  final String? eventId; // ID del evento asociado (opcional)

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    this.startDate, // Opcional, para compatibilidad con anuncios existentes
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.type = 'regular',
    this.cultId,
    this.serviceId,
    this.location,
    this.locationId,
    this.eventId,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Para el startDate, puede ser null en anuncios antiguos
    DateTime? startDate;
    if (data.containsKey('startDate') && data['startDate'] != null) {
      startDate = (data['startDate'] as Timestamp).toDate();
    }
    
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startDate: startDate,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as DocumentReference,
      isActive: data['isActive'] ?? true,
      type: data['type'] ?? 'regular',
      cultId: data['cultId'],
      serviceId: data['serviceId'],
      location: data['location'],
      locationId: data['locationId'],
      eventId: data['eventId'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'type': type,
    };
    
    // Solo añadir campos opcionales si no son nulos
    if (cultId != null) {
      map['cultId'] = cultId as Object;
    }
    
    if (serviceId != null) {
      map['serviceId'] = serviceId as Object;
    }
    
    if (location != null) {
      map['location'] = location as Object;
    }
    
    if (locationId != null) {
      map['locationId'] = locationId as Object;
    }

    if (eventId != null) {
      map['eventId'] = eventId as Object;
    }
    
    return map;
  }
} 