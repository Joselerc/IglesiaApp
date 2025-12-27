import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../l10n/app_localizations.dart';

/// Widget para seleccionar usuarios.
/// 
/// Este widget permite buscar y seleccionar múltiples usuarios de una lista.
/// Es reutilizable para diferentes contextos como grupos, ministerios, etc.
class SelectUsersWidget extends StatefulWidget {
  /// Lista opcional de IDs de usuarios que deben ser excluidos de la selección.
  final List<String> excludeUserIds;
  
  /// Título para mostrar en la parte superior del widget.
  final String title;
  
  /// Texto del botón de confirmación.
  final String confirmButtonText;
  
  /// Función que se llama cuando se confirma la selección.
  final Function(List<String> selectedUserIds) onConfirm;
  
  /// Texto mostrado cuando no se encuentran usuarios.
  final String emptyStateText;
  
  /// Placeholder para el campo de búsqueda.
  final String searchPlaceholder;
  
  /// Determina si permite selección múltiple o única.
  final bool multiSelect;

  const SelectUsersWidget({
    Key? key,
    this.excludeUserIds = const [],
    this.title = 'Selecionar usuários',
    this.confirmButtonText = 'Confirmar seleção',
    required this.onConfirm,
    this.emptyStateText = 'Nenhum usuário encontrado',
    this.searchPlaceholder = 'Buscar usuários...',
    this.multiSelect = true,
  }) : super(key: key);

  @override
  State<SelectUsersWidget> createState() => _SelectUsersWidgetState();
}

class _SelectUsersWidgetState extends State<SelectUsersWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('displayName')
          .get();

      final users = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'displayName': data['displayName'] ?? data['name'] ?? 'Usuário sem nome',
              'email': data['email'] ?? '',
              'photoURL': data['photoURL'] ?? data['photoUrl'],
            };
          })
          .where((user) => 
            // Filtrar usuários excluídos
            !widget.excludeUserIds.contains(user['id'])
          )
          .toList();

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar usuários: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers
            .where((user) => 
              user['displayName'].toString().toLowerCase().contains(query.toLowerCase()) ||
              user['email'].toString().toLowerCase().contains(query.toLowerCase())
            )
            .toList();
      }
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        if (!widget.multiSelect) {
          // Si es selección única, limpiar selecciones previas
          _selectedUserIds.clear();
        }
        _selectedUserIds.add(userId);
      }
    });
  }

  void _confirmSelection() {
    widget.onConfirm(_selectedUserIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final title =
        widget.title.isNotEmpty ? widget.title : (strings?.inviteMembers ?? '');
    final confirmText = widget.confirmButtonText.isNotEmpty
        ? widget.confirmButtonText
        : (strings?.sendInvitations ?? '');
    final emptyText = widget.emptyStateText.isNotEmpty
        ? widget.emptyStateText
        : (strings?.noUsersFound ?? '');
    final searchHint = widget.searchPlaceholder.isNotEmpty
        ? widget.searchPlaceholder
        : (strings?.searchUsers ?? '');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom, // Respetar área segura
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.subtitle1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Buscador
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                filled: true,
                fillColor: AppColors.warmSand,
              ),
              onChanged: _filterUsers,
            ),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // Contador de seleccionados
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                strings?.selectedUsers(_selectedUserIds.length) ??
                    'Usuarios seleccionados: ${_selectedUserIds.length}',
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_selectedUserIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedUserIds.clear();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(strings?.clear ?? 'Limpiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: AppSpacing.xs),
          
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
                              Icons.search_off,
                              size: 48,
                              color: AppColors.mutedGray,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              emptyText,
                              style: AppTextStyles.subtitle2,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = _selectedUserIds.contains(user['id']);
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: AppSpacing.xs),
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.xs),
                              side: BorderSide(
                                color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: (user['photoURL'] != null &&
                                        (user['photoURL'] as String).isNotEmpty &&
                                        (user['photoURL'] as String)
                                            .toLowerCase()
                                            .startsWith('http'))
                                    ? NetworkImage(user['photoURL'])
                                    : null,
                                backgroundColor: AppColors.warmSand,
                                child: (user['photoURL'] == null ||
                                        (user['photoURL'] as String).isEmpty)
                                    ? Icon(Icons.person,
                                        color: AppColors.textSecondary)
                                    : null,
                              ),
                              title: Text(
                                user['displayName'],
                                style: AppTextStyles.subtitle2,
                              ),
                              subtitle: Text(
                                user['email'],
                                style: AppTextStyles.bodyText2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: widget.multiSelect
                                  ? Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) {
                                        _toggleUserSelection(user['id']);
                                      },
                                    )
                                  : Radio<String>(
                                      value: user['id'],
                                      groupValue: _selectedUserIds.isEmpty ? null : _selectedUserIds.first,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) {
                                        if (value != null) {
                                          _toggleUserSelection(value);
                                        }
                                      },
                                    ),
                              onTap: () {
                                _toggleUserSelection(user['id']);
                              },
                              selectedTileColor: AppColors.warmSand.withOpacity(0.3),
                              selected: isSelected,
                            ),
                          );
                        },
                      ),
          ),
          
          // Botón de confirmar
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: AppSpacing.sm),
            child: ElevatedButton(
              onPressed: _selectedUserIds.isEmpty || _isLoading ? null : _confirmSelection,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
                      ),
                    )
                  : Text(
                      confirmText,
                      style: AppTextStyles.button,
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 
