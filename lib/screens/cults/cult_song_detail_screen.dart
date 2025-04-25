import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../models/cult.dart';
import '../../models/cult_song.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../theme/app_colors.dart';

// Widget para mostrar el progreso de carga
class UploadProgressWidget extends StatefulWidget {
  final File file;
  final String fileName;
  final String fileExtension;
  final Cult cult;
  final CultSong cultSong;
  final VoidCallback onUploadComplete;
  
  const UploadProgressWidget({
    Key? key,
    required this.file,
    required this.fileName,
    required this.fileExtension,
    required this.cult,
    required this.cultSong,
    required this.onUploadComplete,
  }) : super(key: key);
  
  @override
  State<UploadProgressWidget> createState() => _UploadProgressWidgetState();
}

class _UploadProgressWidgetState extends State<UploadProgressWidget> {
  double _progress = 0.0;
  bool _isUploading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _uploadFile();
  }
  
  Future<void> _uploadFile() async {
    try {
      // Subir archivo a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('cult_songs')
          .child(widget.cult.id)
          .child(widget.cultSong.id)
          .child(widget.fileName);
      
      final uploadTask = storageRef.putFile(widget.file);
      
      // Monitorear el progreso de la carga
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _progress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });
      
      // Esperar a que se complete la carga
      await uploadTask.whenComplete(() => null);
      
      // Obtener la URL de descarga
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Obtener los archivos actuales
      final doc = await FirebaseFirestore.instance
          .collection('cult_songs')
          .doc(widget.cultSong.id)
          .get();
      
      if (!doc.exists) {
        throw Exception('A música não existe');
      }
      
      final songData = doc.data() as Map<String, dynamic>;
      final files = List<dynamic>.from(songData['files'] as List<dynamic>? ?? []);
      
      // Determinar el tipo de archivo (documento o audio)
      final fileType = ['pdf', 'txt', 'doc', 'docx'].contains(widget.fileExtension) ? 'document' : 'audio';
      
      // Añadir el nuevo archivo
      files.add({
        'name': widget.fileName,
        'fileUrl': downloadUrl,
        'fileType': fileType,
        'fileExtension': widget.fileExtension,
        'uploadedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('cult_songs')
          .doc(widget.cultSong.id)
          .update({'files': files});
      
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        // Notificar que la carga se ha completado
        widget.onUploadComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Erro ao enviar arquivo: $e';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.fileExtension == 'pdf' ? Icons.picture_as_pdf :
                ['txt', 'doc', 'docx'].contains(widget.fileExtension) ? Icons.description :
                Icons.audio_file,
                color: widget.fileExtension == 'pdf' ? Colors.red :
                      ['txt', 'doc', 'docx'].contains(widget.fileExtension) ? Colors.blue :
                      Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Enviando: ${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ] else if (_errorMessage.isNotEmpty) ...[
            Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isUploading = true;
                  _errorMessage = '';
                });
                _uploadFile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
          ] else ...[
            const Text(
              'Arquivo enviado com sucesso',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget separado para el reproductor de audio
class AudioPlayerWidget extends StatefulWidget {
  final String fileUrl;
  final VoidCallback onStop;
  
  const AudioPlayerWidget({
    Key? key,
    required this.fileUrl,
    required this.onStop,
  }) : super(key: key);
  
  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  DateTime _lastPositionUpdate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    
    // Iniciar reproducción
    _initPlayer();
    
    // Configurar listeners
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _audioPlayer.seek(Duration.zero);
      }
    });
    
    // Limitamos las actualizaciones de posición para evitar parpadeos
    _audioPlayer.positionStream.listen((position) {
      final now = DateTime.now();
      // Solo actualizamos el estado cada 300ms para evitar parpadeos
      if (now.difference(_lastPositionUpdate).inMilliseconds > 300) {
        setState(() {
          _position = position;
        });
        _lastPositionUpdate = now;
      } else {
        // Actualizamos la variable sin llamar a setState
        _position = position;
      }
    });
    
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }
  
  Future<void> _initPlayer() async {
    try {
      setState(() {
        _isPlaying = true;
      });
      
      await _audioPlayer.setUrl(widget.fileUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Erro ao iniciar reprodução: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Barra de progreso
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.success,
              inactiveTrackColor: AppColors.success.withOpacity(0.2),
              thumbColor: AppColors.success,
              overlayColor: AppColors.success.withOpacity(0.3),
            ),
            child: Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
              onChanged: (value) {
                final position = Duration(seconds: value.toInt());
                _audioPlayer.seek(position);
              },
            ),
          ),
          // Tiempo actual y duración total
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Controles adicionales
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, color: AppColors.success),
                tooltip: 'Retroceder 10 segundos',
                onPressed: () {
                  final newPosition = Duration(
                    seconds: (_position.inSeconds - 10).clamp(0, _duration.inSeconds),
                  );
                  _audioPlayer.seek(newPosition);
                },
              ),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.success,
                  size: 48,
                ),
                tooltip: _isPlaying ? 'Pausar' : 'Reproduzir',
                onPressed: () {
                  if (_isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.stop_circle, color: AppColors.error, size: 36),
                tooltip: 'Parar',
                onPressed: () {
                  _audioPlayer.stop();
                  widget.onStop();
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, color: AppColors.success),
                tooltip: 'Avançar 10 segundos',
                onPressed: () {
                  final newPosition = Duration(
                    seconds: (_position.inSeconds + 10).clamp(0, _duration.inSeconds),
                  );
                  _audioPlayer.seek(newPosition);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CultSongDetailScreen extends StatefulWidget {
  final CultSong cultSong;
  final Cult cult;
  
  const CultSongDetailScreen({
    Key? key,
    required this.cultSong,
    required this.cult,
  }) : super(key: key);

  @override
  State<CultSongDetailScreen> createState() => _CultSongDetailScreenState();
}

class _CultSongDetailScreenState extends State<CultSongDetailScreen> {
  bool _isUploading = false;
  File? _uploadingFile;
  String? _uploadingFileName;
  String? _uploadingFileExtension;
  
  // Variables para el audio
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cultSong.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('cult_songs')
                .doc(widget.cultSong.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
              }
              
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text('Música não encontrada'),
                );
              }
              
              final songData = snapshot.data!.data() as Map<String, dynamic>;
              final files = List<Map<String, dynamic>>.from(songData['files'] as List<dynamic>? ?? []);
              
              // Separar archivos por tipo
              final documentFiles = files.where((file) => 
                file['fileType'] == 'document' || 
                ['pdf', 'txt', 'doc', 'docx'].contains(file['fileExtension'])
              ).toList();
              
              final audioFiles = files.where((file) => 
                file['fileType'] == 'audio' || 
                ['mp3', 'wav', 'aac', 'm4a'].contains(file['fileExtension'])
              ).toList();
              
              // Combinar listas con documentos primero
              final orderedFiles = [...documentFiles, ...audioFiles];
              
              return Column(
                children: [
                  // Información de la canción
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        Icon(Icons.music_note, size: 24, color: AppColors.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cultSong.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Duração: ${_formatDuration(widget.cultSong.duration)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Ordem: ${widget.cultSong.order + 1}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de archivos
                  Expanded(
                    child: orderedFiles.isEmpty && !_isUploading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Não há arquivos associados a esta música'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _isUploading ? null : _pickFile,
                                  icon: const Icon(Icons.upload_file),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  label: const Text('Enviar Arquivo'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: orderedFiles.length,
                            itemBuilder: (context, index) {
                              final file = orderedFiles[index];
                              final fileName = file['name'] as String? ?? 'Archivo sin nombre';
                              final fileUrl = file['fileUrl'] as String? ?? '';
                              final fileType = file['fileType'] as String? ?? 'audio';
                              final fileExtension = file['fileExtension'] as String? ?? '';
                              
                              // Determinar el icono según el tipo de archivo
                              IconData fileIcon;
                              Color iconColor;
                              
                              if (fileType == 'document' || ['pdf', 'txt', 'doc', 'docx'].contains(fileExtension)) {
                                if (fileExtension == 'pdf') {
                                  fileIcon = Icons.picture_as_pdf;
                                  iconColor = Colors.red;
                                } else {
                                  fileIcon = Icons.description;
                                  iconColor = Colors.blue;
                                }
                              } else {
                                fileIcon = Icons.audio_file;
                                iconColor = Colors.green;
                              }
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(fileIcon, color: iconColor),
                                      title: Text(fileName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Subido el ${_formatDate(file['uploadedAt'] as Timestamp?)}'),
                                          Text(
                                            fileType == 'document' ? 'Partitura/Documento' : 'Audio',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: fileType == 'document' ? Colors.blue[700] : Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (fileType == 'audio')
                                            IconButton(
                                              icon: Icon(
                                                _isPlaying && _currentlyPlayingUrl == fileUrl
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.green,
                                              ),
                                              onPressed: () => _playAudio(fileUrl),
                                            )
                                          else
                                            IconButton(
                                              icon: const Icon(Icons.open_in_new, color: Colors.blue),
                                              onPressed: () => _openDocument(fileUrl, fileName),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteFile(files.indexOf(file)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Mostrar controles de reproducción si es un archivo de audio y está reproduciéndose
                                    if (fileType == 'audio' && _isPlaying && _currentlyPlayingUrl == fileUrl)
                                      AudioPlayerWidget(
                                        fileUrl: fileUrl,
                                        onStop: () {
                                          setState(() {
                                            _isPlaying = false;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
          
          // Mostrar el widget de progreso de carga si hay un archivo subiendo
          if (_isUploading && _uploadingFile != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: UploadProgressWidget(
                file: _uploadingFile!,
                fileName: _uploadingFileName!,
                fileExtension: _uploadingFileExtension!,
                cult: widget.cult,
                cultSong: widget.cultSong,
                onUploadComplete: () {
                  setState(() {
                    _isUploading = false;
                    _uploadingFile = null;
                    _uploadingFileName = null;
                    _uploadingFileExtension = null;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Arquivo enviado com sucesso')),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _pickFile,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'data desconhecida';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Método para seleccionar un archivo
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'pdf', 'txt', 'doc', 'docx'],
      );
      
      if (result == null || result.files.single.path == null) return;
      
      final file = File(result.files.single.path!);
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase().replaceAll('.', '');
      
      setState(() {
        _isUploading = true;
        _uploadingFile = file;
        _uploadingFileName = fileName;
        _uploadingFileExtension = fileExtension;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }
  
  // Método para reproducir audio
  void _playAudio(String url) {
    // Si ya está reproduciendo, detener
    if (_isPlaying && _currentlyPlayingUrl == url) {
      setState(() {
        _isPlaying = false;
        _currentlyPlayingUrl = null;
      });
    } else {
      // Mostrar un SnackBar para indicar que se está cargando
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carregando áudio...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Iniciar reproducción
      setState(() {
        _isPlaying = true;
        _currentlyPlayingUrl = url;
      });
    }
  }
  
  // Método para abrir documentos
  Future<void> _openDocument(String url, String fileName) async {
    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando documento...'),
          ],
        ),
      ),
    );
    
    try {
      // Verificar si la URL es válida
      final Uri uri = Uri.parse(url);
      
      // Para archivos PDF, podemos intentar abrirlos directamente
      if (fileName.toLowerCase().endsWith('.pdf')) {
        if (await canLaunchUrl(uri)) {
          // Cerrar el diálogo de carga
          Navigator.of(context).pop();
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Si no se puede abrir directamente, descargar y abrir localmente
          await _downloadAndOpenFile(url, fileName);
          // Cerrar el diálogo de carga
          if (context.mounted) Navigator.of(context).pop();
        }
      } else {
        // Para otros tipos de documentos, intentar abrir con url_launcher
        if (await canLaunchUrl(uri)) {
          // Cerrar el diálogo de carga
          Navigator.of(context).pop();
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Não é possível abrir o documento';
        }
      }
    } catch (e) {
      // Cerrar el diálogo de carga en caso de error
      if (context.mounted) Navigator.of(context).pop();
      
      print('Erro ao abrir documento: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir documento: $e')),
        );
      }
    }
  }
  
  // Método auxiliar para descargar y abrir archivos localmente
  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    try {
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      
      // Verificar si el archivo ya existe
      final file = File(filePath);
      if (await file.exists()) {
        // Si ya existe, intentar abrirlo directamente
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      
      // Descargar el archivo con progreso
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Actualizar el diálogo de progreso si está montado
            if (context.mounted) {
              // Actualizar el texto del diálogo con el progreso
              final progress = (received / total * 100).toStringAsFixed(0);
              Navigator.of(context).pop(); // Cerrar el diálogo actual
              
              // Mostrar un nuevo diálogo con el progreso actualizado
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: received / total,
                      ),
                      const SizedBox(height: 16),
                      Text('Baixando: $progress%'),
                    ],
                  ),
                ),
              );
            }
          }
        },
      );
      
      // Abrir el archivo descargado
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não é possível abrir o arquivo baixado';
      }
    } catch (e) {
      print('Erro ao baixar e abrir arquivo: $e');
      rethrow;
    }
  }
  
  Future<void> _deleteFile(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir arquivo'),
        content: const Text('Tem certeza que deseja excluir este arquivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // Obtener los archivos actuales
      final doc = await FirebaseFirestore.instance
          .collection('cult_songs')
          .doc(widget.cultSong.id)
          .get();
      
      if (!doc.exists) return;
      
      final songData = doc.data() as Map<String, dynamic>;
      final files = List<dynamic>.from(songData['files'] as List<dynamic>? ?? []);
      
      // Añadir información de depuración
      print('Eliminando archivo en el índice: $index');
      print('Número de archivos antes de eliminar: ${files.length}');
      
      // Eliminar el archivo de Storage
      if (index >= 0 && index < files.length) {
        final file = files[index] as Map<String, dynamic>;
        final fileUrl = file['fileUrl'] as String? ?? '';
        
        print('URL del archivo a eliminar: $fileUrl');
        
        if (fileUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(fileUrl).delete();
            print('Arquivo excluído do Storage');
          } catch (e) {
            print('Erro ao excluir arquivo do Storage: $e');
          }
        }
        
        // Eliminar el archivo de la lista
        files.removeAt(index);
        print('Arquivo excluído da lista');
        print('Número de arquivos após exclusão: ${files.length}');
        
        // Actualizar en Firestore
        await FirebaseFirestore.instance
            .collection('cult_songs')
            .doc(widget.cultSong.id)
            .update({'files': files});
        
        print('Lista de arquivos atualizada no Firestore');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo excluído com sucesso')),
        );
      }
    } catch (e) {
      print('Erro ao excluir arquivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir arquivo: $e')),
      );
    }
  }
} 