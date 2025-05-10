import 'package:flutter/material.dart';
import '../../theme/app_colors.dart'; // Asegúrate que la ruta es correcta
import '../../theme/app_text_styles.dart'; // Asegúrate que la ruta es correcta
import '../../models/family_model.dart'; // Importar el modelo
import 'package:cloud_firestore/cloud_firestore.dart'; // Para Firestore
import './create_edit_family_screen.dart'; // <-- AÑADIR IMPORT
import './family_details_screen.dart'; // <-- AÑADIR IMPORT
import '../../models/user_model.dart'; // Asegurar que UserModel esté importado

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
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

  void _navigateToCreateFamily() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditFamilyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Famílias'),
        backgroundColor: AppColors.primary, // O el color que corresponda
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome da família...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // Listado de familias
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('families').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar famílias: ${snapshot.error}', style: AppTextStyles.bodyText1));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhuma família cadastrada.', style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary)));
                }

                var familiesDocs = snapshot.data!.docs;

                // Filtrar familias basado en familyName
                if (_searchTerm.isNotEmpty) {
                  familiesDocs = familiesDocs.where((doc) {
                    final family = FamilyModel.fromFirestore(doc);
                    // Filtrar por familyName
                    return family.familyName.toLowerCase().contains(_searchTerm.toLowerCase());
                  }).toList();
                }
                
                if (familiesDocs.isEmpty && _searchTerm.isNotEmpty) {
                  return Center(child: Text('Nenhuma família encontrada para "$_searchTerm".', style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary)));
                }

                return ListView.separated(
                  itemCount: familiesDocs.length,
                  separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final family = FamilyModel.fromFirestore(familiesDocs[index]);
                    
                    String familyDisplayName = family.familyName.isNotEmpty 
                                               ? family.familyName.toUpperCase()
                                               : 'FAMÍLIA';
                    
                    String initials = '';
                    if (family.familyName.isNotEmpty) { 
                      final parts = family.familyName.trim().split(' ').where((s) => s.isNotEmpty).toList();
                      if (parts.isNotEmpty) {
                        initials = parts.first[0]; 
                        if (parts.length > 1) {
                          initials += parts.last[0]; 
                        }
                      }
                    } else {
                      initials = 'F'; 
                    }
                    initials = initials.toUpperCase();
                    
                    // Obtener el ID del primer guardián (si existe)
                    String? firstGuardianId = family.guardianUserIds.isNotEmpty ? family.guardianUserIds.first : null;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.secondary.withOpacity(0.2),
                        backgroundImage: family.familyAvatarUrl != null && family.familyAvatarUrl!.isNotEmpty
                            ? NetworkImage(family.familyAvatarUrl!) 
                            : null, 
                        child: (family.familyAvatarUrl == null || family.familyAvatarUrl!.isEmpty)
                            ? Text(
                                initials, 
                                style: AppTextStyles.subtitle1.copyWith(fontSize: 24, color: AppColors.secondary, fontWeight: FontWeight.bold),
                              )
                            : null, 
                      ),
                      title: Text(familyDisplayName, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)), 
                      subtitle: firstGuardianId != null
                          // Usar FutureBuilder para obtener el nombre del primer responsable
                          ? FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(firstGuardianId).get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  return Text('Resp.: Carregando...', style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary));
                                }
                                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                                  return Text('Resp.: Não encontrado', style: AppTextStyles.bodyText2.copyWith(color: Colors.red));
                                }
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                final guardianName = userData['displayName'] ?? '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim();
                                return Text(
                                  'Resp.: $guardianName',
                                  style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            )
                          : Text('Resp.: Nenhum', style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary)), // Si no hay responsables
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary), 
                      onTap: () {
                        // Navegar a Detalles
                        Navigator.push(context, MaterialPageRoute(builder: (context) => FamilyDetailsScreen(familyId: family.id)));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Botón flotante o fijo en la parte inferior
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0), // Aumentado el padding inferior
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Usar color primario de la app
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _navigateToCreateFamily,
          child: Text(
            'NOVO REGISTRO',
            style: AppTextStyles.button.copyWith(color: Colors.white, fontWeight: FontWeight.bold), // Estilo del tema para el texto del botón
          ),
        ),
      ),
    );
  }
} 