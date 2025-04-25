import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para registrar la asistencia real a eventos (verificada por líderes)
class EventAttendance {
  final String id;
  final String eventId;
  final String userId;
  final String eventType; // 'ministry' o 'group'
  final String entityId; // ID del ministerio o grupo
  final bool attended; // true = asistió, false = no asistió
  final DateTime verificationDate; // Fecha en que se verificó la asistencia
  final String verifiedBy; // ID del líder que verificó la asistencia
  final String? notes; // Notas opcionales (ejm. llegó tarde, etc.)
  final bool wasExpected; // Si estaba en la lista de confirmados originalmente

  EventAttendance({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.eventType,
    required this.entityId,
    required this.attended,
    required this.verificationDate,
    required this.verifiedBy,
    this.notes,
    required this.wasExpected,
  });

  factory EventAttendance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventAttendance(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      eventType: data['eventType'] ?? '',
      entityId: data['entityId'] ?? '',
      attended: data['attended'] ?? false,
      verificationDate: (data['verificationDate'] as Timestamp).toDate(),
      verifiedBy: data['verifiedBy'] ?? '',
      notes: data['notes'],
      wasExpected: data['wasExpected'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'eventType': eventType,
      'entityId': entityId,
      'attended': attended,
      'verificationDate': Timestamp.fromDate(verificationDate),
      'verifiedBy': verifiedBy,
      'notes': notes,
      'wasExpected': wasExpected,
    };
  }

  // Copia con modificaciones
  EventAttendance copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? eventType,
    String? entityId,
    bool? attended,
    DateTime? verificationDate,
    String? verifiedBy,
    String? notes,
    bool? wasExpected,
  }) {
    return EventAttendance(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      entityId: entityId ?? this.entityId,
      attended: attended ?? this.attended,
      verificationDate: verificationDate ?? this.verificationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
      wasExpected: wasExpected ?? this.wasExpected,
    );
  }
} 