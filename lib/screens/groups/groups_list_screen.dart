import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/group.dart';
import '../../services/auth_service.dart';
import 'group_feed_screen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<DocumentReference> _selectedAdmins = [];

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
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Group',
                      style: TextStyle(
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

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter group name',
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter group description',
                  ),
                  maxLength: 250,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', whereIn: ['admin', 'pastor'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final users = snapshot.data!.docs;

                    if (users.isEmpty) {
                      return const Text('No administrators available',
                          style: TextStyle(color: Colors.grey));
                    }

                    return FormField<List<DocumentReference>>(
                      initialValue: _selectedAdmins,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select at least one administrator';
                        }
                        return null;
                      },
                      builder: (FormFieldState<List<DocumentReference>> field) {
                        return InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select Administrators',
                            errorText: field.errorText,
                          ),
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SingleChildScrollView(
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final userData = users[index].data() as Map<String, dynamic>;
                                  final role = userData['role'] as String;
                                  final roleText = role == 'admin' ? '(Administrator)' : '(Pastor)';
                                  
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(
                                      '${userData['name']} $roleText',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    value: _selectedAdmins.contains(users[index].reference),
                                    onChanged: (bool? selected) {
                                      setState(() {
                                        if (selected == true) {
                                          _selectedAdmins.add(users[index].reference);
                                        } else {
                                          _selectedAdmins.remove(users[index].reference);
                                        }
                                        field.didChange(_selectedAdmins);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _createGroup,
                  child: const Text('Create Group'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = Provider.of<AuthService>(context, listen: false).currentUser;
        if (user == null) return;

        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        final group = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'imageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': userRef,
          'members': [userRef],
          'groupAdmin': _selectedAdmins,
        };

        await FirebaseFirestore.instance.collection('groups').add(group);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
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
            TextButton.icon(
              onPressed: _showCreateGroupModal,
              icon: const Icon(Icons.add, color: Colors.green),
              label: const Text(
                'New Group',
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