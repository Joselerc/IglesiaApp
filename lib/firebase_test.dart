import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Este archivo es solo para verificar que las importaciones de Firebase funcionan correctamente
class FirebaseTest {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  void testFunction() {
    print('Test de importaciones Firebase');
  }
} 