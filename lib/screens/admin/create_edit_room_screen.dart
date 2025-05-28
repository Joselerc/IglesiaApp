import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear hora
import '../../models/scheduled_room_model.dart';
import '../../models/kid_room_model.dart'; // Necesario si creamos KidRoom aquí
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CreateEditRoomScreen extends StatefulWidget {
  final String? meetingId;  // ID de la programación/reunión para edición

  const CreateEditRoomScreen({
    super.key, 
    this.meetingId, 
  });

  @override
  State<CreateEditRoomScreen> createState() => _CreateEditRoomScreenState();
}

class _CreateEditRoomScreenState extends State<CreateEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isLoadingData = false;

  // Controladores y estado
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _ageRange;
  final _maxChildrenController = TextEditingController(text: '0');
  bool _includeOpen = false;
  bool _repeatWeekly = false;
  String _internalRoomName = ''; // Para el nombre de la sala física si se crea aquí

  final List<String> _ageRangeOptions = [
    'Berçário',
    'Sala 2 a 3 anos',
    'Sala 4 a 5 anos',
    'Sala 6 a 7 anos',
    'Sala 8 anos', // Asumiendo que "8" en la imagen significa "Sala 8 anos"
    'Sala 9 a 10 anos',
    // Añadir más si es necesario
  ];

  bool get _isEditMode => widget.meetingId != null;
  bool get _isCreatingScheduleForExistingRoom => widget.meetingId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadScheduledRoomData();
    }
  }

  Future<void> _loadScheduledRoomData() async {
    if (widget.meetingId == null) return;
    setState(() => _isLoadingData = true);
    try {
      DocumentSnapshot scheduleDoc = await FirebaseFirestore.instance.collection('scheduledRooms').doc(widget.meetingId!).get();
      if (scheduleDoc.exists) {
        final schedule = ScheduledRoomModel.fromFirestore(scheduleDoc);
        _descriptionController.text = schedule.description;
        _selectedDate = schedule.date.toDate();
        _startTime = TimeOfDay.fromDateTime(schedule.startTime.toDate());
        _endTime = TimeOfDay.fromDateTime(schedule.endTime.toDate());
        _ageRange = schedule.ageRange;
        _maxChildrenController.text = schedule.maxChildren?.toString() ?? '0';
        _includeOpen = schedule.isOpen;
        _repeatWeekly = schedule.repeatWeekly;
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reunião não encontrada.'),backgroundColor: Colors.red));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Erro ao carregar dados da reunião: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e'),backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _maxChildrenController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Ejemplo: desde hace un mes
      lastDate: DateTime.now().add(const Duration(days: 365)),   // Ejemplo: hasta un año en el futuro
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveRoomAndSchedule() async {
    print('[SAVE_SCHEDULE_DEBUG] Iniciando _saveRoomAndSchedule...');
    if (!_formKey.currentState!.validate()) {
      print('[SAVE_SCHEDULE_DEBUG] Formulario inválido.');
      return;
    }
    if (_selectedDate == null || _startTime == null || _endTime == null || _ageRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios (*).'), backgroundColor: Colors.red));
        print('[SAVE_SCHEDULE_DEBUG] Campos de data/hora/faixa etária incompletos.');
        return;
    }
    if (_isSaving) {
      print('[SAVE_SCHEDULE_DEBUG] Já está salvando, retornando...');
      return;
    }

    // Imprimir estado ANTES de la condición del diálogo
    print('[SAVE_SCHEDULE_DEBUG] ANTES DEL DIÁLOGO - _repeatWeekly: $_repeatWeekly');
    print('[SAVE_SCHEDULE_DEBUG] ANTES DEL DIÁLOGO - _isEditMode (widget.meetingId != null): ${_isEditMode}');
    print('[SAVE_SCHEDULE_DEBUG] ANTES DEL DIÁLOGO - widget.meetingId: ${widget.meetingId}');

    bool generateRepetitions = _repeatWeekly && !_isEditMode;
    print('[SAVE_SCHEDULE_DEBUG] Condición generateRepetitions: $generateRepetitions');

    if (generateRepetitions) {
      print('[SAVE_SCHEDULE_DEBUG] MOSTRANDO DIÁLOGO de confirmación para repeticiones...');
      final bool? confirmRepeat = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Repetir Semanalmente'),
            content: const SingleChildScrollView( 
              child: Text('Esta programação será configurada para se repetir semanalmente durante o próximo ano. Perto do final deste período, você poderá extendê-la. Deseja continuar?'),
            ),
            actions: <Widget>[
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop(false)),
              TextButton(child: Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), onPressed: () => Navigator.of(dialogContext).pop(true)),
            ],
          );
        },
      );
      print('[SAVE_SCHEDULE_DEBUG] Resultado del diálogo de confirmación: $confirmRepeat');
      if (confirmRepeat != true) {
        print('[SAVE_SCHEDULE_DEBUG] Usuario canceló la repetición. Retornando de _saveRoomAndSchedule.');
        return; 
      }
      print('[SAVE_SCHEDULE_DEBUG] Usuario CONFIRMÓ la repetición.');
    } else {
      print('[SAVE_SCHEDULE_DEBUG] NO se generarán repeticiones porque generateRepetitions es false.');
    }

    setState(() => _isSaving = true);
    print('[SAVE_SCHEDULE_DEBUG] _isSaving = true. Iniciando try-catch para guardar.');

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      String baseScheduleId = _isEditMode ? widget.meetingId! : FirebaseFirestore.instance.collection('scheduledRooms').doc().id;
      print('[SAVE_SCHEDULE_DEBUG] baseScheduleId: $baseScheduleId');
      Timestamp firstInstanceCreatedAt = Timestamp.now();
      Timestamp? lastInstanceDateForRepetition;

      final startDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _startTime!.hour, _startTime!.minute);
      final endDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _endTime!.hour, _endTime!.minute);

      final ScheduledRoomModel firstOrEditedSchedule = ScheduledRoomModel(
        id: baseScheduleId,
        description: _descriptionController.text.trim(),
        date: Timestamp.fromDate(_selectedDate!),
        startTime: Timestamp.fromDate(startDateTime),
        endTime: Timestamp.fromDate(endDateTime),
        ageRange: _ageRange,
        maxChildren: int.tryParse(_maxChildrenController.text.trim()),
        isOpen: _includeOpen,
        repeatWeekly: _repeatWeekly,
        originalScheduleId: _isEditMode ? ((await FirebaseFirestore.instance.collection('scheduledRooms').doc(baseScheduleId).get()).data()?['originalScheduleId'] as String?) : baseScheduleId,
        repetitionEndDate: null,
        checkedInChildIds: _isEditMode 
            ? List<String>.from((await FirebaseFirestore.instance.collection('scheduledRooms').doc(baseScheduleId).get()).data()?['checkedInChildIds'] ?? [])
            : [],
        createdAt: _isEditMode 
            ? ((await FirebaseFirestore.instance.collection('scheduledRooms').doc(baseScheduleId).get()).data()?['createdAt'] as Timestamp? ?? firstInstanceCreatedAt)
            : firstInstanceCreatedAt,
        updatedAt: _isEditMode ? Timestamp.now() : null,
      );
      
      DocumentReference firstOrEditedDocRef = FirebaseFirestore.instance.collection('scheduledRooms').doc(baseScheduleId);
      batch.set(firstOrEditedDocRef, firstOrEditedSchedule.toMap(), SetOptions(merge: _isEditMode));
      print('[SAVE_SCHEDULE_DEBUG] Primera instancia/plantilla añadida al batch.');

      if (generateRepetitions) {
        print('[SAVE_SCHEDULE_DEBUG] Iniciando bucle para 51 repeticiones...');
        DateTime nextDate = _selectedDate!;
        for (int i = 0; i < 51; i++) { 
          nextDate = nextDate.add(const Duration(days: 7));
          final nextStartDateTime = DateTime(nextDate.year, nextDate.month, nextDate.day, _startTime!.hour, _startTime!.minute);
          final nextEndDateTime = DateTime(nextDate.year, nextDate.month, nextDate.day, _endTime!.hour, _endTime!.minute);
          final repeatedScheduleId = FirebaseFirestore.instance.collection('scheduledRooms').doc().id;
          print('[SAVE_SCHEDULE_DEBUG] Generando repetición ${i+1} con ID: $repeatedScheduleId para fecha: $nextDate');

          final repeatedSchedule = ScheduledRoomModel(
            id: repeatedScheduleId,
            description: firstOrEditedSchedule.description,
            date: Timestamp.fromDate(nextDate),
            startTime: Timestamp.fromDate(nextStartDateTime),
            endTime: Timestamp.fromDate(nextEndDateTime),
            ageRange: firstOrEditedSchedule.ageRange,
            maxChildren: firstOrEditedSchedule.maxChildren,
            isOpen: firstOrEditedSchedule.isOpen,
            repeatWeekly: false, // Las instancias individuales no se marcan como repetitivas
            originalScheduleId: baseScheduleId,
            repetitionEndDate: null,
            checkedInChildIds: [],
            createdAt: firstInstanceCreatedAt,
            updatedAt: null,
          );
          DocumentReference repeatedDocRef = FirebaseFirestore.instance.collection('scheduledRooms').doc(repeatedScheduleId);
          batch.set(repeatedDocRef, repeatedSchedule.toMap());
          if (i == 50) {
            lastInstanceDateForRepetition = Timestamp.fromDate(nextDate);
          }
        }
        if (lastInstanceDateForRepetition != null) {
          print('[SAVE_SCHEDULE_DEBUG] Añadiendo actualización de repetitionEndDate al batch: $lastInstanceDateForRepetition');
          batch.update(firstOrEditedDocRef, {'repetitionEndDate': lastInstanceDateForRepetition});
        }
        print('[SAVE_SCHEDULE_DEBUG] Fin del bucle de repeticiones.');
      }
      
      print('[SAVE_SCHEDULE_DEBUG] Ejecutando batch.commit()...');
      await batch.commit();
      print('[SAVE_SCHEDULE_DEBUG] Batch commit completado.');
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }

      if (mounted) {
        final String successMessage = 'Programação ${_isEditMode ? "atualizada" : "criada"} com sucesso!${(generateRepetitions) ? " Repetições semanais geradas para 1 ano." : ""}';
        final snackBar = SnackBar(content: Text(successMessage), backgroundColor: Colors.green, duration: Duration(seconds: generateRepetitions ? 4 : 2));
        
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        
        await Future.delayed(Duration(milliseconds: generateRepetitions ? 2000 : 1000));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e, s) {
      print("Erro ao salvar programação: $e\nStackTrace: $s");
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar programação: Verifique os logs.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
      print('[SAVE_SCHEDULE_DEBUG] _isSaving = false (en finally).');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Programação' : 'Nova/Editar Programação'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isLoadingData && _isEditMode)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição *'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Descrição é obrigatória' : null,
                    ),
                    const SizedBox(height: 20),
                    // Fecha
                    _buildDateTimePickerField(
                      label: 'Data *',
                      value: _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Selecionar data',
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 20),
                    // Hora Inicio y Fin
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimePickerField(
                            label: 'Início *',
                            value: _startTime != null ? _startTime!.format(context) : 'Selecionar hora',
                            icon: Icons.access_time_outlined,
                            onTap: () => _selectTime(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateTimePickerField(
                            label: 'Finalização *',
                            value: _endTime != null ? _endTime!.format(context) : 'Selecionar hora',
                            icon: Icons.access_time_outlined,
                            onTap: () => _selectTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Rango Etario
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Faixa etária *', border: OutlineInputBorder()),
                      value: _ageRange,
                      items: _ageRangeOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _ageRange = newValue);
                      },
                      validator: (v) => v == null ? 'Selecione uma faixa etária' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _maxChildrenController,
                      decoration: const InputDecoration(labelText: 'Número máximo de crianças/as', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Incluir como aberta'),
                      subtitle: _repeatWeekly 
                        ? const Text('Não disponível para programações repetitivas', 
                            style: TextStyle(color: Colors.orange, fontSize: 12))
                        : null,
                      value: _includeOpen,
                      onChanged: _repeatWeekly ? null : (bool value) => setState(() => _includeOpen = value),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Repetir semanalmente'),
                      value: _repeatWeekly,
                      onChanged: (bool value) => setState(() {
                        _repeatWeekly = value;
                        // Si se activa repetir semanalmente, desactivar "incluir como aberta"
                        if (value) {
                          _includeOpen = false;
                        }
                      }),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          if (_isSaving) Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: Colors.white)))),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _isSaving ? Colors.grey.shade400 : AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _isSaving ? null : _saveRoomAndSchedule,
          child: Text(_isEditMode ? 'SALVAR ALTERAÇÕES' : 'CRIAR', style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDateTimePickerField({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(icon),
        ),
        child: Text(value, style: AppTextStyles.bodyText1.copyWith(color: value.startsWith('Selecionar') ? Colors.grey.shade600 : null)),
      ),
    );
  }
} 