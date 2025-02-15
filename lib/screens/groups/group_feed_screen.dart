import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../../models/group_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/group_event.dart';
import 'group_event_detail_screen.dart';
import '../../widgets/create_group_post_bottom_sheet.dart';
import '../../widgets/group_post_content.dart';
import 'dart:io';
import '../../modals/group_comments_modal.dart';
import '../../modals/create_group_event_modal.dart';
import 'group_chat_screen.dart';
import '../profile_screen.dart';
import 'group_details_screen.dart';

class GroupFeedScreen extends StatefulWidget {
  final Group group;

  const GroupFeedScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? imageFile;

  void _showComments(BuildContext context, GroupPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.pink[50],
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (context) => GroupCommentsModal(post: post),
    );
  }

  Future<void> _handleLike(GroupPost post) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    final postRef = FirebaseFirestore.instance.collection('group_posts').doc(post.id);
    
    if (post.likes.contains(userRef)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userRef])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userRef])
      });
    }
  }

  Future<void> _handleSave(GroupPost post) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    final postRef = FirebaseFirestore.instance.collection('group_posts').doc(post.id);
    
    if (post.savedBy.contains(userRef)) {
      await postRef.update({
        'savedBy': FieldValue.arrayRemove([userRef])
      });
    } else {
      await postRef.update({
        'savedBy': FieldValue.arrayUnion([userRef])
      });
    }
  }

  Future<void> _handleShare(GroupPost post) async {
    final postRef = FirebaseFirestore.instance.collection('group_posts').doc(post.id);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    
    await postRef.update({
      'shares': FieldValue.arrayUnion([userRef])
    });
    
    await Share.share(
      'Check out this post from ${post.authorId}: ${post.contentText}',
      subject: 'Group Post',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailsScreen(
                  group: widget.group,
                ),
              ),
            );
          },
          child: Text(widget.group.name),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final userRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid);
                  
              final isAdmin = widget.group.groupAdmin.contains(userRef);
              
              if (!isAdmin) return const SizedBox();

              return TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => CreateGroupEventModal(group: widget.group),
                  );
                },
                icon: const Icon(Icons.event_available, color: Colors.green),
                label: const Text(
                  'New Event',
                  style: TextStyle(color: Colors.green),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('group_events')
                    .where('groupId', isEqualTo: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.group.id))
                    .where('isActive', isEqualTo: true)
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar eventos'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data!.docs;
                  
                  if (events.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay eventos próximos',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final eventData = events[index].data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupEventDetailScreen(
                                event: GroupEvent.fromFirestore(events[index]),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: eventData['imageUrl'] != null
                                    ? Image.network(
                                        eventData['imageUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.event);
                                        },
                                      )
                                    : const Icon(Icons.event),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                eventData['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('group_posts')
                .where('groupId', isEqualTo: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.group.id))
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Error al cargar los posts')),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No hay posts aún')),
                );
              }

              List<GroupPost> posts = [];
              try {
                posts = snapshot.data!.docs
                    .map((doc) => GroupPost.fromFirestore(doc))
                    .toList();
              } catch (e) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('Error al procesar los posts: $e')),
                );
              }

              if (posts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No hay posts disponibles')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= posts.length) return null;
                    final post = posts[index];
                    
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(post.authorId.id)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        final userName = userSnapshot.hasData && userSnapshot.data!.exists
                            ? (userSnapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Usuario desconocido'
                            : 'Cargando...';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey,
                                        child: Icon(Icons.person, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Lógica para reportar
                                    },
                                    child: Text(
                                      'Report',
                                      style: TextStyle(
                                        color: Colors.blue[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (post.imageUrls.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Image.network(
                                    post.imageUrls[0],
                                    fit: BoxFit.cover,
                                    key: ValueKey('post_image_${post.id}'),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading post image: $error');
                                      return const Center(
                                        child: Icon(Icons.image_not_supported, size: 40),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          post.likes.contains(FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(FirebaseAuth.instance.currentUser?.uid))
                                              ? Icons.favorite 
                                              : Icons.favorite_border,
                                          size: 24,
                                        ),
                                        onPressed: () => _handleLike(post),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.likes.length.toString(),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () => _showComments(context, post),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.mode_comment_outlined),
                                            const SizedBox(width: 4),
                                            StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('group_posts_comments')
                                                  .where('groupPostId', isEqualTo: post.id)
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                                return Text('$count');
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.share_outlined, size: 24),
                                        onPressed: () => _handleShare(post),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        post.shares.length.toString(),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      post.savedBy.contains(FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(FirebaseAuth.instance.currentUser?.uid))
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      size: 24,
                                    ),
                                    onPressed: () => _handleSave(post),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.savedBy.length.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),

                            GroupPostContent(
                              userName: userName,
                              content: post.contentText,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => CreateGroupPostBottomSheet(
                    groupId: widget.group.id,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      group: widget.group,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}