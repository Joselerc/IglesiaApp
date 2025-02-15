import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/prayer.dart';
import '../../../models/prayer_comment.dart';
import '../../../widgets/loading_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

class PrayerCommentModal extends StatefulWidget {
  final Prayer prayer;

  const PrayerCommentModal({
    super.key,
    required this.prayer,
  });

  @override
  State<PrayerCommentModal> createState() => _PrayerCommentModalState();
}

class _PrayerCommentModalState extends State<PrayerCommentModal> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);

      final prayerRef = FirebaseFirestore.instance
          .collection('prayers')
          .doc(widget.prayer.id);

      await FirebaseFirestore.instance.collection('prayer_comments').add({
        'authorId': userRef,
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'prayerId': prayerRef,
      });

      if (mounted) {
        _commentController.clear();
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 20,
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('prayer_comments')
                .where('prayerId', isEqualTo: FirebaseFirestore.instance.collection('prayers').doc(widget.prayer.id))
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Something went wrong');
              }

              if (!snapshot.hasData) {
                return const LoadingIndicator();
              }

              final comments = snapshot.data!.docs;

              return Expanded(
                child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = PrayerComment.fromFirestore(comments[index]);
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isAuthor = currentUser != null && comment.authorId.id == currentUser.uid;
                    final hasLiked = comment.likes.any((ref) => ref.id == currentUser?.uid);

                    return ListTile(
                      title: Row(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: comment.authorId.snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text('Loading...');
                              
                              final userData = snapshot.data!.data() as Map<String, dynamic>?;
                              return Text(
                                userData?['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(comment.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(comment.content),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: Icon(
                              Icons.thumb_up,
                              color: hasLiked ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                            label: Text(comment.likes.length.toString()),
                            onPressed: () async {
                              if (currentUser == null) return;
                              
                              final userRef = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid);

                              if (hasLiked) {
                                await FirebaseFirestore.instance
                                    .collection('prayer_comments')
                                    .doc(comment.id)
                                    .update({
                                      'likes': FieldValue.arrayRemove([userRef])
                                    });
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('prayer_comments')
                                    .doc(comment.id)
                                    .update({
                                      'likes': FieldValue.arrayUnion([userRef])
                                    });
                              }
                            },
                          ),
                          if (isAuthor)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Comment'),
                                    content: const Text('Are you sure you want to delete this comment?'),
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
                                      .collection('prayer_comments')
                                      .doc(comment.id)
                                      .delete();
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isLoading ? null : _submitComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 