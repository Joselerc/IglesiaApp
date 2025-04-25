import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Esconder Delta de Firestore si existe
import 'package:flutter_quill/flutter_quill.dart' hide Text; // Volver a añadir hide Text
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'; // Importar extensiones para embeds
import 'dart:convert'; // Para jsonEncode/Decode en borradores
import 'dart:io'; // Para File
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../services/image_service.dart'; 
import '../../utils/icon_utils.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
// Importar embeds estándar

class EditPageScreen extends StatefulWidget {
  final String? pageId;

  const EditPageScreen({super.key, required this.pageId});

  @override
  State<EditPageScreen> createState() => _EditPageScreenState();
}

class _EditPageScreenState extends State<EditPageScreen> with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  QuillController _quillController = QuillController.basic(); // Restaurado
  final FocusNode _editorFocusNode = FocusNode(); // Restaurado
  final ScrollController _scrollController = ScrollController(); // <--- Nuevo ScrollController
  // final _contentController = TextEditingController(); // Eliminado

  bool _isLoading = false;
  StreamSubscription? _changeSubscription; // Restaurado

  // Dependencias para imágenes (tarjeta y contenido)
  final ImagePicker _picker = ImagePicker(); 
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final ImageService _imageService = ImageService(); 

  bool _hasUnsavedChanges = false;

  // --- Estados de tarjeta de vista previa ---
  String _cardDisplayType = 'icon';
  String? _cardImageUrl;
  String _cardIconName = 'article_outlined';
  File? _selectedCardImageFile;
  bool _isUploadingCardImage = false;
  // --- Fin estados tarjeta ---

  // Clave de borrador vuelve a mencionar Quill
  String get _draftKey => 'editPageDraft_quill_${widget.pageId ?? 'new'}'; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController.addListener(_markAsChanged); 
    // _contentController.addListener(_markAsChanged); // Eliminado
    _subscribeToChanges(); // Restaurado
    _initializePageData(); // Cargar datos
    _editorFocusNode.addListener(_onFocusChange); // <--- Añadir listener
  }

  @override
  void dispose() {
    _titleController.removeListener(_markAsChanged);
    // _contentController.removeListener(_markAsChanged); // Eliminado
    _titleController.dispose();
    // _contentController.dispose(); // Eliminado
    _changeSubscription?.cancel(); // Restaurado
    _quillController.dispose(); // Restaurado
    _editorFocusNode.removeListener(_onFocusChange); // <--- Remover listener
    _editorFocusNode.dispose(); 
    _scrollController.dispose(); // <--- Dispose ScrollController
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused && _hasUnsavedChanges) {
      _saveDraft();
      // Mensaje de borrador ajustado
      debugPrint("Borrador Quill guardado al pausar la app."); 
    }
  }

  // --- Lógica de subida de imagen del editor (Restaurada) ---
  // Será usada por el callback de la barra de herramientas de Quill
  Future<String?> _uploadEditorImageCallback(BuildContext context, File imageFile) async {
    if (mounted) setState(() => _isLoading = true); 
    String? downloadUrl;

    try {
       final fileName = 'pageContent_${widget.pageId ?? _uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
       final compressedImage = await _imageService.compressImage(imageFile, quality: 80);
       final fileToUpload = compressedImage ?? imageFile;
       final storageRef = _storage.ref().child('page_content_images').child(fileName); 
       final metadata = SettableMetadata(contentType: 'image/jpeg');

       debugPrint("⬆️ Subiendo imagen del editor (Quill Callback) a: ${storageRef.fullPath}");
       final uploadTask = storageRef.putFile(fileToUpload, metadata);
       final snapshot = await uploadTask;
       downloadUrl = await snapshot.ref.getDownloadURL();
       debugPrint("✅ Imagen del editor (Quill Callback) subida: $downloadUrl");
    } catch (e) {
       debugPrint('❌ Error al subir imagen del editor (Quill Callback): $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao inserir imagem: $e'), backgroundColor: Colors.red),
         );
       }
       downloadUrl = null; 
    } finally {
       if (mounted) {
         setState(() => _isLoading = false); 
       }
    }
    return downloadUrl;
  }

  Future<void> _initializePageData() async {
    // Resetear estados de tarjeta 
    _cardDisplayType = 'icon';
    _cardImageUrl = null;
    _cardIconName = 'article_outlined';
    _selectedCardImageFile = null;
    _isUploadingCardImage = false;
    // _contentController.clear(); // Eliminado
    // Asegurarse de que el controlador Quill está limpio al inicio
    _quillController = QuillController.basic(); 
    _subscribeToChanges(); // Volver a suscribir por si se llama de nuevo

    if (widget.pageId != null) {
      await _loadPageData(); 
    } else {
      final bool didRestoreDraft = await _tryLoadAndRestoreDraft();
      if (!didRestoreDraft && mounted) {
         // No necesitamos hacer nada aquí, _quillController ya está básico
         print("Nueva página, inicializando QuillController vacío."); 
      }
    }
    // Si _quillController sigue siendo null (no debería ocurrir), inicializar
    if (_quillController == null && mounted) { 
      print("WARN: _quillController era null, reinicializando.");
      _quillController = QuillController.basic();
      _subscribeToChanges();
    }
  }

  // --- Lógica de Borradores (Adaptada para Quill) ---
  Future<void> _saveDraft() async {
    if (!_hasUnsavedChanges) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Obtener el Delta JSON del documento Quill
      final contentJson = _quillController.document.toDelta().toJson(); 
      final draftData = {
        'title': _titleController.text,
        'elements': contentJson, // Guardar el Delta JSON
        'cardDisplayType': _cardDisplayType,
        'cardImageUrl': _cardImageUrl,
        'cardIconName': _cardIconName,
      };
      final draftString = jsonEncode(draftData);
      await prefs.setString(_draftKey, draftString);
      debugPrint("Borrador Quill JSON guardado localmente para $_draftKey");
    } catch (e) {
      debugPrint("Error guardando borrador Quill JSON: $e");
    }
  }

  Future<bool> _tryLoadAndRestoreDraft() async {
    setState(() => _isLoading = true);
    bool restored = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftString = prefs.getString(_draftKey);

      if (draftString != null && draftString.isNotEmpty) {
        debugPrint("Borrador Quill encontrado para $_draftKey");
        final draftData = jsonDecode(draftString) as Map<String, dynamic>?;

        if (draftData != null && mounted) {
          final bool? restoreChoice = await showDialog<bool>( /* ... diálogo sin cambios ... */ 
             context: context,
             barrierDismissible: false, 
             builder: (context) => AlertDialog(
              title: const Text('Restaurar Borrador?'),
              content: const Text('Encontramos alterações não salvas. Deseja restaurá-las?'),
              actions: [
                TextButton( child: const Text('Descartar Borrador'), onPressed: () => Navigator.of(context).pop(false) ),
                ElevatedButton( child: const Text('Restaurar'), onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white) ),
              ],
            ),
          );

          if (restoreChoice == true) {
            Document restoredDocument;
            try {
              final contentJson = draftData['elements'] as List<dynamic>?; // Quill Delta es una Lista
              if (contentJson != null) {
                restoredDocument = Document.fromJson(contentJson);
                print("Documento Quill restaurado desde borrador JSON.");
              } else {
                 print("WARN: Contenido del borrador ('elements') no es una lista. Creando documento vacío.");
                 restoredDocument = Document();
              }
            } catch (e) {
               print("Error restaurando Quill desde borrador JSON: $e. Usando documento vacío.");
               restoredDocument = Document();
            }
            
            // Actualizar el documento del controlador EXISTENTE
            _quillController.document = restoredDocument; 
            _quillController.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local); 

            // Actualizar estado de la UI
            setState(() {
              _titleController.text = draftData['title'] ?? '';
              _cardDisplayType = draftData['cardDisplayType'] ?? 'icon';
              _cardImageUrl = draftData['cardImageUrl'];
              _cardIconName = draftData['cardIconName'] ?? 'article_outlined';
              _selectedCardImageFile = null;
              _hasUnsavedChanges = true;
              debugPrint("Borrador Quill restaurado en controlador existente.");
            });
            await _clearDraft();
            restored = true;
          } else {
             await _clearDraft(); 
          }
        }
      }
    } catch (e) {
      debugPrint("Error cargando/restaurando borrador Quill JSON: $e");
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
    return restored;
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      debugPrint("Borrador Quill limpiado para $_draftKey");
    } catch (e) {
      debugPrint("Error limpiando borrador: $e");
    }
  }
  // --- Fin Lógica de Borradores ---

  Future<void> _loadPageData() async {
    if (widget.pageId == null) return;

    final bool didRestore = await _tryLoadAndRestoreDraft();
    if (didRestore) return;
    
    setState(() => _isLoading = true);
    Document loadedDocument = Document(); // Inicializar como documento Quill vacío
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pageContent')
          .doc(widget.pageId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _titleController.text = data['title'] ?? '';
        _cardDisplayType = data['cardDisplayType'] as String? ?? 'icon';
        _cardImageUrl = data['cardImageUrl'] as String?;
        _cardIconName = data['cardIconName'] as String? ?? 'article_outlined';
        _selectedCardImageFile = null;
        _isUploadingCardImage = false;

        // Cargar contenido de 'elements' como JSON Delta
        final elementsData = data['elements']; 
        if (elementsData is List) { // Quill Delta es una Lista
          try { 
            // Intentar parsear como JSON Delta
            loadedDocument = Document.fromJson(elementsData.cast<Map<String, dynamic>>());
            print("Documento Quill cargado desde Firestore JSON.");
          } catch (e) { 
            print("ERROR: El campo 'elements' (Lista) no pudo ser parseado por Quill: $e. Usando documento vacío.");
            loadedDocument = Document()..insert(0, "[Contenido no pudo ser cargado]"); // Mostrar error en editor
          }
        } else if (elementsData is String && elementsData.isNotEmpty) {
            // Si es texto plano (dato antiguo), lo insertamos
            print("WARN: El campo 'elements' era String, insertando como texto plano.");
            loadedDocument = Document()..insert(0, elementsData);
        } else {
           print("WARN: El campo 'elements' no es Lista ni String, o está vacío. Usando documento vacío.");
           loadedDocument = Document(); // Documento vacío por defecto
        }
        
      } else {
        print("Documento no encontrado en Firestore (ID: ${widget.pageId}). Inicializando vacío.");
         _titleController.clear();
         _cardDisplayType = 'icon'; _cardIconName = 'article_outlined'; _cardImageUrl = null;
         loadedDocument = Document();
      }
      
      if (mounted) {
         _quillController.document = loadedDocument; // Cargar el documento preparado
         _quillController.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local); // Resetear selección
         setState(() { 
           _hasUnsavedChanges = false; // Marcar como no cambiado después de cargar
         });
      }

    } catch (e) {
      debugPrint('Error cargando datos de la página desde Firestore: $e');
      if (mounted) {
        _titleController.clear();
        _quillController.document = Document(); // Resetear a vacío en caso de error
        _quillController.updateSelection(const TextSelection.collapsed(offset: 0), ChangeSource.local);
        _hasUnsavedChanges = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar página: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } 
  } 
  
  // Suscribirse a cambios (Restaurado)
  void _subscribeToChanges() {
    _changeSubscription?.cancel(); 
    _changeSubscription = _quillController.document.changes.listen((_) { 
      _markAsChanged();
    });
  }
  
  // Marcar que hay cambios sin guardar
  void _markAsChanged() {
     if (!_hasUnsavedChanges && mounted) { 
       setState(() { _hasUnsavedChanges = true; });
     }
  }

  // --- Lógica de subida de imagen para la TARJETA (sin cambios) ---
  Future<void> _pickAndUploadCardImage() async { /* ... sin cambios ... */ 
     final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
    if (image == null) return;
    setState(() { _isUploadingCardImage = true; _selectedCardImageFile = File(image.path); _cardImageUrl = null; _markAsChanged(); });

    try {
      final fileName = 'pageCard_${widget.pageId ?? _uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedImage = await _imageService.compressImage(_selectedCardImageFile!, quality: 80);
      final fileToUpload = compressedImage ?? _selectedCardImageFile!;
      final storageRef = _storage.ref().child('page_card_images').child(fileName); 
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = storageRef.putFile(fileToUpload, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() { _cardImageUrl = downloadUrl; _selectedCardImageFile = null; _isUploadingCardImage = false; });
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Imagem da capa carregada!'), backgroundColor: Colors.green) );
      }
    } catch (e) {
      debugPrint('Error al subir imagen de capa: $e');
      if (mounted) {
        setState(() { _selectedCardImageFile = null; _isUploadingCardImage = false; });
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao carregar imagem da capa: $e'), backgroundColor: Colors.red) );
      }
    } 
  } 
  // --- Fin lógica tarjeta ---

  // Guardar la página (Necesita adaptarse a Quill)
  void _savePage() async {
    // Validar título 
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Por favor, insira um título para a página.'), backgroundColor: Colors.red) );
      return; 
    }
    // Validaciones de la tarjeta 
    if (_cardDisplayType == 'icon' && _cardIconName.isEmpty) { 
      // Añadir SnackBar para feedback
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Por favor, selecione um ícone para a página.'), backgroundColor: Colors.red) );
      return; 
    }
    if (_cardDisplayType == 'image' && _cardImageUrl == null) { 
      // Añadir SnackBar para feedback
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Por favor, carregue uma imagem para a capa.'), backgroundColor: Colors.red) );
      return; 
    }

    // Si pasa las validaciones, debería continuar...
    setState(() => _isLoading = true); 

    List<dynamic>? contentJson; 
    try {
      contentJson = _quillController.document.toDelta().toJson();
      debugPrint("✅ Contenido Quill Delta serializado para guardar.");
    } catch (e) {
      print("❌ Error serializando contenido Quill Delta: $e");
      if (mounted) { /* ... */ }
      setState(() => _isLoading = false); 
      return; 
    }

    // --- Construcción Condicional de pageData ---
    final pageData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'elements': contentJson,
      'lastUpdatedAt': FieldValue.serverTimestamp(), 
      'cardDisplayType': _cardDisplayType,
    };

    if (_cardDisplayType == 'icon') {
      pageData['cardIconName'] = _cardIconName; 
    } else if (_cardDisplayType == 'image' && _cardImageUrl != null) {
      pageData['cardImageUrl'] = _cardImageUrl;
    }
    // --- Fin Construcción Condicional ---

    try {
      debugPrint("💾 Intentando guardar pageData (Quill) para ID: ${widget.pageId ?? 'nuevo'}");
      debugPrint("💾 Datos a guardar: $pageData"); // Imprimir datos
      
      if (widget.pageId == null) {
        // Crear nuevo: usa el pageData construido sin FieldValue.delete()
        await FirebaseFirestore.instance.collection('pageContent').add(pageData);
        debugPrint("✅ Página nueva (Quill) creada.");
      } else {
        // Actualizar existente: podemos añadir FieldValue.delete() explícitamente si es necesario
        // para limpiar campos al cambiar de tipo de tarjeta.
        final updateData = Map<String, dynamic>.from(pageData); // Copiar datos base
        if (_cardDisplayType == 'icon') {
          updateData['cardImageUrl'] = FieldValue.delete(); // Asegurar que se borra el campo imagen
        } else if (_cardDisplayType == 'image') {
          updateData['cardIconName'] = FieldValue.delete(); // Asegurar que se borra el campo icono
        }
        debugPrint("💾 Datos para actualizar: $updateData"); // Imprimir datos de actualización
        await FirebaseFirestore.instance.collection('pageContent').doc(widget.pageId).update(updateData);
        debugPrint("✅ Página existente (Quill) actualizada.");
      }
      
      if (mounted) {
         await _clearDraft(); 
         debugPrint("💾 Borrador limpiado después de guardar.");
         debugPrint("💾 Intentando establecer _hasUnsavedChanges = false");
         setState(() { _hasUnsavedChanges = false; }); 
         debugPrint("💾 Estado _hasUnsavedChanges debería ser false ahora: $_hasUnsavedChanges");
         ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Página salva com sucesso!'), backgroundColor: Colors.green) );
         debugPrint("💾 Navegando hacia atrás...");
         Navigator.pop(context); 
      }
    } catch (e) { 
       debugPrint('❌ Error al guardar la página (Quill) en Firestore: $e');
       if (mounted) { 
         ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao salvar página: $e'), backgroundColor: Colors.red) );
       }
    } 
    finally { 
       if (mounted) {
        setState(() => _isLoading = false);
      }
    } 
  } 

  // --- Diálogo de confirmación para salir (sin cambios) ---
  Future<bool> _showExitConfirmDialog() async { /* ... sin cambios ... */ 
    debugPrint("🚪 Verificando salida: _hasUnsavedChanges = $_hasUnsavedChanges"); 
    if (!_hasUnsavedChanges) return true;
     final bool? shouldDiscard = await showDialog<bool>( 
        context: context,
        builder: (context) => AlertDialog(
           title: const Text('Descartar Alterações?'),
           content: const Text('Você tem alterações não salvas. Deseja sair mesmo assim?'),
           actions: <Widget>[
              TextButton( child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop(false) ),
              TextButton( child: const Text('Descartar e Sair', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true) ),
           ],
        ),
     );
     if (shouldDiscard == true) { await _clearDraft(); }
     return shouldDiscard ?? false;
  } 

  // --- NUEVO: Listener para el foco del editor ---
  void _onFocusChange() {
    if (_editorFocusNode.hasFocus) {
      // Esperar un poco a que el teclado aparezca antes de hacer scroll
      Future.delayed(const Duration(milliseconds: 300), () {
        // Asegurarse de que el widget aún está montado
        if (mounted && _editorFocusNode.context != null) {
          Scrollable.ensureVisible(
            _editorFocusNode.context!,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: 0.0, // Intentar alinear al borde superior
          );
        }
      });
    }
  }
  // --- Fin Listener ---

  @override
  Widget build(BuildContext context) {
    // Añadir print aquí para ver el estado en cada build
    debugPrint("🔄 Build method: _isLoading = $_isLoading"); 
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldPop = await _showExitConfirmDialog();
        if (shouldPop && mounted) { Navigator.pop(context); }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pageId == null ? 'Criar Nova Página' : 'Editar Página'),
          flexibleSpace: Container( decoration: BoxDecoration( gradient: LinearGradient( colors: [ AppColors.primary, AppColors.primary.withOpacity(0.7) ] ) ) ),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(Icons.save),
              // Añadir print aquí para ver si la lambda se ejecuta
              onPressed: _isLoading ? null : () { 
                debugPrint("🔘 Botón Salvar Pulsado! Llamando a _savePage...");
                _savePage(); 
              },
              tooltip: 'Salvar Página',
            ),
          ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                controller: _scrollController, // <--- Asignar controller
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, 
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration( labelText: 'Título da Página', border: OutlineInputBorder(), hintText: 'Ex: Sobre Nós', ),
                        onChanged: (_) => _markAsChanged(), 
                      ),
                      const SizedBox(height: 24),
                      Text( 'Aparência na Lista de Páginas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16), decoration: BoxDecoration( border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50, ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [ 
                            DropdownButtonFormField<String>( value: _cardDisplayType, isExpanded: true, items: const [ DropdownMenuItem(value: 'icon', child: Text('Ícone e Título', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'image', child: Text('Imagem de Capa (16:9)', overflow: TextOverflow.ellipsis)), ], onChanged: (value) { if (value != null && value != _cardDisplayType) { setState(() { _cardDisplayType = value; }); _markAsChanged(); } }, decoration: const InputDecoration( labelText: 'Tipo de Visualização na Lista', border: OutlineInputBorder(), isDense: true, ), ),
                            const SizedBox(height: 16),
                            if (_cardDisplayType == 'icon') ...[ DropdownButtonFormField<String>( value: _cardIconName, items: IconUtils.getAvailableIconNames().map((name) { return DropdownMenuItem( value: name, child: Row( children: [ Icon(IconUtils.getIconDataFromString(name), size: 20), const SizedBox(width: 10), Text(name), ], ), ); }).toList(), onChanged: (value) { if (value != null && value != _cardIconName) { setState(() { _cardIconName = value; }); _markAsChanged(); } }, decoration: const InputDecoration( labelText: 'Ícone', border: OutlineInputBorder(), isDense: true, ), isExpanded: true, ), ] else ...[ const Text('Imagem de Capa (16:9)', style: TextStyle(fontWeight: FontWeight.w500)), const SizedBox(height: 8), AspectRatio( aspectRatio: 16 / 9, child: Container( decoration: BoxDecoration( border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4), color: Colors.grey.shade200, ), child: Stack( alignment: Alignment.center, children: [ if (_selectedCardImageFile != null) Image.file(_selectedCardImageFile!, fit: BoxFit.cover) else if (_cardImageUrl != null) Image.network(_cardImageUrl!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey, size: 30), loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) return child; return const Center(child: CircularProgressIndicator(strokeWidth: 2)); }, ) else const Icon(Icons.image_search, size: 40, color: Colors.grey), if (_isUploadingCardImage) Container( color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.white)), ), ], ), ), ), const SizedBox(height: 8), Center( child: OutlinedButton.icon( icon: const Icon(Icons.upload_file, size: 18), label: Text(_cardImageUrl != null ? 'Trocar Imagem' : 'Selecionar Imagem'), onPressed: _isUploadingCardImage ? null : _pickAndUploadCardImage, ), ), ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text( 'Conteúdo da Página', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ),
                      const SizedBox(height: 8),
                      SizedBox( 
                        height: 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            QuillSimpleToolbar(
                              controller: _quillController, 
                              config: QuillSimpleToolbarConfig(
                                showBoldButton: true,
                                showItalicButton: true,
                                showUnderLineButton: true, 
                                showStrikeThrough: false,
                                showInlineCode: false,
                                showColorButton: true,
                                showBackgroundColorButton: true,
                                showClearFormat: true,
                                showHeaderStyle: true, 
                                showListNumbers: true,
                                showListBullets: true,
                                showListCheck: false, 
                                showCodeBlock: false,
                                showQuote: true,
                                showIndent: true, 
                                showLink: true,
                                showSearchButton: false,
                                embedButtons: FlutterQuillEmbeds.toolbarButtons(
                                  imageButtonOptions: QuillToolbarImageButtonOptions(
                                    imageButtonConfig: QuillToolbarImageConfig(
                                      onRequestPickImage: (context) async {
                                        final image = await _picker.pickImage(source: ImageSource.gallery);
                                        return image?.path;
                                      },
                                      onImageInsertCallback: (String imagePath, QuillController controller) async {
                                        final imageUrl = await _uploadEditorImageCallback(context, File(imagePath));
                                        if (imageUrl != null) {
                                          final index = controller.selection.baseOffset;
                                          final length = controller.selection.extentOffset - index;
                                          controller.replaceText(
                                            index, length, BlockEmbed.image(imageUrl), null
                                          );
                                          controller.updateSelection(
                                            TextSelection.collapsed(offset: index + 1),
                                            ChangeSource.remote
                                          );
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Falha ao carregar imagem.'), backgroundColor: Colors.red)
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    tooltip: 'Inserir Imagem',
                                  ),
                                ),
                                buttonOptions: QuillSimpleToolbarButtonOptions(
                                  base: QuillToolbarBaseButtonOptions(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: QuillEditor.basic(
                                  controller: _quillController,
                                  focusNode: _editorFocusNode,
                                  scrollController: ScrollController(), // Editor tiene su propio scroll interno
                                  config: QuillEditorConfig(
                                    padding: const EdgeInsets.all(12),
                                    placeholder: 'Digite o conteúdo da página aqui...',
                                    expands: true, 
                                    embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
} 