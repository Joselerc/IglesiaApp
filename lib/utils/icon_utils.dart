import 'package:flutter/material.dart';

// Mapa que asocia nombres de string con IconData de Material Icons
const Map<String, IconData> _iconMap = {
  // Iconos comunes
  'article': Icons.article,
  'article_outlined': Icons.article_outlined,
  'info': Icons.info,
  'info_outline': Icons.info_outline,
  'star': Icons.star,
  'star_outline': Icons.star_outline,
  'help': Icons.help,
  'help_outline': Icons.help_outline,
  'book': Icons.book,
  'book_outlined': Icons.book_outlined,
  'contact_page': Icons.contact_page,
  'contact_page_outlined': Icons.contact_page_outlined,
  'event': Icons.event,
  'event_available': Icons.event_available,
  'church': Icons.church,
  'home': Icons.home,
  'home_outlined': Icons.home_outlined,
  'settings': Icons.settings,
  'settings_outlined': Icons.settings_outlined,
  'person': Icons.person,
  'person_outline': Icons.person_outline,
  'group': Icons.group,
  'group_outlined': Icons.group_outlined,
  'people': Icons.people,
  'people_outline': Icons.people_outline,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'videocam': Icons.videocam,
  'videocam_outlined': Icons.videocam_outlined,
  'photo_camera': Icons.photo_camera,
  'photo_camera_outlined': Icons.photo_camera_outlined,
  'link': Icons.link,
  'attach_file': Icons.attach_file,
  'location_on': Icons.location_on,
  'location_on_outlined': Icons.location_on_outlined,
  'map': Icons.map,
  'map_outlined': Icons.map_outlined,
  'calendar_today': Icons.calendar_today,
  'calendar_month': Icons.calendar_month,
  'schedule': Icons.schedule,
  'access_time': Icons.access_time,
  'work': Icons.work,
  'work_outline': Icons.work_outline,
  'support_agent': Icons.support_agent,
  'admin_panel_settings': Icons.admin_panel_settings,
  'admin_panel_settings_outlined': Icons.admin_panel_settings_outlined,
  'edit': Icons.edit,
  'edit_outlined': Icons.edit_outlined,
  'add': Icons.add,
  'add_circle': Icons.add_circle,
  'add_circle_outline': Icons.add_circle_outline,
  'remove': Icons.remove,
  'delete': Icons.delete,
  'delete_outline': Icons.delete_outline,
  'check': Icons.check,
  'check_circle': Icons.check_circle,
  'check_circle_outline': Icons.check_circle_outline,
  'close': Icons.close,
  'arrow_forward_ios': Icons.arrow_forward_ios,
  'arrow_back_ios': Icons.arrow_back_ios,
  'menu': Icons.menu,
  'more_vert': Icons.more_vert,

  // Puedes añadir más iconos aquí según necesites
  // El formato es: 'nombre_del_icono_en_string': Icons.nombreDelIconoEnCodigo,
};

class IconUtils {
  /// Convierte un nombre de icono (String) a su correspondiente IconData.
  /// 
  /// Si el nombre no se encuentra en el mapa interno, devuelve un icono por defecto 
  /// (actualmente Icons.article_outlined).
  static IconData getIconDataFromString(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.article_outlined; // Icono por defecto si el nombre es nulo o vacío
    }
    return _iconMap[iconName.toLowerCase()] ?? Icons.article_outlined; // Busca en minúsculas y devuelve defecto si no lo encuentra
  }

  /// Devuelve la lista de nombres de iconos disponibles (las claves del mapa).
  static List<String> getAvailableIconNames() {
    return _iconMap.keys.toList();
  }
} 