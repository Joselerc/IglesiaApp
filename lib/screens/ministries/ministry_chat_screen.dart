import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../models/ministry.dart';
import '../../screens/shared/image_viewer_screen.dart';
import '../../screens/ministries/ministry_details_screen.dart';
import 'dart:async';

class MinistryChatScreen extends StatefulWidget {
  final Ministry ministry;

  const MinistryChatScreen({
    Key? key,
    required this.ministry,
  }) : super(key: key);

  @override
  State<MinistryChatScreen> createState() => _MinistryChatScreenState();
}

class _MinistryChatScreenState extends State<MinistryChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isAdmin = false;
  bool _isUploading = false;
  bool _isRecording = false;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  // FlutterSound en lugar de Record
  final FlutterSoundRecorder _soundRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;

  // Mantenemos un mapa para controlar qué audio está reproduciéndose actualmente
  final Map<String, bool> _playingAudios = {};
  String? _currentlyPlayingAudioId;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _soundRecorder.openRecorder();
    await _soundPlayer.openPlayer();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  @override
  void dispose() {
    _soundRecorder.closeRecorder();
    _soundPlayer.closePlayer();
    super.dispose();
  }

  void _checkAdminStatus() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _isAdmin = widget.ministry.adminIds.contains(currentUser.uid);
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas administradores podem enviar arquivos')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      
      if (['.jpg', '.jpeg', '.png', '.gif'].contains(fileExtension)) {
        // Para imágenes, mostrar diálogo de confirmación
        await _showImagePreviewDialog(file, fileName, fileExtension);
      } else {
        // Para otros archivos, seguir con el flujo actual
        setState(() {
          _isUploading = true;
        });
        
        await _uploadFile(file, fileName, fileExtension);
      }
    }
  }

  Future<void> _showImagePreviewDialog(File file, String fileName, String fileExtension) async {
    final TextEditingController messageController = TextEditingController();
    
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar imagem'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vista previa de la imagen
              Container(
                width: 250, 
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo opcional para añadir un mensaje
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  hintText: 'Adicionar uma mensagem (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    
    if (shouldSend == true) {
      setState(() {
        _isUploading = true;
      });
      
      // Comprimir la imagen primero
      File fileToUpload = file;
      if (['.jpg', '.jpeg', '.png'].contains(fileExtension)) {
        try {
          fileToUpload = await _compressImage(file);
        } catch (e) {
          print('Error comprimiendo imagen: $e');
        }
      }
      
      // Subir el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'ministry_chats/${widget.ministry.id}/$timestamp-$fileName';
      
      try {
        // Subir archivo a Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = storageRef.putFile(fileToUpload);
        
        final snapshot = await uploadTask.whenComplete(() => null);
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Enviar mensaje con archivo adjunto
        await FirebaseFirestore.instance
            .collection('ministry_chat_messages')
            .add({
              'content': messageController.text.trim(), // Incluir texto opcional
              'authorId': FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid),
              'ministryId': FirebaseFirestore.instance
                  .collection('ministries')
                  .doc(widget.ministry.id),
              'createdAt': FieldValue.serverTimestamp(),
              'fileUrl': downloadUrl,
              'fileName': fileName,
              'fileType': 'image',
              'isDeleted': false,
            });
      } catch (e) {
        print('Error uploading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir el archivo: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  Future<void> _uploadFile(File file, String fileName, String fileExtension) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'ministry_chats/${widget.ministry.id}/$timestamp-$fileName';
      
      // Determinar el tipo de archivo
      String fileType = 'document';
      if (['.jpg', '.jpeg', '.png', '.gif'].contains(fileExtension)) {
        fileType = 'image';
      } else if (fileExtension == '.pdf') {
        fileType = 'pdf';
      }
      
      // Subir archivo a Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = storageRef.putFile(file);
      
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Enviar mensaje con archivo adjunto
      await FirebaseFirestore.instance
          .collection('ministry_chat_messages')
          .add({
            'content': '', 
            'authorId': FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid),
            'ministryId': FirebaseFirestore.instance
                .collection('ministries')
                .doc(widget.ministry.id),
            'createdAt': FieldValue.serverTimestamp(),
            'fileUrl': downloadUrl,
            'fileName': fileName,
            'fileType': fileType,
            'isDeleted': false,
          });
      
    } catch (e) {
      print('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir el archivo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Método para comprimir imágenes
  Future<File> _compressImage(File file) async {
    final extension = path.extension(file.path).toLowerCase();
    final tempDir = await getTemporaryDirectory();
    
    if (extension == '.png') {
      // Para PNG, usamos un enfoque específico para PNG
      final targetPath = '${tempDir.path}/${path.basenameWithoutExtension(file.path)}_compressed.png';
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.png, // Especificar formato PNG
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
      
      return result != null ? File(result.path) : file;
    } else if (extension == '.jpg' || extension == '.jpeg') {
      // Para JPEG/JPG
      final targetPath = '${tempDir.path}/${path.basename(file.path)}';
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
      
      return result != null ? File(result.path) : file;
    } else {
      // Otros formatos de imagen
      return file;
    }
  }

  Widget _buildFilePreview(String fileUrl, String fileType, String fileName, [String? messageId]) {
    // Detectar si es un archivo de audio basado en la extensión
    final isAudioFile = fileName.toLowerCase().endsWith('.aac') || 
                       fileName.toLowerCase().endsWith('.mp3') || 
                       fileName.toLowerCase().endsWith('.m4a') ||
                       fileName.toLowerCase().contains('audio');
    
    if (isAudioFile && messageId != null) {
      return _buildAudioPreview(fileUrl, fileName, messageId, '');
    }

    switch (fileType) {
      case 'image':
        return GestureDetector(
          onTap: () => _openImageViewer(fileUrl, fileName),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                fileUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      case 'pdf':
        return GestureDetector(
          onTap: () => _openFileForDownload(fileUrl, fileName),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.download, color: Colors.grey.shade700, size: 20),
              ],
            ),
          ),
        );
      default:
        return GestureDetector(
          onTap: () => _openFileForDownload(fileUrl, fileName),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.download, color: Colors.grey.shade700, size: 20),
              ],
            ),
          ),
        );
    }
  }

  void _openFileForDownload(String fileUrl, String fileName) async {
    // Si es un archivo de audio, no permitir la descarga
    if (fileName.toLowerCase().endsWith('.aac') || 
        fileName.toLowerCase().endsWith('.mp3') ||
        fileName.toLowerCase().endsWith('.m4a') ||
        fileName.toLowerCase().contains('audio')) {
      // Simplemente mostrar un mensaje o reproducir en lugar de descargar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O download de arquivos de áudio não é permitido')),
      );
      return;
    }
    
    // Para el resto de archivos, mantener la funcionalidad original
    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Baixar arquivo'),
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
    
    // Continuar con el proceso de descarga para archivos que no sean audio
    // Resto del código original...
  }

  void _openImageViewer(String imageUrl, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: imageUrl,
          fileName: fileName,
        ),
      ),
    );
  }

  // Nuevo método para mostrar diálogo de eliminación
  void _showDeleteDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir mensagem'),
        content: const Text('Tem certeza de que deseja excluir esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(messageId);
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Nuevo método para eliminar un mensaje
  void _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ministry_chat_messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
        'content': '',
        'fileUrl': null,
        'fileName': null,
        'fileType': null,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem excluída')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir mensagem: $e')),
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final message = _messageController.text.trim();
      _messageController.clear();

      try {
        await FirebaseFirestore.instance.collection('ministry_chat_messages').add({
          'content': message,
          'authorId': FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid),
          'ministryId': FirebaseFirestore.instance
              .collection('ministries')
              .doc(widget.ministry.id),
          'createdAt': FieldValue.serverTimestamp(),
          'isDeleted': false,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar mensagem: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MinistryDetailsScreen(ministry: widget.ministry),
            ),
          ),
          child: Row(
            children: [
              // Imagen o avatar del ministerio - solo verificar si está vacío
              widget.ministry.imageUrl.isNotEmpty
                ? CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(widget.ministry.imageUrl),
                  )
                : CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.ministry.name[0],
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.ministry.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Añadir la lista de miembros al estilo WhatsApp
                    FutureBuilder<List<String>>(
                      future: _getMinistryMembersNames(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            _isAdmin ? "Administrador" : "Membro",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          );
                        }
                        
                        final members = snapshot.data!;
                        String memberText = "";
                        
                        if (members.isEmpty) {
                          memberText = "Sem membros";
                        } else if (members.length == 1) {
                          memberText = members.first;
                        } else {
                          // Si el usuario actual está en la lista, mostrar "Tú" primero
                          List<String> displayMembers = List.from(members);
                          final currentUserIndex = displayMembers.indexWhere(
                            (m) => m.toLowerCase().contains("tú") || m.toLowerCase().contains("tu") || m.toLowerCase().contains("você")
                          );
                          
                          if (currentUserIndex >= 0) {
                            final currentUser = displayMembers.removeAt(currentUserIndex);
                            displayMembers.insert(0, currentUser);
                          }
                          
                          // Limitar la cantidad de nombres que se muestran
                          memberText = displayMembers.take(3).join(", ");
                          
                          if (members.length > 3) {
                            memberText += " e mais ${members.length - 3}";
                          }
                        }
                        
                        return Text(
                          memberText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MinistryDetailsScreen(ministry: widget.ministry),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ministry_chat_messages')
                  .where('ministryId', isEqualTo: FirebaseFirestore.instance
                      .collection('ministries')
                      .doc(widget.ministry.id))
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Sem mensagens ainda",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Extraer el documento completo y sus datos
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final messageId = message.id;
                    
                    // Extraer propiedades con valores predeterminados seguros
                    final authorId = messageData['authorId'] as DocumentReference?;
                    final String content = messageData['content'] ?? '';
                    final bool isDeleted = messageData['isDeleted'] ?? false;
                    
                    // Extraer propiedades de archivos con seguridad
                    final String? fileUrl = messageData['fileUrl'] as String?;
                    final String? fileName = messageData['fileName'] as String?;
                    final String? fileType = messageData['fileType'] as String?;
                    
                    // Solo proceder si tenemos un ID de autor válido
                    if (authorId == null) {
                      return const SizedBox.shrink(); // No mostrar mensajes sin autor
                    }
                    
                    final isCurrentUser = currentUserId == authorId.id;
                    
                    // Determinar si este mensaje es parte de una secuencia del mismo autor
                    bool isFirstInSequence = true;
                    if (index < messages.length - 1) {
                      final prevMessageData = messages[index + 1].data() as Map<String, dynamic>;
                      final prevAuthorId = prevMessageData['authorId'] as DocumentReference?;
                      
                      if (prevAuthorId != null && authorId.id == prevAuthorId.id) {
                        isFirstInSequence = false;
                      }
                    }
                    
                    // Convertir timestamp a DateTime
                    final timestamp = messageData['createdAt'] as Timestamp?;
                    final dateTime = timestamp?.toDate();
                    final timeString = dateTime != null ? DateFormat('HH:mm').format(dateTime) : '';
                    
                    // Ahora construir la UI con variables bien definidas
                    return FutureBuilder<DocumentSnapshot>(
                      future: authorId.get(),
                      builder: (context, authorSnapshot) {
                        // Datos del autor
                        String authorName = 'Usuario';
                        String? photoUrl;
                        
                        if (authorSnapshot.hasData && authorSnapshot.data!.exists) {
                          final authorData = authorSnapshot.data!.data() as Map<String, dynamic>?;
                          if (authorData != null) {
                            authorName = authorData['name'] ?? 
                                       authorData['displayName'] ?? 
                                       'Usuario';
                            photoUrl = authorData['photoUrl'] ?? 
                                     authorData['photoURL'];
                          }
                        }
                        
                        // Obtener color personalizado para el usuario
                        final Color userColor = getUserColor(authorId.id);
                        
                        return Align(
                          alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // Avatar y nombre (solo en el primer mensaje de la secuencia)
                                if (isFirstInSequence)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Avatar con inicial o foto
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: userColor.withOpacity(0.2),
                                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                          child: photoUrl == null ? Text(
                                            authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: userColor,
                                            ),
                                          ) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          authorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: userColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // El mensaje en sí - GestureDetector para longPress en todo el mensaje
                                GestureDetector(
                                  onLongPress: isCurrentUser && !isDeleted ? () => _showDeleteDialog(messageId) : null,
                                  child: Card(
                                    // Usar el mismo color para todos los mensajes
                                    color: Colors.white, // Color uniforme para todos los mensajes
                                    margin: EdgeInsets.only(
                                      left: 15,
                                      right: 15,
                                      top: isFirstInSequence ? 2 : 1,
                                      bottom: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: IntrinsicWidth( // Esto hace que el card se ajuste al contenido
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Contenido del mensaje con la hora a la derecha
                                            if (isDeleted)
                                              Row(
                                                mainAxisSize: MainAxisSize.min, // Para que se ajuste al contenido
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Esse mensagem foi deletada',
                                                    style: TextStyle(
                                                      fontStyle: FontStyle.italic,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Text(
                                                      timeString,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else if (fileUrl != null && fileType == 'image')
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (content.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(bottom: 4.0),
                                                      child: Text(content),
                                                    ),
                                                  _buildFilePreview(fileUrl, 'image', fileName ?? 'image.jpg', messageId),
                                                  Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 4),
                                                      child: Text(
                                                        timeString,
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else if (fileUrl != null && fileType == 'audio')
                                              _buildAudioPreview(fileUrl, fileName ?? 'audio.aac', messageId, timeString)
                                            else if (fileUrl != null)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  _buildFilePreview(fileUrl, fileType ?? 'document', fileName ?? 'archivo', messageId),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text(
                                                      timeString,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else if (content.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min, // Para que se ajuste al contenido
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Expanded(child: Text(content)),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 8),
                                                    child: Text(
                                                      timeString,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gravando: ${_formatDuration(_recordingDuration)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    onPressed: _stopRecording,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _cancelRecording,
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              left: 8.0, 
              right: 8.0, 
              top: 10.0,
              bottom: 10.0 + MediaQuery.of(context).padding.bottom, // Respetar área segura inferior
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                if (_isAdmin && !_isRecording)
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: _pickAndUploadFile,
                  ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      filled: true,
                      fillColor: Colors.grey[200],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    enabled: !_isRecording,
                    style: const TextStyle(fontSize: 16),
                    onChanged: (text) {
                      // Forzar actualización de UI cuando cambia el texto
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isRecording 
                          ? Icons.send 
                          : (_messageController.text.isNotEmpty 
                              ? Icons.send 
                              : Icons.mic),
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else if (_messageController.text.isNotEmpty) {
                        _sendMessage();
                      } else {
                        _startRecording();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Método para iniciar grabación
  Future<void> _startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _soundRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;
      
      setState(() {
        _isRecording = true;
      });
      
      // Iniciar timer para actualizar la UI con la duración
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        if (_soundRecorder.isRecording && _recordingStartTime != null) {
          setState(() {
            _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          });
        }
      });
    } catch (e) {
      print('Error al iniciar grabación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar la grabación: $e')),
      );
    }
  }

  // Método para cancelar grabación
  void _cancelRecording() async {
    _recordingTimer?.cancel();
    
    if (_soundRecorder.isRecording) {
      await _soundRecorder.stopRecorder();
      
      // Borrar el archivo temporal
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
      _recordingPath = null;
      _recordingStartTime = null;
      // No cambiar ningún otro estado que pueda afectar al botón de audio
    });
  }

  // Método para detener y enviar grabación
  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    
    try {
      if (_soundRecorder.isRecording) {
        String? path = await _soundRecorder.stopRecorder();
        
        // Calcular duración final antes de resetear
        final finalDuration = _recordingStartTime != null 
            ? DateTime.now().difference(_recordingStartTime!) 
            : _recordingDuration;
        
        // Solo subir si la grabación duró más de 1 segundo
        if (finalDuration.inSeconds > 1 && path != null) {
          setState(() {
            _isUploading = true;
          });
          
          // Subir archivo de audio
          try {
            final file = File(path);
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = 'audio_$timestamp.aac';
            final storagePath = 'ministry_chats/${widget.ministry.id}/$fileName';
            
            // Subir archivo a Firebase Storage
            final storageRef = FirebaseStorage.instance.ref().child(storagePath);
            final uploadTask = storageRef.putFile(file);
            
            final snapshot = await uploadTask.whenComplete(() => null);
            final downloadUrl = await snapshot.ref.getDownloadURL();
            
            // Enviar mensaje con audio adjunto
            await FirebaseFirestore.instance
                .collection('ministry_chat_messages')
                .add({
                  'content': '', 
                  'authorId': FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid),
                  'ministryId': FirebaseFirestore.instance
                      .collection('ministries')
                      .doc(widget.ministry.id),
                  'createdAt': FieldValue.serverTimestamp(),
                  'fileUrl': downloadUrl,
                  'fileName': fileName,
                  'fileType': 'audio',
                  'fileDuration': finalDuration.inSeconds, // Guardar duración
                  'isDeleted': false,
                });
          } catch (e) {
            print('Error al subir audio: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al subir el audio: $e')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La grabación es demasiado corta')),
          );
        }
      }
    } catch (e) {
      print('Error al detener grabación: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _isUploading = false;
        _recordingDuration = Duration.zero;
        _recordingPath = null;
        _recordingStartTime = null; // Resetear la variable
      });
    }
  }

  // Método para reproducir o pausar un audio específico por ID
  void _playPauseAudio(String audioId, String audioUrl) async {
    // Si ya hay un audio reproduciéndose, primero lo detenemos
    if (_currentlyPlayingAudioId != null && _currentlyPlayingAudioId != audioId) {
      await _soundPlayer.stopPlayer();
      setState(() {
        _playingAudios[_currentlyPlayingAudioId!] = false;
      });
    }
    
    setState(() {
      // Actualizamos el estado del audio actual
      final isPlaying = _playingAudios[audioId] ?? false;
      _playingAudios[audioId] = !isPlaying;
      
      if (!isPlaying) {
        _currentlyPlayingAudioId = audioId;
              } else {
        _currentlyPlayingAudioId = null;
      }
    });
    
    if (_playingAudios[audioId] == true) {
      await _soundPlayer.startPlayer(
                  fromURI: audioUrl,
                  whenFinished: () {
          setState(() {
            _playingAudios[audioId] = false;
            _currentlyPlayingAudioId = null;
          });
        },
      );
    } else {
      await _soundPlayer.pausePlayer();
    }
  }

  // Widget para mostrar el reproductor de audio (estilo mensaje)
  Widget _buildAudioPreview(String audioUrl, String fileName, String? messageId, String timeString) {
    // Si tenemos un ID de mensaje, usamos el estado de reproducción específico de ese mensaje
    final bool isPlaying = messageId != null 
        ? (_playingAudios[messageId] ?? false) 
        : _soundPlayer.isPlaying;

    // Intentar obtener la duración del audio desde Firebase
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ministry_chat_messages')
          .where('fileUrl', isEqualTo: audioUrl)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        // Obtener la duración del documento si está disponible
        int durationSeconds = 30; // Valor predeterminado
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final Map<String, dynamic> data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          if (data.containsKey('fileDuration')) {
            durationSeconds = data['fileDuration'] as int;
          }
        }
        
        final durationText = _formatDuration(Duration(seconds: durationSeconds));
        
        // Colores estilo WhatsApp
        final Color cardColor = Theme.of(context).primaryColor;
        final Color textColor = Colors.white;
        
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: cardColor,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de reproducción (ahora primero en la fila)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: cardColor,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      if (messageId != null) {
                        _playPauseAudio(messageId, audioUrl);
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Línea de onda y duración
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Visualización simplificada de la onda
                      Container(
                        height: 20,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Duración
                      Text(
                        durationText,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // Hora de envío con check
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.check,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // Añade esta función para generar un color consistente basado en el ID de usuario
  Color getUserColor(String userId) {
    // Lista de colores distintos y agradables para los usuarios
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber[800]!,
      Colors.deepOrange,
      Colors.cyan[700]!,
      Colors.lime[800]!,
      Colors.deepPurple,
    ];
    
    // Genera un índice basado en la suma de los códigos ASCII de los caracteres
    int hash = 0;
    for (int i = 0; i < userId.length; i++) {
      hash += userId.codeUnitAt(i);
    }
    
    // Usa el hash para seleccionar un color de la lista
    return colors[hash % colors.length];
  }

  // Añade este método para obtener los nombres de los miembros del ministerio
  Future<List<String>> _getMinistryMembersNames() async {
    try {
      // Obtener el documento del ministerio
      final ministryDoc = await FirebaseFirestore.instance
          .collection('ministries')
          .doc(widget.ministry.id)
          .get();
      
      if (!ministryDoc.exists) {
        return [];
      }
      
      final ministryData = ministryDoc.data()!;
      
      // Obtener la lista de miembros (puede ser como array de refs o array de IDs)
      List<dynamic> membersRefs = ministryData['members'] ?? [];
      
      if (membersRefs.isEmpty) {
        return [];
      }
      
      List<String> memberNames = [];
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Procesar cada miembro
      for (var memberRef in membersRefs) {
        String memberId;
        
        // Manejar diferentes formatos (referencia o string)
        if (memberRef is DocumentReference) {
          memberId = memberRef.id;
        } else {
          memberId = memberRef.toString();
        }
        
        // Si es el usuario actual, mostrar "Tú"
        if (memberId == currentUserId) {
          memberNames.add("Você");
          continue;
        }
        
        // Obtener los datos del usuario
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            String userName = userData['name'] ?? 
                             userData['displayName'] ?? 
                             'Usuário';
            memberNames.add(userName);
          }
        } catch (e) {
          // Si hay error al obtener el usuario, omitirlo
          print('Erro ao obter dados do usuário: $e');
        }
      }
      
      return memberNames;
    } catch (e) {
      print('Erro ao obter membros: $e');
      return [];
    }
  }
} 