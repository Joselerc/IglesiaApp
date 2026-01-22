import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class EventDateTimeStep extends StatefulWidget {
  final Function(Map<String, dynamic> dateTimeData) onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final DateTime? initialStartDate;
  final TimeOfDay? initialStartTime;
  final DateTime? initialEndDate;
  final TimeOfDay? initialEndTime;

  const EventDateTimeStep({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
    this.initialStartDate,
    this.initialStartTime,
    this.initialEndDate,
    this.initialEndTime,
  });

  @override
  State<EventDateTimeStep> createState() => _EventDateTimeStepState();
}

class _EventDateTimeStepState extends State<EventDateTimeStep> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _startTime = widget.initialStartTime;
    _endDate = widget.initialEndDate;
    _endTime = widget.initialEndTime;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      setState(() {
        _startDate = picked;
        if (_endDate == null || _endDate!.isBefore(_startDate!)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
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
      setState(() {
        _startTime = picked;
        if (_endTime == null) {
          // Establecer un tiempo de finalización por defecto (1 hora después)
          _endTime = TimeOfDay(
            hour: (_startTime!.hour + 1) % 24, 
            minute: _startTime!.minute
          );
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
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
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _handleNext() {
    setState(() {
      _showErrors = true;
    });

    if (_startDate != null && 
        _startTime != null && 
        _endDate != null && 
        _endTime != null) {
      final dateTimeData = {
        'startDate': _startDate,
        'startTime': _startTime,
        'endDate': _endDate,
        'endTime': _endTime,
      };
      widget.onNext(dateTimeData);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.selectDate;
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return AppLocalizations.of(context)!.selectTime;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.eventDateAndTime,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.defineWhenEventStartsAndEnds,
                style: AppTextStyles.bodyText2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Sección de inicio
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
                            Icons.play_circle_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.start,
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _startDate != null 
                                    ? AppColors.primary.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: _showErrors && _startDate == null
                                    ? Border.all(color: Colors.red)
                                    : Border.all(
                                        color: _startDate != null 
                                            ? AppColors.primary.withOpacity(0.3) 
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(_startDate),
                                      style: TextStyle(
                                        color: _startDate == null ? Colors.grey[600] : AppColors.textPrimary,
                                        fontWeight: _startDate != null ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.calendar_today, 
                                    size: 20, 
                                    color: _startDate != null ? AppColors.primary : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _startTime != null 
                                    ? AppColors.primary.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: _showErrors && _startTime == null
                                    ? Border.all(color: Colors.red)
                                    : Border.all(
                                        color: _startTime != null 
                                            ? AppColors.primary.withOpacity(0.3) 
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatTime(_startTime),
                                      style: TextStyle(
                                        color: _startTime == null ? Colors.grey[600] : AppColors.textPrimary,
                                        fontWeight: _startTime != null ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time, 
                                    size: 20, 
                                    color: _startTime != null ? AppColors.primary : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección de fin
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
                            Icons.stop_circle_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.end,
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _endDate != null 
                                    ? AppColors.primary.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: _showErrors && _endDate == null
                                    ? Border.all(color: Colors.red)
                                    : Border.all(
                                        color: _endDate != null 
                                            ? AppColors.primary.withOpacity(0.3) 
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(_endDate),
                                      style: TextStyle(
                                        color: _endDate == null ? Colors.grey[600] : AppColors.textPrimary,
                                        fontWeight: _endDate != null ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.calendar_today, 
                                    size: 20, 
                                    color: _endDate != null ? AppColors.primary : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _endTime != null 
                                    ? AppColors.primary.withOpacity(0.05)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: _showErrors && _endTime == null
                                    ? Border.all(color: Colors.red)
                                    : Border.all(
                                        color: _endTime != null 
                                            ? AppColors.primary.withOpacity(0.3) 
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatTime(_endTime),
                                      style: TextStyle(
                                        color: _endTime == null ? Colors.grey[600] : AppColors.textPrimary,
                                        fontWeight: _endTime != null ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time, 
                                    size: 20, 
                                    color: _endTime != null ? AppColors.primary : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              // Botones de navegación
              Row(
                children: [
                  Expanded(
                    child: _buildBottomButton(
                      label: AppLocalizations.of(context)!.back,
                      onPressed: widget.onBack,
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBottomButton(
                      label: AppLocalizations.of(context)!.cancel,
                      onPressed: widget.onCancel,
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBottomButton(
                      label: AppLocalizations.of(context)!.next,
                      onPressed: _handleNext,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
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

  Widget _buildBottomButton({
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
