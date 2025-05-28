import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart'; // Para la lista de niños del visitante
import '../../services/image_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import './create_edit_child_screen.dart'; // Para agregar/editar niños
import '../checkin/child_selection_screen.dart'; // Para el flujo de Check-in

class CreateEditVisitorScreen extends StatefulWidget {
  final String? visitorUserId; // ID del visitante para modo edición

  const CreateEditVisitorScreen({super.key, this.visitorUserId});

  @override
  State<CreateEditVisitorScreen> createState() => _CreateEditVisitorScreenState();
}

class _CreateEditVisitorScreenState extends State<CreateEditVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isLoadingData = false;

  // Controladores del Responsable (Visitante)
  final _fullNameController = TextEditingController();
  DateTime? _birthDate; // Aunque no se muestra en la UI de la imagen, lo mantenemos por consistencia con UserModel
  String? _gender;    // Ídem
  final _phoneController = TextEditingController();
  String _phoneCountryCode = '+55';
  String _phoneCompleteNumber = '';
  String _isoCountryCode = 'BR';
  String? _phoneType;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  XFile? _pickedImage;
  String? _existingPhotoUrl;

  // Dirección (Igual que en responsable de familia)
  final _cepController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  bool _addressExpanded = false;

  // --- Key para IntlPhoneField del Visitante ---
  Key _visitorPhoneFieldKey = UniqueKey(); 
  // --- Fin Key ---

  // Lista de niños asociados al visitante (manejo local por ahora)
  final List<ChildModel> _associatedChildren = [];
  // Podríamos necesitar una lista de XFile para las fotos de los niños si se añaden aquí

  // --- Variables para Búsqueda de Usuario (Visitante) ---
  final _userSearchController = TextEditingController();
  String _userSearchTerm = '';
  List<UserModel> _userSearchResults = [];
  bool _isSearchingUsers = false;
  bool _showUserSearchResults = false;
  // String? _visitorPhotoUrlFromSearch; // Reemplazado por _existingPhotoUrl
  // --- Fin Variables para Búsqueda ---

  bool get _isEditMode => widget.visitorUserId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadVisitorData();
    }
    _userSearchController.addListener(() {
      if (mounted) {
        setState(() {
          _userSearchTerm = _userSearchController.text;
          if (_userSearchTerm.length > 2) {
            _showUserSearchResults = true;
            _searchUsers(_userSearchTerm);
          } else {
            _showUserSearchResults = false;
            _userSearchResults = [];
          }
        });
      }
    });
  }

  Future<void> _loadVisitorData() async {
    if (widget.visitorUserId == null) return;
    setState(() => _isLoadingData = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.visitorUserId!).get();
      if (userDoc.exists) {
        final userData = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        _fullNameController.text = userData.displayName ?? '${userData.name ?? ''} ${userData.surname ?? ''}'.trim();
        _emailController.text = userData.email;
        _phoneController.text = userData.phone ?? '';
        _isoCountryCode = userData.isoCountryCode ?? 'BR';
        _phoneCountryCode = userData.phoneCountryCode ?? '+55';
        _phoneCompleteNumber = userData.phoneComplete ?? '';
        _birthDate = userData.birthDate?.toDate();
        _gender = userData.gender;
        _existingPhotoUrl = userData.photoUrl;
        // TODO: Cargar dirección si está en UserModel
        
        // --- CARGAR NIÑOS ASOCIADOS ---
        if (widget.visitorUserId != null) {
          print('Cargando crianças para visitante: ${widget.visitorUserId}');
          final childrenQuery = await FirebaseFirestore.instance
              .collection('children')
              .where('familyId', isEqualTo: widget.visitorUserId) // familyId se usa para visitorId aquí
              .get();
          
          List<ChildModel> loadedChildren = [];
          for (var doc in childrenQuery.docs) {
            try {
              loadedChildren.add(ChildModel.fromFirestore(doc));
            } catch (e) {
              print('Error al parsear ChildModel desde Firestore: ${doc.id} - $e');
            }
          }
          // Actualizar el estado con los niños cargados
          // Esto se hace dentro del setState principal que ya está manejando _isLoadingData
          _associatedChildren.clear(); // Limpiar por si se recarga
          _associatedChildren.addAll(loadedChildren);
          print('Crianças carregadas: ${_associatedChildren.length}');
        }
        // --- FIN CARGAR NIÑOS ---

      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitante não encontrado.'), backgroundColor: Colors.red));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Erro ao carregar dados do visitante: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    // Disponer todos los controladores
    _fullNameController.dispose(); _phoneController.dispose(); _emailController.dispose(); _passwordController.dispose();
    _cepController.dispose(); _stateController.dispose(); _cityController.dispose(); _neighborhoodController.dispose();
    _streetController.dispose(); _numberController.dispose(); _complementController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedImage = image);
  }

  // Navegar para agregar/editar niño
  Future<void> _navigateAndAddOrEditChild({ChildModel? existingChild, int? listIndex}) async {
    final result = await Navigator.push<ChildModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditChildScreen(
          familyId: widget.visitorUserId ?? 'temp_visitor_id', // Usar visitorUserId o un ID temporal
          childId: existingChild?.id,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (listIndex != null) { // Editando
          _associatedChildren[listIndex] = result;
        } else { // Añadiendo nuevo
          _associatedChildren.add(result);
        }
      });
    }
  }
  
  void _removeChild(int index) async {
    if (index < 0 || index >= _associatedChildren.length) return;

    final childToRemove = _associatedChildren[index];
    final String childId = childToRemove.id;

    // --- DIÁLOGO DE CONFIRMACIÓN ---
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // El usuario debe tocar un botón
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminação'),
          content: Text('Tem certeza que deseja remover permanentemente ${childToRemove.firstName} ${childToRemove.lastName} da lista de crianças deste visitante?'),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCELAR'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // No eliminar
              },
            ),
            TextButton(
              child: Text('ELIMINAR', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Sí eliminar
              },
            ),
          ],
        );
      },
    );
    // --- FIN DIÁLOGO ---

    if (confirmDelete == true) {
      // Si se confirma, proceder con la eliminación (la lógica de Firestore ya estaba aquí)
      setState(() {
        _isSaving = true; // Mostrar indicador si la eliminación de Firestore toma tiempo
      });
      try {
        // Eliminar de la lista local primero para actualización visual inmediata
        setState(() {
          _associatedChildren.removeAt(index);
        });

        // Eliminar de Firestore si tiene un ID persistente y no es temporal
        if (childId.isNotEmpty && !childId.startsWith('temp_')) {
          // Esta es la parte que elimina de la colección 'children'
          // Si estos niños solo existen en el contexto del visitante y no se guardan 
          // en 'children' hasta que se guarda el visitante, esta línea podría no ser necesaria aquí,
          // sino solo al guardar el visitante (no añadirlo a la lista de niños a guardar).
          // Pero si son niños que ya existen en 'children' y solo se desasocian,
          // entonces la eliminación de 'children' debe ser una decisión de negocio separada.
          // Por ahora, si tienen ID, asumimos que pueden existir en Firestore y se intenta borrar.
          await FirebaseFirestore.instance.collection('children').doc(childId).delete();
          print('Criança $childId potencialmente eliminada de Firestore (se existia).');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${childToRemove.firstName} removido(a).'), backgroundColor: Colors.orange));
        } else {
          // Si solo estaba en la lista local (ej. recién añadido y visitante aún no guardado)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${childToRemove.firstName} removido(a) da lista.'), backgroundColor: Colors.orange));
        }

      } catch (e) {
        print("Erro ao remover criança de Firestore: $e");
        // Reinsertar si falla y mostrar error
        setState(() {
          _associatedChildren.insert(index, childToRemove); 
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao remover ${childToRemove.firstName}: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  // Modificar _handleCheckinForVisitor para que guarde si es necesario
  Future<void> _handleCheckinForVisitor() async {
    if (!_isEditMode && widget.visitorUserId == null) {
      // Si es un nuevo visitante (no en modo edición y sin ID aún),
      // primero intentar guardarlo.
      bool visitorSaved = await _saveVisitor(andNavigateBack: false); // Modificar _saveVisitor para que no siempre navegue
      if (!visitorSaved) {
        // Si el guardado falló (ej. validación), no continuar con check-in
        return;
      }
      // Si se guardó, widget.visitorUserId debería estar actualizado (o el nuevo ID generado)
      // Esto es una simplificación, _saveVisitor necesitaría devolver el ID si es nuevo.
      // Por ahora, asumimos que _saveVisitor actualiza el estado o la navegacion lo maneja.
    }

    if (_associatedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma criança para fazer check-in.')));
      return;
    }
    
    // Determinar el ID a usar para ChildSelectionScreen
    // Si estamos en modo edición, widget.visitorUserId ya está. 
    // Si es nuevo y se guardó, _saveVisitor debería haberlo establecido o navegado.
    // Esta parte necesita robustez si _saveVisitor no actualiza un ID accesible aquí.
    String idForCheckin = widget.visitorUserId ?? _emailController.text.hashCode.toString(); // Fallback muy simple si no hay ID
    
    print('Check-in para visitante ID: $idForCheckin com crianças: ${_associatedChildren.map((c)=>c.id).toList()}');
     Navigator.push(context, MaterialPageRoute(builder: (_) => 
      ChildSelectionScreen(familyId: idForCheckin) 
    ));
  }

  // Modificar _saveVisitor para aceptar un parámetro que controle la navegación
  Future<bool> _saveVisitor({bool andNavigateBack = true}) async {
    if (!_formKey.currentState!.validate()) return false;
    if (_isSaving) return false;
    setState(() => _isSaving = true);
    bool success = false;

    try {
      String? photoUrl = _existingPhotoUrl;
      // Usar visitorUserId si existe (edición), si no, generar uno nuevo (creación)
      String userIdToSave = widget.visitorUserId ?? const Uuid().v4();

      if (_pickedImage != null) {
        photoUrl = await _uploadImage(_pickedImage!, 'user_photos/$userIdToSave.jpg');
        if (photoUrl == null) {
          setState(() => _isSaving = false);
          return false; 
        }
      }
      
      String firstName = ''; String lastName = '';
      final parts = _fullNameController.text.trim().split(' ');
      if(parts.isNotEmpty) firstName = parts.first;
      if(parts.length > 1) lastName = parts.sublist(1).join(' ');
      
      final visitorData = UserModel(
        email: _emailController.text.trim(),
        name: firstName, surname: lastName, displayName: _fullNameController.text.trim(),
        photoUrl: photoUrl, phone: _phoneController.text.trim(),
        phoneCountryCode: _phoneCountryCode, phoneComplete: _phoneCompleteNumber, isoCountryCode: _isoCountryCode,
        birthDate: _birthDate != null ? Timestamp.fromDate(_birthDate!) : null, gender: _gender,
        createdAt: _isEditMode && widget.visitorUserId != null
            ? ((await FirebaseFirestore.instance.collection('users').doc(widget.visitorUserId!).get()).data()?['createdAt'] as Timestamp? ?? Timestamp.now()).toDate()
            : DateTime.now(),
        isVisitorOnly: true, 
      );

      await FirebaseFirestore.instance.collection('users').doc(userIdToSave).set(visitorData.toMap(), SetOptions(merge: _isEditMode || widget.visitorUserId != null));
      print('Visitante ${_isEditMode ? "atualizado" : "guardado"} en Firestore con ID: $userIdToSave');

      if (_associatedChildren.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (ChildModel child in _associatedChildren) {
          final childDataToSave = child.copyWith(familyId: userIdToSave); 
          DocumentReference childDocRef;
          if (childDataToSave.id.isNotEmpty && !childDataToSave.id.startsWith('temp_')) { 
            childDocRef = FirebaseFirestore.instance.collection('children').doc(childDataToSave.id);
            batch.update(childDocRef, childDataToSave.toMap());
          } else {
            final newChildId = childDataToSave.id.startsWith('temp_') || childDataToSave.id.isEmpty ? const Uuid().v4() : childDataToSave.id;
            childDocRef = FirebaseFirestore.instance.collection('children').doc(newChildId);
            final finalChildData = childDataToSave.id == newChildId ? childDataToSave : childDataToSave.copyWith(id: newChildId);
            batch.set(childDocRef, finalChildData.toMap());
          }
        }
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visitante ${_isEditMode ? "atualizado" : "salvo"} com sucesso!'), backgroundColor: Colors.green),
        );
        if (andNavigateBack) {
          Navigator.pop(context);
        }
      }
      success = true;
    } catch (e) {
      print("Erro ao salvar visitante: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar visitante: $e'), backgroundColor: Colors.red));
      }
      success = false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    return success;
  }

  Future<String?> _uploadImage(XFile imageFile, String path) async {
    File? compressedFile = await _imageService.compressImage(File(imageFile.path));
    if (compressedFile == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(compressedFile);
      return await ref.getDownloadURL();
    } catch (e) { /* ... */ return null; }
  }
  
  // --- MÉTODOS DE BÚSQUEDA (Similares a CreateEditFamilyScreen) ---
  Future<void> _searchUsers(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      if (mounted) setState(() { _userSearchResults = []; _isSearchingUsers = false; _showUserSearchResults = false; });
      return;
    }
    if (mounted) setState(() => _isSearchingUsers = true);
    try {
      QuerySnapshot nameQuery = await FirebaseFirestore.instance.collection('users').where('displayName', isGreaterThanOrEqualTo: searchTerm).where('displayName', isLessThanOrEqualTo: '$searchTerm\uf8ff').limit(5).get();
      QuerySnapshot emailQuery = await FirebaseFirestore.instance.collection('users').where('email', isGreaterThanOrEqualTo: searchTerm.toLowerCase()).where('email', isLessThanOrEqualTo: '${searchTerm.toLowerCase()}\uf8ff').limit(5).get();
      Set<String> processedUserIds = {}; 
      List<UserModel> combinedResults = [];
      for (var doc in nameQuery.docs) { if (doc.exists && !processedUserIds.contains(doc.id)) { combinedResults.add(UserModel.fromMap(doc.data() as Map<String, dynamic>)); processedUserIds.add(doc.id); }}
      for (var doc in emailQuery.docs) { if (doc.exists && !processedUserIds.contains(doc.id)) { combinedResults.add(UserModel.fromMap(doc.data() as Map<String, dynamic>)); processedUserIds.add(doc.id); }}
      if (mounted) setState(() { _userSearchResults = combinedResults; _isSearchingUsers = false; });
    } catch (e) {
      print("Error buscando usuarios: $e");
      if (mounted) setState(() { _isSearchingUsers = false; _userSearchResults = []; });
    }
  }

  void _selectUserForVisitor(UserModel selectedUser) {
    if (!mounted) return;
    setState(() {
      // Rellenar campos del visitante
      _fullNameController.text = selectedUser.displayName ?? '${selectedUser.name ?? ''} ${selectedUser.surname ?? ''}'.trim();
      _emailController.text = selectedUser.email; 
      _phoneController.text = selectedUser.phone ?? '';
      _isoCountryCode = selectedUser.isoCountryCode ?? 'BR';
      _phoneCountryCode = selectedUser.phoneCountryCode ?? '+55';
      _phoneCompleteNumber = selectedUser.phoneComplete ?? '';
      _birthDate = selectedUser.birthDate?.toDate();
      _gender = selectedUser.gender;
      _existingPhotoUrl = selectedUser.photoUrl; 
      _pickedImage = null; // Limpiar imagen local

      // IMPORTANTE: NO autocompletar contraseña.
      _passwordController.clear();
      // En este flujo, si se selecciona un usuario existente, no lo convertimos en 'isVisitorOnly=true'.
      // Solo se marca isVisitorOnly=true si se crea un *nuevo* usuario desde este flujo.

      _userSearchController.clear();
      _userSearchTerm = '';
      _showUserSearchResults = false;
      _userSearchResults = [];

      // TODO: Cargar dirección del selectedUser si está en UserModel y la sección de dirección está visible
      // TODO: Cargar niños del selectedUser si es un visitante recurrente (lógica más compleja)
    });
  }
  // --- FIN MÉTODOS DE BÚSQUEDA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Visitante' : 'Novo Visitante'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isLoadingData && _isEditMode) // Solo mostrar loading si es edit mode y está cargando
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // --- Campo de Búsqueda de Usuario ---
                    // No mostrar buscador si estamos en modo edición de un visitante existente
                    if (!_isEditMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextField(
                          controller: _userSearchController,
                          decoration: InputDecoration(
                            labelText: 'Buscar Usuário Existente (Nome/Email)',
                            hintText: 'Digite para buscar...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _userSearchTerm.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                                    _userSearchController.clear();
                                    setState(() {_showUserSearchResults = false; _userSearchResults = []; });
                                  })
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (!_isEditMode && _showUserSearchResults)
                      _isSearchingUsers
                          ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                          : _userSearchResults.isEmpty && _userSearchTerm.length > 2
                              ? Padding(padding: const EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('Nenhum usuário encontrado para "$_userSearchTerm".')))
                              : SizedBox(
                                  height: _userSearchResults.isNotEmpty ? 200.0 : 0, 
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _userSearchResults.length,
                                    itemBuilder: (context, index) {
                                      final user = _userSearchResults[index];
                                      return Card(elevation: 2, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile( /* ... como antes ... */ onTap: () => _selectUserForVisitor(user)));
                                    }
                                  ),
                                ),
                    // --- Fin Búsqueda ---

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
                    
                    // Campos del Responsable
                    TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Nome completo do Responsável *'), validator: (v) => (v==null || v.isEmpty) ? 'Obrigatório' : null, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    // --- Fecha Nacimiento y Sexo (opcionales para visitante, pero los dejamos por consistencia con UserModel) ---
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
                              decoration: const InputDecoration(labelText: 'Nascimento', suffixIcon: Icon(Icons.calendar_today_outlined)),
                              child: Text(_birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : 'Selecionar data'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Sexo'),
                            value: _gender,
                            isExpanded: true,
                            items: ['Masculino', 'Feminino', 'Prefiro não dizer'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                            onChanged: (val) => setState(() => _gender = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // --- Fin Fecha Nacimiento y Sexo ---
                    TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo eletrônico *', suffixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => (v==null || v.isEmpty || !v.contains('@')) ? 'Email inválido' : null, enabled: !_isEditMode),
                    const SizedBox(height: 16),
                    IntlPhoneField(
                       key: _visitorPhoneFieldKey,
                       controller: _phoneController,
                       decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()), 
                       initialCountryCode: _isoCountryCode,
                       languageCode: 'pt',
                       onChanged: (phone) { 
                         setState(() {
                            _phoneCompleteNumber = phone.completeNumber;
                            _phoneCountryCode = phone.countryCode;
                            _isoCountryCode = phone.countryISOCode;
                         });
                       },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Tipo de telefone'),
                      value: _phoneType,
                      isExpanded: true,
                      items: ['Celular', 'Comercial', 'Residencial'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) => setState(() => _phoneType = val),
                    ),
                    const SizedBox(height: 16),
                    // --- Sección Dirección (Re-añadida) ---
                    Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                        title: Text('Direção', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                        initiallyExpanded: _addressExpanded,
                        onExpansionChanged: (bool expanded) => setState(() => _addressExpanded = expanded),
                        children: <Widget>[
                            Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                                children: [
                                TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Rua')),
                                const SizedBox(height: 16),
                                Row(children: [ Expanded(flex: 2, child: TextFormField(controller: _numberController, decoration: const InputDecoration(labelText: 'Número'))), const SizedBox(width: 16), Expanded(flex: 3, child: TextFormField(controller: _complementController, decoration: const InputDecoration(labelText: 'Complemento')))]),
                                const SizedBox(height: 16),
                                TextFormField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: 'Bairro')),
                                const SizedBox(height: 16),
                                Row(children: [Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Município/Localidade'))), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'Estado/Província')))]),
                                const SizedBox(height: 16),
                                TextFormField(controller: _cepController, decoration: const InputDecoration(labelText: 'Código Postal'), keyboardType: TextInputType.number),
                                const SizedBox(height: 16),
                                ],
                            ),
                            ),
                        ],
                        ),
                    ),
                    // --- Fin Sección Dirección ---
                    const SizedBox(height: 24),

                    // --- Sección Niños/as ---
                    Align(
                      alignment: Alignment.centerLeft, 
                      child: Text('Crianças', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12), // Espacio después del título
                    
                    // Botón AGREGAR CRIANÇA primero
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      label: Text('AGREGAR CRIANÇA', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () => _navigateAndAddOrEditChild(),
                    ),
                    const SizedBox(height: 16), // Espacio antes de la lista/mensaje

                    // Lista o mensaje de "sin niños"
                    if (_associatedChildren.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('Aún no tienes ningún niño registrado', style: AppTextStyles.bodyText2.copyWith(color: Colors.grey)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _associatedChildren.length,
                        itemBuilder: (context, index) {
                          final child = _associatedChildren[index];
                          
                          // --- LÓGICA DE INICIALES MÁS ROBUSTA ---
                          String initials = '?';
                          if (child.firstName.isNotEmpty) {
                            initials = child.firstName[0].toUpperCase();
                            if (child.lastName.isNotEmpty) {
                              initials += child.lastName[0].toUpperCase();
                            } else {
                              // Si solo hay nombre, usar las dos primeras letras si es posible
                              if (child.firstName.length > 1) {
                                initials = child.firstName.substring(0, 2).toUpperCase();
                              } else {
                                initials = child.firstName.toUpperCase(); // Solo una letra si el nombre es de una letra
                              }
                            }
                          } else if (child.lastName.isNotEmpty) {
                            // Si solo hay apellido (poco común, pero por si acaso)
                             if (child.lastName.length > 1) {
                                initials = child.lastName.substring(0, 2).toUpperCase();
                              } else {
                                initials = child.lastName.toUpperCase(); 
                              }
                          }
                          // --- FIN LÓGICA DE INICIALES ---

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar( 
                                backgroundImage: (child.photoUrl != null && child.photoUrl!.isNotEmpty) ? NetworkImage(child.photoUrl!) : null,
                                child: (child.photoUrl == null || child.photoUrl!.isEmpty) 
                                  ? Text(initials, style: AppTextStyles.subtitle1.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary))
                                  : null,
                              ),
                              title: Text('${child.firstName} ${child.lastName}'.trim()), // Usar trim para el nombre completo
                              subtitle: Text('Idade: ${child.dateOfBirth != null ? DateTime.now().year - child.dateOfBirth.toDate().year : 'N/A'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: () => _navigateAndAddOrEditChild(existingChild: child, listIndex: index)),
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeChild(index)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          if (_isSaving) Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.white)))),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: _isEditMode 
            ? ElevatedButton( // Solo botón SALVAR si está en modo edición
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving ? Colors.grey.shade400 : AppColors.primary, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : () => _saveVisitor(andNavigateBack: true),
                child: Text('SALVAR ALTERAÇÕES', style: AppTextStyles.button.copyWith(color: Colors.white)),
              )
            : Row( // Dos botones si está en modo creación
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => _saveVisitor(andNavigateBack: true),
                      child: Text('SALVAR VISITANTE', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSaving ? Colors.grey.shade400 : AppColors.primary, 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _handleCheckinForVisitor,
                      child: Text('CHECK-IN', style: AppTextStyles.button.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              )
      ),
    );
  }

  // Copiar aquí el método _buildCheckboxWithField de CreateEditChildScreen
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