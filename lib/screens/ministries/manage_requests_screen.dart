import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ministry.dart';
import '../../services/ministry_service.dart';
import '../../services/membership_request_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';

class ManageRequestsScreen extends StatefulWidget {
  final Ministry ministry;

  const ManageRequestsScreen({
    super.key,
    required this.ministry,
  });

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> with SingleTickerProviderStateMixin {
  final MinistryService _ministryService = MinistryService();
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
    _loadPendingRequests();
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
        widget.ministry.id, 
        'ministry'
      );
      
      // Obtener la cantidad de usuarios que han salido del ministerio
      final exitsSnapshot = await FirebaseFirestore.instance
          .collection('member_exits')
          .where('entityId', isEqualTo: widget.ministry.id)
          .where('entityType', isEqualTo: 'ministry')
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
      debugPrint('Erro carregando estatísticas: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    final strings = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = <Map<String, dynamic>>[];
      
      // Usar el nuevo servicio para obtener las solicitudes pendientes
      final snapshot = await _requestService.getPendingRequests(
        widget.ministry.id, 
        'ministry'
      ).first;
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final requestType = data['requestType']?.toString() ?? 'join';
        if (requestType == 'invite') {
          continue;
        }
          
        requests.add({
          'id': doc.id,
          'userId': data['userId'],
          'name': data['userName'] ?? strings.unknownUser,
          'email': data['userEmail'] ?? strings.noEmail,
          'photoUrl': data['userPhotoUrl'],
          'requestDate': (data['requestTimestamp'] as Timestamp).toDate(),
          'message': data['message'],
        });
      }
      
