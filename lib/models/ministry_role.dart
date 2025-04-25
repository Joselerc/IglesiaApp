import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryRole {
  final String id;
  final String ministryId;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MinistryRole({
    required this.id,
    required this.ministryId,
    required this.name,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory MinistryRole.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MinistryRole(
      id: doc.id,
      ministryId: data['ministryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'ministryId': ministryId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }

    return map;
  }

  MinistryRole copyWith({
    String? id,
    String? ministryId,
    String? name,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MinistryRole(
      id: id ?? this.id,
      ministryId: ministryId ?? this.ministryId,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 