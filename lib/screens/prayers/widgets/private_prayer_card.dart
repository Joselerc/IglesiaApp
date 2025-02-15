import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/private_prayer.dart';

class PrivatePrayerCard extends StatelessWidget {
  final PrivatePrayer prayer;

  const PrivatePrayerCard({
    super.key,
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser != null && prayer.userId.id == currentUser.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pastor name
                StreamBuilder<DocumentSnapshot>(
                  stream: prayer.pastorId.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('Loading...');
                    
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    return Text(
                      'Pastor ${userData?['name'] ?? 'Unknown'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: prayer.isAccepted ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prayer.isAccepted ? 'Accepted' : 'Pending',
                    style: TextStyle(
                      color: prayer.isAccepted ? Colors.green : Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isCreator)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Prayer'),
                          content: const Text('Are you sure you want to delete this private prayer?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await FirebaseFirestore.instance
                            .collection('private_prayers')
                            .doc(prayer.id)
                            .delete();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(prayer.content),
            const SizedBox(height: 8),
            if (prayer.isAccepted && prayer.scheduledAt != null) ...[
              const Divider(),
              Row(
                children: [
                  Icon(
                    prayer.selectedMethod == 'call' ? Icons.phone : Icons.phone_iphone,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scheduled for ${_formatDateTime(prayer.scheduledAt!)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            if (!prayer.isAccepted) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Requested ${timeago.format(prayer.createdAt)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 