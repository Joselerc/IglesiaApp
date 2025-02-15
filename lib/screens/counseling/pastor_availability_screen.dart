import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  final bool isOnline;
  final bool isInPerson;

  TimeSlot({
    required this.start,
    required this.end,
    this.isOnline = true,
    this.isInPerson = false,
  });
}

class PastorAvailabilityScreen extends StatefulWidget {
  const PastorAvailabilityScreen({super.key});

  @override
  State<PastorAvailabilityScreen> createState() => _PastorAvailabilityScreenState();
}

class _PastorAvailabilityScreenState extends State<PastorAvailabilityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final Map<DateTime, List<TimeSlot>> _availabilityMap = {};

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final doc = await FirebaseFirestore.instance
          .collection('pastor_availability')
          .where('userId', isEqualTo: userRef)
          .get();

      if (doc.docs.isNotEmpty) {
        setState(() {
          final data = doc.docs.first.data();
          data.forEach((key, value) {
            if (value is Map && value.containsKey('slots')) {
              final date = DateTime.parse(key);
              final slots = (value['slots'] as List).map((slot) => TimeSlot(
                    start: TimeOfDay(
                      hour: slot['start']['hour'],
                      minute: slot['start']['minute'],
                    ),
                    end: TimeOfDay(
                      hour: slot['end']['hour'],
                      minute: slot['end']['minute'],
                    ),
                    isOnline: slot['isOnline'],
                    isInPerson: slot['isInPerson'],
                  )).toList();
              _availabilityMap[date] = slots;
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading availability')),
        );
      }
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay == null) return;
    
    setState(() {
      _selectedDay = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      _focusedDay = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start != null ? DateTime(
        start.year,
        start.month,
        start.day,
      ) : null;
      _rangeEnd = end != null ? DateTime(
        end.year,
        end.month,
        end.day,
      ) : null;
    });
  }

  Future<void> _saveAvailability() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final availabilityData = _availabilityMap.map((date, slots) {
        return MapEntry(
          DateFormat('yyyy-MM-dd').format(date),
          {
            'slots': slots.map((slot) => {
              'start': {'hour': slot.start.hour, 'minute': slot.start.minute},
              'end': {'hour': slot.end.hour, 'minute': slot.end.minute},
              'isOnline': slot.isOnline,
              'isInPerson': slot.isInPerson,
            }).toList(),
          },
        );
      });

      await FirebaseFirestore.instance.collection('pastor_availability').doc(userId).set({
        'userId': userRef,
        ...availabilityData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving availability')),
        );
      }
    }
  }

  void _showAddTimeSlotDialog() async {
    if (_selectedDay == null && _rangeStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day or range first')),
      );
      return;
    }

    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (startTime == null) return;

    TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 1) % 24,
        minute: startTime.minute,
      ),
    );

    if (endTime == null) return;

    final isOnline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Type'),
        content: const Text('Is this time slot for online counseling?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('In Person'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Online'),
          ),
        ],
      ),
    );

    if (isOnline == null) return;

    setState(() {
      final dates = _selectedDay != null 
          ? [_selectedDay!]
          : _getDatesInRange(_rangeStart!, _rangeEnd!);

      for (final date in dates) {
        final slots = _availabilityMap[date] ?? [];
        slots.add(TimeSlot(
          start: startTime,
          end: endTime,
          isOnline: isOnline,
          isInPerson: !isOnline,
        ));
        _availabilityMap[date] = slots;
      }
    });
  }

  List<DateTime> _getDatesInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  Widget _buildTimeSlotsList() {
    if (_selectedDay == null && (_rangeStart == null || _rangeEnd == null)) {
      return const Center(
        child: Text('Select a day or range to manage time slots'),
      );
    }

    final dates = _selectedDay != null 
        ? [_selectedDay!]
        : _getDatesInRange(_rangeStart!, _rangeEnd!);

    if (dates.isEmpty) {
      return const Center(
        child: Text('No dates selected'),
      );
    }

    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, dateIndex) {
        final date = dates[dateIndex];
        final slots = _availabilityMap[date] ?? [];

        return Card(
          margin: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateFormat('EEEE, MMMM d, y').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (slots.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('No time slots added'),
                )
              else
                ...slots.map((slot) => ListTile(
                  leading: Icon(
                    slot.isOnline ? Icons.video_call : Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    '${slot.start.format(context)} - ${slot.end.format(context)}',
                  ),
                  subtitle: Text(slot.isOnline ? 'Online' : 'In Person'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _availabilityMap[date]?.remove(slot);
                      });
                    },
                  ),
                )).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Availability'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAvailability,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: RangeSelectionMode.enforced,
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              rangeHighlightColor: Colors.blue,
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _buildTimeSlotsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTimeSlotDialog,
        label: const Text('Add Time Slot'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}