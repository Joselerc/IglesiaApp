import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/loading_indicator.dart';

// --- Clase auxiliar interna para manejar estado de edición de miembros --- 
class _FeaturedMemberEditState {
  final String userId;
  final String name;
  final String photoUrl;
  bool isFeatured;
  String currentInfoDeltaJson; // JSON actual del editor para customInfo

  _FeaturedMemberEditState({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.isFeatured,
    required this.currentInfoDeltaJson,
  });

  // Convertir a mapa para guardar en Firestore
  Map<String, dynamic> toMapForFirestore() {
    dynamic customInfoDecoded;
    try {
      customInfoDecoded = currentInfoDeltaJson.isNotEmpty ? jsonDecode(currentInfoDeltaJson) : null;
    } catch (e) {
      print("Error decodificando Delta JSON de miembro destacado: $e");
      customInfoDecoded = {'insert': 'Erro ao salvar info.\n'};
    }
    return {
      'userId': userId,
      'customInfo': customInfoDecoded,
    };
  }
}
// --- Fin clase auxiliar --- 

// --- Modal simple para editar Delta JSON (reutilizado) --- 
class DeltaEditorModal extends StatefulWidget {
  final String? initialContentJson;
  final String title;

  const DeltaEditorModal({super.key, this.initialContentJson, this.title = 'Editar Conteúdo'});

  @override
  State<DeltaEditorModal> createState() => _DeltaEditorModalState();
}

