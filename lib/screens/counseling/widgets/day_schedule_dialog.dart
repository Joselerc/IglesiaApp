import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/pastor_availability.dart' as model;
import '../../../l10n/app_localizations.dart';

// Clase auxiliar para la UI
class UITimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isOnline;
  final bool isInPerson;

  UITimeSlot({
    required this.start,
    required this.end,
    this.isOnline = true,
    this.isInPerson = false,
  });
  
  // Convertir a modelo
  model.TimeSlot toModelTimeSlot() {
    return model.TimeSlot(
      start: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
      end: '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
      isOnline: isOnline,
      isInPerson: isInPerson,
    );
  }
  
  // Crear desde modelo
  static UITimeSlot fromModelTimeSlot(model.TimeSlot slot) {
    final startParts = slot.start.split(':');
    final endParts = slot.end.split(':');
    
    return UITimeSlot(
      start: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      end: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      isOnline: slot.isOnline,
      isInPerson: slot.isInPerson,
    );
  }
}

class DayScheduleDialog extends StatefulWidget {
  final DateTime date;
  final model.DaySchedule schedule;
  final Function(model.DaySchedule) onSave;

  const DayScheduleDialog({
    Key? key,
    required this.date,
    required this.schedule,
    required this.onSave,
  }) : super(key: key);

  @override
  State<DayScheduleDialog> createState() => _DayScheduleDialogState();
}

class _DayScheduleDialogState extends State<DayScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isWorking;
  late List<UITimeSlot> _timeSlots;

  @override
  void initState() {
    super.initState();
    _isWorking = widget.schedule.isWorking;
    
    // Convertir los slots del modelo a UI slots
    if (widget.schedule.timeSlots.isNotEmpty) {
      _timeSlots = widget.schedule.timeSlots.map((slot) => UITimeSlot.fromModelTimeSlot(slot)).toList();
    } else {
      // Añadir un slot vacío si no hay slots
      _timeSlots = [
        UITimeSlot(
          start: const TimeOfDay(hour: 9, minute: 0),
          end: const TimeOfDay(hour: 17, minute: 0),
          isOnline: true,
          isInPerson: true,
        )
      ];
    }
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(UITimeSlot(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
        isOnline: true,
        isInPerson: true,
      ));
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
  }


  void _saveSchedule() {
    // Convertir los UI slots a slots del modelo
    final modelTimeSlots = _timeSlots.map((slot) => slot.toModelTimeSlot()).toList();
    
    final newSchedule = model.DaySchedule(
      isWorking: _isWorking,
      timeSlots: _isWorking ? modelTimeSlots : [],
      sessionDuration: widget.schedule.sessionDuration, // Mantener la duración existente
    );
    
    // Cerrar el diálogo primero para evitar parpadeos
    Navigator.pop(context);
    
    // Luego llamar al callback de guardado
    widget.onSave(newSchedule);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado del diálogo
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(widget.date).replaceRange(0, 1, DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(widget.date)[0].toUpperCase()),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.configureAvailabilityForThisDay,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido del diálogo
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Switch para marcar el día como disponible o no
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isWorking ? AppLocalizations.of(context)!.available : AppLocalizations.of(context)!.unavailable,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _isWorking ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isWorking 
                                    ? AppLocalizations.of(context)!.thisDayMarkedAvailable
                                    : AppLocalizations.of(context)!.thisDayMarkedUnavailable,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isWorking,
                            onChanged: (value) {
                              setState(() {
                                _isWorking = value;
                                if (!value) {
                                  _timeSlots.clear();
                                }
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_isWorking) ...[
                      // Título de franjas horarias
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.timeSlotsSingular,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_timeSlots.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_timeSlots.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.grey.shade600,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                setState(() {
                                  _timeSlots.clear();
                                });
                              },
                              tooltip: 'Excluir todas',
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_timeSlots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.access_time, size: 40, color: Colors.orange.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No hay franjas horarias configuradas',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.orange.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Adicione pelo menos uma faixa de horário para que este dia esteja disponível para consultas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      
                      // Lista de franjas horarias
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _timeSlots[index];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade100,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado de la franja
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      topRight: Radius.circular(11),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.timeSlot((index + 1).toString()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_timeSlots.length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _removeTimeSlot(index),
                                          tooltip: 'Excluir faixa',
                                        ),
                                    ],
                                  ),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Horario en una sola fila
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final time = await showTimePicker(
                                                  context: context,
                                                  initialTime: slot.start,
                                                );
                                                if (time != null) {
                                                  setState(() {
                                                    _timeSlots[index] = UITimeSlot(
                                                      start: time,
                                                      end: slot.end,
                                                      isOnline: slot.isOnline,
                                                      isInPerson: slot.isInPerson,
                                                    );
                                                  });
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      slot.start.format(context),
                                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                          ),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () async {
                                                final time = await showTimePicker(
                                                  context: context,
                                                  initialTime: slot.end,
                                                );
                                                if (time != null) {
                                                  setState(() {
                                                    _timeSlots[index] = UITimeSlot(
                                                      start: slot.start,
                                                      end: time,
                                                      isOnline: slot.isOnline,
                                                      isInPerson: slot.isInPerson,
                                                    );
                                                  });
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      slot.end.format(context),
                                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Tipo de cita con chips
                                      Text(
                                        AppLocalizations.of(context)!.consultationType,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Chip para Online
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _timeSlots[index] = UITimeSlot(
                                                  start: slot.start,
                                                  end: slot.end,
                                                  isOnline: !slot.isOnline,
                                                  isInPerson: slot.isInPerson,
                                                );
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: slot.isOnline ? Colors.blue.shade50 : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: slot.isOnline ? Colors.blue.shade300 : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.videocam_outlined,
                                                    size: 16,
                                                    color: slot.isOnline ? Colors.blue.shade700 : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    AppLocalizations.of(context)!.onlineConsultation,
                                                    style: TextStyle(
                                                      color: slot.isOnline ? Colors.blue.shade700 : Colors.grey,
                                                      fontWeight: slot.isOnline ? FontWeight.w500 : FontWeight.normal,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (slot.isOnline)
                                                    Icon(
                                                      Icons.check_circle,
                                                      size: 16,
                                                      color: Colors.blue.shade700,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // Chip para Presencial
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _timeSlots[index] = UITimeSlot(
                                                  start: slot.start,
                                                  end: slot.end,
                                                  isOnline: slot.isOnline,
                                                  isInPerson: !slot.isInPerson,
                                                );
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: slot.isInPerson ? Colors.green.shade50 : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: slot.isInPerson ? Colors.green.shade300 : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 16,
                                                    color: slot.isInPerson ? Colors.green.shade700 : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    AppLocalizations.of(context)!.inPersonConsultation,
                                                    style: TextStyle(
                                                      color: slot.isInPerson ? Colors.green.shade700 : Colors.grey,
                                                      fontWeight: slot.isInPerson ? FontWeight.w500 : FontWeight.normal,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  if (slot.isInPerson)
                                                    Icon(
                                                      Icons.check_circle,
                                                      size: 16,
                                                      color: Colors.green.shade700,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // Botón para añadir nueva franja
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: Text(AppLocalizations.of(context)!.addTimeSlot),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: _addTimeSlot,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveSchedule,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 