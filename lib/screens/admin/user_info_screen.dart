import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'user_detail_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key}) : super(key: key);

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PermissionService _permissionService = PermissionService();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  Future<void>? _fetchUsersFuture;
  
  @override
  void initState() {
    super.initState();
    _fetchUsersFuture = _fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterUsers(_searchController.text);
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap({...data, 'id': doc.id});
      }).toList();
      
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredUsers = _users;
        });
      }
      return;
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    final filtered = _users.where((user) {
      final name = user.name?.toLowerCase() ?? '';
      final surname = user.surname?.toLowerCase() ?? '';
      final displayName = user.displayName?.toLowerCase() ?? '';
      final email = user.email.toLowerCase();
      
      return name.contains(lowercaseQuery) || 
             surname.contains(lowercaseQuery) || 
             displayName.contains(lowercaseQuery) || 
             email.contains(lowercaseQuery);
    }).toList();

    if (mounted) {
      setState(() {
        _filteredUsers = filtered;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _filteredUsers = _users;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.userInformation),
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
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('view_user_details'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorVerifyingPermission(permissionSnapshot.error.toString())));
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Icon(
                        Icons.visibility_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.unauthorizedAccess,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você não tem permissão para visualizar detalhes de usuários.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                   ],
                 ),
              ),
            );
          }
          
          return FutureBuilder<void>(
             future: _fetchUsersFuture,
             builder: (context, dataSnapshot) {
                if (_isLoading) {
                   return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                }
             
                return Column(
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
                          labelText: AppLocalizations.of(context)!.searchUser,
                          hintText: AppLocalizations.of(context)!.enterNameSurnameEmail,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, child) {
                              return value.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearSearch,
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _users.isEmpty ? Icons.person_off : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _users.isEmpty 
                                    ? 'Nenhum usuário encontrado'
                                    : 'Nenhum resultado para "${_searchController.text}"',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _users.isEmpty 
                                    ? 'Não há usuários cadastrados'
                                    : 'Tente uma busca diferente',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
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
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  backgroundImage: user.photoUrl != null && 
                                      user.photoUrl!.isNotEmpty && 
                                      Uri.tryParse(user.photoUrl!) != null
                                      ? NetworkImage(user.photoUrl!)
                                      : null,
                                  child: !(user.photoUrl != null && 
                                      user.photoUrl!.isNotEmpty && 
                                      Uri.tryParse(user.photoUrl!) != null)
                                      ? Text(
                                          user.name?.isNotEmpty == true 
                                              ? user.name![0] 
                                              : (user.email.isNotEmpty ? user.email[0] : '?'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  user.displayName ?? user.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (user.phone != null && user.phone!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          user.phone!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserDetailScreen(userId: user.email),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                    ),
                  ],
                );
             }
          );
        },
      ),
    );
  }
} 