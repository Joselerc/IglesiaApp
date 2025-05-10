import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id; // Puede ser el UID del tutor principal o un ID generado
  final String familyName;
  final String? familyAvatarUrl;
  final List<String> guardianUserIds;
  final String? address;
  final List<String> childIds; // Lista de IDs de los perfiles de los niños
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  FamilyModel({
    required this.id,
    required this.familyName,
    this.familyAvatarUrl,
    this.guardianUserIds = const [],
    this.address,
    this.childIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      id: doc.id,
      familyName: data['familyName'] ?? '',
      familyAvatarUrl: data['familyAvatarUrl'] as String?,
      guardianUserIds: List<String>.from(data['guardianUserIds'] ?? []),
      address: data['address'] as String?,
      childIds: List<String>.from(data['childIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyName': familyName,
      'familyAvatarUrl': familyAvatarUrl,
      'guardianUserIds': guardianUserIds,
      'address': address,
      'childIds': childIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// Colección en Firestore: families 