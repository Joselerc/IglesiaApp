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
  }) async {
    if (_pendingInviteIds.contains(requestId)) return;
    setState(() {
      _pendingInviteIds.add(requestId);
    });

    final strings = AppLocalizations.of(context)!;
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      if (accept) {
        await _ministryService.acceptJoinRequest(currentUser.uid, ministryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.inviteAcceptedSuccessfully)),
          );
        }
      } else {
        await _ministryService.rejectJoinRequest(currentUser.uid, ministryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.inviteRejectedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.errorRespondingToInvite(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingInviteIds.remove(requestId);
        });
      }
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
        final count = snapshot.data?.docs.length ?? 0;
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTabContentSkeleton();
        }

        final invites = snapshot.data?.docs ?? [];
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
            final isPending = status == 'pending';
            final isBusy = _pendingInviteIds.contains(doc.id);

            return Card(
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
                                ConnectionState.waiting) {
                              return const ListTabContentSkeleton();
                            }

                            try {
                              final ministries = snapshot.data ?? [];
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