      // Ordenar por fecha (más reciente primero)
      requests.sort((a, b) => 
        (b['requestDate'] as DateTime).compareTo(a['requestDate'] as DateTime)
      );
      
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro carregando solicitações pendentes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.errorLoadingData(e.toString()))),
        );
      }
    }
  }

  Future<void> _acceptRequest(String userId, String requestId) async {
    final strings = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });

    try {
      // Aceptar solicitud en el ministerio
      await _ministryService.acceptJoinRequest(userId, widget.ministry.id);

      // Enviar notificación al usuario
      if (mounted) {
        try {
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          await notificationService.sendMinistryJoinRequestAcceptedNotification(
            userId: userId,
            ministryId: widget.ministry.id,
            ministryName: widget.ministry.name,
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
      // Rechazar solicitud en el ministerio
      await _ministryService.rejectJoinRequest(userId, widget.ministry.id);
      
      // Enviar notificación al usuario
      if (mounted) {
        try {
          final notificationService = Provider.of<NotificationService>(context, listen: false);
          await notificationService.sendMinistryJoinRequestRejectedNotification(
            userId: userId,
            ministryId: widget.ministry.id,
            ministryName: widget.ministry.name,
          );
        } catch (e) {
          print('Error enviando notificación de rechazo: $e');
        }
      }
      
      // Actualizar la lista localmente
      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((req) => req['userId'] == userId);
          _rejectedRequests++;
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.requestRejected),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorLoadingData(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _inviteUserToMinistry(String userId) async {
    try {
      await _ministryService.inviteUserToMinistry(userId, widget.ministry.id);
    } catch (e) {
      print('Erro ao enviar convite: $e');
      throw Exception('Erro ao enviar convite: $e');
    }
  }

  Future<void> _showAddUsersModal() async {
    if (!mounted) return;

    final strings = AppLocalizations.of(context)!;
    final selectedUsers = <String>{};
    final selectedFamilies = <String>{};
    List<Map<String, dynamic>> allUsers = [];
    List<Map<String, dynamic>> filteredUsers = [];
    List<Map<String, dynamic>> allFamilies = [];
    List<Map<String, dynamic>> filteredFamilies = [];

    final memberIds = widget.ministry.memberIds;

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

        allUsers.add({
          'id': doc.id,
          'name': userName,
          'email': userData['email'] ?? '',
          'photoUrl': userData['photoUrl'] ?? '',
          'isMember': isMember,
        });
      }

      filteredUsers = List<Map<String, dynamic>>.from(allUsers);

      final familiesSnapshot = await FirebaseFirestore.instance
          .collection('family_groups')
          .get();

      for (var doc in familiesSnapshot.docs) {
        final familyData = doc.data() as Map<String, dynamic>?;
        if (familyData == null) continue;

        final familyName = (familyData['name'] as String?)?.trim();
        final memberIdsRaw = familyData['memberIds'];
        final familyMemberIds = <String>[];
        if (memberIdsRaw is Iterable) {
          for (final entry in memberIdsRaw) {
            if (entry is String) {
              familyMemberIds.add(entry);
            } else if (entry is DocumentReference) {
              familyMemberIds.add(entry.id);
            }
          }
        }

        allFamilies.add({
          'id': doc.id,
          'name': familyName?.isNotEmpty == true
              ? familyName
              : strings.familyFallbackName,
          'photoUrl': familyData['photoUrl'] ?? '',
          'memberIds': familyMemberIds,
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
        useSafeArea: true,
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
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
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
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(strings.users),
                          selected: !showFamilies,
                          onSelected: (_) {
                            setModalState(() {
                              showFamilies = false;
                              updateFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(strings.familiesTitle),
                          selected: showFamilies,
                          onSelected: (_) {
                            setModalState(() {
                              showFamilies = true;
                              updateFilters();
                            });
                          },
                        ),
                      ],
                    ),
                    if (!showFamilies) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: showOnlyNonMembers,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setModalState(() {
                                showOnlyNonMembers = value ?? false;
                                updateFilters();
                              });
                            },
                          ),
                          Text(strings.showOnlyNonMembers),
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
                                    final isSelected =
                                        selectedFamilies.contains(family['id']);
                                    final members =
                                        (family['memberIds'] as List?)
                                            ?.cast<String>() ??
                                            <String>[];
                                    final photoUrl =
                                        family['photoUrl']?.toString();

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: photoUrl != null &&
                                                  photoUrl.isNotEmpty
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: photoUrl == null ||
                                                  photoUrl.isEmpty
                                              ? const Icon(Icons.family_restroom)
                                              : null,
                                        ),
                                        title: Text(
                                          family['name'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          strings.familyMembersCount(
                                            members.length,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: Checkbox(
                                          value: isSelected,
                                          activeColor: Colors.green,
                                          onChanged: (value) {
                                            setModalState(() {
                                              if (value == true) {
                                                selectedFamilies.add(family['id']);
                                              } else {
                                                selectedFamilies
                                                    .remove(family['id']);
                                              }
                                            });
                                          },
                                        ),
                                        onTap: () {
                                          setModalState(() {
                                            if (isSelected) {
                                              selectedFamilies
                                                  .remove(family['id']);
                                            } else {
                                              selectedFamilies.add(family['id']);
                                            }
                                          });
                                        },
                                      ),
                                    );
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
                                        await _inviteUserToMinistry(userId);
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

                                    _loadPendingRequests();
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
              );
            },
          );
        },
      );

      if (mounted) {
        _loadPendingRequests();
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
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
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
              _loadPendingRequests();
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
                // Panel de estadísticas (visible/oculto)
                if (_showStats)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.requestStatistics,
                          style: const TextStyle(
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
                              AppColors.primary,
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
        onPressed: _showAddUsersModal,
        tooltip: AppLocalizations.of(context)!.addUsers,
        backgroundColor: AppColors.primary,
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
    if (_pendingRequests.isEmpty) {
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
                        AppLocalizations.of(context)!.noPendingRequests,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.allUpToDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppColors.primary,
      child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Mostrar más detalles si es necesario
              },
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
                              backgroundImage: request['photoUrl'] != null
                                  ? NetworkImage(request['photoUrl'])
                                  : null,
                              child: request['photoUrl'] == null
                              ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            
                            // Información del usuario
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request['email'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
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
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(request['requestDate']),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Mensaje si existe
                    if (request['message'] != null && request['message'].toString().isNotEmpty)
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
                              '${AppLocalizations.of(context)!.message}:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request['message'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Botones de acción
                            Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                        TextButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: Text(AppLocalizations.of(context)!.reject),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _rejectRequest(request['userId'], request['id']),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                          label: Text(AppLocalizations.of(context)!.accept),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _acceptRequest(request['userId'], request['id']),
                                ),
                              ],
                            ),
                          ],
                ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
  
  Widget _buildRequestsHistoryTab(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('membership_requests')
          .where('entityId', isEqualTo: widget.ministry.id)
          .where('entityType', isEqualTo: 'ministry')
          .where('status', isEqualTo: status)
          .orderBy('requestTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(AppLocalizations.of(context)!.errorLoadingData(snapshot.error.toString())),
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
            final String inviterName = invitedByName ?? addedByName ?? AppLocalizations.of(context)!.administrator;
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
                        
                        // Información del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? AppLocalizations.of(context)!.unknownUser,
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

  Widget _buildExitedMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('member_exits')
          .where('entityId', isEqualTo: widget.ministry.id)
          .where('entityType', isEqualTo: 'ministry')
          .orderBy('exitTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(AppLocalizations.of(context)!.errorLoadingData(snapshot.error.toString())),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
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
            
            final DateTime exitDate = (data['exitTimestamp'] as Timestamp).toDate();
            final DateTime? joinDate = data['joinTimestamp'] != null 
                ? (data['joinTimestamp'] as Timestamp).toDate() 
                : null;
            
            // Calcular el tiempo que el usuario estuvo en el ministerio
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
                        
                        // Información del usuario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? AppLocalizations.of(context)!.unknownUser,
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
                                    'Tempo no ministério: ${_formatDuration(membershipDuration)}',
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
                                String adminName = AppLocalizations.of(context)!.administrator;
                                
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final adminData = snapshot.data!.data() as Map<String, dynamic>;
                                  adminName = adminData['name'] ?? AppLocalizations.of(context)!.administrator;
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
}

// Necesario para la pestaña de historial
final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
