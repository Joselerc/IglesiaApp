import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AppConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static const String CONFIG_DOC_ID = 'main_config';
  
  /// Obtiene la configuración de la aplicación
  Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final doc = await _firestore.collection('appConfig').doc(CONFIG_DOC_ID).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error al obtener configuración de app: $e');
      return null;
    }
  }
  
  /// Stream de la configuración de la aplicación
  Stream<DocumentSnapshot> getAppConfigStream() {
    return _firestore.collection('appConfig').doc(CONFIG_DOC_ID).snapshots();
  }
  
  /// Actualiza el nombre de la iglesia
  Future<void> updateChurchName(String newName) async {
    try {
      await _firestore.collection('appConfig').doc(CONFIG_DOC_ID).set({
        'churchName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar nombre de iglesia: $e');
      throw Exception('Error al actualizar nombre de iglesia: $e');
    }
  }
  
  /// Actualiza el logo de la iglesia
  Future<String> updateChurchLogo(File imageFile) async {
    try {
      // Eliminar logo anterior si existe
      final config = await getAppConfig();
      if (config != null && config['logoUrl'] != null) {
        try {
          await _storage.refFromURL(config['logoUrl']).delete();
        } catch (e) {
          print('No se pudo eliminar logo anterior: $e');
        }
      }
      
      // Subir nuevo logo
      final String fileName = 'church_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference ref = _storage.ref().child('app_config').child(fileName);
      
      await ref.putFile(imageFile);
      final String downloadUrl = await ref.getDownloadURL();
      
      // Actualizar en Firestore
      await _firestore.collection('appConfig').doc(CONFIG_DOC_ID).set({
        'logoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return downloadUrl;
    } catch (e) {
      print('Error al actualizar logo: $e');
      throw Exception('Error al actualizar logo: $e');
    }
  }
  
  /// Actualiza el color principal de la app
  Future<void> updatePrimaryColor(int colorValue) async {
    try {
      await _firestore.collection('appConfig').doc(CONFIG_DOC_ID).set({
        'primaryColor': colorValue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar color principal: $e');
      throw Exception('Error al actualizar color principal: $e');
    }
  }
  
  /// Inicializa la configuración por defecto si no existe
  Future<void> initializeDefaultConfig() async {
    try {
      final config = await getAppConfig();
      if (config == null) {
        await _firestore.collection('appConfig').doc(CONFIG_DOC_ID).set({
          'churchName': 'Amor Em Movimento',
          'logoUrl': '',
          'primaryColor': 0xFF4C513B, // Color verde oliva por defecto
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error al inicializar configuración: $e');
    }
  }
}

