import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import 'edit_page_screen.dart'; // Importar la futura pantalla de edición

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
        title: const Text('Gerenciar Páginas'),
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
            return Center(child: Text('Erro ao verificar permissão: ${permissionSnapshot.error}'));
          }
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Acesso Negado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Você não tem permissão para gerenciar páginas.',
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
                return Center(child: Text('Erro ao carregar páginas: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_document, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma página personalizada criada ainda.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                       SizedBox(height: 8),
                      Text(
                        'Toque no botão + para criar a primeira.',
                         style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  final title = pageData?['title'] as String? ?? 'Página sem Título';
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
                               const SnackBar(content: Text('Sem permissão para editar páginas.'), backgroundColor: Colors.red),
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
                        const SnackBar(content: Text('Sem permissão para criar páginas.'), backgroundColor: Colors.red),
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
                tooltip: 'Criar Nova Página',
              );
            } else {
              return const SizedBox.shrink();
            }
         }
      ),
    );
  }
} 