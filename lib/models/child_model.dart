import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String familyId; // ID de la familia a la que pertenece
  final String firstName;
  final String lastName;
  final Timestamp dateOfBirth;
  final String? gender; // <-- NUEVO CAMPO
  final String? photoUrl; // Opcional
  final String? allergies; // Opcional
  final String? medicalNotes; // Opcional, para notas médicas o necesidades especiales
  final String? notes; // Notas generales, opcional
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  ChildModel({
    required this.id,
    required this.familyId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender, // <-- NUEVO PARÁMETRO
    this.photoUrl,
    this.allergies,
    this.medicalNotes,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChildModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? Timestamp.now(), // Considerar un valor por defecto apropiado o manejarlo como requerido
      gender: data['gender'] as String?, // <-- LEER NUEVO CAMPO
      photoUrl: data['photoUrl'] as String?,
      allergies: data['allergies'] as String?,
      medicalNotes: data['medicalNotes'] as String?,
      notes: data['notes'] as String?,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender, // <-- AÑADIR A MAP
      'photoUrl': photoUrl,
      'allergies': allergies,
      'medicalNotes': medicalNotes,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // --- MÉTODO COPYWITH --- 
  ChildModel copyWith({
    String? id,
    String? familyId,
    String? firstName,
    String? lastName,
    Timestamp? dateOfBirth,
    String? gender,
    String? photoUrl,
    String? allergies,
    String? medicalNotes,
    String? notes,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ChildModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      allergies: allergies ?? this.allergies,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  // --- FIN MÉTODO COPYWITH ---
}

// Colección en Firestore: children
// (Puede ser una colección de nivel superior o subcolección de 'families') 