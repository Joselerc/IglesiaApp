import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'group_feed_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/group_card.dart';
import '../../modals/create_group_modal.dart';
import '../../services/permission_service.dart';
import '../../widgets/skeletons/list_tab_content_skeleton.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final GroupService _groupService = GroupService();
  final PermissionService _permissionService = PermissionService();
  
  // Estado para saber si el usuario tiene permiso para crear grupos
  bool _canCreateGroup = false;
  
  @override
  void initState() {
    super.initState();
    // Verificamos el permiso del usuario al iniciar
    _checkCreatePermission();
    // Intentar marcar como leídas las notificaciones "huerfanas" o mal formadas al entrar a la lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanOrphanNotifications();
    });
  }
  
  Future<void> _cleanOrphanNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      // 1. Notificaciones genéricas de "Nuevos grupos"
      final genericNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', whereIn: ['group', 'newGroup']) 
          .get();

      for (var doc in genericNotifs.docs) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }

      // 2. Notificaciones de posts huérfanas (sin groupId o mal formadas)
      final postNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', isEqualTo: 'group_post')
          .get();

      for (var doc in postNotifs.docs) {
        final data = doc.data();
        // Si no tiene groupId, intentamos recuperarlo del post original
        if (data['groupId'] == null && data['entityId'] != null) {
           try {
             final postId = data['entityId'] as String;
             final postDoc = await FirebaseFirestore.instance.collection('group_posts').doc(postId).get();
             
             if (postDoc.exists) {
               final postData = postDoc.data();
               dynamic groupRef = postData?['groupId'];
               String? groupId;
               
               if (groupRef is DocumentReference) {
                 groupId = groupRef.id;
               } else if (groupRef is String) {
                 groupId = groupRef;
               }
               
               if (groupId != null) {
                 // REPARACIÓN: Añadir el groupId a la notificación
                 batch.update(doc.reference, {'groupId': groupId});
                 hasUpdates = true;
                 debugPrint('🔧 Reparando notificación grupo ${doc.id}: asignando groupId=$groupId');
               }
             } else {
               // Si el post no existe, la notificación es basura -> borrar
               batch.update(doc.reference, {'isRead': true});
               hasUpdates = true;
               debugPrint('🗑️ Borrando notificación huérfana de post de grupo inexistente: ${doc.id}');
             }
           } catch (e) {
             debugPrint('Error verificando post grupo para notificación ${doc.id}: $e');
           }
        }
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('✅ GROUPS_LIST - Limpieza y reparación de notificaciones realizada');
      }
    } catch (e) {
      debugPrint('❌ GROUPS_LIST - Error en limpieza de notificaciones: $e');
    }
  }
  
  Future<void> _checkCreatePermission() async {
    // Verificar el permiso específico para crear grupos
    final hasPermission = await _permissionService.hasPermission('create_group');
    if (mounted) {
      setState(() {
        _canCreateGroup = hasPermission;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Group> _filterGroups(List<Group> groups) {
    if (_searchQuery.isEmpty) return groups;
    return groups.where((group) => 
      group.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _handleGroupAction(Group group) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve estar logado para entrar em um grupo')),
      );
      return;
    }

    final status = group.getUserStatus(user.uid);

    if (status == 'Enter') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupFeedScreen(group: group),
        ),
      );
    } else if (status == 'Pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua solicitação está pendente de aprovação')),
      );
    } else {
      try {
        await _groupService.requestToJoin(group.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitação enviada com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Encabezado fijo con diseño gradiente y título
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.7),
                  AppColors.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Grupos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    // Mostrar el botón de añadir solo si es pastor
                    if (_canCreateGroup)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                        tooltip: 'Criar Connect',
                        onPressed: () {
                          // Acción para crear un nuevo grupo
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => const CreateGroupModal(),
                          );
                        },
                      )
                    else
                      // Placeholder para mantener el espaciado
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          
          // Barra de búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar grupos...',
                hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: AppTextStyles.bodyText2.copyWith(color: AppColors.textPrimary),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.error),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTabContentSkeleton();
                }

                try {
                  final allGroups = snapshot.data!.docs.map((doc) => 
                    Group.fromFirestore(doc)
                  ).toList();
                  
                  final filteredGroups = _filterGroups(allGroups);

                  if (filteredGroups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off, size: 64, color: AppColors.mutedGray),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum grupo encontrado',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredGroups.length,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      
                      return GroupCard(
                        group: group,
                        userId: userId,
                        onActionPressed: _handleGroupAction,
                      );
                    },
                  );
                } catch (e) {
                  return Center(
                    child: Text(
                      'Erro ao processar dados: ${e.toString()}',
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.error),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      // Mostrar el FAB solo si es pastor
      floatingActionButton: _canCreateGroup
          ? FloatingActionButton(
              onPressed: () {
                // Acción para crear un nuevo grupo
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const CreateGroupModal(),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
              tooltip: 'Criar Connect',
            )
          : null, // Ocultar si no es pastor
    );
  }
} 