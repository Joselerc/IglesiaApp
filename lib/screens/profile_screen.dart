import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/circular_image_picker.dart';
import '../models/user_model.dart';
import '../models/profile_field.dart';
import '../models/profile_field_response.dart';
import '../services/profile_fields_service.dart';
import '../theme/app_colors.dart';
import 'announcements/create_announcement_modal.dart';
import 'notifications/push_notification_screen.dart';
import '../modals/create_ministry_modal.dart';
import '../modals/create_group_modal.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'admin/user_role_management_screen.dart';
import 'statistics/ministry_members_stats_screen.dart';
import 'statistics/group_members_stats_screen.dart';
import 'statistics_services/services_stats_screen.dart';
import '../widgets/custom/selection_field.dart';
import 'admin/manage_home_sections_screen.dart';
import '../theme/app_text_styles.dart';
import 'admin/profile_fields_admin_screen.dart';
import 'admin/manage_live_stream_config_screen.dart'; // <-- Import añadido
import 'admin/manage_donations_screen.dart'; // <-- Import añadido


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  UserModel? _currentUser;
  final ProfileFieldsService _profileFieldsService = ProfileFieldsService();
  bool _isPastor = false;
  
  // Variables para el teléfono con código de país
  String _phoneCountryCode = '+55'; // Código de marcación (ej: +55)
  String _phoneCompleteNumber = '';
  bool _isValidPhone = false;
  String _isoCountryCode = 'BR'; // NUEVO: Código ISO (ej: BR)

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPastorStatus();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 CARGANDO DATOS DE USUARIO');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          // Obtener los datos del teléfono
          final phoneSimple = userData['phone'] as String? ?? '';
          final phoneComplete = userData['phoneComplete'] as String? ?? '';
          final phoneCountryCode = userData['phoneCountryCode'] as String? ?? '+55';
          
          // Log detallado de los datos cargados
          print('📱 DATOS DE TELÉFONO CARGADOS DE FIRESTORE:');
          print('- phone: "$phoneSimple"');
          print('- phoneComplete: "$phoneComplete"');
          print('- phoneCountryCode: "$phoneCountryCode"');
          
          // Leer ISO code directamente, con fallback a conversión para datos antiguos
          String loadedIsoCode = userData['isoCountryCode'] as String? ?? '';
          if (loadedIsoCode.isEmpty) {
            print('⚠️ isoCountryCode no encontrado en Firestore, usando fallback desde phoneCountryCode: $phoneCountryCode');
            loadedIsoCode = _getIsoCodeFromDialCode(phoneCountryCode);
          } else {
            print('🌍 Código ISO cargado desde Firestore: $loadedIsoCode');
          }
          
          setState(() {
            _currentUser = UserModel.fromMap(userData);
            _nameController.text = _currentUser?.name ?? '';
            _surnameController.text = _currentUser?.surname ?? '';
            
            // Asignar los valores del teléfono de manera segura
            _phoneController.text = phoneSimple;
            _phoneCompleteNumber = phoneComplete;
            _phoneCountryCode = phoneCountryCode; // Guardamos el dial code leído
            _isoCountryCode = loadedIsoCode; // Usar el código ISO cargado o convertido
            _isValidPhone = phoneSimple.length >= 8;
            
            // Log adicional después de asignar
            print('📱 TELÉFONO INICIALIZADO EN UI:');
            print('- _phoneController.text: "${_phoneController.text}"');
            print('- _phoneCompleteNumber: "$_phoneCompleteNumber"');
            print('- _phoneCountryCode: "$_phoneCountryCode"');
            print('- _isValidPhone: $_isValidPhone');
          });
        } else {
          print('⚠️ DOCUMENTO DE USUARIO NO EXISTE O COMPONENT NO ESTÁ MONTADO');
        }
      } else {
        print('⚠️ USUARIO NO AUTENTICADO');
      }
    } catch (e) {
      print('❌ ERROR AL CARGAR DATOS DEL USUARIO: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Obtener el teléfono con trim para eliminar espacios
        final phoneNumber = _phoneController.text.trim();
        
        // Depuración más detallada
        print('🔄 GUARDANDO PERFIL:');
        print('- Usuario ID: ${user.uid}');
        print('- Nombre: ${_nameController.text.trim()}');
        print('- Apellido: ${_surnameController.text.trim()}');
        print('- Teléfono: "$phoneNumber"');
        
        // Crear el mapa de datos a actualizar
        final Map<String, dynamic> updatedData = {
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'displayName': '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        };
        
        // Añadir el teléfono solo si no está vacío
        // Esto es importante: añadir explícitamente el teléfono aunque sea vacío
        updatedData['phone'] = phoneNumber;
        
        // Guardar código ISO y código de marcación
        if (phoneNumber.isNotEmpty) {
          updatedData['isoCountryCode'] = _isoCountryCode; // GUARDAR ISO CODE
          updatedData['phoneComplete'] = _phoneCompleteNumber;
          updatedData['phoneCountryCode'] = _phoneCountryCode;
        } else {
          // Si no hay número, limpiar los campos relacionados
          updatedData['isoCountryCode'] = '';
          updatedData['phoneComplete'] = '';
          updatedData['phoneCountryCode'] = '';
        }
        
        // Intentar la actualización como operación separada
        print('💾 Enviando actualización a Firestore...');
        
        // Usar set con merge para asegurar que el campo se actualice
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updatedData, SetOptions(merge: true));
        
        // Verificar que se guardó correctamente con una nueva consulta
        final verificacionDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final datoVerificado = verificacionDoc.data()?['phone'] as String? ?? 'no encontrado';
        print('✅ Verificación después de guardar:');
        print('- Teléfono en DB: "$datoVerificado"');
        
        if (datoVerificado != phoneNumber) {
          print('⚠️ ADVERTENCIA: El teléfono guardado no coincide con el enviado');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ ERROR AL GUARDAR PERFIL: $e');
      print('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
    setState(() => _isLoading = false);
  }

  // Verificar si el usuario actual es un pastor
  Future<void> _checkPastorStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      // Asegurarse de que el widget esté montado antes de llamar a setState
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isPastor = userData['role'] == 'pastor';
          print('✅ Rol de Pastor verificado: $_isPastor'); // Log
        });
      } else if (mounted) {
         setState(() {
           _isPastor = false; // Asegurarse de que es false si no se encuentra o no es pastor
         });
         print('ℹ️ Usuario no es pastor o documento no existe.');
      }
    }
  }

  // Método simple para guardar solo información personal
  Future<void> _guardarInformacionPersonal() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Mostrar indicador de carga
      setState(() => _isLoading = true);
      
      // Log inicial
      print('🔄 INICIANDO GUARDADO DE INFORMACIÓN PERSONAL');
      
      // Obtener el número de teléfono limpio (sin espacios)
      final String phoneNumber = _phoneController.text.trim();
      
      // Si no tenemos un número completo pero sí un número simple, construirlo
      if (phoneNumber.isNotEmpty && (_phoneCompleteNumber.isEmpty || !_phoneCompleteNumber.contains(phoneNumber))) {
        _phoneCompleteNumber = '$_phoneCountryCode$phoneNumber';
        print('🔧 Reconstruyendo número completo: $_phoneCompleteNumber');
      }
      
      // Log detallado
      print('📱 GUARDANDO TELÉFONO:');
      print('- Número simple: "$phoneNumber"');
      print('- Número completo: "$_phoneCompleteNumber"');
      print('- Código de país: "$_phoneCountryCode"');
      
      // Preparar datos para guardar
      final Map<String, dynamic> datos = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'displayName': '${_nameController.text.trim()} ${_surnameController.text.trim()}',
      };
      
      // Siempre guardar el teléfono, incluso si está vacío, para sobrescribir valores anteriores
      datos['phone'] = phoneNumber;
      
      // Guardar código ISO y código de marcación
      if (phoneNumber.isNotEmpty) {
        datos['isoCountryCode'] = _isoCountryCode; // GUARDAR ISO CODE
        datos['phoneComplete'] = _phoneCompleteNumber;
        datos['phoneCountryCode'] = _phoneCountryCode;
      } else {
        // Si no hay número, limpiar los campos relacionados
        datos['isoCountryCode'] = '';
        datos['phoneComplete'] = '';
        datos['phoneCountryCode'] = '';
      }
      
      print('📤 DATOS A GUARDAR:');
      datos.forEach((key, value) {
        print('- $key: "$value"');
      });
      
      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(datos);
      
      // Verificar que se guardó correctamente
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final userData = docSnap.data();
        if (userData != null) {
          print('✅ VERIFICACIÓN DESPUÉS DE GUARDAR:');
          print('- phone: "${userData['phone']}"');
          print('- phoneComplete: "${userData['phoneComplete']}"');
          print('- phoneCountryCode: "${userData['phoneCountryCode']}"');
          
          // Verificar si coincide con lo que intentamos guardar
          if (userData['phone'] != phoneNumber) {
            print('⚠️ ERROR: El teléfono guardado no coincide con el enviado');
          } else {
            print('✅ ÉXITO: Teléfono guardado correctamente');
          }
        }
      }
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información personal actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ ERROR AL GUARDAR INFORMACIÓN PERSONAL: $e');
      print('Stack trace: ${StackTrace.current}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
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
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          // Añadir comprobación robusta para snapshot y sus datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            // Mostrar un estado de error o carga si no hay datos válidos
            // Esto evita el error de null check
            print("❌ PROFILE_SCREEN - Error: No se encontraron datos válidos para el usuario.");
            // Podrías mostrar un mensaje de error más amigable aquí
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 16),
                    const Text(
                      "No se pudieron cargar los datos del perfil.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    // Botón de Cerrar Sesión añadido aquí
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Color naranja
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        // Llamar al método de logout del AuthService
                        // Asegúrate de que AuthService esté disponible vía Provider
                        try {
                          Provider.of<AuthService>(context, listen: false).forceSignOut();
                          // Navegar a la pantalla de login después de logout (opcional pero recomendado)
                          // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        } catch (e) {
                          print("Error al cerrar sesión: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error al cerrar sesión: $e"))
                          );
                        }
                      },
                    ),
                    // Puedes descomentar el botón de reintentar si quieres
                    // const SizedBox(height: 10),
                    // TextButton(onPressed: _loadUserData, child: Text("Reintentar")),
                  ],
                ),
              ),
            );
          }

          // Si llegamos aquí, snapshot.data y snapshot.data!.data() son seguros de usar
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sección de cabecera con imagen de perfil
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Stack(
            children: [
              CircularImagePicker(
                documentId: FirebaseAuth.instance.currentUser!.uid,
                currentImageUrl: userData['photoUrl'] as String? ?? '',
                storagePath: 'user_images',
                collectionName: 'users',
                fieldName: 'photoUrl',
                defaultIcon: const Icon(Icons.person, size: 60, color: Colors.white),
                size: 100,
                isEditable: true,
              ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // Simular el clic en la imagen principal
                                final imagePicker = ImagePicker();
                                imagePicker.pickImage(source: ImageSource.gallery);
                              },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData['displayName'] ?? 'Completa tu perfil',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userData['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sección de información personal - NUEVO DISEÑO
                Container(
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
                      // Header con estilo
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
                            // Título con icono
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
                                const Text(
                                  'Informação Pessoal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Botón de guardar en su propia línea
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save, size: 14, color: Colors.white),
                                label: const Text(
                                  'Salvar',
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
                                onPressed: _guardarInformacionPersonal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Contenido
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Campo de nombre
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nome',
                                labelStyle: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Container(
                                  margin: const EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: const Color(0xFF2196F3).withOpacity(0.7),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo de apellido
                            TextFormField(
                              controller: _surnameController,
                              decoration: InputDecoration(
                                labelText: 'Sobrenome',
                                labelStyle: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Container(
                                  margin: const EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: const Color(0xFF2196F3).withOpacity(0.7),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu sobrenome';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo de teléfono
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Si hay un teléfono guardado, mostrarlo como texto informativo
                                if (_phoneCompleteNumber.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                                    child: Text(
                                      'Número atual: $_phoneCompleteNumber',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                IntlPhoneField(
                                  initialCountryCode: _isoCountryCode, // Usar código ISO directamente
                                  decoration: InputDecoration(
                                    labelText: 'Telefone',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    hintText: _phoneController.text.isEmpty ? 'Opcional' : null,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  // Establecer el valor inicial del teléfono
                                  initialValue: _phoneController.text,
                                  onChanged: (phone) {
                                    setState(() {
                                      // Guardar el número sin espacios ni caracteres especiales
                                      final cleanNumber = phone.number.replaceAll(RegExp(r'\s+'), '');
                                      _phoneCountryCode = phone.countryCode;
                                      _phoneCompleteNumber = phone.completeNumber;
                                      _isValidPhone = cleanNumber.length >= 10;
                                      
                                      // Solo actualizar el controller si el número ha cambiado
                                      // para evitar ciclos de actualización
                                      if (_phoneController.text != cleanNumber) {
                                        _phoneController.text = cleanNumber;
                                      }
                                      
                                      // Depuración detallada
                                      print('📱 TELÉFONO ACTUALIZADO (onChanged):');
                                      print('- Número: $cleanNumber');
                                      print('- Completo: ${phone.completeNumber}');
                                      print('- País: ${phone.countryCode}');
                                    });
                                  },
                                  onSaved: (phone) {
                                    if (phone != null) {
                                      // Este evento ocurre cuando se guarda el formulario
                                      final cleanNumber = phone.number.replaceAll(RegExp(r'\s+'), '');
                                      _phoneController.text = cleanNumber;
                                      _phoneCompleteNumber = phone.completeNumber;
                                      _phoneCountryCode = phone.countryCode;
                                      
                                      print('📱 TELÉFONO GUARDADO (onSaved):');
                                      print('- Número: $cleanNumber');
                                      print('- Completo: ${phone.completeNumber}');
                                    }
                                  },
                                  validator: (phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return null; // Es opcional
                                    }
                                    if (phone.number.length < 8) {
                                      return 'Telefone inválido';
                                    }
                                    return null;
                                  },
                                  // Asegurar que el teléfono se guarde correctamente incluso cuando solo se cambia el código de país
                                  onCountryChanged: (country) {
                                    setState(() {
                                      _isoCountryCode = country.code; // Actualizar código ISO
                                      _phoneCountryCode = '+${country.dialCode}'; // Actualizar código de marcación
                                      if (_phoneController.text.isNotEmpty) {
                                        _phoneCompleteNumber = '$_phoneCountryCode${_phoneController.text}';
                                      }
                                      
                                      // Depuración
                                      print('📱 PAÍS CAMBIADO:');
                                      print('- Código ISO: $_isoCountryCode');
                                      print('- Código Marcación: $_phoneCountryCode');
                                      print('- Completo actualizado: $_phoneCompleteNumber');
                                    });
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
                
                const SizedBox(height: 24),
                
                // Sección de información adicional - NUEVO DISEÑO
                StreamBuilder<List<ProfileFieldResponse>>(
                  stream: _profileFieldsService.getUserResponses(
                    FirebaseAuth.instance.currentUser!.uid,
                  ),
                  builder: (context, responsesSnapshot) {
                    if (responsesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final responses = responsesSnapshot.data ?? [];

                    return StreamBuilder<List<ProfileField>>(
                      stream: _profileFieldsService.getActiveProfileFields(),
                      builder: (context, fieldsSnapshot) {
                        if (fieldsSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final fields = fieldsSnapshot.data ?? [];

                        if (fields.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        // Crear un map para almacenar controladores y valores para cada campo
                        final Map<String, TextEditingController> controllers = {};
                        final Map<String, dynamic> fieldValues = {};
                        
                        // Inicializar controladores con valores existentes
                        for (var field in fields) {
                          final response = responses.firstWhere(
                            (r) => r.fieldId == field.id,
                            orElse: () => ProfileFieldResponse(
                              id: '',
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              fieldId: field.id,
                              value: '',
                              updatedAt: DateTime.now(),
                            ),
                          );
                          
                          String initialValue = '';
                          if (response.value != null && response.value != '') {
                            if (field.type == 'date' && response.value is DateTime) {
                              initialValue = '${response.value.day}/${response.value.month}/${response.value.year}';
                            } else {
                              initialValue = response.value.toString();
                            }
                          }
                          
                          controllers[field.id] = TextEditingController(text: initialValue);
                          fieldValues[field.id] = response.value;
                        }

                        return Container(
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
                              // Header con estilo
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9C27B0).withOpacity(0.08),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Título con icono
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF9C27B0).withOpacity(0.2),
                                                spreadRadius: 1,
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.assignment_outlined,
                                            color: Color(0xFF9C27B0),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Informação Adicional',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF9C27B0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Botón de guardar en su propia línea
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.save, size: 14, color: Colors.white),
                                        label: const Text(
                                          'Salvar',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF9C27B0),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          elevation: 0,
                                          minimumSize: const Size(85, 32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () => _guardarInformacionAdicional(fields, controllers, fieldValues),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Contenido
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: fields.isEmpty
                                  ? Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Não há informações adicionais para preencher',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...fields.map((field) {
                                          // Construir un widget de entrada para cada campo con estilo mejorado
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: _buildFieldInput(
                                              field, 
                                              controllers[field.id]!,
                                              fieldValues,
                                              responses.firstWhere(
                                                (r) => r.fieldId == field.id,
                                                orElse: () => ProfileFieldResponse(
                                                  id: '',
                                                  userId: FirebaseAuth.instance.currentUser!.uid,
                                                  fieldId: field.id,
                                                  value: '',
                                                  updatedAt: DateTime.now(),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 24),

                // Sección de Ministerios y Grupos - NUEVO DISEÑO
                Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con estilo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'Participação',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Sección de ministerios
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título de Ministerios con badge informativo
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE57373),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.work_outline,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Ministérios',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Lista de ministerios
                            FutureBuilder<bool>(
                              future: _checkIfUserBelongsToAnyMinistry(),
                              builder: (context, ministrySnapshot) {
                                if (ministrySnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFE57373),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                
                                if (ministrySnapshot.hasError) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade700),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Erro ao carregar ministérios',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Si pertenece a algún ministerio
                                if (ministrySnapshot.hasData && ministrySnapshot.data == true) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Tarjeta de servicios
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFF9F9FC), Color(0xFFF3E5F5)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () {
                                              Navigator.pushNamed(context, '/work-services');
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(18),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFFE57373).withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.workspace_premium,
                                                        color: Color(0xFFE57373),
                                                        size: 26,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Minhas Escalas',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFFD32F2F),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Gerenciar suas atribuições e convites de trabalho nos ministérios',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey.shade700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: Color(0xFFE57373),
                                                      size: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Botón para unirse a otro ministerio
                                      Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE57373).withOpacity(0.3)),
                                          gradient: LinearGradient(
                                            colors: [Colors.white, const Color(0xFFFFF8F8)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () {
                                              Navigator.pushNamed(context, '/ministries');
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.add_circle,
                                                    color: Color(0xFFE57373),
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      'Juntar-se a outro Ministério',
                                                      style: TextStyle(
                                                        color: Color(0xFFE57373),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Si NO pertenece a ningún ministerio
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.work_outline,
                                              color: Colors.grey.shade400,
                                              size: 35,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Você não pertence a nenhum ministério',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Junte-se a um ministério para participar do serviço na igreja',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFE57373),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/ministries');
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'Juntar-se a um Ministério',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
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
                              },
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Título de Grupos con badge informativo
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.group,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Grupos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Consultar pertenencia a grupos
                            FutureBuilder<bool>(
                              future: _checkIfUserBelongsToAnyGroup(),
                              builder: (context, groupSnapshot) {
                                if (groupSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                
                                if (groupSnapshot.hasError) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade700),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Erro ao carregar grupos',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Si pertenece a algún grupo
                                if (groupSnapshot.hasData && groupSnapshot.data == true) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // --- INICIO MODIFICACIÓN ---
                                      // Eliminar el FutureBuilder que mostraba la lista de grupos
                                      // const SizedBox.shrink(), // Ya no es necesario si eliminamos el FutureBuilder
                                      // --- FIN MODIFICACIÓN ---
                                      
                                      /* Código Original Eliminado:
                                      FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance.collection('groups').get(),
                                        builder: (context, gruposSnapshot) {
                                          if (gruposSnapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(vertical: 20),
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFF4CAF50),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          
                                          if (gruposSnapshot.hasError) {
                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      'Erro ao carregar grupos',
                                                      style: TextStyle(
                                                        color: Colors.red.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          
                                          final userId = FirebaseAuth.instance.currentUser?.uid;
                                          if (userId == null) return const SizedBox();
                                          
                                          final userPath = '/users/$userId';
                                          final gruposDelUsuario = gruposSnapshot.data!.docs.where((doc) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            if (!data.containsKey('members') || !(data['members'] is List)) return false;
                                            
                                            final List<dynamic> members = data['members'];
                                            
                                            // Verificar todas las posibles formas en que un usuario puede estar en la lista
                                            return members.any((m) => 
                                              m.toString() == userPath || // Ruta completa
                                              m.toString() == userId || // Solo ID
                                              (m is DocumentReference && m.id == userId) // DocumentReference
                                            );
                                          }).toList();
                                          
                                          // Log para depuración
                                          debugPrint('📊 GRUPOS-UI: Encontrados ${gruposDelUsuario.length} grupos para el usuario');
                                          
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // Lista de grupos del usuario con nuevo diseño
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFF9F9FC), Color(0xFFE8F5E9)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: gruposDelUsuario.isEmpty
                                                    ? Padding(
                                                        padding: const EdgeInsets.all(20),
                                                        child: Center(
                                                          child: Column(
                                                            children: [
                                                              Icon(
                                                                Icons.info_outline,
                                                                size: 24,
                                                                color: Colors.grey[400],
                                                              ),
                                                              const SizedBox(height: 8),
                                                              Text(
                                                                'Você não pertence a nenhum grupo',
                                                                style: TextStyle(
                                                                  color: Colors.grey[600],
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    : ListView.separated(
                                                        shrinkWrap: true,
                                                        physics: const NeverScrollableScrollPhysics(),
                                                        itemCount: gruposDelUsuario.length,
                                                        separatorBuilder: (context, index) => Divider(
                                                          height: 1,
                                                          thickness: 1,
                                                          color: Colors.green.shade50,
                                                          indent: 70,
                                                          endIndent: 16,
                                                        ),
                                                        itemBuilder: (context, index) {
                                                          final doc = gruposDelUsuario[index];
                                                          final data = doc.data() as Map<String, dynamic>;
                                                          final name = data['name'] as String? ?? 'Grupo sem nome';
                                                          
                                                          return Material(
                                                            color: Colors.transparent,
                                                            child: InkWell(
                                                              onTap: () {
                                                                Navigator.pushNamed(
                                                                  context,
                                                                  '/groups/${doc.id}',
                                                                );
                                                              },
                                                              child: Padding(
                                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      width: 45,
                                                                      height: 45,
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        shape: BoxShape.circle,
                                                                        boxShadow: [
                                                                          BoxShadow(
                                                                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                                                                            blurRadius: 8,
                                                                            offset: const Offset(0, 3),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      child: const Center(
                                                                        child: Icon(
                                                                          Icons.group_rounded,
                                                                          color: Color(0xFF4CAF50),
                                                                          size: 24,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 16),
                                                                    Expanded(
                                                                      child: Text(
                                                                        name,
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.w600,
                                                                          fontSize: 16,
                                                                          color: Color(0xFF2E7D32),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      padding: const EdgeInsets.all(8),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.white,
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons.arrow_forward_ios,
                                                                        color: Color(0xFF4CAF50),
                                                                        size: 16,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                ),
                                              ),
                                
                                              const SizedBox(height: 16),
                                              
                                              // Botón para unirse a otro grupo - nuevo diseño
                                              Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                                                  gradient: LinearGradient(
                                                    colors: [Colors.white, const Color(0xFFF1F8E9)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(12),
                                                    onTap: () {
                                                      Navigator.pushNamed(context, '/groups');
                                                    },
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.add_circle,
                                                            color: Color(0xFF4CAF50),
                                                            size: 20,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Flexible(
                                                            child: Text(
                                                              'Juntar-se a outro Grupo',
                                                              style: TextStyle(
                                                                color: Color(0xFF4CAF50),
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 15,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      */
                                      
                                      // Mantener el botón "Juntar-se a outro Grupo"
                                      const SizedBox(height: 16), // Espacio antes del botón
                                      Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                                          gradient: LinearGradient(
                                            colors: [Colors.white, const Color(0xFFF1F8E9)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () {
                                              Navigator.pushNamed(context, '/groups');
                                            },
                                            child: Center(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.add_circle,
                                                    color: Color(0xFF4CAF50),
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      'Juntar-se a outro Grupo',
                                                      style: TextStyle(
                                                        color: Color(0xFF4CAF50),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Si NO pertenece a ningún grupo - nuevo diseño
                                  return Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.group,
                                              color: Colors.grey.shade400,
                                              size: 35,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Você não pertence a nenhum grupo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Junte-se a um grupo para participar da vida comunitária',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4CAF50),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/groups');
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'Juntar-se a um Grupo',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
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
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // --- NUEVA SECCIÓN DE ADMINISTRACIÓN (Solo para Pastores) ---
                if (_isPastor) ...[
                  const SizedBox(height: 24),
                  Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header de la sección admin (Estilo unificado)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08), // Color base para admin
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: AppColors.primary, 
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                    'Administração',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                                  color: AppColors.primary, 
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- Lista de Opciones Administrativas --- 
                        
                        // 1. Gerenciar Tela Inicial (Nueva Opción)
                        _buildAdminListTile(
                          icon: Icons.view_quilt_outlined,
                          title: 'Gerenciar Tela Inicial',
                      onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManageHomeSectionsScreen()),
                            );
                          },
                        ),
                        
                        // 2. Gerenciar Páginas (Contenido)
                        _buildAdminListTile(
                          icon: Icons.edit_document, 
                          title: 'Gerenciar Páginas',
                          subtitle: 'Criar e editar conteúdo informativo',
                          onTap: () => Navigator.pushNamed(context, '/admin/manage-pages'), // <-- Usar pushNamed como antes
                        ),
                        
                        // 3. Gerenciar Disponibilidade
                         _buildAdminListTile(
                          icon: Icons.event_available, 
                          title: 'Gerenciar Disponibilidade',
                          subtitle: 'Configure seus horários para aconselhamento',
                          onTap: () => Navigator.pushNamed(context, '/counseling/pastor-availability'), // <-- Usar pushNamed como antes
                        ),

                        // 4. Gerenciar Campos de Perfil (Descomentado y Corregido)
                        _buildAdminListTile(
                          icon: Icons.list_alt,
                          title: 'Gerenciar Campos de Perfil',
                          subtitle: 'Configure os campos adicionais para os usuários',
                      onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const ProfileFieldsAdminScreen()), // <-- Nombre de clase corregido
                             );
                           },
                        ),
                        
                        // 5. Gerenciar Papéis
                        _buildAdminListTile(
                           icon: Icons.admin_panel_settings,
                           title: 'Gerenciar Papéis',
                           subtitle: 'Atribua papéis de pastor a outros usuários',
                      onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UserRoleManagementScreen()), // <-- Correcto con push(MaterialPageRoute...)
                            );
                           },
                         ),
                         
                        // 6. Gerenciar Anúncios
                        _buildAdminListTile(
                          icon: Icons.campaign, 
                          title: 'Gerenciar Anúncios',
                          subtitle: 'Crie e edite anúncios para a igreja',
                          onTap: () => _showCreateAnnouncementModal(context), // <-- Correcto con Modal
                        ),
                        
                        // 7. Gerenciar Vídeos (Restaurado con pushNamed)
                         _buildAdminListTile(
                           icon: Icons.video_library, 
                           title: 'Gerenciar Vídeos',
                           subtitle: 'Administre as seções e vídeos da igreja',
                           onTap: () => Navigator.pushNamed(context, '/videos/manage'), // <-- Navegación corregida
                         ),

                         _buildAdminListTile(
                           icon: Icons.volunteer_activism,
                           title: 'Gerenciar Doações',
                           subtitle: 'Configure a seção e formas de doação',
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const ManageDonationsScreen()),
                             );
                           },
                         ), 

                        // Añadir la gestión de transmisiones en vivo aquí
                        _buildAdminListTile(
                           icon: Icons.live_tv_outlined,
                           title: 'Gerenciar Transmissões Ao Vivo',
                           subtitle: 'Criar, editar e controlar transmissões',
                           onTap: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ManageLiveStreamConfigScreen()), // Navegación actualizada
                              );
                           },
                         ),

                        // 8. Administrar Cultos (Restaurado con pushNamed)
                         _buildAdminListTile(
                           icon: Icons.church,
                           title: 'Administrar Cultos',
                           subtitle: 'Gerenciar cultos, ministérios e canções',
                           onTap: () => Navigator.pushNamed(context, '/cults'), // <-- Navegación corregida
                         ),
                      
                         
                        // 10. Criar Ministério
                        _buildAdminListTile(
                          icon: Icons.add_business_outlined, 
                          title: 'Criar Ministério',
                          onTap: () => _showCreateMinistryModal(context), // <-- Correcto con Modal
                        ),
                        
                        // 11. Criar Grupo
                        _buildAdminListTile(
                          icon: Icons.group_add_outlined, 
                          title: 'Criar Grupo',
                          onTap: () => _showCreateGroupModal(context), // <-- Correcto con Modal
                        ),
                        
                        // 12. Solicitações de Aconselhamento
                        _buildAdminListTile(
                           icon: Icons.support_agent, 
                           title: 'Solicitações de Aconselhamento',
                           subtitle: 'Gerencie as solicitações dos membros',
                           onTap: () => Navigator.pushNamed(context, '/counseling/pastor-requests'), // <-- Usar pushNamed como antes
                         ),
                         
                        // 13. Orações Privadas (Restaurado con pushNamed)
                         _buildAdminListTile(
                            icon: Icons.favorite_outline, 
                            title: 'Orações Privadas',
                            subtitle: 'Gerencie as solicitações de oração privada',
                            onTap: () => Navigator.pushNamed(context, '/prayers/pastor-private-requests'), // <-- Navegación corregida
                          ),
                         
                        // 14. Enviar Notificação Push
                        _buildAdminListTile(
                           icon: Icons.notifications_active_outlined,
                           title: 'Enviar Notificação Push',
                           subtitle: 'Envie mensagens aos membros da igreja',
                          onTap: () {
                            Navigator.push(
                              context,
                               MaterialPageRoute(builder: (context) => const PushNotificationScreen()), // <-- Correcto con push(MaterialPageRoute...)
                            );
                          },
                        ),
                
                        // --- Subsección: Estadísticas y Asistencia ---
                FutureBuilder<bool>(
                  future: _isUserLeader(),
                  builder: (context, leaderSnapshot) {
                             if (!leaderSnapshot.hasData || leaderSnapshot.data != true) {
                               return const SizedBox.shrink();
                    }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
                                Padding(
                                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                                  child: Text('Relatórios e Assistência', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                
                                // 15. Gerenciar Assistência a Eventos (Descomentado - Ajustar navegación si es necesario)
                                 _buildAdminListTile(
                                   icon: Icons.event_available, 
                                   title: 'Gerenciar Assistência a Eventos',
                                   subtitle: 'Verificar assistência e gerar relatórios',
                                   onTap: () => Navigator.pushNamed(context, '/admin/events'), // Mantengo pushNamed aquí, verifica si existe
                                 ),
                                
                                // 16. Estatísticas de Ministérios
                                _buildAdminListTile(
                                  icon: Icons.bar_chart_outlined,
                                  title: 'Estatísticas de Ministérios',
                                  subtitle: 'Análise de participação e membros',
                              onTap: () {
                                Navigator.push(
                                  context,
                                      MaterialPageRoute(builder: (context) => const MinistryMembersStatsScreen()), // <-- Correcto
                                    );
                                  },
                                ),

                                // 17. Estatísticas de Grupos
                                _buildAdminListTile(
                                  icon: Icons.pie_chart_outline, 
                                  title: 'Estatísticas de Grupos',
                                  subtitle: 'Análise de participação e membros',
                              onTap: () {
                                Navigator.push(
                                  context,
                                      MaterialPageRoute(builder: (context) => const GroupMembersStatsScreen()), // <-- Correcto
                                    );
                                  },
                                ),

                                // 18. Estatísticas de Serviços/Escalas
                                _buildAdminListTile(
                                  icon: Icons.assessment_outlined, // Icono alternativo 
                                  title: 'Estatísticas de Escalas',
                                  subtitle: 'Análise de participação e convites',
                              onTap: () {
                                Navigator.push(
                                  context,
                                      MaterialPageRoute(builder: (context) => const ServicesStatsScreen()), // <-- Correcto
                                    );
                                  },
                                ),
                                
                                // 19. Informação de Usuários (Restaurado con pushNamed)
                                 _buildAdminListTile(
                                    icon: Icons.supervised_user_circle_outlined,
                                    title: 'Informação de Usuários',
                                    subtitle: 'Consultar detalhes de participação',
                                    onTap: () => Navigator.pushNamed(context, '/admin/user-info'), // <-- Navegación corregida
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                // --- FIN SECCIÓN ADMINISTRACIÓN ---

                // Botón de Cerrar Sesión 
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // Color naranja
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    onPressed: () {
                      try {
                        Provider.of<AuthService>(context, listen: false).forceSignOut();
                      } catch (e) {
                        print("Error al cerrar sesión: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error al cerrar sesión: $e"))
                        );
                      }
                              },
                            ),
                          ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // --- NUEVO: Helper para construir los ListTiles de admin de forma consistente ---
  Widget _buildAdminListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor, // Opcional para mantener colores específicos si se desea
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary), // Usar color primario por defecto
          title: Text(title, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.caption) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
          dense: true,
        ),
        const Divider(height: 1, indent: 70, endIndent: 16), // Ajustar indentación si el icono cambia de tamaño
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Método para mostrar el modal de creación de anuncios
  void _showCreateAnnouncementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAnnouncementModal(),
    );
  }
  
  // Método para mostrar el modal de creación de ministerios
  void _showCreateMinistryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateMinistryModal(),
    );
  }
  
  // Método para mostrar el modal de creación de grupos
  void _showCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupModal(),
    );
  }
  
  
  // Método para verificar si el usuario actual es líder de algún grupo o ministerio
  Future<bool> _isUserLeader() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 Verificando liderazgo para usuario: ${user?.uid}');
    if (user == null) {
      debugPrint('⚠️ Usuario no autenticado');
      return false;
    }
    
    try {
      // Obtener todos los ministerios y verificar manualmente si el usuario es administrador
      debugPrint('🔍 Consultando ministerios directamente...');
      final ministeriosQuery = await FirebaseFirestore.instance
          .collection('ministries')
          .get();
      
      debugPrint('🔍 Total ministerios: ${ministeriosQuery.docs.length}');
      
      // Verificar cada ministerio si contiene al usuario como admin
      for (var doc in ministeriosQuery.docs) {
        debugPrint('Revisando ministerio: ${doc.id}');
        
        // Intentar todas las posibles variantes de nombres de campo para administradores
        final esAdmin = await _checkIfUserIsAdmin(doc.id, 'ministries', user.uid);
        if (esAdmin) {
          debugPrint('✅ Es líder de ministerio: ${doc.id}');
          return true;
        }
      }
      
      // Obtener todos los grupos y verificar manualmente si el usuario es administrador
      debugPrint('🔍 Consultando grupos directamente...');
      final gruposQuery = await FirebaseFirestore.instance
          .collection('groups')
          .get();
      
      debugPrint('📊 Total grupos: ${gruposQuery.docs.length}');
      
      // Verificar cada grupo si contiene al usuario como admin
      for (var doc in gruposQuery.docs) {
        debugPrint('Revisando grupo: ${doc.id}');
        
        // Intentar todas las posibles variantes de nombres de campo para administradores
        final esAdmin = await _checkIfUserIsAdmin(doc.id, 'groups', user.uid);
        if (esAdmin) {
          debugPrint('✅ Es líder de grupo: ${doc.id}');
          return true;
        }
      }
      
      debugPrint('❌ No se encontró al usuario como líder después de revisar todos los grupos y ministerios');
      return false;
    } catch (e) {
      debugPrint('❌❌ Error al verificar liderazgo: $e');
      return false;
    }
  }
  
  // Método para verificar si un usuario es administrador de una entidad
  Future<bool> _checkIfUserIsAdmin(String entityId, String collectionName, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(entityId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      
      // Lista de posibles nombres de campo para los administradores
      final List<String> possibleAdminFields = [
        'adminIds',
        'ministrieAdmin',
        'ministryAdmin',
        'ministriesAdmin',
        'groupAdmin',
        'groupsAdmin',
        'admins',
        'admin'
      ];
      
      // Revisar cada posible nombre de campo
      for (var fieldName in possibleAdminFields) {
        if (data.containsKey(fieldName)) {
          debugPrint('📋 Campo encontrado: $fieldName');
          
          final fieldValue = data[fieldName];
          
          // Si es una lista, verificar si contiene el ID del usuario
          if (fieldValue is List) {
            final adminList = List<dynamic>.from(fieldValue);
            debugPrint('📋 Lista de admins: $adminList');
            
            // Buscar si el usuario está en la lista de administradores
            for (var admin in adminList) {
              String adminId = '';
              
              // Si es una referencia de documento, extraer el ID
              if (admin is DocumentReference) {
                adminId = admin.id;
                debugPrint('🔍 Referencia encontrada con ID: $adminId');
              } else {
                adminId = admin.toString();
              }
              
              if (adminId == userId) {
                debugPrint('✅ Usuario encontrado como administrador!');
                return true;
              }
            }
          }
          // Si es un solo valor, verificar si es igual al ID del usuario
          else if (fieldValue.toString() == userId) {
            debugPrint('✅ Usuario es el único admin');
            return true;
          }
        }
      }
      
      debugPrint('❌ Usuario no encontrado en ningún campo de administrador');
      return false;
    } catch (e) {
      debugPrint('❌ Error al verificar administrador: $e');
      return false;
    }
  }

  // Verificar si el usuario pertenece a algún ministerio
  Future<bool> _checkIfUserBelongsToAnyMinistry() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      // La ruta que debemos buscar en el array members
      final userPath = '/users/$userId';
      debugPrint('🔍 MINISTERIOS-CHECK: Verificando membresía para usuario: $userId');
      debugPrint('🔍 MINISTERIOS-CHECK: Buscando path: "$userPath"');
      
      // Obtener todos los ministerios
      final ministeriosQuery = await FirebaseFirestore.instance
          .collection('ministries')
          .get();
      
      debugPrint('🔍 MINISTERIOS-CHECK: Encontrados ${ministeriosQuery.docs.length} ministerios');
      
      // Revisar cada ministerio
      for (var doc in ministeriosQuery.docs) {
        final data = doc.data();
        debugPrint('🔍 MINISTERIOS-CHECK: Revisando ministerio: ${doc.id}');
        
        // Verificar si existe el campo members
        if (!data.containsKey('members')) {
          debugPrint('❌ MINISTERIOS-CHECK: Ministerio ${doc.id} no tiene campo "members"');
          continue;
        }
        
        // Verificar si es una lista
        if (!(data['members'] is List)) {
          debugPrint('❌ MINISTERIOS-CHECK: Campo "members" no es una lista en ministerio ${doc.id}');
          continue;
        }
        
        // Obtener la lista de miembros
        final List<dynamic> members = data['members'];
        debugPrint('🔍 MINISTERIOS-CHECK: Ministerio ${doc.id} tiene ${members.length} miembros');
        
        // Imprimir los primeros miembros para debug
        if (members.isNotEmpty) {
          final int printCount = members.length > 3 ? 3 : members.length;
          for (int i = 0; i < printCount; i++) {
            debugPrint('🔍 MINISTERIOS-CHECK: Miembro[$i]: ${members[i]} (${members[i].runtimeType})');
          }
        }
        
        // Buscar al usuario
        for (var member in members) {
          final String memberStr = member.toString();
          if (memberStr == userPath) {
            debugPrint('✅ MINISTERIOS-CHECK: Usuario encontrado con path exacto: $memberStr');
            return true;
          }
          
          // Caso especial: si el miembro es solo el ID sin el path
          if (memberStr == userId) {
            debugPrint('✅ MINISTERIOS-CHECK: Usuario encontrado con solo ID: $memberStr');
            return true;
          }
          
          // Caso para DocumentReference
          if (member is DocumentReference && member.id == userId) {
            debugPrint('✅ MINISTERIOS-CHECK: Usuario encontrado como DocumentReference: ${member.path}');
            return true;
          }
        }
      }
      
      debugPrint('❌ MINISTERIOS-CHECK: Usuario NO pertenece a ningún ministerio - RETORNANDO FALSE');
      return false;
    } catch (e) {
      debugPrint('❌ MINISTERIOS-CHECK: Error verificando ministerios: $e');
      return false;
    }
  }

  // Verificar si el usuario pertenece a algún grupo
  Future<bool> _checkIfUserBelongsToAnyGroup() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      // La ruta que debemos buscar en el array members
      final userPath = '/users/$userId';
      debugPrint('🔍 GRUPOS-CHECK: Verificando membresía para: $userPath');
      
      // Obtener todos los grupos
      final gruposQuery = await FirebaseFirestore.instance
          .collection('groups')
          .get();
      
      debugPrint('🔍 GRUPOS-CHECK: Encontrados ${gruposQuery.docs.length} grupos');
      
      if (gruposQuery.docs.isEmpty) {
        debugPrint('⚠️ GRUPOS-CHECK: No hay grupos en la colección');
        return false;
      }
      
      // Revisar cada grupo
      for (var doc in gruposQuery.docs) {
        final data = doc.data();
        debugPrint('🔍 GRUPOS-CHECK: Revisando grupo: ${doc.id}');
        
        // Verificar si existe el campo members y es una lista
        if (!data.containsKey('members')) {
          debugPrint('⚠️ GRUPOS-CHECK: Grupo ${doc.id} no tiene campo "members"');
          continue;
        }
        
        if (!(data['members'] is List)) {
          debugPrint('⚠️ GRUPOS-CHECK: Campo "members" no es una lista en grupo ${doc.id}');
          continue;
        }
        
        final List<dynamic> members = data['members'];
        debugPrint('🔍 GRUPOS-CHECK: Grupo ${doc.id} tiene ${members.length} miembros');
        
        // Imprimir algunos miembros para debug
        if (members.isNotEmpty) {
          final int printCount = members.length > 3 ? 3 : members.length;
          for (int i = 0; i < printCount; i++) {
            debugPrint('🔍 GRUPOS-CHECK: Miembro[$i]: ${members[i]} (${members[i].runtimeType})');
          }
        }
        
        // Verificar si el userPath está en la lista
        for (var member in members) {
          final String memberStr = member.toString();
          if (memberStr == userPath) {
            debugPrint('✅ GRUPOS-CHECK: Usuario encontrado con path exacto: $memberStr');
            return true;
          }
          
          // Caso especial para solo ID
          if (memberStr == userId) {
            debugPrint('✅ GRUPOS-CHECK: Usuario encontrado con solo ID: $memberStr');
            return true;
          }
          
          // Caso para DocumentReference
          if (member is DocumentReference && member.id == userId) {
            debugPrint('✅ GRUPOS-CHECK: Usuario encontrado como DocumentReference: ${member.path}');
            return true;
          }
        }
      }
      
      debugPrint('❌ GRUPOS-CHECK: Usuario NO pertenece a ningún grupo - RETORNANDO FALSE');
      return false;
    } catch (e) {
      debugPrint('❌ GRUPOS-CHECK: Error verificando grupos: $e');
      return false;
    }
  }
  
  // Método para guardar la información adicional
  Future<void> _guardarInformacionAdicional(
    List<ProfileField> fields,
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> fieldValues
  ) async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Recorrer todos los campos y guardar sus valores
      for (var field in fields) {
        final fieldId = field.id;
        var value = fieldValues[fieldId];
        
        // Para campos de texto, usar el valor del controlador
        if (field.type == 'text' || field.type == 'email' || field.type == 'phone') {
          value = controllers[fieldId]!.text;
        }
        
        // No guardar valores vacíos
        if (value is String && value.trim().isEmpty) {
          continue;
        }
        
        // Crear un objeto de respuesta
        final response = ProfileFieldResponse(
          id: '',
          userId: userId,
          fieldId: fieldId,
          value: value,
          updatedAt: DateTime.now(),
        );
        
        // Guardar la respuesta
        await _profileFieldsService.saveUserResponse(response);
      }
      
      // Actualizar el estado de completado del usuario
      final hasCompleted = await _profileFieldsService.hasCompletedRequiredFields(userId);
      
      // Actualizar el documento del usuario
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hasCompletedAdditionalFields': hasCompleted,
        'additionalFieldsLastUpdated': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informação adicional salva com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar información adicional: $e');
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
  
  // Método para construir los widgets de input para cada tipo de campo
  Widget _buildFieldInput(
    ProfileField field,
    TextEditingController controller,
    Map<String, dynamic> fieldValues,
    ProfileFieldResponse response
  ) {
    final Color primaryColor = const Color(0xFF9C27B0); // Color morado para la sección adicional
    
    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            labelStyle: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            helperText: field.description,
            helperStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                _getIconDataForFieldType(field.type),
                color: primaryColor.withOpacity(0.7),
              ),
            ),
            suffixIcon: field.isRequired
                ? Tooltip(
                    message: 'Campo obrigatório',
                    child: Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.red[400],
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          keyboardType: field.type == 'email'
              ? TextInputType.emailAddress
              : field.type == 'phone'
                  ? TextInputType.phone
                  : TextInputType.text,
          onChanged: (value) {
            fieldValues[field.id] = value;
          },
        );
      
      case 'number':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            labelStyle: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            helperText: field.description,
            helperStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.numbers,
                color: primaryColor.withOpacity(0.7),
              ),
            ),
            suffixIcon: field.isRequired
                ? Tooltip(
                    message: 'Campo obrigatório',
                    child: Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.red[400],
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            fieldValues[field.id] = int.tryParse(value) ?? value;
          },
        );
      
      case 'date':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            labelStyle: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            helperText: field.description,
            helperStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.calendar_today,
                color: primaryColor.withOpacity(0.7),
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.calendar_month,
                color: Color(0xFF9C27B0),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryColor,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    controller.text = '${date.day}/${date.month}/${date.year}';
                    fieldValues[field.id] = date;
                  });
                }
              },
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          readOnly: true,
        );
      
      case 'select':
        final options = field.options ?? [];
        return SelectionFormField(
          initialValue: response.value as String?,
          label: field.name,
          hint: 'Seleccione una opción',
          options: options,
          isRequired: field.isRequired,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.list_alt,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          backgroundColor: Colors.grey[50]!,
          borderRadius: 10,
          onChanged: (value) {
            setState(() {
              fieldValues[field.id] = value;
              controller.text = value ?? '';
            });
          },
          validator: field.isRequired 
              ? (value) => value == null || value.isEmpty 
                  ? 'Este campo es requerido' 
                  : null
              : null,
        );
      
      default:
        return const Text('Tipo de campo não suportado');
    }
  }

  // Método para obtener el ícono específico para cada tipo de campo
  IconData _getIconDataForFieldType(String type) {
    switch (type) {
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'date':
        return Icons.calendar_today;
      case 'select':
        return Icons.list;
      case 'number':
        return Icons.numbers;
      case 'text':
      default:
        return Icons.text_fields;
    }
  }

  // Función auxiliar para obtener ISO code desde dial code
  String _getIsoCodeFromDialCode(String? dialCode) {
    // Mapeo de códigos de marcación a códigos ISO 2
    final Map<String, String> dialCodeToIso = {
      '+1': 'US',  // Estados Unidos / Canadá
      '+44': 'GB', // Reino Unido
      '+351': 'PT', // Portugal
      '+34': 'ES', // España
      '+49': 'DE', // Alemania
      '+33': 'FR', // Francia
      '+39': 'IT', // Italia
      '+54': 'AR', // Argentina
      '+57': 'CO', // Colombia
      '+52': 'MX', // México
      '+55': 'BR', // Brasil
      '+81': 'JP', // Japón
      '+86': 'CN', // China
      '+91': 'IN', // India
      // Añadir más mapeos según sea necesario
    };

    // Buscar el código ISO correspondiente
    if (dialCode != null && dialCodeToIso.containsKey(dialCode)) {
      return dialCodeToIso[dialCode]!;
    }
    
    // Devolver 'BR' como default si no se encuentra o es nulo
    return 'BR';
  }
} 