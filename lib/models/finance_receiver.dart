import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceReceiver {
  final String id;
  final String name;
  final String idReceiver;
  final String paymentAccountId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  FinanceReceiver({
    required this.id,
    required this.name,
    required this.idReceiver,
    required this.paymentAccountId,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory FinanceReceiver.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FinanceReceiver(
      id: doc.id,
      name: data['name'] ?? '',
      idReceiver: data['idReceiver'] ?? '',
      paymentAccountId: data['paymentAccountId'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'idReceiver': idReceiver,
      'paymentAccountId': paymentAccountId,
      'isActive': isActive,
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
