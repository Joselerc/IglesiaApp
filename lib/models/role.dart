import 'package:cloud_firestore/cloud_firestore.dart';

class Role {
  final String id;
  final String name;
  final String? description; // Descripción opcional
  final List<String> permissions; // Lista de strings de permisos

  Role({
    required this.id,
    required this.name,
    this.description,
    required this.permissions,
  });

  factory Role.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Role(
      id: doc.id,
      name: data['name'] ?? 'Papel Sem Nome', // Valor por defecto
      description: data['description'] as String?,
      // Asegurar que permissions sea siempre una lista de strings
      permissions: List<String>.from(data['permissions'] ?? []), 
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'permissions': permissions,
      // Opcional: añadir createdAt/updatedAt si quieres rastrear cambios
      // 'updatedAt': FieldValue.serverTimestamp(), 
    };
  }
} 