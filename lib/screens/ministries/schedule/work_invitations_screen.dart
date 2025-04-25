import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/work_schedule.dart';

class WorkInvitationsScreen extends StatelessWidget {
  final String ministryId;
  final String userId;

  const WorkInvitationsScreen({
    super.key,
    required this.ministryId,
    required this.userId,
  });

  void _showDescriptionModal(BuildContext context, WorkSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.jobName),
        content: Text(schedule.description ?? 'No description available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToInvitation(BuildContext context, WorkSchedule schedule, String response) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final scheduleRef = FirebaseFirestore.instance
          .collection('work_schedules')
          .doc(schedule.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(scheduleRef);
        final currentSchedule = WorkSchedule.fromFirestore(doc);

        if (response == 'accepted' && !currentSchedule.hasAvailableSpots) {
          throw Exception('No spots available');
        }

        final updatedStatus = Map<DocumentReference, String>.from(currentSchedule.workersStatus);
        final oldStatus = updatedStatus[userRef] ?? 'pending';
        updatedStatus[userRef] = response;

        final newHistory = List<StatusChange>.from(currentSchedule.statusHistory)
          ..add(StatusChange(
            user: userRef,
            fromStatus: oldStatus,
            toStatus: response,
            timestamp: DateTime.now(),
          ));

        final firestoreStatus = updatedStatus.map(
          (key, value) => MapEntry(key.path, value)
        );

        transaction.update(scheduleRef, {
          'workersStatus': firestoreStatus,
          'statusHistory': newHistory.map((change) => change.toMap()).toList(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation ${response == 'accepted' ? 'accepted' : 'declined'} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error responding to invitation: $e')),
      );
    }
  }

  void _showCancelConfirmation(BuildContext context, WorkSchedule schedule) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Participation'),
        content: Text('Are you sure you want to cancel your participation in "${schedule.jobName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final scheduleRef = FirebaseFirestore.instance
                    .collection('work_schedules')
                    .doc(schedule.id);

                await FirebaseFirestore.instance.runTransaction((transaction) async {
                  final doc = await transaction.get(scheduleRef);
                  final currentSchedule = WorkSchedule.fromFirestore(doc);

                  final updatedStatus = Map<DocumentReference, String>.from(currentSchedule.workersStatus);
                  final oldStatus = updatedStatus[userRef] ?? 'accepted';
                  updatedStatus[userRef] = 'cancelled';

                  final newHistory = List<StatusChange>.from(currentSchedule.statusHistory)
                    ..add(StatusChange(
                      user: userRef,
                      fromStatus: oldStatus,
                      toStatus: 'cancelled',
                      timestamp: DateTime.now(),
                    ));

                  final firestoreStatus = updatedStatus.map(
                    (key, value) => MapEntry(key.path, value)
                  );

                  transaction.update(scheduleRef, {
                    'workersStatus': firestoreStatus,
                    'statusHistory': newHistory.map((change) => change.toMap()).toList(),
                  });
                });

                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Participation cancelled successfully')),
                  );
                }
              } catch (e) {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling participation: $e')),
                  );
                }
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Work Schedule'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Invitations'),
              Tab(text: 'Calendar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('work_schedules')
                  .where('ministryId', isEqualTo: ministryId)
                  .where('invitedWorkers', arrayContains: userRef)
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schedules = snapshot.data!.docs
                    .map((doc) => WorkSchedule.fromFirestore(doc))
                    .where((schedule) {
                      final today = DateTime.now();
                      final isToday = schedule.date.year == today.year &&
                                    schedule.date.month == today.month &&
                                    schedule.date.day == today.day;
                      final isFuture = schedule.date.isAfter(today);
                      
                      return (isToday || isFuture) &&
                             schedule.hasAvailableSpots &&
                             (schedule.workersStatus[userRef] == 'pending' ||
                              schedule.workersStatus[userRef] == 'cancelled');
                    })
                    .toList();

                if (schedules.isEmpty) {
                  return const Center(child: Text('No pending invitations'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showDescriptionModal(context, schedule),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule.jobName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(schedule.date),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('HH:mm').format(schedule.timeSlot.startTime)} - ${DateFormat('HH:mm').format(schedule.timeSlot.endTime)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    'Workers: ${schedule.acceptedWorkersCount}/${schedule.requiredWorkers}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => _respondToInvitation(context, schedule, 'rejected'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Decline'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _respondToInvitation(context, schedule, 'accepted'),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('work_schedules')
                  .where('ministryId', isEqualTo: ministryId)
                  .where('invitedWorkers', arrayContains: userRef)
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schedules = snapshot.data!.docs
                    .map((doc) => WorkSchedule.fromFirestore(doc))
                    .where((schedule) => schedule.workersStatus[userRef] == 'accepted')
                    .toList();

                if (schedules.isEmpty) {
                  return const Center(child: Text('No accepted schedules'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: schedule.description != null && schedule.description!.isNotEmpty
                            ? () => _showDescriptionModal(context, schedule)
                            : null,
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(schedule.jobName),
                              const Spacer(),
                              if (schedule.description != null && schedule.description!.isNotEmpty)
                                Text(
                                  'Show description',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(schedule.date),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('HH:mm').format(schedule.timeSlot.startTime)} - ${DateFormat('HH:mm').format(schedule.timeSlot.endTime)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Workers: ${schedule.acceptedWorkersCount}/${schedule.requiredWorkers}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () => _showCancelConfirmation(context, schedule),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
