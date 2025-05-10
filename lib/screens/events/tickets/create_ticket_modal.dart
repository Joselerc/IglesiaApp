import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../../../models/ticket_model.dart';
import '../../../services/ticket_service.dart';
import '../../../services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateTicketModal extends StatefulWidget {
  final EventModel event;

  const CreateTicketModal({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  _CreateTicketModalState createState() => _CreateTicketModalState();
}

class _CreateTicketModalState extends State<CreateTicketModal> {
  final _formKey = GlobalKey<FormState>();
  final _ticketService = TicketService();
  final _permissionService = PermissionService();
  
  final _typeController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _ticketsPerUserController = TextEditingController(text: '1');
  
  bool _isPaid = false;
  String _currency = 'BRL';
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPermission = false;
  
  // Nuevos campos
  bool _useEventDateAsDeadline = true;
  DateTime? _registrationDeadline;
  String _accessRestriction = 'public';
  
  // Lista de campos personalizados para el formulario
  List<TicketFormField> _formFields = [
    TicketFormField(
      id: 'fullName',
      label: 'Nome completo',
      type: 'text',
      isRequired: true,
      useUserProfile: true,
      userProfileField: 'displayName',
    ),
    TicketFormField(
      id: 'email',
      label: 'Email',
      type: 'email',
      isRequired: true,
      useUserProfile: true,
      userProfileField: 'email',
    ),
    TicketFormField(
      id: 'phone',
      label: 'Telefone',
      type: 'phone',
      isRequired: true,
      useUserProfile: true,
      userProfileField: 'phoneNumber',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    try {
      final isPastor = await _isPastor();
      final hasManageTicketPermission = await _permissionService.hasPermission('manage_event_tickets');
      
      setState(() {
        _hasPermission = isPastor || hasManageTicketPermission;
        
        if (!_hasPermission) {
          _errorMessage = 'No tienes permiso para crear tickets';
        }
      });
    } catch (e) {
      print('Error al verificar permisos: $e');
      setState(() {
        _errorMessage = 'Error al verificar permisos';
        _hasPermission = false;
      });
    }
  }
  
  Future<bool> _isPastor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'pastor';
      }
      return false;
    } catch (e) {
      print('Error al verificar si es pastor: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _ticketsPerUserController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDeadlineDate() async {
    final initialDate = _registrationDeadline ?? DateTime.now();
    final lastDate = widget.event.startDate ?? DateTime.now().add(const Duration(days: 365));
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: lastDate,
    );
    
    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      
      if (selectedTime != null) {
        setState(() {
          _registrationDeadline = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Não selecionada';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _createTicket() async {
    // No permitir crear tickets si no tiene permiso
    if (!_hasPermission) {
      setState(() {
        _errorMessage = 'No tienes permiso para crear tickets';
      });
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Validar fecha límite
      if (!_useEventDateAsDeadline && _registrationDeadline == null) {
        throw Exception('Você deve selecionar uma data limite para as inscrições');
      }
      
      // Crear el modelo de ticket
      final ticket = TicketModel(
        id: '', // Se asignará al guardar
        eventId: widget.event.id,
        type: _typeController.text.trim(),
        isPaid: _isPaid,
        price: _isPaid ? double.tryParse(_priceController.text) ?? 0 : 0,
        currency: _currency,
        quantity: _quantityController.text.isNotEmpty 
            ? int.tryParse(_quantityController.text) 
            : null,
        formFields: _formFields,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        // Nuevos campos
        useEventDateAsDeadline: _useEventDateAsDeadline,
        registrationDeadline: _useEventDateAsDeadline ? null : _registrationDeadline,
        accessRestriction: _accessRestriction,
        ticketsPerUser: int.tryParse(_ticketsPerUserController.text) ?? 1,
      );
      
      // Guardar el ticket
      await _ticketService.createTicket(widget.event.id, ticket);
      
      // Actualizar el evento para indicar que tiene tickets
      if (!widget.event.hasTickets) {
        await _updateEventHasTickets();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresso criado com sucesso')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateEventHasTickets() async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({'hasTickets': true});
    } catch (e) {
      print('Error al actualizar hasTickets: $e');
    }
  }

  void _addFormField() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        String fieldType = 'text';
        bool isRequired = true;
        bool useProfile = false;
        String profileField = '';
        
        return AlertDialog(
          title: Text('Adicionar campo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do campo',
                    hintText: 'Ex: Idade, País, etc.',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fieldType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de campo',
                  ),
                  items: [
                    DropdownMenuItem(value: 'text', child: Text('Texto')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                    DropdownMenuItem(value: 'number', child: Text('Número')),
                    DropdownMenuItem(value: 'select', child: Text('Seleção')),
                  ],
                  onChanged: (value) {
                    if (value != null) fieldType = value;
                  },
                ),
                SwitchListTile(
                  title: Text('Campo obrigatório'),
                  value: isRequired,
                  onChanged: (value) => isRequired = value,
                ),
                SwitchListTile(
                  title: Text('Usar dados do perfil'),
                  subtitle: Text('Preencher com informações do usuário'),
                  value: useProfile,
                  onChanged: (value) {
                    useProfile = value;
                    if (value) {
                      // Sugerir un campo de perfil basado en el tipo
                      if (fieldType == 'email') {
                        profileField = 'email';
                      } else if (fieldType == 'phone') {
                        profileField = 'phoneNumber';
                      } else {
                        profileField = 'displayName';
                      }
                    }
                  },
                ),
                if (useProfile)
                  DropdownButtonFormField<String>(
                    value: profileField,
                    decoration: InputDecoration(
                      labelText: 'Campo do perfil',
                    ),
                    items: [
                      DropdownMenuItem(value: 'displayName', child: Text('Nome')),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(value: 'phoneNumber', child: Text('Telefone')),
                    ],
                    onChanged: (value) {
                      if (value != null) profileField = value;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('O nome do campo é obrigatório')),
                  );
                  return;
                }
                
                // Generar un ID único basado en el nombre
                final id = nameController.text.trim()
                    .toLowerCase()
                    .replaceAll(' ', '_')
                    .replaceAll(RegExp(r'[^\w\s]'), '');
                
                // Verificar que el ID sea único
                if (_formFields.any((field) => field.id == id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Já existe um campo com esse nome')),
                  );
                  return;
                }
                
                final newField = TicketFormField(
                  id: id,
                  label: nameController.text.trim(),
                  type: fieldType,
                  isRequired: isRequired,
                  useUserProfile: useProfile,
                  userProfileField: useProfile ? profileField : '',
                );
                
                setState(() {
                  _formFields.add(newField);
                });
                
                Navigator.pop(context);
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
  
  void _editFormField(int index) {
    final field = _formFields[index];
    
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: field.label);
        String fieldType = field.type;
        bool isRequired = field.isRequired;
        bool useProfile = field.useUserProfile;
        String profileField = field.userProfileField;
        
        return AlertDialog(
          title: Text('Editar campo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do campo',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fieldType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de campo',
                  ),
                  items: [
                    DropdownMenuItem(value: 'text', child: Text('Texto')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'phone', child: Text('Telefone')),
                    DropdownMenuItem(value: 'number', child: Text('Número')),
                    DropdownMenuItem(value: 'select', child: Text('Seleção')),
                  ],
                  onChanged: (value) {
                    if (value != null) fieldType = value;
                  },
                ),
                SwitchListTile(
                  title: Text('Campo obrigatório'),
                  value: isRequired,
                  onChanged: (value) => isRequired = value,
                ),
                SwitchListTile(
                  title: Text('Usar dados do perfil'),
                  subtitle: Text('Preencher com informações do usuário'),
                  value: useProfile,
                  onChanged: (value) {
                    useProfile = value;
                  },
                ),
                if (useProfile)
                  DropdownButtonFormField<String>(
                    value: profileField.isNotEmpty ? profileField : 'displayName',
                    decoration: InputDecoration(
                      labelText: 'Campo do perfil',
                    ),
                    items: [
                      DropdownMenuItem(value: 'displayName', child: Text('Nome')),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(value: 'phoneNumber', child: Text('Telefone')),
                    ],
                    onChanged: (value) {
                      if (value != null) profileField = value;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('O nome do campo é obrigatório')),
                  );
                  return;
                }
                
                setState(() {
                  _formFields[index] = TicketFormField(
                    id: field.id, // Mantener el ID original
                    label: nameController.text.trim(),
                    type: fieldType,
                    isRequired: isRequired,
                    useUserProfile: useProfile,
                    userProfileField: useProfile ? profileField : '',
                    options: field.options,
                    defaultValue: field.defaultValue,
                  );
                });
                
                Navigator.pop(context);
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
  
  void _removeFormField(int index) {
    // No permitir eliminar los campos básicos si son los únicos
    if (_formFields.length <= 3 && index < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não é possível excluir todos os campos básicos')),
      );
      return;
    }
    
    setState(() {
      _formFields.removeAt(index);
    });
  }
  
  void _reorderFormFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _formFields.removeAt(oldIndex);
      _formFields.insert(newIndex, item);
    });
  }

  String _getFieldTypeText(String type) {
    switch (type) {
      case 'text':
        return 'Texto';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Telefone';
      case 'number':
        return 'Número';
      case 'select':
        return 'Seleção';
      default:
        return 'Desconhecido';
    }
  }

  IconData _getFieldTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      case 'number':
        return Icons.pin;
      case 'select':
        return Icons.list;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no tiene permiso, mostrar mensaje de error
    if (!_hasPermission && _errorMessage != null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header con gradiente
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.85),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Criar novo ingresso',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de ticket
                    TextFormField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de ingresso',
                        hintText: 'Ex: Geral, VIP, Estudante',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor digite o tipo de ingresso';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Entrada pagada ou gratuita
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SwitchListTile(
                          title: const Text('Ingresso pago'),
                          subtitle: Text(_isPaid ? 'Os participantes deverão pagar' : 'Ingresso gratuito'),
                          value: _isPaid,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _isPaid = value;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    // Precio (solo se é pagada)
                    if (_isPaid) ...[
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Precio
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Preço',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_isPaid) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o preço';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Informe um número válido';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Moeda
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Moeda',
                                border: OutlineInputBorder(),
                              ),
                              value: _currency,
                              items: const [
                                DropdownMenuItem(value: 'BRL', child: Text('BRL')),
                                DropdownMenuItem(value: 'USD', child: Text('USD')),
                                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _currency = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Quantidade disponível
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade disponível (opcional)',
                        hintText: 'Deixe em branco para ilimitado',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'Informe um número inteiro válido';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Limite de entradas por usuário
                    TextFormField(
                      controller: _ticketsPerUserController,
                      decoration: const InputDecoration(
                        labelText: 'Limite de ingressos por usuário',
                        hintText: 'Ex: 1, 2, 3',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe um número';
                        }
                        final number = int.tryParse(value);
                        if (number == null) {
                          return 'Informe um número inteiro válido';
                        }
                        if (number < 1) {
                          return 'O mínimo é 1 ingresso por usuário';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Seção de data limite para inscrições
                    _buildSectionHeader('Data limite para inscrições'),
                    const SizedBox(height: 10),
                    
                    // Opções de data limite
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text('Até a data do evento'),
                            value: true,
                            groupValue: _useEventDateAsDeadline,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _useEventDateAsDeadline = value ?? true;
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<bool>(
                            title: const Text('Escolher uma data limite personalizada'),
                            value: false,
                            groupValue: _useEventDateAsDeadline,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _useEventDateAsDeadline = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Selector de data limite (se personalizada)
                    if (!_useEventDateAsDeadline) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDeadlineDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 10),
                              Text(
                                'Data limite: ${_formatDate(_registrationDeadline)}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 28),
                    
                    // Seção de restrições de acesso
                    _buildSectionHeader('Permissões de registro'),
                    const SizedBox(height: 10),
                    
                    // Opções de restrição de acesso
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Aberto ao público'),
                            subtitle: const Text('Qualquer pessoa pode se registrar'),
                            value: 'public',
                            groupValue: _accessRestriction,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _accessRestriction = value ?? 'public';
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Apenas membros do ministério'),
                            value: 'ministry',
                            groupValue: _accessRestriction,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _accessRestriction = value ?? 'ministry';
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Apenas membros de grupos'),
                            value: 'group',
                            groupValue: _accessRestriction,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _accessRestriction = value ?? 'group';
                              });
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: const Text('Apenas membros da igreja'),
                            value: 'church',
                            groupValue: _accessRestriction,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _accessRestriction = value ?? 'church';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Seção de campos do formulário personalizado
                    _buildSectionHeader('Campos do formulário de registro'),
                    const SizedBox(height: 4),
                    Text(
                      'Defina os campos que o usuário deverá preencher ao se registrar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Lista de campos atuais
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ReorderableListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        onReorder: _reorderFormFields,
                        children: [
                          for (int i = 0; i < _formFields.length; i++)
                            Card(
                              key: Key('field_${_formFields[i].id}'),
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: ListTile(
                                title: Text(_formFields[i].label),
                                subtitle: Text(
                                  _getFieldTypeText(_formFields[i].type) +
                                      (_formFields[i].isRequired ? ' (Obrigatório)' : ' (Opcional)') +
                                      (_formFields[i].useUserProfile ? ' - Auto' : ''),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  child: Icon(
                                    _getFieldTypeIcon(_formFields[i].type),
                                    color: Theme.of(context).primaryColor,
                                    size: 18,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                                      onPressed: () => _editFormField(i),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _removeFormField(i),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Botão para adicionar campo
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _addFormField,
                        icon: Icon(Icons.add),
                        label: Text('Adicionar campo'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    // Mensagem de erro
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Botão de criar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Criar ingresso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 