import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profile_field.dart';
import '../../services/profile_fields_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom/selection_field.dart';

class ProfileFieldsAdminScreen extends StatefulWidget {
  const ProfileFieldsAdminScreen({super.key});

  @override
  State<ProfileFieldsAdminScreen> createState() => _ProfileFieldsAdminScreenState();
}

class _ProfileFieldsAdminScreenState extends State<ProfileFieldsAdminScreen> {
  final ProfileFieldsService _profileFieldsService = ProfileFieldsService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Campos de Perfil'),
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
        future: _permissionService.hasPermission('manage_profile_fields'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text('Erro ao verificar permissão: ${permissionSnapshot.error}'));
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
                    Text('Acesso Negado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Você não tem permissão para gerenciar campos de perfil.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          // Contenido original cuando tiene permiso
          return StreamBuilder<List<ProfileField>>(
            stream: _profileFieldsService.getAllProfileFields(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro ao carregar os campos: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final fields = snapshot.data ?? [];

              if (fields.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Não há campos de perfil definidos',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditFieldDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Campo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: fields.length,
                    itemBuilder: (context, index) {
                      final field = fields[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            field.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.description,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      _getLocalizedFieldType(field.type),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                  ),
                                  Chip(
                                    label: Text(
                                      field.isRequired ? 'Obrigatório' : 'Opcional',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: field.isRequired
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    side: BorderSide(
                                      color: field.isRequired
                                          ? Colors.red.shade300
                                          : Colors.green.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                  ),
                                  Chip(
                                    label: Text(
                                      field.isActive ? 'Ativo' : 'Inativo',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: field.isActive
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    side: BorderSide(
                                      color: field.isActive
                                          ? Colors.green.shade300
                                          : Colors.grey.shade400,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: AppColors.primary),
                                tooltip: 'Editar',
                                onPressed: () => _showAddEditFieldDialog(context, field),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Excluir',
                                onPressed: () => _confirmDeleteField(context, field),
                              ),
                            ],
                          ),
                        ),
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
          );
        },
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_profile_fields'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.done &&
              permissionSnapshot.hasData &&
              permissionSnapshot.data == true) {
            return FloatingActionButton(
              onPressed: () => _showAddEditFieldDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  String _getLocalizedFieldType(String type) {
    switch (type) {
      case 'text':
        return 'Texto';
      case 'number':
        return 'Número';
      case 'date':
        return 'Data';
      case 'select':
        return 'Seleção';
      case 'email':
        return 'E-mail';
      case 'phone':
        return 'Telefone';
      default:
        return type;
    }
  }

  Future<void> _showAddEditFieldDialog(BuildContext context, [ProfileField? field]) async {
    final bool hasPermission = await _permissionService.hasPermission('manage_profile_fields');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sem permissão para gerenciar campos de perfil.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEditProfileFieldModalContent(
        initialField: field,
        profileFieldsService: _profileFieldsService,
      ),
    );
  }

  Future<void> _confirmDeleteField(BuildContext context, ProfileField field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza de que deseja excluir o campo "${field.name}"?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _profileFieldsService.deleteProfileField(field.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campo excluído com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir o campo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

class _AddEditProfileFieldModalContent extends StatefulWidget {
  final ProfileField? initialField;
  final ProfileFieldsService profileFieldsService;

  const _AddEditProfileFieldModalContent({
    Key? key,
    this.initialField,
    required this.profileFieldsService,
  }) : super(key: key);

  @override
  State<_AddEditProfileFieldModalContent> createState() => _AddEditProfileFieldModalContentState();
}

class _AddEditProfileFieldModalContentState extends State<_AddEditProfileFieldModalContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedType = 'text';
  bool _isRequired = false;
  bool _isActive = true;
  bool _isSaving = false;

  // Controlador para el input de nuevas opciones del select
  final TextEditingController _optionInputController = TextEditingController();
  // Lista para mantener las opciones del select que se van añadiendo
  List<String> _currentOptions = [];

  final List<String> _types = ['text', 'number', 'date', 'email', 'phone', 'select']; // 'select' añadido de nuevo

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialField?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialField?.description ?? '');
    _selectedType = widget.initialField?.type ?? 'text';
    _isRequired = widget.initialField?.isRequired ?? false;
    _isActive = widget.initialField?.isActive ?? true;
    // Inicializar _currentOptions si estamos editando un campo 'select' existente
    if (widget.initialField != null && widget.initialField!.type == 'select') {
      _currentOptions = List<String>.from(widget.initialField!.options ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _optionInputController.dispose(); // Dispose del nuevo controller
    super.dispose();
  }

  String _getLocalizedFieldType(String type) {
    switch (type) {
      case 'text': return 'Texto';
      case 'number': return 'Número';
      case 'date': return 'Data';
      case 'email': return 'E-mail';
      case 'phone': return 'Telefone';
      case 'select': return 'Seleção'; // Localización para 'select'
      default: return type;
    }
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Validación adicional para el tipo 'select'
    if (_selectedType == 'select' && _currentOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, adicione ao menos uma opção para o campo de seleção.'), backgroundColor: Colors.red),
      );
      return;
    }

    print('PRINT DEBUG: Attempting to save field.'); // <--- PRINT 4
    print('PRINT DEBUG: _selectedType during save: $_selectedType'); // <--- PRINT 5
    if (_selectedType == 'select') {
      print('PRINT DEBUG: _currentOptions during save: $_currentOptions'); // <--- PRINT 6
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final fieldToSave = ProfileField(
        id: widget.initialField?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        isRequired: _isRequired,
        order: widget.initialField?.order ?? DateTime.now().millisecondsSinceEpoch,
        isActive: _isActive,
        options: _selectedType == 'select' ? _currentOptions : null, // Guardar _currentOptions si es tipo 'select'
        createdAt: widget.initialField?.createdAt ?? DateTime.now(),
        createdBy: widget.initialField?.createdBy ?? user.uid,
      );

      if (widget.initialField == null) {
        await widget.profileFieldsService.createProfileField(fieldToSave);
      } else {
        await widget.profileFieldsService.updateProfileField(fieldToSave);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialField == null ? 'Campo criado com sucesso' : 'Campo atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('PRINT DEBUG: Building _AddEditProfileFieldModalContent. _selectedType is: $_selectedType'); // <--- PRINT 2 (MOVIDO Y CORREGIDO)
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                widget.initialField == null ? 'Criar Campo de Perfil' : 'Editar Campo de Perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome do Campo',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.text_fields),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Por favor, insira um nome';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SelectionField(
                        label: 'Tipo de Campo',
                        hint: 'Seleccione o tipo de campo',
                        value: _selectedType,
                        options: _types,
                        isRequired: true,
                        prefixIcon: Icon(Icons.category, color: AppColors.primary.withOpacity(0.7)),
                        itemLabelBuilder: (type) => _getLocalizedFieldType(type),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              print('PRINT DEBUG: Tipo de Campo cambiado a: $value'); // <--- PRINT 1
                              _selectedType = value;
                              // Limpiar opciones si se cambia de 'select' a otro tipo
                              if (_selectedType != 'select') {
                                _currentOptions.clear();
                                _optionInputController.clear();
                              }
                            });
                          }
                        },
                      ),
                      // UI Condicional para gestionar opciones del tipo 'select'
                      if (_selectedType == 'select') ...[
                        // Este print es solo para lógica, no devuelve widget
                        () { print('PRINT DEBUG: Rendering UI for select options'); return const SizedBox.shrink(); }(), // <--- PRINT 3 (CORREGIDO)
                        const SizedBox(height: 20),
                        Text('Opções de Seleção', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _optionInputController,
                                decoration: InputDecoration(
                                  labelText: 'Nova Opção',
                                  hintText: 'Digite uma opção...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                // No añadir directamente al presionar Enter para dar chance al botón
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final optionText = _optionInputController.text.trim();
                                if (optionText.isNotEmpty && !_currentOptions.contains(optionText)) {
                                  setState(() {
                                    _currentOptions.add(optionText);
                                    _optionInputController.clear();
                                  });
                                } else if (optionText.isNotEmpty && _currentOptions.contains(optionText)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Esta opção já foi adicionada.'), backgroundColor: Colors.orange),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                              child: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_currentOptions.isEmpty)
                          const Text('Nenhuma opção adicionada ainda.', style: TextStyle(color: Colors.grey))
                        else
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _currentOptions.map((option) => Chip(
                              label: Text(option),
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              deleteIcon: Icon(Icons.close, size: 16, color: AppColors.primary.withOpacity(0.7)),
                              onDeleted: () {
                                setState(() {
                                  _currentOptions.remove(option);
                                });
                              },
                            )).toList(),
                          ),
                      ],
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text('Campo Obrigatório'),
                        subtitle: const Text('Os usuários devem preencher este campo'),
                        value: _isRequired,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setState(() => _isRequired = value),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Campo Ativo'),
                        subtitle: const Text('Mostrar este campo no perfil'),
                        value: _isActive,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 16.0),
                child: ElevatedButton.icon(
                  icon: _isSaving 
                      ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    widget.initialField == null ? 'Criar Campo' : 'Salvar Alterações', 
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveField,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 