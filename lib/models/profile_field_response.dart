import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileFieldResponse {
  final String id;
  final String userId;
  final String fieldId;
  final dynamic value; // Puede ser String, int, DateTime, etc.
  final DateTime updatedAt;

  ProfileFieldResponse({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.value,
    required this.updatedAt,
  });

  factory ProfileFieldResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Manejar diferentes tipos de valores
    dynamic value = data['value'];
    if (value is Timestamp) {
      value = value.toDate();
    }
    
    return ProfileFieldResponse(
      id: doc.id,
      userId: data['userId'] ?? '',
      fieldId: data['fieldId'] ?? '',
      value: value,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    // Convertir DateTime a Timestamp si es necesario
    dynamic mappedValue = value;
    if (value is DateTime) {
      mappedValue = Timestamp.fromDate(value);
    }
    
    return {
      'userId': userId,
      'fieldId': fieldId,
      'value': mappedValue,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 