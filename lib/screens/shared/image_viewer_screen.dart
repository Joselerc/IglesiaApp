import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String fileName;

  const ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Verificar se a URL é válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(widget.imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida no ImageViewerScreen: $widget.imageUrl');
    }

    if (!isValidUrl) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.fileName,
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
                'Não foi possível carregar a imagem',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'A URL da imagem não é válida',
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
          widget.fileName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
            tooltip: 'Baixar',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(context),
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: PhotoView(
              imageProvider: NetworkImage(widget.imageUrl),
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
                      'Não foi possível carregar a imagem',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Indicador de loading para downloads
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Baixando imagem...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    // Verificar se a URL é válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(widget.imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida no _shareImage: $widget.imageUrl');
    }

    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível compartilhar: URL da imagem inválida')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparando imagem para compartilhar...')),
      );
      
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${widget.fileName}';
      
      // Usar Dio para download
      await Dio().download(widget.imageUrl, tempPath);
      
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Imagem compartilhada da Igreja Amor em Movimento',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar: $e')),
      );
    }
  }

  Future<void> _downloadImage(BuildContext context) async {
    // Verificar si la URL es válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(widget.imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida no _downloadImage: $widget.imageUrl');
    }

    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível baixar: URL da imagem inválida')),
      );
      return;
    }

    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Baixar imagem'),
        content: Text('Deseja baixar "$widget.fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Baixar'),
          ),
        ],
      ),
    );
    
    if (shouldDownload != true) {
      return;
    }
    
    try {
      setState(() => _isLoading = true);
      
      // Obter diretório de downloads baseado na plataforma
      Directory directory;
      if (Platform.isAndroid) {
        // Para Android 13+ (API 33+), no necesitamos permisos para el directorio de la app
        // Para versiones anteriores, solicitar permisos si es necesario
        try {
          // Intentar usar directorio externo primero
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = externalDir;
          } else {
            // Fallback a directorio de aplicación
            directory = await getApplicationDocumentsDirectory();
          }
        } catch (e) {
          // Si hay problemas con permisos, usar directorio de aplicación
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // iOS: usar diretório de documentos da aplicação
        directory = await getApplicationDocumentsDirectory();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciando download...')),
      );
      
      // Usar Dio para download (compatível iOS + Android)
      final path = '${directory.path}/${widget.fileName}';
      await Dio().download(widget.imageUrl, path);
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagem salva em: $path')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Erro ao baixar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar: $e')),
      );
    }
  }
} 