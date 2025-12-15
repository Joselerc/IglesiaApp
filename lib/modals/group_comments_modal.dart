import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_post.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class GroupCommentsModal extends StatefulWidget {
  final GroupPost post;

  const GroupCommentsModal({
    super.key,
    required this.post,
  });

  @override
  State<GroupCommentsModal> createState() => _GroupCommentsModalState();
}

class _GroupCommentsModalState extends State<GroupCommentsModal> {
  final TextEditingController commentController = TextEditingController();
  bool _isSubmitting = false;

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
      return 'agora';
    }
  }

  Future<void> _submitComment() async {
    final comment = commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('group_posts_comments').add({
        'content': comment,
        'authorId': FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid),
        'groupPostId': widget.post.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      commentController.clear();

      await FirebaseFirestore.instance
          .collection('group_posts')
          .doc(widget.post.id)
          .update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(DocumentSnapshot comment) async {
    try {
      final authorId = (comment.data() as Map<String, dynamic>)['authorId'] as DocumentReference;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (authorId.id != currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.deleteOwnCommentsOnly)),
        );
        return;
      }

      final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.deleteComment),
              content: Text(AppLocalizations.of(context)!.deleteCommentConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(AppLocalizations.of(context)!.delete,
                      style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldDelete) return;

      await FirebaseFirestore.instance
          .collection('group_posts_comments')
          .doc(comment.id)
          .delete();

      await FirebaseFirestore.instance
          .collection('group_posts')
          .doc(widget.post.id)
          .update({
        'commentCount': FieldValue.increment(-1),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commentDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.comments,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_posts_comments')
                  .where('groupPostId', isEqualTo: widget.post.id)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noCommentsYet,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        Text(
                          AppLocalizations.of(context)!.beFirstToComment,
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final commentDoc = comments[index];
                    final comment = commentDoc.data() as Map<String, dynamic>;
                    final timestamp = comment['createdAt'] as Timestamp?;
                    final userRef = comment['authorId'] as DocumentReference?;
                    final isAuthor = userRef?.id == FirebaseAuth.instance.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: userRef?.get(),
                            builder: (context, userSnapshot) {
                              String? photoUrl;
                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                photoUrl = userData?['photoUrl'];
                              }
                              return CircleAvatar(
                                radius: 18,
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                backgroundColor: Colors.grey[200],
                                child: photoUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    FutureBuilder<DocumentSnapshot>(
                                      future: userRef?.get(),
                                      builder: (context, userSnapshot) {
                                        String username = 'Usuario';
                                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                          username = userData?['name'] ?? userData?['displayName'] ?? 'Usuario';
                                        }
                                        return Text(
                                          username,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    if (timestamp != null)
                                      Text(
                                        _getTimeAgo(timestamp),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comment['content'] as String? ?? '',
                                  style: const TextStyle(fontSize: 14, height: 1.3),
                                ),
                                if (isAuthor)
                                  GestureDetector(
                                    onTap: () => _deleteComment(commentDoc),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                      ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: FirebaseAuth.instance.currentUser?.photoURL == null
                      ? const Icon(Icons.person, size: 20, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addCommentHint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}