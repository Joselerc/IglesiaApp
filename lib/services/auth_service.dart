import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;
  
  AuthService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    debugPrint('🔍 AUTH_SERVICE - Inicializando servicio de autenticación');
    
    // Verificar usuario actual
    User? user = _auth.currentUser;
    if (user != null) {
      debugPrint('ℹ️ AUTH_SERVICE - Usuario actual en constructur: ${user.uid} (${user.email})');
      
      // Verificar token
      try {
        await user.getIdToken(true);
        debugPrint('✅ AUTH_SERVICE - Token renovado exitosamente');
      } catch (e) {
        debugPrint('⚠️ AUTH_SERVICE - Error al renovar token: $e');
      }
    } else {
      debugPrint('ℹ️ AUTH_SERVICE - No hay usuario actual al inicializar el servicio');
    }
    
    // Escuchar cambios de estado de autenticación
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('✅ AUTH_SERVICE - Usuario autenticado: ${user.uid} (${user.email})');
      } else {
        debugPrint('🚫 AUTH_SERVICE - Usuario desconectado');
      }
      notifyListeners();
    });
    
    _initialized = true;
    notifyListeners();
  }
  
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Método para forzar el cierre de sesión limpiando todos los datos
  Future<void> forceSignOut() async {
    debugPrint('🔄 AUTH_SERVICE - Forzando cierre de sesión');
    
    try {
      // Verificar si hay un usuario actualmente
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        debugPrint('ℹ️ AUTH_SERVICE - Cerrando sesión para: ${currentUser.uid}');
        
        // Registrar el cierre de sesión en Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('login_history')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'event': 'logout',
            'platform': defaultTargetPlatform.toString(),
          });
          debugPrint('✅ AUTH_SERVICE - Registro de logout guardado en Firestore');
        } catch (e) {
          debugPrint('⚠️ AUTH_SERVICE - Error al registrar logout: $e');
        }
        
        // Operación básica de cierre de sesión - más confiable y compatible con todas las plataformas
        await _auth.signOut();
        
        // Limpiar preferencias relacionadas
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('firebase_auth_token');
        await prefs.remove('auth_credential');
        await prefs.remove('had_previous_login');
        
        debugPrint('✅ AUTH_SERVICE - Cierre de sesión completado');
      } else {
        debugPrint('ℹ️ AUTH_SERVICE - No hay usuario actual para cerrar sesión');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AUTH_SERVICE - Error al forzar cierre de sesión: $e');
      // No relanzamos la excepción para evitar interrumpir el flujo
    }
  }
  
  // Método para intentar iniciar sesión con manejo de errores mejorado
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('🔑 AUTH_SERVICE - Iniciando sesión con email: $email');
    
    try {
      // Primero forzamos cierre de sesión para limpiar cualquier estado
      await forceSignOut();
      
      // Esperar un momento para asegurar que todo esté limpio
      await Future.delayed(const Duration(milliseconds: 500));
      
      // ELIMINADO: La función setPersistence() solo está disponible en web
      // await _auth.setPersistence(Persistence.LOCAL);
      debugPrint('ℹ️ AUTH_SERVICE - Intentando inicio de sesión directo');
      
      // Intentar inicio de sesión
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ AUTH_SERVICE - Inicio de sesión exitoso: ${userCredential.user!.uid}');
      
      // Registrar fecha de último login en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ AUTH_SERVICE - Registro de login actualizado en Firestore');
      
      // Registrar inicio de sesión exitoso en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('had_previous_login', true);
      
      // También mantener registro de los logins en una subcolección
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('login_history')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'event': 'login',
        'platform': defaultTargetPlatform.toString(),
      });
      
      return userCredential;
    } catch (e) {
      debugPrint('❌ AUTH_SERVICE - Error al iniciar sesión: $e');
      rethrow;
    }
  }
  
  // Obtener información detallada sobre el estado de autenticación
  Future<Map<String, dynamic>> getAuthDiagnostics() async {
    debugPrint('🔍 AUTH_SERVICE - Recopilando diagnósticos de autenticación');
    
    final Map<String, dynamic> diagnostics = {
      'currentUser': null,
      'tokenValid': false,
      'persistenceMode': 'unknown',
      'previousLogins': false,
    };
    
    try {
      // Verificar usuario actual
      final User? user = _auth.currentUser;
      if (user != null) {
        diagnostics['currentUser'] = {
          'uid': user.uid,
          'email': user.email,
          'isAnonymous': user.isAnonymous,
          'emailVerified': user.emailVerified,
          'providerId': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'unknown',
        };
        
        // Verificar validez del token
        try {
          final String? token = await user.getIdToken(true);
          diagnostics['tokenValid'] = token != null && token.isNotEmpty;
        } catch (e) {
          diagnostics['tokenError'] = e.toString();
        }
      }
      
      // Verificar datos de persistencia
      SharedPreferences prefs = await SharedPreferences.getInstance();
      diagnostics['previousLogins'] = prefs.getBool('had_previous_login') ?? false;
      
      debugPrint('ℹ️ AUTH_SERVICE - Diagnósticos recopilados: ${diagnostics.toString()}');
      return diagnostics;
    } catch (e) {
      debugPrint('❌ AUTH_SERVICE - Error al recopilar diagnósticos: $e');
      diagnostics['error'] = e.toString();
      return diagnostics;
    }
  }

  // Método para verificar si el usuario actual es pastor
  Future<bool> isCurrentUserPastor() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      // Verificar si el usuario tiene el rol de pastor basado en el roleId y permisos
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      // Primero verificamos si tiene roleId de pastor (compatibilidad)
      final userData = userDoc.data();
      if (userData != null) {
        final String? roleId = userData['roleId'] as String?;
        
        if (roleId != null) {
          // Obtener el rol y verificar si tiene los permisos necesarios
          final roleDoc = await FirebaseFirestore.instance
              .collection('roles')
              .doc(roleId)
              .get();
              
          if (roleDoc.exists) {
            final roleData = roleDoc.data();
            if (roleData != null) {
              final List<dynamic> permissions = roleData['permissions'] ?? [];
              
              // Si tiene permiso de manage_pages o es el rol específico de pastor
              if (roleId == 'pastor' || permissions.contains('manage_pages')) {
                return true;
              }
            }
          }
        }
        
        // Para compatibilidad con versiones anteriores
        if (userData['role'] == 'pastor') {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error al verificar rol de pastor: $e');
      return false;
    }
  }
}
