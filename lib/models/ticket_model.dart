import 'package:cloud_firestore/cloud_firestore.dart';

class TicketFormField {
  final String id;           // Identificador único del campo 
  final String label;        // Etiqueta visible para el usuario
  final String type;         // Tipo de campo: "text", "email", "phone", "number", "select", etc.
  final bool isRequired;     // Si el campo es obligatorio
  final bool useUserProfile; // Si debe prellenarse con datos del perfil del usuario
  final String userProfileField; // Campo del perfil a usar para prellenado
  final List<String>? options; // Opciones para campos tipo select
  final String? defaultValue; // Valor predeterminado

  TicketFormField({
    required this.id,
    required this.label,
    required this.type,
    this.isRequired = true,
    this.useUserProfile = false,
    this.userProfileField = '',
    this.options,
    this.defaultValue,
  });

  factory TicketFormField.fromMap(Map<String, dynamic> map) {
    return TicketFormField(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? true,
      useUserProfile: map['useUserProfile'] ?? false,
      userProfileField: map['userProfileField'] ?? '',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      defaultValue: map['defaultValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'isRequired': isRequired,
      'useUserProfile': useUserProfile,
      'userProfileField': userProfileField,
      'options': options,
      'defaultValue': defaultValue,
    };
  }
}

class TicketModel {
  final String id;
  final String eventId;
  final String type; // Tipo de entrada (Estándar, VIP, etc.)
  final bool isPaid;
  final double price;
  final String currency;
  final int? quantity; // Cantidad disponible (null = ilimitado)
  final List<TicketFormField> formFields; // Campos personalizados para el formulario
  final String createdBy; // ID del usuario que creó el ticket
  final DateTime createdAt;
  
  // Nuevos campos
  final DateTime? registrationDeadline; // Fecha límite de registro (null = hasta la fecha del evento)
  final bool useEventDateAsDeadline; // Si se usa la fecha del evento como límite
  final String accessRestriction; // "public", "ministry", "group", "church"
  final int ticketsPerUser; // Cuántas entradas puede reservar cada usuario (0 = ilimitado)

  TicketModel({
    required this.id,
    required this.eventId,
    required this.type,
    required this.isPaid,
    required this.price,
    required this.currency,
    this.quantity,
    required this.formFields,
    required this.createdBy,
    required this.createdAt,
    this.registrationDeadline,
    this.useEventDateAsDeadline = true,
    this.accessRestriction = 'public',
    this.ticketsPerUser = 1,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extraer los campos personalizados
    final List<TicketFormField> formFields = [];
    if (data['formFields'] != null) {
      for (var fieldMap in data['formFields']) {
        formFields.add(TicketFormField.fromMap(fieldMap));
      }
    } else {
      // Si no hay campos personalizados, crear los campos predeterminados
      formFields.addAll([
        TicketFormField(
          id: 'fullName',
          label: 'Nombre completo',
          type: 'text',
          isRequired: true,
          useUserProfile: true,
          userProfileField: 'displayName',
        ),
        TicketFormField(
          id: 'email',
          label: 'Email',
          type: 'email',
          isRequired: true,
          useUserProfile: true,
          userProfileField: 'email',
        ),
        TicketFormField(
          id: 'phone',
          label: 'Teléfono',
          type: 'phone',
          isRequired: true,
          useUserProfile: true,
          userProfileField: 'phoneNumber',
        ),
      ]);
    }
    
    return TicketModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      type: data['type'] ?? '',
      isPaid: data['isPaid'] ?? false,
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'BRL',
      quantity: data['quantity'],
      formFields: formFields,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      registrationDeadline: data['registrationDeadline'] != null 
          ? (data['registrationDeadline'] as Timestamp).toDate() 
          : null,
      useEventDateAsDeadline: data['useEventDateAsDeadline'] ?? true,
      accessRestriction: data['accessRestriction'] ?? 'public',
      ticketsPerUser: data['ticketsPerUser'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'type': type,
      'isPaid': isPaid,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'formFields': formFields.map((field) => field.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'registrationDeadline': registrationDeadline != null 
          ? Timestamp.fromDate(registrationDeadline!) 
          : null,
      'useEventDateAsDeadline': useEventDateAsDeadline,
      'accessRestriction': accessRestriction,
      'ticketsPerUser': ticketsPerUser,
    };
  }

  // Helper para obtener un texto descriptivo del precio
  String get priceDisplay => isPaid ? '$price $currency' : 'Gratis';
  
  // Helper para obtener un texto descriptivo de la disponibilidad
  String get availabilityDisplay => quantity != null ? '$quantity disponíveis	' : 'Ilimitado';
  
  // Helper para obtener un texto descriptivo de la restricción de acceso
  String get accessRestrictionDisplay {
    switch (accessRestriction) {
      case 'ministry':
        return 'Solo miembros del ministerio';
      case 'group':
        return 'Solo miembros de grupos';
      case 'church':
        return 'Solo miembros de la iglesia';
      case 'public':
      default:
        return 'Abierto al público';
    }
  }
  
  // Helper para obtener un texto descriptivo del límite de entradas por usuario
  String get ticketsPerUserDisplay => 
      ticketsPerUser > 0 ? '$ticketsPerUser por usuário	' : 'Ilimitado';
} 