import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profile_field.dart';
import '../../services/profile_fields_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom/selection_field.dart';

class ProfileFieldsAdminScreen extends StatefulWidget {
  const ProfileFieldsAdminScreen({super.key});

  @override
  State<ProfileFieldsAdminScreen> createState() => _ProfileFieldsAdminScreenState();
}

class _ProfileFieldsAdminScreenState extends State<ProfileFieldsAdminScreen> {
  final ProfileFieldsService _profileFieldsService = ProfileFieldsService();
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
      body: StreamBuilder<List<ProfileField>>(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditFieldDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: field?.name ?? '');
    final _descriptionController = TextEditingController(text: field?.description ?? '');
    String _selectedType = field?.type ?? 'text';
    bool _isRequired = field?.isRequired ?? false;
    bool _isActive = field?.isActive ?? true;
    final _optionsController = TextEditingController(
      text: field?.options?.join(', ') ?? '',
    );

    final types = ['text', 'number', 'date', 'select', 'email', 'phone'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            field == null ? 'Criar Campo de Perfil' : 'Editar Campo de Perfil',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Campo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.text_fields),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SelectionField(
                    label: 'Tipo de Campo',
                    hint: 'Seleccione el tipo de campo',
                    value: _selectedType,
                    options: types,
                    isRequired: true,
                    prefixIcon: Icon(
                      Icons.category, 
                      color: AppColors.primary.withOpacity(0.7)
                    ),
                    itemLabelBuilder: (type) => _getLocalizedFieldType(type),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedType == 'select')
                    TextFormField(
                      controller: _optionsController,
                      decoration: InputDecoration(
                        labelText: 'Opções (separadas por vírgulas)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Opção 1, Opção 2, Opção 3',
                        prefixIcon: const Icon(Icons.list),
                      ),
                      validator: (value) {
                        if (_selectedType == 'select' && (value == null || value.isEmpty)) {
                          return 'Por favor, insira as opções';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Campo Obrigatório'),
                    subtitle: const Text('Os usuários devem preencher este campo'),
                    value: _isRequired,
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _isRequired = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Campo Ativo'),
                    subtitle: const Text('Mostrar este campo no perfil'),
                    value: _isActive,
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw Exception('Usuário não autenticado');
                    }

                    List<String>? options;
                    if (_selectedType == 'select' && _optionsController.text.isNotEmpty) {
                      options = _optionsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      
                      // Asegurar que no haya opciones duplicadas
                      options = options.toSet().toList();
                      
                      // Si no hay opciones después de filtrar, mostrar un error
                      if (options.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Debe ingresar al menos una opción válida para el campo de selección'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    if (field == null) {
                      // Crear nuevo campo
                      final newField = ProfileField(
                        id: '',
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        type: _selectedType,
                        isRequired: _isRequired,
                        order: DateTime.now().millisecondsSinceEpoch, // Temporal
                        isActive: _isActive,
                        options: options,
                        createdAt: DateTime.now(),
                        createdBy: user.uid,
                      );
                      await _profileFieldsService.createProfileField(newField);
                    } else {
                      // Actualizar campo existente
                      final updatedField = ProfileField(
                        id: field.id,
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        type: _selectedType,
                        isRequired: _isRequired,
                        order: field.order,
                        isActive: _isActive,
                        options: options,
                        createdAt: field.createdAt,
                        createdBy: field.createdBy,
                      );
                      await _profileFieldsService.updateProfileField(updatedField);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            field == null
                                ? 'Campo criado com sucesso'
                                : 'Campo atualizado com sucesso',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(field == null ? 'Criar' : 'Atualizar'),
            ),
          ],
        ),
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