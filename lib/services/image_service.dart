import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  /// Comprime una imagen para reducir su tamaño antes de subirla
  /// La calidad predeterminada ahora es 85 en lugar de 70 para mejor nitidez
  Future<File?> compressImage(File imageFile, {int quality = 85}) async {
    try {
      // Obtener extensión del archivo original
      final extension = path.extension(imageFile.path).toLowerCase();
      
      // Crear un directorio temporal donde guardar la imagen comprimida
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${const Uuid().v4()}$extension';
      
      // Comprimir según formato (jpeg, png, etc)
      CompressFormat format;
      switch (extension) {
        case '.jpg':
        case '.jpeg':
          format = CompressFormat.jpeg;
          break;
        case '.png':
          format = CompressFormat.png;
          break;
        case '.heic':
          format = CompressFormat.heic;
          break;
        case '.webp':
          format = CompressFormat.webp;
          break;
        default:
          format = CompressFormat.jpeg;
      }
      
      // Obtener información de la imagen para redimensionarla si es muy grande
      final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());
      final width = decodedImage.width;
      final height = decodedImage.height;
      
      // Verificar el tamaño del archivo para determinar si necesita compresión
      final fileSize = await imageFile.length();
      final fileSizeInMb = fileSize / (1024 * 1024);
      
      // Si la imagen ya es pequeña (<1MB) y de dimensiones razonables, aplicamos menos compresión
      if (fileSizeInMb < 1.0 && width <= 1500 && height <= 1500) {
        quality = 95; // Mayor calidad para imágenes pequeñas
      }
      
      // Si la imagen es mayor de 1600px en cualquier dimensión, la reducimos
      // Aumentamos el límite de 1200 a 1600 para mantener mejor calidad
      int? targetWidth;
      int? targetHeight;
      
      if (width > 1600 || height > 1600) {
        final aspectRatio = width / height;
        if (width > height) {
          targetWidth = 1600;
          targetHeight = (1600 / aspectRatio).round();
        } else {
          targetHeight = 1600;
          targetWidth = (1600 * aspectRatio).round();
        }
      }
      
      // Comprimir la imagen
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        format: format,
        minWidth: targetWidth ?? width,
        minHeight: targetHeight ?? height,
        // No usamos minSize ya que no está disponible en flutter_image_compress
      );
      
      if (result != null) {
        // Verificar que la compresión no redujo demasiado la calidad
        final compressedSize = await File(result.path).length();
        if (compressedSize < fileSize * 0.1) {
          // Si se redujo más del 90%, posiblemente perdimos demasiada calidad
          // En este caso, recomprimimos con mayor calidad
          await File(result.path).delete();
          return compressImage(imageFile, quality: quality + 10);
        }
        return File(result.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error al comprimir imagen: $e');
      return null;
    }
  }
  
  /// Limpia la caché de imágenes cuando ya no se necesiten
  Future<void> clearImageCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final directory = Directory(tempDir.path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        await directory.create();
      }
    } catch (e) {
      debugPrint('Error al limpiar la caché de imágenes: $e');
    }
  }
} 