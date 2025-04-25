import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/cult.dart';
import '../../../services/work_schedule_service.dart';

class DuplicateCultModal extends StatefulWidget {
  final Cult cult;
  
  const DuplicateCultModal({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<DuplicateCultModal> createState() => _DuplicateCultModalState();
}

class _DuplicateCultModalState extends State<DuplicateCultModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  
  // Opciones de duplicación
  bool _duplicateAnnouncements = true;
  bool _duplicateSchedule = true;
  bool _duplicateTimeSlots = true;
  bool _duplicateMinistries = true;
  bool _duplicateUsers = true;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar con valores del culto original
    _nameController.text = '${widget.cult.name} (copia)';
    _selectedDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day + 7,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.cult.startTime);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Future<void> _duplicateCult() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Crear nuevo culto
      final cultDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // Calcular la duración del culto original
      final originalDuration = widget.cult.endTime.difference(widget.cult.startTime);
      
      // Calcular la hora de fin sumando la duración
      final endTime = startTime.add(originalDuration);
      
      // Crear el nuevo culto
      final newCultData = {
        'serviceId': FirebaseFirestore.instance.collection('services').doc(widget.cult.serviceId),
        'name': _nameController.text,
        'date': Timestamp.fromDate(cultDate),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'planificado',
        'createdBy': widget.cult.createdBy,
        'createdAt': Timestamp.now(),
      };
      
      final newCultRef = await FirebaseFirestore.instance.collection('cults').add(newCultData);
      
      // Configurar opciones de duplicación
      Map<String, bool> duplicateOptions = {
        'duplicateAnnouncements': _duplicateAnnouncements,
        'duplicateSchedule': _duplicateSchedule,
        'duplicateTimeSlots': _duplicateTimeSlots,
        'duplicateMinistries': _duplicateMinistries,
        'duplicateUsers': _duplicateUsers,
      };
      
      // Duplicar franjas horarias y asignaciones
      await WorkScheduleService().duplicateCult(
        sourceCultId: widget.cult.id,
        newCultId: newCultRef.id,
        newCultDate: cultDate,
        options: duplicateOptions,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Culto duplicado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al duplicar culto: $e'),
            backgroundColor: Colors.red,
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
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Duplicar Culto'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del culto
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del culto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Fecha
                const Text(
                  'Fecha del nuevo culto',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat.yMMMMd('es').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Hora
                const Text(
                  'Hora de inicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                InkWell(
                  onTap: () => _selectTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      _selectedTime.format(context),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Opciones de duplicación
                const Text(
                  'Elementos a duplicar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                CheckboxListTile(
                  value: _duplicateAnnouncements,
                  onChanged: (value) {
                    setState(() {
                      _duplicateAnnouncements = value ?? true;
                    });
                  },
                  title: const Text('Anuncios'),
                  subtitle: const Text('Se duplicarán los anuncios del culto'),
                  secondary: const Icon(Icons.announcement),
                  activeColor: Colors.deepPurple,
                ),
                
                CheckboxListTile(
                  value: _duplicateSchedule,
                  onChanged: (value) {
                    setState(() {
                      _duplicateSchedule = value ?? true;
                      // Si se desmarca horario, desmarcar todo lo que depende de él
                      if (!_duplicateSchedule) {
                        _duplicateTimeSlots = false;
                        _duplicateMinistries = false;
                        _duplicateUsers = false;
                      }
                    });
                  },
                  title: const Text('Horario'),
                  subtitle: const Text('Estructura temporal del culto'),
                  secondary: const Icon(Icons.schedule),
                  activeColor: Colors.deepPurple,
                ),
                
                CheckboxListTile(
                  value: _duplicateTimeSlots,
                  onChanged: _duplicateSchedule ? (value) {
                    setState(() {
                      _duplicateTimeSlots = value ?? true;
                      // Si se desmarca franjas, desmarcar lo que depende
                      if (!_duplicateTimeSlots) {
                        _duplicateMinistries = false;
                        _duplicateUsers = false;
                      }
                    });
                  } : null,
                  title: const Text('Franjas Horarias'),
                  subtitle: const Text('Divisiones de tiempo dentro del culto'),
                  secondary: const Icon(Icons.timeline),
                  activeColor: Colors.deepPurple,
                ),
                
                CheckboxListTile(
                  value: _duplicateMinistries,
                  onChanged: _duplicateTimeSlots ? (value) {
                    setState(() {
                      _duplicateMinistries = value ?? true;
                      // Si se desmarca ministerios, desmarcar usuarios
                      if (!_duplicateMinistries) {
                        _duplicateUsers = false;
                      }
                    });
                  } : null,
                  title: const Text('Ministerios'),
                  subtitle: const Text('Asignaciones de ministerios a franjas horarias'),
                  secondary: const Icon(Icons.people_alt),
                  activeColor: Colors.deepPurple,
                ),
                
                CheckboxListTile(
                  value: _duplicateUsers,
                  onChanged: _duplicateMinistries ? (value) {
                    setState(() {
                      _duplicateUsers = value ?? true;
                    });
                  } : null,
                  title: const Text('Usuarios Invitados'),
                  subtitle: const Text('Se enviarán invitaciones a las mismas personas'),
                  secondary: const Icon(Icons.person_add),
                  activeColor: Colors.deepPurple,
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _duplicateCult,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Duplicar Culto'),
          ),
        ),
      ),
    );
  }
} 