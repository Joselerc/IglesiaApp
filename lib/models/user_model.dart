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
  final bool hasSkippedBanner;  // Si el usuario ha omitido el banner
  final bool hasCompletedAdditionalFields; // Si el usuario ha completado los campos adicionales
  final DateTime? additionalFieldsLastUpdated; // Última actualización de campos adicionales
  final DateTime? lastBannerShown; // Última vez que se mostró el banner
  final bool neverShowBannerAgain; // Si el usuario ha elegido no mostrar el banner nunca más
  final String role;      // Rol del usuario (user, admin, pastor, etc.)

  UserModel({
    required this.email,
    this.name,
    this.surname,
    this.displayName,
    this.photoUrl,
    this.phone,
    required this.createdAt,
    this.lastLogin,
    this.hasSkippedBanner = false,
    this.hasCompletedAdditionalFields = false,
    this.additionalFieldsLastUpdated,
    this.lastBannerShown,
    this.neverShowBannerAgain = false,
    this.role = 'user',
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
      'hasCompletedAdditionalFields': hasCompletedAdditionalFields,
      'additionalFieldsLastUpdated': additionalFieldsLastUpdated != null 
          ? Timestamp.fromDate(additionalFieldsLastUpdated!) 
          : null,
      'lastBannerShown': lastBannerShown != null 
          ? Timestamp.fromDate(lastBannerShown!) 
          : null,
      'neverShowBannerAgain': neverShowBannerAgain,
      'role': role,
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
      hasCompletedAdditionalFields: map['hasCompletedAdditionalFields'] ?? false,
      additionalFieldsLastUpdated: map['additionalFieldsLastUpdated'] != null 
          ? (map['additionalFieldsLastUpdated'] as Timestamp).toDate() 
          : null,
      lastBannerShown: map['lastBannerShown'] != null 
          ? (map['lastBannerShown'] as Timestamp).toDate() 
          : null,
      neverShowBannerAgain: map['neverShowBannerAgain'] ?? false,
      role: map['role'] ?? 'user',
    );
  }

  // Método de ayuda para crear displayName
  static String createDisplayName(String name, String surname) {
    return '$name $surname'.trim();
  }
}
