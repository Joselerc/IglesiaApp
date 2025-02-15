import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/counseling_appointment.dart';

class SetReminderModal extends StatefulWidget {
  final CounselingAppointment appointment;

  const SetReminderModal({
    super.key,
    required this.appointment,
  });

  @override
  State<SetReminderModal> createState() => _SetReminderModalState();
}

class _SetReminderModalState extends State<SetReminderModal> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.appointment.reminder?.isSet == true) {
      _selectedDate = widget.appointment.reminder!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.appointment.reminder!.date);
    }
  }

  Future<void> _selectDate() async {
    final appointmentDate = widget.appointment.date;
    final now = DateTime.now();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: appointmentDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final reminderDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (reminderDateTime.isAfter(widget.appointment.date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder cannot be set after the appointment time'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('counseling_appointments')
          .doc(widget.appointment.id)
          .update({
        'reminder': {
          'date': Timestamp.fromDate(reminderDateTime),
          'isSet': true,
        },
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving reminder')),
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

  Future<void> _removeReminder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('counseling_appointments')
          .doc(widget.appointment.id)
          .update({
        'reminder': {
          'date': null,
          'isSet': false,
        },
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error removing reminder')),
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Reminder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Appointment: ${DateFormat('EEEE, MMMM d, y - h:mm a').format(widget.appointment.date)}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Reminder Date'),
            subtitle: Text(
              _selectedDate != null
                  ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                  : 'Select date',
            ),
            onTap: _selectDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder Time'),
            subtitle: Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : 'Select time',
            ),
            onTap: _selectTime,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.appointment.reminder?.isSet == true)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _removeReminder,
                    child: const Text('Remove Reminder'),
                  ),
                ),
              if (widget.appointment.reminder?.isSet == true)
                const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveReminder,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Reminder'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 