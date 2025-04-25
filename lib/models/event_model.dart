import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final bool isActive;
  
  // Nuevos campos
  final String eventType; // 'presential', 'online', 'hybrid'
  final String? url; // Para eventos online o híbridos
  
  // Campos de ubicación
  final String? country;
  final String? postalCode;
  final String? state;
  final String? city;
  final String? neighborhood;
  final String? street;
  final String? number;
  final String? complement;
  final String? churchLocationId; // Referencia a una ubicación guardada de iglesia
  
  // Campos de fecha
  final DateTime startDate;
  final DateTime endDate;
  
  // Campos de recurrencia
  final bool isRecurrent;
  final String? recurrenceType; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? recurrenceInterval;
  final String? recurrenceEndType; // 'after', 'never', 'on_date'
  final int? recurrenceCount;
  final DateTime? recurrenceEndDate;
  final bool hasTickets; // Nuevo campo

  EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.createdBy,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.url,
    this.country,
    this.postalCode,
    this.state,
    this.city,
    this.neighborhood,
    this.street,
    this.number,
    this.complement,
    this.churchLocationId,
    this.isRecurrent = false,
    this.recurrenceType,
    this.recurrenceInterval,
    this.recurrenceEndType,
    this.recurrenceCount,
    this.recurrenceEndDate,
    this.hasTickets = false,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as DocumentReference,
      isActive: data['isActive'] ?? true,
      eventType: data['eventType'] ?? '',
      url: data['url'],
      country: data['country'],
      postalCode: data['postalCode'],
      state: data['state'],
      city: data['city'],
      neighborhood: data['neighborhood'],
      street: data['street'],
      number: data['number'],
      complement: data['complement'],
      churchLocationId: data['churchLocationId'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isRecurrent: data['isRecurrent'] ?? false,
      recurrenceType: data['recurrenceType'],
      recurrenceInterval: data['recurrenceInterval'],
      recurrenceEndType: data['recurrenceEndType'],
      recurrenceCount: data['recurrenceCount'],
      recurrenceEndDate: data['recurrenceEndDate'] != null 
          ? (data['recurrenceEndDate'] as Timestamp).toDate()
          : null,
      hasTickets: data['hasTickets'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'eventType': eventType,
      'url': url,
      'country': country,
      'postalCode': postalCode,
      'state': state,
      'city': city,
      'neighborhood': neighborhood,
      'street': street,
      'number': number,
      'complement': complement,
      'churchLocationId': churchLocationId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isRecurrent': isRecurrent,
      'recurrenceType': recurrenceType,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndType': recurrenceEndType,
      'recurrenceCount': recurrenceCount,
      'recurrenceEndDate': recurrenceEndDate != null 
          ? Timestamp.fromDate(recurrenceEndDate!)
          : null,
      'hasTickets': hasTickets,
    };
  }
} 