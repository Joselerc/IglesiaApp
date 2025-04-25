import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo simple para representar una página personalizada de la colección 'pageContent'.
/// Usado principalmente para la selección en la pantalla de edición de secciones.
class PageContentModel {
  final String id;
  final String title;
  // Puedes añadir otros campos si los necesitas para la selección o visualización,
  // como 'iconName' o 'imageUrl' si los implementas.

  PageContentModel({
    required this.id,
    required this.title,
  });

  /// Crea una instancia de PageContentModel desde un DocumentSnapshot de Firestore.
  factory PageContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PageContentModel(
      id: doc.id,
      // Asegúrate de que el campo 'title' exista en tus documentos de pageContent
      title: data['title'] as String? ?? 'Página sem Título', 
    );
  }
} 