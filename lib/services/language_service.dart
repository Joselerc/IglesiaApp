import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _locale = const Locale('pt', ''); // Portugués por defecto

  Locale get locale => _locale;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'pt';
    _locale = Locale(languageCode, '');
    notifyListeners();
    // Si hay usuario logueado, sincronizar el idioma a Firestore para que
    // las notificaciones push lleguen en su idioma.
    _syncToFirestore(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _locale.languageCode) {
      _locale = Locale(languageCode, '');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
      await _syncToFirestore(languageCode);
    }
  }

  /// Guarda el idioma seleccionado en `users/{uid}.preferredLanguage` para
  /// que otros clientes y Cloud Functions puedan respetarlo al enviar
  /// notificaciones push.
  Future<void> _syncToFirestore(String languageCode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'preferredLanguage': languageCode}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error guardando preferredLanguage en Firestore: $e');
    }
  }
}

