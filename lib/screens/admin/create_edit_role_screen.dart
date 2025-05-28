import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import '../../models/role.dart';
import '../../services/role_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart'; // Para usar estilos definidos
// Importar la lista de permisos (la crearemos después o la definiremos aquí)
// import 'permissions_list.dart'; 

class CreateEditRoleScreen extends StatefulWidget {
  final Role? role; // Rol existente para editar, o null para crear

  const CreateEditRoleScreen({super.key, this.role});

  @override
  State<CreateEditRoleScreen> createState() => _CreateEditRoleScreenState();
}

class _CreateEditRoleScreenState extends State<CreateEditRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleService = RoleService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  // Mapa para mantener el estado de los checkboxes de permisos
  // La clave será el string del permiso, el valor será true/false
  Map<String, bool> _selectedPermissions = {}; 

  // --- Lista de Permisos Categorizada ---
  final Map<String, List<String>> _permissionCategories = {
    'Administração Geral': [
      'manage_roles', 'assign_user_roles', 'manage_users', 
      'view_user_list', 'view_user_details', 
      'send_push_notifications',
    ],
    'Configuração Home': [
      'manage_home_sections', 'manage_pages', 'manage_donations_config',
      'manage_livestream_config',
    ],
     'Conteúdo e Eventos': [
      'manage_announcements', 'manage_videos', 'manage_cults', 
      'manage_event_tickets', 'manage_event_attendance',
      'create_events', 'delete_events', 'manage_courses',
    ],
    'Comunidade (Grupos)': [
      'create_group', 'delete_group',
    ],
     'Comunidade (Ministérios)': [
      'create_ministry', 'delete_ministry',
    ],
    'Aconselhamento e Oração': [
      'manage_counseling_availability', 'manage_counseling_requests',
      'manage_private_prayers', 'assign_cult_to_prayer',
    ],
    'Relatórios e Estatísticas': [
      'view_ministry_stats', 'view_group_stats', 'view_schedule_stats',
      'view_course_stats', 'view_church_statistics', 'view_cult_stats',
      'view_work_stats',
    ],
    'MyKids (Gestão Infantil)': [
      'manage_family_profiles', 'manage_checkin_rooms',
    ],
    'Outros': [
        'manage_profile_fields', // Movido aquí o crear categoría "Perfil"
    ]
    // Asegúrate de que todos los 46 permisos estén en alguna categoría
  };

  // --- Mapa de Traducciones para Permisos ---
  final Map<String, String> _permissionTranslations = {
    // Administração Geral
    'manage_roles': 'Gerenciar Papéis',
    'assign_user_roles': 'Atribuir Papéis a Usuários',
    'manage_users': 'Gerenciar Usuários',
    'view_user_list': 'Ver Lista de Usuários',
    'view_user_details': 'Ver Detalhes de Usuários',
    'send_push_notifications': 'Enviar Notificações Push',
    
    // Configuração Home
    'manage_home_sections': 'Gerenciar Seções da Tela Inicial',
    'manage_pages': 'Gerenciar Páginas',
    'manage_donations_config': 'Configurar Doações',
    'manage_livestream_config': 'Configurar Transmissões ao Vivo',
    
    // Conteúdo e Eventos
    'manage_announcements': 'Gerenciar Anúncios',
    'manage_videos': 'Gerenciar Vídeos',
    'manage_cults': 'Gerenciar Cultos',
    'manage_event_tickets': 'Gerenciar Ingressos de Eventos',
    'manage_event_attendance': 'Gerenciar Presença em Eventos',
    'create_events': 'Criar Eventos',
    'delete_events': 'Excluir Eventos',
    'manage_courses': 'Gerenciar Cursos',
    
    // Comunidade (Grupos)
    'create_group': 'Criar Connect',
    'delete_group': 'Excluir Connect',
    
    // Comunidade (Ministérios)
    'create_ministry': 'Criar Ministérios',
    'delete_ministry': 'Excluir Ministérios',
    
    // Aconselhamento e Oração
    'manage_counseling_availability': 'Gerenciar Disponibilidade para Aconselhamento',
    'manage_counseling_requests': 'Gerenciar Solicitações de Aconselhamento',
    'manage_private_prayers': 'Gerenciar Orações Privadas',
    'assign_cult_to_prayer': 'Atribuir Culto à Oração',
    
    // Relatórios e Estatísticas
    'view_ministry_stats': 'Ver Estatísticas de Ministérios',
    'view_group_stats': 'Ver Estatísticas de Grupos',
    'view_schedule_stats': 'Ver Estatísticas de Escalas',
    'view_course_stats': 'Ver Estatísticas de Cursos',
    'view_church_statistics': 'Ver Estatísticas da Igreja',
    'view_cult_stats': 'Ver Estatísticas de Cultos',
    'view_work_stats': 'Ver Estatísticas de Trabalho',
    
    // MyKids (Gestão Infantil)
    'manage_family_profiles': 'Gerenciar Perfis Familiares',
    'manage_checkin_rooms': 'Gerenciar Salas e Check-in',
    
    // Outros
    'manage_profile_fields': 'Gerenciar Campos de Perfil',
  };

  // Obtener lista plana de todos los permisos
  List<String> get _allPermissions => _permissionCategories.values.expand((x) => x).toList();

  bool get _isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
    _descriptionController = TextEditingController(text: widget.role?.description ?? '');
    // Inicializar permisos
    _initializePermissions();
  }
  
  void _initializePermissions() {
     _selectedPermissions = {}; // Resetear
     final existingPermissions = widget.role?.permissions ?? [];
     for (var permission in _allPermissions) {
       _selectedPermissions[permission] = _isEditing ? existingPermissions.contains(permission) : false;
     }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    // Eliminar la verificación de permiso y continuar directamente
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final List<String> permissionsList = _selectedPermissions.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    try {
      bool success;
      final roleData = Role(
        id: widget.role?.id ?? '', // Usar ID existente o vacío si es nuevo
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null, // Guardar null si está vacío
        permissions: permissionsList,
      );

      if (_isEditing) {
        success = await _roleService.updateRole(roleData);
      } else {
        final newId = await _roleService.addRole(roleData);
        success = newId != null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Papel salvo com sucesso!' : 'Erro ao salvar papel.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
       print("Error al guardar rol: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: Colors.red),
         );
       }
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper para saber si todos los permisos están seleccionados
  bool _areAllSelected() {
    return _selectedPermissions.values.every((isSelected) => isSelected);
  }

  // Helper para seleccionar/deseleccionar todos
  void _toggleSelectAll(bool selectAll) {
    // Actualizar todos los permisos sin llamar a setState()
    for (var permission in _allPermissions) {
      _selectedPermissions[permission] = selectAll;
    }
    
    // Forzar reconstrucción solo de los componentes que realmente lo necesitan
    if (mounted) {
      setState(() {
        // No es necesario hacer nada aquí, solo forzar la reconstrucción
        // del widget que muestra el estado general
      });
    }
  }

  // Helper para actualizar un permiso individual sin reconstruir toda la lista
  void _updatePermission(String permission, bool value) {
    // Actualiza el mapa sin llamar a setState()
    _selectedPermissions[permission] = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Perfil' : 'Criar Novo Perfil'),
         backgroundColor: AppColors.primary, 
         foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 120), // Más espacio para el botón considerando el padding del dispositivo
              child: ListView(
                key: const PageStorageKey('permission_list'), // Mantener posición
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  TextFormField( // Nombre del Rol
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Papel',
                      hintText: 'Ex: Líder de Grupo, Editor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'O nome do papel é obrigatório.';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField( // Descripción
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (Opcional)',
                      hintText: 'Responsabilidades deste papel...',
                      border: OutlineInputBorder(),
                    ),
                     maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // --- Sección Permissões con "Selecionar Todos" ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Permissões',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      // Nuevo switch personalizado para Seleccionar/Deseleccionar Todos
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Todos', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 8),
                          _SelectAllSwitch(
                            value: _areAllSelected(),
                            onChanged: (value) {
                              _toggleSelectAll(value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // --- Lista Categorizada ---
                  ..._permissionCategories.entries.map((categoryEntry) {
                      final categoryTitle = categoryEntry.key;
                      final categoryPermissions = categoryEntry.value;

                      return Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // Título de la Categoría
                           Padding(
                             padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
                             child: Text(
                               categoryTitle,
                               style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                             ),
                           ),
                           // Lista de Switches para esta categoría
                           ...categoryPermissions.map((permission) {
                             return SmoothPermissionSwitch(
                               permission: permission,
                               initialValue: _selectedPermissions[permission] ?? false,
                               permissionTranslations: _permissionTranslations,
                               onChanged: (value) {
                                 _updatePermission(permission, value);
                               },
                             );
                           }).toList(),
                           const SizedBox(height: AppSpacing.sm), // Espacio después de cada categoría
                         ],
                       );
                   }).toList(),
                  // -------------------------

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            // Botón sticky al fondo
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: true,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + MediaQuery.of(context).padding.bottom * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Salvando...' : (_isEditing ? 'Salvar Alterações' : 'Criar Papel')),
                    onPressed: _isLoading ? null : _saveRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: AppTextStyles.button, // Usar estilo de botón definido
                      minimumSize: const Size(double.infinity, 50), // Ancho completo
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper para capitalizar texto (podría ir a un archivo de utils)
extension StringExtension on String {
    String capitalizeFirstLetter() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}

// Widget de switch personalizado para evitar reconstrucciones innecesarias
class SmoothPermissionSwitch extends StatefulWidget {
  final String permission;
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final Map<String, String> permissionTranslations;

  const SmoothPermissionSwitch({
    Key? key,
    required this.permission,
    required this.initialValue,
    required this.onChanged,
    required this.permissionTranslations,
  }) : super(key: key);

  @override
  State<SmoothPermissionSwitch> createState() => _SmoothPermissionSwitchState();
}

class _SmoothPermissionSwitchState extends State<SmoothPermissionSwitch> with SingleTickerProviderStateMixin {
  late bool _isChecked;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isChecked) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SmoothPermissionSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _isChecked) {
      _isChecked = widget.initialValue;
      if (_isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSwitch() {
    setState(() {
      _isChecked = !_isChecked;
      if (_isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onChanged(_isChecked);
    });
  }

  String _getPermissionTranslation(String permission) {
    // Buscar la traducción en el mapa, si no existe usar el método anterior como fallback
    return widget.permissionTranslations[permission] ?? 
           permission.replaceAll('_', ' ').capitalizeFirstLetter();
  }

  @override
  Widget build(BuildContext context) {
    // Buscar la traducción en el mapa, si no existe usar el método anterior como fallback
    final permissionText = _getPermissionTranslation(widget.permission);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _toggleSwitch();
          // Añadir feedback táctil
          HapticFeedback.lightImpact();
        },
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
          decoration: BoxDecoration(
            color: _isChecked ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isChecked ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  permissionText,
                  style: AppTextStyles.bodyText2.copyWith(
                    fontWeight: _isChecked ? FontWeight.w500 : FontWeight.normal,
                    color: _isChecked ? AppColors.primary.darken(10) : null,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    width: 45,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Color.lerp(
                        Colors.grey.shade300,
                        AppColors.primary,
                        _animation.value,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isChecked
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: _isChecked ? 22 : 2,
                          top: 2,
                          child: Container(
                            width: 21,
                            height: 21,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  spreadRadius: 0.1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extensión para manipular colores fácilmente
extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }
}

// Widget para el switch "Seleccionar todos" con el mismo estilo que SmoothPermissionSwitch
class _SelectAllSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SelectAllSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_SelectAllSwitch> createState() => _SelectAllSwitchState();
}

class _SelectAllSwitchState extends State<_SelectAllSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.value;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isChecked) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_SelectAllSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _isChecked) {
      _isChecked = widget.value;
      if (_isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSwitch() {
    setState(() {
      _isChecked = !_isChecked;
      if (_isChecked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onChanged(_isChecked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          _toggleSwitch();
          // Añadir feedback táctil
          HapticFeedback.lightImpact();
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 45,
              height: 25,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Color.lerp(
                  Colors.grey.shade300,
                  AppColors.primary,
                  _animation.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isChecked
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isChecked ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 0.1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 