import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
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

  AppLocalizations get _loc => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final isPastor = await _isPastor();
      final hasManageTicketPermission =
          await _permissionService.hasPermission('manage_event_tickets');

      setState(() {
        _hasPermission = isPastor || hasManageTicketPermission;

        if (!_hasPermission) {
          _errorMessage = _loc.ticketPermissionDenied;
        }
      });
    } catch (e) {
      print('Error al verificar permisos: $e');
      setState(() {
        _errorMessage = _loc.ticketPermissionError;
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
    final lastDate =
        widget.event.startDate ?? DateTime.now().add(const Duration(days: 365));

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
    if (date == null) return _loc.ticketDeadlineNotSelected;
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _createTicket() async {
    // No permitir crear tickets si no tiene permiso
    if (!_hasPermission) {
      setState(() {
        _errorMessage = _loc.ticketPermissionDenied;
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
        throw Exception(_loc.unauthenticatedUser);
      }

      // Validar fecha límite
      if (!_useEventDateAsDeadline && _registrationDeadline == null) {
        throw Exception(_loc.ticketDeadlineRequired);
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
        registrationDeadline:
            _useEventDateAsDeadline ? null : _registrationDeadline,
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
          SnackBar(content: Text(_loc.ticketCreatedSuccessfully)),
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
    final loc = _loc;
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        String fieldType = 'text';
        bool isRequired = true;
        bool useProfile = false;
        String profileField = '';

        return AlertDialog(
          title: Text(loc.ticketFieldDialogAddTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.ticketFieldDialogNameLabel,
                    hintText: loc.ticketFieldDialogNameHint,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fieldType,
                  decoration: InputDecoration(
                    labelText: loc.ticketFieldTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'text', child: Text(loc.ticketFieldTypeText)),
                    DropdownMenuItem(
                        value: 'email', child: Text(loc.ticketFieldTypeEmail)),
                    DropdownMenuItem(
                        value: 'phone', child: Text(loc.ticketFieldTypePhone)),
                    DropdownMenuItem(
                        value: 'number',
                        child: Text(loc.ticketFieldTypeNumber)),
                    DropdownMenuItem(
                        value: 'select',
                        child: Text(loc.ticketFieldTypeSelect)),
                  ],
                  onChanged: (value) {
                    if (value != null) fieldType = value;
                  },
                ),
                SwitchListTile(
                  title: Text(loc.ticketFieldRequiredSwitch),
                  value: isRequired,
                  onChanged: (value) => isRequired = value,
                ),
                SwitchListTile(
                  title: Text(loc.ticketFieldUseProfileSwitch),
                  subtitle: Text(loc.ticketFieldUseProfileSubtitle),
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
                      labelText: loc.ticketFieldProfileLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'displayName', child: Text(loc.name)),
                      DropdownMenuItem(value: 'email', child: Text(loc.email)),
                      DropdownMenuItem(
                          value: 'phoneNumber', child: Text(loc.phone)),
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
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.ticketFieldNameRequired)),
                  );
                  return;
                }

                // Generar un ID único basado en el nombre
                final id = nameController.text
                    .trim()
                    .toLowerCase()
                    .replaceAll(' ', '_')
                    .replaceAll(RegExp(r'[^\w\s]'), '');

                // Verificar que el ID sea único
                if (_formFields.any((field) => field.id == id)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.ticketFieldDuplicated)),
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
              child: Text(loc.add),
            ),
          ],
        );
      },
    );
  }

  void _editFormField(int index) {
    final loc = _loc;
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
          title: Text(loc.ticketFieldDialogEditTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: loc.ticketFieldDialogNameLabel,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fieldType,
                  decoration: InputDecoration(
                    labelText: loc.ticketFieldTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'text', child: Text(loc.ticketFieldTypeText)),
                    DropdownMenuItem(
                        value: 'email', child: Text(loc.ticketFieldTypeEmail)),
                    DropdownMenuItem(
                        value: 'phone', child: Text(loc.ticketFieldTypePhone)),
                    DropdownMenuItem(
                        value: 'number',
                        child: Text(loc.ticketFieldTypeNumber)),
                    DropdownMenuItem(
                        value: 'select',
                        child: Text(loc.ticketFieldTypeSelect)),
                  ],
                  onChanged: (value) {
                    if (value != null) fieldType = value;
                  },
                ),
                SwitchListTile(
                  title: Text(loc.ticketFieldRequiredSwitch),
                  value: isRequired,
                  onChanged: (value) => isRequired = value,
                ),
                SwitchListTile(
                  title: Text(loc.ticketFieldUseProfileSwitch),
                  subtitle: Text(loc.ticketFieldUseProfileSubtitle),
                  value: useProfile,
                  onChanged: (value) {
                    useProfile = value;
                  },
                ),
                if (useProfile)
                  DropdownButtonFormField<String>(
                    value:
                        profileField.isNotEmpty ? profileField : 'displayName',
                    decoration: InputDecoration(
                      labelText: loc.ticketFieldProfileLabel,
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'displayName', child: Text(loc.name)),
                      DropdownMenuItem(value: 'email', child: Text(loc.email)),
                      DropdownMenuItem(
                          value: 'phoneNumber', child: Text(loc.phone)),
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
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.ticketFieldNameRequired)),
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
              child: Text(loc.save),
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
        SnackBar(content: Text(_loc.ticketsCannotRemoveBaseFields)),
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
    final loc = _loc;
    switch (type) {
      case 'text':
        return loc.ticketFieldTypeText;
      case 'email':
        return loc.ticketFieldTypeEmail;
      case 'phone':
        return loc.ticketFieldTypePhone;
      case 'number':
        return loc.ticketFieldTypeNumber;
      case 'select':
        return loc.ticketFieldTypeSelect;
      default:
        return loc.unknown;
    }
  }

  String _buildFieldSubtitle(TicketFormField field) {
    final loc = _loc;
    final tokens = <String>[_getFieldTypeText(field.type)];
    tokens.add(field.isRequired ? loc.requiredField : loc.optional);
    if (field.useUserProfile) {
      tokens.add(loc.ticketFieldAutoFillLabel);
    }
    return tokens.where((token) => token.isNotEmpty).join(' • ');
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
    final loc = _loc;
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
                child: Text(loc.close),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  loc.ticketModalTitle,
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
                      decoration: InputDecoration(
                        labelText: loc.ticketTypeLabel,
                        hintText: loc.ticketTypeHint,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return loc.ticketEntryNameRequired;
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
                          title: Text(loc.ticketPaidToggleLabel),
                          subtitle: Text(_isPaid
                              ? loc.ticketPaidToggleSubtitlePaid
                              : loc.ticketPaidToggleSubtitleFree),
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
                              decoration: InputDecoration(
                                labelText: loc.ticketPriceLabel,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_isPaid) {
                                  if (value == null || value.trim().isEmpty) {
                                    return loc.ticketPriceRequired;
                                  }
                                  if (double.tryParse(value) == null) {
                                    return loc.ticketPriceInvalid;
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
                              decoration: InputDecoration(
                                labelText: loc.ticketCurrencyLabel,
                                border: OutlineInputBorder(),
                              ),
                              value: _currency,
                              items: const [
                                DropdownMenuItem(
                                    value: 'BRL', child: Text('BRL')),
                                DropdownMenuItem(
                                    value: 'USD', child: Text('USD')),
                                DropdownMenuItem(
                                    value: 'EUR', child: Text('EUR')),
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
                      decoration: InputDecoration(
                        labelText: loc.ticketAvailableQuantityLabel,
                        hintText: loc.ticketAvailableQuantityHint,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return loc.enterAValidNumber;
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Limite de entradas por usuário
                    TextFormField(
                      controller: _ticketsPerUserController,
                      decoration: InputDecoration(
                        labelText: loc.ticketPerUserLabel,
                        hintText: loc.ticketPerUserHint,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.ticketEnterNumber;
                        }
                        final number = int.tryParse(value);
                        if (number == null) {
                          return loc.enterAValidNumber;
                        }
                        if (number < 1) {
                          return loc.ticketPerUserMinimum;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Sección de fecha límite
                    _buildSectionHeader(loc.ticketDeadlineSectionTitle),
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
                            title: Text(loc.ticketDeadlineOptionEvent),
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
                            title: Text(loc.ticketDeadlineOptionCustom),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18,
                                  color: Theme.of(context).primaryColor),
                              const SizedBox(width: 10),
                              Text(
                                loc.ticketDeadlineLabel(
                                    _formatDate(_registrationDeadline)),
                                style: const TextStyle(fontSize: 15),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Sección de permisos
                    _buildSectionHeader(loc.ticketAccessSectionTitle),
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
                            title: Text(loc.ticketAccessOptionPublic),
                            subtitle:
                                Text(loc.ticketAccessOptionPublicSubtitle),
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
                            title: Text(loc.ticketAccessOptionMinistry),
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
                            title: Text(loc.ticketAccessOptionGroup),
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
                            title: Text(loc.ticketAccessOptionChurch),
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

                    // Sección de campos personalizados
                    _buildSectionHeader(loc.ticketFormFieldsTitle),
                    const SizedBox(height: 4),
                    Text(
                      loc.ticketFormFieldsDescription,
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
                                subtitle:
                                    Text(_buildFieldSubtitle(_formFields[i])),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2),
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
                                      icon: Icon(Icons.edit,
                                          size: 20, color: Colors.blue),
                                      onPressed: () => _editFormField(i),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          size: 20, color: Colors.red),
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
                        label: Text(loc.ticketAddFieldButtonLabel),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
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
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
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
                            : Text(loc.ticketCreateButtonLabel,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
