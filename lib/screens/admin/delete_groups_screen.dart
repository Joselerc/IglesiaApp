import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

class DeleteGroupsScreen extends StatefulWidget {
  const DeleteGroupsScreen({super.key});

  @override
  State<DeleteGroupsScreen> createState() => _DeleteGroupsScreenState();
}

class _DeleteGroupsScreenState extends State<DeleteGroupsScreen> {
  final GroupService _groupService = GroupService();
  late final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.deleteGroups),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('delete_group'),
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
                      AppLocalizations.of(context)!.noPermissionDeleteGroups,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headline3,
                    ),
                  ],
                ),
              ),
            );
          }
          
          return _buildGroupList();
        },
      ),
    );
  }
  
  Widget _buildGroupList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(AppLocalizations.of(context)!.error(snapshot.error.toString()), style: AppTextStyles.bodyText1),
          );
        }
        
        final groups = snapshot.data?.docs ?? [];
        
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noGroupsAvailable,
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = Group.fromFirestore(groups[index]);
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.groups, color: AppColors.primary),
                ),
                title: Text(group.name, style: AppTextStyles.subtitle1),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteGroup(group),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _confirmDeleteGroup(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.confirmDeleteGroup(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup(group.id);
            },
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteGroup(String groupId) async {
    setState(() => _isLoading = true);
    
    try {
      await _groupService.deleteGroup(groupId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo eliminado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar grupo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 