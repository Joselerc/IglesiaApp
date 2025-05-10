import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart'; // Usaremos UserModel
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import './create_edit_visitor_screen.dart'; // Pantalla para crear/editar visitante

class VisitorListScreen extends StatefulWidget {
  const VisitorListScreen({super.key});

  @override
  State<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends State<VisitorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreateVisitor({String? userId}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateEditVisitorScreen(visitorUserId: userId)),
    );
  }
  
  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String initials = parts.first[0];
    if (parts.length > 1) initials += parts.last[0];
    return initials.toUpperCase();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitantes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nome do visitante/telefone...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Filtrar por isVisitorOnly == true
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isVisitorOnly', isEqualTo: true)
                  .orderBy('displayName') // Ordenar por nombre
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar visitantes: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum visitante/usuário encontrado.'));
                }

                var userDocs = snapshot.data!.docs;

                if (_searchTerm.isNotEmpty) {
                  userDocs = userDocs.where((doc) {
                    final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
                    final nameMatch = user.displayName?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false;
                    final phoneMatch = user.phone?.contains(_searchTerm) ?? false;
                    return nameMatch || phoneMatch;
                  }).toList();
                }

                return ListView.separated(
                  itemCount: userDocs.length,
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 70, endIndent: 16, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final userDoc = userDocs[index];
                    final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>); // Pasar ID si fromMap lo requiere
                    
                    String phoneDisplay = user.phone ?? 'Sem telefone';
                    if (user.phone != null && user.phoneCountryCode != null) {
                        phoneDisplay = '${user.phoneCountryCode} ${user.phone}';
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                            ? Text(_getInitials(user.displayName), style: AppTextStyles.subtitle1.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      title: Text(user.displayName ?? 'Nome não disponível', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(phoneDisplay, style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                      onTap: () => _navigateToCreateVisitor(userId: userDoc.id), // Pasar ID para modo edición
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Color de la app
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _navigateToCreateVisitor(), // Sin userId para modo creación
          child: Text('NOVO VISITANTE', style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
} 