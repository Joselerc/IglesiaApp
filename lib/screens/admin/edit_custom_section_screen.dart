import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/home_screen_section.dart';
import '../../models/page_content_model.dart'; // Asumiendo que tienes un modelo para pageContent
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class EditCustomSectionScreen extends StatefulWidget {
  final HomeScreenSection? section; // Null si es nueva sección

  const EditCustomSectionScreen({super.key, this.section});

  @override
  State<EditCustomSectionScreen> createState() => _EditCustomSectionScreenState();
}

class _EditCustomSectionScreenState extends State<EditCustomSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  List<String> _selectedPageIds = [];
  bool _isLoadingPages = true;
  bool _isSaving = false;
  List<PageContentModel> _availablePages = []; // Lista de todas las páginas disponibles

  bool get _isEditing => widget.section != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.section!.title;
      _selectedPageIds = List<String>.from(widget.section!.pageIds ?? []);
    }
    _loadAvailablePages();
  }

  Future<void> _loadAvailablePages() async {
    setState(() => _isLoadingPages = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pageContent')
          .orderBy('title') // Ordenar por título para la selección
          .get();
          
      // TODO: Crear el modelo PageContentModel si no existe
      // Asumiendo que existe un PageContentModel.fromFirestore
      _availablePages = snapshot.docs
          .map((doc) => PageContentModel.fromFirestore(doc))
          .toList();
          
    } catch (e) {
      print('Error cargando páginas disponibles: $e');
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar páginas: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPages = false);
      }
    }
  }

  Future<void> _saveSection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPageIds.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos uma página.'))
        );
       return;
    }

    setState(() => _isSaving = true);
    
    // --- Convertir IDs de String a DocumentReference ---
    final List<DocumentReference> pageRefs = _selectedPageIds.map((pageId) {
      // Asegurarse que pageId no esté vacío antes de crear la referencia
      if (pageId.trim().isNotEmpty) {
        return FirebaseFirestore.instance.collection('pageContent').doc(pageId.trim());
      } else {
        // Esto no debería pasar si la selección es correcta, pero es una salvaguarda
        print("Advertencia: Se encontró un pageId vacío en _selectedPageIds");
        return null; // O manejar el error de otra forma
      }
    }).whereType<DocumentReference>().toList(); // Filtrar nulos y asegurar el tipo
    // --- Fin Conversión ---
    
    final data = {
      'title': _titleController.text.trim(),
      'type': 'customPageList',
      'isActive': _isEditing ? widget.section!.isActive : false, 
      'pageIds': pageRefs, // <-- Usar la lista de referencias
    };

    try {
      if (_isEditing) {
        data['order'] = widget.section!.order; 
        await FirebaseFirestore.instance
            .collection('homeScreenSections')
            .doc(widget.section!.id)
            .update(data);
      } else {
        // Crear nueva sección
        // Obtener el siguiente número de orden
        final lastOrderQuery = await FirebaseFirestore.instance
            .collection('homeScreenSections')
            .orderBy('order', descending: true)
            .limit(1)
            .get();
        final nextOrder = (lastOrderQuery.docs.isNotEmpty 
              ? (lastOrderQuery.docs.first.data()['order'] ?? -1) 
              : -1) + 1;
        data['order'] = nextOrder;
        
        await FirebaseFirestore.instance.collection('homeScreenSections').add(data);
      }
      
      if (mounted) {
        Navigator.pop(context); // Volver a la pantalla anterior
      }
    } catch (e) {
      print('Error guardando sección: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar seção: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
   // TODO: Implementar eliminación si se está editando
   Future<void> _deleteSection() async {
      if (!_isEditing) return;
      
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('Excluir Seção?'),
              content: Text('Tem certeza que deseja excluir a seção "${widget.section!.title}"? Esta ação não pode ser desfeita.'),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                  ),
              ],
          ),
      );

      if (confirm == true) {
          setState(() => _isSaving = true);
          try {
              await FirebaseFirestore.instance
                  .collection('homeScreenSections')
                  .doc(widget.section!.id)
                  .delete();
              if (mounted) Navigator.pop(context); // Salir después de eliminar
          } catch (e) {
              print('Error eliminando sección: $e');
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
                  setState(() => _isSaving = false);
              }
          }
      }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Seção' : 'Criar Nova Seção'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Botón de eliminar (solo si se edita)
           if (_isEditing)
             IconButton(
                 icon: const Icon(Icons.delete_outline),
                 tooltip: 'Excluir Seção',
                 onPressed: _isSaving ? null : _deleteSection,
             ),
          // Botón de guardar
          IconButton(
            icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            tooltip: 'Salvar',
            onPressed: _isSaving ? null : _saveSection,
          ),
        ],
      ),
      body: _isLoadingPages
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título da Seção',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira um título.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Páginas Incluídas nesta Seção',
                    style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_availablePages.isEmpty)
                    const Text('Nenhuma página personalizada encontrada para selecionar.')
                  else
                    // Lista de Checkboxes para seleccionar páginas
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _availablePages.length,
                      itemBuilder: (context, index) {
                        final page = _availablePages[index];
                        final bool isSelected = _selectedPageIds.contains(page.id);
                        return CheckboxListTile(
                          title: Text(page.title.isNotEmpty ? page.title : 'Página sem título (${page.id.substring(0,5)}...)'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPageIds.add(page.id);
                              } else {
                                _selectedPageIds.remove(page.id);
                              }
                              _markAsChanged(); // Marcar cambios
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          activeColor: AppColors.primary,
                        );
                      },
                    ),
                  // Añadir aquí un indicador visual de cambios no guardados si se implementa _markAsChanged
                ],
              ),
            ),
    );
  }
  
  // Helper para marcar cambios (necesario para el PopScope si se añade)
  void _markAsChanged() {
    // Implementar lógica si se añade PopScope para confirmar salida
    // if (!_hasUnsavedChanges) {
    //   setState(() {
    //     _hasUnsavedChanges = true;
    //   });
    // }
  }
}

// TODO: Definir el modelo PageContentModel si no existe
// Crear archivo lib/models/page_content_model.dart
class PageContentModel {
  final String id;
  final String title;
  // Otros campos relevantes de pageContent que puedas necesitar
  
  PageContentModel({required this.id, required this.title});

  factory PageContentModel.fromFirestore(DocumentSnapshot doc) {
     final data = doc.data() as Map<String, dynamic>? ?? {};
     return PageContentModel(
       id: doc.id,
       title: data['title'] as String? ?? '', // Asegurarse que el campo title existe
       // Mapear otros campos aquí
     );
  }
} 