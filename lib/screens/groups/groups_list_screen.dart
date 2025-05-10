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

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final GroupService _groupService = GroupService();
  final PermissionService _permissionService = PermissionService();
  
  // Estado para saber si el usuario tiene permiso para crear grupos
  bool _canCreateGroup = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Verificamos el permiso del usuario al iniciar
    _checkCreatePermission();
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
    _tabController.dispose();
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
              child: Column(
                children: [
                  // Barra superior con botones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            tooltip: 'Criar Grupo',
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
                  
                  // Pestañas con más espacio horizontal
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      labelStyle: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Text('Todos'),
                        Text('Meus Grupos'),
                      ],
                    ),
                  ),
                ],
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
          
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña "Todos los Grupos"
                _buildAllGroupsTab(userId),
                
                // Pestaña "Mis Grupos"
                _buildMyGroupsTab(userId),
              ],
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
              tooltip: 'Criar Grupo',
            )
          : null, // Ocultar si no es pastor
    );
  }
  
  // Construye la pestaña de todos los grupos
  Widget _buildAllGroupsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
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
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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
                    'Você não pertence a nenhum grupo',
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
    );
  }
  
  // Construye la pestaña de mis grupos
  Widget _buildMyGroupsTab(String userId) {
    if (userId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 64, color: AppColors.mutedGray),
            const SizedBox(height: 16),
            Text(
              'Você deve estar logado para ver seus grupos',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: FirebaseFirestore.instance.collection('users').doc(userId))
          .snapshots(),
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
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final userGroups = snapshot.data!.docs.map((doc) => 
          Group.fromFirestore(doc)
        ).toList();
        
        final filteredUserGroups = _filterGroups(userGroups);

        if (filteredUserGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 64, color: AppColors.mutedGray),
                const SizedBox(height: 16),
                Text(
                  'Você não pertence a nenhum grupo',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0); // Ir a la pestaña de todos los grupos
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar grupos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUserGroups.length,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemBuilder: (context, index) {
            final group = filteredUserGroups[index];
            
            return GroupCard(
              group: group,
              userId: userId,
              onActionPressed: (group) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupFeedScreen(group: group),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
} 