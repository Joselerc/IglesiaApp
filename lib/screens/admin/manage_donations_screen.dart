import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
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
  final TextEditingController keyController;
  final String id;

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
      entry.keyController.dispose();
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
        _bankAccountsController.text = (data['bankAccounts'] as List<dynamic>? ?? []).join('\n\n');

        final List<dynamic> pixData = data['pixKeys'] ?? [];
        _pixKeyEntries = pixData.map<PixKeyEntry>((pixMap) {
            final String type = pixMap['type'] ?? 'CNPJ';
            final String key = pixMap['key'] ?? '';
            return PixKeyEntry(
              id: UniqueKey().toString(),
              type: _pixKeyTypes.contains(type) ? type : 'CNPJ',
              key: key,
              keyController: TextEditingController(text: key),
            );
          }).toList();
      }
    } catch (e) {
      debugPrint('❌ Error al cargar configuración de donaciones: $e');
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
        type: 'CNPJ',
        key: '',
        keyController: TextEditingController(),
      ));
    });
  }

  void _removePixKeyEntry(int index) {
    setState(() {
      _pixKeyEntries[index].keyController.dispose();
      _pixKeyEntries.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
     if (pickedFile != null) {
       setState(() {
         _imageFile = File(pickedFile.path);
         _imageUrl = null;
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
       debugPrint('❌ Error al subir imagen de donación: $e');
       return null;
     }
   }

  Future<void> _saveConfig() async {
    final bool hasPermission = await _permissionService.hasPermission('manage_donations_config');
    if (!hasPermission) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionToSaveSettings), backgroundColor: Colors.red),
         );
      }
      return;
    }
    
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

    for (var entry in _pixKeyEntries) {
        entry.key = entry.keyController.text.trim();
    }

    final List<Map<String, String>> pixKeysToSave = _pixKeyEntries
        .where((entry) => entry.key.isNotEmpty)
        .map((entry) => {'type': entry.type, 'key': entry.key})
        .toList();

    final List<String> bankAccountsToSave = _bankAccountsController.text
        .split(RegExp(r'\n\s*\n'))
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: FittedBox( // Ajusta el texto para que quepa sin elipsis
          fit: BoxFit.scaleDown,
          child: Text(
            AppLocalizations.of(context)!.manageDonationsTitle,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_donations_config'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (permissionSnapshot.hasError || permissionSnapshot.data == false) {
            return _buildAccessDenied();
          }

          return FutureBuilder<void>(
            future: _loadConfigFuture,
            builder: (context, dataSnapshot) {
              if (_isLoadingData) {
                 return const Center(child: CircularProgressIndicator());
              }
              
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sección 1: Información General
                      _buildSectionCard(
                        title: AppLocalizations.of(context)!.configureDonationsSection,
                        icon: Icons.info_outline_rounded,
                        children: [
                          _buildTextField(
                            controller: _sectionTitleController,
                            label: AppLocalizations.of(context)!.sectionTitleOptional,
                            icon: Icons.title,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: AppLocalizations.of(context)!.descriptionOptional,
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Sección 2: Imagen de Fondo
                      _buildSectionCard(
                        title: AppLocalizations.of(context)!.backgroundImageOptional,
                        icon: Icons.image_outlined,
                        children: [
                          _buildImagePicker(),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Sección 3: Cuentas Bancarias
                      _buildSectionCard(
                        title: AppLocalizations.of(context)!.bankAccountsOptional,
                        icon: Icons.account_balance_outlined,
                        children: [
                          _buildTextField(
                            controller: _bankAccountsController,
                            label: AppLocalizations.of(context)!.bankingInformation,
                            hint: AppLocalizations.of(context)!.bankAccountsHint,
                            icon: Icons.format_list_bulleted,
                            maxLines: 5,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Sección 4: Claves Pix
                      _buildSectionCard(
                        title: AppLocalizations.of(context)!.pixKeysOptional,
                        icon: Icons.pix_outlined,
                        children: [
                          if (_pixKeyEntries.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(Icons.pix, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context)!.noPixKeysAdded,
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ..._pixKeyEntries.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildPixEntry(entry.value, entry.key),
                            );
                          }),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: _addPixKeyEntry,
                              icon: const Icon(Icons.add_circle_outline),
                              label: Text(AppLocalizations.of(context)!.addPixKey),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 80), // Espacio para el FAB
                    ],
                  ),
                ),
              );
            }
          );
        },
      ),
      floatingActionButton: _isLoading
          ? const CircularProgressIndicator()
          : FloatingActionButton.extended(
              onPressed: _saveConfig,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: Colors.white)), // Usando 'save' para texto corto
              elevation: 4,
            ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.accessDenied,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noPermissionManageDonations,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded( // Expanded para asegurar que el título ocupe el espacio disponible
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    // Eliminados maxLines y overflow para permitir que el texto fluya
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey[500], size: 20) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: _imageFile == null && _imageUrl == null ? BorderStyle.none : BorderStyle.solid,
            width: 1,
          ),
          image: _imageFile != null
              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
              : (_imageUrl != null && _imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                  : null),
        ),
        child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
            ? DottedBorderPlaceholder()
            : Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                        onPressed: () => setState(() { _imageFile = null; _imageUrl = null; }),
                        tooltip: AppLocalizations.of(context)!.removeImage,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPixEntry(PixKeyEntry entry, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: entry.type,
                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                items: _pixKeyTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => entry.type = value);
                },
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Input Key
          Expanded(
            child: TextFormField(
              controller: entry.keyController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.pixKey,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.keyRequired;
                }
                return null;
              },
            ),
          ),
          // Delete
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
            onPressed: () => _removePixKeyEntry(index),
            tooltip: AppLocalizations.of(context)!.removeKey,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para el borde punteado
class DottedBorderPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, width: 1.5), 
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.tapToAddImage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
