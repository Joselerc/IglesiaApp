import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text; // Quill para visualización
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'; // Para embeds
import 'package:url_launcher/url_launcher.dart'; // Para abrir enlaces
import '../../theme/app_colors.dart'; // Tu AppColors
import 'dart:convert';

class DynamicPageViewScreen extends StatefulWidget {
  final String pageId;
  const DynamicPageViewScreen({super.key, required this.pageId});
  @override
  State<DynamicPageViewScreen> createState() => _DynamicPageViewScreenState();
}

class _DynamicPageViewScreenState extends State<DynamicPageViewScreen> {
  QuillController? _controller; // Controlador Quill
  bool _isLoading = true;
  String _pageTitle = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadPageContent(); // Cambiado para cargar contenido completo
  }

  @override
  void dispose() {
    _controller?.dispose(); // Dispose del controlador Quill
    super.dispose();
  }

  Future<void> _loadPageContent() async { // Renombrado y modificado
    setState(() {
      _isLoading = true;
      _pageTitle = 'Carregando...';
      _controller = null; // Resetear controlador
    });

    String loadedTitle = 'Página';
    Document loadedDocument = Document(); // Documento Quill vacío por defecto

    try {
      final doc = await FirebaseFirestore.instance
          .collection('pageContent')
          .doc(widget.pageId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        loadedTitle = data['title'] ?? 'Página sem título';
        
        // Cargar contenido de 'elements' como JSON Delta
        final elementsData = data['elements']; 
        if (elementsData is List) { // Quill Delta es una Lista
          try { 
            loadedDocument = Document.fromJson(elementsData.cast<Map<String, dynamic>>());
            print("VIEWER: Documento Quill cargado desde Firestore JSON.");
          } catch (e) { 
            print("VIEWER ERROR: 'elements' (Lista) no pudo ser parseado por Quill: $e");
            loadedDocument = Document()..insert(0, "[Erro ao carregar conteúdo da página]"); 
          }
        } else if (elementsData is String && elementsData.isNotEmpty) {
            print("VIEWER WARN: 'elements' era String, insertando como texto plano.");
            loadedDocument = Document()..insert(0, elementsData);
        } else {
           print("VIEWER WARN: 'elements' no es Lista ni String, o está vacío. Mostrando vazio.");
           // loadedDocument ya está vacío
        }

      } else {
         loadedTitle = doc.exists ? 'Página sem conteúdo' : 'Página Não Encontrada';
         // loadedDocument ya está vacío
      }
    } catch (e) {
      print("VIEWER Error general cargando página: $e");
       loadedTitle = "Erro ao carregar página";
       loadedDocument = Document()..insert(0, "[Erro ao carregar conteúdo]"); 
    }

    // Crear controlador Quill con el documento cargado y en modo readOnly
    final quillController = QuillController(
      document: loadedDocument, 
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true, // <--- Añadir readOnly aquí
    );

    setState(() {
      _pageTitle = loadedTitle;
      _controller = quillController;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_pageTitle),
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
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller == null) {
      // Esto no debería pasar si _isLoading es false, pero es una salvaguarda
      return const Center(child: Text('Erro ao inicializar o visualizador de conteúdo.'));
    }

    // Usar QuillEditor para mostrar el contenido
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      child: QuillEditor.basic(
        controller: _controller!, 
        config: QuillEditorConfig(
          padding: EdgeInsets.zero, 
          expands: false, 
          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
         throw 'Could not launch $url';
      }
    } catch (e) {
       debugPrint('Não foi possível abrir o link: $url. Erro: $e');
       if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Não foi possível abrir o link: $url')),
           );
       }
    }
  }
}
