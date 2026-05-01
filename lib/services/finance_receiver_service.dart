import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/finance_receiver.dart';
import './auth_service.dart';

class FinanceReceiverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  CollectionReference get _collection =>
      _firestore.collection('finance_receivers');

  Stream<List<FinanceReceiver>> streamReceivers({bool onlyActive = false}) {
    Query query = _collection.orderBy('name');
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FinanceReceiver.fromFirestore(doc)).toList();
    });
  }

  Future<FinanceReceiver?> getReceiver(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return FinanceReceiver.fromFirestore(doc);
  }

  Future<String?> addReceiver({
    required String name,
    required String idReceiver,
    required String paymentAccountId,
    bool isActive = true,
  }) async {
    final user = _authService.currentUser;
    final data = {
      'name': name,
      'idReceiver': idReceiver,
      'paymentAccountId': paymentAccountId,
      'isActive': isActive,
      'createdBy': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final doc = await _collection.add(data);
    return doc.id;
  }

  Future<void> updateReceiver({
    required String id,
    required String name,
    required String idReceiver,
    required String paymentAccountId,
    required bool isActive,
  }) async {
    await _collection.doc(id).update({
      'name': name,
      'idReceiver': idReceiver,
      'paymentAccountId': paymentAccountId,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
