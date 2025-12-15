import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../../models/group_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group_event.dart';
import 'group_event_detail_screen.dart';
import '../../widgets/create_group_post_bottom_sheet.dart';
import '../../screens/create_post_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../modals/group_comments_modal.dart';
import 'group_chat_screen.dart';
import '../profile_screen.dart';
import 'group_details_screen.dart';
import 'manage_group_requests_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin/admin_events_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

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
  bool _canCreateEvents = false;
  bool _canManageRequests = false;
  bool _canCreatePosts = false;

  void _showComments(BuildContext context, GroupPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => GroupCommentsModal(post: post),
    );
  }

  void _navigateToManageRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageGroupRequestsScreen(group: widget.group),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPermissions();
      _markNotificationsAsRead();
    });
  }

  Future<void> _markNotificationsAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      final generalNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('entityId', isEqualTo: widget.group.id)
          .where('isRead', isEqualTo: false)
          .where('entityType', whereIn: ['group', 'group_event'])
          .get();

      for (var doc in generalNotifs.docs) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking notifications: $e');
    }
  }

  Future<void> _loadPermissions() async {
    if (mounted) {
      setState(() {
        _canCreateEvents = true;
        _canManageRequests = true;
        _canCreatePosts = true;
      });
    }
  }

  Widget _buildEventsSection() {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('group_events')
          .where('groupId', isEqualTo: FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.id))
          .orderBy('date')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final events = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date =
                  (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              if (date.isAfter(now) || _isSameDay(date, now)) {
                return doc;
              }
              return null;
            })
            .where((element) => element != null)
            .toList();

        if (events.isEmpty) {
          return const SizedBox.shrink();
        }
        const double cardSize = 210;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.upcomingEvents,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_canCreateEvents)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminEventsListScreen(
                                initialFilterType: 'group',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: cardSize,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final doc = events[index]!;
                    final event = GroupEvent.fromFirestore(doc);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupEventDetailScreen(event: event),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: cardSize,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Imagen de fondo
                              if (event.imageUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: event.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.event,
                                        color: Colors.grey),
                                  ),
                                )
                              else
                                Container(
                                  color: Colors.green.withOpacity(0.1),
                                  child: const Icon(Icons.event,
                                      size: 48, color: Colors.green),
                                ),

                              // 2. Gradiente
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.8),
                                    ],
                                    stops: const [0.4, 0.7, 1.0],
                                  ),
                                ),
                              ),

                              // 3. Contenido Texto
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3.0,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('d MMM • HH:mm',
                                                  Localizations.localeOf(
                                                          context)
                                                      .languageCode)
                                              .format(event.date),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(
                group: widget.group,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green.withOpacity(0.1),
                backgroundImage: widget.group.imageUrl.isNotEmpty
                    ? NetworkImage(widget.group.imageUrl)
                      : null,
                child: widget.group.imageUrl.isEmpty
                    ? const Icon(Icons.group, color: Colors.green)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Grupo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_canManageRequests) 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('membership_requests')
                  .where('entityId', isEqualTo: widget.group.id)
                  .where('entityType', isEqualTo: 'group')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final pendingCount =
                    snapshot.hasData ? snapshot.data!.docs.length : 0;
                return IconButton(
                  icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                    child:
                        const Icon(Icons.people_outline, color: Colors.black87),
                  ),
                    tooltip: AppLocalizations.of(context)!.manageRequests,
                    onPressed: _navigateToManageRequests,
                );
              },
            ),
          const SizedBox(width: 8),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildEventsSection()),
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
                return SliverToBoxAdapter(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 60, horizontal: 20),
                    child: Center(
                        child: Column(
                          children: [
                          Icon(Icons.groups_outlined,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.groupNoPostsYet,
                            textAlign: TextAlign.center,
                          style: TextStyle(
                                color: Colors.grey[500], fontSize: 16),
                          ),
                          if (_canCreatePosts) ...[
                            const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                  builder: (context) =>
                                      CreateGroupPostBottomSheet(
                                  groupId: widget.group.id,
                                ),
                              );
                            },
                              icon: const Icon(Icons.add),
                              label:
                                  Text(AppLocalizations.of(context)!.createPost),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ],
                    ),
                  ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final post = GroupPost.fromFirestore(doc);
                    return GroupPostCard(
                      post: post,
                      onCommentTap: () => _showComments(context, post),
                    );
                  },
                  childCount: snapshot.data!.docs.length,
                                            ),
                                          );
                                        },
                                      ),
          // Espacio extra
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: _canCreatePosts
          ? FloatingActionButton.extended(
              onPressed: () async {
                final picker = ImagePicker();
                final images = await picker.pickMultiImage();
                if (images.isNotEmpty && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatePostScreen(
                        initialImages: images,
                        entityId: widget.group.id,
                        entityType: PostEntityType.group,
                      ),
                    ),
                  );
                }
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: Text(AppLocalizations.of(context)!.newPost),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
        currentIndex: 0,
          onTap: (index) {
            if (index == 0) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(group: widget.group),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppLocalizations.of(context)!.start,
            ),
            BottomNavigationBarItem(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .where('isRead', isEqualTo: false)
                    .where('entityType', isEqualTo: 'group_chat')
                    .snapshots(),
                builder: (context, snapshot) {
                  int chatCount = 0;
                  if (snapshot.hasData) {
                    chatCount = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['groupId'] == widget.group.id || 
                        data['entityId'] == widget.group.id;
                    }).length;
                  }
                  if (chatCount > 0) {
                    return Badge(
                      label: Text('$chatCount'),
                    child: const Icon(Icons.chat_bubble_outline),
                  );
                }
                return const Icon(Icons.chat_bubble_outline);
              },
            ),
              label: AppLocalizations.of(context)!.chat,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
      ),
    );
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class GroupPostCard extends StatefulWidget {
  final GroupPost post;
  final VoidCallback onCommentTap;

  const GroupPostCard({
    super.key,
    required this.post,
    required this.onCommentTap,
  });

  @override
  State<GroupPostCard> createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<GroupPostCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  late final Future<List<String>> _taggedUserNamesFuture;

  Future<void> _handleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postRef =
        FirebaseFirestore.instance.collection('group_posts').doc(widget.post.id);
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    final isLiked = widget.post.likes.any((ref) => ref.id == userId);

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userRef])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userRef])
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _taggedUserNamesFuture = _fetchTaggedUserNames();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = widget.post.likes.any((ref) => ref.id == userId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[100]!),
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 1. Header
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: FutureBuilder<DocumentSnapshot>(
              future: widget.post.authorId.get(),
              builder: (context, snapshot) {
                String? photoUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  photoUrl = data['photoUrl'];
                }
                return CircleAvatar(
                  backgroundImage:
                      photoUrl != null && photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                  backgroundColor: Colors.grey[200],
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                );
              },
            ),
            title: FutureBuilder<DocumentSnapshot>(
              future: widget.post.authorId.get(),
              builder: (context, snapshot) {
                String name = 'Usuario';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['name'] ?? data['displayName'] ?? 'Usuario';
                }
                return Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold));
              },
            ),
            subtitle: Text(
              _formatDate(widget.post.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: widget.post.authorId.id == userId
                ? IconButton(
                    icon: const Icon(Icons.more_vert),
                        onPressed: () {
                      _showOptionsBottomSheet(context);
                    },
                  )
                : null,
          ),

          // 2. Carousel
          if (widget.post.imageUrls.isNotEmpty)
            GestureDetector(
              onDoubleTap: _handleLike,
              child: AspectRatio(
                aspectRatio: _getAspectRatio(widget.post.aspectRatio),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.post.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                          });
                        },
                  itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.post.imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) =>
                              const Center(child: Icon(Icons.error)),
                        );
                      },
                    ),
                    if (widget.post.imageUrls.length > 1)
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.post.imageUrls
                              .asMap()
                              .entries
                              .map((entry) {
                                      return Container(
                              width: 6.0,
                              height: 6.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 3.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                                ),
                              ),
                            ),
                            
          // 3. Acciones (Likes/Comentarios)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                InkWell(
                  onTap: _handleLike,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onCommentTap,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // 4. Descripción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                if (widget.post.likes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${widget.post.likes.length} Me gusta',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                if (widget.post.contentText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FutureBuilder<DocumentSnapshot>(
                      future: widget.post.authorId.get(),
                      builder: (context, snapshot) {
                        String name = '';
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          name =
                              data['name'] ?? data['displayName'] ?? 'Usuario';
                        }
                        return RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14),
                            children: [
                              if (name.isNotEmpty)
                                TextSpan(
                                  text: '$name ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              TextSpan(
                                text: widget.post.contentText,
                                style: const TextStyle(height: 1.4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (widget.post.commentCount > 0)
                  GestureDetector(
                    onTap: widget.onCommentTap,
                    child: Text(
                      'Ver los ${widget.post.commentCount} comentarios',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                if (widget.post.location != null &&
                    widget.post.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.post.location!,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                FutureBuilder<List<String>>(
                  future: _taggedUserNamesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final names = snapshot.data!;
                    final extra =
                        names.length > 3 ? ' +${names.length - 3}' : '';
                    final visibleNames = names.take(3).join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_outlined,
                              size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Con $visibleNames$extra',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
                ),
              ),
            ],
          ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
          children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(AppLocalizations.of(context)!.deletePost,
                style: const TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.deletePost),
                  content: Text(
                      AppLocalizations.of(context)!.deletePostConfirmation),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppLocalizations.of(context)!.cancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(AppLocalizations.of(context)!.delete,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  for (var url in widget.post.imageUrls) {
                    try {
                      await FirebaseStorage.instance.refFromURL(url).delete();
                    } catch (_) {}
                  }
                  await FirebaseFirestore.instance
                      .collection('group_posts')
                      .doc(widget.post.id)
                      .delete();
                } catch (e) {
                  // Error handling
                }
              }
            },
          ),
        ],
      ),
    );
  }

  double _getAspectRatio(String aspectRatioString) {
    if (aspectRatioString.contains('portrait')) return 4 / 5;
    if (aspectRatioString.contains('landscape')) return 16 / 9;
    return 1.0;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return DateFormat('d MMM').format(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return 'Ahora';
  }

  Future<List<String>> _fetchTaggedUserNames() async {
    if (widget.post.taggedUsers.isEmpty) return [];
    final List<String> names = [];
    for (final ref in widget.post.taggedUsers) {
      try {
        final snap = await ref.get();
        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          final name = data['name'] ?? data['displayName'];
          if (name != null && name.toString().isNotEmpty) {
            names.add(name.toString());
          }
        }
      } catch (_) {}
    }
    return names;
  }
}
