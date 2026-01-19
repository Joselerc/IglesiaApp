import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ministry.dart';
import '../../services/auth_service.dart';
import '../../services/ministry_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'ministry_feed_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/ministry_card.dart';
import '../../modals/create_ministry_modal.dart';
import '../../services/permission_service.dart';
import '../../widgets/skeletons/list_tab_content_skeleton.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class MinistriesListScreen extends StatefulWidget {
  const MinistriesListScreen({super.key});

  @override
  State<MinistriesListScreen> createState() => _MinistriesListScreenState();
}

class _MinistriesListScreenState extends State<MinistriesListScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final MinistryService _ministryService = MinistryService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  final Set<String> _pendingInviteIds = {};
  List<QueryDocumentSnapshot> _cachedInvites = [];
  List<Ministry> _cachedMinistries = [];
  int _cachedPendingInviteCount = 0;
  
  // Estado para saber si el usuario puede crear ministerios
  bool _canCreateMinistry = false;
  
  @override
  void initState() {
    super.initState();
    // Verificar el permiso específico
    _checkCreatePermission();
    // Intentar marcar como leídas las notificaciones "huerfanas" o mal formadas al entrar a la lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanOrphanNotifications();
    });
  }
  
  Future<void> _cleanOrphanNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Buscar notificaciones de ministerios que no se hayan limpiado
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      // 1. Notificaciones genéricas de "Nuevos ministerios"
      final genericNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', whereIn: ['ministry', 'newMinistries']) 
          .get();

      for (var doc in genericNotifs.docs) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }

      // 2. Notificaciones de posts huérfanas (sin ministryId o mal formadas)
      // Esto busca CUALQUIER notificación de tipo ministry_post no leída y verifica si se puede limpiar
      // Como estamos en la lista general, no sabemos a qué ministerio pertenecen, pero podemos
      // verificar si el post existe. Si no existe, es basura y se borra.
      // Si existe, la dejamos (el usuario debe entrar al ministerio para borrarla y leerla).
      // PERO: Si el usuario ya está aquí, tal vez quiera "marcar todo como leído"? No, eso no es estándar.
      // Lo que haremos es reparar las notificaciones que no tengan ministryId para que el badge del Home funcione bien.
      
      final postNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', isEqualTo: 'ministry_post')
          .get();

      for (var doc in postNotifs.docs) {
        final data = doc.data();
        // Si no tiene ministryId, intentamos recuperarlo del post original
        if (data['ministryId'] == null && data['entityId'] != null) {
           try {
             final postId = data['entityId'] as String;
             final postDoc = await FirebaseFirestore.instance.collection('ministry_posts').doc(postId).get();
             
             if (postDoc.exists) {
               final postData = postDoc.data();
               dynamic ministryRef = postData?['ministryId'];
               String? ministryId;
               
               if (ministryRef is DocumentReference) {
                 ministryId = ministryRef.id;
               } else if (ministryRef is String) {
                 ministryId = ministryRef;
               }
               
               if (ministryId != null) {
                 // REPARACIÓN: Añadir el ministryId a la notificación para que el filtro del Home funcione
                 batch.update(doc.reference, {'ministryId': ministryId});
                 hasUpdates = true;
                 debugPrint('🔧 Reparando notificación ${doc.id}: asignando ministryId=$ministryId');
               }
             } else {
               // Si el post no existe, la notificación es basura -> borrar
               batch.update(doc.reference, {'isRead': true});
               hasUpdates = true;
               debugPrint('🗑️ Borrando notificación huérfana de post inexistente: ${doc.id}');
             }
           } catch (e) {
             debugPrint('Error verificando post para notificación ${doc.id}: $e');
           }
        }
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('✅ MINISTRIES_LIST - Limpieza y reparación de notificaciones realizada');
      }
    } catch (e) {
      debugPrint('❌ MINISTRIES_LIST - Error en limpieza de notificaciones: $e');
    }
  }
  
  Future<void> _checkCreatePermission() async {
    // Verificar el permiso específico para crear ministerios
    final hasPermission = await _permissionService.hasPermission('create_ministry');
    if (mounted) {
      setState(() {
        _canCreateMinistry = hasPermission;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Ministry> _filterMinistries(List<Ministry> ministries) {
    if (_searchQuery.isEmpty) return ministries;
    return ministries.where((ministry) => 
      ministry.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _handleMinistryAction(Ministry ministry) async {
    final strings = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.mustBeLoggedInToJoinMinistry)),
      );
      return;
    }

    final status = ministry.getUserStatus(user.uid);

    if (status == 'Enter') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MinistryFeedScreen(ministry: ministry),
        ),
      );
    } else if (status == 'Pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.joinRequestPendingApproval)),
      );
    } else {
      try {
        await _ministryService.requestToJoin(ministry.id);
        
        if (mounted) {
          setState(() {
            final updatedPendingRequests = Map<String, dynamic>.from(ministry.pendingRequests);
            updatedPendingRequests[user.uid] = Timestamp.now();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.joinRequestSent)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.errorLoadingData(e.toString()))),
          );
        }
      }
    }
  }


  Stream<QuerySnapshot> _ministryInviteStream(String userId) {
    if (userId.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }
    return FirebaseFirestore.instance
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('entityType', isEqualTo: 'ministry')
        .where('requestType', isEqualTo: 'invite')
        .orderBy('requestTimestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _pendingMinistryInviteStream(String userId) {
    if (userId.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }
    return FirebaseFirestore.instance
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('entityType', isEqualTo: 'ministry')
        .where('requestType', isEqualTo: 'invite')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _respondToInvite({
    required String requestId,
    required String ministryId,
    required bool accept,
    required String inviterId,
    required String inviterName,
    required String ministryName,
    required String userName,
  }) async {
    // Evitar procesamiento múltiple del mismo request
    if (_pendingInviteIds.contains(requestId)) {
      debugPrint('Request $requestId ya está siendo procesado');
      return;
    }

    setState(() {
      _pendingInviteIds.add(requestId);
    });

    final strings = AppLocalizations.of(context)!;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado');
        return;
      }

      debugPrint('Procesando invitación $requestId para ministerio $ministryId - Accept: $accept');

      if (accept) {
        await _ministryService.acceptJoinRequest(currentUser.uid, ministryId);

        // Enviar notificación al invitador
        if (inviterId.isNotEmpty && inviterId != currentUser.uid) {
          try {
            final notificationService =
                Provider.of<NotificationService>(context, listen: false);
            await notificationService.createNotification(
              title: strings.notifTypeMinistryInviteAccepted,
              message: strings.ministryInviteAcceptedMessage(userName, ministryName),
              type: NotificationType.ministryInviteAccepted,
              userId: inviterId,
              senderId: currentUser.uid,
              entityId: ministryId,
              entityType: 'ministry',
              ministryId: ministryId,
              actionRoute: '/ministries',
            );
          } catch (e) {
            debugPrint('Error enviando notificación de aceptación: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.inviteAcceptedSuccessfully)),
          );
        }
      } else {
        await _ministryService.rejectJoinRequest(currentUser.uid, ministryId);

        // Enviar notificación al invitador
        if (inviterId.isNotEmpty && inviterId != currentUser.uid) {
          try {
            final notificationService =
                Provider.of<NotificationService>(context, listen: false);
            await notificationService.createNotification(
              title: strings.notifTypeMinistryInviteRejected,
              message: strings.ministryInviteRejectedMessage(userName, ministryName),
              type: NotificationType.ministryInviteRejected,
              userId: inviterId,
              senderId: currentUser.uid,
              entityId: ministryId,
              entityType: 'ministry',
              ministryId: ministryId,
              actionRoute: '/ministries',
            );
          } catch (e) {
            debugPrint('Error enviando notificación de rechazo: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.inviteRejectedSuccessfully)),
          );
        }
      }

      debugPrint('Invitación $requestId procesada exitosamente');

    } catch (e) {
      debugPrint('Error procesando invitación $requestId: $e');

      if (mounted) {
        String errorMessage = strings.errorRespondingToInvite(e.toString());

        // Manejar errores específicos
        if (e.toString().contains('solicitud pendiente')) {
          errorMessage = 'Esta invitación ya fue procesada anteriormente';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Asegurarse de limpiar el estado incluso si hay error
      if (mounted) {
        setState(() {
          _pendingInviteIds.remove(requestId);
        });
      }
      debugPrint('Estado limpiado para invitación $requestId');
    }
  }

  String _inviteStatusLabel(AppLocalizations strings, String status) {
    switch (status) {
      case 'accepted':
        return strings.acceptedStatus;
      case 'rejected':
        return strings.rejectedStatus;
      default:
        return strings.pendingStatus;
    }
  }

  Color _inviteStatusColor(ColorScheme scheme, String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.shade600;
      case 'rejected':
        return scheme.error;
      default:
        return Colors.orange.shade600;
    }
  }

  Widget _buildInvitesTabLabel(String userId, AppLocalizations strings) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendingMinistryInviteStream(userId),
      builder: (context, snapshot) {
        final count = snapshot.hasData
            ? snapshot.data!.docs.length
            : _cachedPendingInviteCount;
        if (snapshot.hasData) {
          _cachedPendingInviteCount = count;
        }
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.invitations),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvitesTab(String userId, AppLocalizations strings) {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<QuerySnapshot>(
      stream: _ministryInviteStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(strings.errorLoadingInvitations));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedInvites.isEmpty) {
          return const ListTabContentSkeleton();
        }

        final invites = snapshot.hasData ? snapshot.data!.docs : _cachedInvites;
        if (snapshot.hasData) {
          _cachedInvites = invites;
        }
        if (invites.isEmpty) {
          return Center(
            child: Text(
              strings.noInvitesFound,
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: invites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = invites[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString() ?? 'pending';
            final ministryName =
                data['entityName']?.toString() ?? strings.ministries;
            final inviterId = data['invitedBy']?.toString() ?? '';
            final inviterName =
                data['invitedByName']?.toString() ?? strings.unknownUser;
            final inviteeName =
                data['userName']?.toString() ?? strings.unknownUser;
            final isPending = status == 'pending';
            final isBusy = _pendingInviteIds.contains(doc.id);

            return Dismissible(
              key: Key('ministry_invite_${doc.id}_$status'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              confirmDismiss: (direction) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(strings.confirmAction),
                    content: Text(strings.confirmDeleteInvite),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(strings.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(strings.delete),
                      ),
                    ],
                  ),
                );
                return confirmed ?? false;
              },
              onDismissed: (direction) async {
                try {
                  // Si está pendiente, rechazar primero
                  if (isPending && !_pendingInviteIds.contains(doc.id)) {
                    await _respondToInvite(
                      requestId: doc.id,
                      ministryId: data['entityId']?.toString() ?? '',
                      accept: false,
                      inviterId: inviterId,
                      inviterName: inviterName,
                      ministryName: ministryName,
                      userName: inviteeName,
                    );
                  }
                  // Marcar como eliminada localmente (opcional, ya que el stream se actualizará)
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${strings.errorDeletingInvite}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.12),
                            child:
                                Icon(Icons.groups, color: colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ministryName,
                              style: AppTextStyles.subtitle2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _inviteStatusColor(colorScheme, status)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _inviteStatusLabel(strings, status),
                              style: AppTextStyles.caption.copyWith(
                                color: _inviteStatusColor(colorScheme, status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _respondToInvite(
                                        requestId: doc.id,
                                        ministryId:
                                            data['entityId']?.toString() ?? '',
                                        accept: false,
                                        inviterId: inviterId,
                                        inviterName: inviterName,
                                        ministryName: ministryName,
                                        userName: inviteeName,
                                      ),
                              child: Text(strings.reject),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _respondToInvite(
                                        requestId: doc.id,
                                        ministryId:
                                            data['entityId']?.toString() ?? '',
                                        accept: true,
                                        inviterId: inviterId,
                                        inviterName: inviterName,
                                        ministryName: ministryName,
                                        userName: inviteeName,
                                      ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: Text(strings.accept),
                            ),
                          ],
                        ),
                      ],
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
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final userId = user?.uid ?? '';
    final strings = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            strings.ministries,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const Spacer(),
                          if (_canCreateMinistry)
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: strings.createMinistry,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => const CreateMinistryModal(),
                                );
                              },
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(text: strings.ministries),
                        _buildInvitesTabLabel(userId, strings),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: strings.searchMinistry,
                            hintStyle: AppTextStyles.bodyText2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: AppTextStyles.bodyText2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<Ministry>>(
                          stream: _ministryService.getMinistries(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  strings.somethingWentWrong,
                                  style: AppTextStyles.bodyText1.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _cachedMinistries.isEmpty) {
                              return const ListTabContentSkeleton();
                            }

                            try {
                              final ministries =
                                  snapshot.hasData ? snapshot.data! : _cachedMinistries;
                              if (snapshot.hasData) {
                                _cachedMinistries = ministries;
                              }
                              final filteredMinistries =
                                  _filterMinistries(ministries);

                              if (filteredMinistries.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.group_off,
                                        size: 64,
                                        color: AppColors.mutedGray,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        strings.noMinistriesAvailable,
                                        style: AppTextStyles.subtitle1.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: filteredMinistries.length,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final ministry = filteredMinistries[index];

                                  return MinistryCard(
                                    ministry: ministry,
                                    userId: userId,
                                    onActionPressed: _handleMinistryAction,
                                  );
                                },
                              );
                            } catch (e) {
                              return Center(
                                child: Text(
                                  strings.somethingWentWrong,
                                  style: AppTextStyles.bodyText1.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildInvitesTab(userId, strings),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _canCreateMinistry
            ? FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const CreateMinistryModal(),
                  );
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add),
                tooltip: strings.createMinistry,
              )
            : null,
      ),
    );
  }

}
