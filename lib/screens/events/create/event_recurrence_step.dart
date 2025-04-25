import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

enum RecurrenceType {
  single,
  recurring,
}

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

enum RecurrenceEndType {
  never,
  afterOccurrences,
  onDate,
}

class EventRecurrenceStep extends StatefulWidget {
  final Function(Map<String, dynamic> recurrenceData) onCreate;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const EventRecurrenceStep({
    super.key,
    required this.onCreate,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<EventRecurrenceStep> createState() => _EventRecurrenceStepState();
}

class _EventRecurrenceStepState extends State<EventRecurrenceStep> {
  RecurrenceType _type = RecurrenceType.single;
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  int _interval = 1;
  RecurrenceEndType _endType = RecurrenceEndType.never;
  int _occurrences = 1;
  DateTime? _endDate;

  void _showRecurrenceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y descripción
              Text(
                'Configurações de Recorrência',
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Defina a frequência do seu evento recorrente',
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Sección de frecuencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.repeat,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Frequência',
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Intervalo y tipo de frecuencia
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            initialValue: _interval.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                _interval = int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<RecurrenceFrequency>(
                            value: _frequency,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: RecurrenceFrequency.daily,
                                child: Text('Diariamente'),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.weekly,
                                child: Text('Semanalmente'),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.monthly,
                                child: Text('Mensalmente'),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.yearly,
                                child: Text('Anualmente'),
                              ),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                _frequency = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección de fin de recurrencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event_busy,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Termina',
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Opciones de fin de recurrencia
                    Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: Colors.grey[400],
                      ),
                      child: Column(
                        children: [
                          // Nunca termina
                          Container(
                            decoration: BoxDecoration(
                              color: _endType == RecurrenceEndType.never
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: _endType == RecurrenceEndType.never
                                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                  : null,
                            ),
                            child: RadioListTile<RecurrenceEndType>(
                              title: Text(
                                'Nunca',
                                style: TextStyle(
                                  fontWeight: _endType == RecurrenceEndType.never
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              value: RecurrenceEndType.never,
                              groupValue: _endType,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setModalState(() {
                                  _endType = value!;
                                });
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Después de X ocurrencias
                          Container(
                            decoration: BoxDecoration(
                              color: _endType == RecurrenceEndType.afterOccurrences
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: _endType == RecurrenceEndType.afterOccurrences
                                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                  : null,
                            ),
                            child: RadioListTile<RecurrenceEndType>(
                              title: Row(
                                children: [
                                  const Text('Após'),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      enabled: _endType == RecurrenceEndType.afterOccurrences,
                                      initialValue: _occurrences.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        setModalState(() {
                                          _occurrences = int.tryParse(value) ?? 1;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('ocorrências'),
                                ],
                              ),
                              value: RecurrenceEndType.afterOccurrences,
                              groupValue: _endType,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setModalState(() {
                                  _endType = value!;
                                });
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // En una fecha específica
                          Container(
                            decoration: BoxDecoration(
                              color: _endType == RecurrenceEndType.onDate
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: _endType == RecurrenceEndType.onDate
                                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                  : null,
                            ),
                            child: RadioListTile<RecurrenceEndType>(
                              title: Row(
                                children: [
                                  const Text('Em data'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _endType == RecurrenceEndType.onDate
                                          ? () async {
                                              final picked = await showDatePicker(
                                                context: context,
                                                initialDate: _endDate ?? DateTime.now(),
                                                firstDate: DateTime.now(),
                                                lastDate: DateTime.now().add(
                                                  const Duration(days: 365 * 5),
                                                ),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context).copyWith(
                                                      colorScheme: ColorScheme.light(
                                                        primary: AppColors.primary,
                                                        onPrimary: Colors.white,
                                                        surface: Colors.white,
                                                      ),
                                                      textButtonTheme: TextButtonThemeData(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (picked != null) {
                                                setModalState(() {
                                                  _endDate = picked;
                                                });
                                              }
                                            }
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _endType == RecurrenceEndType.onDate
                                                ? AppColors.primary
                                                : Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _endDate != null
                                                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                                  : ' Data',
                                              style: TextStyle(
                                                color: _endType == RecurrenceEndType.onDate
                                                    ? AppColors.primary
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: _endType == RecurrenceEndType.onDate
                                                  ? AppColors.primary
                                                  : Colors.grey[400],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              value: RecurrenceEndType.onDate,
                              groupValue: _endType,
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                setModalState(() {
                                  _endType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _type = RecurrenceType.recurring;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Concluído'),
                  ),
                ],
              ),
              // Espacio adicional para alejar los botones del borde inferior
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreate() {
    final recurrenceData = {
      'type': _type,
      'isRecurrent': _type == RecurrenceType.recurring,
      if (_type == RecurrenceType.recurring) ...{
        'frequency': _frequency.toString().split('.').last,
        'interval': _interval,
        'endType': _endType.toString().split('.').last,
        if (_endType == RecurrenceEndType.afterOccurrences)
          'occurrences': _occurrences,
        if (_endType == RecurrenceEndType.onDate) 
          'endDate': _endDate,
      },
    };
    widget.onCreate(recurrenceData);
  }

  String _getRecurrenceDescription() {
    if (_type == RecurrenceType.single) {
      return 'Evento único (não recorrente)';
    }
    
    String result = 'Repete ';
    
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        result += _interval > 1 ? 'a cada $_interval dias' : 'diariamente';
        break;
      case RecurrenceFrequency.weekly:
        result += _interval > 1 ? 'a cada $_interval semanas' : 'semanalmente';
        break;
      case RecurrenceFrequency.monthly:
        result += _interval > 1 ? 'a cada $_interval meses' : 'mensalmente';
        break;
      case RecurrenceFrequency.yearly:
        result += _interval > 1 ? 'a cada $_interval anos' : 'anualmente';
        break;
    }
    
    switch (_endType) {
      case RecurrenceEndType.never:
        result += ', sem fim definido';
        break;
      case RecurrenceEndType.afterOccurrences:
        result += ', até $_occurrences ocorrências';
        break;
      case RecurrenceEndType.onDate:
        result += _endDate != null 
            ? ', até ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
            : ', até data específica';
        break;
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recorrência do Evento',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Defina se seu evento acontecerá uma única vez ou será recorrente',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event_repeat,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tipo de Evento',
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<RecurrenceType>(
                    segments: const [
                      ButtonSegment(
                        value: RecurrenceType.single,
                        label: Text('Único'),
                        icon: Icon(Icons.event),
                      ),
                      ButtonSegment(
                        value: RecurrenceType.recurring,
                        label: Text('Recorrente'),
                        icon: Icon(Icons.repeat),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (Set<RecurrenceType> newSelection) {
                      setState(() {
                        _type = newSelection.first;
                      });
                      if (_type == RecurrenceType.recurring) {
                        _showRecurrenceModal();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_type == RecurrenceType.recurring) 
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getRecurrenceDescription(),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: _showRecurrenceModal,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Voltar'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Criar'),
                ),
              ],
            ),
            // Espacio adicional para alejar los botones del borde inferior
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 