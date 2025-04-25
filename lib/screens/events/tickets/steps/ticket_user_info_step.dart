import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketUserInfoStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplete;
  final VoidCallback onBack;

  const TicketUserInfoStep({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<TicketUserInfoStep> createState() => _TicketUserInfoStepState();
}

class _TicketUserInfoStepState extends State<TicketUserInfoStep> {
  final List<Map<String, dynamic>> _fields = [
    {
      'id': 'email',
      'name': 'Email',
      'required': true,
      'order': 1,
      'enabled': true,
    },
    {
      'id': 'fullName',
      'name': 'Nombre completo',
      'required': true,
      'order': 2,
      'enabled': true,
    },
    {
      'id': 'phone',
      'name': 'Teléfono',
      'required': false,
      'order': 3,
      'enabled': true,
    },
  ];

  final _newFieldController = TextEditingController();

  @override
  void dispose() {
    _newFieldController.dispose();
    super.dispose();
  }

  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Nuevo Campo'),
        content: TextField(
          controller: _newFieldController,
          decoration: const InputDecoration(
            labelText: 'Nombre del campo',
            hintText: 'Ej.: Edad, Dirección, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (_newFieldController.text.isNotEmpty) {
                setState(() {
                  _fields.add({
                    'id': _newFieldController.text.toLowerCase().replaceAll(' ', '_'),
                    'name': _newFieldController.text,
                    'required': false,
                    'order': _fields.length + 1,
                    'enabled': true,
                  });
                });
                _newFieldController.clear();
                Navigator.pop(context);

                // Guardar el nuevo campo en Firestore para futuros eventos
                FirebaseFirestore.instance
                    .collection('ticket_fields')
                    .add({
                      'name': _newFieldController.text,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _handleComplete() {
    final enabledFields = _fields.where((field) => field['enabled']).toList()
      ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    widget.onComplete({
      'requiredFields': enabledFields
          .where((field) => field['required'])
          .map((field) => field['id'])
          .toList(),
      'optionalFields': enabledFields
          .where((field) => !field['required'])
          .map((field) => field['id'])
          .toList(),
      'fieldOrder': enabledFields
          .map((field) => field['id'])
          .toList(),
    });
  }

  // Método para obtener el icono adecuado según el tipo de campo
  IconData _getIconForField(String fieldId) {
    switch (fieldId) {
      case 'email':
        return Icons.email;
      case 'fullName':
        return Icons.person;
      case 'phone':
        return Icons.phone;
      case 'age':
        return Icons.cake;
      case 'address':
        return Icons.home;
      case 'city':
        return Icons.location_city;
      case 'country':
        return Icons.flag;
      case 'postalCode':
        return Icons.local_post_office;
      case 'documentId':
        return Icons.badge;
      default:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información requerida',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona la información que necesitas de los asistentes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _fields.removeAt(oldIndex);
                _fields.insert(newIndex, item);
                
                // Actualizar el orden
                for (var i = 0; i < _fields.length; i++) {
                  _fields[i]['order'] = i + 1;
                }
              });
            },
            children: _fields.map((field) {
              return Card(
                key: ValueKey(field['id']),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForField(field['id']), 
                          color: Colors.grey.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field['name'],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Orden: ${field['order']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: field['enabled'] ? Colors.blue.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Incluir',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: field['enabled'] ? Colors.blue.shade700 : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: field['enabled'],
                                onChanged: field['id'] == 'email' || field['id'] == 'fullName'
                                    ? null
                                    : (value) {
                                        setState(() {
                                          field['enabled'] = value;
                                          // Si el campo no está habilitado, no puede ser requerido
                                          if (!value) {
                                            field['required'] = false;
                                          }
                                        });
                                      },
                                activeColor: Colors.blue,
                                activeTrackColor: Colors.blue.shade100,
                              ),
                            ],
                          ),
                          if (field['enabled'])
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: field['required'] ? Colors.purple.shade50 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Obligatorio',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: field['required'] ? Colors.purple.shade700 : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: field['required'],
                                  onChanged: field['id'] == 'email' || field['id'] == 'fullName'
                                      ? null
                                      : (value) {
                                          setState(() {
                                            field['required'] = value;
                                          });
                                        },
                                  activeColor: Colors.purple,
                                  activeTrackColor: Colors.purple.shade100,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddFieldDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Nuevo Campo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text('Atrás'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _handleComplete,
                      child: const Text('Crear Entrada'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 