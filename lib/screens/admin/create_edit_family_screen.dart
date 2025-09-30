import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para ImagePicker
import 'package:intl_phone_field/intl_phone_field.dart'; // <-- AÑADIR IMPORT
import 'package:uuid/uuid.dart'; // Para generar IDs
import 'package:firebase_storage/firebase_storage.dart'; // Para Storage
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../constants/privacy_terms_texts.dart'; // <-- IMPORTAR TEXTOS
import '../../models/family_model.dart'; // Importar modelo familia
import '../../services/image_service.dart'; // <-- IMPORTAR IMAGE SERVICE
import 'package:firebase_auth/firebase_auth.dart';
// Asegúrate de tener el widget CircularImagePicker o uno similar, o lo implementaremos aquí de forma simplificada
// import '../../widgets/circular_image_picker.dart'; 

class CreateEditFamilyScreen extends StatefulWidget {
  const CreateEditFamilyScreen({super.key});

  @override
  State<CreateEditFamilyScreen> createState() => _CreateEditFamilyScreenState();
}

class _CreateEditFamilyScreenState extends State<CreateEditFamilyScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // --- Claves para Forms por Paso ---
  final _step1FormKey = GlobalKey<FormState>(); // Añadido por consistencia, aunque no se use aún
  final _step2FormKey = GlobalKey<FormState>();
  // --- Fin Claves ---

  // Controladores para el primer paso
  final _familyNameController = TextEditingController();
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // Controladores y variables para el Paso 2: Datos del Responsable
  final _guardianFullNameController = TextEditingController();
  DateTime? _guardianBirthDate;
  String? _guardianGender;
  final _guardianPhoneController = TextEditingController();
  String _guardianPhoneCountryCode = '+55';
  String _guardianPhoneCompleteNumber = '';
  String _guardianIsoCountryCode = 'BR'; 
  String? _guardianPhoneType;
  final _guardianEmailController = TextEditingController();
  final _guardianPasswordController = TextEditingController();
  bool _guardianPasswordVisible = false;
  XFile? _guardianPickedImage; // Foto para el responsable

  // Controladores para la Dirección (Paso 2)
  final _cepController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  bool _addressExpanded = false; // Para controlar el ExpansionTile

  // --- Variables para Búsqueda de Usuario (Responsable) ---
  final _userSearchController = TextEditingController();
  String _userSearchTerm = '';
  List<UserModel> _userSearchResults = []; // Necesitarás importar UserModel
  bool _isSearchingUsers = false;
  bool _showUserSearchResults = false;
  String? _guardianPhotoUrlFromSearch; // Para almacenar la URL de la foto del usuario buscado
  // --- Fin Variables para Búsqueda ---

  // --- Variables para el Paso 3: Términos y Condiciones ---
  bool _term1Accepted = false;
  bool _term2Accepted = false;
  bool _term3Accepted = false;
  bool _term4Accepted = false;
  // --- Fin Variables para Paso 3 ---

  // --- Variable para el Paso 4: Foto de Consentimiento ---
  XFile? _consentPhoto;
  // --- Fin Variable para Paso 4 ---

  // --- Flag para controlar validación del Paso 2 ---
  bool _step2AttemptedValidation = false;
  // --- Fin Flag ---

  // --- Estado de Guardado ---
  bool _isSaving = false;
  // --- Fin Estado de Guardado ---

  // --- Instancia de ImageService ---
  final ImageService _imageService = ImageService();
  // --- Fin Instancia ---

  // TODO: Añadir controladores y variables para futuros pasos

  @override
  void initState() { // Asegúrate que initState exista o créalo
    super.initState();
    _userSearchController.addListener(() {
      if (mounted) { // Verificar si el widget está montado
        setState(() {
          _userSearchTerm = _userSearchController.text;
          if (_userSearchTerm.length > 2) { // Iniciar búsqueda después de 3 caracteres
            _showUserSearchResults = true; // Mostrar área de resultados (incluso si está vacía o cargando)
            _searchUsers(_userSearchTerm);
          } else {
            _showUserSearchResults = false;
            _userSearchResults = [];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _familyNameController.dispose();
    // Disponer controladores del Paso 2
    _guardianFullNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianEmailController.dispose();
    _guardianPasswordController.dispose();
    _cepController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _neighborhoodController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _userSearchController.dispose(); // Disponer el nuevo controlador
    // TODO: Dispose otros controladores
    super.dispose();
  }

  Future<void> _pickGuardianImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _guardianPickedImage = image;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validar Paso 1 (Nombre familia)
      // Usando FormKey sería: if (_step1FormKey.currentState!.validate()) { ... }
      // Por ahora, validación simple:
      if (_familyNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, introduza o nome da família.'), backgroundColor: Colors.red),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validar Paso 2 (Datos responsable) usando FormKey
      setState(() {
        _step2AttemptedValidation = true; // Marcar que se intentó validar
      });

      bool isBirthDateValid = _guardianBirthDate != null;
      bool isFormValid = _step2FormKey.currentState?.validate() ?? false;

      if (!isFormValid || !isBirthDateValid) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, corrija os erros e preencha todos os campos obrigatórios (*).'), backgroundColor: Colors.red),
        );
        return;
      }
      // Aquí podrías guardar temporalmente los datos del paso 2
    } else if (_currentStep == 2) {
      // Validar Paso 3 (Términos requeridos)
      bool requiredTermsAccepted = _term1Accepted && _term2Accepted && _term3Accepted;
      if (!requiredTermsAccepted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, aceite as 3 primeiras confirmações para continuar.'), backgroundColor: Colors.red),
        );
        return; // No avanzar si no se aceptaron los términos requeridos
      }
    }
    // TODO: Añadir validación para otros pasos futuros

    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_pageController.hasClients) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Implementación de _saveFamily ---
  Future<void> _saveFamily() async {
    if (_isSaving) return; // Evitar doble guardado

    // 1. Validar el último paso (foto de consentimiento)
    if (_consentPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, tire a foto de confirmação antes de salvar.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
      print('[SAVE_FAMILY] Estado _isSaving = true');
    });

    try {
      String? familyPhotoUrl;
      String? guardianPhotoUrl;
      String? consentPhotoUrl;
      final familyId = const Uuid().v4(); 
      print('[SAVE_FAMILY] Generado familyId: $familyId');

      // 3. Subir imágenes en PARALELO
      print('[SAVE_FAMILY] Iniciando subida paralela de imágenes...');
      List<Future<String?>> uploadFutures = [];
      Map<String, String?> imageUrls = {}; // Para almacenar URLs por tipo

      if (_pickedImage != null) {
        print('[SAVE_FAMILY] Añadiendo futuro para foto de familia...');
        uploadFutures.add(
          _uploadImage(_pickedImage!, 'family_photos/$familyId.jpg')
              .then((url) => imageUrls['family'] = url)
        );
      }
      if (_guardianPickedImage != null) {
        print('[SAVE_FAMILY] Añadiendo futuro para foto de responsable...');
        uploadFutures.add(
           _uploadImage(_guardianPickedImage!, 'guardian_photos/${familyId}_guardian.jpg')
               .then((url) => imageUrls['guardian'] = url)
        );
      }
      if (_consentPhoto != null) { // Siempre debería ser no nulo aquí por validación previa
         print('[SAVE_FAMILY] Añadiendo futuro para foto de consentimiento...');
          uploadFutures.add(
            _uploadImage(_consentPhoto!, 'family_consent_photos/${familyId}_consent.jpg')
                .then((url) => imageUrls['consent'] = url)
        );
      }
      
      // Esperar a que todas las subidas terminen
      await Future.wait(uploadFutures);
      print('[SAVE_FAMILY] Subida paralela completada. URLs: $imageUrls');

      // Verificar si alguna subida falló (las obligatorias)
      if (imageUrls['consent'] == null) {
         print('[SAVE_FAMILY] Falló subida foto consentimiento (obligatoria)');
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro crítico ao carregar foto de confirmação.'), backgroundColor: Colors.red));
            setState(() => _isSaving = false);
         }
         return;
      }
      // Podrías añadir verificaciones similares para otras fotos si fueran obligatorias
      
      // Asignar URLs obtenidas
      familyPhotoUrl = imageUrls['family'];
      // Si no se subió foto de guardián, mantener la de búsqueda si existe
      guardianPhotoUrl = imageUrls['guardian'] ?? _guardianPhotoUrlFromSearch;
      consentPhotoUrl = imageUrls['consent']; // Ya validado que no es null

      // 4. Preparar nombre/apellido del responsable
      String guardianFirstName = '';
      String guardianLastName = '';
      final fullNameParts = _guardianFullNameController.text.trim().split(' ');
      if (fullNameParts.isNotEmpty) {
        guardianFirstName = fullNameParts.first;
        if (fullNameParts.length > 1) {
          guardianLastName = fullNameParts.sublist(1).join(' ');
        }
      }
      print('[SAVE_FAMILY] Nombre responsable: $guardianFirstName $guardianLastName');

      // 5. Crear instancia del modelo
       print('[SAVE_FAMILY] Creando instancia de FamilyModel...');
       
       // --- OBTENER UID DEL USUARIO ACTUAL (ASUMIENDO QUE ES EL PRIMER GUARDIÁN) ---
       // Esta es una simplificación. Idealmente, buscaríamos/crearíamos un UserModel
       // para el responsable introducido en el Paso 2 y guardaríamos su ID.
       final currentUser = FirebaseAuth.instance.currentUser;
       String? firstGuardianId = currentUser?.uid; 
       // --- FIN SIMPLIFICACIÓN ---

       final newFamily = FamilyModel(
        id: familyId, 
        familyName: _familyNameController.text.trim(), 
        familyAvatarUrl: familyPhotoUrl, // Foto de familia (Paso 1)
        // Guardar el ID del usuario actual como el (único) guardián inicial
        guardianUserIds: firstGuardianId != null ? [firstGuardianId] : [], 
        address: '${_streetController.text.trim()}, ${_numberController.text.trim()} - ${_neighborhoodController.text.trim()}, ${_cityController.text.trim()} / ${_stateController.text.trim()} - CEP: ${_cepController.text.trim()}'.replaceAll(RegExp(r'(^, )|( - , )|( / $)|( - CEP: $)'), '').trim(), 
        childIds: [], 
        createdAt: Timestamp.now(), 
        // --- FALTAN DATOS DE RESPONSABLE Y CONSENTIMIENTO EN EL MODELO --- 
        // Los datos del responsable (nombre, email, tel, etc. del Paso 2) no se guardan aquí,
        // se asume que están en el UserModel referenciado por guardianUserIds.
        // Los datos de consentimiento (bools, foto) tampoco se guardan.
      );
      
      final familyDataToSave = newFamily.toMap();
      print('[SAVE_FAMILY] Datos a guardar en Firestore: $familyDataToSave');

      // 6. Guardar en Firestore
      print('[SAVE_FAMILY] Guardando en Firestore...');
      await FirebaseFirestore.instance.collection('families').doc(familyId).set(familyDataToSave);
      print('[SAVE_FAMILY] Documento guardado en Firestore.');

      // 7. Éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Família registrada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Regresar a la lista
      }

    } catch (e) {
      print("Erro ao salvar família: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar família: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _userSearchResults = [];
          _isSearchingUsers = false;
          _showUserSearchResults = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isSearchingUsers = true;
      });
    }

    try {
      // Búsqueda por displayName (case-insensitive aproximado)
      QuerySnapshot nameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: searchTerm)
          .where('displayName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .limit(5) // Limitar resultados
          .get();

      // Búsqueda por email (case-insensitive aproximado)
      QuerySnapshot emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchTerm.toLowerCase())
          .where('email', isLessThanOrEqualTo: '${searchTerm.toLowerCase()}\uf8ff')
          .limit(5) // Limitar resultados
          .get();

      Set<String> processedUserIds = {}; // Para evitar duplicados si el nombre y email coinciden
      List<UserModel> combinedResults = [];

      for (var doc in nameQuery.docs) {
        if (doc.exists && !processedUserIds.contains(doc.id)) {
          // Asumiendo que UserModel tiene un factory constructor 'fromMap' que toma el id del documento
          combinedResults.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
          processedUserIds.add(doc.id);
        }
      }
      for (var doc in emailQuery.docs) {
        if (doc.exists && !processedUserIds.contains(doc.id)) {
          combinedResults.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
          processedUserIds.add(doc.id);
        }
      }
      
      // Podrías querer ordenar o priorizar resultados aquí

      if (mounted) {
        setState(() {
          _userSearchResults = combinedResults;
          _isSearchingUsers = false;
        });
      }
    } catch (e) {
      print("Error buscando usuarios: $e");
      if (mounted) {
        setState(() {
          _isSearchingUsers = false;
          _userSearchResults = []; // Limpiar resultados en caso de error
        });
      }
    }
  }

  void _selectUserForGuardian(UserModel selectedUser) {
    if (!mounted) return;

    setState(() {
      _guardianFullNameController.text = selectedUser.displayName ?? '${selectedUser.name ?? ''} ${selectedUser.surname ?? ''}'.trim();
      _guardianEmailController.text = selectedUser.email;
      
      // Asumiendo que tu UserModel (el que modificaste para ProfileScreen) tiene estos campos:
      _guardianPhoneController.text = selectedUser.phone ?? ''; 
      // _guardianIsoCountryCode = selectedUser.isoCountryCode ?? 'BR';
      // _guardianPhoneCountryCode = selectedUser.phoneCountryCode ?? '+55';
      // _guardianPhoneCompleteNumber = selectedUser.phoneComplete ?? '';
      // La línea anterior está comentada porque tu UserModel actual no tiene isoCountryCode, etc.
      // Si los añades a UserModel, puedes descomentarlos.

      _guardianBirthDate = selectedUser.birthDate?.toDate(); // Corregido: convertir Timestamp a DateTime
      _guardianGender = selectedUser.gender;
      
      _guardianPhotoUrlFromSearch = selectedUser.photoUrl;
      _guardianPickedImage = null; // Limpiar imagen local si seleccionamos un usuario existente con foto

      // NO autocompletar contraseña
      _guardianPasswordController.clear();

      // Limpiar búsqueda y ocultar resultados
      _userSearchController.clear();
      _userSearchTerm = '';
      _showUserSearchResults = false;
      _userSearchResults = [];
    });
  }

  Future<String?> _uploadImage(XFile imageFile, String path) async {
    File? compressedFile;
    try {
      // 1. Comprimir la imagen usando el servicio
      final File originalFile = File(imageFile.path);
      compressedFile = await _imageService.compressImage(originalFile);

      if (compressedFile == null) {
        print('La compresión de imagen falló para $path');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao processar a imagem.'), backgroundColor: Colors.orange),
        );
        return null; // Detener si la compresión falla
      }

      // 2. Subir el archivo comprimido
      final ref = FirebaseStorage.instance.ref().child(path);
      // Usar putFile con el archivo comprimido
      final uploadTask = ref.putFile(compressedFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 3. Limpiar el archivo comprimido temporal (opcional, pero buena práctica)
      // Si compressImage crea archivos temporales, podríamos limpiarlos aquí 
      // o confiar en la limpieza general de ImageService si la tiene.
      // await compressedFile.delete(); // Descomentar si es necesario limpiar explícitamente
      
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen a $path: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar imagem: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
       // Asegurarse de eliminar el archivo temporal si existe y no se hizo antes
       /* Descomentar si se requiere limpieza explícita aquí
       if (compressedFile != null && await compressedFile.exists()) {
         try {
           await compressedFile.delete();
         } catch (e) {
           print('Error al eliminar archivo temporal comprimido: $e');
         }
       }
       */
    }
  }

  Future<void> _takeConsentPhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _consentPhoto = photo;
      });
    }
  }

  Widget _buildStep3TermsAndConditions() {
    // Determinar si los términos REQUERIDOS han sido aceptados
    bool requiredTermsAccepted = _term1Accepted && _term2Accepted && _term3Accepted; // Solo los primeros 3

    // Textos cortos para los switches
    String term1SwitchLabel = "Li e concordo com os termos, as condições de uso e a política de privacidade da aplicação MyKids.";
    String term2SwitchLabel = "Concordo com o tratamento dos meus dados pessoais e dos de minha família, conforme descrito anteriormente e para os fins da atividade religiosa.";
    String term3SwitchLabel = "Concordo com a coleta, armazenamento e processamento de dados dos meus familiares menores (crianças e adolescentes), visando seu melhor interesse e segurança nas atividades.";
    String term4SwitchLabel = "Concordo com a difusão de fotografias de ambientes que possam incluir imagens dos meus familiares (incluindo crianças e adolescentes) nos canais de comunicação da igreja.";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Termos e Condições de Uso', 
            style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          
          // --- Área de Texto Scrollable con Términos Completos ---
          Container(
            height: 300, // Altura fija para el área de texto, ajustar según necesidad
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.white, // Fondo blanco para el texto
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  fullPrivacyTermsText, // Mostrar el texto completo importado
                  style: AppTextStyles.bodyText2?.copyWith(fontSize: 13), // Estilo para el texto legal
                ),
              ),
            ),
          ),
          // --- Fin Área de Texto ---

          const SizedBox(height: 16),
          Text(
            'Confirmações de Leitura e Aceite:',
            style: AppTextStyles.bodyText1?.copyWith(fontWeight: FontWeight.w600)
          ),
          const SizedBox(height: 12),
          
          // Switches de aceptación
          _buildTermSwitch(term1SwitchLabel, _term1Accepted, (bool value) => setState(() => _term1Accepted = value)),
          const SizedBox(height: 12),
          _buildTermSwitch(term2SwitchLabel, _term2Accepted, (bool value) => setState(() => _term2Accepted = value)),
          const SizedBox(height: 12),
          _buildTermSwitch(term3SwitchLabel, _term3Accepted, (bool value) => setState(() => _term3Accepted = value)),
          const SizedBox(height: 12),
          _buildTermSwitch(term4SwitchLabel, _term4Accepted, (bool value) => setState(() => _term4Accepted = value)), // Este sigue aquí, pero no bloquea
          
          const SizedBox(height: 24),
          // Mensaje de advertencia si los términos REQUERIDOS no están aceptados
          if (!requiredTermsAccepted)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Text(
                  'Por favor, leia e aceite as 3 primeiras confirmações para continuar.', // Mensaje actualizado
                  style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_currentStep > 0) _previousStep(); else Navigator.pop(context);
                  },
                  child: Text('CANCELAR', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: requiredTermsAccepted ? AppColors.primary : Colors.grey.shade400, // Usar requiredTermsAccepted
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // Usar requiredTermsAccepted para habilitar/deshabilitar y para la acción
                  onPressed: requiredTermsAccepted ? _nextStep : null, 
                  child: Text('LI E CONCORDO', style: AppTextStyles.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermSwitch(String text, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.8)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: Text(text, style: AppTextStyles.bodyText1.copyWith(color: AppColors.textPrimary))),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4TakePhotoConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.camera_enhance_outlined, size: 80, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 16),
          Text(
            'Confirmação de Presença', 
            style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Para finalizar o registro e confirmar seu consentimento, por favor, tire uma foto sua no momento.',
            style: AppTextStyles.bodyText1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Mostrar la foto tomada o un botón para tomarla
          _consentPhoto == null
            ? ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('TIRAR FOTO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: AppTextStyles.button,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _takeConsentPhoto,
              )
            : Column(
                children: [
                  Text('Foto de confirmação capturada:', style: AppTextStyles.caption?.copyWith(color: Colors.green.shade800)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(_consentPhoto!.path),
                      height: 200, // Ajustar altura según sea necesario
                      fit: BoxFit.contain,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Tirar novamente'),
                    onPressed: _takeConsentPhoto, 
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary)
                  )
                ],
              ),
          
          const SizedBox(height: 32),
          // El botón principal de "SALVAR FAMÍLIA" estará en el bottomNavigationBar
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalSteps = 4; 
    bool isLastStep = _currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Novo Registro - Passo ${_currentStep + 1}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Deshabilitar botón atrás mientras guarda para evitar estados inconsistentes
          onPressed: _isSaving ? null : () {
            if (_currentStep == 0) {
              Navigator.pop(context);
            } else {
              _previousStep();
            }
          },
        ),
      ),
      body: Stack( // <-- Envolver el PageView con un Stack
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (step) {
              setState(() {
                _currentStep = step;
              });
            },
            children: <Widget>[
              _buildStep1FamilyInfo(),
              _buildStep2GuardianInfo(),
              _buildStep3TermsAndConditions(),
              _buildStep4TakePhotoConfirmation(), 
            ],
          ),
          // --- Superposición de Carga --- 
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Fondo semitransparente
                child: const Center(
                  child: Column( // Añadir texto opcional
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text("Salvando família...", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  )
                ),
              ),
            ),
          // --- Fin Superposición ---
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: (_currentStep == 2) 
            ? const SizedBox.shrink() 
            // Deshabilitar botón mientras guarda
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isSaving || (isLastStep && _consentPhoto == null)) 
                                     ? Colors.grey.shade400 
                                     : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving // Si está guardando, onPressed es null
                    ? null 
                    : (isLastStep 
                        ? (_consentPhoto != null ? _saveFamily : null) 
                        : _nextStep),
                child: Text(
                  isLastStep ? 'SALVAR FAMÍLIA' : 'CONTINUAR',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildStep1FamilyInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              backgroundImage: _pickedImage != null ? FileImage(File(_pickedImage!.path)) : null,
              child: _pickedImage == null
                  ? Icon(Icons.camera_alt_outlined, size: 50, color: AppColors.secondary.withOpacity(0.7))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            label: Text('Editar foto', style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary)),
            onPressed: _pickImage,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _familyNameController,
            decoration: InputDecoration(
              labelText: 'Nome da Família *',
              hintText: 'Introduza o nome da família',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'O nome da família é obrigatório.';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2GuardianInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _userSearchController,
              decoration: InputDecoration(
                labelText: 'Buscar Responsável Existente (Nome/Email)',
                hintText: 'Digite para buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _userSearchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _userSearchController.clear();
                          setState(() {
                            _showUserSearchResults = false;
                            _userSearchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),

            if (_showUserSearchResults)
              _isSearchingUsers
                  ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  : _userSearchResults.isEmpty && _userSearchTerm.length > 2
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: Text('Nenhum usuário encontrado para "$_userSearchTerm".')),
                        )
                      : SizedBox(
                          height: _userSearchResults.isNotEmpty ? 200.0 : 0,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _userSearchResults.length,
                            itemBuilder: (context, index) {
                              final user = _userSearchResults[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                        ? NetworkImage(user.photoUrl!)
                                        : null,
                                    child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                        ? Icon(Icons.person_outline, color: AppColors.secondary.withOpacity(0.8))
                                        : null,
                                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                                  ),
                                  title: Text(user.displayName ?? '${user.name ?? ''} ${user.surname ?? ''}'.trim()),
                                  subtitle: Text(user.email),
                                  onTap: () => _selectUserForGuardian(user),
                                ),
                              );
                            },
                          ),
                        ),
            const SizedBox(height: 16),

            // --- INICIO DEL FORMULARIO VALIDABLE ---
            Center(
              child: GestureDetector(
                onTap: _pickGuardianImage, 
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  backgroundImage: _guardianPickedImage != null 
                      ? FileImage(File(_guardianPickedImage!.path)) // Prioridad 1: Imagen local seleccionada
                      : (_guardianPhotoUrlFromSearch != null && _guardianPhotoUrlFromSearch!.isNotEmpty) 
                          ? NetworkImage(_guardianPhotoUrlFromSearch!) // Prioridad 2: Imagen del usuario buscado
                          : null, // Sin imagen de fondo si no hay local ni de búsqueda
                  child: (_guardianPickedImage == null && (_guardianPhotoUrlFromSearch == null || _guardianPhotoUrlFromSearch!.isEmpty))
                      // Mostrar ícono solo si no hay imagen local NI imagen de búsqueda
                      ? Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.secondary.withOpacity(0.7))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                label: Text('Editar foto do responsável', style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary)),
                onPressed: _pickGuardianImage,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _guardianFullNameController,
              decoration: const InputDecoration(labelText: 'Nome completo *'),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome completo é obrigatório.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _guardianBirthDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        locale: const Locale('pt', 'BR'),
                      );
                      if (picked != null && picked != _guardianBirthDate) {
                        setState(() {
                          _guardianBirthDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Nascimento *',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                        errorText: _step2AttemptedValidation && _guardianBirthDate == null 
                                   ? 'Data obrigatória' 
                                   : null,
                      ),
                      child: Text(
                        _guardianBirthDate != null 
                            ? '${_guardianBirthDate!.day}/${_guardianBirthDate!.month}/${_guardianBirthDate!.year}' 
                            : 'Selecionar data',
                        style: _guardianBirthDate != null ? AppTextStyles.bodyText1 : AppTextStyles.bodyText1.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Sexo *'),
                    value: _guardianGender,
                    isExpanded: true,
                    items: ['Masculino', 'Feminino', 'Prefiro não dizer']
                        .map((label) => DropdownMenuItem(child: Text(label, overflow: TextOverflow.ellipsis), value: label))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _guardianGender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            IntlPhoneField(
              controller: _guardianPhoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone *',
                border: OutlineInputBorder(borderSide: BorderSide()),
              ),
              initialCountryCode: _guardianIsoCountryCode,
              languageCode: 'pt',
              onChanged: (phone) {
                setState(() {
                  _guardianPhoneCompleteNumber = phone.completeNumber;
                  _guardianPhoneCountryCode = phone.countryCode;
                  _guardianIsoCountryCode = phone.countryISOCode;
                });
              },
              onCountryChanged: (country) {
                setState(() {
                   _guardianIsoCountryCode = country.code;
                   _guardianPhoneCountryCode = '+${country.dialCode}';
                });
              },
              validator: (phoneNumber) {
                if (phoneNumber == null || phoneNumber.number.trim().isEmpty) {
                  return 'Telefone é obrigatório.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de telefone *'),
              value: _guardianPhoneType,
              isExpanded: true,
              items: ['Teléfono', 'Comercial', 'Residencial']
                  .map((label) => DropdownMenuItem(child: Text(label), value: label))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _guardianPhoneType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _guardianEmailController,
              decoration: const InputDecoration(labelText: 'Correo eletrônico *', suffixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Correo eletrônico é obrigatório.';
                if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                  return 'Formato de correo inválido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _guardianPasswordController,
              decoration: InputDecoration(
                labelText: 'Senha *',
                suffixIcon: IconButton(
                  icon: Icon(_guardianPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () {
                    setState(() {
                      _guardianPasswordVisible = !_guardianPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_guardianPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Senha é obrigatória.';
                }
                 if (value.length < 6) {
                   return 'Senha deve ter pelo menos 6 caracteres.';
                 }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text('Direção', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                trailing: Icon(_addressExpanded ? Icons.expand_less : Icons.expand_more),
                initiallyExpanded: _addressExpanded,
                tilePadding: EdgeInsets.zero,
                onExpansionChanged: (bool expanded) {
                  setState(() => _addressExpanded = expanded);
                },
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: [
                        TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Rua')),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(flex: 2, child: TextFormField(controller: _numberController, decoration: const InputDecoration(labelText: 'Número'))),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: TextFormField(controller: _complementController, decoration: const InputDecoration(labelText: 'Complemento'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: 'Bairro')),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Município/Localidade'))),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'Estado/Província'))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cepController,
                          decoration: const InputDecoration(labelText: 'Código Postal'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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