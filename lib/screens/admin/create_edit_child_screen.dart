import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/child_model.dart';
import '../../services/image_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CreateEditChildScreen extends StatefulWidget {
  final String familyId;
  final String? childId;

  const CreateEditChildScreen({
    super.key, 
    required this.familyId,
    this.childId,
  });

  @override
  State<CreateEditChildScreen> createState() => _CreateEditChildScreenState();
}

class _CreateEditChildScreenState extends State<CreateEditChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isLoadingData = false;
  String? _existingPhotoUrl;

  // Controladores y Estado
  final _fullNameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  XFile? _pickedImage;

  bool _hasDietaryRestrictions = false;
  final _dietaryRestrictionsController = TextEditingController();
  bool _hasAdditionalObservations = false;
  final _additionalObservationsController = TextEditingController();
  bool _hasSpecificNeeds = false;
  final _specificNeedsController = TextEditingController();

  bool get _isEditMode => widget.childId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadChildData();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dietaryRestrictionsController.dispose();
    _additionalObservationsController.dispose();
    _specificNeedsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _loadChildData() async {
    if (widget.childId == null) return;
    setState(() => _isLoadingData = true);
    try {
      DocumentSnapshot childDoc = await FirebaseFirestore.instance.collection('children').doc(widget.childId!).get();
      if (childDoc.exists) {
        final childData = ChildModel.fromFirestore(childDoc);
        _fullNameController.text = '${childData.firstName} ${childData.lastName}'.trim();
        _birthDate = childData.dateOfBirth.toDate();
        _gender = childData.gender;
        _existingPhotoUrl = childData.photoUrl;
        
        if (childData.allergies != null && childData.allergies!.isNotEmpty) {
          _hasDietaryRestrictions = true;
          _dietaryRestrictionsController.text = childData.allergies!;
        }
        if (childData.notes != null && childData.notes!.isNotEmpty) {
          _hasAdditionalObservations = true;
          _additionalObservationsController.text = childData.notes!;
        }
        if (childData.medicalNotes != null && childData.medicalNotes!.isNotEmpty) {
          _hasSpecificNeeds = true;
          _specificNeedsController.text = childData.medicalNotes!;
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Criança não encontrada.'),backgroundColor: Colors.red));
         Navigator.pop(context);
      }
    } catch (e) {
      print("Erro ao carregar dados da criança: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e'),backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // --- GUARDAR CRIANÇA ---
  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione a data de nascimento.'), backgroundColor: Colors.red));
      return;
    }
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione o sexo.'), backgroundColor: Colors.red));
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      String? photoUrl = _existingPhotoUrl;
      String childIdToSave = _isEditMode ? widget.childId! : const Uuid().v4();

      if (_pickedImage != null) {
        photoUrl = await _uploadImage(_pickedImage!, 'child_photos/$childIdToSave.jpg');
        if (photoUrl == null) {
          setState(() => _isSaving = false);
          return;
        }
      }

      String firstName = '';
      String lastName = '';
      final parts = _fullNameController.text.trim().split(' ');
      if(parts.isNotEmpty) firstName = parts.first;
      if(parts.length > 1) lastName = parts.sublist(1).join(' ');

      final childData = ChildModel(
        id: childIdToSave, 
        familyId: widget.familyId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: Timestamp.fromDate(_birthDate!),
        gender: _gender, 
        photoUrl: photoUrl,
        allergies: _hasDietaryRestrictions ? _dietaryRestrictionsController.text.trim() : null,
        medicalNotes: _hasSpecificNeeds ? _specificNeedsController.text.trim() : null, 
        notes: _hasAdditionalObservations ? _additionalObservationsController.text.trim() : null,
        createdAt: _isEditMode 
            ? ((await FirebaseFirestore.instance.collection('children').doc(childIdToSave).get()).data()?['createdAt'] ?? Timestamp.now())
            : Timestamp.now(),
        updatedAt: _isEditMode ? Timestamp.now() : null,
        isActive: true,
      );

      await FirebaseFirestore.instance.collection('children').doc(childIdToSave).set(childData.toMap(), SetOptions(merge: _isEditMode));
      print('Criança ${ _isEditMode ? "atualizada" : "criada"} com ID: $childIdToSave e familyID: ${childData.familyId}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Criança ${_isEditMode ? "atualizada" : "adicionada"} com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, childData);
      }
    } catch (e) {
       print("Erro ao salvar criança: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar criança: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
   // Helper para subir imagen (copiado/adaptado)
   Future<String?> _uploadImage(XFile imageFile, String path) async {
     File? compressedFile;
      try {
        final File originalFile = File(imageFile.path);
        compressedFile = await _imageService.compressImage(originalFile);
        if (compressedFile == null) {
           print('La compresión de imagen falló para $path');
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao processar a imagem.'), backgroundColor: Colors.orange));
           return null; 
        }
        final ref = FirebaseStorage.instance.ref().child(path);
        final uploadTask = ref.putFile(compressedFile);
        final snapshot = await uploadTask.whenComplete(() => {});
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        print('Error al subir imagen a $path: $e');
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar imagem: $e'), backgroundColor: Colors.red));
        }
        return null;
      }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Criança' : 'Adicionar Criança'), 
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Selector de Foto
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.secondary.withOpacity(0.1),
                      backgroundImage: _pickedImage != null 
                          ? FileImage(File(_pickedImage!.path)) 
                          : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty 
                              ? NetworkImage(_existingPhotoUrl!) 
                              : null as ImageProvider<Object>?),
                      child: (_pickedImage == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty)) 
                          ? Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.secondary.withOpacity(0.7)) 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                     icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                     label: Text('Editar foto', style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary)),
                     onPressed: _pickImage,
                   ),
                   const SizedBox(height: 24),

                  // Campos Principales
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Nome completo *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Nome completo é obrigatório.' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Expanded(
                        child: InkWell(
                          onTap: () async {
                             final DateTime? picked = await showDatePicker(
                              context: context, initialDate: _birthDate ?? DateTime.now(),
                              firstDate: DateTime(1950), // Rango de fechas apropiado para niños
                              lastDate: DateTime.now(), locale: const Locale('pt', 'BR'),
                            );
                            if (picked != null && picked != _birthDate) setState(() => _birthDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Nascimento *', suffixIcon: Icon(Icons.calendar_today_outlined)),
                             child: Text(_birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Selecionar data'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Sexo *'),
                          value: _gender,
                          isExpanded: true,
                          items: ['Masculino', 'Feminino'] // Opciones para niños
                              .map((label) => DropdownMenuItem(child: Text(label, overflow: TextOverflow.ellipsis), value: label))
                              .toList(),
                          onChanged: (value) => setState(() => _gender = value),
                          validator: (value) => (value == null) ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Campos Adicionales con Checkbox
                  _buildCheckboxWithField(
                    title: 'Possui alguma restrição dietética?', 
                    value: _hasDietaryRestrictions,
                    controller: _dietaryRestrictionsController,
                    onChanged: (val) => setState(() => _hasDietaryRestrictions = val ?? false)
                  ),
                  const SizedBox(height: 16),
                  _buildCheckboxWithField(
                    title: 'Observações adicionais', 
                    value: _hasAdditionalObservations,
                    controller: _additionalObservationsController,
                    onChanged: (val) => setState(() => _hasAdditionalObservations = val ?? false)
                  ),
                   const SizedBox(height: 16),
                  _buildCheckboxWithField(
                    title: 'Necessidades específicas', 
                    value: _hasSpecificNeeds,
                    controller: _specificNeedsController,
                    onChanged: (val) => setState(() => _hasSpecificNeeds = val ?? false)
                  ),
                ],
              ),
            ),
          ),
          // Indicador de Carga
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSaving ? Colors.grey.shade400 : AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : _saveChild,
          child: Text(_isEditMode ? 'SALVAR ALTERAÇÕES' : 'SALVAR CRIANÇA', style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
  
  // Widget helper para Checkbox + TextField condicional
  Widget _buildCheckboxWithField({
    required String title,
    required bool value,
    required TextEditingController controller,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text(title, style: AppTextStyles.bodyText1),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        ),
        if (value) 
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Detalhes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
      ],
    );
  }
} 