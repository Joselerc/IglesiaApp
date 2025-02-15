import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _blockedDates = List.from(widget.initialDates);
  }

  Future<void> _addDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      // Verificar si ya existe la fecha
      final existingDate = _blockedDates.any((date) =>
          date.year == picked.year &&
          date.month == picked.month &&
          date.day == picked.day);

      if (existingDate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This date is already blocked'),
            ),
          );
        }
        return;
      }

      // Verificar si hay citas programadas para esa fecha
      final appointments = await FirebaseFirestore.instance
          .collection('counseling_appointments')
          .where('pastorId', isEqualTo: widget.availabilityRef)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(picked.year, picked.month, picked.day),
          ))
          .where('date', isLessThan: Timestamp.fromDate(
            DateTime(picked.year, picked.month, picked.day + 1),
          ))
          .get();

      if (appointments.docs.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Warning'),
              content: const Text(
                'There are appointments scheduled for this date. Blocking it will prevent new appointments, but existing ones will be maintained.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _blockedDates.add(picked);
                    });
                  },
                  child: const Text('Block Anyway'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _blockedDates.add(picked);
        });
      }
    }
  }

  Future<void> _removeDate(DateTime date) async {
    // Verificar si hay citas programadas para esa fecha
    final appointments = await FirebaseFirestore.instance
        .collection('counseling_appointments')
        .where('pastorId', isEqualTo: widget.availabilityRef)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(date.year, date.month, date.day),
        ))
        .where('date', isLessThan: Timestamp.fromDate(
          DateTime(date.year, date.month, date.day + 1),
        ))
        .get();

    if (appointments.docs.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning'),
            content: const Text(
              'There are appointments scheduled for this date. Unblocking it will allow new appointments to be scheduled.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _blockedDates.remove(date);
                  });
                },
                child: const Text('Unblock Anyway'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {
        _blockedDates.remove(date);
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.availabilityRef.update({
        'unavailableDates': _blockedDates.map((date) => Timestamp.fromDate(date)).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving blocked dates')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          Row(
            children: [
              const Text(
                'Blocked Dates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addDate,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_blockedDates.isEmpty)
            const Center(
              child: Text(
                'No blocked dates',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _blockedDates.length,
                itemBuilder: (context, index) {
                  final date = _blockedDates[index];
                  return ListTile(
                    title: Text(DateFormat('EEEE, MMMM d, y').format(date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeDate(date),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 