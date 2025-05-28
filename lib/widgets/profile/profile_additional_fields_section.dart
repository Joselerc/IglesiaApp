import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para userId
import 'package:intl/intl.dart';
import '../../../models/profile_field.dart';
import '../../../models/profile_field_response.dart';
import '../../../services/profile_fields_service.dart';
import '../../../widgets/custom/selection_field.dart'; // Asumiendo la ruta correcta
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/skeletons/additional_fields_skeleton.dart'; // Para el loader

class ProfileAdditionalFieldsSection extends StatefulWidget {
  final String userId;
  const ProfileAdditionalFieldsSection({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileAdditionalFieldsSection> createState() => _ProfileAdditionalFieldsSectionState();
}

class _ProfileAdditionalFieldsSectionState extends State<ProfileAdditionalFieldsSection> {
  final ProfileFieldsService _profileFieldsService = ProfileFieldsService();
  final _formKey = GlobalKey<FormState>(); // Clave para el Form si decides usarla aquí
  bool _isLoading = false; // Para el feedback del botón de guardar
  bool _isInitialized = false;

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _fieldValues = {};
  List<ProfileField> _fieldsToDisplay = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  Future<void> _initializeFields() async {
    if (widget.userId.isEmpty) {
      if (mounted) setState(() => _isInitialized = true); // Marcar como inicializado aunque no haya userId
      return;
    }
    try {
      final fields = await _profileFieldsService.getActiveProfileFields().first;
      if (fields.isEmpty) {
        if (mounted) setState(() => _isInitialized = true);
        return;
      }
      _fieldsToDisplay = List.from(fields);

      final responses = await _profileFieldsService.getUserResponses(widget.userId).first;

      for (var field in _fieldsToDisplay) {
        final response = responses.firstWhere(
          (r) => r.fieldId == field.id,
          orElse: () => ProfileFieldResponse(id: '', userId: widget.userId, fieldId: field.id, value: null, updatedAt: DateTime.now()),
        );

        String initialText = '';
        dynamic initialFieldValue = response.value;

        if (field.type == 'date') {
          DateTime? dateVal;
          if (initialFieldValue is Timestamp) dateVal = initialFieldValue.toDate();
          else if (initialFieldValue is DateTime) dateVal = initialFieldValue;
          initialText = dateVal != null ? DateFormat('dd/MM/yyyy').format(dateVal) : '';
        } else {
          initialText = initialFieldValue?.toString() ?? '';
        }
        
        _controllers.putIfAbsent(field.id, () => TextEditingController(text: initialText));
        _fieldValues.putIfAbsent(field.id, () => initialFieldValue);
      }
    } catch (e) {
      debugPrint("Error inicializando campos adicionales en ProfileAdditionalFieldsSection: $e");
      // Considerar mostrar un mensaje de error
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // _buildFieldInput y _guardarInformacionAdicional serán muy similares a las versiones corregidas
  // que discutimos para ProfileScreen, pero usarán el estado local de este widget.

  Widget _buildFieldInput(ProfileField field) {
    TextEditingController controller = _controllers[field.id]!;
    final Color primaryColor = const Color(0xFF9C27B0);
    dynamic currentValue = _fieldValues[field.id];

    // Sincronizar controller con currentValue (especialmente para date, y para texto si currentValue cambió por fuera)
    if (field.type == 'date') {
      DateTime? dateValue;
      if (currentValue is Timestamp) dateValue = currentValue.toDate();
      else if (currentValue is DateTime) dateValue = currentValue;
      final formattedDateText = dateValue != null ? DateFormat('dd/MM/yyyy').format(dateValue) : '';
      if (controller.text != formattedDateText) controller.text = formattedDateText;
    } else if (field.type != 'select') {
      final currentControllerText = currentValue?.toString() ?? '';
      if (controller.text != currentControllerText) controller.text = currentControllerText;
    }

    InputDecoration standardInputDecoration(String label, String? hint, IconData prefixIconData, bool isRequired) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
        // errorBorder y focusedErrorBorder pueden ayudar a que el borde no se quede rojo si el valor es válido.
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.red.shade700, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.red.shade900, width: 1.5)),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(prefixIconData, color: primaryColor.withOpacity(0.7)),
        suffixIcon: isRequired ? Tooltip(message: 'Campo obrigatório', child: Icon(Icons.star, size: 10, color: Colors.red[400])) : null,
      );
    }

    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'number':
        return TextFormField(
          controller: controller,
          decoration: standardInputDecoration(field.name, field.description, _getIconDataForFieldType(field.type), field.isRequired),
          keyboardType: field.type == 'email' ? TextInputType.emailAddress : field.type == 'phone' ? TextInputType.phone : field.type == 'number' ? TextInputType.number : TextInputType.text,
          validator: (value) => (field.isRequired && (value == null || value.isEmpty)) ? 'Este campo é obrigatório' : null,
          onChanged: (value) {
            setState(() {
              if (field.type == 'number') _fieldValues[field.id] = int.tryParse(value) ?? value;
              else _fieldValues[field.id] = value;
            });
          },
        );
      case 'date':
        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: standardInputDecoration(field.name, field.description, Icons.calendar_today, field.isRequired),
          onTap: () async {
            DateTime initialDate = DateTime.now();
            if (_fieldValues[field.id] is DateTime) initialDate = _fieldValues[field.id];
            else if (_fieldValues[field.id] is Timestamp) initialDate = (_fieldValues[field.id] as Timestamp).toDate();
            
            final date = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(1900), lastDate: DateTime.now(), locale: const Locale('pt', 'BR'));
            if (date != null) {
              setState(() {
                _fieldValues[field.id] = date;
                controller.text = DateFormat('dd/MM/yyyy').format(date);
              });
            }
          },
          validator: (value) => (field.isRequired && _fieldValues[field.id] == null) ? 'Este campo é obrigatório' : null,
        );
      case 'select':
        final options = field.options ?? [];
        String? currentSelection = _fieldValues[field.id] as String?;
        if (currentSelection != null && !options.contains(currentSelection)) currentSelection = null;
        
        return Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: InputDecorationTheme(
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorStyle: const TextStyle(fontSize: 0, height: 0, color: Colors.transparent),
            ),
          ),
          child: FormField<String>(
            key: ValueKey('form_field_select_${field.id}'),
            initialValue: currentSelection,
            validator: (value) {
              return null;
            },
            builder: (FormFieldState<String> fieldState) {
              return Column( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectionFormField(
                    initialValue: fieldState.value, 
                    label: field.name, 
                    hint: field.description ?? 'Seleccione uma opción',
                    options: options,
                    isRequired: field.isRequired, 
                    onChanged: (value) {
                      setState(() { 
                        _fieldValues[field.id] = value; 
                        fieldState.didChange(value);
                      });
                    },
                  ),
                ],
              );
            },
          ),
        );
      default: return Text('Tipo de campo não suportado: ${field.type}');
    }
  }

  Future<void> _saveAdditionalFields() async {
    // if (_formKey.currentState?.validate() == false) return; // Si usas Form y validación global

    bool allValid = true;
    for (var field in _fieldsToDisplay) {
        if (field.isRequired) {
            final value = _fieldValues[field.id];
            if (value == null || (value is String && value.trim().isEmpty)) {
                allValid = false;
                break;
            }
        }
    }
    if (!allValid) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios (*).'), backgroundColor: Colors.red));
        return;
    }

    setState(() => _isLoading = true);
    try {
      for (var field in _fieldsToDisplay) {
        final valueToSave = _fieldValues[field.id];
        if (valueToSave == null && !field.isRequired) continue;
        if (valueToSave is String && valueToSave.trim().isEmpty && field.type != 'select' && !field.isRequired) continue;
        
        // No crear respuesta si no es requerida y el valor es nulo o un string vacío (para select)
        if (!field.isRequired && (valueToSave == null || (valueToSave is String && valueToSave.isEmpty && field.type == 'select'))) continue;

        final response = ProfileFieldResponse(
          id: '', userId: widget.userId, fieldId: field.id, value: valueToSave, updatedAt: DateTime.now(),
        );
        await _profileFieldsService.saveUserResponse(response);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informações adicionais salvas com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar informações: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconDataForFieldType(String type) { /* ... tu implementación ... */ 
    switch (type) {
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'date': return Icons.calendar_today;
      case 'select': return Icons.list_alt;
      case 'number': return Icons.format_list_numbered;
      case 'text':
      default: return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const AdditionalFieldsSkeleton();
    if (_fieldsToDisplay.isEmpty) return const SizedBox.shrink(); // No mostrar nada si no hay campos

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: const [Icon(Icons.assignment_outlined, color: Color(0xFF9C27B0), size: 20), SizedBox(width: 12), Text('Informação Adicional', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0)))]),
                ElevatedButton.icon(
                  icon: _isLoading ? Container(width:16, height:16, child:CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : const Icon(Icons.save, size: 14, color: Colors.white),
                  label: const Text('Salvar', style: TextStyle(fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), elevation: 0, minimumSize: const Size(85, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: _isLoading ? null : _saveAdditionalFields,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            // Considerar usar un Form aquí con el _formKey si necesitas validación global de esta sección
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _fieldsToDisplay.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildFieldInput(field),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
} 