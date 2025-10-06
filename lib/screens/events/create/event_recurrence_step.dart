import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

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
  RecurrenceEndType _endType = RecurrenceEndType.afterOccurrences; // Cambiado de never a afterOccurrences
  int _occurrences = 5; // Valor por defecto más razonable
  DateTime? _endDate;

  void _showRecurrenceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
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
                AppLocalizations.of(context)!.recurrenceSettings,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.defineRecurringEventFrequency,
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
                          AppLocalizations.of(context)!.frequency,
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Texto explicativo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.intervalExplanation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Label más claro
                    Text(
                      AppLocalizations.of(context)!.repeatEvery,
                      style: AppTextStyles.bodyText2.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Intervalo y tipo de frecuencia
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                if (_interval < 1) _interval = 1;
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
                                child: Text(_interval > 1 ? AppLocalizations.of(context)!.days : AppLocalizations.of(context)!.day),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.weekly,
                                child: Text(_interval > 1 ? AppLocalizations.of(context)!.weeks : AppLocalizations.of(context)!.week),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.monthly,
                                child: Text(_interval > 1 ? AppLocalizations.of(context)!.months : AppLocalizations.of(context)!.month),
                              ),
                              DropdownMenuItem(
                                value: RecurrenceFrequency.yearly,
                                child: Text(_interval > 1 ? AppLocalizations.of(context)!.years : AppLocalizations.of(context)!.year),
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
                    
                    // Mostrar resumen de la configuración
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        _getIntervalDescription(),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                          AppLocalizations.of(context)!.ends,
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
                          // Nunca termina - OCULTADO TEMPORALMENTE
                          /*
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
                                AppLocalizations.of(context)!.never,
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
                          */
                          
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
                                  Text(AppLocalizations.of(context)!.after),
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
                                  Text(AppLocalizations.of(context)!.occurrences),
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
      return AppLocalizations.of(context)!.singleEventNotRecurring;
    }
    
    String result = AppLocalizations.of(context)!.repeats + ' ';
    
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXDays(_interval) : AppLocalizations.of(context)!.daily;
        break;
      case RecurrenceFrequency.weekly:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXWeeks(_interval) : AppLocalizations.of(context)!.weekly;
        break;
      case RecurrenceFrequency.monthly:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXMonths(_interval) : AppLocalizations.of(context)!.monthly;
        break;
      case RecurrenceFrequency.yearly:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXYears(_interval) : AppLocalizations.of(context)!.yearly;
        break;
    }
    
    switch (_endType) {
      case RecurrenceEndType.never:
        result += ', ${AppLocalizations.of(context)!.noEndDefined}';
        break;
      case RecurrenceEndType.afterOccurrences:
        result += ', ${AppLocalizations.of(context)!.untilXOccurrences(_occurrences)}';
        break;
      case RecurrenceEndType.onDate:
        result += _endDate != null 
            ? ', ${AppLocalizations.of(context)!.until} ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
            : ', ${AppLocalizations.of(context)!.untilSpecificDate}';
        break;
    }
    
    return result;
  }

  String _getIntervalDescription() {
    String result = AppLocalizations.of(context)!.repeats + ' ';
    
    switch (_frequency) {
      case RecurrenceFrequency.daily:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXDays(_interval) : AppLocalizations.of(context)!.daily;
        break;
      case RecurrenceFrequency.weekly:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXWeeks(_interval) : AppLocalizations.of(context)!.weekly;
        break;
      case RecurrenceFrequency.monthly:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXMonths(_interval) : AppLocalizations.of(context)!.monthly;
        break;
      case RecurrenceFrequency.yearly:
        result += _interval > 1 ? AppLocalizations.of(context)!.everyXYears(_interval) : AppLocalizations.of(context)!.yearly;
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
              AppLocalizations.of(context)!.eventRecurrence,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.defineEventOccurrenceType,
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
                        AppLocalizations.of(context)!.eventType,
                        style: AppTextStyles.subtitle2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<RecurrenceType>(
                    segments: [
                      ButtonSegment(
                        value: RecurrenceType.single,
                        label: Text(AppLocalizations.of(context)!.single),
                        icon: const Icon(Icons.event),
                      ),
                      ButtonSegment(
                        value: RecurrenceType.recurring,
                        label: Text(AppLocalizations.of(context)!.recurring),
                        icon: const Icon(Icons.repeat),
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
                      child: Text(AppLocalizations.of(context)!.back),
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
                      child: Text(AppLocalizations.of(context)!.cancel),
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
                  child: Text(AppLocalizations.of(context)!.create),
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