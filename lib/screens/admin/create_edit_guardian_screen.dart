import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/image_service.dart'; // Reutilizar servicio de imagen
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CreateEditGuardianScreen extends StatefulWidget {
  final String familyId; // ID de la familia a la que se añade el responsable
  final String? guardianUserId; // <-- DESCOMENTAR Y HACER OPCIONAL

  const CreateEditGuardianScreen({
    super.key, 
    required this.familyId,
    this.guardianUserId, // <-- AÑADIR AL CONSTRUCTOR
  });

  @override
  State<CreateEditGuardianScreen> createState() => _CreateEditGuardianScreenState();
}

class _CreateEditGuardianScreenState extends State<CreateEditGuardianScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isLoadingData = false; // Para el modo edición

  // Controladores (similares al Paso 2 de CreateEditFamily)
  final _fullNameController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  final _phoneController = TextEditingController();
  String _phoneCountryCode = '+55';
  String _phoneCompleteNumber = '';
  String _isoCountryCode = 'BR'; 
  String? _phoneType;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  XFile? _pickedImage;
  String? _existingPhotoUrl; // Para la foto actual en modo edición

  bool get _isEditMode => widget.guardianUserId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadGuardianData();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _loadGuardianData() async {
    if (widget.guardianUserId == null) return;
    setState(() => _isLoadingData = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.guardianUserId!).get();
      if (userDoc.exists) {
        final userData = UserModel.fromMap(userDoc.data() as Map<String, dynamic>); // Asumiendo que fromMap toma id del doc o es null
        _fullNameController.text = userData.displayName ?? '${userData.name ?? ''} ${userData.surname ?? ''}'.trim();
        _emailController.text = userData.email;
        _phoneController.text = userData.phone ?? '';
        _isoCountryCode = userData.isoCountryCode ?? 'BR';
        _phoneCountryCode = userData.phoneCountryCode ?? '+55';
        _phoneCompleteNumber = userData.phoneComplete ?? '';
        _birthDate = userData.birthDate?.toDate(); 
        _gender = userData.gender;
        _existingPhotoUrl = userData.photoUrl;
        // No cargamos la contraseña
        // PhoneType no está en UserModel, así que no se puede cargar
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responsável não encontrado.'),backgroundColor: Colors.red));
        Navigator.pop(context); // Volver si no se encuentra
      }
    } catch (e) {
      print("Erro ao carregar dados do responsável: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e'),backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // --- GUARDAR RESPONSÁVEL ---
  Future<void> _saveGuardian() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione a data de nascimento.'), backgroundColor: Colors.red));
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      String? photoUrl = _existingPhotoUrl; // Mantener foto existente si no se elige nueva
      String userIdToAssign;

      if (_isEditMode) {
        userIdToAssign = widget.guardianUserId!;
        print('Actualizando responsable existente ID: $userIdToAssign');
        // Subir nueva foto solo si se seleccionó una
        if (_pickedImage != null) {
          photoUrl = await _uploadImage(_pickedImage!, 'user_photos/$userIdToAssign.jpg');
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

        // Actualizar documento del usuario
        // NOTA: La contraseña solo se actualiza si se introduce algo en el campo.
        Map<String, dynamic> userDataToUpdate = {
          'name': firstName,
          'surname': lastName,
          'displayName': _fullNameController.text.trim(),
          'photoUrl': photoUrl,
          'phone': _phoneController.text.trim(),
          'phoneCountryCode': _phoneCountryCode,
          'phoneComplete': _phoneCompleteNumber,
          'isoCountryCode': _isoCountryCode,
          'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
          'gender': _gender,
          // Email no se actualiza aquí generalmente, es un identificador.
          // PhoneType no está en UserModel.
        };
        if(_passwordController.text.isNotEmpty){
            // Aquí iría la lógica para actualizar la contraseña en Firebase Auth si la usamos.
            // Por ahora, no hacemos nada con la contraseña para el update en Firestore.
            print("Contraseña cambiada, pero la lógica de Auth no está implementada aquí.");
        }

        await FirebaseFirestore.instance.collection('users').doc(userIdToAssign).update(userDataToUpdate);
        print('Usuario actualizado en Firestore con ID: $userIdToAssign');

      } else {
        // Lógica de creación de nuevo usuario (como estaba antes)
        final email = _emailController.text.trim();
        final existingUserQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();

        if (existingUserQuery.docs.isNotEmpty) {
          userIdToAssign = existingUserQuery.docs.first.id;
          print('Usuario existente encontrado con email $email, ID: $userIdToAssign');
           if (_pickedImage != null) {
               print('Advertencia: Se seleccionó foto pero el usuario ya existe. La foto no se actualizará aquí.');
           }
        } else {
          print('Email $email no encontrado. Creando nuevo registro de usuario en Firestore...');
          if (_pickedImage != null) {
            final tempUserIdForPhoto = const Uuid().v4(); // Solo para la ruta de la foto si el usuario es nuevo
            photoUrl = await _uploadImage(_pickedImage!, 'user_photos/$tempUserIdForPhoto.jpg');
            if (photoUrl == null) {
               setState(() => _isSaving = false);
               return;
            }
          }
          
          final newUserDoc = FirebaseFirestore.instance.collection('users').doc();
          userIdToAssign = newUserDoc.id;
          
          String firstName = '';
          String lastName = '';
          final parts = _fullNameController.text.trim().split(' ');
          if(parts.isNotEmpty) firstName = parts.first;
          if(parts.length > 1) lastName = parts.sublist(1).join(' ');

          final newUser = UserModel(
            email: email,
            name: firstName,
            surname: lastName,
            displayName: _fullNameController.text.trim(),
            photoUrl: photoUrl,
            phone: _phoneController.text.trim(),
            phoneCountryCode: _phoneCountryCode,
            phoneComplete: _phoneCompleteNumber,
            isoCountryCode: _isoCountryCode,
            birthDate: _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
            gender: _gender,
            createdAt: DateTime.now(),
          );
          await newUserDoc.set(newUser.toMap());
          print('Nuevo usuario creado en Firestore con ID: $userIdToAssign');
        }

        // Añadir a la familia solo si es modo creación (o si se quiere permitir cambiar)
        await FirebaseFirestore.instance.collection('families').doc(widget.familyId).update({
          'guardianUserIds': FieldValue.arrayUnion([userIdToAssign])
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Responsável ${_isEditMode ? "atualizado" : "adicionado"} com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }

    } catch (e) {
      print("Erro ao salvar responsável: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar responsável: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  // Helper para subir imagen (similar al de CreateEditFamilyScreen, adaptar si es necesario)
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
        title: Text(_isEditMode ? 'Editar Responsável' : 'Adicionar Responsável'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isLoadingData)
            const Center(child: CircularProgressIndicator())
          else
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

                    // Campos del Formulario (reutilizados de _buildStep2GuardianInfo)
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
                                firstDate: DateTime(1900), lastDate: DateTime.now(), locale: const Locale('pt', 'BR'),
                              );
                              if (picked != null && picked != _birthDate) setState(() => _birthDate = picked);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(labelText: 'Nascimento *', suffixIcon: const Icon(Icons.calendar_today_outlined),
                              // TODO: Validar fecha en _saveGuardian si es null
                              ),
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
                            items: ['Masculino', 'Feminino', 'Prefiro não dizer']
                                .map((label) => DropdownMenuItem(child: Text(label, overflow: TextOverflow.ellipsis), value: label))
                                .toList(),
                            onChanged: (value) => setState(() => _gender = value),
                            validator: (value) => (value == null) ? 'Obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IntlPhoneField(
                        key: UniqueKey(), // Key para posible reseteo si hay edición
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefone *', border: OutlineInputBorder(borderSide: BorderSide())), 
                        initialCountryCode: _isoCountryCode,
                        languageCode: 'pt',
                        onChanged: (phone) {
                          setState(() {
                            _phoneCompleteNumber = phone.completeNumber;
                            _phoneCountryCode = phone.countryCode;
                            _isoCountryCode = phone.countryISOCode;
                          });
                        },
                         validator: (phoneNumber) => (phoneNumber == null || phoneNumber.number.trim().isEmpty) ? 'Telefone é obrigatório.' : null,
                    ),
                     const SizedBox(height: 16),
                     DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Tipo de telefone *'),
                        value: _phoneType,
                        isExpanded: true, 
                        items: ['Teléfono', 'Comercial', 'Residencial'].map((label) => DropdownMenuItem(child: Text(label), value: label)).toList(),
                        onChanged: (value) => setState(() => _phoneType = value),
                        validator: (value) => (value == null) ? 'Obrigatório' : null,
                     ),
                    const SizedBox(height: 16),
                     TextFormField(
                        controller: _emailController,
                        enabled: !_isEditMode, // No permitir editar email en modo edición
                        decoration: const InputDecoration(labelText: 'Correo eletrônico *', suffixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                           if (value == null || value.trim().isEmpty) return 'Correo eletrônico é obrigatório.';
                           if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(value)) return 'Formato de correo inválido.';
                           return null;
                        },
                     ),
                    const SizedBox(height: 16),
                     TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                           labelText: _isEditMode ? 'Nova Senha (deixar em branco para não alterar)' : 'Senha *',
                           suffixIcon: IconButton(
                             icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                             onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                           ),
                        ),
                        obscureText: !_passwordVisible,
                        validator: (value) {
                           if (!_isEditMode && (value == null || value.isEmpty)) return 'Senha é obrigatória.';
                           if (value != null && value.isNotEmpty && value.length < 6) return 'Senha deve ter pelo menos 6 caracteres.';
                           return null;
                        },
                     ),
                     // No incluir dirección aquí según imagen 3
                  ],
                ),
              ),
            ),
        ],
      ),
       bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSaving ? Colors.grey.shade400 : AppColors.primary, // Color Naranja
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : _saveGuardian,
          child: Text(_isEditMode ? 'SALVAR ALTERAÇÕES' : 'GUARDAR RESPONSÁVEL', style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
} 