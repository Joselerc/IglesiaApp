import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/family_model.dart';
import '../../models/user_model.dart'; // Para mostrar responsables
import '../../models/child_model.dart'; // Para mostrar niños
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:intl/intl.dart'; // Para formatear edad
import './create_edit_guardian_screen.dart'; // <-- AÑADIR IMPORT
import './create_edit_child_screen.dart'; // <-- AÑADIR IMPORT
import '../checkin/child_selection_screen.dart'; // <-- AÑADIR IMPORT
import './child_details_screen.dart'; // <-- CORREGIR RUTA IMPORT

// Importar pantallas de creación (se crearán después)
// import './create_edit_guardian_screen.dart'; // <-- ELIMINAR O COMENTAR ESTA
// import './create_edit_child_screen.dart';

class FamilyDetailsScreen extends StatefulWidget {
  final String familyId;

  const FamilyDetailsScreen({super.key, required this.familyId});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {

  // Método para calcular edad (simplificado)
  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return '';
    final birth = birthDate.toDate();
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age > 0 ? '$age anos' : 'Menos de 1 ano';
  }

  void _navigateToAddGuardian({String? guardianUserId}) {
     Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEditGuardianScreen(
        familyId: widget.familyId,
        guardianUserId: guardianUserId,
      )));
  }

  void _navigateToAddChild() {
     Navigator.push(context, MaterialPageRoute(builder: (_) => CreateEditChildScreen(familyId: widget.familyId)));
  }
  
  void _handleCheckin() {
    // Navegar a la pantalla de selección de niños
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => ChildSelectionScreen(familyId: widget.familyId))
    );
  }

  Future<void> _confirmDeleteChild(ChildModel childToDelete) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Criança'),
          content: Text('Tem certeza que deseja remover permanentemente ${childToDelete.firstName} ${childToDelete.lastName} da família?'),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCELAR'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text('ELIMINAR', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      // Podríamos mostrar un indicador de carga aquí si la operación es larga
      // setState(() => _isDeletingChild = true); 
      try {
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // 1. Eliminar de la colección 'children'
        DocumentReference childRef = FirebaseFirestore.instance.collection('children').doc(childToDelete.id);
        batch.delete(childRef);

        // 2. Eliminar de childIds en la familia
        DocumentReference familyRef = FirebaseFirestore.instance.collection('families').doc(widget.familyId);
        batch.update(familyRef, {
          'childIds': FieldValue.arrayRemove([childToDelete.id])
        });
        
        // TODO: Considerar eliminar también los CheckinRecords asociados a este childId si es necesario.

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${childToDelete.firstName} removido(a) com sucesso.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print("Erro ao eliminar criança: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover ${childToDelete.firstName}: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        // if (mounted) setState(() => _isDeletingChild = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('families').doc(widget.familyId).snapshots(),
        builder: (context, familySnapshot) {
          if (familySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!familySnapshot.hasData || !familySnapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(title: const Text('Erro')),
              body: const Center(child: Text('Família não encontrada.')),
            );
          }

          final family = FamilyModel.fromFirestore(familySnapshot.data!);

          return Scaffold(
            appBar: AppBar(
              title: Text(family.familyName.isNotEmpty ? family.familyName : 'Detalhes da Família'),
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Centrar elementos principales
                children: [
                  // --- Sección Superior Reestructurada ---
                  CircleAvatar(
                    radius: 50, // Ligeramente más grande
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    backgroundImage: family.familyAvatarUrl != null && family.familyAvatarUrl!.isNotEmpty
                        ? NetworkImage(family.familyAvatarUrl!)
                        : null,
                    child: family.familyAvatarUrl == null || family.familyAvatarUrl!.isEmpty
                        ? Text(
                            _getInitials(family.familyName),
                            style: AppTextStyles.subtitle1.copyWith(fontSize: 28, color: AppColors.secondary, fontWeight: FontWeight.bold), // Ajustar tamaño
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuir botones
                    children: [
                      _buildAddButton(Icons.person_add_alt_1_outlined, 'Adicionar\nResponsável', _navigateToAddGuardian), // \n para salto de línea si es necesario
                      _buildAddButton(Icons.child_care_outlined, 'Adicionar\nCriança', _navigateToAddChild), // Texto corregido
                    ],
                  ),
                  const SizedBox(height: 24),
                  // --- Fin Sección Superior ---
                  
                  const Divider(),

                  // Sección Responsables (Alinear texto a la izquierda)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Responsáveis', style: AppTextStyles.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _buildGuardiansList(family.guardianUserIds),
                  const SizedBox(height: 24),
                  const Divider(),

                  // Sección Niños (Alinear texto a la izquierda)
                  Align(
                     alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Crianças', style: AppTextStyles.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _buildChildrenList(family.id),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Botón Check-in fijo abajo
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0), // Padding inferior ya ajustado
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Usar color primario de la app
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleCheckin,
                child: Text('CHECK-IN', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper para obtener iniciales (duplicado de family_list_screen, considerar mover a utils)
  String _getInitials(String name) {
      String initials = '';
      if (name.isNotEmpty) {
        final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          initials = parts.first[0];
          if (parts.length > 1) {
            initials += parts.last[0];
          }
        }
      } else {
        initials = '?'; // Fallback diferente para detalles
      }
      return initials.toUpperCase();
  }

  Widget _buildAddButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Aumentar padding horizontal para separar botones
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center,)
          ],
        ),
      ),
    );
  }

  Widget _buildGuardiansList(List<String> guardianIds) {
    if (guardianIds.isEmpty) {
      return const Text('Nenhum responsável adicionado.', style: TextStyle(color: Colors.grey));
    }

    // Usar múltiples StreamBuilders o un FutureBuilder complejo para obtener datos de cada user ID.
    // Esto puede ser ineficiente si hay muchos responsables. Una mejor solución 
    // a largo plazo sería desnormalizar algunos datos o usar Cloud Functions.
    // Por ahora, un ListView simple con StreamBuilder por cada ID.
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Deshabilitar scroll interno
      itemCount: guardianIds.length,
      itemBuilder: (context, index) {
        final userId = guardianIds[index];
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return ListTile(title: Text('Responsável não encontrado (ID: $userId)'));
            }
            final user = UserModel.fromMap(userSnapshot.data!.data() as Map<String, dynamic>); 
            
            // Formatear número de teléfono con código de país
            String phoneDisplay = 'Sem telefone';
            if (user.phone != null && user.phone!.isNotEmpty) {
              phoneDisplay = user.phone!;
              if (user.phoneCountryCode != null && user.phoneCountryCode!.isNotEmpty) {
                // Asegurarse que el código no tenga ya el +
                String countryCode = user.phoneCountryCode!.startsWith('+') 
                                   ? user.phoneCountryCode! 
                                   : '+${user.phoneCountryCode}';
                phoneDisplay = '$countryCode $phoneDisplay';
              }
            }

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) 
                    ? NetworkImage(user.photoUrl!) 
                    : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty) 
                    ? Text(_getInitials(user.displayName ?? '${user.name ?? ''} ${user.surname ?? ''}'.trim()))
                    : null,
                ),
                title: Text(user.displayName ?? '${user.name ?? ''} ${user.surname ?? ''}'.trim()),
                subtitle: Text('$phoneDisplay\n${user.email}'), // Usar el teléfono formateado
                isThreeLine: true,
                onTap: () {
                   print('Ver/Editar responsável: ${userSnapshot.data!.id}');
                   _navigateToAddGuardian(guardianUserId: userSnapshot.data!.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChildrenList(String familyId) {
    // Stream para obtener los niños de esta familia
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .where('familyId', isEqualTo: familyId)
          .snapshots(),
      builder: (context, childrenSnapshot) {
        if (childrenSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!childrenSnapshot.hasData || childrenSnapshot.data!.docs.isEmpty) {
          return const Text('Nenhuma criança adicionada.', style: TextStyle(color: Colors.grey));
        }

        final childrenDocs = childrenSnapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: childrenDocs.length,
          itemBuilder: (context, index) {
            final child = ChildModel.fromFirestore(childrenDocs[index]);
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onLongPress: () {
                  _confirmDeleteChild(child);
                },
                onTap: () {
                  print('Ver/Editar criança: ${child.id} da família ${widget.familyId}');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    ChildDetailsScreen(childId: child.id, familyId: widget.familyId)
                  ));
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (child.photoUrl != null && child.photoUrl!.isNotEmpty)
                        ? NetworkImage(child.photoUrl!)
                        : null,
                    child: (child.photoUrl == null || child.photoUrl!.isEmpty)
                        ? Text(_getInitials('${child.firstName} ${child.lastName}'))
                        : null,
                  ),
                  title: Text('${child.firstName} ${child.lastName}'),
                  subtitle: Text(_calculateAge(child.dateOfBirth)), // Mostrar edad
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
} 