import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_role_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';

class UserRoleManagementScreen extends StatefulWidget {
  const UserRoleManagementScreen({Key? key}) : super(key: key);

  @override
  _UserRoleManagementScreenState createState() => _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  final UserRoleService _roleService = UserRoleService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isAuthorized = false;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkAuthorization();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorization() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isPastor = await authService.isCurrentUserPastor();
      
      setState(() {
        _isAuthorized = isPastor;
        _isLoading = false;
      });
      
      if (_isAuthorized) {
        _loadUsers();
      } else {
        // Si no está autorizado, mostrar mensaje y navegar hacia atrás después de un delay
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você não tem permissão para acessar esta página'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
          });
        }
      }
    } catch (e) {
      print('Erro ao verificar autorização: $e');
      setState(() {
        _isLoading = false;
        _isAuthorized = false;
      });
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
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final loadedUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        final userRole = data['role'] as String? ?? 'user';
        
        // Asegurarse de que el rol sea uno de los disponibles
        String safeRole = userRole;
        if (!_roleService.getAvailableRoles().contains(userRole)) {
          print('⚠️ Usuario ${doc.id} tiene un rol desconocido: $userRole');
          safeRole = 'user'; // Valor predeterminado seguro
        }
        
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? data['email'] ?? 'Usuário sem nome',
          'photoUrl': data['photoUrl'],
          'role': safeRole,
        };
      }).toList();
      
      setState(() {
        _users = loadedUsers;
        _filteredUsers = List.from(loadedUsers);
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    // No permitir cambiar el propio rol (para evitar que un pastor se quite sus privilegios)
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
      await _roleService.updateUserRole(userId, newRole);
      
      // Actualizar la lista local
      final index = _users.indexWhere((u) => u['id'] == userId);
      if (index >= 0) {
        setState(() {
          _users[index]['role'] = newRole;
          // También actualizar la lista filtrada
          final filteredIndex = _filteredUsers.indexWhere((u) => u['id'] == userId);
          if (filteredIndex >= 0) {
            _filteredUsers[filteredIndex]['role'] = newRole;
          }
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Papel do usuário atualizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erro ao atualizar papel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar papel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Papéis de Usuários'),
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
                    // Buscador
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
                    
                    // Lista de usuarios
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : _filteredUsers.isEmpty
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
                                    final userRole = user['role'] as String;
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
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userEmail,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                'Papel atual: ',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: userRole == 'pastor'
                                                      ? Colors.blue.withOpacity(0.1)
                                                      : Colors.grey.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  userRole,
                                                  style: TextStyle(
                                                    color: userRole == 'pastor'
                                                        ? Colors.blue.shade700
                                                        : Colors.grey.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: isCurrentUser
                                          ? const Tooltip(
                                              message: 'Não é possível alterar seu próprio papel',
                                              child: Icon(Icons.lock, color: Colors.grey),
                                            )
                                          : userRole == 'admin'
                                          ? Tooltip(
                                              message: 'Este usuário é administrador',
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'admin',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : DropdownButton<String>(
                                              value: _roleService.getAvailableRoles().contains(userRole) 
                                                  ? userRole 
                                                  : _roleService.getAvailableRoles().first,
                                              underline: Container(),
                                              icon: const Icon(Icons.edit, size: 16),
                                              items: _roleService.getAvailableRoles()
                                                .where((role) => role != 'admin')
                                                .map((role) {
                                                return DropdownMenuItem<String>(
                                                  value: role,
                                                  child: Text(role),
                                                );
                                              }).toList(),
                                              onChanged: (newRole) {
                                                if (newRole != null && newRole != userRole) {
                                                  _updateUserRole(userId, newRole);
                                                }
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
} 