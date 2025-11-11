import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/group.dart';
import '../../models/group_post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group_event.dart';
import 'group_event_detail_screen.dart';
import '../../widgets/create_group_post_bottom_sheet.dart';
import 'dart:io';
import 'dart:async'; // Para Completer
import '../../modals/group_comments_modal.dart';
import '../../modals/create_group_event_modal.dart';
import 'group_chat_screen.dart';
import '../profile_screen.dart';
import 'group_details_screen.dart';
import 'manage_group_requests_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin/event_attendance_screen.dart';
import '../admin/admin_events_list_screen.dart';
import '../../theme/app_colors.dart';
import '../../services/permission_service.dart'; // Importar servicio de permisos
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
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  File? imageFile;
  final PermissionService _permissionService = PermissionService(); // Instancia del servicio
  bool _canCreateEvents = false;
  bool _canManageRequests = false;
  bool _canCreatePosts = false;

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
    // Verificar permisos al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar permisos del usuario
      _loadPermissions();
      
      // Log para depuración
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      debugPrint('🚀 GROUP_FEED - Inicializando pantalla para usuario: $userId');
      final isAdmin = widget.group.isAdmin(userId);
      debugPrint('👑 GROUP_FEED - Usuario es admin del grupo: $isAdmin');
    });
  }

  // Método para cargar permisos
  Future<void> _loadPermissions() async {
    // Ya que estos permisos se eliminaron, establecemos todos como true
    // para que las funcionalidades estén disponibles para todos
    if (mounted) {
      setState(() {
        _canCreateEvents = true;
        _canManageRequests = true;
        _canCreatePosts = true;
        
        debugPrint('🔒 GROUP_FEED - Permisos establecidos como disponibles para todos los usuarios');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si el usuario actual es admin (solo para logging)
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = widget.group.isAdmin(userId);
    
    // Solo usar permisos directamente, sin combinar con isAdmin
    debugPrint('🛡️ GROUP_FEED - Permisos: canCreatePosts=$_canCreatePosts, canCreateEvents=$_canCreateEvents, canManageRequests=$_canManageRequests');
    debugPrint('👑 GROUP_FEED - Admin status (solo informativo): $isAdmin');
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 70, // Aumentar altura de la barra
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
              // Imagen circular del grupo - aumentar tamaño
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: widget.group.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.group.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.group.imageUrl.isEmpty
                    ? const Icon(Icons.group, color: Colors.grey, size: 28)
                    : null,
              ),
              // Nombre del grupo con textos más grandes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Grupo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Mostrar botón de crear evento solo si tiene permiso
          if (_canCreateEvents) 
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
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
            ),
          // Mostrar botón de gestionar solicitudes solo si tiene permiso
          if (_canManageRequests) 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('membership_requests')
                  .where('entityId', isEqualTo: widget.group.id)
                  .where('entityType', isEqualTo: 'group')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                
                return Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.people, color: Colors.white),
                    tooltip: AppLocalizations.of(context)!.manageRequests,
                    onPressed: _navigateToManageRequests,
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Eventos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildEventsSection(),
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
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Ícono o ilustración
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.groups_outlined,
                            size: 60,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Mensaje principal
                        Text(
                          AppLocalizations.of(context)!.shareWithGroup,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Mensaje secundario
                        Text(
                          AppLocalizations.of(context)!.groupNoPostsYet,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Botón CTA (solo visible para admins)
                        if (_canCreatePosts) 
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(AppLocalizations.of(context)!.createPost),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                      ],
                    ),
                  ),
                );
              }

              final posts = snapshot.data!.docs
                  .map((doc) => GroupPost.fromFirestore(doc))
                  .toList();

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
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(post.authorId.id)
                          .get(),
                      builder: (context, userSnapshot) {
                        String userName = 'Usuario';
                        String userPhotoUrl = '';
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          userName = userData['name'] ?? userData['displayName'] ?? 'Usuario';
                          userPhotoUrl = userData['photoUrl'] ?? '';
                        }
                        
                        // Estilo Instagram para posts
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                          elevation: 0,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabecera del post (usuario, foto, opciones)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // Avatar del usuario
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: userPhotoUrl.isNotEmpty 
                                          ? NetworkImage(userPhotoUrl) 
                                          : null,
                                      child: userPhotoUrl.isEmpty
                                          ? const Icon(Icons.person, size: 20, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    // Nombre de usuario
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Menú de opciones (solo visible para el autor)
                                    if (post.authorId.id == FirebaseAuth.instance.currentUser?.uid)
                                      IconButton(
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) => Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(Icons.delete, color: Colors.red),
                                                  title: const Text('Eliminar post', 
                                                      style: TextStyle(color: Colors.red)),
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    // Mostrar diálogo de confirmación
                                                    final shouldDelete = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Exlcuir post'),
                                                        content: const Text('Tem certeza que deseja excluir esta publicação?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context, false),
                                                            child: const Text('Cancelar'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context, true),
                                                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ?? false;
                                                    
                                                    if (shouldDelete) {
                                                      try {
                                                        // Eliminar imágenes si existen
                                                        for (final imageUrl in post.imageUrls) {
                                                          try {
                                                            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
                                                            await ref.delete();
                                                          } catch (e) {
                                                            // Ignorar errores al eliminar imágenes
                                                            print('Error al eliminar imagen: $e');
                                                          }
                                                        }
                                                        
                                                        // Eliminar el post
                                                        await FirebaseFirestore.instance
                                                            .collection('group_posts')
                                                            .doc(post.id)
                                                            .delete();
                                                        
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Publicación eliminada correctamente')),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Error al eliminar: $e')),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Imagen del post (si existe)
                              if (post.imageUrls.isNotEmpty)
                                _buildPostImage(post.imageUrls.first, post.aspectRatio),
                              
                              // Acciones (like, comentar)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        post.likes.contains(FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth.instance.currentUser?.uid))
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: post.likes.contains(FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth.instance.currentUser?.uid))
                                            ? Colors.red
                                            : null,
                                      ),
                                      onPressed: () => _handleLike(post),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chat_bubble_outline),
                                          onPressed: () => _showComments(context, post),
                                        ),
                                        if (post.commentCount > 0)
                                          Text(
                                            '${post.commentCount}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Contador de likes
                              if (post.likes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                                  child: Text(
                                    '${post.likes.length} ${post.likes.length == 1 ? 'like' : 'likes'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                
                              // Contenido de la publicación (nombre + texto)
                              if (post.contentText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: ExpandableText(
                                    userName: userName,
                                    text: post.contentText,
                                  ),
                                ),
                                
                              // Fecha
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 8),
                                child: Text(
                                  _formatDate(post.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              
                              // Divisor
                              const Divider(height: 1),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          currentIndex: 0, // Mantener inicio seleccionado
          onTap: (index) {
            // Navegar en función del índice seleccionado
            if (index == 0) {
              // Inicio - Volver a la pantalla principal
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            } else if (index == 1) {
              // Chats - Ir a la pantalla de chat del grupo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(group: widget.group),
                ),
              );
            } else if (index == 2) {
              // Para usuarios con permisos: mostrar diálogo de creación
              // Para usuarios sin permisos: ir a detalles del grupo
              if (_canCreatePosts) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => CreateGroupPostBottomSheet(
                    groupId: widget.group.id,
                  ),
                );
              } else {
                // Navegar a la pantalla de detalles del grupo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailsScreen(
                      group: widget.group,
                    ),
                  ),
                );
              }
            } else if (index == 3) {
              // Perfil - Ir a la pantalla de perfil
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
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: AppLocalizations.of(context)!.chat,
            ),
            BottomNavigationBarItem(
              icon: _canCreatePosts 
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  )
                : const Icon(Icons.info_outline),
              label: _canCreatePosts ? AppLocalizations.of(context)!.newItem : AppLocalizations.of(context)!.info,
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
      ),
    );
  }
  
  // Construir imagen del post con diferentes relaciones de aspecto
  Widget _buildPostImage(String imageUrl, String aspectRatio) {
    double aspectRatioValue = 1.0; // Default square ratio
    
    // Determinar la relación de aspecto basada en el valor almacenado
    if (aspectRatio.contains('portrait')) {
      aspectRatioValue = 9.0 / 16.0; // Portrait (9:16)
    } else if (aspectRatio.contains('landscape')) {
      aspectRatioValue = 16.0 / 9.0; // Landscape (16:9)
    }
    
    return AspectRatio(
      aspectRatio: aspectRatioValue,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain, // Cambiado de 'cover' a 'contain' para evitar distorsión
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error),
        ),
        // Removidos los límites de caché para permitir mejor calidad
        fadeInDuration: const Duration(milliseconds: 200),
      ),
    );
  }
  
  // Formatear fecha en formato relativo
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return DateFormat('d MMM yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  Widget _buildEventsSection() {
    final now = DateTime.now();
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('group_events')
          .where('groupId', isEqualTo: FirebaseFirestore.instance.collection('groups').doc(widget.group.id))
          .orderBy('date')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        // Si está cargando, no mostramos nada
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        // Si no hay datos o no hay eventos, no mostramos nada
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Filtrar eventos para obtener solo los que son futuros
        final events = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
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
        
        // Tenemos eventos, ahora mostramos la sección
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
                      "Próximos eventos",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (_canCreateEvents) 
                      IconButton(
                        icon: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.green,
                        ),
                        tooltip: 'Administrar eventos',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminEventsListScreen(
                                initialFilterType: 'group',
                              ),
                            ),
                          ).then((value) {
                            // Al volver, actualizar la lista de eventos
                            setState(() {});
                          });
                        },
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 130, // Altura para tarjetas 16:9
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final doc = events[index]!;
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final title = data['title'] ?? 'Sin título';
                    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final imageUrl = data['imageUrl'] ?? '';
                    final description = data['description'] ?? '';
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupEventDetailScreen( 
                              event: GroupEvent.fromFirestore(doc),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 200,
                        height: 113, // Proporción 16:9 (200 / 16 * 9 = 112.5)
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Imagen de fondo
                            Positioned.fill(
                              child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.event, size: 50, color: Colors.grey),
                                  ),
                            ),
                            
                            // Gradiente superpuesto para mejorar la legibilidad
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Insignia de grupo
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group, color: Colors.white, size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      'Grupo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Fecha
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(date),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Contenido (Título y detalles)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    
                                    // Hora del evento
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
  
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para verificar si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

class ExpandableText extends StatefulWidget {
  final String userName;
  final String text;

  const ExpandableText({
    Key? key,
    required this.userName,
    required this.text,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.userName} ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: widget.text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 60 && !_expanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = true;
              });
            },
            child: Text(
              'ver más',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}