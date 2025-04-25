import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/home_screen_section.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'edit_custom_section_screen.dart'; // <-- Importar pantalla de edición
// Importar EditHomeScreenSectionScreen (se creará después)
// import 'edit_home_section_screen.dart'; 

class ManageHomeSectionsScreen extends StatefulWidget {
  const ManageHomeSectionsScreen({super.key});

  @override
  State<ManageHomeSectionsScreen> createState() => _ManageHomeSectionsScreenState();
}

class _ManageHomeSectionsScreenState extends State<ManageHomeSectionsScreen> {
  final CollectionReference _sectionsCollection = 
      FirebaseFirestore.instance.collection('homeScreenSections');
      
  // Variable local para manejar el reordenamiento visual inmediato
  List<HomeScreenSection> _localSections = [];

  // Función para actualizar el orden en Firestore
  Future<void> _updateSectionsOrder(List<HomeScreenSection> orderedSections) async {
    final batch = FirebaseFirestore.instance.batch();
    List<HomeScreenSection> updatedLocalSections = []; // Lista temporal para la UI
    
    for (int i = 0; i < orderedSections.length; i++) {
      final section = orderedSections[i];
      HomeScreenSection updatedSection = section; // Iniciar con la sección actual
      
      // Actualizar Firestore solo si el orden cambió
      if (section.order != i) {
        final docRef = _sectionsCollection.doc(section.id);
        batch.update(docRef, {'order': i});
        // Crear una nueva instancia con el orden actualizado para la UI local
        updatedSection = HomeScreenSection(
          id: section.id,
          title: section.title,
          type: section.type,
          order: i, // <<< Usar el nuevo índice como orden
          isActive: section.isActive,
          pageIds: section.pageIds,
        );
      }
      updatedLocalSections.add(updatedSection);
    }
    
    try {
      await batch.commit();
      print('✅ Orden de secciones actualizado en Firestore.');
      // Actualizar la lista local de una vez si la escritura fue exitosa
      // Esto asegura que la UI refleje el estado guardado
      setState(() {
          _localSections = updatedLocalSections;
      });
    } catch (e) {
      print('❌ Error al actualizar orden en Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar a nova ordem: $e'))
        );
        // Si falla, la UI NO se actualiza con la nueva lista temporal,
        // manteniendo el estado visual previo al commit fallido.
        // El StreamBuilder eventualmente corregirá la UI al estado de Firestore.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Tela Inicial'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _sectionsCollection.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma seção encontrada.'));
          }

          // Actualizar la lista local cuando los datos cambian
          _localSections = snapshot.data!.docs
              .map((doc) => HomeScreenSection.fromFirestore(doc))
              .toList();

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _localSections.length,
            itemBuilder: (context, index) {
              final section = _localSections[index];
              // Usar el ID de la sección como Key para el ReorderableListView
              return Card(
                key: ValueKey(section.id), 
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                  title: Text(section.title),
                  subtitle: Text(section.type.toString().split('.').last), 
                  trailing: Switch(
                    value: section.isActive,
                    onChanged: (bool value) async {
                      try {
                        await _sectionsCollection.doc(section.id).update({'isActive': value});
                        // No es necesario setState aquí porque el StreamBuilder reconstruirá
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao atualizar status: $e'))
                        );
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                  onTap: () {
                     if (section.type == HomeScreenSectionType.customPageList) {
                       // Navegar a la pantalla de edición pasando la sección
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => EditCustomSectionScreen(section: section),
                         ),
                       );
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Esta seção não pode ser editada aqui.'))
                       );
                     }
                  },
                ),
              );
            },
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                // Ajustar newIndex si el item se mueve hacia abajo en la lista
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                // Mover el item en la lista local para feedback visual inmediato
                final HomeScreenSection item = _localSections.removeAt(oldIndex);
                _localSections.insert(newIndex, item);

                // Actualizar el orden en Firestore
                // Pasar una copia de la lista reordenada
                _updateSectionsOrder(List.from(_localSections)); 
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Navegar a la pantalla de creación pasando null
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => const EditCustomSectionScreen(section: null),
             ),
           );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Criar Nova Seção de Páginas',
      ),
    );
  }
} 