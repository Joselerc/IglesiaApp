// lib/models/service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final String churchId;
  final String createdBy;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.churchId,
    required this.createdBy,
    required this.createdAt,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      churchId: data['churchId']?.id ?? '',
      createdBy: data['createdBy']?.id ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'churchId': FirebaseFirestore.instance.collection('churches').doc(churchId),
      'createdBy': FirebaseFirestore.instance.collection('users').doc(createdBy),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}