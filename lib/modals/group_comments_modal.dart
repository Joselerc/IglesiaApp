import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_post.dart';

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
      
      // Actualizar el contador de comentarios en el post
      await FirebaseFirestore.instance
          .collection('group_posts')
          .doc(widget.post.id)
          .update({
        'commentCount': FieldValue.increment(1),
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao publicar comentário: $e')),
      );
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
      // Verificar si el usuario actual es el autor del comentario
      final authorId = (comment.data() as Map<String, dynamic>)['authorId'] as DocumentReference;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (authorId.id != currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você só pode excluir seus próprios comentários')),
        );
        return;
      }
      
      // Mostrar diálogo de confirmación
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir comentário'),
          content: const Text('Tem certeza de que deseja excluir este comentário?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldDelete) return;
      
      // Eliminar el comentario
      await FirebaseFirestore.instance
          .collection('group_posts_comments')
          .doc(comment.id)
          .delete();
          
      // Actualizar el contador de comentarios en el post
      await FirebaseFirestore.instance
          .collection('group_posts')
          .doc(widget.post.id)
          .update({
        'commentCount': FieldValue.increment(-1),
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comentário excluído')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir comentário: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el padding seguro para la parte inferior
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('group_posts_comments')
                      .where('groupPostId', isEqualTo: widget.post.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      'Comentários ($count)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Lista de comentarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('group_posts_comments')
                  .where('groupPostId', isEqualTo: widget.post.id)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                }

                final comments = snapshot.data?.docs ?? [];
                
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Não há comentários ainda',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a comentar!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
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
                          // Avatar del autor
                          FutureBuilder<DocumentSnapshot>(
                            future: userRef?.get(),
                            builder: (context, userSnapshot) {
                              String? photoUrl;
                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                photoUrl = userData?['photoUrl'] as String?;
                              }
                              
                              return CircleAvatar(
                                radius: 16,
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                child: photoUrl == null ? const Icon(Icons.person, size: 16) : null,
                              );
                            },
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Contenido del comentario
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Autor y tiempo
                                Row(
                                  children: [
                                    FutureBuilder<DocumentSnapshot>(
                                      future: userRef?.get(),
                                      builder: (context, userSnapshot) {
                                        String username = 'Usuário';
                                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                          username = userData?['name'] as String? ?? 'Usuário';
                                        }
                                        
                                        return Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    if (timestamp != null)
                                      Text(
                                        _getTimeAgo(timestamp),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Texto del comentario
                                Text(
                                  comment['content'] as String? ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          
                          // Botón de eliminar (solo visible para el autor)
                          if (isAuthor)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteComment(commentDoc),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Campo para añadir comentario
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16, 
              top: 8,
              bottom: 8 + bottomPadding, // Añadir el padding seguro
            ),
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
              children: [
                // Avatar del usuario actual
                CircleAvatar(
                  radius: 16,
                  backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                      ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                      : null,
                  child: FirebaseAuth.instance.currentUser?.photoURL == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Campo de texto
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Adicionar um comentário...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Botón de enviar
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: Theme.of(context).primaryColor),
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