class _DeltaEditorModalState extends State<DeltaEditorModal> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialContent();
  }

  void _loadInitialContent() {
    Document document;
    if (widget.initialContentJson != null && widget.initialContentJson!.isNotEmpty) {
      try {
        document = Document.fromJson(jsonDecode(widget.initialContentJson!));
      } catch (e) {
        print("Error decodificando JSON para DeltaEditorModal: $e");
        document = Document()..insert(0, widget.initialContentJson!); // Fallback a texto plano
      }
    } else {
      document = Document();
    }
    _controller = QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check), // Icono de check
            tooltip: 'Confirmar',
            onPressed: () {
              final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
              Navigator.pop(context, deltaJson); // Devolver el JSON
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showHeaderStyle: true,
                showListBullets: true,
                showListNumbers: true,
                showQuote: true,
                showIndent: true,
                showLink: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showClearFormat: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
                config: const QuillEditorConfig(
                  padding: EdgeInsets.zero,
                  autoFocus: true, // Enfocar al abrir este modal simple
                  placeholder: 'Digite o conteúdo aqui...',
                  expands: false,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
// --- Fin DeltaEditorModal --- 


// --- Pantalla Principal de Edición (antes RichTextEditorModal) --- 
enum EntityType { ministry, group } // Mover Enum aquí si no está global

class EditEntityInfoModal extends StatefulWidget {
  final String entityId;
  final EntityType entityType;

  const EditEntityInfoModal({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  State<EditEntityInfoModal> createState() => _EditEntityInfoModalState();
}

class _EditEntityInfoModalState extends State<EditEntityInfoModal> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Estado para descripción principal
  QuillController? _descriptionController;

  // Estado para sección destacada
  bool _showFeaturedSection = false;
  final TextEditingController _featuredTitleController = TextEditingController();
  List<_FeaturedMemberEditState> _membersStateList = [];

  String get _collectionPath => widget.entityType == EntityType.ministry ? 'ministries' : 'groups';
  String get _entityTypeName => widget.entityType == EntityType.ministry ? 'Ministério' : 'Grupo';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _descriptionController?.dispose();
    _featuredTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    _errorMessage = null;
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection(_collectionPath).doc(widget.entityId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        throw Exception('$_entityTypeName não encontrado.');
      }
      final data = docSnapshot.data()!;

      // Cargar estado de sección destacada
      _showFeaturedSection = data['showFeaturedMembersSection'] as bool? ?? false;
      _featuredTitleController.text = data['featuredMembersSectionTitle'] as String? ?? '';
      
      // Cargar miembros y estado de destacados
      await _loadAndPrepareMembersState(data);

      // Cargar descripción principal
      _initializeDescriptionController(data['descriptionDelta']);

      setState(() => _isLoading = false);

    } catch (e) {
      print("Error cargando datos para edición: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Erro ao carregar dados: ${e.toString()}";
      });
    }
  }
  
  // Carga miembros y prepara el estado de edición para destacados
  Future<void> _loadAndPrepareMembersState(Map<String, dynamic> data) async {
     final List<dynamic> featuredMembersData = data['featuredMembers'] as List<dynamic>? ?? [];
     final List<String> currentMemberIds = _getMemberIdsFromData(data);
     final allMembersDocs = await _loadMembersFromIds(currentMemberIds);
      
      List<_FeaturedMemberEditState> tempEditList = [];
      for (var memberDoc in allMembersDocs) {
        final userId = memberDoc.id;
        final userData = memberDoc.data() as Map<String, dynamic>; 
        final name = userData['name'] ?? userData['displayName'] ?? 'Usuário Desconhecido';
        final photoUrl = userData['photoUrl'] as String? ?? '';

        final featuredData = featuredMembersData.firstWhere(
          (fm) => fm is Map && fm['userId'] == userId,
          orElse: () => null,
        ) as Map<String, dynamic>?;

        String initialInfoJson = '';
        if (featuredData != null && featuredData['customInfo'] != null) {
          try {
            if (featuredData['customInfo'] is Map || featuredData['customInfo'] is List) {
               initialInfoJson = jsonEncode(featuredData['customInfo']);
            } else { print("WARN: customInfo (load) para $userId no es JSON."); }
          } catch (e) { print("Error codificando customInfo (load) para $userId: $e"); }
        }
        
        tempEditList.add(_FeaturedMemberEditState(
          userId: userId,
          name: name,
          photoUrl: photoUrl,
          isFeatured: featuredData != null,
          currentInfoDeltaJson: initialInfoJson,
        ));
      }

      tempEditList.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      _membersStateList = tempEditList; // Asignar directamente, setState se llama en _loadInitialData
  }

  // Inicializa controlador Quill para descripción principal
  void _initializeDescriptionController(dynamic descriptionData) {
    Document document;
    if (descriptionData is List || descriptionData is Map) { 
      try {
        final List<dynamic> deltaList = descriptionData is List ? descriptionData : [descriptionData];
        document = Document.fromJson(deltaList);
      } catch (e) {
        print('Error parseando descriptionDelta: $e');
        document = Document()..insert(0, '(Erro ao carregar)');
      }
    } else if (descriptionData is String && descriptionData.isNotEmpty) {
       document = Document()..insert(0, descriptionData);
    } else {
      document = Document(); 
    }
    _descriptionController = QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
    // No ponemos readOnly=true aquí porque es la pantalla de edición
  }

  // Edita info de miembro destacado abriendo DeltaEditorModal
  Future<void> _editMemberInfo(_FeaturedMemberEditState memberState) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => DeltaEditorModal(
          title: 'Editar Info: ${memberState.name}',
          initialContentJson: memberState.currentInfoDeltaJson,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      setState(() { memberState.currentInfoDeltaJson = result; });
    }
  }

  // Guarda TODOS los cambios
  Future<void> _saveAllChanges() async {
    setState(() => _isSaving = true);
    final descriptionDeltaJson = jsonDecode(jsonEncode(_descriptionController?.document.toDelta().toJson() ?? []));
    final featuredTitle = _featuredTitleController.text.trim();
    final featuredMembersToSave = _membersStateList
        .where((state) => state.isFeatured)
        .map((state) => state.toMapForFirestore())
        .toList();

    try {
      await FirebaseFirestore.instance.collection(_collectionPath).doc(widget.entityId).update({
        'descriptionDelta': descriptionDeltaJson,
        'showFeaturedMembersSection': _showFeaturedSection,
        'featuredMembersSectionTitle': _showFeaturedSection ? featuredTitle : FieldValue.delete(),
        'featuredMembers': _showFeaturedSection ? featuredMembersToSave : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(), // Marcar actualización
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informações salvas com sucesso!')));
        Navigator.pop(context); // Cerrar modal
      }
    } catch (e) {
      print("Error guardando todo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar informações.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Helpers para obtener IDs (adaptados)
  List<String> _getMemberIdsFromData(Map<String, dynamic> data) {
    List<String> memberIds = [];
    final membersField = data['members'];
    if (membersField is List) {
      memberIds = membersField.whereType<DocumentReference>().map((ref) => ref.id).toList();
    }
    return memberIds;
  }
  
  Future<List<DocumentSnapshot>> _loadMembersFromIds(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    List<DocumentSnapshot> memberDocs = [];
    for (String memberId in memberIds) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (doc.exists) memberDocs.add(doc);
      } catch (e) { print('Error loading member $memberId: $e'); }
    }
    return memberDocs;
  }
  // -- Fin Helpers --

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Informações do $_entityTypeName'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          _isSaving 
            ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))) 
            : IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Salvar Tudo',
                onPressed: _isLoading ? null : _saveAllChanges,
              )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: LoadingIndicator());
    if (_errorMessage != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))));
    if (_descriptionController == null) return const Center(child: Text('Erro ao inicializar editor.')); // Control extra

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Sección Miembros Destacados --- 
              Text('Seção "Membros em Destaque"' , style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Mostrar esta seção?', style: AppTextStyles.bodyText1),
                value: _showFeaturedSection,
                onChanged: (value) => setState(() => _showFeaturedSection = value),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_showFeaturedSection) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _featuredTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da Seção',
                    hintText: 'Ex: Liderança, Contatos...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecione membros para destacar e edite suas informações:',
                  style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildFeaturedMembersList(), // Widget para la lista de miembros
              ],
              const Divider(height: 32, thickness: 1),
              // --- Sección Descripción Principal --- 
              Text('Descrição Principal do $_entityTypeName', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Barra de herramientas descripción principal
              QuillSimpleToolbar(
                controller: _descriptionController!, // Usar el controller principal
                config: const QuillSimpleToolbarConfig(
                  showBoldButton: true,
                  showItalicButton: true,
                  showHeaderStyle: true,
                  showListBullets: true,
                  showListNumbers: true,
                  showQuote: true,
                  showIndent: true,
                  showLink: true,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showClearFormat: true,
                ),
              ),
              const Divider(height: 1),
              // Editor descripción principal
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(minHeight: 200), // Darle altura mínima
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: QuillEditor.basic(
                    controller: _descriptionController!, 
                    focusNode: FocusNode(), // Un focus node propio para este editor
                    config: const QuillEditorConfig(
                      padding: EdgeInsets.zero,
                      autoFocus: false,
                      placeholder: 'Digite a descrição principal aqui...',
                      expands: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget que construye la lista de miembros para destacar
  Widget _buildFeaturedMembersList() {
    if (_membersStateList.isEmpty) return const Text('Nenhum membro encontrado neste grupo/ministério.');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _membersStateList.length,
      itemBuilder: (context, index) {
        final memberState = _membersStateList[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              CheckboxListTile(
                title: Row(children: [
                  CircleAvatar(radius: 18, backgroundImage: memberState.photoUrl.isNotEmpty ? NetworkImage(memberState.photoUrl) : null, child: memberState.photoUrl.isEmpty ? const Icon(Icons.person, size: 18) : null,),
                  const SizedBox(width: 12),
                  Expanded(child: Text(memberState.name, style: AppTextStyles.bodyText1, overflow: TextOverflow.ellipsis,))
                ]),
                value: memberState.isFeatured,
                onChanged: (value) => setState(() { 
                  memberState.isFeatured = value ?? false; 
                   _membersStateList.sort((a, b) { if (a.isFeatured && !b.isFeatured) return -1; if (!a.isFeatured && b.isFeatured) return 1; return a.name.toLowerCase().compareTo(b.name.toLowerCase()); });
                }),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                dense: true,
              ),
              if (memberState.isFeatured) ...[
                const Divider(height: 0, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 50, right: 8, bottom: 4),
                  child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(_getPreviewText(memberState.currentInfoDeltaJson), style: AppTextStyles.caption.copyWith(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Editar Info'),
                      onPressed: () => _editMemberInfo(memberState),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), textStyle: AppTextStyles.caption),
                    ),
                  ]),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  // Obtener texto preview de JSON Delta
  String _getPreviewText(String deltaJson) {
    if (deltaJson.isEmpty) return '(Sem info adicional)';
    try {
      final doc = Document.fromJson(jsonDecode(deltaJson));
      final text = doc.toPlainText().trim().replaceAll('\n', ' ');
      return text.isNotEmpty ? text : '(Info definida)';
    } catch (e) { return '(Erro ao ler info)'; }
  }
} 