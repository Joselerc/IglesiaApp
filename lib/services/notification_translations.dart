/// Diccionario de traducciones para textos que viajan en notificaciones push.
///
/// Las notificaciones push del sistema operativo NO pasan por
/// `AppLocalizations`, así que cuando se envían debe traducirse el texto
/// manualmente al idioma del receptor (que persistimos en
/// `users/{uid}.preferredLanguage`).
///
/// Cada entrada del map tiene un "templater" por idioma soportado. Si el
/// idioma del receptor no está soportado, se usa portugués como fallback
/// (idioma por defecto de la app).
class NotificationTranslations {
  static const String _defaultLanguage = 'pt';
  static const List<String> _supportedLanguages = ['pt', 'es'];

  /// Diccionario `clave -> idioma -> función(params) -> texto`
  static final Map<String, Map<String, String Function(Map<String, String>)>>
      _translations = {
    // ----- Convites de serviço (escalas) -----
    'NEW_SERVICE_INVITATION': {
      'pt': (_) => 'Novo convite de serviço',
      'es': (_) => 'Nueva invitación de trabajo',
    },
    'INVITED_TO_SERVE_AS': {
      'pt': (p) =>
          'Você foi convidado para servir como ${p['role'] ?? ''}'.trim(),
      'es': (p) =>
          'Has sido invitado para servir como ${p['role'] ?? ''}'.trim(),
    },
  };

  /// Traduce una clave a texto en el idioma indicado.
  ///
  /// Si la clave no existe, devuelve un fallback razonable (la propia clave
  /// con los params) para no romper la notificación.
  static String translate(
    String key, {
    String? language,
    Map<String, String> params = const {},
  }) {
    final lang = _normalizeLanguage(language);
    final entry = _translations[key];
    if (entry != null) {
      final builder = entry[lang] ?? entry[_defaultLanguage];
      if (builder != null) return builder(params);
    }
    // Fallback humano si no hay traducción
    if (params.isEmpty) return key;
    return '$key ${params.values.join(' ')}';
  }

  /// Devuelve el idioma normalizado (siempre uno soportado).
  static String _normalizeLanguage(String? language) {
    final candidate = (language ?? _defaultLanguage).toLowerCase();
    if (_supportedLanguages.contains(candidate)) return candidate;
    // Aceptar variantes tipo "pt_BR" o "es-ES"
    final base = candidate.split(RegExp(r'[_-]')).first;
    if (_supportedLanguages.contains(base)) return base;
    return _defaultLanguage;
  }
}
