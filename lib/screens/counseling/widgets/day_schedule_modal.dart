import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayScheduleModal extends StatefulWidget {
  final String day;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSave;

  const DayScheduleModal({
    super.key,
    required this.day,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<DayScheduleModal> createState() => _DayScheduleModalState();
}

class _DayScheduleModalState extends State<DayScheduleModal> {
  late bool _isWorking;
  late bool _hasOnline;
  late bool _hasInPerson;
  TimeOfDay? _onlineStart;
  TimeOfDay? _onlineEnd;
  TimeOfDay? _inPersonStart;
  TimeOfDay? _inPersonEnd;

  @override
  void initState() {
    super.initState();
    _isWorking = widget.initialData['isWorking'] ?? false;
    _hasOnline = widget.initialData['onlineStart']?.isNotEmpty ?? false;
    _hasInPerson = widget.initialData['inPersonStart']?.isNotEmpty ?? false;
    
    if (_hasOnline) {
      _onlineStart = _parseTimeString(widget.initialData['onlineStart']);
      _onlineEnd = _parseTimeString(widget.initialData['onlineEnd']);
    }
    
    if (_hasInPerson) {
      _inPersonStart = _parseTimeString(widget.initialData['inPersonStart']);
      _inPersonEnd = _parseTimeString(widget.initialData['inPersonEnd']);
    }
  }

  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(bool isStart, bool isOnline) async {
    final initialTime = isStart
        ? (isOnline ? _onlineStart : _inPersonStart) ?? TimeOfDay.now()
        : (isOnline ? _onlineEnd : _inPersonEnd) ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isOnline) {
          if (isStart) {
            _onlineStart = picked;
          } else {
            _onlineEnd = picked;
          }
        } else {
          if (isStart) {
            _inPersonStart = picked;
          } else {
            _inPersonEnd = picked;
          }
        }
      });
    }
  }

  void _save() {
    // Validar que end time sea después de start time
    bool isValid = true;
    String errorMessage = '';

    if (_hasOnline && _onlineStart != null && _onlineEnd != null) {
      final start = DateTime(2024, 1, 1, _onlineStart!.hour, _onlineStart!.minute);
      final end = DateTime(2024, 1, 1, _onlineEnd!.hour, _onlineEnd!.minute);
      if (end.isBefore(start)) {
        isValid = false;
        errorMessage = 'Online end time must be after start time';
      }
    }

    if (_hasInPerson && _inPersonStart != null && _inPersonEnd != null) {
      final start = DateTime(2024, 1, 1, _inPersonStart!.hour, _inPersonStart!.minute);
      final end = DateTime(2024, 1, 1, _inPersonEnd!.hour, _inPersonEnd!.minute);
      if (end.isBefore(start)) {
        isValid = false;
        errorMessage = 'In-person end time must be after start time';
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    final newData = {
      'isWorking': _isWorking,
      'onlineStart': _hasOnline ? _formatTimeOfDay(_onlineStart) : '',
      'onlineEnd': _hasOnline ? _formatTimeOfDay(_onlineEnd) : '',
      'inPersonStart': _hasInPerson ? _formatTimeOfDay(_inPersonStart) : '',
      'inPersonEnd': _hasInPerson ? _formatTimeOfDay(_inPersonEnd) : '',
    };

    widget.onSave(newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${toBeginningOfSentenceCase(widget.day)} Schedule',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Available for counseling'),
            value: _isWorking,
            onChanged: (value) {
              setState(() {
                _isWorking = value;
              });
            },
          ),
          if (_isWorking) ...[
            const SizedBox(height: 16),
            // Online Schedule
            CheckboxListTile(
              title: const Text('Online Counseling'),
              value: _hasOnline,
              onChanged: (value) {
                setState(() {
                  _hasOnline = value ?? false;
                });
              },
            ),
            if (_hasOnline) ...[
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(_onlineStart?.format(context) ?? 'Select time'),
                onTap: () => _selectTime(true, true),
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(_onlineEnd?.format(context) ?? 'Select time'),
                onTap: () => _selectTime(false, true),
              ),
            ],
            const Divider(),
            // In-Person Schedule
            CheckboxListTile(
              title: const Text('In-Person Counseling'),
              value: _hasInPerson,
              onChanged: (value) {
                setState(() {
                  _hasInPerson = value ?? false;
                });
              },
            ),
            if (_hasInPerson) ...[
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(_inPersonStart?.format(context) ?? 'Select time'),
                onTap: () => _selectTime(true, false),
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(_inPersonEnd?.format(context) ?? 'Select time'),
                onTap: () => _selectTime(false, false),
              ),
            ],
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Schedule'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 