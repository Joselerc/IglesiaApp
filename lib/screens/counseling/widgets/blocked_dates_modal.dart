import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class BlockedDatesModal extends StatefulWidget {
  final DocumentReference availabilityRef;
  final List<DateTime> initialDates;

  const BlockedDatesModal({
    super.key,
    required this.availabilityRef,
    required this.initialDates,
  });

  @override
  State<BlockedDatesModal> createState() => _BlockedDatesModalState();
}

class _BlockedDatesModalState extends State<BlockedDatesModal> {
  late List<DateTime> _blockedDates;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _blockedDates = List.from(widget.initialDates);
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
  }

  Future<void> _toggleDate(DateTime date) async {
    // Normalizar la fecha para que solo tenga año, mes y día
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // Verificar si la fecha ya está bloqueada
    final isBlocked = _blockedDates.any((blockedDate) => 
        blockedDate.year == normalizedDate.year && 
        blockedDate.month == normalizedDate.month && 
        blockedDate.day == normalizedDate.day);
    
    if (isBlocked) {
      // Verificar si hay citas programadas para esta fecha antes de desbloquearla
      final hasAppointments = await _checkForAppointments(normalizedDate);
      if (hasAppointments) {
        if (mounted) {
          _showAppointmentsExistDialog();
        }
        return;
      }
      
      setState(() {
        _blockedDates.removeWhere((blockedDate) => 
            blockedDate.year == normalizedDate.year && 
            blockedDate.month == normalizedDate.month && 
            blockedDate.day == normalizedDate.day);
      });
    } else {
      setState(() {
        _blockedDates.add(normalizedDate);
      });
    }
  }

  Future<bool> _checkForAppointments(DateTime date) async {
    try {
      // Obtener el ID del pastor desde la referencia
      final pastorId = widget.availabilityRef.id;
      
      // Crear fechas de inicio y fin para el día
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // Buscar citas para este pastor en esta fecha
      final querySnapshot = await FirebaseFirestore.instance
          .collection('counseling_appointments')
          .where('pastorId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(pastorId))
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar citas: $e');
      return false;
    }
  }

  void _showAppointmentsExistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se puede desbloquear'),
        content: const Text(
          'No se puede desbloquear esta fecha porque hay citas programadas. '
          'Cancele las citas primero antes de desbloquear la fecha.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBlockedDates() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Convertir las fechas a Timestamp para Firestore
      final blockedDatesTimestamps = _blockedDates
          .map((date) => Timestamp.fromDate(date))
          .toList();
      
      // Actualizar solo el campo de fechas bloqueadas
      await widget.availabilityRef.update({
        'unavailableDates': blockedDatesTimestamps,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fechas bloqueadas guardadas correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
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
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Gestionar Fechas Bloqueadas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Seleccione las fechas que desea bloquear o desbloquear:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _toggleDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                // Verificar si el día está bloqueado
                final isBlocked = _blockedDates.any((blockedDate) => 
                    blockedDate.year == day.year && 
                    blockedDate.month == day.month && 
                    blockedDate.day == day.day);
                
                if (isBlocked) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBlockedDates,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Guardar Fechas Bloqueadas'),
            ),
          ),
        ],
      ),
    );
  }
} 