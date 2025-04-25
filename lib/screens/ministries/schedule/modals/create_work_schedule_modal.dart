import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/work_schedule.dart';
import 'package:intl/intl.dart';

class CreateWorkScheduleModal extends StatefulWidget {
  final String ministryId;

  const CreateWorkScheduleModal({
    super.key,
    required this.ministryId,
  });

  @override
  State<CreateWorkScheduleModal> createState() => _CreateWorkScheduleModalState();
}

class _CreateWorkScheduleModalState extends State<CreateWorkScheduleModal> {
  final _formKey = GlobalKey<FormState>();
  final _jobNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _requiredWorkers = 1;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<String> _selectedWorkers = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _workersData = [];
  List<Map<String, dynamic>> _ministryMembersData = [];
  bool _isLoadingMinistryMembers = false;

  @override
  void initState() {
    super.initState();
    // Cargar los miembros del ministerio
    _loadMinistryMembers();
  }

  // Método para cargar los miembros del ministerio
  Future<void> _loadMinistryMembers() async {
    setState(() {
      _isLoadingMinistryMembers = true;
    });
    
    try {
      print('🔍 Iniciando carga de miembros para ministerio ID: ${widget.ministryId}');
      
      // 1. Primero intentamos cargar directamente los miembros del ministerio
      final ministryDoc = await FirebaseFirestore.instance
          .collection('ministries')
          .doc(widget.ministryId)
          .get();
      
      if (!ministryDoc.exists) {
        print('❌ Error: El ministerio no existe. ID: ${widget.ministryId}');
        throw Exception('El ministerio no existe');
      }
      
      print('✅ Ministerio encontrado: ${ministryDoc.id}');
      final ministryData = ministryDoc.data() as Map<String, dynamic>;
      
      // Lista para almacenar todos los IDs de miembros, independientemente de su origen
      List<String> allMemberIds = [];
      
      // 2. Verificar si el campo 'members' existe y procesarlo según su formato
      if (ministryData.containsKey('members')) {
        final dynamic membersField = ministryData['members'];
        print('📋 Tipo de datos del campo members: ${membersField.runtimeType}');
        
        if (membersField is List) {
          print('📋 Campo members es una lista de longitud: ${membersField.length}');
          
          // Procesar cada elemento según su tipo
          for (var member in membersField) {
            if (member is String) {
              print('✓ Miembro encontrado (String): $member');
              allMemberIds.add(member);
            } else if (member is DocumentReference) {
              print('✓ Miembro encontrado (DocumentReference): ${member.id}');
              allMemberIds.add(member.id);
            } else if (member is Map) {
              // Podría ser un mapa con información del usuario
              String? userId = member['id'] ?? member['userId'];
              if (userId != null) {
                print('✓ Miembro encontrado (Map): $userId');
                allMemberIds.add(userId);
              }
            } else {
              print('⚠️ Formato de miembro no reconocido: $member (${member.runtimeType})');
            }
          }
        } else {
          print('⚠️ Campo members no es una lista: $membersField');
        }
      } else {
        print('⚠️ El campo "members" no existe en el documento del ministerio');
      }
      
      // 3. También verificamos si existe un campo 'participants' (alternativo común)
      if (ministryData.containsKey('participants')) {
        final dynamic participantsField = ministryData['participants'];
        print('🔍 Encontrado campo participants de tipo: ${participantsField.runtimeType}');
        
        if (participantsField is List) {
          for (var participant in participantsField) {
            String? participantId;
            
            if (participant is String) {
              participantId = participant;
            } else if (participant is DocumentReference) {
              participantId = participant.id;
            } else if (participant is Map) {
              participantId = participant['id'] ?? participant['userId'];
            }
            
            if (participantId != null && !allMemberIds.contains(participantId)) {
              print('✓ Participante encontrado: $participantId');
              allMemberIds.add(participantId);
            }
          }
        }
      }
      
      // 4. Como último recurso, intentar cargar usuarios con el rol correcto para este ministerio
      if (allMemberIds.isEmpty) {
        print('🔍 Intentando buscar usuarios vinculados a este ministerio por rol...');
        
        final usersQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('ministries', arrayContains: widget.ministryId)
            .limit(30) // Límite razonable
            .get();
            
        for (var doc in usersQuery.docs) {
          print('✓ Usuario encontrado por consulta: ${doc.id}');
          allMemberIds.add(doc.id);
        }
      }
      
      print('👥 Total de IDs de miembros encontrados: ${allMemberIds.length}');
      
      // Verificar si encontramos miembros para procesar
      if (allMemberIds.isEmpty) {
        print('ℹ️ No se encontraron miembros para este ministerio');
        setState(() {
          _ministryMembersData = [];
          _isLoadingMinistryMembers = false;
        });
        return;
      }
      
      // 5. Ahora cargamos los datos de cada miembro
      final List<Map<String, dynamic>> membersData = [];
      
      for (int i = 0; i < allMemberIds.length; i++) {
        final memberId = allMemberIds[i];
        print('🔄 Procesando miembro $i: $memberId');
        
        try {
          final memberDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();
          
          if (!memberDoc.exists) {
            print('⚠️ Usuario no encontrado: $memberId');
            continue;
          }
          
          print('✅ Usuario encontrado: ${memberDoc.id}');
          final userData = memberDoc.data() as Map<String, dynamic>;
          
          final name = userData['name'] ?? userData['displayName'] ?? 'Usuario sin nombre';
          final photoUrl = userData['photoUrl'] ?? '';
          final email = userData['email'] ?? '';
          
          print('👤 Datos del usuario - Nombre: $name, Email: $email');
          
          membersData.add({
            'id': memberId,
            'name': name,
            'photoUrl': photoUrl,
            'email': email,
          });
        } catch (memberError) {
          print('❌ Error procesando miembro $i: $memberError');
          // Continuar con el siguiente miembro
        }
      }
      
      print('✅ Procesamiento completado. Miembros encontrados: ${membersData.length}');
      
      setState(() {
        _ministryMembersData = membersData;
        _isLoadingMinistryMembers = false;
      });
    } catch (e) {
      print('❌ Error global al cargar miembros del ministerio: $e');
      setState(() {
        _isLoadingMinistryMembers = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar miembros: $e')),
        );
      }
    }
  }

