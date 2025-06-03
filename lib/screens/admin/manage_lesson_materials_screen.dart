import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:igreja_amor_em_movimento/models/course_lesson.dart';
import 'package:igreja_amor_em_movimento/services/course_service.dart';
import 'package:igreja_amor_em_movimento/theme/app_colors.dart';
import 'package:igreja_amor_em_movimento/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageLessonMaterialsScreen extends StatefulWidget {
  final CourseLesson lesson;

  const ManageLessonMaterialsScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<ManageLessonMaterialsScreen> createState() => _ManageLessonMaterialsScreenState();
}

class _ManageLessonMaterialsScreenState extends State<ManageLessonMaterialsScreen> {
  final CourseService _courseService = CourseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<String> _materialUrls = [];
  List<String> _materialNames = [];

  @override
  void initState() {
    super.initState();
    _materialUrls = List.from(widget.lesson.complementaryMaterialUrls);
    _materialNames = List.from(widget.lesson.complementaryMaterialNames);
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // Excluir tipos de video comunes (puedes añadir más)
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 
          'txt', 'rtf', 'jpg', 'jpeg', 'png', 'gif', 'zip', 'rar', '7z'
        ],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        // Validar tamaño del archivo (25 MB)
        int fileSize = await file.length();
        if (fileSize > 25 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: O arquivo excede o limite de 25MB.'), backgroundColor: Colors.red),
          );
          return;
        }

        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        // Subir archivo a Firebase Storage
        final path = 'courses/${widget.lesson.courseId}/lessons/${widget.lesson.id}/materials/$fileName';
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(file);

        // Escuchar progreso de subida
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        // Esperar a que la subida termine
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Actualizar lista de materiales en Firestore
        _materialUrls.add(downloadUrl);
        _materialNames.add(fileName);
        
        await _courseService.updateLesson(
          widget.lesson.copyWith(
            complementaryMaterialUrls: _materialUrls,
            complementaryMaterialNames: _materialNames,
          )
        );

        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material adicionado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        // Usuario canceló la selección
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar material: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _deleteMaterial(int index) async {
    // Mostrar diálogo de confirmación
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Material'),
        content: Text('Tem certeza que deseja excluir o material "${_materialNames[index]}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    
    try {
      String urlToDelete = _materialUrls[index];
      String nameToDelete = _materialNames[index];
      
      // Eliminar de Firebase Storage
      try {
         await _storage.refFromURL(urlToDelete).delete();
      } catch (e) {
        // Si falla al borrar de Storage (p.ej. archivo no existe), continuar para borrar de Firestore
        print("Erro ao excluir arquivo do Storage (pode já ter sido excluído): $e");
      }

      // Actualizar listas locales
      setState(() {
        _materialUrls.removeAt(index);
        _materialNames.removeAt(index);
      });

      // Actualizar Firestore
      await _courseService.updateLesson(
        widget.lesson.copyWith(
          complementaryMaterialUrls: _materialUrls,
          complementaryMaterialNames: _materialNames,
        )
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material excluído com sucesso.'), backgroundColor: Colors.green),
      );

    } catch (e) {
      // Revertir si falla la actualización de Firestore?
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir material: $e'), backgroundColor: Colors.red),
      );
      // Añadir de nuevo a las listas locales si falló la actualización
      // setState(() { ... }); 
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir a URL: $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materiais - ${widget.lesson.title}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicador de progreso de subida
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            
          // Lista de materiales
          Expanded(
            child: _materialUrls.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Nenhum material adicionado ainda.', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Use o botão abaixo para adicionar.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _materialUrls.length,
                    itemBuilder: (context, index) {
                      final url = _materialUrls[index];
                      final name = index < _materialNames.length 
                          ? _materialNames[index] 
                          : 'Material ${index + 1}';
                          
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.attach_file, color: Colors.grey),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                                onPressed: () => _openUrl(url),
                                tooltip: 'Abrir/Baixar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteMaterial(index),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Material'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
} 