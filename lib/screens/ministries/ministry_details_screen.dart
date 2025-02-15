import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ministry.dart';
import '../../models/ministry_event.dart';
import '../ministries/ministry_event_detail_screen.dart';
import '../groups/widgets/edit_description_dialog.dart';
import '../../../modals/create_event_modal.dart';
import '../../widgets/circular_image_picker.dart';

class MinistryDetailsScreen extends StatefulWidget {
  final Ministry ministry;

  const MinistryDetailsScreen({
    super.key,
    required this.ministry,
  });

  @override
  State<MinistryDetailsScreen> createState() => _MinistryDetailsScreenState();
}

class _MinistryDetailsScreenState extends State<MinistryDetailsScreen> {
  bool notificationsEnabled = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      setState(() {
        isAdmin = widget.ministry.ministrieAdmin.contains(userRef);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ministries')
                        .doc(widget.ministry.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final ministryData = snapshot.data!.data() as Map<String, dynamic>;
                      final currentImageUrl = ministryData['imageUrl'] as String? ?? '';

                      return CircularImagePicker(
                        documentId: widget.ministry.id,
                        currentImageUrl: currentImageUrl,
                        storagePath: 'ministry_images',
                        collectionName: 'ministries',
                        fieldName: 'imageUrl',
                        defaultIcon: const Icon(Icons.church, size: 60),
                        isEditable: isAdmin,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.ministry.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: widget.ministry.members.map((ref) => ref.id).toList())
                        .snapshots(),
                    builder: (context, snapshot) {
                      final memberCount = snapshot.hasData ? snapshot.data!.size : 0;
                      return Text(
                        'Ministry - $memberCount members',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Descripción
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ministries')
                    .doc(widget.ministry.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading...');
                  }

                  final ministryData = snapshot.data!.data() as Map<String, dynamic>;
                  final description = ministryData['description'] as String? ?? '';

                  return GestureDetector(
                    onTap: isAdmin ? () async {
                      final newDescription = await showDialog<String>(
                        context: context,
                        builder: (context) => EditDescriptionDialog(
                          initialDescription: description,
                        ),
                      );

                      if (newDescription != null) {
                        await FirebaseFirestore.instance
                            .collection('ministries')
                            .doc(widget.ministry.id)
                            .update({'description': newDescription});
                      }
                    } : null,
                    child: Text(
                      description.isEmpty 
                          ? 'Add ministry description'
                          : description,
                      style: TextStyle(
                        color: description.isEmpty && isAdmin ? Colors.blue : null,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Eventos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAdmin) IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => CreateEventModal(
                              ministry: widget.ministry,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ministry_events')
                          .where('ministryId', isEqualTo: FirebaseFirestore.instance.collection('ministries').doc(widget.ministry.id))
                          .orderBy('date')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final events = snapshot.data!.docs;
                        
                        if (events.isEmpty) {
                          return const Center(
                            child: Text('No events yet'),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = MinistryEvent.fromFirestore(events[index]);
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MinistryEventDetailScreen(
                                      event: event,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(right: 8),
                                child: Container(
                                  width: 150,
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.date.toString().split(' ')[0],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Notificaciones
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Ministry Notifications'),
              trailing: Switch(
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                },
              ),
            ),

            // Lista de miembros
            Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: widget.ministry.members.map((ref) => ref.id).toList())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${members.length} members',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index].data() as Map<String, dynamic>;
                            final memberId = members[index].id;
                            final isCurrentUser = memberId == FirebaseAuth.instance.currentUser?.uid;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: member['photoUrl'] != null && member['photoUrl'].toString().isNotEmpty
                                    ? NetworkImage(member['photoUrl'])
                                    : null,
                                child: member['photoUrl'] == null || member['photoUrl'].toString().isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                isCurrentUser ? 'You' : member['name'] ?? 'Unknown',
                              ),
                              trailing: widget.ministry.ministrieAdmin.contains(members[index].reference)
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Ministry Admin',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.exit_to_app, color: Colors.red),
                    label: const Text('Exit ministry'),
                    onPressed: () async {
                      final userRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid);
                      
                      await FirebaseFirestore.instance
                          .collection('ministries')
                          .doc(widget.ministry.id)
                          .update({
                            'members': FieldValue.arrayRemove([userRef])
                          });
                      
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.flag, color: Colors.orange),
                    label: const Text('Report Ministry'),
                    onPressed: () {
                      // TODO: Implementar la lógica para reportar el ministerio
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  if (isAdmin) TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete Ministry'),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Ministry'),
                          content: const Text('Are you sure you want to delete this ministry? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await FirebaseFirestore.instance
                            .collection('ministries')
                            .doc(widget.ministry.id)
                            .delete();
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}