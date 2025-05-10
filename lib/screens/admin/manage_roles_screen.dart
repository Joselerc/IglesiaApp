import 'package:flutter/material.dart';
import '../../models/role.dart';
import '../../services/role_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart'; 
// Importar pantalla de crear/editar 
import 'create_edit_role_screen.dart'; 

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  final RoleService _roleService = RoleService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;

  Future<void> _showDeleteConfirmation(BuildContext context, Role role) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem certeza que deseja excluir o papel "${role.name}"?'),
                const SizedBox(height: 10),
                const Text(
                  'Atenção: Isso pode afetar usuários que têm este papel atribuído.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteRole(role.id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRole(String roleId) async {
    // Verificación adicional de permisos antes de realizar acciones críticas
    final bool hasPermission = await _permissionService.hasPermission('manage_roles');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem permissão para excluir papéis'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _roleService.deleteRole(roleId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Papel excluído com sucesso' : 'Falha ao excluir papel'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir papel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Papéis'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_roles'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(
              child: Text('Erro ao verificar permissão: ${permissionSnapshot.error}'),
            );
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Acesso Negado', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Você não tem permissão para gerenciar papéis e permissões.',
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          return Stack(
            children: [
              StreamBuilder<List<Role>>(
                stream: _roleService.getRoles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar papéis: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum papel encontrado. Crie o primeiro!'));
                  }

                  final roles = snapshot.data!;

                  return ListView.separated(
                    itemCount: roles.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return ListTile(
                        title: Text(role.name, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(role.description ?? 'Sem descrição'),
                            const SizedBox(height: 4),
                            Text(
                              '${role.permissions.length} permissões atribuídas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Editar papel',
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => CreateEditRoleScreen(role: role))
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Excluir papel',
                              onPressed: () => _showDeleteConfirmation(context, role),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEditRoleScreen(role: role)));
                        },
                      );
                    },
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEditRoleScreen()));
        },
        tooltip: 'Criar Novo Papel',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
} 