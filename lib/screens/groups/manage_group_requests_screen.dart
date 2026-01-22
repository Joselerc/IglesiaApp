import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/membership_request_service.dart';
import '../../services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/family_localizations.dart';

class ManageGroupRequestsScreen extends StatefulWidget {
  final Group group;

  const ManageGroupRequestsScreen({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  State<ManageGroupRequestsScreen> createState() => _ManageGroupRequestsScreenState();
}

class _ManageGroupRequestsScreenState extends State<ManageGroupRequestsScreen> with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final MembershipRequestService _requestService = MembershipRequestService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingRequests = [];
  int _totalRequests = 0;
  int _acceptedRequests = 0;
  int _rejectedRequests = 0;
  int _exitedMembers = 0;
  late TabController _tabController;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRequests();
    _loadStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadStats() async {
    try {
      final stats = await _requestService.getRequestStats(
        widget.group.id, 
        'group'
      );
      
      // Obtener la cantidad de usuarios que han salido del grupo
      final exitsSnapshot = await FirebaseFirestore.instance
          .collection('member_exits')
          .where('entityId', isEqualTo: widget.group.id)
          .where('entityType', isEqualTo: 'group')
          .count()
          .get();
      
      final exitCount = exitsSnapshot.count ?? 0;
      
      if (mounted) {
      setState(() {
          _totalRequests = stats['totalRequests'];
          _acceptedRequests = stats['acceptedRequests'];
          _rejectedRequests = stats['rejectedRequests'];
          _exitedMembers = exitCount;
      });
      }
    } catch (e) {
      debugPrint('Error cargando estatísticas: $e');
    }
    }

  Future<void> _loadRequests() async {
    final strings = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = <Map<String, dynamic>>[];
      
      // Debug: Imprimir los pendingRequests del grupo
      print('Group pendingRequests: ${widget.group.pendingRequests}');
      
      // Usar el nuevo servicio para obtener las solicitudes pendientes
      print('Buscando solicitudes para grupo: ${widget.group.id}, tipo: group');
      final snapshot = await _requestService.getPendingRequests(
        widget.group.id, 
        'group'
      ).first;
      
      print('Solicitudes encontradas: ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Solicitud encontrada: ${doc.id}, usuario: ${data['userId']}');

        final requestType = data['requestType']?.toString() ?? 'join';
        final requestTimestamp = data['requestTimestamp'] as Timestamp?;

        requests.add({
          'id': doc.id,
          'userId': data['userId'],
          'name': data['userName'] ?? strings.unknownUser,
          'email': data['userEmail'] ?? strings.noEmail,
          'photoUrl': data['userPhotoUrl'],
          'requestDate': requestTimestamp?.toDate() ?? DateTime.now(),
          'message': data['message'],
          'requestType': requestType,
          'invitedByName': data['invitedByName'],
        });
      }
      
      // Ordenar por fecha (más reciente primero)
      requests.sort((a, b) => 
        (b['requestDate'] as DateTime).compareTo(a['requestDate'] as DateTime)
      );

      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.errorLoadingData(e.toString()))),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String userId, String requestId) async {
    final strings = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      // Aceptar solicitud en el grupo
      await _groupService.acceptJoinRequest(userId, widget.group.id);

      // Enviar notificación al usuario
      if (mounted) {
        try {
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          await notificationService.sendGroupJoinRequestAcceptedNotification(
            userId: userId,
            groupId: widget.group.id,
            groupName: widget.group.name,
          );
        } catch (e) {
          print('Error enviando notificación de aceptación: $e');
        }
      }

      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((request) => request['userId'] == userId);
          _acceptedRequests++;
          _isLoading = false;
        });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.requestAcceptedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.errorLoadingData(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  Future<void> _rejectRequest(String userId, String requestId) async {
    final strings = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      // Rechazar solicitud en el grupo
      await _groupService.rejectJoinRequest(userId, widget.group.id);

      // Enviar notificación al usuario
      if (mounted) {
        try {
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          await notificationService.sendGroupJoinRequestRejectedNotification(
            userId: userId,
            groupId: widget.group.id,
            groupName: widget.group.name,
          );
        } catch (e) {
          print('Error enviando notificación de rechazo: $e');
        }
      }

      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((request) => request['userId'] == userId);
          _rejectedRequests++;
          _isLoading = false;
        });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.requestRejected),
              backgroundColor: Colors.orange,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.errorLoadingData(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  Future<void> _revokeInvite(String userId) async {
    final strings = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.rejectJoinRequest(userId, widget.group.id);

      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((request) => request['userId'] == userId);
          _rejectedRequests++;
          _isLoading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.cancelInvitation),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorLoadingData(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _inviteUserToGroup(String userId) async {
    try {
      await _groupService.inviteUserToGroup(userId, widget.group.id);
    } catch (e) {
      print('Erro ao enviar convite: $e');
      throw Exception('Erro ao enviar convite: $e');
    }
  }

  Future<void> _showAddUserModal() async {
    if (!mounted) return;

    final strings = AppLocalizations.of(context)!;
    final selectedUsers = <String>{};
    final selectedFamilies = <String>{};
    List<Map<String, dynamic>> allUsers = [];
    List<Map<String, dynamic>> filteredUsers = [];
    List<Map<String, dynamic>> allFamilies = [];
    List<Map<String, dynamic>> filteredFamilies = [];
    final userLookup = <String, Map<String, dynamic>>{};
    final expandedFamilyIds = <String>{};

    final memberIds = widget.group.memberIds;

    List<String> extractUserIds(dynamic rawList) {
      if (rawList is Iterable) {
        return rawList.map<String>((entry) {
          if (entry is DocumentReference) return entry.id;
          if (entry is String && entry.startsWith('/users/')) {
            return entry.substring(7);
          }
          return entry.toString();
        }).toList();
      }
      return [];
    }

    Map<String, String> extractRoles(dynamic rawMap) {
      final roles = <String, String>{};
      if (rawMap is Map) {
        rawMap.forEach((key, value) {
          if (key == null) return;
          String userId;
          if (key is DocumentReference) {
            userId = key.id;
          } else if (key is String && key.startsWith('/users/')) {
            userId = key.substring(7);
          } else {
            userId = key.toString();
          }
          roles[userId] = value?.toString() ?? '';
        });
      }
      return roles;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      if (!mounted) return;

      for (var doc in usersSnapshot.docs) {
        final isMember = memberIds.contains(doc.id);
        final userData = doc.data() as Map<String, dynamic>?;
        if (userData == null) continue;

        final userName =
            userData['name'] ?? userData['displayName'] ?? strings.unknownUser;
        final photoUrl = userData['photoUrl'] ?? '';
        final email = userData['email'] ?? '';

        allUsers.add({
          'id': doc.id,
          'name': userName,
          'email': email,
          'photoUrl': photoUrl,
          'isMember': isMember,
        });
        userLookup[doc.id] = {
          'name': userName,
          'email': email,
          'photoUrl': photoUrl,
        };
      }

      filteredUsers = List<Map<String, dynamic>>.from(allUsers);

      final familiesSnapshot = await FirebaseFirestore.instance
          .collection('family_groups')
          .get();

      for (var doc in familiesSnapshot.docs) {
        final familyData = doc.data() as Map<String, dynamic>?;
        if (familyData == null) continue;

        final familyName = (familyData['name'] as String?)?.trim();
        final membersRaw = familyData['members'] ?? familyData['memberIds'];
        final familyMemberIds = extractUserIds(membersRaw).toSet().toList();
        final memberRoles = extractRoles(familyData['memberRoles']);

        allFamilies.add({
          'id': doc.id,
          'name': familyName?.isNotEmpty == true
              ? familyName
              : strings.familyFallbackName,
          'photoUrl': familyData['photoUrl'] ?? '',
          'memberIds': familyMemberIds,
          'memberRoles': memberRoles,
        });
      }

      filteredFamilies = List<Map<String, dynamic>>.from(allFamilies);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          String searchQuery = '';
          bool showOnlyNonMembers = false;
          bool showFamilies = false;

          void updateFilters() {
            if (showFamilies) {
              if (searchQuery.isNotEmpty) {
                filteredFamilies = allFamilies
                    .where((family) => family['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList()
                    .cast<Map<String, dynamic>>();
              } else {
                filteredFamilies = List<Map<String, dynamic>>.from(allFamilies);
              }
              return;
            }

            final baseList = showOnlyNonMembers
                ? allUsers
                    .where((user) => !(user['isMember'] as bool))
                    .toList()
                    .cast<Map<String, dynamic>>()
                : List<Map<String, dynamic>>.from(allUsers);

            if (searchQuery.isNotEmpty) {
              filteredUsers = baseList
                  .where((user) =>
                      user['name']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      user['email']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()))
                  .toList()
                  .cast<Map<String, dynamic>>();
            } else {
              filteredUsers = baseList;
            }
          }

          int selectedInviteCount() {
            final ids = <String>{}..addAll(selectedUsers);
            for (final family in allFamilies) {
              if (!selectedFamilies.contains(family['id'])) continue;
              final members =
                  (family['memberIds'] as List?)?.cast<String>() ?? <String>[];
              ids.addAll(members);
            }
            ids.removeWhere(memberIds.contains);
            return ids.length;
          }

          updateFilters();

          return StatefulBuilder(
            builder: (context, setModalState) {
              final colorScheme = Theme.of(context).colorScheme;
              Widget buildMemberRow(Map<String, dynamic> member) {
                final memberId = member['id']?.toString() ?? '';
                final photoUrl = member['photoUrl']?.toString() ?? '';
                final isMember = member['isMember'] == true;
                final isSelected = member['isSelected'] == true;
                final canSelect = member['canSelect'] == true;

                void toggleSelection() {
                  setModalState(() {
                    if (isSelected) {
                      selectedUsers.remove(memberId);
                    } else {
                      selectedUsers.add(memberId);
                    }
                  });
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: canSelect ? toggleSelection : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.12),
                          backgroundImage:
                              photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty
                              ? Icon(Icons.person,
                                  size: 18, color: colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['name']?.toString() ?? strings.unknownUser,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member['role']?.toString() ??
                                    familyRoleLabel(strings, 'otro'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMember)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              strings.member,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Checkbox(
                            value: isSelected,
                            onChanged: canSelect ? (_) => toggleSelection() : null,
                            activeColor: colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }

              Widget buildFamilyCard(Map<String, dynamic> family) {
                final familyId = family['id']?.toString() ?? '';
                final isSelected = selectedFamilies.contains(familyId);
                final isExpanded = expandedFamilyIds.contains(familyId);
                final members = (family['memberIds'] as List?)
                        ?.cast<String>() ??
                    <String>[];
                final memberRoles =
                    (family['memberRoles'] as Map?)?.cast<String, String>() ??
                        <String, String>{};
                final photoUrl = family['photoUrl']?.toString() ?? '';

                final memberItems = members.map((memberId) {
                  final user = userLookup[memberId] ?? const <String, dynamic>{};
                  final alreadyMember = memberIds.contains(memberId);
                  final isSelectedByUser = selectedUsers.contains(memberId);
                  final isSelectedRow = isSelected || isSelectedByUser;
                  final canSelect = !alreadyMember && !isSelected;

                  return {
                    'id': memberId,
                    'name': user['name'] ?? strings.unknownUser,
                    'photoUrl': user['photoUrl'] ?? '',
                    'role': familyRoleLabel(
                      strings,
                      memberRoles[memberId]?.toString() ?? 'otro',
                    ),
                    'isMember': alreadyMember,
                    'isSelected': isSelectedRow,
                    'canSelect': canSelect,
                  };
                }).toList();
                memberItems.sort((a, b) => (a['name'] as String)
                    .toLowerCase()
                    .compareTo((b['name'] as String).toLowerCase()));

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setModalState(() {
                            if (isExpanded) {
                              expandedFamilyIds.remove(familyId);
                            } else {
                              expandedFamilyIds.add(familyId);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                backgroundColor:
                                    colorScheme.primary.withValues(alpha: 0.12),
                                child: photoUrl.isEmpty
                                    ? Icon(Icons.family_restroom,
                                        color: colorScheme.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      family['name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      strings.familyMembersCount(members.length),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                activeColor: colorScheme.primary,
                                onChanged: (value) {
                                  setModalState(() {
                                    if (value == true) {
                                      selectedFamilies.add(familyId);
                                    } else {
                                      selectedFamilies.remove(familyId);
                                    }
                                  });
                                },
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.expand_more,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.familyMembersLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (memberItems.isEmpty)
                                      Text(
                                        strings.noUsersFound,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    if (memberItems.isNotEmpty)
                                      ...memberItems.map(buildMemberRow),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }

              return AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  top: false,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Material(
                      color: colorScheme.surface,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.85,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.addUsers,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: showFamilies
                            ? strings.searchFamilies
                            : strings.searchUsers,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                          updateFilters();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(strings.users),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(strings.familiesTitle),
                          ),
                        ],
                        selected: {showFamilies},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => states.contains(MaterialState.selected)
                                ? colorScheme.primary.withValues(alpha: 0.12)
                                : colorScheme.surfaceContainerHighest,
                          ),
                          foregroundColor: MaterialStateProperty.resolveWith(
                            (states) => states.contains(MaterialState.selected)
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          side: MaterialStateProperty.resolveWith(
                            (states) => BorderSide(
                              color: states.contains(MaterialState.selected)
                                  ? colorScheme.primary
                                      .withValues(alpha: 0.35)
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        onSelectionChanged: (selection) {
                          setModalState(() {
                            showFamilies = selection.first;
                            updateFilters();
                          });
                        },
                      ),
                    ),
                    if (!showFamilies) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: showOnlyNonMembers,
                            activeColor: colorScheme.primary,
                            onChanged: (value) {
                              setModalState(() {
                                showOnlyNonMembers = value ?? false;
                                updateFilters();
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              strings.showOnlyNonMembers,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Text(
                      strings.selectedUsers(selectedInviteCount()),
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: showFamilies
                          ? (filteredFamilies.isEmpty
                              ? Center(
                                  child: Text(
                                    strings.noFamiliesFound,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredFamilies.length,
                                  itemBuilder: (context, index) {
                                    final family = filteredFamilies[index];
                                    return buildFamilyCard(family);
                                  },
                                ))
                          : (filteredUsers.isEmpty
                              ? Center(
                                  child: Text(
                                    strings.noUserFound,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    final isSelected =
                                        selectedUsers.contains(user['id']);
                                    final isMember = user['isMember'] as bool;

                                    return Card(
                                      margin:
                                          const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: user['photoUrl'] != null &&
                                                  user['photoUrl'].isNotEmpty
                                              ? NetworkImage(user['photoUrl'])
                                              : null,
                                          child: user['photoUrl'] == null ||
                                                  user['photoUrl'].isEmpty
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user['name'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMember)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  strings.member,
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          user['email'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: isMember
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.green)
                                            : Checkbox(
                                                value: isSelected,
                                                activeColor: Colors.green,
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    if (value == true) {
                                                      selectedUsers
                                                          .add(user['id']);
                                                    } else {
                                                      selectedUsers
                                                          .remove(user['id']);
                                                    }
                                                  });
                                                },
                                              ),
                                        onTap: isMember
                                            ? null
                                            : () {
                                                setModalState(() {
                                                  if (isSelected) {
                                                    selectedUsers
                                                        .remove(user['id']);
                                                  } else {
                                                    selectedUsers
                                                        .add(user['id']);
                                                  }
                                                });
                                              },
                                        tileColor:
                                            isMember ? Colors.grey[100] : null,
                                      ),
                                    );
                                  },
                                )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: selectedUsers.isEmpty &&
                                selectedFamilies.isEmpty
                            ? null
                            : () async {
                                Navigator.pop(context);

                                if (!mounted) return;

                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  final userIdsToInvite =
                                      <String>{}..addAll(selectedUsers);

                                  for (final family in allFamilies) {
                                    if (!selectedFamilies
                                        .contains(family['id'])) continue;
                                    final members =
                                        (family['memberIds'] as List?)
                                            ?.cast<String>() ??
                                            <String>[];
                                    userIdsToInvite.addAll(members);
                                  }

                                  userIdsToInvite
                                      .removeWhere(memberIds.contains);

                                  if (userIdsToInvite.isNotEmpty) {
                                    for (var userId in userIdsToInvite) {
                                      if (mounted) {
                                        await _inviteUserToGroup(userId);
                                      }
                                    }
                                  }

                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(strings.invitesSent),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    _loadRequests();
                                    _loadStats();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${strings.somethingWentWrong}: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Text(strings.sendInvitations),
                      ),
                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (mounted) {
        _loadRequests();
        _loadStats();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.somethingWentWrong}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.memberManagement),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green,
                Colors.green.withOpacity(0.8),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.visibility_off : Icons.bar_chart),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
            tooltip: _showStats ? AppLocalizations.of(context)!.hideStatistics : AppLocalizations.of(context)!.viewStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRequests();
              _loadStats();
            },
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.pending),
            Tab(text: AppLocalizations.of(context)!.approved),
            Tab(text: AppLocalizations.of(context)!.rejected),
            Tab(text: AppLocalizations.of(context)!.exits),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Panel de estatísticas (visible/oculto)
                if (_showStats)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.requestStatistics,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              AppLocalizations.of(context)!.total,
                              _totalRequests,
                              Colors.green,
                              Icons.people_outline,
                            ),
                            _buildStatCard(
                              AppLocalizations.of(context)!.approved,
                              _acceptedRequests,
                              Colors.green,
                              Icons.check_circle_outline,
                            ),
                            _buildStatCard(
                              AppLocalizations.of(context)!.rejected,
                              _rejectedRequests,
                              Colors.orange,
                              Icons.cancel_outlined,
                            ),
                            _buildStatCard(
                              AppLocalizations.of(context)!.exits,
                              _exitedMembers,
                              Colors.red,
                              Icons.exit_to_app,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                // Contenido de las pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña "Pendientes"
                      _buildPendingRequestsTab(),
                      
                      // Pestaña "Aceptadas"
                      _buildRequestsHistoryTab('accepted'),
                      
                      // Pestaña "Rechazadas"
                      _buildRequestsHistoryTab('rejected'),
                      
                      // Pestaña "Saídas"
                      _buildExitedMembersTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
      onPressed: _showAddUserModal,
      tooltip: AppLocalizations.of(context)!.addUsers,
      backgroundColor: Colors.green,
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    final strings = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream: _requestService.getPendingRequests(widget.group.id, 'group'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(strings.errorLoadingData(snapshot.error.toString())),
          );
        }
        final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          DateTime resolveDate(Map<String, dynamic> data) {
            final raw = data['requestTimestamp'];
            if (raw is Timestamp) return raw.toDate();
            if (raw is DateTime) return raw;
            return DateTime.fromMillisecondsSinceEpoch(0);
          }

          return resolveDate(bData).compareTo(resolveDate(aData));
        });
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  strings.noPendingRequests,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.allUpToDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadStats();
          },
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final requestType = data['requestType']?.toString() ?? 'join';
              final isInvite = requestType == 'invite';
              final inviterName =
                  data['invitedByName']?.toString() ?? strings.administrator;
              final statusColor = isInvite
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary;
              final rawTimestamp = data['requestTimestamp'];
              final requestDate = rawTimestamp is Timestamp
                  ? rawTimestamp.toDate()
                  : rawTimestamp is DateTime
                      ? rawTimestamp
                      : DateTime.now();
              final photoUrl = data['userPhotoUrl']?.toString();
              final name = data['userName']?.toString() ?? strings.unknownUser;
              final email = data['userEmail']?.toString() ?? strings.noEmail;
              final message = data['message']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: photoUrl != null &&
                                      photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isInvite
                                    ? strings.invitationLabel
                                    : strings.requestPending,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isInvite) ...[
                          Row(
                            children: [
                              const Icon(Icons.person_add,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${strings.invitedByLabel}: $inviterName',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${strings.requestedOn} ${DateFormat('dd/MM/yyyy HH:mm').format(requestDate)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (message.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${strings.message}:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              if (isInvite)
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _revokeInvite(
                                            data['userId'],
                                          ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  child: Text(strings.cancelInvitation),
                                )
                              else ...[
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _rejectRequest(
                                            data['userId'],
                                            doc.id,
                                          ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  child: Text(strings.reject),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _acceptRequest(
                                            data['userId'],
                                            doc.id,
                                          ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  child: Text(strings.accept),
                                ),
                              ],
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
        );
      },
    );
  }

  Widget _buildRequestsHistoryTab(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('membership_requests')
          .where('entityId', isEqualTo: widget.group.id)
          .where('entityType', isEqualTo: 'group')
          .where('status', isEqualTo: status)
          .orderBy('requestTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!
                  .errorLoadingData(snapshot.error.toString()),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'accepted' ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'accepted' 
                    ? AppLocalizations.of(context)!.noApprovedRequests 
                    : AppLocalizations.of(context)!.noRejectedRequests,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final strings = AppLocalizations.of(context)!;
            
            final DateTime requestDate = (data['requestTimestamp'] as Timestamp).toDate();
            final DateTime? responseDate = data['responseTimestamp'] != null 
                ? (data['responseTimestamp'] as Timestamp).toDate() 
                : null;
                
            final Duration? responseTime = responseDate != null 
                ? responseDate.difference(requestDate) 
                : null;
            final String requestType = data['requestType']?.toString() ?? 'join';
            final bool isDirectAdd = data['directAdd'] == true;
            final String? invitedByName = data['invitedByName'] as String?;
            final String? addedByName = data['addedByName'] as String?;
            final String inviterName = invitedByName ??
                addedByName ??
                AppLocalizations.of(context)!.administrator;
            final bool showInviter = requestType == 'invite' || isDirectAdd || invitedByName != null || addedByName != null;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Foto de perfil
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: data['userPhotoUrl'] != null && data['userPhotoUrl'].toString().isNotEmpty
                              ? NetworkImage(data['userPhotoUrl'])
                              : null,
                          child: data['userPhotoUrl'] == null || data['userPhotoUrl'].toString().isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        
                        // Informacion del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  data['userName'] ?? strings.unknownUser,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                data['userEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Indicador de estado
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'accepted' ? Colors.green[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: status == 'accepted' ? Colors.green : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status == 'accepted' 
                              ? AppLocalizations.of(context)!.accepted 
                              : AppLocalizations.of(context)!.rejected,
                            style: TextStyle(
                              color: status == 'accepted' ? Colors.green[800] : Colors.orange[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Información de fechas
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (showInviter) 
                            Row(
                              children: [
                                const Icon(Icons.person_add, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.invitedByLabel}: $inviterName',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.requested}: ${DateFormat('dd/MM/yyyy HH:mm').format(requestDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          if (responseDate != null)
                            Row(
                              children: [
                                Icon(
                                  status == 'accepted' ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: status == 'accepted' ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    isDirectAdd 
                                      ? '${AppLocalizations.of(context)!.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(responseDate)}'
                                      : '${status == 'accepted' ? AppLocalizations.of(context)!.accepted : AppLocalizations.of(context)!.rejected}: ${DateFormat('dd/MM/yyyy HH:mm').format(responseDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: status == 'accepted' ? Colors.green[700] : Colors.orange[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                          if (responseTime != null && !isDirectAdd)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)!.responseTime}: ${_formatDuration(responseTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Mensaje de solicitud si existe y no fue añadido directamente
                    if (!isDirectAdd && data['message'] != null && data['message'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.message}:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                data['message'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Razón de aceptación/rechazo si existe
                    if (data['responseReason'] != null && data['responseReason'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.reason}:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: status == 'accepted' ? Colors.green[50] : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: status == 'accepted' ? Colors.green[200]! : Colors.orange[200]!,
                                ),
                              ),
                              child: Text(
                                data['responseReason'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: status == 'accepted' ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildExitedMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('member_exits')
          .where('entityId', isEqualTo: widget.group.id)
          .where('entityType', isEqualTo: 'group')
          .orderBy('exitTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!
                  .errorLoadingData(snapshot.error.toString()),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
          children: [
                const Icon(
                  Icons.exit_to_app,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noExitsRecorded,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final strings = AppLocalizations.of(context)!;
            
            final DateTime exitDate = (data['exitTimestamp'] as Timestamp).toDate();
            final DateTime? joinDate = data['joinTimestamp'] != null 
                ? (data['joinTimestamp'] as Timestamp).toDate() 
                : null;
            
            // Calcular el tiempo que el usuario estuvo en el grupo
            final Duration? membershipDuration = joinDate != null
                ? exitDate.difference(joinDate)
                : null;
            
            // Determinar si el usuario salió voluntariamente o fue eliminado
            final bool isVoluntaryExit = data['exitType'] == 'voluntary';
            final String removedById = data['removedById'] ?? '';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Foto de perfil
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: data['userPhotoUrl'] != null
                              ? NetworkImage(data['userPhotoUrl'])
                            : null,
                          child: data['userPhotoUrl'] == null
                              ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                        ),
                        const SizedBox(width: 16),
                        
                        // Informacion del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                  data['userName'] ?? strings.unknownUser,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                data['userEmail'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)!.exitedOn}: ${DateFormat('dd/MM/yyyy HH:mm').format(exitDate)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Indicador del tipo de salida
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVoluntaryExit ? Colors.orange[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isVoluntaryExit ? Colors.orange : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isVoluntaryExit 
                              ? AppLocalizations.of(context)!.voluntaryExit 
                              : AppLocalizations.of(context)!.removed,
                            style: TextStyle(
                              color: isVoluntaryExit ? Colors.orange[800] : Colors.red[800],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Información detallada
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (joinDate != null)
                            Row(
                              children: [
                                const Icon(Icons.login, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Entrou em: ${DateFormat('dd/MM/yyyy').format(joinDate)}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          
                          if (membershipDuration != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.timer, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tempo no grupo: ${_formatDuration(membershipDuration)}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          if (!isVoluntaryExit && removedById.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(removedById)
                                  .get(),
                              builder: (context, snapshot) {
                                String adminName =
                                    AppLocalizations.of(context)!.administrator;
                                
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final adminData = snapshot.data!.data() as Map<String, dynamic>;
                                  adminName = adminData['name'] ??
                                      AppLocalizations.of(context)!.administrator;
                                }
                                
                                return Row(
                                  children: [
                                    const Icon(Icons.person_remove, size: 16, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${AppLocalizations.of(context)!.removedBy}: $adminName',
                                        style: const TextStyle(fontSize: 14, color: Colors.red),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
          ],
        ),
      ),
                    
                    // Razón de salida si existe
                    if (data['exitReason'] != null && data['exitReason'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.reason}:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              width: double.infinity,
                              child: Text(
                                data['exitReason'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                                // No limitamos el número de líneas para que el motivo se vea completo
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'dia' : 'dias'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hora' : 'horas'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'segundo' : 'segundos'}';
    }
  }
} 
