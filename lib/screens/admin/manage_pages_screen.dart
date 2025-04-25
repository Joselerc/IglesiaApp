import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _pagesCollection.orderBy('title').snapshots(), // Ordenar por título por defecto
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
                  onTap: () {
                    // Navegar a la pantalla de edición para esta página
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de edición para crear una nueva página (pageId será null)
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
      ),
    );
  }
} 