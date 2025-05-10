import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ministry.dart';
import '../../services/ministry_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class DeleteMinistriesScreen extends StatefulWidget {
  const DeleteMinistriesScreen({super.key});

  @override
  State<DeleteMinistriesScreen> createState() => _DeleteMinistriesScreenState();
}

class _DeleteMinistriesScreenState extends State<DeleteMinistriesScreen> {
  final MinistryService _ministryService = MinistryService();
  late final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eliminar Ministérios'),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('delete_ministry'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final hasPermission = snapshot.data ?? false;
          if (!hasPermission) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_accounts, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Você não tem permissão para excluir ministérios',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline3,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return _buildMinistryList();
        },
      ),
    );
  }
  
  Widget _buildMinistryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ministries').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}', style: AppTextStyles.bodyText1),
          );
        }
        
        final ministries = snapshot.data?.docs ?? [];
        
        if (ministries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Não há ministérios disponíveis',
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ministries.length,
          itemBuilder: (context, index) {
            final ministry = Ministry.fromFirestore(ministries[index]);
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.groups, color: AppColors.primary),
                ),
                title: Text(ministry.name, style: AppTextStyles.subtitle1),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteMinistry(ministry),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _confirmDeleteMinistry(Ministry ministry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminação'),
        content: Text('Você tem certeza de que deseja excluir o ministério "${ministry.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMinistry(ministry.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteMinistry(String ministryId) async {
    setState(() => _isLoading = true);
    
    try {
      await _ministryService.deleteMinistry(ministryId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ministério excluído com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir ministério: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 