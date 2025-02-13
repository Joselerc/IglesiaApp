import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/group_event.dart';
import 'package:intl/intl.dart';

class GroupEventDetailScreen extends StatelessWidget {
  final GroupEvent event;

  const GroupEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del evento
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  // Fecha y hora
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(event.date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('h:mm a').format(event.date),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Creador del evento
                  StreamBuilder<DocumentSnapshot>(
                    stream: event.createdBy.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading creator...');
                      }
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      return Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Created by ${userData?['name'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Grupo al que pertenece
                  StreamBuilder<DocumentSnapshot>(
                    stream: event.groupId.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading group...');
                      }
                      final groupData = snapshot.data!.data() as Map<String, dynamic>?;
                      return Row(
                        children: [
                          const Icon(Icons.group, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            groupData?['name'] ?? 'Unknown Group',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Descripción
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Attendees',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: event.attendees.map((ref) => ref.id).toList())
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading attendees...');
                      }

                      final attendees = snapshot.data!.docs;

                      if (attendees.isEmpty) {
                        return const Text('No attendees yet');
                      }

                      return Column(
                        children: attendees.map((doc) {
                          final userData = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(userData['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final userRef = FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid);

            final isAttending = event.attendees.contains(userRef);

            return ElevatedButton(
              onPressed: () async {
                final eventRef = FirebaseFirestore.instance
                    .collection('group_events')
                    .doc(event.id);

                if (isAttending) {
                  await eventRef.update({
                    'attendees': FieldValue.arrayRemove([userRef])
                  });
                } else {
                  await eventRef.update({
                    'attendees': FieldValue.arrayUnion([userRef])
                  });
                }
              },
              child: Text(isAttending ? 'Leave Event' : 'Join Event'),
            );
          },
        ),
      ),
    );
  }
} 