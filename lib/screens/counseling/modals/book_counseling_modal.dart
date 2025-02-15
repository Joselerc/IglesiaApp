import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookCounselingModal extends StatefulWidget {
  const BookCounselingModal({super.key});

  @override
  State<BookCounselingModal> createState() => _BookCounselingModalState();
}

class _BookCounselingModalState extends State<BookCounselingModal> {
  DocumentReference? _selectedPastorId;
  bool? _isOnline;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // Almacenamos la disponibilidad del pastor seleccionado
  DocumentSnapshot? _pastorAvailability;

  Future<void> _loadPastorAvailability() async {
    if (_selectedPastorId == null) return;

    setState(() {
      _pastorAvailability = null;
      _selectedDate = null;
      _selectedTime = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('pastor_availability')
          .doc(_selectedPastorId!.id)  // Usamos el ID del pastor directamente
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This pastor has not set their availability yet'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _pastorAvailability = doc;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading pastor availability')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    if (_selectedPastorId == null || _isOnline == null || _pastorAvailability == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pastor and appointment type first'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final availabilityData = _pastorAvailability!.data() as Map<String, dynamic>;

    // Encontrar la primera fecha disponible
    DateTime initialDate = now;
    bool foundValidDate = false;
    for (int i = 0; i < 90; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayData = availabilityData[dateStr];
      
      if (dayData != null && 
          dayData.containsKey('slots') && 
          (dayData['slots'] as List).isNotEmpty &&
          (dayData['slots'] as List).any((slot) => 
            (_isOnline! && slot['isOnline']) || (!_isOnline! && slot['isInPerson'])
          )) {
        initialDate = date;
        foundValidDate = true;
        break;
      }
    }

    if (!foundValidDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available dates found in the next 90 days'),
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime date) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayData = availabilityData[dateStr];
        
        if (dayData == null || !dayData.containsKey('slots') || (dayData['slots'] as List).isEmpty) {
          return false;
        }

        return (dayData['slots'] as List).any((slot) => 
          (_isOnline! && slot['isOnline']) || (!_isOnline! && slot['isInPerson'])
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null || _pastorAvailability == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date first')),
      );
      return;
    }

    final availabilityData = _pastorAvailability!.data() as Map<String, dynamic>;
    final dayName = DateFormat('EEEE').format(_selectedDate!).toLowerCase();
    final daySchedule = availabilityData[dayName];

    // Obtener el rango de horas disponibles
    final startTimeStr = _isOnline! ? daySchedule['onlineStart'] : daySchedule['inPersonStart'];
    final endTimeStr = _isOnline! ? daySchedule['onlineEnd'] : daySchedule['inPersonEnd'];
    
    final startTime = TimeOfDay(
      hour: int.parse(startTimeStr.split(':')[0]),
      minute: int.parse(startTimeStr.split(':')[1])
    );
    final endTime = TimeOfDay(
      hour: int.parse(endTimeStr.split(':')[0]),
      minute: int.parse(endTimeStr.split(':')[1])
    );

    // Obtener citas existentes para ese día
    final existingAppointments = await FirebaseFirestore.instance
        .collection('counseling_appointments')
        .where('pastorId', isEqualTo: _selectedPastorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)))
        .where('date', isLessThan: Timestamp.fromDate(
          DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day + 1)))
        .get();

    final bookedTimes = existingAppointments.docs
        .map((doc) => TimeOfDay.fromDateTime((doc.data()['date'] as Timestamp).toDate()))
        .toList();

    final sessionDuration = availabilityData['sessionDuration'] ?? 60;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                    states.contains(MaterialState.selected)
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      // Verificar si la hora está dentro del rango disponible
      final selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        picked.hour,
        picked.minute,
      );

      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        endTime.hour,
        endTime.minute,
      );

      if (selectedDateTime.isBefore(startDateTime) || 
          selectedDateTime.isAfter(endDateTime.subtract(Duration(minutes: sessionDuration)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a time between ${startTime.format(context)} and ${endTime.format(context)}'
            ),
          ),
        );
        return;
      }

      // Verificar si el horario está ocupado
      if (bookedTimes.any((time) => 
          time.hour == picked.hour && time.minute == picked.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time slot is already booked'),
          ),
        );
        return;
      }

      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedPastorId == null ||
        _isOnline == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);

      await FirebaseFirestore.instance.collection('counseling_appointments').add({
        'pastorId': _selectedPastorId,
        'userId': userRef,
        'date': Timestamp.fromDate(appointmentDate),
        'isOnline': _isOnline,
        'location': _isOnline! ? 'online' : "Church Avenue 32, Pinheiros",
        'status': 'scheduled',
        'reminder': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error booking appointment')),
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
    final bool canSelectDateTime = _selectedPastorId != null && _isOnline != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Book Counseling',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Pastor selector
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'pastor')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final pastors = snapshot.data!.docs;

                  return DropdownButtonFormField<DocumentReference>(
                    decoration: const InputDecoration(
                      labelText: 'Select Pastor',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedPastorId,
                    items: pastors.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.reference,
                        child: Text('Pastor ${data['name'] ?? 'Unknown'}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPastorId = value;
                      });
                      _loadPastorAvailability();
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Appointment type selector
              DropdownButtonFormField<bool>(
                decoration: const InputDecoration(
                  labelText: 'Appointment Type',
                  border: OutlineInputBorder(),
                ),
                value: _isOnline,
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('Online'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('In Person'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _isOnline = value;
                    _selectedDate = null;
                    _selectedTime = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Date and time selection siempre visible
              ListTile(
                enabled: canSelectDateTime,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Select Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? DateFormat('EEEE, MMMM d, y').format(_selectedDate!)
                      : 'Select pastor and type first',
                  style: TextStyle(
                    color: canSelectDateTime ? null : Colors.grey,
                  ),
                ),
                onTap: canSelectDateTime ? _selectDate : null,
              ),
              ListTile(
                enabled: canSelectDateTime && _selectedDate != null,
                leading: const Icon(Icons.access_time),
                title: const Text('Select Time'),
                subtitle: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : canSelectDateTime 
                          ? 'Select date first'
                          : 'Select pastor and type first',
                  style: TextStyle(
                    color: (canSelectDateTime && _selectedDate != null) ? null : Colors.grey,
                  ),
                ),
                onTap: (canSelectDateTime && _selectedDate != null) ? _selectTime : null,
              ),
              const SizedBox(height: 24),
              if (_isOnline == false)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Church Avenue 32, Pinheiros',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookAppointment,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Book Appointment'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
