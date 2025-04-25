import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/cult.dart';
import '../../../models/ministry.dart';

class CreateCultMinistryModal extends StatefulWidget {
  final Cult cult;
  
  const CreateCultMinistryModal({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<CreateCultMinistryModal> createState() => _CreateCultMinistryModalState();
}

class _CreateCultMinistryModalState extends State<CreateCultMinistryModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  bool _isTemporary = false;
  String? _selectedMinistryId;
  bool _isLoading = false;
  List<Ministry> _ministries = [];
  bool _isLoadingMinistries = true;
  
  @override
  void initState() {
    super.initState();
    _loadMinistries();
    
    // Inicializar con las horas del culto
    _startTime = TimeOfDay.fromDateTime(widget.cult.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.cult.endTime);
  }
  
  Future<void> _loadMinistries() async {
    setState(() {
      _isLoadingMinistries = true;
    });
    
    try {
      // Cargar todos los ministerios sin filtrar por churchId
      final snapshot = await FirebaseFirestore.instance
          .collection('ministries')
          .get();
      
      setState(() {
        _ministries = snapshot.docs.map((doc) => Ministry.fromFirestore(doc)).toList();
        _isLoadingMinistries = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMinistries = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ministerios: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Si la hora de fin es anterior a la hora de inicio, ajustarla
        if (_timeToDouble(_endTime) <= _timeToDouble(_startTime)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
    }
  }
  
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        if (_timeToDouble(picked) > _timeToDouble(_startTime)) {
          _endTime = picked;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La hora de fin debe ser posterior a la hora de inicio')),
          );
        }
      });
    }
  }
  
  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }
  
  DateTime _combineDateWithTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  
  Future<void> _createCultMinistry() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isTemporary && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar un nombre para el ministerio temporal')),
      );
      return;
    }
    
    if (!_isTemporary && _selectedMinistryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un ministerio')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final startDateTime = _combineDateWithTime(widget.cult.date, _startTime);
      final endDateTime = _combineDateWithTime(widget.cult.date, _endTime);
      
      // Obtener el nombre del ministerio
      String ministryName = _nameController.text.trim();
      if (!_isTemporary && _selectedMinistryId != null) {
        final ministry = _ministries.firstWhere((m) => m.id == _selectedMinistryId);
        ministryName = ministry.name;
      }
      
      // Crear el ministerio del culto
      await FirebaseFirestore.instance.collection('cult_ministries').add({
        'cultId': FirebaseFirestore.instance.collection('cults').doc(widget.cult.id),
        'ministryId': _isTemporary ? null : FirebaseFirestore.instance.collection('ministries').doc(_selectedMinistryId),
        'name': ministryName,
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'isTemporary': _isTemporary,
        'members': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ministerio añadido correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir ministerio: $e')),
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
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Añadir Ministerio al Culto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Tipo de ministerio (existente o temporal)
            SwitchListTile(
              title: const Text('Ministerio Temporal'),
              subtitle: const Text('Crear un ministerio solo para este culto'),
              value: _isTemporary,
              onChanged: (value) {
                setState(() {
                  _isTemporary = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Si es temporal, mostrar campo para nombre
            if (_isTemporary)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Ministerio',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_isTemporary && (value == null || value.trim().isEmpty)) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              )
            // Si no es temporal, mostrar dropdown de ministerios existentes
            else
              _isLoadingMinistries
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Ministerio',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMinistryId,
                    items: _ministries.map((ministry) {
                      return DropdownMenuItem<String>(
                        value: ministry.id,
                        child: Text(ministry.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMinistryId = value;
                      });
                    },
                  ),
            
            const SizedBox(height: 16),
            
            // Horario
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de inicio',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_startTime.format(context)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_endTime.format(context)),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCultMinistry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Añadir Ministerio'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 