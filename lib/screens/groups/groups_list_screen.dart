import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'group_feed_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/group_card.dart';
import '../../modals/create_group_modal.dart';
import '../../services/permission_service.dart';
import '../../widgets/skeletons/list_tab_content_skeleton.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final GroupService _groupService = GroupService();
  final PermissionService _permissionService = PermissionService();
  final Set<String> _pendingInviteIds = {};
  
  // Estado para saber si el usuario tiene permiso para crear grupos
  bool _canCreateGroup = false;
  
  @override
  void initState() {
    super.initState();
    // Verificamos el permiso del usuario al iniciar
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
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      // 1. Notificaciones genéricas de "Nuevos grupos"
      final genericNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', whereIn: ['group', 'newGroup']) 
          .get();

      for (var doc in genericNotifs.docs) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }

      // 2. Notificaciones de posts huérfanas (sin groupId o mal formadas)
      final postNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', isEqualTo: 'group_post')
          .get();

      for (var doc in postNotifs.docs) {
        final data = doc.data();
        // Si no tiene groupId, intentamos recuperarlo del post original
        if (data['groupId'] == null && data['entityId'] != null) {
           try {
             final postId = data['entityId'] as String;
             final postDoc = await FirebaseFirestore.instance.collection('group_posts').doc(postId).get();
             
             if (postDoc.exists) {
               final postData = postDoc.data();
               dynamic groupRef = postData?['groupId'];
               String? groupId;
               
               if (groupRef is DocumentReference) {
                 groupId = groupRef.id;
               } else if (groupRef is String) {
                 groupId = groupRef;
               }
               
               if (groupId != null) {
                 // REPARACIÓN: Añadir el groupId a la notificación
                 batch.update(doc.reference, {'groupId': groupId});
                 hasUpdates = true;
                 debugPrint('🔧 Reparando notificación grupo ${doc.id}: asignando groupId=$groupId');
               }
             } else {
               // Si el post no existe, la notificación es basura -> borrar
               batch.update(doc.reference, {'isRead': true});
               hasUpdates = true;
               debugPrint('🗑️ Borrando notificación huérfana de post de grupo inexistente: ${doc.id}');
             }
           } catch (e) {
             debugPrint('Error verificando post grupo para notificación ${doc.id}: $e');
           }
        }
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('✅ GROUPS_LIST - Limpieza y reparación de notificaciones realizada');
      }
    } catch (e) {
      debugPrint('❌ GROUPS_LIST - Error en limpieza de notificaciones: $e');
    }
  }
  
  Future<void> _checkCreatePermission() async {
    // Verificar el permiso específico para crear grupos
    final hasPermission = await _permissionService.hasPermission('create_group');
    if (mounted) {
      setState(() {
        _canCreateGroup = hasPermission;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Group> _filterGroups(List<Group> groups) {
    if (_searchQuery.isEmpty) return groups;
    return groups.where((group) => 
      group.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _handleGroupAction(Group group) async {
    final strings = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.mustBeLoggedInToJoinGroup)),
      );
      return;
    }

    final status = group.getUserStatus(user.uid);

    if (status == 'Enter') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupFeedScreen(group: group),
        ),
      );
    } else if (status == 'Pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.joinRequestPendingApproval)),
      );
    } else {
      try {
        await _groupService.requestToJoin(group.id);
        
        if (mounted) {
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

  Stream<QuerySnapshot> _groupInviteStream(String userId) {
    if (userId.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }
    return FirebaseFirestore.instance
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('entityType', isEqualTo: 'group')
        .where('requestType', isEqualTo: 'invite')
        .orderBy('requestTimestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _pendingGroupInviteStream(String userId) {
    if (userId.isEmpty) {
      return const Stream<QuerySnapshot>.empty();
    }
    return FirebaseFirestore.instance
        .collection('membership_requests')
        .where('userId', isEqualTo: userId)
        .where('entityType', isEqualTo: 'group')
        .where('requestType', isEqualTo: 'invite')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _respondToInvite({
    required String requestId,
    required String groupId,
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
        await _groupService.acceptJoinRequest(currentUser.uid, groupId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.inviteAcceptedSuccessfully)),
          );
        }
      } else {
        await _groupService.rejectJoinRequest(currentUser.uid, groupId);
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
      stream: _pendingGroupInviteStream(userId),
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
      stream: _groupInviteStream(userId),
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
            final groupName =
                data['entityName']?.toString() ?? strings.groups;
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
                          child: Icon(Icons.group,
                              color: colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            groupName,
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
                                      groupId: data['entityId']?.toString() ?? '',
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
                                      groupId: data['entityId']?.toString() ?? '',
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
                            strings.groups,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const Spacer(),
                          if (_canCreateGroup)
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: strings.createConnect,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => const CreateGroupModal(),
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
                        Tab(text: strings.groups),
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
                          hintText: strings.searchGroups,
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
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('groups')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  strings.errorLoadingGroups(snapshot.error ?? ''),
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
                              final allGroups = snapshot.data!.docs
                                  .map((doc) => Group.fromFirestore(doc))
                                  .toList();

                              final filteredGroups = _filterGroups(allGroups);

                              if (filteredGroups.isEmpty) {
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
                                      strings.noGroupsAvailable,
                                        style:
                                            AppTextStyles.subtitle1.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: filteredGroups.length,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                itemBuilder: (context, index) {
                                  final group = filteredGroups[index];

                                  return GroupCard(
                                    group: group,
                                    userId: userId,
                                    onActionPressed: _handleGroupAction,
                                  );
                                },
                              );
                            } catch (e) {
                              return Center(
                                child: Text(
                                  'Erro ao processar dados: ${e.toString()}',
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
        floatingActionButton: _canCreateGroup
            ? FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const CreateGroupModal(),
                  );
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add),
                tooltip: strings.createConnect,
              )
            : null,
      ),
    );
  }

} 
