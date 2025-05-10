import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/home_screen_section.dart';
import '../../services/permission_service.dart';
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
  final PermissionService _permissionService = PermissionService();
      
  List<HomeScreenSection> _localSections = [];

  Future<void> _updateSectionsOrder(List<HomeScreenSection> orderedSections) async {
    final bool hasPermission = await _permissionService.hasPermission('manage_home_sections');
    if (!hasPermission) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Sem permissão para reordenar seções.'), backgroundColor: Colors.red),
         );
      }
      return;
    }
    
    final batch = FirebaseFirestore.instance.batch();
    List<HomeScreenSection> updatedLocalSections = [];
    
    for (int i = 0; i < orderedSections.length; i++) {
      final section = orderedSections[i];
      HomeScreenSection updatedSection = section;
      
      if (section.order != i) {
        final docRef = _sectionsCollection.doc(section.id);
        batch.update(docRef, {'order': i});
        updatedSection = HomeScreenSection(
          id: section.id,
          title: section.title,
          type: section.type,
          order: i,
          isActive: section.isActive,
          pageIds: section.pageIds,
        );
      }
      updatedLocalSections.add(updatedSection);
    }
    
    try {
      await batch.commit();
      print('✅ Orden de secciones actualizado en Firestore.');
      setState(() {
          _localSections = updatedLocalSections;
      });
    } catch (e) {
      print('❌ Error al actualizar orden en Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar a nova ordem: $e'))
        );
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
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_home_sections'),
        builder: (context, permissionSnapshot) {
           if (permissionSnapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
           }
           if (permissionSnapshot.hasError) {
             return Center(child: Text('Erro ao verificar permissão: ${permissionSnapshot.error}'));
           }
           if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
             return const Center(
               child: Padding(
                 padding: EdgeInsets.all(16.0),
                 child: Text(
                   'Você não tem permissão para gerenciar as seções da tela inicial.',
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 16, color: Colors.red),
                 ),
               ),
             );
           }
           
           return StreamBuilder<QuerySnapshot>(
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

               _localSections = snapshot.data!.docs
                   .map((doc) => HomeScreenSection.fromFirestore(doc))
                   .toList();

               return ReorderableListView.builder(
                 padding: const EdgeInsets.all(8.0),
                 itemCount: _localSections.length,
                 itemBuilder: (context, index) {
                   final section = _localSections[index];
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
                           final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
                           if (!hasPerm) {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('Sem permissão para alterar status.'), backgroundColor: Colors.red),
                                 );
                             }
                             return;
                           }
                           try {
                             await _sectionsCollection.doc(section.id).update({'isActive': value});
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Erro ao atualizar status: $e'))
                             );
                           }
                         },
                         activeColor: AppColors.primary,
                       ),
                       onTap: () async {
                         final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
                         if (!hasPerm) {
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sem permissão para editar seções.'), backgroundColor: Colors.red),
                              );
                           }
                           return;
                         }
                         if (section.type == HomeScreenSectionType.customPageList) {
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
                     if (newIndex > oldIndex) {
                       newIndex -= 1;
                     }
                     final HomeScreenSection item = _localSections.removeAt(oldIndex);
                     _localSections.insert(newIndex, item);
                     _updateSectionsOrder(List.from(_localSections)); 
                   });
                 },
               );
             },
           );
        }
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_home_sections'),
        builder: (context, permissionSnapshot) {
           if (permissionSnapshot.connectionState == ConnectionState.done &&
               permissionSnapshot.hasData &&
               permissionSnapshot.data == true) {
             return FloatingActionButton(
               onPressed: () async {
                 final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
                 if (!hasPerm) {
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Sem permissão para criar seções.'), backgroundColor: Colors.red),
                     );
                   }
                   return;
                 }
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
             );
           } else {
             return const SizedBox.shrink();
           }
        }
      ),
    );
  }
} 