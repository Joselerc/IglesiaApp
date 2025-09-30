/// Constantes para todos los assets de la aplicación
class AppAssets {
  AppAssets._(); // Constructor privado para evitar instanciación

  /// Logos de la iglesia
  static const String churchLogo = 'assets/images/logo/church_logo.png';
  static const String appIcon = 'assets/images/logo/app_icon.png';
  
  /// URL de respaldo del logo en Firebase Storage
  static const String churchLogoFallback = 
      'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2Flogoaem.png?alt=media&token=6cbd3bba-fc29-47f6-8cd6-d7ba2fd8ea0f';
  
  /// Carpeta de imágenes de anuncios
  static const String announcementsPath = 'assets/images/announcements/';
  
  /// Carpeta de imágenes de eventos
  static const String eventsPath = 'assets/images/events/';
  
  /// Biblia
  static const String biblePath = 'assets/bible/';
}
