import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/prayer.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../services/permission_service.dart';
import '../../../l10n/app_localizations.dart';

class PrayerCommentModal extends StatefulWidget {
  final Prayer prayer;
  final bool currentUserIsPastor; // Mantenemos por compatibilidad pero no lo usaremos

  const PrayerCommentModal({
    super.key, 
    required this.prayer,
    required this.currentUserIsPastor,
  });

  @override
  State<PrayerCommentModal> createState() => _PrayerCommentModalState();
}

class _PrayerCommentModalState extends State<PrayerCommentModal> {
  final _commentController = TextEditingController();
  final _permissionService = PermissionService(); // Servicio de permisos
  bool _isSubmitting = false;
  bool _hasAssignPermission = false; // Permiso para asignar oraciones a cultos
  
  // Referencia a la colección de comentarios
  late final CollectionReference _commentsCollection;
  late final DocumentReference _prayerRef;
  
  // Estado para la ordenación
  String _sortByField = 'createdAt'; // 'createdAt', 'likes'
  bool _sortDescending = true;    // true para descendente, false para ascendente

  @override
  void initState() {
    super.initState();
    _prayerRef = FirebaseFirestore.instance.collection('prayers').doc(widget.prayer.id);
    _commentsCollection = FirebaseFirestore.instance.collection('prayer_comments');
    
    // Verificar permisos al iniciar
    _checkPermissions();
  }

