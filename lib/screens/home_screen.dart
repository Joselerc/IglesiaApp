import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/announcement_model.dart';
import 'events/event_detail_screen.dart';
import 'announcements/announcement_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ministries/ministries_list_screen.dart';
import 'groups/groups_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con foto de perfil y nombre
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data?.data() != null) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>;
                            final name = userData['name'] as String?;
                            final surname = userData['surname'] as String?;
                            
                            if (name != null && surname != null) {
                              return Text(
                                '$name $surname',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                          }
                          
                          return const Text(
                            'username',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Banner de bienvenida
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[200],
                  child: const Text(
                    'Welcome! Click here to complete your info',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                // Sección de Anuncios
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Announcements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See More'),
                      ),
                    ],
                  ),
                ),

                // Lista horizontal de anuncios
                SizedBox(
                  height: 170,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('announcements')
                        .orderBy('date', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final announcements = snapshot.data!.docs
                          .map((doc) => AnnouncementModel.fromFirestore(doc))
                          .toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnnouncementDetailScreen(
                                    announcement: announcement,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 160,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(
                                        announcement.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Image.network(
                                      announcement.imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image, size: 50),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('MM/dd/yyyy').format(announcement.date),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.notifications_outlined),
                                            onPressed: () {},
                                            iconSize: 16,
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
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

                // Espacio adicional antes de Ministries & Groups
                const SizedBox(height: 24),

                // Sección de Ministries & Groups
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MinistriesListScreen(),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.people_outline, size: 40),
                                  SizedBox(height: 8),
                                  Text('Ministries'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GroupsListScreen(),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.group_outlined, size: 40),
                                  SizedBox(height: 8),
                                  Text('Groups'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Espacio adicional antes de Prayer
                const SizedBox(height: 24),

                // Sección de Prayer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Private Prayer',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text('Ask for prayer'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {},
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'Public Prayer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('See what prayers are being\nwaited for the day'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Espacio adicional antes de Events
                const SizedBox(height: 24),

                // Sección de Events
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See More'),
                      ),
                    ],
                  ),
                ),

                // Lista horizontal de eventos
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .orderBy('date')
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final events = snapshot.data!.docs
                          .map((doc) => EventModel.fromFirestore(doc))
                          .toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailScreen(
                                    event: event,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 280,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 180,
                                      width: 280,
                                      child: Image.network(
                                        event.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 50),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                DateFormat('MM/dd/yyyy').format(event.date),
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.notifications_outlined),
                                                onPressed: () {},
                                                iconSize: 20,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            event.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            event.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
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

                // Espacio adicional antes de Request Counseling
                const SizedBox(height: 24),

                // Sección de Request Counseling
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.support_agent, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Request Counseling',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Need guidance? We\'re here to help.\nRequest a session anytime.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Book Counseling'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
