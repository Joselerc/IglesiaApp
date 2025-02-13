import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final List<DocumentReference> members;
  final List<DocumentReference> groupAdmin;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.createdBy,
    required this.members,
    required this.groupAdmin,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      members: List<DocumentReference>.from(data['members'] ?? []),
      groupAdmin: List<DocumentReference>.from(data['groupAdmin'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'members': members,
      'groupAdmin': groupAdmin,
    };
  }
} 