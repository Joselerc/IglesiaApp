import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledRoomModel {
  final String id; // ID del evento/reunión
  final String description; // Este será el nombre principal de la programación/sala
  final Timestamp date; // Fecha de la reunión
  final Timestamp startTime; // Hora de inicio (Timestamp completo para facilitar queries)
  final Timestamp endTime;   // Hora de finalización (Timestamp completo)
  final String? ageRange;    // Faixa etária para esta reunión específica
  final int? maxChildren;   // Límite de niños para esta reunión específica (puede diferir de la capacidad de la sala)
  final bool isOpen;        // "Incluye abierta" -> si la reunión está activa/abierta en este momento
  final bool repeatWeekly;  // Si esta programación se repite semanalmente
  final List<String> checkedInChildIds; // IDs de los niños actualmente con check-in
  final Timestamp createdAt;
  Timestamp? updatedAt;

  // --- NUEVOS CAMPOS PARA REPETICIÓN ---
  final String? originalScheduleId; // ID de la primera programación en una serie de repetición
  final Timestamp? repetitionEndDate; // Hasta qué fecha se han generado las repeticiones
  // --- FIN NUEVOS CAMPOS ---

  ScheduledRoomModel({
    required this.id,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.ageRange,
    this.maxChildren,
    this.isOpen = false, // Por defecto no está abierta al crear la programación
    this.repeatWeekly = false,
    this.checkedInChildIds = const [],
    required this.createdAt,
    this.updatedAt,
    // --- AÑADIR A CONSTRUCTOR ---
    this.originalScheduleId,
    this.repetitionEndDate,
  });

  factory ScheduledRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ScheduledRoomModel(
      id: doc.id,
      description: data['description'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      startTime: data['startTime'] ?? Timestamp.now(),
      endTime: data['endTime'] ?? Timestamp.now(),
      ageRange: data['ageRange'] as String?,
      maxChildren: data['maxChildren'] as int?,
      isOpen: data['isOpen'] ?? false,
      repeatWeekly: data['repeatWeekly'] ?? false,
      checkedInChildIds: List<String>.from(data['checkedInChildIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      // --- LEER DE MAP ---
      originalScheduleId: data['originalScheduleId'] as String?,
      repetitionEndDate: data['repetitionEndDate'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'ageRange': ageRange,
      'maxChildren': maxChildren,
      'isOpen': isOpen,
      'repeatWeekly': repeatWeekly,
      'checkedInChildIds': checkedInChildIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // --- AÑADIR A MAP ---
      'originalScheduleId': originalScheduleId,
      'repetitionEndDate': repetitionEndDate,
    };
  }

  // Add copyWith method if not already present and needed for updates
  ScheduledRoomModel copyWith({
    String? id,
    String? description,
    Timestamp? date,
    Timestamp? startTime,
    Timestamp? endTime,
    String? ageRange,
    int? maxChildren,
    bool? isOpen,
    bool? repeatWeekly,
    List<String>? checkedInChildIds,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? originalScheduleId,
    Timestamp? repetitionEndDate,
  }) {
    return ScheduledRoomModel(
      id: id ?? this.id,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ageRange: ageRange ?? this.ageRange,
      maxChildren: maxChildren ?? this.maxChildren,
      isOpen: isOpen ?? this.isOpen,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      checkedInChildIds: checkedInChildIds ?? this.checkedInChildIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      originalScheduleId: originalScheduleId ?? this.originalScheduleId,
      repetitionEndDate: repetitionEndDate ?? this.repetitionEndDate,
    );
  }
}

// Colección en Firestore: scheduledRooms (o roomSchedules) 