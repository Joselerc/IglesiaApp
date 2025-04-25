import 'package:cloud_firestore/cloud_firestore.dart';

class MinistryUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {'name': 'Usuario Desconocido'};
  }

  Future<List<Map<String, dynamic>>> getUsersDetails(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    final users = await Future.wait(
      userIds.map((id) => getUserDetails(id))
    );
    
    return users.map((user) => {
      'id': userIds[users.indexOf(user)],
      ...user,
    }).toList();
  }
} 