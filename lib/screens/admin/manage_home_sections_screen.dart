import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/home_screen_section.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'edit_custom_section_screen.dart'; // <-- Importar pantalla de edición
import '../../l10n/app_localizations.dart';
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
           SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionReorderSections), backgroundColor: Colors.red),
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
          hideWhenEmpty: section.hideWhenEmpty,
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
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingNewOrder(e.toString())))
        );
      }
    }
  }

  // Función para obtener el icono apropiado para cada sección
  Widget _getSectionIcon(HomeScreenSectionType type) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    switch (type) {
      case HomeScreenSectionType.announcements:
        iconData = Icons.campaign;
        iconColor = Colors.orange[700]!;
        backgroundColor = Colors.orange[100]!;
        break;
      case HomeScreenSectionType.events:
        iconData = Icons.event;
        iconColor = Colors.blue[700]!;
        backgroundColor = Colors.blue[100]!;
        break;
      case HomeScreenSectionType.cults:
        iconData = Icons.church;
        iconColor = Colors.purple[700]!;
        backgroundColor = Colors.purple[100]!;
        break;
      case HomeScreenSectionType.liveStream:
        iconData = Icons.live_tv;
        iconColor = Colors.red[700]!;
        backgroundColor = Colors.red[100]!;
        break;
      case HomeScreenSectionType.videos:
        iconData = Icons.video_library;
        iconColor = Colors.indigo[700]!;
        backgroundColor = Colors.indigo[100]!;
        break;
      case HomeScreenSectionType.ministries:
        iconData = Icons.work_outline;
        iconColor = Colors.teal[700]!;
        backgroundColor = Colors.teal[100]!;
        break;
      case HomeScreenSectionType.groups:
        iconData = Icons.group;
        iconColor = Colors.green[700]!;
        backgroundColor = Colors.green[100]!;
        break;
      case HomeScreenSectionType.counseling:
        iconData = Icons.support_agent;
        iconColor = Colors.cyan[700]!;
        backgroundColor = Colors.cyan[100]!;
        break;
      case HomeScreenSectionType.donations:
        iconData = Icons.volunteer_activism;
        iconColor = Colors.pink[700]!;
        backgroundColor = Colors.pink[100]!;
        break;
      case HomeScreenSectionType.courses:
        iconData = Icons.school;
        iconColor = Colors.amber[700]!;
        backgroundColor = Colors.amber[100]!;
        break;
      case HomeScreenSectionType.privatePrayer:
        iconData = Icons.favorite_outline;
        iconColor = Colors.deepPurple[700]!;
        backgroundColor = Colors.deepPurple[100]!;
        break;
      case HomeScreenSectionType.publicPrayer:
        iconData = Icons.public;
        iconColor = Colors.lightBlue[700]!;
        backgroundColor = Colors.lightBlue[100]!;
        break;
      case HomeScreenSectionType.customPageList:
        iconData = Icons.list_alt;
        iconColor = Colors.brown[700]!;
        backgroundColor = Colors.brown[100]!;
        break;
      case HomeScreenSectionType.servicesGrid:
        iconData = Icons.grid_view;
        iconColor = Colors.grey[700]!;
        backgroundColor = Colors.grey[300]!;
        break;
      default:
        iconData = Icons.help_outline;
        iconColor = Colors.grey[700]!;
        backgroundColor = Colors.grey[300]!;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  // Función para mostrar el diálogo de edición de título
  Future<void> _showEditTitleDialog(HomeScreenSection section) async {
    final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionEditSections), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final TextEditingController controller = TextEditingController(
      text: section.title.isNotEmpty ? section.title : _getDefaultSectionTitle(section.type)
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editSectionName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.typeLabel(_getSectionTypeDisplay(section.type)),
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.sectionName,
                border: const OutlineInputBorder(),
              ),
              maxLength: 50,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null && result != section.title) {
      try {
        await _sectionsCollection.doc(section.id).update({'title': result});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.sectionNameUpdated)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingName(e.toString()))),
          );
        }
      }
    }
  }

  // Función para mostrar opciones de visibilidad condicional
  Future<void> _showConditionalVisibilityDialog(HomeScreenSection section) async {
    final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
    if (!hasPerm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionEditSections), backgroundColor: Colors.red),
        );
      }
      return;
    }

    bool hideWhenEmpty = section.hideWhenEmpty;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.configureVisibility),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                              Text(
                  AppLocalizations.of(context)!.sectionLabel(_getSectionDisplayTitle(section)),
                  style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.hideWhenNoContent,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hideWhenEmpty 
                          ? AppLocalizations.of(context)!.sectionWillBeHiddenWhen(_getContentTypeText(context, section.type))
                          : AppLocalizations.of(context)!.sectionWillBeDisplayed,
                        style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(width: 16),
                  _CustomSwitch(
                    value: hideWhenEmpty,
                    onChanged: (value) {
                      setDialogState(() {
                        hideWhenEmpty = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, hideWhenEmpty),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != section.hideWhenEmpty) {
      try {
        await _sectionsCollection.doc(section.id).update({'hideWhenEmpty': result});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.visibilityConfigUpdated)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingConfig(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageHomeScreenTitle),
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
             return Center(child: Text(AppLocalizations.of(context)!.errorVerifyingPermission(permissionSnapshot.error.toString())));
           }
           if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Text(
                   AppLocalizations.of(context)!.noPermissionManageHomeSections,
                   textAlign: TextAlign.center,
                   style: const TextStyle(fontSize: 16, color: Colors.red),
                 ),
               ),
             );
           }
           
           return StreamBuilder<QuerySnapshot>(
             stream: _sectionsCollection.orderBy('order').snapshots(),
             builder: (context, snapshot) {
               if (snapshot.hasError) {
                 return Center(child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString())));
               }
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               }
               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                 return Center(child: Text(AppLocalizations.of(context)!.noSectionsFound));
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
                     elevation: 2,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: ListTile(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       leading: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           ReorderableDragStartListener(
                             index: index,
                             child: const Icon(Icons.drag_handle, color: Colors.grey),
                           ),
                           const SizedBox(width: 8),
                           _getSectionIcon(section.type),
                         ],
                       ),
                       title: Row(
                         children: [
                           Expanded(
                             child: Text(
                               _getSectionDisplayTitle(section),
                               style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
                             ),
                           ),
                           IconButton(
                             icon: const Icon(Icons.edit, size: 20),
                             onPressed: () => _showEditTitleDialog(section),
                             tooltip: AppLocalizations.of(context)!.editName,
                           ),
                         ],
                       ),
                                                  subtitle: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(_getSectionTypeDisplay(section.type)),
                           if (section.type == HomeScreenSectionType.events || 
                               section.type == HomeScreenSectionType.announcements ||
                               section.type == HomeScreenSectionType.cults ||
                               section.type == HomeScreenSectionType.videos ||
                               section.type == HomeScreenSectionType.customPageList) ...[
                             const SizedBox(height: 4),
                             Row(
                               children: [
                                 Icon(
                                   section.hideWhenEmpty ? Icons.visibility_off : Icons.visibility,
                                   size: 16,
                                   color: section.hideWhenEmpty ? Colors.orange : Colors.green,
                                 ),
                                 const SizedBox(width: 4),
                                 Text(
                                   section.hideWhenEmpty ? AppLocalizations.of(context)!.hiddenWhenEmpty : AppLocalizations.of(context)!.alwaysVisible,
                                   style: AppTextStyles.caption.copyWith(
                                     color: section.hideWhenEmpty ? Colors.orange : Colors.green,
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 GestureDetector(
                                   onTap: () => _showConditionalVisibilityDialog(section),
                                   child: Icon(
                                     Icons.settings,
                                     size: 16,
                                     color: Colors.grey[600],
                                   ),
                                 ),
                               ],
                             ),
                           ],
                         ],
                       ),
                       trailing: _CustomSwitch(
                         value: section.isActive,
                         onChanged: (bool value) async {
                           final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
                           if (!hasPerm) {
                             if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionChangeStatus), backgroundColor: Colors.red),
                                 );
                             }
                             return;
                           }
                           try {
                             await _sectionsCollection.doc(section.id).update({'isActive': value});
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingStatus(e.toString())))
                             );
                           }
                         },
                       ),
                       onTap: () async {
                         final bool hasPerm = await _permissionService.hasPermission('manage_home_sections');
                         if (!hasPerm) {
                           if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionEditSections), backgroundColor: Colors.red),
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
                             SnackBar(content: Text(AppLocalizations.of(context)!.sectionCannotBeEditedHere))
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
                       SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionCreateSections), backgroundColor: Colors.red),
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
               tooltip: AppLocalizations.of(context)!.createNewPageSection,
             );
           } else {
             return const SizedBox.shrink();
           }
        }
      ),
    );
  }

  // Función helper para obtener el título para mostrar
  String _getSectionDisplayTitle(HomeScreenSection section) {
    // Para liveStream, siempre mostrar el título de la sección de homeScreenSections
    if (section.type == HomeScreenSectionType.liveStream) {
      return section.title;
    }
    
    // Para otras secciones, mostrar el título si está disponible
    if (section.title.isNotEmpty) {
      return section.title;
    }
    
    // Si no hay título, mostrar un nombre por defecto basado en el tipo
    return _getDefaultSectionTitle(section.type);
  }
  
  // Función helper para obtener el nombre por defecto de cada tipo de sección
  String _getDefaultSectionTitle(HomeScreenSectionType type) {
    switch (type) {
      case HomeScreenSectionType.announcements:
        return AppLocalizations.of(context)!.announcements;
      case HomeScreenSectionType.cults:
        return AppLocalizations.of(context)!.scheduledCults;
      case HomeScreenSectionType.servicesGrid:
        return AppLocalizations.of(context)!.services;
      case HomeScreenSectionType.events:
        return AppLocalizations.of(context)!.events;
      case HomeScreenSectionType.counseling:
        return AppLocalizations.of(context)!.counseling;
      case HomeScreenSectionType.videos:
        return AppLocalizations.of(context)!.videos;
      case HomeScreenSectionType.liveStream:
        return AppLocalizations.of(context)!.liveStreamLabel;
      case HomeScreenSectionType.donations:
        return AppLocalizations.of(context)!.donations;
      case HomeScreenSectionType.courses:
        return AppLocalizations.of(context)!.onlineCourses;
      case HomeScreenSectionType.ministries:
        return AppLocalizations.of(context)!.ministries;
      case HomeScreenSectionType.groups:
        return AppLocalizations.of(context)!.connect;
      case HomeScreenSectionType.privatePrayer:
        return AppLocalizations.of(context)!.privatePrayer;
      case HomeScreenSectionType.publicPrayer:
        return AppLocalizations.of(context)!.publicPrayer;
      case HomeScreenSectionType.customPageList:
        return AppLocalizations.of(context)!.customPages;
      default:
        return AppLocalizations.of(context)!.unknownSection;
    }
  }
  
  // Función helper para obtener el tipo de sección para mostrar
  String _getSectionTypeDisplay(HomeScreenSectionType type) {
    switch (type) {
      case HomeScreenSectionType.announcements:
        return AppLocalizations.of(context)!.announcements;
      case HomeScreenSectionType.cults:
        return AppLocalizations.of(context)!.cultsTab;
      case HomeScreenSectionType.servicesGrid:
        return AppLocalizations.of(context)!.servicesGridObsolete;
      case HomeScreenSectionType.events:
        return AppLocalizations.of(context)!.events;
      case HomeScreenSectionType.counseling:
        return AppLocalizations.of(context)!.counseling;
      case HomeScreenSectionType.videos:
        return AppLocalizations.of(context)!.videos;
      case HomeScreenSectionType.liveStream:
        return AppLocalizations.of(context)!.liveStreamType;
      case HomeScreenSectionType.donations:
        return AppLocalizations.of(context)!.donations;
      case HomeScreenSectionType.courses:
        return AppLocalizations.of(context)!.courses;
      case HomeScreenSectionType.ministries:
        return AppLocalizations.of(context)!.ministries;
      case HomeScreenSectionType.groups:
        return AppLocalizations.of(context)!.groups;
      case HomeScreenSectionType.privatePrayer:
        return AppLocalizations.of(context)!.privatePrayer;
      case HomeScreenSectionType.publicPrayer:
        return AppLocalizations.of(context)!.publicPrayer;
      case HomeScreenSectionType.customPageList:
        return AppLocalizations.of(context)!.pageList;
      default:
        return type.toString().split('.').last;
    }
  }

  // Función helper para obtener el texto del tipo de contenido para visibilidad condicional
  String _getContentTypeText(BuildContext context, HomeScreenSectionType type) {
    switch (type) {
      case HomeScreenSectionType.events:
        return AppLocalizations.of(context)!.events;
      case HomeScreenSectionType.announcements:
        return AppLocalizations.of(context)!.announcements;
      case HomeScreenSectionType.cults:
        return AppLocalizations.of(context)!.scheduledCults;
      case HomeScreenSectionType.videos:
        return AppLocalizations.of(context)!.videos;
      case HomeScreenSectionType.customPageList:
        return AppLocalizations.of(context)!.pages;
      default:
        return AppLocalizations.of(context)!.content;
    }
  }
}

// Widget de switch personalizado igual al de create_edit_role_screen
class _CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<_CustomSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.value;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isChecked) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _isChecked) {
      _isChecked = widget.value;
      if (_isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSwitch() {
    setState(() {
      _isChecked = !_isChecked;
      if (_isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onChanged(_isChecked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          _toggleSwitch();
          // Añadir feedback táctil
          HapticFeedback.lightImpact();
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 45,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Color.lerp(
                  Colors.grey.shade300,
                  AppColors.primary,
                  _animation.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isChecked
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isChecked ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 0.1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 