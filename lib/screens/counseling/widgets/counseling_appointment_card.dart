import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/counseling_appointment.dart';
import 'set_reminder_modal.dart';

class CounselingAppointmentCard extends StatelessWidget {
  final CounselingAppointment appointment;
  final bool isPast;

  const CounselingAppointmentCard({
    super.key,
    required this.appointment,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pastor info
                  StreamBuilder<DocumentSnapshot>(
                    stream: appointment.pastorId.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      
                      final pastorData = snapshot.data!.data() as Map<String, dynamic>?;
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: pastorData?['photoUrl'] != null
                                ? NetworkImage(pastorData!['photoUrl'])
                                : null,
                            child: pastorData?['photoUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pastor ${pastorData?['name'] ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, MMMM d, y - h:mm a')
                                      .format(appointment.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Location info
                  Row(
                    children: [
                      Icon(
                        appointment.isOnline ? Icons.video_call : Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status and actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusTextColor(appointment.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isPast && appointment.status == 'scheduled')
                        TextButton.icon(
                          icon: const Icon(Icons.notifications),
                          label: Text(
                            appointment.reminder?.isSet == true
                                ? 'Edit Reminder'
                                : 'Set Reminder',
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => SetReminderModal(
                                appointment: appointment,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Blur overlay for past appointments
            if (isPast)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.green[100]!;
      case 'completed':
        return Colors.blue[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.green[900]!;
      case 'completed':
        return Colors.blue[900]!;
      case 'cancelled':
        return Colors.red[900]!;
      default:
        return Colors.grey[900]!;
    }
  }
} 