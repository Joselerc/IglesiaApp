import 'package:cloud_firestore/cloud_firestore.dart';

class Ministry {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final List<DocumentReference> members;
  final List<DocumentReference> ministrieAdmin;

  Ministry({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.createdBy,
    required this.members,
    required this.ministrieAdmin,
  });

  factory Ministry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    
    return Ministry(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as DocumentReference,
      members: (data['members'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
      ministrieAdmin: (data['ministrieAdmin'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'members': members,
      'ministrieAdmin': ministrieAdmin,
    };
  }

  factory Ministry.fromMap(Map<String, dynamic> map, String id) {
    return Ministry(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as DocumentReference,
      members: (map['members'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
      ministrieAdmin: (map['ministrieAdmin'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [],
    );
  }
} 