  void _showDateTimePicker(bool isStartDate) async {
    // Seleccionar fecha
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_selectedStartDate ?? DateTime.now()) : 
                              (_selectedEndDate ?? _selectedStartDate ?? DateTime.now().add(const Duration(hours: 2))),
      firstDate: isStartDate ? DateTime.now() : (_selectedStartDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Seleccionar hora
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: isStartDate ? (_startTime ?? TimeOfDay.now()) :
                                (_endTime ?? _startTime ?? TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                dayPeriodBorderSide: const BorderSide(color: Colors.grey),
                dayPeriodColor: MaterialStateColor.resolveWith((states) => 
                  states.contains(MaterialState.selected) 
                    ? Theme.of(context).primaryColor
                    : Colors.transparent
                ),
                dayPeriodTextColor: MaterialStateColor.resolveWith((states) => 
                  states.contains(MaterialState.selected) 
                    ? Colors.white
                    : Theme.of(context).primaryColor
                ),
                hourMinuteColor: MaterialStateColor.resolveWith((states) => 
                  states.contains(MaterialState.selected) 
                    ? Theme.of(context).primaryColor.withOpacity(0.12)
                    : Colors.grey.shade200
                ),
                hourMinuteTextColor: MaterialStateColor.resolveWith((states) => 
                  states.contains(MaterialState.selected) 
                    ? Theme.of(context).primaryColor
                    : Colors.black87
                ),
                dialHandColor: Theme.of(context).primaryColor,
                dialBackgroundColor: Colors.grey.shade100,
                hourMinuteTextStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                helpTextStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        final DateTime fullDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          if (isStartDate) {
            _selectedStartDate = fullDateTime;
            _startTime = selectedTime;
            
            // Si la fecha de fin es anterior a la nueva fecha de inicio, actualizar la fecha de fin
            if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
              _selectedEndDate = _selectedStartDate!.add(const Duration(hours: 2));
              _endTime = TimeOfDay(
                hour: (_startTime!.hour + 2) % 24,
                minute: _startTime!.minute,
              );
            }
          } else {
            _selectedEndDate = fullDateTime;
            _endTime = selectedTime;
          }
        });
        
        // Validar que la fecha y hora de fin sea posterior a la de inicio
        if (!isStartDate && _selectedStartDate != null && _selectedEndDate != null) {
          if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La fecha y hora de fin debe ser posterior a la de inicio'),
                backgroundColor: Colors.red,
              ),
            );
            
            setState(() {
              _selectedEndDate = _selectedStartDate!.add(const Duration(hours: 2));
              _endTime = TimeOfDay(
                hour: (_startTime!.hour + 2) % 24,
                minute: _startTime!.minute,
              );
            });
          }
        }
      }
    }
  }

  void _showSelectWorkersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seleccionar Trabajadores',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_isLoadingMinistryMembers)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Cargando miembros...',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_ministryMembersData.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay miembros en este ministerio',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Intentar cargar los miembros nuevamente
                                  _loadMinistryMembers();
                                  
                                  // Mostrar mensaje informativo
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Intentando cargar miembros nuevamente...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Intentar nuevamente'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            // Barra de búsqueda
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar miembros...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  fillColor: Colors.grey.shade100,
                                  filled: true,
                                ),
                                onChanged: (value) {
                                  // Aquí se implementaría la lógica de filtrado
                                  // pero por simplicidad no la incluimos
                                },
                              ),
                            ),
                            // Selector para todos/ninguno
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        // Seleccionar todos los miembros
                                        _selectedWorkers = _ministryMembersData
                                            .map((member) => member['id'] as String)
                                            .toList();
                                        
                                        // Actualizar el state principal
                                        this.setState(() {
                                          _workersData = List.from(_ministryMembersData);
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.select_all, size: 18),
                                    label: const Text('Seleccionar todos'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        // Deseleccionar todos
                                        _selectedWorkers = [];
                                        
                                        // Actualizar el state principal
                                        this.setState(() {
                                          _workersData = [];
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.deselect, size: 18),
                                    label: const Text('Deseleccionar todos'),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Lista de miembros
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: _ministryMembersData.length,
                                itemBuilder: (context, index) {
                                  final member = _ministryMembersData[index];
                                  final isSelected = _selectedWorkers.contains(member['id']);
                                  
                                  return CheckboxListTile(
                                    title: Text(
                                      member['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(member['email'] ?? ''),
                                    secondary: CircleAvatar(
                                      backgroundImage: member['photoUrl'].isNotEmpty 
                                          ? NetworkImage(member['photoUrl']) 
                                          : null,
                                      child: member['photoUrl'].isEmpty 
                                          ? Text(member['name'].substring(0, 1).toUpperCase())
                                          : null,
                                    ),
                                    value: isSelected,
                                    onChanged: (selected) {
                                      setState(() {
                                        if (selected == true) {
                                          if (!_selectedWorkers.contains(member['id'])) {
                                            _selectedWorkers.add(member['id']);
                                            
                                            // Actualizar también _workersData en el state principal
                                            this.setState(() {
                                              _workersData.add(member);
                                            });
                                          }
                                        } else {
                                          _selectedWorkers.remove(member['id']);
                                          
                                          // Actualizar también _workersData en el state principal
                                          this.setState(() {
                                            _workersData.removeWhere((worker) => worker['id'] == member['id']);
                                          });
                                        }
                                      });
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedWorkers.length} seleccionados',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _createSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona fecha y hora de inicio y fin')),
      );
      return;
    }

    if (_selectedWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona al menos un trabajador')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convertir IDs de usuarios a referencias
      final List<DocumentReference> workerRefs = _selectedWorkers
          .map((workerId) => FirebaseFirestore.instance.collection('users').doc(workerId))
          .toList();

      // Crear el mapa de workersStatus con referencias
      final Map<DocumentReference, String> initialWorkersStatus = {
        for (var ref in workerRefs) ref: 'pending'
      };

      final TimeSlot timeSlot = TimeSlot(
        startTime: _selectedStartDate!,
        endTime: _selectedEndDate!,
      );
      
      final schedule = WorkSchedule(
        jobName: _jobNameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        requiredWorkers: _requiredWorkers,
        date: _selectedStartDate!,
        timeSlot: timeSlot,
        invitedWorkers: workerRefs,
        status: 'pending',
        ministryId: widget.ministryId,
        createdAt: DateTime.now(),
        workersStatus: initialWorkersStatus,
      );

      await FirebaseFirestore.instance
          .collection('work_schedules')
          .add(schedule.toMap());

      if (mounted) {
        Navigator.pop(context, true); // Retornamos true para indicar que se creó correctamente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horario de trabajo creado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear horario: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Horario de Trabajo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Sección de Información Básica
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.work, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Información del Trabajo',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _jobNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre del Trabajo',
                                      hintText: 'Ej. Asistente de Evento',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.work),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa un nombre para el trabajo';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Descripción (opcional)',
                                      hintText: 'Detalles sobre el trabajo',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.description),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Text('Trabajadores requeridos:'),
                                      const SizedBox(width: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: _requiredWorkers > 1 
                                                  ? () {
                                                      setState(() {
                                                        _requiredWorkers--;
                                                      });
                                                    }
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                '$_requiredWorkers',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: _requiredWorkers < 50
                                                  ? () {
                                                      setState(() {
                                                        _requiredWorkers++;
                                                      });
                                                    } 
                                                  : null,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Sección de Fecha y Hora
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fecha y Hora',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Fecha y hora de inicio
                                  InkWell(
                                    onTap: () => _showDateTimePicker(true),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.event),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedStartDate == null
                                                ? 'Seleccionar fecha y hora de inicio'
                                                : '${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} ${DateFormat('HH:mm').format(_selectedStartDate!)}',
                                            style: TextStyle(
                                              color: _selectedStartDate == null ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Fecha y hora de fin
                                  InkWell(
                                    onTap: () => _showDateTimePicker(false),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.event),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedEndDate == null
                                                ? 'Seleccionar fecha y hora de fin'
                                                : '${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)} ${DateFormat('HH:mm').format(_selectedEndDate!)}',
                                            style: TextStyle(
                                              color: _selectedEndDate == null ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Sección de Trabajadores Seleccionados
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.people, color: Theme.of(context).primaryColor),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Trabajadores',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _showSelectWorkersModal,
                                        icon: const Icon(Icons.person_add, size: 16),
                                        label: const Text('Seleccionar'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_selectedWorkers.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No hay trabajadores seleccionados',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        // Etiqueta con el número de trabajadores
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${_selectedWorkers.length} trabajadores seleccionados',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Mostrar los datos de los trabajadores
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _workersData.length,
                                          itemBuilder: (context, index) {
                                            final worker = _workersData[index];
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundImage: worker['photoUrl'].isNotEmpty
                                                      ? NetworkImage(worker['photoUrl'])
                                                      : null,
                                                  child: worker['photoUrl'].isEmpty
                                                      ? Text(worker['name'].substring(0, 1).toUpperCase())
                                                      : null,
                                                ),
                                                title: Text(worker['name']),
                                                subtitle: Text(worker['email'] ?? ''),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedWorkers.remove(worker['id']);
                                                      _workersData.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Botón grande de guardar en la parte inferior
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createSchedule,
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
                            : const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _jobNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 