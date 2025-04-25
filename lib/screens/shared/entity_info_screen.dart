import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text; // Esconder Text de flutter_quill
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/loading_indicator.dart'; // Corregida ruta
// import '../../widgets/user_avatar.dart'; // No encontrado

// Enum para definir el tipo de entidad
enum EntityType { ministry, group }

// Modelo auxiliar para la información de miembros destacados
class _FeaturedMemberInfo {
  final String userId;
  final String name;
  final String photoUrl;
  final String customInfoDeltaJson; // Info como JSON
  QuillController? infoController; // Controlador para renderizar customInfo

  _FeaturedMemberInfo({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.customInfoDeltaJson,
  }) {
    // Inicializar controlador aquí
    _initializeController();
  }

  void _initializeController() {
    Document document;
    if (customInfoDeltaJson.isNotEmpty) {
      try {
        document = Document.fromJson(jsonDecode(customInfoDeltaJson));
      } catch (e) {
        print('Error parsing customInfo for $userId: $e');
        document = Document()..insert(0, '(Erro ao carregar info)');
      }
    } else {
      document = Document(); // Vacío si no hay info
    }
    infoController = QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
    infoController?.readOnly = true; // Asegurar solo lectura
  }
  
  // Método para liberar el controlador
  void dispose() {
    infoController?.dispose();
  }
}

class EntityInfoScreen extends StatefulWidget {
  final String entityId;
  final EntityType entityType;

  const EntityInfoScreen({
    super.key,
    required this.entityId,
    required this.entityType,
  });

  @override
  State<EntityInfoScreen> createState() => _EntityInfoScreenState();
}

