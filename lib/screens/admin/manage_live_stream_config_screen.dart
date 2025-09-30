import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ManageLiveStreamConfigScreen extends StatefulWidget {
  const ManageLiveStreamConfigScreen({super.key});

  @override
  State<ManageLiveStreamConfigScreen> createState() => _ManageLiveStreamConfigScreenState();
}

class _ManageLiveStreamConfigScreenState extends State<ManageLiveStreamConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  bool _isLoadingData = true; // Para la carga inicial

  // Controladores
  final _sectionTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageTitleController = TextEditingController();
  final _urlController = TextEditingController();

  // Variables de estado
  String? _imageUrl;
  File? _imageFile; // Para la imagen seleccionada localmente
  bool _isActive = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Referencia al documento de configuración
  DocumentReference get _liveStreamConfigDocRef =>
      _firestore.collection('app_config').doc('live_stream');

  Future<void>? _loadConfigFuture;

  @override
  void initState() {
    super.initState();
    _loadConfigFuture = _loadConfigData();
  }

  @override
  void dispose() {
    _sectionTitleController.dispose();
    _descriptionController.dispose();
    _imageTitleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigData() async {
    setState(() => _isLoadingData = true);
    try {
      final snapshot = await _liveStreamConfigDocRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _sectionTitleController.text = data['sectionTitle'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _imageTitleController.text = data['imageTitle'] ?? '';
        _urlController.text = data['url'] ?? '';
        _imageUrl = data['imageUrl'];
        _isActive = data['isActive'] ?? false;
        print('📊 Datos de configuración de directo cargados:');
        print('- Título Sección: ${_sectionTitleController.text}');
        print('- Activo: $_isActive');
        print('- URL Imagen: $_imageUrl');
      } else {
        print('⚠️ No existe configuración previa para directos.');
        // Puedes establecer valores por defecto si lo deseas
        _isActive = false;
      }
    } catch (e) {
      print('❌ Error al cargar configuración de directo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // Borrar URL anterior si se elige nueva imagen
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final String fileName = 'live_stream_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _saveConfig() async {
    final bool hasPermission = await _permissionService.hasPermission('manage_livestream_config');
    if (!hasPermission) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionToSaveSettings), backgroundColor: Colors.red),
         );
      }
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    String? finalImageUrl = _imageUrl; // Mantener URL si no se cambió la imagen

    // Subir nueva imagen si existe
    if (_imageFile != null) {
      finalImageUrl = await _uploadImage(_imageFile!);
      if (finalImageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUploadingImageStream), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // Preparar datos para Firestore
    final Map<String, dynamic> configData = {
      'sectionTitle': _sectionTitleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageTitle': _imageTitleController.text.trim(),
      'url': _urlController.text.trim(),
      'imageUrl': finalImageUrl, // Usar la URL final (nueva o existente)
      'isActive': _isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _liveStreamConfigDocRef.set(configData, SetOptions(merge: true));
      print('✅ Configuración de directo guardada.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.configurationSaved), backgroundColor: Colors.green),
        );
        // Opcional: Navegar hacia atrás
        // Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error al guardar configuración de directo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSaving(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageLiveStreamTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_livestream_config'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (permissionSnapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorCheckingPermission(permissionSnapshot.error.toString())));
          }
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.accessDenied, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text(AppLocalizations.of(context)!.noPermissionManageLiveStream, textAlign: TextAlign.center),
                   ],
                 ),
              ),
            );
          }

          return FutureBuilder<void>(
            future: _loadConfigFuture,
            builder: (context, dataSnapshot) {
              if (_isLoadingData) {
                 return const Center(child: CircularProgressIndicator());
              }
              
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                  children: [
                    // Título de la Sección
                    TextFormField(
                      controller: _sectionTitleController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.sectionTitleHome,
                        hintText: AppLocalizations.of(context)!.sectionTitleHint,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterSectionTitle;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción -> Texto Adicional
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.additionalTextOptional,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),


                    // Imagen y Título sobre Imagen
                    Text(AppLocalizations.of(context)!.transmissionImage, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // --- Selector de Imagen Mejorado ---
                    _imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty)
                        ? GestureDetector(
                            onTap: _pickImage,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade600, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(context)!.tapToAddImage,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _pickImage,
                            child: AspectRatio(
                               aspectRatio: 16 / 9,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageFile != null
                                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                                        : Image.network(_imageUrl!, fit: BoxFit.cover,
                                            loadingBuilder: (context, child, progress) =>
                                                progress == null ? child : const Center(child: CircularProgressIndicator()),
                                            errorBuilder: (context, error, stackTrace) =>
                                               const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40))),
                                  ),
                                ),
                              ),
                          ),
                    // -------------------------------------
                    const SizedBox(height: 16),

                    // Título sobre Imagen
                    TextFormField(
                      controller: _imageTitleController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.titleOverImage,
                        hintText: AppLocalizations.of(context)!.titleOverImageHint,
                        border: OutlineInputBorder(),
                      ),
                      // Podría ser opcional, ajustar validator si es necesario
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // URL del Directo
                    Text(AppLocalizations.of(context)!.transmissionLink, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                     TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.urlYouTubeVimeo,
                        hintText: AppLocalizations.of(context)!.pasteFullLinkHere,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.link),
                      ),
                       keyboardType: TextInputType.url,
                      validator: (value) {
                        // Es opcional tener URL, pero si se pone, validar formato básico
                        if (value != null && value.isNotEmpty && !value.startsWith('http')) {
                          return AppLocalizations.of(context)!.pleaseEnterValidUrl;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    const SizedBox(height: 16),
                    // Interruptor Activo/Inactivo
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.activateTransmissionHome),
                      subtitle: Text(
                          _isActive
                           ? AppLocalizations.of(context)!.visibleInHome
                           : AppLocalizations.of(context)!.hiddenInHome,
                           style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _isActive ? AppColors.secondary : Colors.grey
                           )
                      ),
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      secondary: Icon(_isActive ? Icons.visibility : Icons.visibility_off, color: _isActive ? AppColors.secondary : Colors.grey),
                    ),

                    const SizedBox(height: 32),

                    // Botón de Guardar
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: Text(AppLocalizations.of(context)!.saveConfiguration, style: TextStyle(color: Colors.white, fontSize: 16)),
                            onPressed: _saveConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// NOTA: Asegúrate de tener el widget CustomLoadingIndicator definido o reemplázalo
// por un CircularProgressIndicator estándar.
// También, asegúrate que AppColors.secondary y AppColors.accent están definidos.
// Considera añadir validaciones más robustas si es necesario. 