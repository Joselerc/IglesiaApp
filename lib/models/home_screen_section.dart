import 'package:cloud_firestore/cloud_firestore.dart';

enum HomeScreenSectionType {
  announcements,
  cults,
  servicesGrid,
  events,
  counseling,
  customPageList, // Representa la sección "Saiba Mais" o similares
  videos,
  liveStream,
  donations,
  courses, // Nueva sección de Cursos Online
  ministries,
  groups,
  privatePrayer,
  publicPrayer,
  workSchedules, // Nueva sección de Escalas de Trabajo
  unknown // Para manejo de errores o tipos futuros
}

class HomeScreenSection {
  final String id;
  final String title; // Título visible, editable para customPageList
  final HomeScreenSectionType type;
  final int order;
  final bool isActive;
  final List<String>? pageIds; // Solo para customPageList
  final bool hideWhenEmpty; // Para eventos y anuncios: ocultar cuando no hay contenido
  // final String? layout; // Posible campo futuro para layout (list, grid, carousel)

  HomeScreenSection({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
    this.isActive = true,
    this.pageIds,
    this.hideWhenEmpty = false, // Por defecto no ocultar
    // this.layout,
  });

  factory HomeScreenSection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<String>? parsedPageIds;
    if (data['pageIds'] is List) {
      parsedPageIds = (data['pageIds'] as List)
          .whereType<DocumentReference>()
          .map((ref) => ref.id)
          .toList();
    }
    
    return HomeScreenSection(
      id: doc.id,
      title: data['title'] ?? '', // Título por defecto si no existe
      type: _stringToSectionType(data['type']), // Convierte string a enum
      order: data['order'] ?? 999, // Orden alto por defecto si no existe
      isActive: data['isActive'] ?? true, // Activo por defecto
      pageIds: parsedPageIds,
      hideWhenEmpty: data['hideWhenEmpty'] ?? false, // Por defecto no ocultar
      // layout: data['layout'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'type': _sectionTypeToString(type), // Convierte enum a string
      'order': order,
      'isActive': isActive,
      'hideWhenEmpty': hideWhenEmpty,
      if (pageIds != null) 'pageIds': pageIds,
      // if (layout != null) 'layout': layout,
      // Considera añadir 'createdAt', 'updatedAt' si es necesario
    };
  }

  // Helper para convertir string a Enum desde Firestore
  static HomeScreenSectionType _stringToSectionType(String? type) {
    switch (type) {
      case 'announcements': return HomeScreenSectionType.announcements;
      case 'cults': return HomeScreenSectionType.cults;
      case 'servicesGrid': return HomeScreenSectionType.servicesGrid;
      case 'events': return HomeScreenSectionType.events;
      case 'counseling': return HomeScreenSectionType.counseling;
      case 'customPageList': return HomeScreenSectionType.customPageList;
      case 'videos': return HomeScreenSectionType.videos;
      case 'liveStream': return HomeScreenSectionType.liveStream;
      case 'donations': return HomeScreenSectionType.donations;
      case 'courses': return HomeScreenSectionType.courses;
      case 'ministries': return HomeScreenSectionType.ministries;
      case 'groups': return HomeScreenSectionType.groups;
      case 'privatePrayer': return HomeScreenSectionType.privatePrayer;
      case 'publicPrayer': return HomeScreenSectionType.publicPrayer;
      case 'workSchedules': return HomeScreenSectionType.workSchedules;
      default: return HomeScreenSectionType.unknown;
    }
  }

  // Helper para convertir Enum a String para Firestore
  static String _sectionTypeToString(HomeScreenSectionType type) {
    switch (type) {
      case HomeScreenSectionType.announcements: return 'announcements';
      case HomeScreenSectionType.cults: return 'cults';
      case HomeScreenSectionType.servicesGrid: return 'servicesGrid';
      case HomeScreenSectionType.events: return 'events';
      case HomeScreenSectionType.counseling: return 'counseling';
      case HomeScreenSectionType.customPageList: return 'customPageList';
      case HomeScreenSectionType.videos: return 'videos';
      case HomeScreenSectionType.liveStream: return 'liveStream';
      case HomeScreenSectionType.donations: return 'donations';
      case HomeScreenSectionType.courses: return 'courses';
      case HomeScreenSectionType.ministries: return 'ministries';
      case HomeScreenSectionType.groups: return 'groups';
      case HomeScreenSectionType.privatePrayer: return 'privatePrayer';
      case HomeScreenSectionType.publicPrayer: return 'publicPrayer';
      case HomeScreenSectionType.workSchedules: return 'workSchedules';
      default: return 'unknown';
    }
  }
} 