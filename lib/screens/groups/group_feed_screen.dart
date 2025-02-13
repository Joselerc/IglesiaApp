import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../../models/group_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/group_event.dart';
import 'group_event_detail_screen.dart';
import '../../widgets/create_group_post_bottom_sheet.dart';
import '../../widgets/group_post_content.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
  final TextEditingController commentController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          // Verificamos si el usuario actual es admin
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
                onPressed: () => _showCreateEventModal(context),
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
          // SOLO modificamos esta parte - Eventos
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
                    .where('date', isGreaterThanOrEqualTo: DateTime.now())
                    .where('isActive', isEqualTo: true)
                    .orderBy('date')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('❌ EVENTOS - Error: ${snapshot.error}');
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
          
          // Posts
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
                            // Header con nombre y Report
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

                            // Imagen del post
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

                            // Botones de interacción
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
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('group_posts_comments')
                                            .where('postId', isEqualTo: FirebaseFirestore.instance
                                                .collection('group_posts')
                                                .doc(post.id))
                                            .orderBy('createdAt', descending: true)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          // Logs para debug
                                          print('Post ID actual: ${post.id}');
                                          print('Referencia completa: ${FirebaseFirestore.instance
                                              .collection('group_posts')
                                              .doc(post.id).path}');
                                          
                                          if (snapshot.hasData) {
                                            snapshot.data!.docs.forEach((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              print('Comentario encontrado:');
                                              print('- ID: ${doc.id}');
                                              print('- PostID ref: ${(data['postId'] as DocumentReference).path}');
                                              print('- Contenido: ${data['content']}');
                                            });
                                          }

                                          final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                          
                                          return Row(
                                            children: [
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(Icons.chat_bubble_outline, size: 24),
                                                onPressed: () => _showComments(context, post),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                commentCount.toString(),
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          );
                                        },
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

                            // Usamos el nuevo widget para el contenido
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
                // Ya estamos en home
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
              icon: const Icon(Icons.person),
              onPressed: () {
                // Navegar al perfil
              },
            ),
          ],
        ),
      ),
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
    // Primero actualizamos el contador de shares
    final postRef = FirebaseFirestore.instance.collection('group_posts').doc(post.id);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    
    await postRef.update({
      'shares': FieldValue.arrayUnion([userRef])
    });
    
    // Luego mostramos las opciones de compartir
    await Share.share(
      'Check out this post from ${post.authorId}: ${post.contentText}',
      subject: 'Group Post',
    );
  }

  void _showComments(BuildContext context, GroupPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comments'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
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
                        await FirebaseFirestore.instance
                            .collection('group_posts_comments')
                            .add({
                          'content': commentController.text,
                          'postId': post.id,
                          'authorId': FirebaseAuth.instance.currentUser?.uid,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();
        DateTime? selectedDate;
        TimeOfDay? selectedTime;
        File? imageFile;
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create New Event',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : DateFormat('MMM d, y').format(selectedDate!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                      ),
                      ListTile(
                        title: Text(
                          selectedTime == null
                              ? 'Select Time'
                              : selectedTime!.format(context),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate() &&
                              selectedDate != null &&
                              selectedTime != null) {
                            try {
                              setState(() => isLoading = true);
                              
                              String imageUrl = '';
                              final ref = FirebaseStorage.instance
                                  .ref()
                                  .child('group_events')
                                  .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                              
                              await ref.putFile(imageFile!);
                              imageUrl = await ref.getDownloadURL();

                              final eventDate = DateTime(
                                selectedDate!.year,
                                selectedDate!.month,
                                selectedDate!.day,
                                selectedTime!.hour,
                                selectedTime!.minute,
                              );

                              await FirebaseFirestore.instance
                                  .collection('group_events')
                                  .add({
                                'title': titleController.text,
                                'description': descriptionController.text,
                                'date': Timestamp.fromDate(eventDate),
                                'imageUrl': imageUrl,
                                'groupId': FirebaseFirestore.instance
                                    .collection('groups')
                                    .doc(widget.group.id),
                                'createdBy': FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser?.uid),
                                'createdAt': FieldValue.serverTimestamp(),
                                'isActive': true,
                              });

                              if (mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error creating event: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Create Event'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Widget _buildCommentTile({
    required BuildContext context,
    required Map<String, dynamic> comment,
    required String commentId,
    required TextEditingController commentController,
  }) {
    return ListTile(
      title: Text(comment['content']),
      subtitle: Text(
        DateFormat('MMM d, y').format(
          (comment['createdAt'] as Timestamp).toDate(),
        ),
      ),
    );
  }
}

class CommentRepliesToggle extends StatefulWidget {
  final String commentId;
  final TextEditingController commentController;
  final Function(String) onToggle;
  final void Function(String, String, TextEditingController) onReply;
  final Widget Function({
    required BuildContext context,
    required Map<String, dynamic> comment,
    required String commentId,
    required bool isReply,
    required TextEditingController commentController,
    required void Function(String, String, TextEditingController) onReply,
  }) buildCommentTile;
  
  const CommentRepliesToggle({
    Key? key,
    required this.commentId,
    required this.commentController,
    required this.onToggle,
    required this.buildCommentTile,
    required this.onReply,
  }) : super(key: key);

  @override
  State<CommentRepliesToggle> createState() => _CommentRepliesToggleState();
}

class _CommentRepliesToggleState extends State<CommentRepliesToggle> {
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Expandir automáticamente si hay una nueva respuesta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.commentController.text.contains('@')) {
        setState(() {
          isExpanded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('group_posts_comments')
          .where('parentCommentId', isEqualTo: widget.commentId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final replies = snapshot.data!.docs;
        // Mostrar siempre el toggle si hay respuestas o si está expandido
        if (replies.isEmpty && !isExpanded) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón de expandir
            InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
                widget.onToggle(widget.commentId);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${replies.length} ${replies.length == 1 ? 'respuesta' : 'respuestas'}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenedor expandible con respuestas
            if (isExpanded) 
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: replies.length,
                itemBuilder: (context, index) {
                  final reply = replies[index];
                  final replyData = reply.data() as Map<String, dynamic>;
                  
                  if (!replyData.containsKey('likes')) {
                    replyData['likes'] = [];
                  }
                  
                  return Container(
                    padding: const EdgeInsets.only(left: 40.0),
                    child: widget.buildCommentTile(
                      context: context,
                      comment: replyData,
                      commentId: reply.id,
                      isReply: true,
                      commentController: widget.commentController,
                      onReply: widget.onReply,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}