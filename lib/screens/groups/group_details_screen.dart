import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group.dart';
import '../../widgets/circular_image_picker.dart';
import '../ministries/image_viewer_screen.dart';
import '../../services/group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../modals/edit_entity_info_modal.dart';
import '../../l10n/app_localizations.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool notificationsEnabled = true;
  bool isAdmin = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _descriptionText = '';
  
  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(currentUser.uid)
            .collection('group_notifications')
            .doc(widget.group.id)
            .get();
        
        if (doc.exists) {
          setState(() {
            notificationsEnabled = doc.data()?['enabled'] ?? true;
          });
        }
      } catch (e) {
        print('Error al cargar configuración de notificaciones: $e');
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('user_settings')
            .doc(currentUser.uid)
            .collection('group_notifications')
            .doc(widget.group.id)
            .set({
              'enabled': value,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        
        setState(() {
          notificationsEnabled = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? AppLocalizations.of(context)!.notificationsEnabled : AppLocalizations.of(context)!.notificationsDisabled,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error al actualizar configuración de notificaciones: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingNotificationSettings),
          ),
        );
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        isAdmin = widget.group.adminIds.contains(currentUser.uid);
      });
    }
  }

  Future<void> _leaveGroup() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (isAdmin && widget.group.adminIds.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotLeaveAsOnlyAdmin),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.leaveGroup),
        content: Text(AppLocalizations.of(context)!.areYouSureLeaveGroup),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.leave),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final groupService = GroupService();
      
      await groupService.recordMemberExit(
        currentUser.uid, 
        widget.group.id,
        reason: 'Saída voluntária'
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.youLeftTheGroup))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLeavingGroup}: $e')),
        );
      }
    }
  }

  Future<void> _deleteGroup() async {
    if (!isAdmin) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteGroup),
        content: Text(AppLocalizations.of(context)!.areYouSureDeleteGroup),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .delete();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.groupDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingGroup}: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId, String userName) async {
    if (!isAdmin) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeMember),
        content: Text('${AppLocalizations.of(context)!.areYouSureLeaveGroup.replaceAll('deseja sair deste grupo', 'deseja remover $userName del grupo')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final groupService = GroupService();
      
      await groupService.removeMember(
        userId,
        widget.group.id,
        currentUser.uid,
        reason: 'Removido pelo administrador'
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.memberRemovedFromGroup)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorRemovingMember}: $e')),
      );
    }
  }

  Future<void> _showMakeAdminConfirmation(String userId, String userName) async {
    if (!isAdmin) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmMakeAdmin),
        content: Text(AppLocalizations.of(context)!.confirmMakeGroupAdmin(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _makeGroupAdmin(userId, userName);
    }
  }

  Future<void> _makeGroupAdmin(String userId, String userName) async {
    if (!isAdmin) return;

    try {
      final groupService = GroupService();
      
      await groupService.promoteToAdmin(
        userId,
        widget.group.id,
        reason: 'Promovido por administrador'
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.userIsNowGroupAdmin(userName))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorMakingGroupAdmin}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFile(String fileUrl, String fileName, String fileType) {
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(fileUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida en _openFile: $fileUrl');
      isValidUrl = false;
    }

    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotOpenInvalidFileUrl)),
      );
      return;
    }

    if (fileType == 'image') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imageUrl: fileUrl,
            fileName: fileName,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.downloadFile),
          content: Text('${AppLocalizations.of(context)!.areYouSureLeaveGroup.split('?')[0].replaceAll('Tem certeza de que deseja sair deste grupo', 'Deseja baixar')} "$fileName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.download),
            ),
          ],
        ),
      );
    }
  }

  Widget _getFileIcon(String fileType, String fileUrl, String fileName) {
    bool isValidUrl = false;
    try {
      final uri = Uri.parse(fileUrl);
      isValidUrl = uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      print('URL inválida: $fileUrl');
      isValidUrl = false;
    }

    switch (fileType) {
      case 'image':
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: isValidUrl 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image, color: Colors.grey, size: 40),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 40),
              ),
        );
      case 'pdf':
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
          ),
        );
      case 'video':
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.videocam, color: Colors.blue, size: 40),
          ),
        );
      case 'document':
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.description, color: Colors.green, size: 40),
          ),
        );
      case 'link':
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.link, color: Colors.purple, size: 40),
          ),
        );
      default:
        return Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.groupInformation),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.group.id)
                      .snapshots(),
                  builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(AppLocalizations.of(context)!.thisGroupNoLongerExists));
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final groupImageUrl = groupData['imageUrl'] as String? ?? '';
          final groupName = groupData['name'] as String? ?? 'Grupo sem nome';
          final groupDescriptionDelta = groupData['descriptionDelta'];
          _extractDescriptionText(groupDescriptionDelta);
          
          final List<String> adminIds = _getAdminIds(groupData);
          final bool currentIsAdmin = adminIds.contains(FirebaseAuth.instance.currentUser?.uid ?? '');
          
          final List<String> memberIds = _getMemberIds(groupData);
          final bool hasDescription = _descriptionText.isNotEmpty && _descriptionText != '(Descrição Vazia)';
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: theme.primaryColor.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'group_image_${widget.group.id}',
                          child: CircularImagePicker(
                            size: 110,
                            documentId: widget.group.id,
                            currentImageUrl: groupImageUrl,
                            storagePath: 'group_images',
                            collectionName: 'groups',
                            fieldName: 'imageUrl',
                            defaultIcon: const Icon(Icons.group, size: 50, color: Colors.white),
                            isEditable: currentIsAdmin,
                            showEditIconOutside: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            groupName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${AppLocalizations.of(context)!.group} · ${memberIds.length} ${AppLocalizations.of(context)!.members}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: currentIsAdmin ? () async { 
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditEntityInfoModal(
                                entityId: widget.group.id,
                                entityType: EntityType.group,
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                        } : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDescription)
                                Text(_descriptionText, style: AppTextStyles.bodyText1)
                              else if (currentIsAdmin)
                                Text(
                                  AppLocalizations.of(context)!.addDescription,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (currentIsAdmin && hasDescription) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.edit, size: 16, color: theme.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)!.edit,
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_getCreatorId(groupData['createdBy']))
                            .get(),
                        builder: (context, snapshot) {
                          String creatorName = AppLocalizations.of(context)!.unknown;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            if (userData != null) {
                              creatorName = userData['name'] ?? userData['displayName'] ?? AppLocalizations.of(context)!.unknown;
                            }
                          }
                          
                          return Text(
                            '${AppLocalizations.of(context)!.createdBy} $creatorName · ${_formatDate(groupData['createdAt'] as Timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.filesLinksAndDocuments,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('group_chat_messages')
                            .where('groupId', isEqualTo: FirebaseFirestore.instance.collection('groups').doc(widget.group.id))
                            .where('fileUrl', isNull: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final fileCount = snapshot.hasData ? snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return data['fileUrl'] != null && data['fileUrl'].toString().isNotEmpty && 
                                   (data['fileType'] != 'audio');
                          }).length : 0;
                          return Text(
                            '$fileCount',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(
                  height: 100,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                    .collection('group_chat_messages')
                        .where('groupId', isEqualTo: FirebaseFirestore.instance.collection('groups').doc(widget.group.id))
                    .where('fileUrl', isNull: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.noSharedFiles,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }
                      
                      final fileMessages = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['fileUrl'] != null && 
                               data['fileUrl'].toString().isNotEmpty && 
                               (data['fileType'] != 'audio');
                      }).toList();
                      
                      if (fileMessages.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.noSharedFiles,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: fileMessages.length,
                        itemBuilder: (context, index) {
                          final fileData = fileMessages[index].data() as Map<String, dynamic>;
                          final fileName = fileData['fileName'] as String? ?? 'Arquivo';
                          final fileUrl = fileData['fileUrl'] as String? ?? '';
                          final fileType = fileData['fileType'] as String? ?? 'unknown';
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => _openFile(fileUrl, fileName, fileType),
                              child: Column(
                                children: [
                                  _getFileIcon(fileType, fileUrl, fileName),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      fileName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                const Divider(),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${memberIds.length} ${AppLocalizations.of(context)!.members}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.searchMember,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                FutureBuilder<List<DocumentSnapshot>>(
                  future: _loadGroupMembers(memberIds),
                  builder: (context, snapshot) {
                    print('===== DIAGNÓSTICO CARGA DE MIEMBROS =====');
                    print('Cantidad de memberIds: ${memberIds.length}');
                    print('memberIds: $memberIds');
                    
                    if (snapshot.hasError) {
                      print('Error en la consulta: ${snapshot.error}');
                      print('Error stack trace: ${snapshot.stackTrace}');
                      return Center(
                        child: Text('${AppLocalizations.of(context)!.errorLoadingMembers}: ${snapshot.error}'),
                      );
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('Estado: Cargando...');
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      print('Estado: No hay datos o lista vacía');
                      return Center(child: Text(AppLocalizations.of(context)!.noMemberFound));
                    }
                    
                    final members = snapshot.data!;
                    print('Miembros encontrados: ${members.length}');
                    print('======================================');
                    
                    final filteredMembers = _searchQuery.isEmpty
                        ? members
                        : members.where((doc) {
                            final userData = doc.data() as Map<String, dynamic>;
                            final userName = userData['name'] ?? userData['displayName'] ?? '';
                            final userEmail = userData['email'] ?? '';
                            return userName.toLowerCase().contains(_searchQuery) ||
                                   userEmail.toLowerCase().contains(_searchQuery);
                          }).toList();
                    
                    if (filteredMembers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppLocalizations.of(context)!.noMembersMatchingSearch(_searchQuery),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final memberDoc = filteredMembers[index];
                        final memberId = memberDoc.id;
                        final userData = memberDoc.data() as Map<String, dynamic>;
                        final name = userData['name'] ?? userData['displayName'] ?? AppLocalizations.of(context)!.unknown;
                        final photoUrl = userData['photoUrl'] ?? '';
                        final isCurrentUser = memberId == FirebaseAuth.instance.currentUser?.uid;
                        final isMemberAdmin = adminIds.contains(memberId);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isCurrentUser ? AppLocalizations.of(context)!.you : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMemberAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.groupAdmin,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(AppLocalizations.of(context)!.available),
                          onTap: currentIsAdmin && !isCurrentUser ? () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                                      title: Text(AppLocalizations.of(context)!.makeGroupAdmin),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showMakeAdminConfirmation(memberId, name);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      title: Text('${AppLocalizations.of(context)!.remove} $name'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _removeMember(memberId, name);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } : null,
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.exit_to_app),
                          label: Text(AppLocalizations.of(context)!.leaveGroup),
                          onPressed: _leaveGroup,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (currentIsAdmin) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            label: Text(AppLocalizations.of(context)!.deleteGroup, style: const TextStyle(color: Colors.red)),
                            onPressed: _deleteGroup,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return AppLocalizations.of(context)!.today;
    }
  }

  String _getCreatorId(dynamic creatorValue) {
    if (creatorValue is DocumentReference) {
      return creatorValue.id;
    }
    
    if (creatorValue is Map && creatorValue['path'] != null) {
      final path = creatorValue['path'] as String;
      final parts = path.split('/');
      return parts.isNotEmpty ? parts.last : '';
    }
    
    if (creatorValue is String) {
      return creatorValue;
    }
    
    return '';
  }

  void _extractDescriptionText(dynamic descriptionData) {
    if (descriptionData is List || descriptionData is Map) {
      try {
        if (descriptionData is List) {
           _descriptionText = descriptionData
              .map((op) => op is Map ? op['insert'] as String? ?? '' : '')
              .join('')
              .replaceAll('\n', ' \n')
              .trim();
        } else if (descriptionData is Map) {
           _descriptionText = descriptionData['insert'] as String? ?? '';
        }
        if (_descriptionText.isEmpty) _descriptionText = '(Descrição Vazia)';

      } catch (e) {
        print('Error extrayendo texto de descriptionDelta: $e');
        _descriptionText = '(Erro ao carregar descrição)';
      }
    } else if (descriptionData is String) {
       _descriptionText = descriptionData;
    } else {
      _descriptionText = '';
    }
  }

  List<String> _getMemberIds(Map<String, dynamic> groupData) {
    List<String> memberIds = [];
    if (groupData['members'] != null) {
      if (groupData['members'] is List) {
        memberIds = (groupData['members'] as List).map<String>((member) {
          if (member is DocumentReference) return member.id;
          if (member is Map && member['path'] != null) {
            final path = member['path'] as String;
            final parts = path.split('/');
            return parts.isNotEmpty ? parts.last : '';
          }
          if (member is String) return member;
          return '';
        }).where((id) => id.isNotEmpty).toList();
      } else if (groupData['members'] is Map) {
        memberIds = (groupData['members'] as Map).keys.toList().cast<String>();
      }
    }
    return memberIds;
  }

  List<String> _getAdminIds(Map<String, dynamic> groupData) {
    List<String> adminIds = [];
    if (groupData['groupAdmin'] != null) {
      if (groupData['groupAdmin'] is List) {
        adminIds = (groupData['groupAdmin'] as List).map<String>((admin) {
          if (admin is DocumentReference) return admin.id;
          if (admin is Map && admin['path'] != null) {
            final path = admin['path'] as String;
            final parts = path.split('/');
            return parts.isNotEmpty ? parts.last : '';
          }
          if (admin is String) return admin;
          return '';
        }).where((id) => id.isNotEmpty).toList();
      } else if (groupData['groupAdmin'] is Map) {
        adminIds = (groupData['groupAdmin'] as Map).keys.toList().cast<String>();
      }
    }
    return adminIds;
  }

  Future<List<DocumentSnapshot>> _loadGroupMembers(List<String> memberIds) async {
    if (memberIds.isEmpty) return [];
    
    List<DocumentSnapshot> memberDocs = [];
    
    for (String memberId in memberIds) {
      try {
        print('Cargando usuario con ID: $memberId');
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        
        if (doc.exists) {
          memberDocs.add(doc);
        } else {
          print('Usuario no encontrado: $memberId');
        }
      } catch (e) {
        print('Error al cargar usuario $memberId: $e');
      }
    }
    
    return memberDocs;
  }
} 