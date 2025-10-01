import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import 'edit_page_screen.dart'; // Importar la futura pantalla de edición
import '../../l10n/app_localizations.dart';

class ManagePagesScreen extends StatefulWidget {
  const ManagePagesScreen({super.key});

  @override
  State<ManagePagesScreen> createState() => _ManagePagesScreenState();
}

class _ManagePagesScreenState extends State<ManagePagesScreen> {
  final CollectionReference _pagesCollection =
      FirebaseFirestore.instance.collection('pageContent'); // Colección para las páginas
  final PermissionService _permissionService = PermissionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.managePagesTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary, // Usar colores del tema
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_pages'),
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
                      const Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.accessDenied,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.noPermissionManagePages,
                        textAlign: TextAlign.center,
                      ),
                   ],
                 ),
              ),
            );
          }
          
          return StreamBuilder<QuerySnapshot>(
            stream: _pagesCollection.orderBy('title').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(AppLocalizations.of(context)!.errorLoadingPages(snapshot.error.toString())));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_document, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noCustomPagesYet,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                       const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.tapPlusToCreateFirst,
                         style: const TextStyle(fontSize: 14, color: Colors.grey),
                         textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final pages = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final pageDoc = pages[index];
                  final pageData = pageDoc.data() as Map<String, dynamic>?; // Safe cast
                  final title = pageData?['title'] as String? ?? AppLocalizations.of(context)!.pageWithoutTitle;
                  final pageId = pageDoc.id;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: const Icon(Icons.article_outlined, color: AppColors.primary),
                      title: Text(title),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () async {
                        final bool hasPerm = await _permissionService.hasPermission('manage_pages');
                        if (!hasPerm) {
                          if (mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionEditPages), backgroundColor: Colors.red),
                             );
                          }
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPageScreen(pageId: pageId),
                          ),
                        );
                      },
                      // TODO: Añadir opción para eliminar (quizás con un Slidable o LongPress)
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<bool>(
         future: _permissionService.hasPermission('manage_pages'),
         builder: (context, permissionSnapshot) {
            if (permissionSnapshot.connectionState == ConnectionState.done &&
                permissionSnapshot.hasData &&
                permissionSnapshot.data == true) {
              return FloatingActionButton(
                onPressed: () async {
                  final bool hasPerm = await _permissionService.hasPermission('manage_pages');
                  if (!hasPerm) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionCreatePages), backgroundColor: Colors.red),
                      );
                    }
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPageScreen(pageId: null),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
                tooltip: AppLocalizations.of(context)!.createNewPage,
              );
            } else {
              return const SizedBox.shrink();
            }
         }
      ),
    );
  }
} 