import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileField {
  final String id;
  final String name;
  final String description;
  final String type; // text, number, date, select, etc.
  final bool isRequired;
  final int order;
  final bool isActive;
  final List<String>? options; // Para campos de tipo select
  final DateTime createdAt;
  final String createdBy;

  ProfileField({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.isRequired,
    required this.order,
    required this.isActive,
    this.options,
    required this.createdAt,
    required this.createdBy,
  });

  factory ProfileField.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Procesar opciones - pueden venir como lista o como mapa
    List<String>? options;
    if (data['options'] != null) {
      if (data['options'] is List) {
        // Si es una lista, convertirla directamente y eliminar duplicados
        options = List<String>.from(data['options']).toSet().toList();
      } else if (data['options'] is Map) {
        // Si es un mapa, extraer los valores y eliminar duplicados
        options = (data['options'] as Map).values
            .map((v) => v.toString())
            .toSet()
            .toList();
      }
    }
    
    return ProfileField(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'text',
      isRequired: data['isRequired'] ?? false,
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      options: options,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'isRequired': isRequired,
      'order': order,
      'isActive': isActive,
      'options': options,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
} 