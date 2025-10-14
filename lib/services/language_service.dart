import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _locale = const Locale('es', ''); // Español por defecto

  Locale get locale => _locale;

  LanguageService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'es';
    _locale = Locale(languageCode, '');
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _locale.languageCode) {
      _locale = Locale(languageCode, '');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
}

