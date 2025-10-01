import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/video_section.dart';
import './edit_section_screen.dart';
import './manage_all_videos_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';

class ManageSectionsScreen extends StatefulWidget {
  const ManageSectionsScreen({super.key});

  @override
  State<ManageSectionsScreen> createState() => _ManageSectionsScreenState();
}

class _ManageSectionsScreenState extends State<ManageSectionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PermissionService _permissionService = PermissionService();
  bool _isReordering = false;
  
  Stream<List<dynamic>> _getCombinedStream() {
    // Combinar el stream de secciones con el stream de videos
    final sectionsStream = _firestore
        .collection('videoSections')
        .orderBy('order')
        .snapshots();
    
    final videosStream = _firestore
        .collection('videos')
        .limit(1)
        .snapshots();
    
    return sectionsStream.asyncMap((sectionsSnapshot) async {
      final sections = sectionsSnapshot.docs;
      final videosSnapshot = await videosStream.first;
      final hasVideos = videosSnapshot.docs.isNotEmpty;
      
      final List<dynamic> combinedList = [];
      
      // Agregar la sección predeterminada de "Vídeos Recentes" si hay videos
      if (hasVideos) {
        combinedList.add({
          'type': 'default',
          'id': 'recent_videos',
          'title': 'Vídeos Recentes',
          'order': -1, // Para que aparezca primero
        });
      }
      
      // Agregar las secciones personalizadas
      combinedList.addAll(sections);
      
      return combinedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_videos'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorVerifyingPermission(permissionSnapshot.error.toString())));
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.accessDenied, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.noPermissionManageVideos, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          // Contenido original cuando tiene permiso
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.videoSections,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isReordering ? Icons.done : Icons.reorder, color: Colors.white),
                            tooltip: _isReordering ? AppLocalizations.of(context)!.saveOrder : AppLocalizations.of(context)!.reorderSections,
                            onPressed: () {
                              setState(() {
                                _isReordering = !_isReordering;
                              });
                              
                              if (_isReordering) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.dragSectionsToReorder),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<dynamic>>(
                    stream: _getCombinedStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final combinedData = snapshot.data!;
                      final sections = <dynamic>[];
                      
                      for (var item in combinedData) {
                        if (item is Map<String, dynamic>) {
                          // Es la sección predeterminada
                          sections.add(item);
                        } else {
                          // Es un documento de Firestore
                          sections.add(VideoSection.fromFirestore(item));
                        }
                      }

                      if (sections.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 70,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noSectionCreated,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _navigateToEditSection(context),
                                icon: const Icon(Icons.add),
                                label: Text(AppLocalizations.of(context)!.createFirstSection),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          if (_isReordering)
                            Container(
                              color: Colors.amber[50],
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber[800]),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Arraste para reordenar. Pressione o botão concluído quando terminar.',
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: _isReordering
                            ? ReorderableListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: sections.length,
                                onReorder: _reorderSections,
                                itemBuilder: (context, index) {
                                  final section = sections[index];
                                  
                                  // Si es la sección predeterminada, no se puede reordenar
                                  if (section is Map<String, dynamic> && section['type'] == 'default') {
                                    return Card(
                                      key: Key(section['id']),
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      elevation: 2,
                                      color: Colors.grey[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.lock, color: Colors.grey),
                                        ),
                                        title: Text(
                                          section['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Text(
                                          AppLocalizations.of(context)!.defaultSectionNotEditable,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return Card(
                                    key: Key(section.id),
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.drag_handle, color: Colors.blueGrey),
                                      ),
                                      title: Text(
                                        section.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: _buildSectionTypeLabel(section.type),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: sections.length,
                                itemBuilder: (context, index) {
                                  final section = sections[index];
                                  
                                  // Si es la sección predeterminada
                                  if (section is Map<String, dynamic> && section['type'] == 'default') {
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      elevation: 2,
                                      color: Colors.blue[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.blue[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.video_library, color: Colors.blue[700], size: 24),
                                        ),
                                        title: Text(
                                          section['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  AppLocalizations.of(context)!.allVideos,
                                                  style: TextStyle(
                                                    color: Colors.blue[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(context)!.defaultSection,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.manage_search, color: Colors.blue[700]),
                                          tooltip: AppLocalizations.of(context)!.manageVideos,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ManageAllVideosScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ManageAllVideosScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: _getSectionIcon(section.type),
                                      title: Text(
                                        section.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: _buildSectionTypeLabel(section.type),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: AppColors.primary),
                                            tooltip: AppLocalizations.of(context)!.editSection,
                                            onPressed: () => _navigateToEditSection(
                                              context,
                                              section: section,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red[400]),
                                            tooltip: AppLocalizations.of(context)!.deleteSection,
                                            onPressed: () => _confirmDeleteSection(section),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: !_isReordering
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToEditSection(context),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.newSection),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _getSectionIcon(String type) {
    switch (type) {
      case 'latest':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.new_releases, color: Colors.blue[700], size: 24),
        );
      case 'favorites':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.favorite, color: Colors.red[400], size: 24),
        );
      case 'custom':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.video_collection, color: Colors.purple[700], size: 24),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.folder, color: Colors.blueGrey, size: 24),
        );
    }
  }

  Widget _buildSectionTypeLabel(String type) {
    String label = AppLocalizations.of(context)!.unknown;
    Color color = Colors.grey;
    
    switch (type) {
      case 'latest':
        label = AppLocalizations.of(context)!.mostRecent;
        color = Colors.blue;
        break;
      case 'favorites':
        label = AppLocalizations.of(context)!.mostPopular;
        color = Colors.red;
        break;
      case 'custom':
        label = AppLocalizations.of(context)!.custom;
        color = Colors.purple;
        break;
    }
    
    return Row(
      children: [
        const SizedBox(height: 24), // Espacio para que el subtítulo tenga altura adecuada
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _reorderSections(int oldIndex, int newIndex) async {
    // Obtener los datos actuales
    final combinedData = await _getCombinedStream().first;
    
    // Verificar si estamos intentando mover la sección predeterminada
    final oldItem = combinedData[oldIndex];
    if (oldItem is Map<String, dynamic> && oldItem['type'] == 'default') {
      // No permitir mover la sección predeterminada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.recentVideosCannotBeReordered),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Ajustar índices considerando la sección predeterminada
    int adjustedOldIndex = oldIndex;
    int adjustedNewIndex = newIndex;
    bool hasDefaultSection = false;
    
    // Verificar si existe la sección predeterminada
    if (combinedData.isNotEmpty && combinedData[0] is Map<String, dynamic> && 
        (combinedData[0] as Map)['type'] == 'default') {
      hasDefaultSection = true;
      adjustedOldIndex = oldIndex - 1;
      adjustedNewIndex = newIndex - 1;
    }
    
    // Prevenir mover a la posición 0 si hay sección predeterminada
    if (hasDefaultSection && newIndex == 0) {
      adjustedNewIndex = 0;
    }
    
    if (adjustedOldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }

    final snapshot = await _firestore
        .collection('videoSections')
        .orderBy('order')
        .get();

    final sections = snapshot.docs
        .map((doc) => VideoSection.fromFirestore(doc))
        .toList();

    final batch = _firestore.batch();

    // Mover la sección reordenada
    final movedSection = sections.removeAt(adjustedOldIndex);
    sections.insert(adjustedNewIndex, movedSection);

    // Actualizar el orden de todas las secciones
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      batch.update(
        _firestore.collection('videoSections').doc(section.id),
        {'order': i},
      );
    }

    await batch.commit();
  }

  void _navigateToEditSection(BuildContext context, {VideoSection? section}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSectionScreen(section: section),
      ),
    );
  }

  Future<void> _confirmDeleteSection(VideoSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVideoSection),
        content: Text(AppLocalizations.of(context)!.confirmDeleteSection(section.title)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore
          .collection('videoSections')
          .doc(section.id)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.sectionDeleted)),
        );
      }
    }
  }
} 