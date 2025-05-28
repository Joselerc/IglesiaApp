import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/profile_field.dart';
import '../../models/profile_field_response.dart';
import '../../services/profile_fields_service.dart';
import '../../widgets/custom/selection_field.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final bool fromBanner;

  const AdditionalInfoScreen({
    super.key,
    this.fromBanner = false,
  });

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final ProfileFieldsService _profileFieldsService = ProfileFieldsService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // Controladores y valores para campos BÁSICOS
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // Para el número sin código de país
  String _phoneFullNumber = ''; // Para el número completo con código de país
  String _phoneCountryCode = 'BR'; // Código ISO del país por defecto
  DateTime? _birthDate;
  String? _gender;
  UserModel? _currentUserData; // Para almacenar los datos básicos del usuario

  // Controladores y valores para campos ADICIONALES
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _controllers = {};
  List<ProfileField> _fields = [];
  
  static const String _prefPrefix = 'field_response_';

  @override
  void initState() {
    super.initState();
    _initializeFieldsAndResponses();
  }

  Future<void> _initializeFieldsAndResponses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isInitializing = false);
      return;
    }

    try {
      // 1. Cargar datos básicos del usuario
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _currentUserData = UserModel.fromMap(userDoc.data()! as Map<String, dynamic>..['id'] = userDoc.id);
        _nameController.text = _currentUserData!.name ?? '';
        _surnameController.text = _currentUserData!.surname ?? '';
        
        // Manejo del teléfono
        _phoneController.text = _currentUserData!.phone ?? ''; // Asumiendo que 'phone' es el número local
        _phoneFullNumber = _currentUserData!.phoneComplete ?? '';
        _phoneCountryCode = _currentUserData!.isoCountryCode?.isNotEmpty == true 
                            ? _currentUserData!.isoCountryCode! 
                            : 'BR'; // O tu lógica para obtener el ISO del dial code

        // birthDate puede ser Timestamp o ya DateTime en tu UserModel
        if (_currentUserData!.birthDate is Timestamp) {
          _birthDate = (_currentUserData!.birthDate as Timestamp).toDate();
        } else if (_currentUserData!.birthDate is DateTime) {
          _birthDate = _currentUserData!.birthDate as DateTime?;
        }
        _gender = _currentUserData!.gender;
      }

      // 2. Cargar campos de perfil adicionales (tu lógica existente)
      _fields = await _profileFieldsService.getActiveProfileFields().first;
      if (_fields.isEmpty) {
        if (mounted) setState(() => _isInitializing = false);
        return;
      }

      final responsesFromFirestore = await _profileFieldsService.getUserResponses(user.uid).first;

      for (final field in _fields) {
        String initialTextForController = '';
        dynamic currentFieldValue;

        final firestoreResponseDoc = responsesFromFirestore.firstWhere(
          (r) => r.fieldId == field.id,
          orElse: () => ProfileFieldResponse(id: '', userId: user.uid, fieldId: field.id, value: null, updatedAt: DateTime.now()),
        );

        if (firestoreResponseDoc.value != null) {
          currentFieldValue = firestoreResponseDoc.value;
        }

        final temporarySavedValue = await _loadTemporaryResponse(field.id);
        if (temporarySavedValue != null) {
            currentFieldValue = temporarySavedValue;
        }
        
        if (field.type == 'select') {
          final options = field.options ?? [];
          if (currentFieldValue != null && options.contains(currentFieldValue.toString())) {
            initialTextForController = currentFieldValue.toString();
            _responses[field.id] = currentFieldValue.toString();
          } else {
            initialTextForController = '';
            _responses[field.id] = null; 
          }
        } else if (field.type == 'date' && currentFieldValue is Timestamp) {
            final dtValue = currentFieldValue.toDate();
            initialTextForController = DateFormat('yyyy-MM-dd').format(dtValue);
            _responses[field.id] = dtValue;
        } else if (field.type == 'date' && currentFieldValue is DateTime) {
          initialTextForController = DateFormat('yyyy-MM-dd').format(currentFieldValue);
          _responses[field.id] = currentFieldValue;
        } else if (currentFieldValue != null) {
          initialTextForController = currentFieldValue.toString();
          _responses[field.id] = currentFieldValue;
        } else {
            _responses[field.id] = null;
        }

        _controllers[field.id] = TextEditingController(text: initialTextForController);
      }
    } catch (e) {
      debugPrint("Error inicializando campos y respuestas: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }
  
  Future<String?> _loadTemporaryResponse(String fieldId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final prefs = await SharedPreferences.getInstance();
      final fieldKey = '${_prefPrefix}${user.uid}_$fieldId';
      return prefs.getString(fieldKey);
    } catch (e) {
      print('Error al cargar respuesta temporal para $fieldId: $e');
      return null;
    }
  }

  Future<void> _saveTemporaryResponse(String fieldId, String value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();
      final fieldKey = '${_prefPrefix}${user.uid}_$fieldId';
      await prefs.setString(fieldKey, value);
    } catch (e) {
      print('Error al guardar respuesta temporal para $fieldId: $e');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuário não autenticado'));
    }

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fields.isEmpty && !_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Não há campos adicionais para completar',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Informações Adicionais',
              style: AppTextStyles.headline3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Por favor, complete as seguintes informações:',
                          style: AppTextStyles.bodyText1,
                        ),
                      ),
                      const SizedBox(height: 16), // Espacio antes de los campos básicos

                      // --- CAMPOS BÁSICOS (si no están completos) ---
                      if (!_isBasicFieldComplete('name')) 
                        _buildBasicTextField(_nameController, 'Nome', 'Digite seu nome', Icons.person),
                      if (!_isBasicFieldComplete('surname')) 
                        _buildBasicTextField(_surnameController, 'Sobrenome', 'Digite seu sobrenome', Icons.person_outline),
                      if (!_isBasicFieldComplete('birthDate')) 
                        _buildBirthDateField(),
                      if (!_isBasicFieldComplete('gender')) 
                        _buildGenderField(),
                      if (!_isBasicFieldComplete('phone')) 
                        _buildPhoneField(),
                      
                      // Separador si se muestran campos básicos Y hay campos adicionales
                      if ((!_isBasicFieldComplete('name') || !_isBasicFieldComplete('surname') || !_isBasicFieldComplete('birthDate') || !_isBasicFieldComplete('gender') || !_isBasicFieldComplete('phone')) && _fields.isNotEmpty)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Text('Outras Informações', style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary)),
                            const Divider(height: 24),
                          ],
                        ),
                      
                      // --- CAMPOS ADICIONALES (como ya los tenías) ---
                      ..._fields.map((field) {
                        if (!_controllers.containsKey(field.id)) {
                           _controllers[field.id] = TextEditingController();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFieldInput(field, user.uid), 
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + MediaQuery.of(context).padding.bottom),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _saveResponses(user.uid),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text(
                      'Salvar Informações',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInput(ProfileField field, String userId) {
    TextEditingController? controller = _controllers[field.id];
    if (controller == null) {
        print("ERROR: Controlador no encontrado para el campo ${field.id} en _buildFieldInput");
        controller = TextEditingController(); 
        _controllers[field.id] = controller;
    }

    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            helperText: field.description,
            border: const OutlineInputBorder(),
            suffixIcon: field.isRequired
                ? const Icon(Icons.star, size: 10, color: Colors.red)
                : null,
          ),
          keyboardType: field.type == 'email'
              ? TextInputType.emailAddress
              : field.type == 'phone'
                  ? TextInputType.phone
                  : TextInputType.text,
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            if (field.type == 'email' && value != null && value.isNotEmpty) {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Insira um email válido';
              }
            }
            if (field.type == 'phone' && value != null && value.isNotEmpty) {
              final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Insira um número de telefone válido';
              }
            }
            return null;
          },
          onChanged: (value) {
            _responses[field.id] = value;
            _saveTemporaryResponse(field.id, value);
          },
        );
      
      case 'number':
         return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            helperText: field.description,
            border: const OutlineInputBorder(),
            suffixIcon: field.isRequired
                ? const Icon(Icons.star, size: 10, color: Colors.red)
                : null,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
             if (field.isRequired && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            if (value != null && value.isNotEmpty) {
              final numRegex = RegExp(r'^[0-9]+$');
              if (!numRegex.hasMatch(value)) {
                return 'Insira um número válido';
              }
            }
            return null;
          },
          onChanged: (value) {
            _responses[field.id] = int.tryParse(value) ?? value;
            _saveTemporaryResponse(field.id, value); 
          },
        );

      case 'date':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            helperText: field.description,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (field.isRequired)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.star, size: 10, color: Colors.red),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime initialPickerDate = DateTime.now();
                    if (_responses[field.id] is DateTime) {
                        initialPickerDate = _responses[field.id];
                    } else if (controller!.text.isNotEmpty) {
                        try {
                            initialPickerDate = DateFormat('yyyy-MM-dd').parse(controller.text);
                        } catch (e) { /* usa DateTime.now() */ }
                    }
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initialPickerDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      controller!.text = formattedDate;
                      _responses[field.id] = date;
                      _saveTemporaryResponse(field.id, formattedDate);
                    }
                  },
                ),
              ],
            ),
          ),
          readOnly: true,
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) {
              return 'Este campo é obrigatório';
            }
            return null;
          },
        );
      
      case 'select':
        final options = field.options ?? [];
        String? currentValueInResponses = _responses[field.id] as String?;
        if (currentValueInResponses != null && !options.contains(currentValueInResponses)) {
            currentValueInResponses = null;
        }

        return SelectionField(
          key: ValueKey('selection_${field.id}'), 
          label: field.name,
          hint: field.description,
          value: currentValueInResponses,
          options: options,
          isRequired: field.isRequired,
          onChanged: (value) {
            if (value != null) {
              _updateFieldValue(field.id, value);
            }
          },
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.list_alt, color: Colors.purple.withOpacity(0.7), size: 22),
          ),
          borderRadius: 10.0,
          backgroundColor: Colors.grey[50]!,
          dropdownIcon: Icons.keyboard_arrow_down,
        );
      
      default:
        return Text('Tipo de campo não suportado: ${field.type}');
    }
  }

  void _updateFieldValue(String fieldId, String value) {
    _responses[fieldId] = value;
    _saveTemporaryResponse(fieldId, value);
    print('AdditionalInfoScreen - _updateFieldValue para ${fieldId}: valor=$value');
  }

  Future<void> _saveResponses(String userId) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, corrija os erros antes de salvar.'), backgroundColor: Colors.red,)
      );
      return;
    }
    
    bool allRequiredBasicFilled = true;
    // Validar campos básicos requeridos que están visibles
    if (!_isBasicFieldComplete('name') && (_nameController.text.trim().isEmpty)) allRequiredBasicFilled = false;
    if (!_isBasicFieldComplete('surname') && (_surnameController.text.trim().isEmpty)) allRequiredBasicFilled = false;
    if (!_isBasicFieldComplete('birthDate') && _birthDate == null) allRequiredBasicFilled = false;
    if (!_isBasicFieldComplete('gender') && (_gender == null || _gender!.isEmpty)) allRequiredBasicFilled = false;
    if (!_isBasicFieldComplete('phone') && (_phoneController.text.trim().isEmpty)) allRequiredBasicFilled = false;

    if (!allRequiredBasicFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, preencha todos os campos básicos obrigatórios.'), backgroundColor: Colors.red,)
        );
        return;
    }
    
    bool allRequiredAdditionalFilled = true;
    for (final field in _fields) {
        if (field.isRequired) {
            final value = _responses[field.id];
            if (value == null || (value is String && value.isEmpty)) {
                allRequiredAdditionalFilled = false;
                break;
            }
        }
    }

    if (!allRequiredAdditionalFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, preencha todos os campos adicionais obrigatórios (*)'), backgroundColor: Colors.red,)
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
      // Guardar campos de perfil adicionales
      for (final field in _fields) {
        final fieldId = field.id;
        final value = _responses[fieldId];

        if (value == null) continue;
        if (value is String && value.trim().isEmpty && field.type != 'select') continue;
        if (field.type == 'select' && (value == null || value.toString().isEmpty)) continue;

        final response = ProfileFieldResponse(
          id: '',
          userId: userId,
          fieldId: fieldId,
          value: value,
          updatedAt: DateTime.now(),
        );
        await _profileFieldsService.saveUserResponse(response);
      }

      final hasCompletedAdditional = await _profileFieldsService.hasCompletedRequiredFields(userId);
      
      // Preparar datos del usuario para actualizar (incluyendo básicos)
      final Map<String, dynamic> userDataToUpdate = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'displayName': '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        'phone': _phoneController.text.trim(),
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
        'gender': _gender,
        'hasCompletedAdditionalFields': hasCompletedAdditional,
        'additionalFieldsLastUpdated': FieldValue.serverTimestamp(),
      };

      // Lógica para phoneComplete, isoCountryCode y phoneCountryCode (código de marcación)
      final String phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isNotEmpty) {
        userDataToUpdate['isoCountryCode'] = _phoneCountryCode; // _phoneCountryCode aquí es el ISO (ej: 'BR')
        
        // Intentar obtener el código de marcación de _currentUserData o usar un fallback
        String dialCode = _currentUserData?.phoneCountryCode ?? ''; // Este es el código de marcación (+55)
        if (dialCode.isEmpty && _phoneCountryCode == 'BR') {
          dialCode = '+55'; // Fallback para Brasil si no hay nada en _currentUserData
        }
        userDataToUpdate['phoneCountryCode'] = dialCode; // Código de marcación (+55)
        userDataToUpdate['phoneComplete'] = '$dialCode$phoneNumber';

      } else {
        userDataToUpdate['isoCountryCode'] = '';
        userDataToUpdate['phoneCountryCode'] = '';
        userDataToUpdate['phoneComplete'] = '';
      }

      if (hasCompletedAdditional && widget.fromBanner) {
        userDataToUpdate['hasSkippedBanner'] = false;
        userDataToUpdate['lastBannerShown'] = FieldValue.serverTimestamp(); 
      }
      
      await FirebaseFirestore.instance.collection('users').doc(userId).update(userDataToUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informações salvas com sucesso'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      for (final fieldId in _responses.keys) {
        final fieldKey = '${_prefPrefix}${userId}_$fieldId';
        await prefs.remove(fieldKey);
      }

      if (widget.fromBanner && mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      print('Error al guardar respuestas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper para verificar si los campos básicos están completos (ejemplo simple)
  bool _isBasicFieldComplete(String fieldName) {
    if (_currentUserData == null) return true; // Si no hay datos, no podemos decir que esté incompleto para mostrarlo
    switch (fieldName) {
      case 'name': return _currentUserData!.name?.isNotEmpty == true;
      case 'surname': return _currentUserData!.surname?.isNotEmpty == true;
      case 'phone': return _currentUserData!.phone?.isNotEmpty == true; 
      case 'birthDate': return _currentUserData!.birthDate != null;
      case 'gender': return _currentUserData!.gender?.isNotEmpty == true;
      default: return true; 
    }
  }

  // --- WIDGETS PARA CONSTRUIR CAMPOS BÁSICOS ---
  Widget _buildBasicTextField(TextEditingController controller, String label, String hint, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(iconData, color: AppColors.primary.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: const Tooltip(message: 'Campo obrigatório', child: Icon(Icons.star, size: 10, color: Colors.red)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo é obrigatório';
          }
          return null;
        },
        // onChanged: (value) { setState(() {}); } // Podría ser necesario para actualizar el estado si _isBasicFieldComplete depende de controladores
      ),
    );
  }

  Widget _buildBirthDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: TextEditingController(
          text: _birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : ''
        ),
        readOnly: true,
        decoration: InputDecoration(
          labelText: 'Data de Nascimento',
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: const Tooltip(message: 'Campo obrigatório', child: Icon(Icons.star, size: 10, color: Colors.red)),
        ),
        onTap: () async {
          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: _birthDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            locale: const Locale('pt', 'BR'),
          );
          if (pickedDate != null && pickedDate != _birthDate) {
            setState(() {
              _birthDate = pickedDate;
              // El controlador se actualiza por el `text` en su constructor la próxima vez que se construya o podrías actualizarlo aquí explícitamente.
            });
          }
        },
        validator: (value) {
          if (_birthDate == null) { // Validar la variable de estado _birthDate
            return 'Este campo é obrigatório';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _gender,
        decoration: InputDecoration(
          labelText: 'Gênero',
          prefixIcon: Icon(Icons.person_outline, color: AppColors.primary.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: const Tooltip(message: 'Campo obrigatório', child: Icon(Icons.star, size: 10, color: Colors.red)),
        ),
        items: ['Masculino', 'Feminino', 'Prefiro não dizer'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _gender = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo é obrigatório';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    // Usar IntlPhoneField que ya tienes en ProfileScreen sería ideal para consistencia,
    // pero requiere más configuración. Por ahora, un TextFormField simple.
    // Si quieres IntlPhoneField, necesitaríamos añadir la dependencia y la lógica de manejo del número completo.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _phoneController, // Asume que _phoneController solo tiene el número local
        decoration: InputDecoration(
          labelText: 'Telefone',
          hintText: 'Ex: 912345678',
          prefixIcon: Icon(Icons.phone, color: AppColors.primary.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[50],
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: const Tooltip(message: 'Campo obrigatório', child: Icon(Icons.star, size: 10, color: Colors.red)),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo é obrigatório';
          }
          // Aquí podrías añadir una validación de formato de teléfono más específica si lo deseas.
          return null;
        },
        onChanged: (value) {
          // Actualizar el número de teléfono. La lógica del número completo se manejará al guardar.
        },
      ),
    );
  }
} 