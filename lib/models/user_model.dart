import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // No necesitamos almacenar el uid como campo ya que será el ID del documento
  final String email;      // Email del usuario
  final String? name;       // Nombre
  final String? surname;    // Apellido
  final String? displayName; // Nombre completo (name + surname)
  final String? photoUrl;   // URL de la foto de perfil (opcional)
  final String? phone;      // Número de teléfono (opcional)
  final DateTime createdAt;  // Fecha de creación
  final DateTime? lastLogin;  // Última fecha de inicio de sesión
  final bool hasSkippedBanner;  // Nuevo campo

  UserModel({
    required this.email,
    this.name,
    this.surname,
    this.displayName,
    this.photoUrl,
    this.phone,
    required this.createdAt,
    this.lastLogin,
    this.hasSkippedBanner = false,  // Por defecto false
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'hasSkippedBanner': hasSkippedBanner,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      name: map['name'],
      surname: map['surname'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null 
          ? (map['lastLogin'] as Timestamp).toDate() 
          : null,
      hasSkippedBanner: map['hasSkippedBanner'] ?? false,
    );
  }

  // Método de ayuda para crear displayName
  static String createDisplayName(String name, String surname) {
    return '$name $surname'.trim();
  }
}
