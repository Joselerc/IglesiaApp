import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import 'group_feed_screen.dart';
import '../../modals/create_group_modal.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  String _searchQuery = '';

  List<Group> _filterGroups(List<Group> groups) {
    if (_searchQuery.isEmpty) return groups;
    return groups.where((group) => 
      group.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showCreateGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const CreateGroupModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Groups'),
            TextButton(
              onPressed: _showCreateGroupModal,
              child: const Text(
                '+ New Group',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final groups = snapshot.data!.docs.map((doc) => 
                  Group.fromFirestore(doc)
                ).toList();

                final filteredGroups = _filterGroups(groups);

                if (filteredGroups.isEmpty) {
                  return const Center(
                    child: Text('No groups found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    final userRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid);
                    final isMember = group.members.contains(userRef);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(group.imageUrl),
                        onBackgroundImageError: (_, __) => const Icon(Icons.group),
                      ),
                      title: Text(group.name),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupFeedScreen(group: group),
                            ),
                          );
                        },
                        child: Text(isMember ? 'Enter' : 'Solicit to Join'),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Groups',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('members', arrayContains: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userGroups = snapshot.data!.docs.map((doc) => 
                  Group.fromFirestore(doc)
                ).toList();

                if (userGroups.isEmpty) {
                  return const Center(
                    child: Text(
                      'You are not a member of any group yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: userGroups.length,
                  itemBuilder: (context, index) {
                    final group = userGroups[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(group.imageUrl),
                        onBackgroundImageError: (_, __) => const Icon(Icons.group),
                      ),
                      title: Text(group.name),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupFeedScreen(group: group),
                            ),
                          );
                        },
                        child: const Text('Enter'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 