class _EntityInfoScreenState extends State<EntityInfoScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _entityData;
  List<_FeaturedMemberInfo> _featuredMembersInfo = [];
  QuillController? _descriptionController;
  String _descriptionSectionTitle = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController?.dispose();
    // Liberar controladores de miembros destacados
    for (var member in _featuredMembersInfo) {
      member.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final collectionPath = widget.entityType == EntityType.ministry ? 'ministries' : 'groups';
      final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(widget.entityId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        throw Exception('${_entityTypeName()} não encontrado.');
      }

      _entityData = docSnapshot.data()!;

      // Extraer datos básicos
      final name = _entityData!['name'] as String? ?? 'Nome não definido';
      final imageUrl = _entityData!['imageUrl'] as String? ?? '';

      // Extraer configuración de miembros destacados
      final showFeaturedSection = _entityData!['showFeaturedMembersSection'] as bool? ?? false;
      final featuredSectionTitle = _entityData!['featuredMembersSectionTitle'] as String? ?? '';
      final List<dynamic> featuredMembersData = _entityData!['featuredMembers'] as List<dynamic>? ?? [];

      // Cargar miembros destacados si la sección está activa
      List<_FeaturedMemberInfo> tempFeaturedList = [];
      if (showFeaturedSection && featuredMembersData.isNotEmpty) {
        for (var memberMap in featuredMembersData) {
          if (memberMap is Map) {
            final userId = memberMap['userId'] as String?;
            final customInfoData = memberMap['customInfo']; // Puede ser Mapa/Lista o null
            
            if (userId != null) {
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                final name = userData['name'] ?? userData['displayName'] ?? 'Usuário Desconhecido';
                final photoUrl = userData['photoUrl'] as String? ?? '';
                
                // Convertir customInfo a JSON String
                String customInfoJson = '';
                if (customInfoData != null) {
                  try {
                    if (customInfoData is Map || customInfoData is List) {
                      customInfoJson = jsonEncode(customInfoData);
                    } else {
                      print("WARN: customInfo para $userId no es un mapa/lista JSON válido.");
                    }
                  } catch (e) {
                    print("Error encoding customInfo for $userId: $e");
                  }
                }

                tempFeaturedList.add(_FeaturedMemberInfo(
                  userId: userId,
                  name: name,
                  photoUrl: photoUrl,
                  customInfoDeltaJson: customInfoJson,
                ));
              } else {
                 print("WARN: Usuario destacado $userId no encontrado.");
              }
            } else {
               print("WARN: Miembro destacado sin userId.");
            }
          } else {
             print("WARN: Formato inesperado en lista featuredMembers.");
          }
        }
      }
      // Liberar controladores antiguos antes de asignar la nueva lista
      for (var oldMember in _featuredMembersInfo) { oldMember.dispose(); }
      _featuredMembersInfo = tempFeaturedList;

      // Cargar título de descripción
      _descriptionSectionTitle = _entityData!['descriptionSectionTitle'] as String? ?? '';

      // Inicializar controlador de descripción principal
      _initializeDescriptionController(_entityData!['descriptionDelta']);

      setState(() => _isLoading = false);

    } catch (e) {
      print("Error cargando datos en EntityInfoScreen: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Erro ao carregar informações: ${e.toString()}";
      });
    }
  }

  void _initializeDescriptionController(dynamic descriptionData) {
    Document document;
    if (descriptionData is List || descriptionData is Map) { // Quill Delta es List<Map>
      try {
        // Asegurarse que es una lista antes de fromJson
        final List<dynamic> deltaList = descriptionData is List ? descriptionData : [descriptionData];
        document = Document.fromJson(deltaList);
      } catch (e) {
        print('Error parseando descriptionDelta: $e');
        document = Document()..insert(0, '(Erro ao carregar descrição)');
      }
    } else if (descriptionData is String && descriptionData.isNotEmpty) {
       // Compatibilidad con descripción antigua (texto plano)
      document = Document()..insert(0, descriptionData);
    } else {
      document = Document(); // Vacío si no hay descripción
    }

    if (_descriptionController == null) {
       _descriptionController = QuillController(document: document, selection: const TextSelection.collapsed(offset: 0));
    } else {
       if (_descriptionController!.document.toDelta() != document.toDelta()) {
          _descriptionController!.document = document;
       }
    }
    _descriptionController?.readOnly = true; // Siempre solo lectura aquí
  }

  String _entityTypeName() => widget.entityType == EntityType.ministry ? 'Ministério' : 'Grupo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Carregando...' : _entityData!['name'] as String? ?? 'Nome não definido'), // Mostrar nombre en AppBar
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator( // Añadir RefreshIndicator por si acaso
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 32.0),
                    children: [
                      // --- Sección Miembros Destacados --- 
                      if (_entityData!['showFeaturedMembersSection'] == true && _featuredMembersInfo.isNotEmpty) ...[
                        _buildFeaturedMembersSection(),
                        const SizedBox(height: 16),
                      ],
                      // --- Sección Descripción Principal --- 
                      _buildDescriptionSection(),
                    ],
                  ),
                ),
    );
  }

  // --- Widget para la sección de miembros destacados --- 
  Widget _buildFeaturedMembersSection() {
    final String title = _entityData!['featuredMembersSectionTitle'] as String? ?? 'Miembros Destacados';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _featuredMembersInfo.length,
          itemBuilder: (context, index) {
            final member = _featuredMembersInfo[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila con Avatar y Nombre
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: member.photoUrl.isNotEmpty ? NetworkImage(member.photoUrl) : null,
                          child: member.photoUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            member.name,
                            style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 1), // Línea divisoria
                    // Info personalizada (Editor Quill)
                    if (member.infoController != null)
                      SizedBox(
                        width: double.infinity, // Ocupar ancho
                        child: QuillEditor.basic(
                          controller: member.infoController!, // El controlador ya está en modo readOnly
                          config: const QuillEditorConfig(
                            padding: EdgeInsets.zero,
                            autoFocus: false,
                            expands: false,
                          ),
                        ),
                      )
                    else
                      const Text('(Sem info adicional)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  // --- Widget para la sección de descripción principal ---
  Widget _buildDescriptionSection() {
    if (_descriptionController == null || _descriptionController!.document.isEmpty()) {
      if (_descriptionSectionTitle.isNotEmpty) {
         return Padding(
           padding: const EdgeInsets.only(bottom: 12.0),
           child: Text(_descriptionSectionTitle, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
         );
      } else {
         return const Padding( padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text('Sem descrição principal.', style: TextStyle(color: Colors.grey))), );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_descriptionSectionTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(_descriptionSectionTitle, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
          ),
        Container(
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco para el editor
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: QuillEditor.basic(
            controller: _descriptionController!, // Ya está en modo readOnly
            config: const QuillEditorConfig(
              padding: EdgeInsets.zero,
              autoFocus: false,
              expands: false,
            ),
          ),
        ),
      ],
    );
  }
} 