import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:qr_flutter/qr_flutter.dart'; // Para QR Code (aunque no se usa aquí, el import general)
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';

class ManageDonationsScreen extends StatefulWidget {
  const ManageDonationsScreen({super.key});

  @override
  State<ManageDonationsScreen> createState() => _ManageDonationsScreenState();
}

class PixKeyEntry {
  String type;
  String key;
  final TextEditingController keyController; // Controlador para este campo
  final String id; // ID único para el widget (opcional, para keys)

  PixKeyEntry({required this.type, required this.key, required this.keyController, required this.id});
}

class _ManageDonationsScreenState extends State<ManageDonationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Controladores
  final _sectionTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bankAccountsController = TextEditingController();

  // Estado de la Imagen
  String? _imageUrl;
  File? _imageFile;

  // Estado de las Claves Pix
  List<PixKeyEntry> _pixKeyEntries = [];
  final List<String> _pixKeyTypes = ['CNPJ', 'CPF', 'Teléfono', 'Email', 'Aleatória'];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Referencia al documento (Nueva Colección)
  DocumentReference get _donationConfigDocRef =>
      _firestore.collection('donationsPage').doc('settings');

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
    _bankAccountsController.dispose();
    for (var entry in _pixKeyEntries) {
      entry.keyController.dispose(); // Limpiar controladores de Pix
    }
    super.dispose();
  }

  Future<void> _loadConfigData() async {
    setState(() => _isLoadingData = true);
    try {
      final snapshot = await _donationConfigDocRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _sectionTitleController.text = data['sectionTitle'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _imageUrl = data['imageUrl'];
        // Cargar cuentas bancarias (asumiendo lista de strings, tomamos el primero si existe)
        _bankAccountsController.text = (data['bankAccounts'] as List<dynamic>? ?? []).join('\n\n'); // Unir con saltos de línea

        // Cargar claves Pix
        final List<dynamic> pixData = data['pixKeys'] ?? [];
        _pixKeyEntries = pixData.map<PixKeyEntry>((pixMap) {
            final String type = pixMap['type'] ?? 'CNPJ';
            final String key = pixMap['key'] ?? '';
            return PixKeyEntry(
              id: UniqueKey().toString(), // Generar ID único para el widget
              type: _pixKeyTypes.contains(type) ? type : 'CNPJ', // Validar tipo
              key: key,
              keyController: TextEditingController(text: key),
            );
          }).toList();
      }
    } catch (e) {
      print('❌ Error al cargar configuración de donaciones: $e');
      // Manejar error
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _addPixKeyEntry() {
    setState(() {
      _pixKeyEntries.add(PixKeyEntry(
        id: UniqueKey().toString(),
        type: 'CNPJ', // Tipo por defecto
        key: '',
        keyController: TextEditingController(),
      ));
    });
  }

  void _removePixKeyEntry(int index) {
    setState(() {
      _pixKeyEntries[index].keyController.dispose(); // Liberar controlador
      _pixKeyEntries.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
     if (pickedFile != null) {
       setState(() {
         _imageFile = File(pickedFile.path);
         _imageUrl = null; // Indicar que hay una nueva imagen local
       });
     }
  }

  Future<String?> _uploadImage(File image) async {
     try {
       final String fileName = 'donation_section_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
       final ref = _storage.ref().child(fileName);
       final uploadTask = ref.putFile(image);
       final snapshot = await uploadTask.whenComplete(() => {});
       return await snapshot.ref.getDownloadURL();
     } catch (e) {
       print('❌ Error al subir imagen de donación: $e');
       return null;
     }
   }

  Future<void> _saveConfig() async {
    // --- Doble verificación de permiso --- 
    final bool hasPermission = await _permissionService.hasPermission('manage_donations_config');
    if (!hasPermission) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionToSaveSettings), backgroundColor: Colors.red),
         );
      }
      return; // No continuar si no tiene permiso
    }
    // -------------------------------------
    
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? finalImageUrl = _imageUrl;
    if (_imageFile != null) {
      finalImageUrl = await _uploadImage(_imageFile!);
      if (finalImageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUploadingImage('Error desconocido')), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // Guardar valores de los controladores en los entries
    for (var entry in _pixKeyEntries) {
        entry.key = entry.keyController.text.trim();
    }

    final List<Map<String, String>> pixKeysToSave = _pixKeyEntries
        .where((entry) => entry.key.isNotEmpty) // Solo guardar claves no vacías
        .map((entry) => {'type': entry.type, 'key': entry.key})
        .toList();

    final List<String> bankAccountsToSave = _bankAccountsController.text
        .split(RegExp(r'\n\s*\n')) // Dividir por líneas en blanco
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();

    final Map<String, dynamic> configData = {
      'sectionTitle': _sectionTitleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'imageUrl': finalImageUrl,
      'bankAccounts': bankAccountsToSave,
      'pixKeys': pixKeysToSave,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _donationConfigDocRef.set(configData, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.donationConfigSaved), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('❌ Error al guardar configuración de donaciones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSaving(e.toString())), backgroundColor: Colors.red),
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageDonationsTitle)),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_donations_config'),
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
                      Text(AppLocalizations.of(context)!.noPermissionManageDonations, textAlign: TextAlign.center),
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
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(AppLocalizations.of(context)!.configureDonationsSection, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Campos Gerais ---
                    TextFormField(
                       controller: _sectionTitleController,
                       decoration: InputDecoration(labelText: AppLocalizations.of(context)!.sectionTitleOptional, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                       controller: _descriptionController,
                       decoration: InputDecoration(labelText: AppLocalizations.of(context)!.descriptionOptional, border: OutlineInputBorder()),
                       maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Imagem ---
                    Text(AppLocalizations.of(context)!.backgroundImageOptional, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                     GestureDetector(
                       onTap: _pickImage,
                       child: AspectRatio(
                         aspectRatio: 16 / 9,
                         child: Container(
                           decoration: BoxDecoration(
                             color: Colors.grey.shade200,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.grey.shade300),
                             image: _imageFile != null
                                 ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                 : (_imageUrl != null && _imageUrl!.isNotEmpty
                                     ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                                     : null),
                           ),
                           child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                             ? Center(
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
                               )
                             : Align(
                               alignment: Alignment.topRight,
                               child: IconButton(
                                 icon: const Icon(Icons.delete_outline, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]), 
                                 onPressed: () => setState(() { _imageFile = null; _imageUrl = null; }),
                                 tooltip: AppLocalizations.of(context)!.removeImage,
                               ),
                             ),
                         ),
                       ),
                     ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Contas Bancárias ---
                     Text(AppLocalizations.of(context)!.bankAccountsOptional, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     const SizedBox(height: AppSpacing.sm),
                     TextFormField(
                       controller: _bankAccountsController,
                       decoration: InputDecoration(
                         labelText: AppLocalizations.of(context)!.bankingInformation,
                         hintText: AppLocalizations.of(context)!.bankAccountsHint,
                         border: OutlineInputBorder(),
                       ),
                       maxLines: 5,
                     ),
                     const SizedBox(height: AppSpacing.lg),
                     const Divider(),
                     const SizedBox(height: AppSpacing.lg),

                     // --- Chaves Pix ---
                      Text(AppLocalizations.of(context)!.pixKeysOptional, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),
                      if (_pixKeyEntries.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(AppLocalizations.of(context)!.noPixKeysAdded, style: TextStyle(color: Colors.grey)),
                        ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pixKeyEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _pixKeyEntries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dropdown Tipo (Ahora Flexible)
                                Flexible(
                                  flex: 2, // Darle una proporción (ajustable)
                                  child: DropdownButtonFormField<String>(
                                    value: entry.type,
                                    items: _pixKeyTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => entry.type = value);
                                      }
                                    },
                                    // Quitar el SizedBox fijo y usar Flexible
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(), 
                                      // Ajustar padding si es necesario para la apariencia
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                // Input Chave (Mantiene Expanded)
                                Expanded(
                                  flex: 3, // Darle una proporción mayor (ajustable)
                                  child: TextFormField(
                                    controller: entry.keyController,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(context)!.pixKey,
                                      border: const OutlineInputBorder(),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => _removePixKeyEntry(index),
                                        tooltip: AppLocalizations.of(context)!.removeKey,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return AppLocalizations.of(context)!.keyRequired;
                                      }
                                      // TODO: Añadir validaciones específicas por tipo?
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.addPixKey),
                        onPressed: _addPixKeyEntry,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),

                     // Botón Guardar
                     _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(AppLocalizations.of(context)!.saveSettings, style: TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: _saveConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg), // Espacio extra al final
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }
} 