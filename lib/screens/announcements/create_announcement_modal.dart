import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../services/permission_service.dart';

class CreateAnnouncementModal extends StatefulWidget {
  const CreateAnnouncementModal({Key? key}) : super(key: key);

  @override
  State<CreateAnnouncementModal> createState() => _CreateAnnouncementModalState();
}

class _CreateAnnouncementModalState extends State<CreateAnnouncementModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PermissionService _permissionService = PermissionService();
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isCheckingPermission = true;
  bool _hasPermission = false;
  String? _errorMessage;
  DateTime? _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermission() async {
    try {
      final hasPerm = await _permissionService.hasPermission('manage_announcements');
      if (mounted) {
        setState(() {
          _hasPermission = hasPerm;
          _isCheckingPermission = false;
        });
        if (!hasPerm) {
          // Opcional: cerrar modal si no tiene permiso tras un delay
          // Future.delayed(Duration(seconds: 2), () => Navigator.pop(context));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erro ao verificar permissão: $e";
          _isCheckingPermission = false;
          _hasPermission = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar imagem: $e';
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Selecione uma data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _createAnnouncement() async {
    if (!_hasPermission) {
      setState(() { 
         _errorMessage = 'Você não tem permissão para criar anúncios.'; 
         _isLoading = false;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Por favor, selecione uma imagem para o anúncio';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // 1. Subir la imagen a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('announcement_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      
      // 2. Crear el anuncio en Firestore
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : Timestamp.fromDate(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'isActive': true,
        'type': 'regular',
      });
      
      if (mounted) {
        Navigator.pop(context, true); // Cerrar el modal con resultado exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anúncio criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao criar anúncio: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header inspirado en create_ministry_modal
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Criar Anúncio',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.grey[700], size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // --- Mostrar contenido basado en permiso y carga ---
          _isCheckingPermission
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : !_hasPermission 
              ? Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Acesso Negado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text(
                              _errorMessage ?? 'Você não tem permissão para criar anúncios.',
                              textAlign: TextAlign.center,
                            ),
                         ],
                       ),
                    ),
                  ),
                )
              : Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selección de imagen
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined, size: 56, color: Colors.grey[400]),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Adicionar imagem',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Recomendado: 16:9 (1920x1080)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Campos de formulario
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Título do Anúncio',
                              hintText: 'Digite um título claro e conciso',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.title_rounded, color: Theme.of(context).primaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, digite um título';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Descrição',
                              hintText: 'Forneça detalhes sobre o anúncio',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(Icons.description_outlined, color: Theme.of(context).primaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, digite uma descrição';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Selector de fecha
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Data do anúncio/expiração',
                                hintText: 'Selecione uma data',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.calendar_today_outlined, color: Theme.of(context).primaryColor),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate != null 
                                        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!)
                                        : 'Opcional: Selecione uma data',
                                    style: TextStyle(
                                      color: _selectedDate != null 
                                          ? Colors.black87
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Mensaje de error estilizado
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
          // --- Fin del contenido condicional ---
          
          // --- Botón de acción (deshabilitado si no tiene permiso) ---
          if (!_isCheckingPermission)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_isLoading || !_hasPermission) ? null : _createAnnouncement,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.publish_rounded),
                          SizedBox(width: 8),
                          Text(
                            'Publicar Anúncio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
} 