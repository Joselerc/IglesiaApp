import 'package:flutter/material.dart';
import 'package:flutter_media_downloader/flutter_media_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;
  final MediaDownload _mediaDownloader = MediaDownload();

  ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar si la URL es válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida en ImageViewerScreen: $imageUrl');
    }

    if (!isValidUrl) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            fileName,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 80, color: Colors.white.withOpacity(0.7)),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar la imagen',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'La URL de la imagen no es válida',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          fileName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
            tooltip: 'Descargar',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, imageChunkEvent) => Center(
            child: CircularProgressIndicator(
              value: imageChunkEvent?.cumulativeBytesLoaded != null && 
                    imageChunkEvent?.expectedTotalBytes != null
                  ? imageChunkEvent!.cumulativeBytesLoaded / imageChunkEvent.expectedTotalBytes!
                  : null,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 80, color: Colors.white.withOpacity(0.7)),
                const SizedBox(height: 16),
                Text(
                  'No se pudo cargar la imagen',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    // Verificar si la URL es válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida en _shareImage: $imageUrl');
    }

    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede compartir: URL de imagen inválida')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparando imagen para compartir...')),
      );
      
      final http.Response response = await http.get(Uri.parse(imageUrl));
      
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.bodyBytes);
      
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Imagen compartida desde Church App',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir: $e')),
      );
    }
  }

  Future<void> _downloadImage(BuildContext context) async {
    // Verificar si la URL es válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida en _downloadImage: $imageUrl');
    }

    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede descargar: URL de imagen inválida')),
      );
      return;
    }

    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descargar imagen'),
        content: Text('¿Quieres descargar "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
    
    if (shouldDownload != true) {
      return;
    }
    
    try {
      await Permission.storage.request();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciando descarga...')),
      );
      
      try {
        await _mediaDownloader.downloadMedia(
          context,
          imageUrl,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen descargada correctamente')),
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permisos necesarios'),
            content: const Text('No se pudo descargar. Por favor, concede permisos de almacenamiento manualmente en la configuración.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la descarga: $e')),
      );
    }
  }
} 