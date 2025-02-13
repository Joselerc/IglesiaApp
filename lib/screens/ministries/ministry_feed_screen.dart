import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ministry.dart';
import '../../models/ministry_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/ministry_event.dart';
import '../../screens/ministries/ministry_event_detail_screen.dart';
/*import '../../screens/ministries/create_ministry_post_screen.dart';*/
import '../../widgets/create_post_bottom_sheet.dart';
import '../../widgets/ministry_post_content.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MinistryFeedScreen extends StatefulWidget {
  final Ministry ministry;

  const MinistryFeedScreen({
    super.key,
    required this.ministry,
  });

  @override
  State<MinistryFeedScreen> createState() => _MinistryFeedScreenState();
}

class _MinistryFeedScreenState extends State<MinistryFeedScreen> {
  final TextEditingController commentController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? imageFile;

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

  void _showComments(BuildContext context, MinistryPost post) {
    final postRef = FirebaseFirestore.instance
        .collection('ministry_posts')
        .doc(post.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.pink[50],
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (context) => Container(
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
                    .collection('comments')
                    .where('postId', isEqualTo: postRef)
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
                            Text(_getTimeAgo(comment['createdAt'] as Timestamp)),
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
                              .collection('comments')
                              .add({
                                'content': commentController.text,
                                'postId': postRef,
                                'authorId': FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser.uid),
                                'createdAt': FieldValue.serverTimestamp(),
                                'likes': [],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ministry.name),
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
                  
              final isAdmin = widget.ministry.ministrieAdmin.contains(userRef);
              
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
                    builder: (context) {
                      final formKey = GlobalKey<FormState>();
                      final titleController = TextEditingController();
                      final descriptionController = TextEditingController();
                      DateTime? selectedDate;
                      TimeOfDay? selectedTime;
                      File? imageFile;

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
                                    ListTile(
                                      leading: const Icon(Icons.image),
                                      title: Text(
                                        imageFile == null
                                            ? 'Select Event Image'
                                            : 'Image Selected',
                                      ),
                                      trailing: imageFile != null
                                          ? const Icon(Icons.check, color: Colors.green)
                                          : null,
                                      onTap: () async {
                                        final picker = ImagePicker();
                                        final pickedFile = await picker.pickImage(
                                          source: ImageSource.gallery,
                                        );
                                        if (pickedFile != null) {
                                          setState(() {
                                            imageFile = File(pickedFile.path);
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (formKey.currentState!.validate() &&
                                              selectedDate != null &&
                                              selectedTime != null &&
                                              imageFile != null) {
                                            try {
                                              final storageRef = FirebaseStorage.instance
                                                  .ref()
                                                  .child('ministry_events')
                                                  .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

                                              await storageRef.putFile(imageFile!);
                                              final imageUrl = await storageRef.getDownloadURL();

                                              final date = DateTime(
                                                selectedDate!.year,
                                                selectedDate!.month,
                                                selectedDate!.day,
                                                selectedTime!.hour,
                                                selectedTime!.minute,
                                              );

                                              await FirebaseFirestore.instance
                                                  .collection('ministry_events')
                                                  .add({
                                                'title': titleController.text,
                                                'description': descriptionController.text,
                                                'date': date,
                                                'imageUrl': imageUrl,
                                                'ministryId': FirebaseFirestore.instance
                                                    .collection('ministries')
                                                    .doc(widget.ministry.id),
                                                'attendees': [],
                                                'isActive': true,
                                              });

                                              if (mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Event created successfully'),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error creating event: $e'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Create Event'),
                                      ),
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
          // SOLO modificamos esta parte - Eventos
          SliverToBoxAdapter(
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ministry_events')
                    .where('isActive', isEqualTo: true)
                    .where('ministryId', isEqualTo: FirebaseFirestore.instance
                        .collection('ministries')
                        .doc(widget.ministry.id))
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
                              builder: (context) => MinistryEventDetailScreen(
                                event: MinistryEvent.fromFirestore(events[index]),
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
                .collection('ministry_posts')
                .where('ministryId', isEqualTo: FirebaseFirestore.instance
                    .collection('ministries')
                    .doc(widget.ministry.id))
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

              List<MinistryPost> posts = [];
              try {
                posts = snapshot.data!.docs
                    .map((doc) => MinistryPost.fromFirestore(doc))
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
                                      GestureDetector(
                                        onTap: () => _showComments(context, post),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.mode_comment_outlined),
                                            const SizedBox(width: 4),
                                            StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('comments')
                                                  .where('postId', isEqualTo: FirebaseFirestore.instance
                                                      .collection('ministry_posts')
                                                      .doc(post.id))
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                print('Post ID: ${post.id}'); // Debug
                                                print('Número de comentarios: ${snapshot.data?.docs.length ?? 0}'); // Debug
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

                            // Usamos el nuevo widget para el contenido
                            MinistryPostContent(
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
                  builder: (context) => CreatePostBottomSheet(
                    ministryId: widget.ministry.id,
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

  Future<void> _handleLike(MinistryPost post) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    final postRef = FirebaseFirestore.instance.collection('ministry_posts').doc(post.id);
    
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

  Future<void> _handleSave(MinistryPost post) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    final postRef = FirebaseFirestore.instance.collection('ministry_posts').doc(post.id);
    
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

  Future<void> _handleShare(MinistryPost post) async {
    // Primero actualizamos el contador de shares
    final postRef = FirebaseFirestore.instance.collection('ministry_posts').doc(post.id);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid);
    
    await postRef.update({
      'shares': FieldValue.arrayUnion([userRef])
    });
    
    // Luego mostramos las opciones de compartir
    await Share.share(
      'Check out this post from ${post.authorId}: ${post.contentText}',
      subject: 'Ministry Post',
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
          .collection('comments')
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