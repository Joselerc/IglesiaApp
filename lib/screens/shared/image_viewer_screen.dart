import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Verificar se a URL é válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida no ImageViewerScreen: $imageUrl');
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
          fileName,
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
                  'Não foi possível carregar a imagem',
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
    // Verificar se a URL é válida
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida no _shareImage: $imageUrl');
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
      
      final http.Response response = await http.get(Uri.parse(imageUrl));
      
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.bodyBytes);
      
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
      final uri = Uri.parse(imageUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida no _downloadImage: $imageUrl');
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
        content: Text('Deseja baixar "$fileName"?'),
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
      // Solicitar permissões de armazenamento
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissões de armazenamento necessárias')),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciando download...')),
      );
      
      // Obter diretório de downloads
      final Directory? downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir == null) {
        throw Exception('Não foi possível acessar o diretório de downloads');
      }
      
      // Verificar si FlutterDownloader está disponible (no en iOS por ahora)
      if (Platform.isIOS) {
        throw Exception('Download temporariamente indisponível no iOS');
      }
      
      // Usar flutter_downloader para baixar
      final taskId = await FlutterDownloader.enqueue(
        url: imageUrl,
        savedDir: downloadsDir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );
      
      if (taskId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download iniciado')),
        );
      } else {
        throw Exception('Não foi possível iniciar o download');
      }
    } catch (e) {
      debugPrint('Erro ao baixar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar: Funcionalidade temporariamente indisponível')),
      );
    }
  }
} 