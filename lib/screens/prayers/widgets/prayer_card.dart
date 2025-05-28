import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/prayer.dart';
import '../modals/prayer_comment_modal.dart';
import '../modals/assign_cult_modal.dart';
import '../../../services/prayer_service.dart';
import '../../../services/permission_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/rendering.dart';

class PrayerCard extends StatefulWidget {
  final Prayer prayer;

  const PrayerCard({
    super.key,
    required this.prayer,
  });

  @override
  State<PrayerCard> createState() => _PrayerCardState();
}

class _PrayerCardState extends State<PrayerCard> {
  final PrayerService _prayerService = PrayerService();
  final PermissionService _permissionService = PermissionService();
  bool _hasAssignPermission = false;
  bool _isLoading = false;
  
  // Estado local para UI optimista de votos
  late int _currentScore;
  late bool _currentUserHasUpvoted;
  late bool _currentUserHasDownvoted;
  
  // Estado local para datos del autor (optimización)
  Map<String, dynamic>? _authorData;
  bool _isLoadingAuthor = true;
  
  @override
  void initState() {
    super.initState();
    _initializeState();
    _checkPermissions();
    _fetchAuthorData(); // Cargar datos del autor una vez
  }
  
  void _initializeState() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    
    _currentScore = widget.prayer.score; // Usar score precalculado
    _currentUserHasUpvoted = userId != null && widget.prayer.upVotedBy.any((ref) => ref.id == userId);
    _currentUserHasDownvoted = userId != null && widget.prayer.downVotedBy.any((ref) => ref.id == userId);
  }
  
  // Cargar datos del autor para optimizar build
  Future<void> _fetchAuthorData() async {
    if (widget.prayer.isAnonymous) {
       setState(() => _isLoadingAuthor = false);
       return; // No cargar datos si es anónimo
    }
    try {
      final authorSnapshot = await widget.prayer.createdBy.get();
      if (mounted && authorSnapshot.exists) {
        setState(() {
          _authorData = authorSnapshot.data() as Map<String, dynamic>?;
          _isLoadingAuthor = false;
        });
      }
    } catch (e) {
      print('Error cargando dados do autor: $e');
      if (mounted) {
        setState(() => _isLoadingAuthor = false); // Marcar como no cargando incluso si hay error
      }
    }
  }
  
  // Método para verificar si el usuario tiene el permiso de asignar oraciones a cultos
  Future<void> _checkPermissions() async {
    final hasPermission = await _permissionService.hasPermission('assign_cult_to_prayer');
    if (mounted) {
      setState(() {
        _hasAssignPermission = hasPermission;
      });
    }
  }
  
  Future<void> _showAssignCultModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: AssignCultModal(prayer: widget.prayer),
      ),
    );
    
    // Si se asignó correctamente, se podría actualizar el estado o mostrar un feedback
    if (result == true) {
      // La oración ya se actualizó, no es necesario hacer nada aquí
    }
  }
  
  Future<void> _unassignFromCult() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Mostrar diálogo de confirmación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desatribuir oração'),
          content: const Text('Tem certeza que deseja desatribuir esta oração do culto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desatribuir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final success = await _prayerService.unassignPrayerFromCult(
        prayerId: widget.prayer.id,
        pastorId: currentUser.uid,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oração desatribuída corretamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao desatribuir a oração')),
          );
        }
      }
    } catch (e) {
      print('Erro ao desatribuir oração: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser != null && widget.prayer.createdBy.id == currentUser.uid;
    final canAssignCultToPrayer = _hasAssignPermission;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5, // Reducir un poco la elevación
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la tarjeta
            Row(
              children: [
                // Foto del creador (usando estado local)
                if (!widget.prayer.isAnonymous) ...[
                  _buildAuthorAvatar(),
                  const SizedBox(width: 12),
                ],
                
                // Nombre del creador (usando estado local)
                Flexible(
                  child: _buildAuthorName(),
                ),
                
                // Indicador de oración asignada a culto (sin cambios)
                if (widget.prayer.isAssignedToCult)
                  _buildStatusChip(Icons.church, 'Atribuída', Colors.blue),
                
                // Indicador de oración aceptada (sin cambios)
                // if (widget.prayer.isAccepted)
                //   _buildStatusChip(Icons.check_circle_outline, 'Aceptada', Colors.green),
                
                // Menú de opciones (se pasa canAssignCultToPrayer en lugar de _hasAssignPermission)
                if (isCreator || canAssignCultToPrayer)
                  _buildOptionsMenu(isCreator, canAssignCultToPrayer),
              ],
            ),
            
            // Tiempo transcurrido desde la creación (sin cambios)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                timeago.format(widget.prayer.createdAt, locale: 'pt_BR'),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            
            // Información del culto asignado (si existe - sin cambios)
            if (widget.prayer.isAssignedToCult && widget.prayer.cultName != null)
               _buildAssignedCultInfo(),
            
            // Contenido de la oración (sin cambios)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.prayer.content,
                style: const TextStyle(
                  fontSize: 15, // Ligeramente más pequeño
                  height: 1.4,
                  color: Color(0xFF424242), // Un gris oscuro
                ),
              ),
            ),
            
            // Fila de acciones (votos y comentarios)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botones de voto (usando estado local)
                // if (!widget.prayer.isAccepted) // Si se quiere ocultar cuando está aceptada
                  Row(
                    children: [
                      _buildVoteButton(
                        icon: Icons.arrow_upward_rounded,
                        iconColor: _currentUserHasUpvoted ? Colors.blue[700]! : Colors.grey,
                        onPressed: () => _handleVote(currentUser, true),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          _currentScore.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentScore > 0 
                                ? Colors.blue[700] 
                                : (_currentScore < 0 ? Colors.red[700] : Colors.grey[600]),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _buildVoteButton(
                        icon: Icons.arrow_downward_rounded,
                        iconColor: _currentUserHasDownvoted ? Colors.red[700]! : Colors.grey,
                        onPressed: () => _handleVote(currentUser, false),
                      ),
                    ],
                  ),
                
                // Botón de comentarios rediseñado
                 _buildCommentButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets auxiliares para build --- 

  Widget _buildAuthorAvatar() {
    if (_isLoadingAuthor) {
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFFEEEEEE),
      );
    }
    String? photoUrl = _authorData?['photoUrl'] as String?;
    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
          ? NetworkImage(photoUrl)
          : null,
      child: photoUrl == null || photoUrl.isEmpty
          ? Icon(Icons.person_outline, color: Theme.of(context).primaryColor, size: 20)
          : null,
    );
  }

  Widget _buildAuthorName() {
    if (widget.prayer.isAnonymous) {
      return const Text(
        'Anônimo',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF616161)),
      );
    }
    if (_isLoadingAuthor) {
       return Container( // Placeholder para el nombre
         width: 80,
         height: 14,
         decoration: BoxDecoration(
           color: Color(0xFFEEEEEE),
           borderRadius: BorderRadius.circular(4),
         ),
       );
    }
    final username = _authorData?['displayName'] ?? _authorData?['name'] ?? 'Usuário';
    return Text(
      username,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    final textColor = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness * 0.7).clamp(0.0, 1.0)).toColor(); // Darker shade
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu(bool isCreator, bool canAssignCultToPrayer) {
    // Lógica del PopupMenuButton modificada para usar canAssignCultToPrayer
    return PopupMenuButton<String>(
       icon: const Icon(Icons.more_vert, color: Colors.grey),
       padding: EdgeInsets.zero, // Reducir padding si es necesario
       tooltip: 'Opções',
       onSelected: (value) async {
         if (value == 'delete') {
           // Mostrar confirmación antes de eliminar
           final confirmed = await showDialog<bool>(
             context: context,
             builder: (context) => AlertDialog(
               title: const Text('Excluir Oração'),
               content: const Text('Tem certeza que deseja excluir esta oração? Esta ação não pode ser desfeita.'),
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

           if (confirmed && mounted) {
             try {
               await FirebaseFirestore.instance
                   .collection('prayers')
                   .doc(widget.prayer.id)
                   .delete();
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Oração excluída com sucesso')),
                   );
                 }
             } catch (e) {
                if (mounted) { 
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text('Erro ao excluir oração: $e')),
                 );
               }
             }
           }
         } else if (value == 'assign_cult' && canAssignCultToPrayer) {
           _showAssignCultModal();
         } else if (value == 'unassign_cult' && canAssignCultToPrayer) {
           _unassignFromCult();
         }
       },
       itemBuilder: (context) {
          // No es necesario recalcular isCreator aquí si ya se pasó como argumento
          // final currentUser = FirebaseAuth.instance.currentUser;
          // final isCreator = currentUser != null && widget.prayer.createdBy.id == currentUser.uid;

         return [
            // Opción de Eliminar (visible para pastor O creador)
            if (canAssignCultToPrayer || isCreator)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              
            // Separador visual si hay opciones de asignación Y opción de eliminar
            if ((canAssignCultToPrayer || isCreator) && canAssignCultToPrayer) 
               const PopupMenuDivider(height: 1), 

            // Opciones de asignación/desasignación (para usuarios con permiso o pastores)
            if (canAssignCultToPrayer && !widget.prayer.isAssignedToCult)
              const PopupMenuItem(
                value: 'assign_cult',
                child: Row(
                  children: [
                    Icon(Icons.church_outlined, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Atribuir ao culto', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            if (canAssignCultToPrayer && widget.prayer.isAssignedToCult)
              const PopupMenuItem(
                value: 'unassign_cult',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Desatribuir do culto', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
          ];
       },
     );
  }

   Widget _buildAssignedCultInfo() {
      return Container(
         margin: const EdgeInsets.only(bottom: 12),
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         decoration: BoxDecoration(
           color: Colors.blue[50],
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.blue[100]!),
         ),
         child: Row(
           children: [
             Icon(Icons.church_outlined, size: 18, color: Colors.blue[700]),
             const SizedBox(width: 8),
             Expanded(
               child: Text(
                 'Atribuída ao culto: ${widget.prayer.cultName}',
                 style: TextStyle(
                   fontSize: 13,
                   color: Colors.blue[800],
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ),
           ],
         ),
       );
   }

  Widget _buildCommentButton() {
    return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('prayer_comments')
                      .where('prayerId', isEqualTo: FirebaseFirestore.instance.collection('prayers').doc(widget.prayer.id))
                      .snapshots(),
                  builder: (context, snapshot) {
                    final commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    
        return TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => PrayerCommentModal(
                                  prayer: widget.prayer,
                                  currentUserIsPastor: false,
                          ),
                        );
                      },
          icon: Icon(Icons.mode_comment_outlined, size: 18, color: Colors.grey[700]),
                      label: Text(
            commentCount > 0 ? commentCount.toString() : '', // Mostrar solo el número o nada
            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700], 
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 36), // Altura mínima
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.grey[100], // Un fondo sutil
                      ),
                    );
                  },
    );
  }
  
  // Método para manejar los votos con UI OPTIMISTA
  Future<void> _handleVote(User? currentUser, bool isUpvote) async {
    if (currentUser == null) { // Añadir verificación de login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve fazer login para votar')),
      );
      return;
    }
    
    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    final prayerRef = FirebaseFirestore.instance.collection('prayers').doc(widget.prayer.id);
        
    // Capturar estado actual ANTES de la actualización optimista
    final initialScore = _currentScore;
    final initialHasUpvoted = _currentUserHasUpvoted;
    final initialHasDownvoted = _currentUserHasDownvoted;
    
    // Calcular nuevo estado local
      int scoreChange = 0;
    bool newHasUpvoted = initialHasUpvoted;
    bool newHasDownvoted = initialHasDownvoted;
      
      if (isUpvote) {
      if (initialHasUpvoted) { // Quitar upvote
          scoreChange = -1;
        newHasUpvoted = false;
      } else { // Añadir upvote
          scoreChange = 1;
        newHasUpvoted = true;
        if (initialHasDownvoted) { // Quitar downvote si existía
          scoreChange += 1;
          newHasDownvoted = false;
        }
      }
    } else { // isDownvote
      if (initialHasDownvoted) { // Quitar downvote
          scoreChange = 1;
        newHasDownvoted = false;
      } else { // Añadir downvote
          scoreChange = -1;
        newHasDownvoted = true;
        if (initialHasUpvoted) { // Quitar upvote si existía
          scoreChange -= 1;
          newHasUpvoted = false;
        }
      }
    }
    
    // --- Actualización Optimista INMEDIATA ---
    setState(() {
      _currentScore = initialScore + scoreChange;
      _currentUserHasUpvoted = newHasUpvoted;
      _currentUserHasDownvoted = newHasDownvoted;
    });
    
    // --- Ejecutar transacción en Firestore en segundo plano ---
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot prayerSnapshot = await transaction.get(prayerRef);
        if (!prayerSnapshot.exists) {
          throw Exception('A oração não existe mais.');
        }
        
        // Recalcular cambios basados en dados reais de Firestore para a transação
        final prayerData = prayerSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> upVotedByList = List.from(prayerData['upVotedBy'] ?? []);
        final List<dynamic> downVotedByList = List.from(prayerData['downVotedBy'] ?? []);
        int actualScoreChange = 0;
        Map<String, dynamic> updates = {};
        
        bool currentlyHasUpvoted = upVotedByList.any((ref) => ref.id == currentUser.uid);
        bool currentlyHasDownvoted = downVotedByList.any((ref) => ref.id == currentUser.uid);

        if (isUpvote) {
          if (currentlyHasUpvoted) { // Quitar upvote
            updates['upVotedBy'] = FieldValue.arrayRemove([userRef]);
            actualScoreChange = -1;
          } else { // Añadir upvote
            updates['upVotedBy'] = FieldValue.arrayUnion([userRef]);
            actualScoreChange = 1;
            if (currentlyHasDownvoted) { // Quitar downvote si existía
              updates['downVotedBy'] = FieldValue.arrayRemove([userRef]);
              actualScoreChange += 1;
            }
          }
        } else { // isDownvote
          if (currentlyHasDownvoted) { // Quitar downvote
            updates['downVotedBy'] = FieldValue.arrayRemove([userRef]);
            actualScoreChange = 1;
          } else { // Añadir downvote
            updates['downVotedBy'] = FieldValue.arrayUnion([userRef]);
            actualScoreChange = -1;
            if (currentlyHasUpvoted) { // Quitar upvote si existía
              updates['upVotedBy'] = FieldValue.arrayRemove([userRef]);
              actualScoreChange -= 1;
            }
          }
        }
        
        // Actualizar score (opcionalmente también totalVotes si lo usas)
        int actualCurrentScore = prayerData['score'] ?? (upVotedByList.length - downVotedByList.length);
        updates['score'] = actualCurrentScore + actualScoreChange;
        
      transaction.update(prayerRef, updates);
    });
    } catch (e) {
      // --- Revertir estado local si Firestore falla ---
      if (mounted) {
         setState(() {
           _currentScore = initialScore;
           _currentUserHasUpvoted = initialHasUpvoted;
           _currentUserHasDownvoted = initialHasDownvoted;
         });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar o voto: $e')),
        );
      }
    }
  }
  
  // Widget para el botón de voto (sin cambios)
  Widget _buildVoteButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: iconColor),
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      iconSize: 20,
      splashRadius: 24,
    );
  }
} 