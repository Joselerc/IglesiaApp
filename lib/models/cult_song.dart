// lib/models/cult_song.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CultSong {
  final String id;
  final String cultId;
  final String name;
  final int duration; // en segundos
  final int order;
  final List<CultSongFile> files;

  CultSong({
    required this.id,
    required this.cultId,
    required this.name,
    required this.duration,
    required this.order,
    required this.files,
  });

  factory CultSong.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Añadir información de depuración
    print('Convirtiendo documento a CultSong: ${doc.id}');
    print('Datos del documento: $data');
    
    // Obtener el ID del culto
    String cultId = '';
    if (data['cultId'] != null) {
      if (data['cultId'] is DocumentReference) {
        cultId = data['cultId'].id;
        print('cultId obtenido de DocumentReference: $cultId');
      } else if (data['cultId'] is String) {
        cultId = data['cultId'];
        print('cultId obtenido de String: $cultId');
      } else {
        print('cultId tiene un tipo desconocido: ${data['cultId'].runtimeType}');
      }
    } else {
      print('cultId es nulo');
    }
    
    // Convertir la lista de archivos
    List<CultSongFile> files = [];
    if (data['files'] != null && data['files'] is List) {
      files = (data['files'] as List).map((file) {
        return CultSongFile(
          name: file['name'] ?? '',
          fileUrl: file['fileUrl'] ?? '',
          fileType: file['fileType'] ?? 'mp3',
        );
      }).toList();
    }
    
    return CultSong(
      id: doc.id,
      cultId: cultId,
      name: data['name'] ?? '',
      duration: data['duration'] ?? 0,
      order: data['order'] ?? 0,
      files: files,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cultId': FirebaseFirestore.instance.collection('cults').doc(cultId),
      'name': name,
      'duration': duration,
      'order': order,
      'files': files.map((file) => file.toMap()).toList(),
    };
  }
}

class CultSongFile {
  final String name;
  final String fileUrl;
  final String fileType;

  CultSongFile({
    required this.name,
    required this.fileUrl,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'fileUrl': fileUrl,
      'fileType': fileType,
    };
  }
}