  // Verificar si el usuario tiene permiso para gestionar oraciones
  Future<void> _checkPermissions() async {
    final hasPermission = await _permissionService.hasPermission('assign_cult_to_prayer');
    if (mounted) {
      setState(() {
        _hasAssignPermission = hasPermission;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Función para obtener tiempo relativo
  String _getTimeAgo(Timestamp timestamp) {
    return timeago.format(timestamp.toDate(), locale: Localizations.localeOf(context).toString());
  }

  // Enviar comentario
  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (comment.isEmpty || currentUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _commentsCollection.add({
        'content': comment,
        'authorId': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'prayerId': _prayerRef,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _commentController.clear();
      // Considerar actualizar contador en prayer si es necesario (más complejo)
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorPublishingComment(e.toString()))),
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
  
  // Eliminar comentario
  Future<void> _deleteComment(DocumentSnapshot commentDoc) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final authorRef = commentDoc['authorId'] as DocumentReference?;
    final isAuthor = authorRef?.id == currentUser?.uid;

    // Permitir eliminar si el usuario es autor O tiene el permiso assign_cult_to_prayer
    if (currentUser == null || (!isAuthor && !_hasAssignPermission)) {
       if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.youDontHavePermissionToDeleteComment)),
         );
       }
      return;
    }

    // Confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteComment),
        content: Text(AppLocalizations.of(context)!.sureYouWantToDeleteComment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    try {
      await _commentsCollection.doc(commentDoc.id).delete();
      // Considerar actualizar contador en prayer si es necesario
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.commentDeleted)),
         );
       }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorDeletingComment(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Paddings del sistema
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Envolver el Container principal con ConstrainedBox para limitar la altura máxima
    return ConstrainedBox(
      constraints: BoxConstraints(
         // Limitar altura máxima al 85% de la pantalla, por ejemplo
        maxHeight: screenHeight * 0.85, 
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.only(top: 16), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 0), // Ajustar padding derecho para botón extra
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _commentsCollection
                        .where('prayerId', isEqualTo: _prayerRef)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text(
                        AppLocalizations.of(context)!.commentsCount(count),
                        style: AppTextStyles.headline3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      );
                    },
                  ),
                  const Spacer(), // Añadir Spacer para empujar botones a la derecha
                  // --- Botón de Ordenar --- 
                  _buildSortButton(), 
                  // --- Botón de Cerrar --- 
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 16, thickness: 1), // Reducir altura Divider
            
            Flexible(
              child: StreamBuilder<QuerySnapshot>(
                stream: _commentsCollection
                    .where('prayerId', isEqualTo: _prayerRef)
                    // Ordenar siempre por fecha en Firestore para la carga inicial y paginación futura
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  var comments = snapshot.data?.docs ?? [];
                  
                  // --- Aplicar Ordenación Client-Side --- 
                  if (comments.isNotEmpty) {
                    comments.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      int comparison = 0;

                      if (_sortByField == 'likes') {
                        final likesA = (dataA['likes'] as List?)?.length ?? 0;
                        final likesB = (dataB['likes'] as List?)?.length ?? 0;
                        comparison = likesA.compareTo(likesB);
                      } else { // 'createdAt'
                        final dateA = (dataA['createdAt'] as Timestamp?) ?? Timestamp.now();
                        final dateB = (dataB['createdAt'] as Timestamp?) ?? Timestamp.now();
                        comparison = dateA.compareTo(dateB);
                      }

                      return _sortDescending ? -comparison : comparison;
                    });
                  }
                  // ----------------------------------------
                  
                  if (comments.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      // Pasar el comment Doc ya ordenado
                      return _buildCommentItem(comments[index]);
                    },
                  );
                },
              ),
            ),
            
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset + bottomPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCurrentUserAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addComment,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _isSubmitting ? null : _submitComment,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot commentDoc) {
    final data = commentDoc.data() as Map<String, dynamic>;
    final authorRef = data['authorId'] as DocumentReference?;
    final timestamp = data['createdAt'] as Timestamp?;
    final likes = List<DocumentReference>.from(data['likes'] ?? []);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = authorRef?.id == currentUser?.uid;
    final hasLiked = currentUser != null && likes.any((ref) => ref.id == currentUser.uid);
    final likeCount = likes.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: authorRef?.get(),
          builder: (context, userSnapshot) {
            String? photoUrl;
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              photoUrl = userData?['photoUrl'] as String?;
            }
            return CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person_outline, size: 16, color: Colors.grey) : null,
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Flexible(
                     child: FutureBuilder<DocumentSnapshot>(
                        future: authorRef?.get(),
                        builder: (context, userSnapshot) {
                          String username = 'Usuário';
                          if (userSnapshot.hasData && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                            username = userData?['displayName'] ?? userData?['name'] ?? 'Usuário';
                          }
                          return Text(
                             username,
                             style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
                             overflow: TextOverflow.ellipsis,
                           );
                        },
                      ), 
                   ),
                  if (timestamp != null)
                    Padding(
                       padding: const EdgeInsets.only(left: 8.0),
                       child: Text(
                        _getTimeAgo(timestamp),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                       ), 
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(data['content'] as String? ?? '', style: Theme.of(context).textTheme.bodyMedium),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        hasLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: hasLiked ? AppColors.primary : Colors.grey[600],
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(right: 4),
                      iconSize: 16,
                      splashRadius: 20,
                      onPressed: () => _handleLikeComment(commentDoc, hasLiked),
                    ),
                    Text(
                      likeCount.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isAuthor || _hasAssignPermission)
          IconButton(
             icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
             padding: const EdgeInsets.only(left: 8, top: 0, bottom: 0, right: 0),
             constraints: const BoxConstraints(),
             onPressed: () => _deleteComment(commentDoc),
             tooltip: 'Excluir',
           ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noCommentsYet,
              style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.beTheFirstToComment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentUserAvatar() {
      final currentUser = FirebaseAuth.instance.currentUser;
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[200],
        backgroundImage: currentUser?.photoURL != null
            ? NetworkImage(currentUser!.photoURL!)
            : null,
        child: currentUser?.photoURL == null
            ? Icon(Icons.person_outline, size: 16, color: Colors.grey[600])
            : null,
      );
    }

  Future<void> _handleLikeComment(DocumentSnapshot commentDoc, bool currentlyLiked) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.youNeedToBeLoggedInToLike)),
        );
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final commentRef = _commentsCollection.doc(commentDoc.id);

      try {
         if (currentlyLiked) {
           await commentRef.update({
             'likes': FieldValue.arrayRemove([userRef])
           });
         } else {
           await commentRef.update({
             'likes': FieldValue.arrayUnion([userRef])
           });
         }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.errorProcessingLike(e.toString()))),
           );
         }
      }
  }

  // --- Widget para el Botón de Ordenar --- 
  Widget _buildSortButton() {
    IconData icon;
    String tooltip;

    if (_sortByField == 'likes') {
      icon = Icons.thumb_up_alt_outlined;
      tooltip = _sortDescending ? AppLocalizations.of(context)!.mostLikedFirst : AppLocalizations.of(context)!.leastLikedFirst;
    } else {
      icon = Icons.calendar_today_outlined;
      tooltip = _sortDescending ? AppLocalizations.of(context)!.mostRecentFirst : AppLocalizations.of(context)!.oldestFirst;
    }

    return PopupMenuButton<String>(
      icon: Icon(icon, color: AppColors.textSecondary, size: 22),
      tooltip: tooltip,
      onSelected: (value) {
        String newSortByField = _sortByField;
        bool newSortDescending = _sortDescending;

        switch (value) {
          case 'recent':
            newSortByField = 'createdAt';
            newSortDescending = true;
            break;
          case 'oldest':
            newSortByField = 'createdAt';
            newSortDescending = false;
            break;
          case 'most_liked':
            newSortByField = 'likes';
            newSortDescending = true;
            break;
          case 'least_liked':
            newSortByField = 'likes';
            newSortDescending = false;
            break;
        }

        if (_sortByField != newSortByField || _sortDescending != newSortDescending) {
          setState(() {
            _sortByField = newSortByField;
            _sortDescending = newSortDescending;
          });
        }
      },
      itemBuilder: (context) => [
        _buildSortMenuItem(AppLocalizations.of(context)!.mostRecentFirst, 'recent', _sortByField == 'createdAt' && _sortDescending),
        _buildSortMenuItem(AppLocalizations.of(context)!.oldestFirst, 'oldest', _sortByField == 'createdAt' && !_sortDescending),
        const PopupMenuDivider(),
        _buildSortMenuItem(AppLocalizations.of(context)!.mostLikedFirst, 'most_liked', _sortByField == 'likes' && _sortDescending),
        _buildSortMenuItem(AppLocalizations.of(context)!.leastLikedFirst, 'least_liked', _sortByField == 'likes' && !_sortDescending),
      ],
    );
  }

  // Helper para construir items del menú de ordenación
  PopupMenuItem<String> _buildSortMenuItem(String title, String value, bool isSelected) {
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: isSelected ? AppColors.primary : null)),
          if (isSelected) Icon(Icons.check, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
} 