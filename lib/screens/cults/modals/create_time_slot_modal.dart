import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/cult.dart';

class CreateTimeSlotModal extends StatefulWidget {
  final Cult cult;
  
  const CreateTimeSlotModal({
    Key? key, 
    required this.cult,
  }) : super(key: key);

  @override
  State<CreateTimeSlotModal> createState() => _CreateTimeSlotModalState();
}

class _CreateTimeSlotModalState extends State<CreateTimeSlotModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1, 
    minute: TimeOfDay.now().minute
  );
  bool _isSubmitting = false;
  
  // Lista de colores predefinidos para elegir
  final List<Color> _colorOptions = [
    Colors.blue[400]!,
    Colors.purple[300]!,
    Colors.indigo[400]!,
    Colors.cyan[600]!,
    Colors.teal[400]!,
    Colors.green[500]!,
    Colors.amber[600]!,
    Colors.deepOrange[400]!,
  ];
  
  // Color seleccionado (por defecto el primero)
  Color _selectedColor = Colors.blue[400]!;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Formatea la hora para mostrar en el campo de texto
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year, 
      now.month, 
      now.day, 
      timeOfDay.hour, 
      timeOfDay.minute
    );
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Convierte color a formato hexadecimal para guardarlo en Firestore
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
  
  // Selecciona la hora de inicio
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        
        // Si la hora de inicio es posterior a la de fin, ajustar la hora de fin
        final startDateTime = DateTime(2023, 1, 1, _startTime.hour, _startTime.minute);
        final endDateTime = DateTime(2023, 1, 1, _endTime.hour, _endTime.minute);
        
        if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1 > 23 ? 23 : _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
    }
  }
  
  // Selecciona la hora de fin
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endTime) {
      // Verificar que la hora de fin sea posterior a la de inicio
      final startDateTime = DateTime(2023, 1, 1, _startTime.hour, _startTime.minute);
      final pickedDateTime = DateTime(2023, 1, 1, picked.hour, picked.minute);
      
      if (pickedDateTime.isAfter(startDateTime)) {
        setState(() {
          _endTime = picked;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A hora de término deve ser posterior à hora de início'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Crea la franja horaria
  Future<void> _createTimeSlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Crear fecha completa con la hora seleccionada
      final cultDate = widget.cult.date;
      final startDateTime = DateTime(
        cultDate.year,
        cultDate.month,
        cultDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        cultDate.year,
        cultDate.month,
        cultDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      // Si el end time es menor que el start time, asumir que es al día siguiente
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime.add(const Duration(days: 1));
      }
      
      // Crear la franja horaria en Firestore
      await FirebaseFirestore.instance.collection('time_slots').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'entityId': widget.cult.id,
        'entityType': 'cult',
        'createdAt': Timestamp.now(),
        'isActive': true,
        'color': _colorToHex(_selectedColor), // Guardar el color seleccionado
      });
      
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el modal
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horário criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar horário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  // Widget para seleccionar el color
  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'Cor do horário',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _colorOptions.length,
            itemBuilder: (context, index) {
              final color = _colorOptions[index];
              final isSelected = _selectedColor == color;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                            ? color.withOpacity(0.8) 
                            : Colors.transparent,
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título del modal y botón de cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Novo Horário',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Campo de nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do horário',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira um nome';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Campos de hora (inicio y fin) en una fila
                Row(
                  children: [
                    // Hora de inicio
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectStartTime,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Hora de início',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: _formatTimeOfDay(_startTime),
                            ),
                            validator: (_) => null,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Hora de fin
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectEndTime,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Hora de término',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: _formatTimeOfDay(_endTime),
                            ),
                            validator: (_) => null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Selector de color
                _buildColorSelector(),
                
                const SizedBox(height: 16),
                
                // Campo de descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 24),
                
                // Botón de crear con padding adicional en la parte inferior
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createTimeSlot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor, // Usar el color seleccionado para el botón
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Criar Horário',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}