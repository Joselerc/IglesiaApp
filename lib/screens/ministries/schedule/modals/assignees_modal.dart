import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/work_schedule.dart';
import 'send_more_invites_modal.dart';

class AssigneesModal extends StatelessWidget {
  final WorkSchedule schedule;
  final String ministryId;
  final bool isLeader;

  const AssigneesModal({
    super.key,
    required this.schedule,
    required this.ministryId,
    required this.isLeader,
  });

  void _showSendMoreInvitesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SendMoreInvitesModal(
        schedule: schedule,
        ministryId: ministryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Text(
                  'Assignees',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${schedule.acceptedWorkersCount}/${schedule.requiredWorkers}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          // List of assignees
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: Future.wait(
                schedule.invitedWorkers.map((ref) => ref.get())
              ).asStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;
                
                // Ordenar usuarios por estado
                final sortedUsers = users.where((user) {
                  final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
                  return schedule.workersStatus[userRef] == 'accepted';
                }).toList()
                  ..addAll(users.where((user) {
                    final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
                    return schedule.workersStatus[userRef] == 'pending';
                  }))
                  ..addAll(users.where((user) {
                    final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
                    return schedule.workersStatus[userRef] == 'rejected' || 
                           schedule.workersStatus[userRef] == 'cancelled';
                  }));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final user = sortedUsers[index];
                    final userData = user.data() as Map<String, dynamic>;
                    final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
                    final status = schedule.workersStatus[userRef];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userData['photoUrl'] != null && userData['photoUrl'].isNotEmpty
                            ? NetworkImage(userData['photoUrl'])
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: userData['photoUrl'] == null || userData['photoUrl'].isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(userData['name'] ?? 'Unknown'),
                      subtitle: Text(
                        _getStatusText(status ?? 'pending'),
                        style: TextStyle(
                          color: _getStatusColor(status ?? 'pending'),
                          fontSize: 12,
                        ),
                      ),
                      trailing: _getStatusIcon(status ?? 'pending'),
                    );
                  },
                );
              },
            ),
          ),
          // Send More Invites button
          if (isLeader) Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: ElevatedButton(
              onPressed: () => _showSendMoreInvitesModal(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Send More Invites'),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'pending':
        return 'Pending response';
      case 'rejected':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled participation';
      default:
        return 'Unknown status';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    final color = _getStatusColor(status);
    switch (status) {
      case 'accepted':
        return Icon(Icons.check_circle, color: color);
      case 'pending':
        return Icon(Icons.schedule, color: color);
      case 'rejected':
      case 'cancelled':
        return Icon(Icons.cancel, color: color);
      default:
        return Icon(Icons.help, color: color);
    }
  }
}