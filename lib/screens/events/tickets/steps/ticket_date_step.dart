import 'package:flutter/material.dart';

class TicketDateStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const TicketDateStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<TicketDateStep> createState() => _TicketDateStepState();
}

class _TicketDateStepState extends State<TicketDateStep> {
  bool _useCustomDate = false;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _handleNext() {
    if (_useCustomDate) {
      if (_startDate == null || _startTime == null || 
          _endDate == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select all dates and times')),
        );
        return;
      }
    }

    widget.onNext({
      'useCustomDate': _useCustomDate,
      if (_useCustomDate) ...{
        'startDate': DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          _startTime!.hour,
          _startTime!.minute,
        ),
        'endDate': DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        ),
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket Availability',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Opciones de fecha
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Until Event Date'),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Custom Date'),
              ),
            ],
            selected: {_useCustomDate},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _useCustomDate = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 24),

          if (_useCustomDate) ...[
            // Fecha y hora de inicio
            Text(
              'Start Date and Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startDate == null 
                      ? 'Select Date'
                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(true),
                    icon: const Icon(Icons.access_time),
                    label: Text(_startTime == null 
                      ? 'Select Time'
                      : _startTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fecha y hora de fin
            Text(
              'End Date and Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_endDate == null 
                      ? 'Select Date'
                      : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(false),
                    icon: const Icon(Icons.access_time),
                    label: Text(_endTime == null 
                      ? 'Select Time'
                      : _endTime!.format(context)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _handleNext,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 