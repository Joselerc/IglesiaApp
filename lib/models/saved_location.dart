import 'package:cloud_firestore/cloud_firestore.dart';

class SavedLocation {
  final String id;
  final String name;
  final String address;
  final DocumentReference createdBy;
  final DateTime createdAt;
  final bool isDefault;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.createdBy,
    required this.createdAt,
    this.isDefault = false,
  });

  factory SavedLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedLocation(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      createdBy: data['createdBy'] as DocumentReference,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDefault': isDefault,
    };
  }
} 