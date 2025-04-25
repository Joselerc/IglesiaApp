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
  final Map<String, dynamic> _responses = {};
  final Map<String, TextEditingController> _controllers = {};
  
  // Prefijo para las claves en SharedPreferences
  static const String _prefPrefix = 'field_response_';

  @override
  void initState() {
    super.initState();
    _loadSavedResponses();
  }

  // Cargar respuestas guardadas temporalmente
  Future<void> _loadSavedResponses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userId = user.uid;
      final prefKey = '${_prefPrefix}${userId}';
      
      final savedResponsesJson = prefs.getString(prefKey);
      if (savedResponsesJson != null) {
        print('Cargando respuestas guardadas temporalmente');
        // No necesitamos procesar el JSON ahora, lo haremos cuando se construya la UI
      }
    } catch (e) {
      print('Error al cargar respuestas guardadas: $e');
    }
  }
  
  // Guardar respuesta temporal para un campo específico
  Future<void> _saveTemporaryResponse(String fieldId, String value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final userId = user.uid;
      final fieldKey = '${_prefPrefix}${userId}_$fieldId';
      
      await prefs.setString(fieldKey, value);
      print('Respuesta guardada temporalmente: $fieldId = $value');
    } catch (e) {
      print('Error al guardar respuesta temporal: $e');
    }
  }
  
  // Cargar respuesta temporal para un campo específico
  Future<String?> _loadTemporaryResponse(String fieldId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final userId = user.uid;
      final fieldKey = '${_prefPrefix}${userId}_$fieldId';
      
      final value = prefs.getString(fieldKey);
      print('Cargando respuesta temporal: $fieldId = $value');
      return value;
    } catch (e) {
      print('Error al cargar respuesta temporal: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Liberar los controladores
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Usuário não autenticado'),
      );
    }

    return StreamBuilder<List<ProfileField>>(
      stream: _profileFieldsService.getActiveProfileFields(),
      builder: (context, fieldsSnapshot) {
        if (fieldsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (fieldsSnapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar os campos: ${fieldsSnapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final fields = fieldsSnapshot.data ?? [];

        if (fields.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Não há campos adicionais para completar',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
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

        return StreamBuilder<List<ProfileFieldResponse>>(
          stream: _profileFieldsService.getUserResponses(user.uid),
          builder: (context, responsesSnapshot) {
            if (responsesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final responses = responsesSnapshot.data ?? [];
            
            // Inicializar controladores y valores
            for (final field in fields) {
              if (!_controllers.containsKey(field.id)) {
                final response = responses.firstWhere(
                  (r) => r.fieldId == field.id,
                  orElse: () => ProfileFieldResponse(
                    id: '',
                    userId: user.uid,
                    fieldId: field.id,
                    value: '',
                    updatedAt: DateTime.now(),
                  ),
                );
                
                // Verificar si es un campo de tipo select
                if (field.type == 'select' && response.value != null && response.value.toString().isNotEmpty) {
                  print('🔍 Cargando selección guardada para "${field.name}": ${response.value}');
                }
                
                String initialValue = '';
                dynamic responseValue = response.value;
                
                // Para campos select, validar que el valor esté en las opciones
                if (field.type == 'select' && responseValue != null) {
                  final options = field.options ?? [];
                  if (!options.contains(responseValue.toString())) {
                    print('⚠️ Valor guardado "${responseValue}" no está en las opciones disponibles para "${field.name}"');
                    responseValue = null;
                  }
                }
                
                if (responseValue != null) {
                  if (field.type == 'date' && responseValue is DateTime) {
                    initialValue = DateFormat('yyyy-MM-dd').format(responseValue);
                  } else {
                    initialValue = responseValue.toString();
                  }
                }
                
                _controllers[field.id] = TextEditingController(text: initialValue);
                _responses[field.id] = responseValue;
              }
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
                              const SizedBox(height: 24),
                              ...fields.map((field) {
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
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
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
          },
        );
      },
    );
  }

  Widget _buildFieldInput(ProfileField field, String userId) {
    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
        return TextFormField(
          controller: _controllers[field.id],
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
          },
        );
      
      case 'number':
        return TextFormField(
          controller: _controllers[field.id],
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
          },
        );
      
      case 'date':
        return TextFormField(
          controller: _controllers[field.id],
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
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      _controllers[field.id]!.text = formattedDate;
                      _responses[field.id] = date;
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
        
        // Validar que el valor actual esté en la lista de opciones
        final currentValue = _responses[field.id] as String?;
        final isValueValid = currentValue != null && options.contains(currentValue);
        
        print('AdditionalInfoScreen - construyendo campo select: ${field.name}, currentValue=$currentValue, isValueValid=$isValueValid');
        
        // Cargar respuesta temporal si existe y no hay valor actual válido
        if (!isValueValid) {
          _loadTemporaryResponse(field.id).then((tempValue) {
            if (tempValue != null && options.contains(tempValue) && mounted) {
              print('Encontrada respuesta temporal para ${field.id}: $tempValue');
              _updateFieldValue(field.id, tempValue);
            }
          });
        }
        
        // Usar una clave única para evitar recreaciones del widget
        return SelectionField(
          // Añadir clave para mantener estado entre reconstrucciones
          key: ValueKey('selection_${field.id}'),
          label: field.name,
          hint: field.description,
          value: isValueValid ? currentValue : null,
          options: options,
          isRequired: field.isRequired,
          onChanged: (value) {
            print('AdditionalInfoScreen - onChanged llamado para ${field.name}: valor recibido=$value');
            
            if (value != null) {
              // Usar método para actualizar estado sin reconstruir toda la UI
              _updateFieldValue(field.id, value);
              
              // Guardar temporalmente la respuesta para persistencia entre reconstrucciones
              _saveTemporaryResponse(field.id, value);
            }
          },
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.list_alt,
              color: Colors.purple.withOpacity(0.7),
              size: 22,
            ),
          ),
          borderRadius: 10.0,
          backgroundColor: Colors.grey[50]!,
          dropdownIcon: Icons.keyboard_arrow_down,
        );
      
      default:
        return const Text('Tipo de campo no soportado');
    }
  }

  void _updateFieldValue(String fieldId, String value) {
    // Actualizar el mapa de respuestas de manera segura
    setState(() {
      _responses[fieldId] = value;
      if (_controllers.containsKey(fieldId)) {
        _controllers[fieldId]!.text = value;
      }
      
      print('🔵 Actualización de UI: Valor "${value}" guardado para el campo $fieldId');
      print('🔵 Estado respuestas: ${_responses.toString()}');
    });
    
    // Notificar solo al FormState para validación
    _formKey.currentState?.validate();
    
    print('AdditionalInfoScreen - valor actualizado STATE: fieldId=$fieldId, value=$value');
    
    // Guardar en SharedPreferences para persistencia entre reconstrucciones
    _saveTemporaryResponse(fieldId, value).then((_) {
      print('📱 Respuesta guardada temporalmente para $fieldId: $value');
    });
    
    // Opcionalmente, puedes guardar instantáneamente en Firebase 
    // para asegurar que se guarda sin necesidad de presionar "Guardar"
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final response = ProfileFieldResponse(
        id: '',
        userId: user.uid,
        fieldId: fieldId,
        value: value,
        updatedAt: DateTime.now(),
      );
      
      _profileFieldsService.saveUserResponse(response).then((_) {
        print('🔥 Respuesta guardada automáticamente en Firebase para $fieldId: $value');
      }).catchError((error) {
        print('❌ Error al guardar automáticamente: $error');
      });
    }
  }

  Future<void> _saveResponses(String userId) async {
    // Validación del formulario estándar
    if (!_formKey.currentState!.validate()) {
      print('Formulario no válido - no se guardarán las respuestas');
      return;
    }
    
    // Imprimir todas las respuestas para depuración
    print('==========================================');
    print('Valores antes de guardar:');
    _responses.forEach((key, value) {
      print('Campo $key: $value (${value?.runtimeType})');
    });
    print('==========================================');
    
    // Validación adicional para los campos select
    bool isValid = true;
    final fields = await _profileFieldsService.getActiveProfileFields().first;
    
    for (final field in fields) {
      if (field.isRequired) {
        final value = _responses[field.id];
        
        if (field.type == 'select') {
          if (value == null || (value is String && value.isEmpty)) {
            setState(() {
              // Forzar actualización de UI para mostrar error
              _responses[field.id] = null;
            });
            isValid = false;
          }
        } else if (value == null || (value is String && value.isEmpty)) {
          isValid = false;
        }
      }
    }
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Guardando respuestas para el usuario: $userId');
      print('Número de respuestas a guardar: ${_responses.length}');
      
      // Guardar cada respuesta
      for (final fieldId in _responses.keys) {
        final value = _responses[fieldId];
        print('Guardando respuesta para el campo: $fieldId');
        print('Valor: $value (${value.runtimeType})');
        
        // No guardar valores vacíos para campos de texto
        if (value is String && value.trim().isEmpty) {
          print('Omitiendo valor vacío para el campo: $fieldId');
          continue;
        }
        
        // Verificar si el valor es para un campo de tipo select
        final field = fields.firstWhere(
          (f) => f.id == fieldId,
          orElse: () => null as ProfileField,
        );
        
        if (field != null && field.type == 'select') {
          print('⭐ Guardando selección para el campo "${field.name}": $value');
        }
        
        final response = ProfileFieldResponse(
          id: '',
          userId: userId,
          fieldId: fieldId,
          value: value,
          updatedAt: DateTime.now(),
        );

        await _profileFieldsService.saveUserResponse(response);
        print('✅ Respuesta guardada exitosamente para el campo: $fieldId');
      }

      // Mostrar tostada con las respuestas guardadas
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informações salvas com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Actualizar el estado de completado del usuario
      final hasCompleted = await _profileFieldsService.hasCompletedRequiredFields(userId);
      print('¿El usuario ha completado todos los campos requeridos? $hasCompleted');
      
      // Actualizar el documento del usuario
      final updateData = {
        'hasCompletedAdditionalFields': hasCompleted,
        'additionalFieldsLastUpdated': FieldValue.serverTimestamp(),
      };

      // Si el usuario ha completado los campos requeridos y viene del banner, 
      // también actualizar los flags del banner para que no se muestre más
      if (hasCompleted && widget.fromBanner) {
        updateData['hasSkippedBanner'] = false; // Esto hará que el banner no se muestre temporalmente
        updateData['lastBannerShown'] = FieldValue.serverTimestamp(); // Actualizar la última vez que se mostró
        print('✅ Usuario completó campos desde el banner, actualizando flags para no mostrar temporalmente');
      }
      
      print('Actualizando documento del usuario con: $updateData');
      await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);
      
      print('Estado de usuario actualizado: hasCompletedAdditionalFields = $hasCompleted');

      // Si viene del banner y ha completado todos los campos requeridos, volver a la pantalla anterior
      if (widget.fromBanner) {
        print('Volviendo a la pantalla anterior desde el banner');
        // Si ha completado los campos, mostrar mensaje adicional
        if (hasCompleted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil completado com sucesso - A notificação não será mais exibida'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Esperar a que se muestre el mensaje antes de volver
          await Future.delayed(const Duration(milliseconds: 1000));
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      }

      // Al finalizar exitosamente, limpiar las respuestas temporales
      final prefs = await SharedPreferences.getInstance();
      for (final fieldId in _responses.keys) {
        final fieldKey = '${_prefPrefix}${userId}_$fieldId';
        await prefs.remove(fieldKey);
      }
    } catch (e) {
      print('Error al guardar respuestas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }
} 