import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/prayer.dart';
import '../modals/prayer_comment_modal.dart';
import 'package:timeago/timeago.dart' as timeago;

class PrayerCard extends StatelessWidget {
  final Prayer prayer;

  const PrayerCard({
    super.key,
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser != null && prayer.createdBy.id == currentUser.uid;
    final hasUpvoted = prayer.upVotedBy.any((ref) => ref.id == currentUser?.uid);
    final hasDownvoted = prayer.downVotedBy.any((ref) => ref.id == currentUser?.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: prayer.createdBy.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('Loading...');
                    
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final username = prayer.isAnonymous ? 'Anonymous' : (userData?['name'] ?? 'Unknown');
                    
                    return Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const Spacer(),
                if (prayer.isAccepted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Accepted',
                      style: TextStyle(
                        color: Colors.green,
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
                          content: const Text('Are you sure you want to delete this prayer?'),
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
                            .collection('prayers')
                            .doc(prayer.id)
                            .delete();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(prayer.content),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!prayer.isAccepted) ...[
                  IconButton(
                    icon: Icon(
                      Icons.arrow_upward,
                      color: hasUpvoted ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () async {
                      if (currentUser == null) return;
                      
                      final userRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid);

                      if (hasUpvoted) {
                        await FirebaseFirestore.instance
                            .collection('prayers')
                            .doc(prayer.id)
                            .update({
                              'upVotedBy': FieldValue.arrayRemove([userRef])
                            });
                      } else {
                        if (hasDownvoted) {
                          await FirebaseFirestore.instance
                              .collection('prayers')
                              .doc(prayer.id)
                              .update({
                                'downVotedBy': FieldValue.arrayRemove([userRef])
                              });
                        }
                        await FirebaseFirestore.instance
                            .collection('prayers')
                            .doc(prayer.id)
                            .update({
                              'upVotedBy': FieldValue.arrayUnion([userRef])
                            });
                      }
                    },
                  ),
                  Text((prayer.upVotedBy.length - prayer.downVotedBy.length).toString()),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_downward,
                      color: hasDownvoted ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      if (currentUser == null) return;
                      
                      final userRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid);

                      if (hasDownvoted) {
                        await FirebaseFirestore.instance
                            .collection('prayers')
                            .doc(prayer.id)
                            .update({
                              'downVotedBy': FieldValue.arrayRemove([userRef])
                            });
                      } else {
                        if (hasUpvoted) {
                          await FirebaseFirestore.instance
                              .collection('prayers')
                              .doc(prayer.id)
                              .update({
                                'upVotedBy': FieldValue.arrayRemove([userRef])
                              });
                        }
                        await FirebaseFirestore.instance
                            .collection('prayers')
                            .doc(prayer.id)
                            .update({
                              'downVotedBy': FieldValue.arrayUnion([userRef])
                            });
                      }
                    },
                  ),
                  const Spacer(),
                ],
                TextButton.icon(
                  icon: const Icon(Icons.comment),
                  label: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('prayer_comments')
                        .where('prayerId', isEqualTo: FirebaseFirestore.instance.collection('prayers').doc(prayer.id))
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text('$count');
                    },
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => FractionallySizedBox(
                        heightFactor: 0.7,
                        child: PrayerCommentModal(
                          prayer: prayer,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              timeago.format(prayer.createdAt),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 