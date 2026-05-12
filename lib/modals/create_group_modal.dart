import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class CreateGroupModal extends StatefulWidget {
  const CreateGroupModal({super.key});

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PermissionService _permissionService = PermissionService();
  List<DocumentReference> _selectedAdmins = [];
  bool _isLoading = false;
  bool _isCheckingPermission = true;
  bool _hasPermission = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  int get _nameRemainingChars => 100 - (_nameController.text.length);
  int get _descriptionRemainingChars => 250 - (_descriptionController.text.length);
  
  static const Color primaryColor = AppColors.primary; // Usar el mismo color que ministerios
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isCheckingPermission = true);
    _hasPermission = await _permissionService.hasPermission('create_group');
    if (mounted) {
      setState(() => _isCheckingPermission = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    // Verificar permiso antes de crear
    final bool hasPermission = await _permissionService.hasPermission('create_group');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionCreateGroups), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final user = Provider.of<AuthService>(context, listen: false).currentUser;
        if (user == null) return;

        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        final group = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'imageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': userRef,
          'members': [userRef],
          'groupAdmin': _selectedAdmins.isEmpty ? [userRef] : _selectedAdmins,
        };

        await FirebaseFirestore.instance.collection('groups').add(group);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.groupCreatedSuccessfully),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorCreatingGroup(e.toString())),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
  }

  Future<void> _selectAdmins() async {
    final selectedAdmins = await showModalBottomSheet<List<DocumentReference>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectAdminsDialog(
        initialSelected: _selectedAdmins,
        primaryColor: primaryColor,
      ),
    );

    if (selectedAdmins != null) {
      setState(() {
        _selectedAdmins = selectedAdmins;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _isCheckingPermission
          ? Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : !_hasPermission
            ? Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar for dragging
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 24),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.accessDenied,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.noPermissionCreateGroupsLong,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.understood),
                    ),
                  ],
                ),
              )
            : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar for dragging
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.createGroup,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.grey[700], size: 18),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del grupo
                          Text(
                            AppLocalizations.of(context)!.groupName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.enterGroupName,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.group, color: primaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              counterText: '',
                            ),
                            maxLength: 100,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.pleaseEnterGroupName;
                              }
                              return null;
                            },
                          ),
                          
                          // Contador de caracteres
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 16),
                              child: Text(
                                '$_nameRemainingChars/100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _nameRemainingChars < 10 ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          
                          // Descripción
                          Text(
                            AppLocalizations.of(context)!.groupDescription,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.enterGroupDescription,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(Icons.description, color: primaryColor),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              counterText: '',
                            ),
                            maxLength: 250,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.pleaseEnterDescription;
                              }
                              return null;
                            },
                          ),
                          
                          // Contador de caracteres
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 16),
                              child: Text(
                                '$_descriptionRemainingChars/250',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _descriptionRemainingChars < 20 ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          
                          // Selección de administradores
                          Text(
                            AppLocalizations.of(context)!.selectAdministrators,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.administratorsCanManage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          OutlinedButton.icon(
                            onPressed: _selectAdmins,
                            icon: Icon(Icons.person_add, color: primaryColor),
                            label: Text(
                              _selectedAdmins.isEmpty 
                                ? AppLocalizations.of(context)!.addAdministrators 
                                : AppLocalizations.of(context)!.administratorsSelected(_selectedAdmins.length.toString()),
                              style: const TextStyle(color: primaryColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              side: BorderSide(color: primaryColor.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: primaryColor.withOpacity(0.05),
                            ),
                          ),
                          
                          if (_selectedAdmins.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.people, color: primaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.selectedAdministrators,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(
                                    _selectedAdmins.length, 
                                    (index) => FutureBuilder<DocumentSnapshot>(
                                      future: _selectedAdmins[index].get(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return ListTile(
                                            leading: const CircleAvatar(
                                              backgroundColor: AppColors.primary,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1, 
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(AppLocalizations.of(context)!.loading),
                                          );
                                        }
                                        
                                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                                        final name = userData['name'] ?? AppLocalizations.of(context)!.unknownUser;
                                        final photoUrl = userData['photoUrl'] ?? '';
                                        
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: primaryColor.withOpacity(0.1),
                                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                            child: photoUrl.isEmpty 
                                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(color: primaryColor))
                                                : null,
                                          ),
                                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                          trailing: IconButton(
                                            icon: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.close, color: Colors.red[700], size: 12),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _selectedAdmins.removeAt(index);
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Información adicional
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.autoMemberInfo,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Botón de crear
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createGroup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.createGroup,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class SelectAdminsDialog extends StatefulWidget {
  final List<DocumentReference> initialSelected;
  final Color primaryColor;
  
  const SelectAdminsDialog({
    super.key,
    this.initialSelected = const [],
    this.primaryColor = AppColors.secondary,
  });

  @override
  State<SelectAdminsDialog> createState() => _SelectAdminsDialogState();
}

class _SelectAdminsDialogState extends State<SelectAdminsDialog> {
  late List<DocumentReference> _selectedAdmins;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selectedAdmins = List.from(widget.initialSelected);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          // Handle bar for dragging
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: widget.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.selectAdministrators,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.grey[700], size: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchUsers,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: widget.primaryColor));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.noUsersAvailable,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                final users = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  
                  final userData = doc.data() as Map<String, dynamic>;
                  final name = (userData['name'] ?? '').toString().toLowerCase();
                  final email = (userData['email'] ?? '').toString().toLowerCase();
                  
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();
                
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.noResultsFound(_searchQuery),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final userData = doc.data() as Map<String, dynamic>;
                    final name = userData['name'] ?? AppLocalizations.of(context)!.user;
                    final email = userData['email'] ?? '';
                    final photoUrl = userData['photoUrl'] ?? '';
                    final userRef = FirebaseFirestore.instance.collection('users').doc(doc.id);
                    final isSelected = _selectedAdmins.contains(userRef);
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected ? widget.primaryColor.withOpacity(0.1) : Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? widget.primaryColor : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isSelected 
                              ? widget.primaryColor.withOpacity(0.2) 
                              : Colors.grey.withOpacity(0.2),
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty 
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', 
                                  style: TextStyle(color: isSelected ? widget.primaryColor : Colors.grey[700]))
                              : null,
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(email),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedAdmins.add(userRef);
                              } else {
                                _selectedAdmins.remove(userRef);
                              }
                            });
                          },
                          activeColor: widget.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAdmins.remove(userRef);
                            } else {
                              _selectedAdmins.add(userRef);
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _selectedAdmins),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(_selectedAdmins.isEmpty 
                    ? AppLocalizations.of(context)!.confirm 
                    : AppLocalizations.of(context)!.select(_selectedAdmins.length.toString())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}