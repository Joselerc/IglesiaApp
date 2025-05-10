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
import 'admin/create_edit_role_screen.dart'; // <-- Import añadido
import 'admin/manage_roles_screen.dart'; // <-- Añadir este import
import 'package:church_app_br/services/permission_service.dart'; // <-- Import PermissionService
import '../services/role_service.dart'; // <-- Import correcto del servicio de roles
import 'admin/delete_ministries_screen.dart';
import 'admin/delete_groups_screen.dart';
import 'admin/kids_admin_screen.dart'; // <-- AÑADIR IMPORT PARA LA NUEVA PANTALLA


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
  final PermissionService _permissionService = PermissionService(); // <-- Instancia del servicio
  final RoleService _roleService = RoleService(); // <-- Instancia del servicio
  
  // Variables para controlar si se muestran las opciones administrativas
  bool _hasAdminAccess = false; // Reemplaza a _isPastor
  
  // Variables para el teléfono con código de país
  String _phoneCountryCode = '+55'; // Código de marcación (ej: +55)
  String _phoneCompleteNumber = '';
  bool _isValidPhone = false;
  String _isoCountryCode = 'BR'; // NUEVO: Código ISO (ej: BR)

  // --- NUEVOS CAMPOS PARA PERFIL ---
  DateTime? _birthDate;
  String? _gender;
  // --- FIN NUEVOS CAMPOS ---

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAdminAccess(); // Nuevo método que reemplaza a _checkPastorStatus
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
            
            // Cargar nuevos campos
            _birthDate = (userData['birthDate'] as Timestamp?)?.toDate();
            _gender = userData['gender'] as String?;

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

  // Verificar si el usuario tiene acceso administrativo basado en permisos
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      print('🔍 Verificando acceso administrativo para: ${user.uid}');
      // Comprobar si es SuperAdmin primero
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Si es superusuario, tiene acceso a todo
        if (userData['isSuperUser'] == true) {
        setState(() {
            _hasAdminAccess = true;
            print('✅ SuperUser verificado: Acceso completo otorgado');
          });
          return;
        }
        
        // Si no es superusuario, verificar si tiene roleId
        final String? roleId = userData['roleId'] as String?;
        if (roleId != null && roleId.isNotEmpty) {
          // Buscar el rol para ver sus permisos
          final role = await _roleService.getRoleById(roleId);
          if (role != null && role.permissions.isNotEmpty) {
            // Si tiene al menos un permiso, darle acceso a la sección
         setState(() {
              _hasAdminAccess = true;
              print('✅ Usuario tiene rol con permisos: ${role.name}');
            });
            return;
          }
        }
        
        // Si llegamos aquí, no tiene permiso según el rol, verificar permisos individuales
        setState(() {
          _hasAdminAccess = false;
          print('ℹ️ Usuario no tiene rol con permisos administrativos, verificando permisos individuales...');
        });
        
        // Solo verificamos un permiso para determinar si mostrar la sección
        final hasAnyAdminPermission = await _permissionService.hasPermission('view_user_list');
        if (hasAnyAdminPermission) {
          setState(() {
            _hasAdminAccess = true;
            print('✅ Usuario tiene al menos un permiso administrativo');
          });
          return;
        }
      }
      
      setState(() {
        _hasAdminAccess = false;
        print('ℹ️ Usuario no tiene acceso administrativo');
      });
    } catch (e) {
      print('❌ Error al verificar permisos administrativos: $e');
      if (mounted) {
        setState(() {
          _hasAdminAccess = false;
        });
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
      
      // Guardar nuevos campos
      datos['birthDate'] = _birthDate != null ? Timestamp.fromDate(_birthDate!) : null;
      datos['gender'] = _gender;
      
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Sección de cabecera con imagen de perfil
                  Container( // <<< Este es el contenedor azul claro
                    // Añadir width: double.infinity
                    width: double.infinity, 
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
                  ), // <<< Fin del contenedor azul claro
                  
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
                              
                              // --- NUEVOS CAMPOS UI ---
                              // Campo de Fecha de Nacimiento
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _birthDate ?? DateTime.now(),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    locale: const Locale('pt', 'BR'),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.primary, // Color primario para el DatePicker
                                            onPrimary: Colors.white, 
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null && picked != _birthDate) {
                                    setState(() {
                                      _birthDate = picked;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Nascimento',
                                    labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.only(left: 12, right: 8),
                                      child: Icon(Icons.calendar_today_outlined, color: const Color(0xFF2196F3).withOpacity(0.7)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0), // Ajuste de padding
                                  ),
                                  child: Padding( // Padding interno para el texto
                                    padding: const EdgeInsets.only(left: 12.0), // Alinea con el texto de otros campos
                                    child: Text(
                                      _birthDate != null 
                                          ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}' 
                                          : 'Selecionar data',
                                      style: _birthDate != null 
                                          ? AppTextStyles.bodyText1.copyWith(color: Colors.black87)
                                          : AppTextStyles.bodyText1.copyWith(color: Colors.grey[700]),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Campo de Sexo
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Sexo',
                                  labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.only(left: 12, right: 8),
                                    child: Icon(Icons.person_outline, color: const Color(0xFF2196F3).withOpacity(0.7)), // Icono ejemplo
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Reducir padding vertical
                                ),
                                value: _gender,
                                isExpanded: true,
                                items: ['Masculino', 'Feminino', 'Prefiro não dizer']
                                    .map((label) => DropdownMenuItem(
                                          child: Padding( // Padding para los items del dropdown
                                            padding: const EdgeInsets.only(left: 12.0),
                                            child: Text(label),
                                          ), 
                                          value: label,
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                                // validator: (value) => (value == null) ? 'Sexo é obrigatório.' : null, // Opcional, si lo quieres obligatorio
                                selectedItemBuilder: (BuildContext context) { // Para alinear el texto seleccionado
                                  return ['Masculino', 'Feminino', 'Prefiro não dizer'].map<Widget>((String item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Text(
                                        item,
                                        style: AppTextStyles.bodyText1.copyWith(color: Colors.black87),
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              const SizedBox(height: 16),
                              // --- FIN NUEVOS CAMPOS UI ---
                              
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
                  
                  // --- NUEVA SECCIÓN DE ADMINISTRACIÓN (Basada en permisos) ---
                  if (_hasAdminAccess) ...[
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
                          
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_donations_config',
                            icon: Icons.volunteer_activism, 
                            title: 'Gerenciar Doações',
                            subtitle: 'Configure a seção e formas de doação',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDonationsScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_livestream_config',
                            icon: Icons.live_tv_outlined,
                            title: 'Gerenciar Transmissões Ao Vivo',
                            subtitle: 'Criar, editar e controlar transmissões',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageLiveStreamConfigScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_courses',
                            icon: Icons.school, 
                            title: 'Gerenciar Cursos Online',
                            subtitle: 'Criar, editar e configurar cursos',
                            onTap: () => Navigator.pushNamed(context, '/admin/courses'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_home_sections',
                            icon: Icons.view_quilt_outlined,
                            title: 'Gerenciar Tela Inicial',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageHomeSectionsScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_pages',
                            icon: Icons.edit_document, 
                            title: 'Gerenciar Páginas',
                            subtitle: 'Criar e editar conteúdo informativo',
                            onTap: () => Navigator.pushNamed(context, '/admin/manage-pages'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_counseling_availability',
                            icon: Icons.event_available, 
                            title: 'Gerenciar Disponibilidade',
                            subtitle: 'Configure seus horários para aconselhamento',
                            onTap: () => Navigator.pushNamed(context, '/counseling/pastor-availability'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_profile_fields',
                            icon: Icons.list_alt,
                            title: 'Gerenciar Campos de Perfil',
                            subtitle: 'Configure os campos adicionais para os usuários',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileFieldsAdminScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'assign_user_roles', // Permiso para pantalla antigua
                            icon: Icons.admin_panel_settings,
                            title: 'Gerenciar Papéis',
                            subtitle: 'Atribua papéis de pastor a outros usuários',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRoleManagementScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_roles', // Permiso para nueva pantalla
                            icon: Icons.assignment_ind_outlined, 
                            title: 'Gerenciar Papéis (New)',
                            subtitle: 'Criar/editar papéis e permissões',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageRolesScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_announcements',
                             icon: Icons.campaign, 
                             title: 'Gerenciar Anúncios',
                             subtitle: 'Crie e edite anúncios para a igreja',
                             onTap: () => _showCreateAnnouncementModal(context),
                           ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_videos',
                             icon: Icons.video_library, 
                             title: 'Gerenciar Vídeos',
                             subtitle: 'Administre as seções e vídeos da igreja',
                             onTap: () => Navigator.pushNamed(context, '/videos/manage'),
                           ),
                          _buildPermissionControlledTile( 
                             permissionKey: 'manage_cults',
                             icon: Icons.church,
                             title: 'Administrar Cultos',
                             subtitle: 'Gerenciar cultos, ministérios e canções',
                             onTap: () => Navigator.pushNamed(context, '/cults'),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'create_ministry',
                             icon: Icons.add_business_outlined, 
                             title: 'Criar Ministério',
                             onTap: () => _showCreateMinistryModal(context),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'create_group',
                             icon: Icons.group_add_outlined, 
                             title: 'Criar Grupo',
                             onTap: () => _showCreateGroupModal(context),
                           ),
                          _buildPermissionControlledTile(
                              permissionKey: 'manage_counseling_requests',
                              icon: Icons.support_agent, 
                              title: 'Solicitações de Aconselhamento',
                              subtitle: 'Gerencie as solicitações dos membros',
                              onTap: () => Navigator.pushNamed(context, '/counseling/pastor-requests'),
                            ),
                          _buildPermissionControlledTile(
                              permissionKey: 'manage_private_prayers',
                              icon: Icons.favorite_outline, 
                              title: 'Orações Privadas',
                              subtitle: 'Gerencie as solicitações de oração privada',
                              onTap: () => Navigator.pushNamed(context, '/prayers/pastor-private-requests'), 
                            ),
                          _buildPermissionControlledTile(
                              permissionKey: 'send_push_notifications',
                              icon: Icons.notifications_active_outlined,
                              title: 'Enviar Notificação Push',
                              subtitle: 'Envie mensagens aos membros da igreja',
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PushNotificationScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'delete_ministry',
                             icon: Icons.delete_outline, 
                             title: 'Eliminar Ministérios',
                             subtitle: 'Remover ministérios existentes',
                             onTap: () => Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (context) => const DeleteMinistriesScreen()
                               )
                             ),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'delete_group',
                             icon: Icons.remove_circle_outline, 
                             title: 'Eliminar Grupos',
                             subtitle: 'Remover grupos existentes',
                             onTap: () => Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (context) => const DeleteGroupsScreen()
                               )
                             ),
                           ),
                  
                          // --- Subsección: Estadísticas y Asistencia --- 
                          // Verificamos primero si el usuario tiene algún permiso de esta sección
                          FutureBuilder<bool>(
                            future: _hasAnyReportPermission(),
                            builder: (context, snapshot) {
                              // No mostrar nada mientras carga o si no tiene permisos
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }
                              
                              // Mostrar la sección solo si tiene al menos un permiso
                              final hasAnyPermission = snapshot.data ?? false;
                              if (!hasAnyPermission) {
                                return const SizedBox.shrink();
                              }
                              
                              // Si tiene permisos, mostrar el encabezado y los elementos
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                           const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
                           Padding(
                             padding: const EdgeInsets.only(left: 20, bottom: 0, top: 8),
                             child: Text('Relatórios e Assistência', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'manage_event_attendance',
                             icon: Icons.event_available, 
                             title: 'Gerenciar Assistência a Eventos',
                             subtitle: 'Verificar assistência e gerar relatórios',
                             onTap: () => Navigator.pushNamed(context, '/admin/events'),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_ministry_stats',
                             icon: Icons.bar_chart_outlined,
                             title: 'Estatísticas de Ministérios',
                             subtitle: 'Análise de participação e membros',
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MinistryMembersStatsScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_group_stats',
                             icon: Icons.pie_chart_outline, 
                             title: 'Estatísticas de Grupos',
                             subtitle: 'Análise de participação e membros',
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupMembersStatsScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_schedule_stats',
                             icon: Icons.assessment_outlined, 
                             title: 'Estatísticas de Escalas',
                             subtitle: 'Análise de participação e convites',
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesStatsScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_course_stats',
                             icon: Icons.analytics_outlined,
                             title: 'Estatísticas de Cursos',
                             subtitle: 'Análise de inscrições e progresso',
                             onTap: () => Navigator.pushNamed(context, '/admin/course-stats'),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_user_details',
                             icon: Icons.supervised_user_circle_outlined,
                             title: 'Informação de Usuários',
                             subtitle: 'Consultar detalhes de participação',
                             onTap: () => Navigator.pushNamed(context, '/admin/user-info'),
                           ),
                        ],
                              );
                            },
                      ),

                          // --- Subsección: Gestão MyKids ---
                          const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, bottom: 0, top: 8),
                            child: Text('Gestão MyKids', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade700)), // Color distintivo para el título
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_family_profiles', // Permiso específico
                            icon: Icons.family_restroom_outlined, 
                            title: 'Perfis Familiares',
                            subtitle: 'Gerenciar perfis de pais e crianças',
                            iconColor: Colors.teal.shade700, // Color del ícono
                            onTap: () {
                              // TODO: Navegar a la pantalla de gestión de perfiles familiares
                              print('Navegar para Perfis Familiares');
                            },
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_checkin_rooms', // Permiso para administrar salas
                            icon: Icons.meeting_room_outlined, 
                            title: 'Gerenciar Salas e Check-in', // Título actualizado para reflejar la pantalla de admin
                            subtitle: 'Administrar salas, check-in/out e assistência',
                            iconColor: Colors.teal.shade700, // Mantener el color del ícono
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const KidsAdminScreen()));
                            },
                          ),
                          // Aquí se pueden añadir más _buildPermissionControlledTile para otras funciones de MyKids

                        ],
                    ),
                    ),
                  ], // <<< Fin del if (_hasAdminAccess)

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
                  
                  // Botón de Diagnóstico (solo para administradores)
                  if (_hasAdminAccess) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.admin_panel_settings, size: 16),
                        label: const Text("Diagnóstico de Permisos", style: TextStyle(fontSize: 14)),
                        onPressed: () => _showPermissionDiagnostics(context),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Contenedor de cambio rápido de usuario ELIMINADO

                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // --- NUEVO: Helper para construir ListTiles controlados por permiso ---
  Widget _buildPermissionControlledTile({
    required String permissionKey,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    // <<< Añadir print para depurar si la función se llama >>>
    print("DEBUG_PROFILE: Intentando construir Tile para permiso: $permissionKey"); 
    
    // El FutureBuilder existente ahora maneja todos los casos
      return FutureBuilder<bool>(
        future: _permissionService.hasPermission(permissionKey),
        builder: (context, snapshot) {
        // No mostrar nada mientras carga (evita parpadeo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); 
          }
        // Si hubo error, tampoco mostrar (podríamos loggear el error)
        if (snapshot.hasError) {
           print("Error al verificar permiso $permissionKey: ${snapshot.error}");
           return const SizedBox.shrink(); 
        }
        // Mostrar el ListTile solo si tiene permiso (o es SuperUser)
          final bool hasPerm = snapshot.data ?? false; 
          if (hasPerm) {
            return _buildAdminListTile(
              icon: icon,
              title: title,
              subtitle: subtitle,
              onTap: onTap,
              iconColor: iconColor,
            );
          } else {
          // Si no tiene permiso, no mostrar nada
            return const SizedBox.shrink();
          }
        },
      );
  }

  // --- Helper original para la apariencia del ListTile ---
  // (Sin cambios)
  Widget _buildAdminListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary), 
          title: Text(title, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.caption) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
          dense: true,
        ),
        const Divider(height: 1, indent: 70, endIndent: 16),
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

  // Método para depuración de permisos
  void _showPermissionDiagnostics(BuildContext context) async {
    try {
      final Map<String, bool> allPermissions = await _permissionService.getAllPermissions();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (!mounted || userId == null) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Diagnóstico de Permisos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Lista de permisos
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Obtener datos del usuario actual
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text('No hay datos de usuario');
                        }
                        
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final roleId = userData['roleId'] as String?;
                        final isSuperUser = userData['isSuperUser'] == true;
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario: ${userData['displayName'] ?? 'Sin nombre'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Email: ${userData['email'] ?? 'Sin email'}'),
                                Text('Role ID: ${roleId ?? 'Sin rol'}'),
                                Text('SuperUser: ${isSuperUser ? 'Sí' : 'No'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Título de la sección
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Permisos Disponibles',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    // Lista de permisos con su estado
                    ...allPermissions.entries.map((entry) {
                      final String permissionKey = entry.key;
                      final bool hasPermission = entry.value;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: hasPermission ? Colors.green.shade50 : Colors.grey.shade100,
                        child: ListTile(
                          title: Text(
                            permissionKey,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(
                            hasPermission ? Icons.check_circle : Icons.cancel,
                            color: hasPermission ? Colors.green : Colors.red.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Sección de diagnóstico de rol
                    FutureBuilder<String?>(
                      future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get()
                            .then((doc) => doc.data()?['roleId'] as String?),
                      builder: (context, roleIdSnapshot) {
                        if (roleIdSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final String? roleId = roleIdSnapshot.data;
                        if (roleId == null || roleId.isEmpty) {
                          return const Card(
                            margin: EdgeInsets.only(top: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No hay información de rol disponible'),
                            ),
                          );
                        }
                        
                        return FutureBuilder<dynamic>(
                          future: _roleService.getRoleById(roleId),
                          builder: (context, roleSnapshot) {
                            if (roleSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final role = roleSnapshot.data;
                            if (role == null) {
                              return Card(
                                margin: const EdgeInsets.only(top: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Rol no encontrado: $roleId'),
                                ),
                              );
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(top: 16),
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rol: ${role.name}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (role.description != null && role.description!.isNotEmpty)
                                      Text('Descripción: ${role.description}'),
                                    const SizedBox(height: 8),
                                    const Text('Permisos del rol:'),
                                    const SizedBox(height: 4),
                                    if (role.permissions.isEmpty)
                                      const Text('Este rol no tiene permisos asignados')
                                    else
                                      ...role.permissions.map((permission) => Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check, size: 16, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Text(permission),
                                          ],
                                        ),
                                      )),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener diagnóstico: $e')),
        );
      }
    }
  }

  // Verificar si el usuario tiene algún permiso relacionado con informes y estadísticas
  Future<bool> _hasAnyReportPermission() async {
    // Lista de permisos relacionados con informes y estadísticas
    final reportPermissions = [
      'manage_event_attendance',
      'view_ministry_stats',
      'view_group_stats',
      'view_schedule_stats',
      'view_user_details'
    ];
    
    // Comprobamos primero si es superusuario
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    
    if (userDoc.exists && userDoc.data()?['isSuperUser'] == true) {
      return true;
    }
    
    // Verificamos cada permiso de la lista
    for (final permission in reportPermissions) {
      if (await _permissionService.hasPermission(permission)) {
        return true;
      }
    }
    
    return false;
  }

  
  // Verifica si el usuario puede eliminar grupos o ministerios
  Future<bool> _canDeleteGroupsOrMinistries() async {
    try {
      // Verificar si es superusuario primero
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()?['isSuperUser'] == true) {
        return true;
      }
      
      // Verificar permisos específicos
      final canDeleteGroups = await _permissionService.hasPermission('delete_group');
      final canDeleteMinistries = await _permissionService.hasPermission('delete_ministry');
      
      return canDeleteGroups || canDeleteMinistries;
    } catch (e) {
      print('Error al verificar permisos de eliminación: $e');
      return false;
    }
  }
  
  // Construye la pestaña para eliminar grupos
  Widget _buildDeleteGroupsTab() {
    return FutureBuilder<bool>(
      future: _permissionService.hasPermission('delete_group'),
      builder: (context, permissionSnapshot) {
        final bool canDeleteGroups = permissionSnapshot.data ?? false;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar grupos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay grupos disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final groups = snapshot.data!.docs;
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final group = groups[index];
                final groupData = group.data() as Map<String, dynamic>;
                final groupName = groupData['name'] as String? ?? 'Grupo sin nombre';
                final groupId = group.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.group, color: Colors.blue),
                  ),
                  title: Text(groupName),
                  subtitle: Text('ID: $groupId'),
                  trailing: canDeleteGroups
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteGroup(groupId, groupName),
                        )
                      : const Icon(Icons.lock, color: Colors.grey),
                );
              },
            );
          },
        );
      },
    );
  }
  
  // Construye la pestaña para eliminar ministerios
  Widget _buildDeleteMinistriesTab() {
    return FutureBuilder<bool>(
      future: _permissionService.hasPermission('delete_ministry'),
      builder: (context, permissionSnapshot) {
        final bool canDeleteMinistries = permissionSnapshot.data ?? false;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ministries').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar ministerios: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay ministerios disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final ministries = snapshot.data!.docs;
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ministries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final ministry = ministries[index];
                final ministryData = ministry.data() as Map<String, dynamic>;
                final ministryName = ministryData['name'] as String? ?? 'Ministerio sin nombre';
                final ministryId = ministry.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    child: const Icon(Icons.work_outline, color: Colors.amber),
                  ),
                  title: Text(ministryName),
                  subtitle: Text('ID: $ministryId'),
                  trailing: canDeleteMinistries
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteMinistry(ministryId, ministryName),
                        )
                      : const Icon(Icons.lock, color: Colors.grey),
                );
              },
            );
          },
        );
      },
    );
  }
  
  // Confirmar y eliminar un grupo
  Future<void> _confirmDeleteGroup(String groupId, String groupName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Grupo'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: '¿Está seguro que desea eliminar el grupo '),
              TextSpan(
                text: groupName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
              const TextSpan(
                text: '\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Grupo "$groupName" eliminado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar el grupo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  // Confirmar y eliminar un ministerio
  Future<void> _confirmDeleteMinistry(String ministryId, String ministryName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ministerio'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: '¿Está seguro que desea eliminar el ministerio '),
              TextSpan(
                text: ministryName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
              const TextSpan(
                text: '\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance.collection('ministries').doc(ministryId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ministerio "$ministryName" eliminado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar el ministerio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
} 