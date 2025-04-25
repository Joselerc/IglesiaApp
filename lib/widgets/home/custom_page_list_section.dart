import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/dynamic_page_viewer_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../common/app_card.dart';
import '../../utils/icon_utils.dart'; // Importar el helper creado
import '../../theme/app_spacing.dart'; // Importar AppSpacing

class CustomPageListSection extends StatelessWidget {
  final String title;
  final List<String> pageIds;

  const CustomPageListSection({
    super.key,
    required this.title,
    required this.pageIds,
  });

  @override
  Widget build(BuildContext context) {
    final String sectionTitle = title.isNotEmpty ? title : 'Saiba Mais'; 

    if (pageIds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcular la altura dinámicamente basada en un ancho fijo y aspect ratio
    const double cardWidth = 180;
    const double cardImageHeight = cardWidth * (9 / 16); // Para aspect ratio 16:9
    const double textPadding = 12 * 2 + 8; // Padding vertical + Sizedbox
    const double approxTextHeight = 40; // Estimación para 2 líneas de texto
    const double iconCardHeight = 90 + textPadding + approxTextHeight; // Altura estimada para tarjeta con icono
    const double imageCardHeight = cardImageHeight + textPadding + approxTextHeight; // Altura estimada para tarjeta con imagen
    // Usar la altura mayor como referencia para el SizedBox, o una altura fija si prefieres
    const double listHeight = imageCardHeight + 8; // Añadir un poco de padding extra

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            sectionTitle, 
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: listHeight, // Usar altura calculada o una fija adecuada
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pageContent')
                .where(FieldPath.documentId, whereIn: pageIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text('Erro: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink(); 
              }

              final docsMap = {for (var doc in snapshot.data!.docs) doc.id: doc};
              final orderedDocs = pageIds.map((id) => docsMap[id]).where((doc) => doc != null).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: orderedDocs.length,
                itemBuilder: (context, index) {
                  final pageDoc = orderedDocs[index]!;
                  final pageData = pageDoc.data() as Map<String, dynamic>? ?? {};
                  final pageTitle = pageData['title'] as String? ?? 'Página sem título';
                  final pageId = pageDoc.id;
                  
                  final cardDisplayType = pageData['cardDisplayType'] as String? ?? 'icon';
                  final cardImageUrl = pageData['cardImageUrl'] as String? ?? '';
                  final cardIconName = pageData['cardIconName'] as String? ?? 'article_outlined';

                  return Container(
                    width: cardWidth, 
                    margin: const EdgeInsets.only(right: 12),
                    child: AppCard(
                      padding: EdgeInsets.zero, 
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DynamicPageViewScreen(pageId: pageId),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Contenido superior (Imagen o Icono)
                          Expanded(
                            flex: cardDisplayType == 'image' ? 9 : 5, // Dar más espacio a la imagen (aproximado 16:9 vs icono)
                            child: cardDisplayType == 'image' && cardImageUrl.isNotEmpty
                                ? _buildCardImage(cardImageUrl)
                                : _buildCardIcon(cardIconName), // Ya no necesita título aquí
                          ),
                          // Título debajo
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Text(
                              pageTitle,
                              style: AppTextStyles.bodyText2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ), 
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardImage(String imageUrl) {
    // La imagen ahora ocupa el espacio superior dado por Expanded
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppSpacing.md), 
        topRight: Radius.circular(AppSpacing.md),
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity, // Asegura que llene el ancho
        height: double.infinity, // Asegura que llene la altura dada por Expanded
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.warmSand.withOpacity(0.3),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
        errorBuilder: (context, error, stacktrace) {
          return Container(
            color: AppColors.warmSand,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
          );
        },
      ),
    );
  }

  Widget _buildCardIcon(String iconName) {
    final IconData iconData = IconUtils.getIconDataFromString(iconName);
    // El icono ahora ocupa el espacio superior dado por Expanded
    // Centrado dentro de ese espacio
    return Center(
      child: Icon(iconData, color: AppColors.primary, size: 40),
    );
  }
}

// Helper para convertir nombre de icono a IconData (Crear archivo utils/icon_utils.dart)
/* 
// En utils/icon_utils.dart
import 'package:flutter/material.dart';

class IconUtils {
  static const Map<String, IconData> _iconMap = {
    'article_outlined': Icons.article_outlined,
    'info_outline': Icons.info_outline,
    'star_outline': Icons.star_outline,
    'help_outline': Icons.help_outline,
    'book_outlined': Icons.book_outlined,
    'contact_page_outlined': Icons.contact_page_outlined,
    // Añadir más iconos según sea necesario
  };

  static IconData getIconDataFromString(String iconName) {
    return _iconMap[iconName] ?? Icons.article_outlined; // Devuelve un icono por defecto
  }
}
*/ 