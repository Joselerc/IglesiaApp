import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../models/user_model.dart'; // Asumiendo la necesidad y la ruta
import '../../../theme/app_colors.dart'; // Para colores consistentes
import '../../../theme/app_text_styles.dart'; // Para estilos de texto consistentes
import '../../l10n/app_localizations.dart';

class ProfilePersonalInformationSection extends StatefulWidget {
  final String userId;

  const ProfilePersonalInformationSection({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePersonalInformationSectionState createState() => _ProfilePersonalInformationSectionState();
}

class _ProfilePersonalInformationSectionState extends State<ProfilePersonalInformationSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  UserModel? _currentUserData; // Para almacenar los datos cargados del usuario

  // Variables para el teléfono con código de país
  String _phoneCountryCode = '+55'; // Código de marcación (ej: +55)
  String _phoneCompleteNumber = '';
  bool _isValidPhone = false;
  String _isoCountryCode = 'BR'; // Código ISO (ej: BR)

  // Campos para perfil
  DateTime? _birthDate;
  String? _gender;

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _loadPersonalData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalData() async {
    if (widget.userId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _currentUserData = UserModel.fromMap(userData);

        _nameController.text = _currentUserData?.name ?? '';
        _surnameController.text = _currentUserData?.surname ?? '';

        final phoneSimple = userData['phone'] as String? ?? '';
        _phoneController.text = phoneSimple;
        _phoneCompleteNumber = userData['phoneComplete'] as String? ?? '';
        _phoneCountryCode = userData['phoneCountryCode'] as String? ?? '+55';
        _isoCountryCode = userData['isoCountryCode'] as String? ?? _getIsoCodeFromDialCode(_phoneCountryCode);
        // _isValidPhone = phoneSimple.length >= 8; // Ajustar según reglas de validación

        _birthDate = (userData['birthDate'] as Timestamp?)?.toDate();
        _gender = userData['gender'] as String?;
        
        // Log para verificar carga
        print('PROFILE_PERSONAL_INFO_SECTION: Datos personales cargados para userId: ${widget.userId}');

      } else {
        print('PROFILE_PERSONAL_INFO_SECTION: Documento no existe o widget no montado para userId: ${widget.userId}');
      }
    } catch (e) {
      print('PROFILE_PERSONAL_INFO_SECTION: Error al cargar datos personales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingPersonalData(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getIsoCodeFromDialCode(String? dialCode) {
    final Map<String, String> dialCodeToIso = {
      '+1': 'US', '+44': 'GB', '+351': 'PT', '+34': 'ES', '+49': 'DE',
      '+33': 'FR', '+39': 'IT', '+54': 'AR', '+57': 'CO', '+52': 'MX',
      '+55': 'BR', '+81': 'JP', '+86': 'CN', '+91': 'IN',
    };
    return dialCodeToIso[dialCode] ?? 'BR';
  }

  Future<void> _savePersonalData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final String phoneNumber = _phoneController.text.trim();
      String currentCompleteNumber = _phoneCompleteNumber;
      String currentCountryCode = _phoneCountryCode;
      String currentIsoCode = _isoCountryCode;

      // Reconstruir número completo si solo se cambió el código de país pero no el número.
      // O si el número simple fue editado y no corresponde al completo.
      if (phoneNumber.isNotEmpty && (!currentCompleteNumber.contains(phoneNumber) || !currentCompleteNumber.startsWith(currentCountryCode))) {
          currentCompleteNumber = '$currentCountryCode$phoneNumber';
      }


      final Map<String, dynamic> dataToSave = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'displayName': '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        'phone': phoneNumber,
        'isoCountryCode': phoneNumber.isNotEmpty ? currentIsoCode : '',
        'phoneComplete': phoneNumber.isNotEmpty ? currentCompleteNumber : '',
        'phoneCountryCode': phoneNumber.isNotEmpty ? currentCountryCode : '',
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
        'gender': _gender,
        'lastProfileUpdate': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(dataToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.personalInfoUpdatedSuccessfully), backgroundColor: Colors.green),
        );
      }
      print('PROFILE_PERSONAL_INFO_SECTION: Datos personales guardados para userId: ${widget.userId}');

    } catch (e) {
      print('PROFILE_PERSONAL_INFO_SECTION: Error al guardar datos personales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingPersonalData(e.toString())), backgroundColor: Colors.red),
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
    if (_isLoading && _currentUserData == null) { // Muestra skeleton solo en la carga inicial
      return const CircularProgressIndicator(); // Placeholder, podrías usar un skeleton más elaborado
    }

    // Aquí irá la UI copiada y adaptada de ProfileScreen
    return Form(
      key: _formKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.personalInformationSection,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: _isLoading 
                          ? Container(width: 16, height: 16, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, size: 14, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.save,
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 0,
                        minimumSize: const Size(85, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _savePersonalData,
                    ),
                  ),
                ],
              ),
            ),
            // Contenido de los campos
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Campo Nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.name,
                      labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Container(margin: const EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.person_outline, color: const Color(0xFF2196F3).withOpacity(0.7))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.pleaseEnterYourName : null,
                  ),
                  const SizedBox(height: 16),

                  // Campo Apellido
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.surname,
                      labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Container(margin: const EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.person_outline, color: const Color(0xFF2196F3).withOpacity(0.7))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? AppLocalizations.of(context)!.pleaseEnterYourSurname : null,
                  ),
                  const SizedBox(height: 16),

                  // Campo Fecha de Nacimiento
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        locale: const Locale('pt', 'BR'),
                        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white)), child: child!),
                      );
                      if (picked != null && picked != _birthDate) {
                        setState(() => _birthDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.birthDateField,
                        labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Container(margin: const EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.calendar_today_outlined, color: const Color(0xFF2196F3).withOpacity(0.7))),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          _birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : AppLocalizations.of(context)!.selectDate,
                          style: _birthDate != null ? AppTextStyles.bodyText1.copyWith(color: Colors.black87) : AppTextStyles.bodyText1.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Sexo
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.genderField,
                      labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: Container(margin: const EdgeInsets.only(left: 12, right: 8), child: Icon(Icons.person_search_outlined, color: const Color(0xFF2196F3).withOpacity(0.7))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    ),
                    value: _gender,
                    isExpanded: true,
                    items: [AppLocalizations.of(context)!.male, AppLocalizations.of(context)!.female, AppLocalizations.of(context)!.preferNotToSay]
                        .map((label) => DropdownMenuItem(child: Padding(padding: const EdgeInsets.only(left: 12.0), child: Text(label)), value: label))
                        .toList(),
                    onChanged: (value) => setState(() => _gender = value),
                    selectedItemBuilder: (BuildContext context) {
                      return [AppLocalizations.of(context)!.male, AppLocalizations.of(context)!.female, AppLocalizations.of(context)!.preferNotToSay].map<Widget>((String item) {
                        return Padding(padding: const EdgeInsets.only(left:12.0), child: Text(item, style: AppTextStyles.bodyText1.copyWith(color: Colors.black87)));
                      }).toList();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Teléfono
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_phoneCompleteNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(AppLocalizations.of(context)!.currentNumber(_phoneCompleteNumber), style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                        ),
                      IntlPhoneField(
                        controller: _phoneController, // ASIGNAR EL CONTROLADOR
                        initialCountryCode: _isoCountryCode,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.phoneField,
                          labelStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          hintText: _phoneController.text.isEmpty ? AppLocalizations.of(context)!.optional : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (phone) {
                          setState(() {
                            final cleanNumber = phone.number.replaceAll(RegExp(r'\s+'), '');
                            // NO actualizar _phoneController.text aquí directamente si ya está asignado al widget.
                            // Dejar que el widget maneje la actualización de su propio controller.
                            // Lo que sí actualizamos son las variables de estado para la lógica de guardado.
                            _phoneCountryCode = phone.countryCode;
                            _phoneCompleteNumber = phone.completeNumber;
                            _isoCountryCode = phone.countryISOCode;
                            // _isValidPhone = cleanNumber.length >= 8; // O la validación que prefieras
                          });
                        },
                        onCountryChanged: (country) {
                          setState(() {
                            _isoCountryCode = country.code;
                            _phoneCountryCode = '+${country.dialCode}';
                            // Actualizar el número completo si ya hay un número ingresado
                            if (_phoneController.text.isNotEmpty) {
                              _phoneCompleteNumber = '$_phoneCountryCode${_phoneController.text}';
                            }
                          });
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) return null; // Opcional
                          if (phone.number.length < 8) return AppLocalizations.of(context)!.invalidPhone;
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 