// lib/screens/cults/modals/add_ministry_member_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/cult.dart';
import '../../../models/cult_ministry.dart';

class AddMinistryMemberModal extends StatefulWidget {
  final CultMinistry cultMinistry;
  final Cult cult;
  
  const AddMinistryMemberModal({
    Key? key,
    required this.cultMinistry,
    required this.cult,
  }) : super(key: key);

  @override
  State<AddMinistryMemberModal> createState() => _AddMinistryMemberModalState();
}

class _AddMinistryMemberModalState extends State<AddMinistryMemberModal> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  String? _selectedUserId;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
    
    // Inicializar con las horas del ministerio
    _startTime = TimeOfDay.fromDateTime(widget.cultMinistry.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.cultMinistry.endTime);
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    
    try {
      // Cargar todos los usuarios sin filtrar por churchId
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      setState(() {
        _users = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Usuario sin nombre',
            'photoUrl': data['photoUrl'] ?? '',
          };
        }).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _roleController.dispose();
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
  
  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un usuario')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final startDateTime = _combineDateWithTime(widget.cult.date, _startTime);
      final endDateTime = _combineDateWithTime(widget.cult.date, _endTime);
      
      // Obtener los miembros actuales
      final doc = await FirebaseFirestore.instance
          .collection('cult_ministries')
          .doc(widget.cultMinistry.id)
          .get();
      
      if (!doc.exists) {
        throw Exception('El ministerio no existe');
      }
      
      final ministryData = doc.data() as Map<String, dynamic>;
      final members = List<dynamic>.from(ministryData['members'] as List<dynamic>? ?? []);
      
      // Verificar si el usuario ya está asignado
      final existingMemberIndex = members.indexWhere((member) => 
        member is Map<String, dynamic> && member['userId'] == _selectedUserId);
      
      if (existingMemberIndex >= 0) {
        throw Exception('Este usuario ya está asignado a este ministerio');
      }
      
      // Añadir el nuevo miembro
      members.add({
        'userId': _selectedUserId,
        'role': _roleController.text.trim(),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
      });
      
      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('cult_ministries')
          .doc(widget.cultMinistry.id)
          .update({'members': members});
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Miembro añadido correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir miembro: $e')),
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
              'Añadir Miembro al Ministerio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Selección de usuario
            _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Usuario',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedUserId,
                  items: _users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'] as String,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundImage: (user['photoUrl'] as String).isNotEmpty 
                                ? NetworkImage(user['photoUrl'] as String) 
                                : null,
                            child: (user['photoUrl'] as String).isEmpty 
                                ? const Icon(Icons.person, size: 15) 
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(user['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUserId = value;
                    });
                  },
                ),
            
            const SizedBox(height: 16),
            
            // Rol del miembro
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Rol en el Ministerio',
                border: OutlineInputBorder(),
                hintText: 'Ej: Director, Músico, Cantante, etc.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese un rol';
                }
                return null;
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
                onPressed: _isLoading ? null : _addMember,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Añadir Miembro'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}