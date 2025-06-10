import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChurchLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final Color? backgroundColor;
  final bool showLoadingIndicator;

  const ChurchLogo({
    super.key,
    this.height = 100,
    this.fit = BoxFit.contain,
    this.backgroundColor,
    this.showLoadingIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height, // Mantener aspecto cuadrado
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logoaem.png',
          height: height,
          fit: fit,
          // Si el asset local falla, mostrar un fallback
          errorBuilder: (context, error, stackTrace) {
            debugPrint('⚠️ CHURCH_LOGO - Error cargando asset local: $error');
            return CachedNetworkImage(
              imageUrl: 'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2Flogoaem.png?alt=media&token=6cbd3bba-fc29-47f6-8cd6-d7ba2fd8ea0f',
              height: height,
              fit: fit,
              placeholder: showLoadingIndicator
                  ? (context, url) => Container(
                      height: height,
                      width: height,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              errorWidget: (context, url, error) {
                debugPrint('❌ CHURCH_LOGO - Error cargando desde red: $error');
                return Container(
                  height: height,
                  width: height,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.church,
                    size: height * 0.5,
                    color: Colors.grey[600],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 