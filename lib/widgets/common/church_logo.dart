import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_assets.dart';
import '../../services/app_config_service.dart';

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
    return StreamBuilder<DocumentSnapshot>(
      stream: AppConfigService().getAppConfigStream(),
      builder: (context, snapshot) {
        // Intentar obtener el logo personalizado
        String? customLogoUrl;
        
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final config = snapshot.data!.data() as Map<String, dynamic>?;
          if (config != null && config['logoUrl'] != null && config['logoUrl'].toString().isNotEmpty) {
            customLogoUrl = config['logoUrl'];
          }
        }
        
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
            child: customLogoUrl != null
                ? CachedNetworkImage(
                    imageUrl: customLogoUrl,
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
                      return _buildDefaultLogo();
                    },
                  )
                : _buildDefaultLogo(),
          ),
        );
      },
    );
  }
  
  Widget _buildDefaultLogo() {
    return Image.asset(
      AppAssets.churchLogo,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('⚠️ CHURCH_LOGO - Error cargando asset local: $error');
        return CachedNetworkImage(
          imageUrl: AppAssets.churchLogoFallback,
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
    );
  }
} 