import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/permission_service.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorVerifyingPermissionAnnouncement(e.toString());
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
        _errorMessage = AppLocalizations.of(context)!.errorSelectingImage(e.toString());
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _createAnnouncement() async {
    if (!_hasPermission) return;
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.pleaseSelectAnnouncementImage);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception(AppLocalizations.of(context)!.userNotAuthenticated);
      
      // 1. Subir imagen
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('announcement_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      
      // 2. Crear anuncio
      final docRef = await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'isActive': true,
        'type': 'regular',
        'startDate': Timestamp.fromDate(DateTime.now()),
      });

      // 3. Notificación
      if (mounted) {
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        notificationService.sendNewAnnouncementNotification(
          announcementId: docRef.id,
          title: AppLocalizations.of(context)!.newAnnouncement,
          announcementTitle: _titleController.text.trim(),
        ).catchError((e) => print('Error notificaciones: $e'));
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.announcementCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.errorCreatingAnnouncement(e.toString());
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.campaign_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.createAnnouncement,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                  child: Icon(Icons.close, color: Colors.grey[700], size: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Contenido
          _isCheckingPermission
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : !_hasPermission
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(_errorMessage ?? AppLocalizations.of(context)!.noPermissionCreateAnnouncements, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : Flexible(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagen
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
                                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                                            const SizedBox(height: 12),
                                            Text(AppLocalizations.of(context)!.addImage, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                            Text(AppLocalizations.of(context)!.recommended16x9, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              TextFormField(
                                controller: _titleController,
                                decoration: _inputDecoration(
                                  label: AppLocalizations.of(context)!.announcementTitle,
                                  hint: AppLocalizations.of(context)!.enterClearConciseTitle,
                                  icon: Icons.title_rounded,
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? AppLocalizations.of(context)!.pleasEnterTitle : null,
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: _inputDecoration(
                                  label: AppLocalizations.of(context)!.description,
                                  hint: AppLocalizations.of(context)!.provideAnnouncementDetails,
                                  icon: Icons.description_outlined,
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? AppLocalizations.of(context)!.pleaseEnterDescription : null,
                              ),
                              const SizedBox(height: 16),
                              
                              InkWell(
                                onTap: () => _selectDate(context),
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: _inputDecoration(
                                    label: AppLocalizations.of(context)!.announcementExpirationDate,
                                    icon: Icons.calendar_today_outlined,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedDate != null 
                                            ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate!)
                                            : AppLocalizations.of(context)!.optionalSelectDate,
                                        style: TextStyle(color: _selectedDate != null ? Colors.black87 : Colors.grey[600]),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                              
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
                                        Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700]))),
                                      ],
                                    ),
                                  ),
                                ),
                                
                              const SizedBox(height: 32),
                              
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _createAnnouncement,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(
                                          AppLocalizations.of(context)!.publishAnnouncement,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
  
  InputDecoration _inputDecoration({required String label, String? hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 8), child: Icon(icon, color: Colors.grey[600])),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      alignLabelWithHint: true,
    );
  }
}
