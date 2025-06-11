import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_role_service.dart';
import '../../services/permission_service.dart';
import '../../services/role_service.dart';
import '../../models/role.dart';
import '../../theme/app_colors.dart';

class UserRoleManagementScreen extends StatefulWidget {
  const UserRoleManagementScreen({Key? key}) : super(key: key);

  @override
  _UserRoleManagementScreenState createState() => _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  final UserRoleService _roleService = UserRoleService();
  final PermissionService _permissionService = PermissionService();
  final RoleService _roleServiceNew = RoleService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isAuthorized = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _currentUserId = '';
  List<Role> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final hasViewListPermission = await _permissionService.hasPermission('view_user_list');
      final hasAssignRolesPermission = await _permissionService.hasPermission('assign_user_roles');
      final canAccessScreen = hasViewListPermission || hasAssignRolesPermission;
      
      setState(() {
        _isAuthorized = canAccessScreen;
      });
      
      if (_isAuthorized) {
        await _loadAvailableRoles();
        await _loadUsers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você não tem permissão para acessar esta página'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    } catch (e) {
      print('Erro ao verificar permissão: $e');
      setState(() {
        _isLoading = false;
        _isAuthorized = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar permissão: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvailableRoles() async {
    try {
      _availableRoles = await _roleServiceNew.getRoles().first;
    } catch (e) {
      print("Error al cargar roles disponibles: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao carregar papéis: $e'), backgroundColor: Colors.red),
        );
      }
      _availableRoles = [];
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = List.from(_users);
      });
      return;
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['displayName'] as String?)?.toLowerCase() ?? '';
        final email = (user['email'] as String).toLowerCase();
        return name.contains(lowercaseQuery) || email.contains(lowercaseQuery);
      }).toList();
    });
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final loadedUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        final roleId = data['roleId'] as String?;
        
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? data['email'] ?? 'Usuário sem nome',
          'photoUrl': data['photoUrl'],
          'roleId': roleId,
        };
      }).toList();
      
      if (mounted) {
        setState(() {
          _users = loadedUsers;
          _filteredUsers = List.from(loadedUsers);
        });
      }
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: $e')),
        );
      }
    }
  }

  Future<void> _updateUserRole(String userId, String? newRoleId) async {
    final bool hasAssignPermission = await _permissionService.hasPermission('assign_user_roles');
    if (!hasAssignPermission) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Você não tem permissão para atualizar papéis.'), backgroundColor: Colors.red),
         );
      }
      return;
    }

    if (userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível alterar seu próprio papel')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'roleId': newRoleId,
      });
      
      final index = _users.indexWhere((u) => u['id'] == userId);
      if (index >= 0) {
        if (mounted) {
          setState(() {
            _users[index]['roleId'] = newRoleId;
            final filteredIndex = _filteredUsers.indexWhere((u) => u['id'] == userId);
            if (filteredIndex >= 0) {
              _filteredUsers[filteredIndex]['roleId'] = newRoleId;
            }
          });
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Papel do usuário atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      print('✅ Papel atualizado com sucesso para o usuário $userId - Novo papel: ${_getRoleName(newRoleId)}');
    } catch (e) {
      print('Erro ao atualizar papel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar papel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRoleName(String? roleId) {
     if (roleId == null || roleId.isEmpty) return "Sem Papel";
     try {
        return _availableRoles.firstWhere((role) => role.id == roleId).name;
     } catch (e) {
       return "Papel inválido";
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Perfiles de Usuários'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : !_isAuthorized
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_accounts,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Acesso não autorizado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você não tem permissão para acessar esta página',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar usuário',
                          hintText: 'Digite nome ou email',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterUsers('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: _filterUsers,
                      ),
                    ),
                    
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nenhum usuário encontrado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredUsers.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                                indent: 70,
                              ),
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final userId = user['id'] as String;
                                final userEmail = user['email'] as String;
                                final userDisplayName = user['displayName'] as String;
                                final userPhotoUrl = user['photoUrl'] as String?;
                                final userRoleId = user['roleId'] as String?;
                                final isCurrentUser = userId == _currentUserId;
                                
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    backgroundImage: userPhotoUrl != null
                                        ? NetworkImage(userPhotoUrl)
                                        : null,
                                    child: userPhotoUrl == null
                                        ? Text(
                                            userDisplayName[0].toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    userDisplayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    userEmail,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: isCurrentUser
                                      ? const Tooltip(
                                          message: 'Não é possível alterar seu próprio papel',
                                          child: Icon(Icons.lock, color: Colors.grey),
                                        )
                                      : FutureBuilder<bool>(
                                          future: _permissionService.hasPermission('assign_user_roles'),
                                          builder: (context, snapshot) {
                                            final hasPermission = snapshot.data ?? false;
                                            if (!hasPermission) {
                                              return const Tooltip(
                                                message: 'Você não tem permissão para alterar papéis',
                                                child: Icon(Icons.no_accounts, color: Colors.grey),
                                              );
                                            }
                                            
                                            return InkWell(
                                              onTap: () {
                                                _showRoleSelectionDialog(userId, userRoleId);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Container(
                                                        constraints: const BoxConstraints(maxWidth: 120),
                                                        child: Text(
                                                          _getRoleName(userRoleId),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showRoleSelectionDialog(String userId, String? currentRoleId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar papel do usuário'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione o papel para atribuir ao usuário:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text(
                            "Sem Papel",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          leading: Icon(
                            Icons.cancel_outlined,
                            color: Colors.grey.shade500,
                          ),
                          selected: currentRoleId == null,
                          selectedTileColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            if (currentRoleId != null) {
                              _updateUserRole(userId, null);
                            }
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        
                        ..._availableRoles.map((role) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              title: Text(role.name),
                              subtitle: role.description != null 
                                  ? Text(
                                      role.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    )
                                  : null,
                              leading: Icon(
                                Icons.assignment_ind,
                                color: AppColors.primary.withOpacity(0.7),
                              ),
                              selected: currentRoleId == role.id,
                              selectedTileColor: AppColors.primary.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                if (currentRoleId != role.id) {
                                  _updateUserRole(userId, role.id);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
} 