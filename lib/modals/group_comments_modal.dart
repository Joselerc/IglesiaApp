import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_post.dart';

class GroupCommentsModal extends StatelessWidget {
  final GroupPost post;
  final TextEditingController commentController = TextEditingController();

  GroupCommentsModal({
    super.key,
    required this.post,
  });

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Comments'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_posts_comments')
                  .where('groupPostId', isEqualTo: post.id)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    final timestamp = comment['createdAt'] as Timestamp?;
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(comment['authorId'].id)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          final userName = userSnapshot.hasData && userSnapshot.data!.exists
                              ? (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Usuario desconocido'
                              : 'Cargando...';
                          return Text(userName);
                        },
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment['content'] ?? ''),
                          Text(
                            timestamp != null 
                                ? _getTimeAgo(timestamp)
                                : 'now'
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (commentController.text.isNotEmpty) {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        await FirebaseFirestore.instance
                            .collection('group_posts_comments')
                            .add({
                              'content': commentController.text.trim(),
                              'groupPostId': post.id,
                              'authorId': FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        commentController.clear();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 