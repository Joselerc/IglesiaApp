import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/ministry.dart';
import '../../services/auth_service.dart';
import 'ministry_feed_screen.dart';

class MinistriesListScreen extends StatefulWidget {
  const MinistriesListScreen({super.key});

  @override
  State<MinistriesListScreen> createState() => _MinistriesListScreenState();
}

class _MinistriesListScreenState extends State<MinistriesListScreen> {
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<DocumentReference> _selectedAdmins = [];

  List<Ministry> _filterMinistries(List<Ministry> ministries) {
    if (_searchQuery.isEmpty) return ministries;
    return ministries.where((ministry) => 
      ministry.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showCreateMinistryModal() {
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
                // Título del modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Ministry',
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

                // Campo nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ministry Name',
                    hintText: 'Enter ministry name',
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),

                // Campo descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter ministry description',
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

                // Selector de admins
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

                // Botón crear
                ElevatedButton(
                  onPressed: _createMinistry,
                  child: const Text('Create Ministry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createMinistry() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = Provider.of<AuthService>(context, listen: false).currentUser;
        if (user == null) return;

        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        final ministry = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'imageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': userRef,
          'members': [userRef],
          'ministrieAdmin': _selectedAdmins,
        };

        await FirebaseFirestore.instance.collection('ministries').add(ministry);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ministry created successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating ministry: $e')),
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
            const Text('Ministries'),
            TextButton.icon(
              onPressed: _showCreateMinistryModal,
              icon: const Icon(Icons.add, color: Colors.green),
              label: const Text(
                'New Ministry',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ministries...',
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
          
          // Lista de ministerios disponibles
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ministries').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ministries = snapshot.data!.docs.map((doc) => 
                  Ministry.fromMap(doc.data() as Map<String, dynamic>, doc.id)
                ).toList();

                final filteredMinistries = _filterMinistries(ministries);

                if (filteredMinistries.isEmpty) {
                  return const Center(
                    child: Text('No ministries found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredMinistries.length,
                  itemBuilder: (context, index) {
                    final ministry = filteredMinistries[index];
                    final isMember = ministry.members.contains(user?.uid);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: ministry.imageUrl.isNotEmpty 
                          ? NetworkImage(ministry.imageUrl)
                          : null,
                        child: ministry.imageUrl.isEmpty 
                          ? const Icon(Icons.group) 
                          : null,
                      ),
                      title: Text(ministry.name),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MinistryFeedScreen(ministry: ministry),
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

          // Sección "Your Ministries"
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Ministries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Lista de ministerios del usuario
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ministries')
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

                final userMinistries = snapshot.data!.docs.map((doc) => 
                  Ministry.fromMap(doc.data() as Map<String, dynamic>, doc.id)
                ).toList();

                if (userMinistries.isEmpty) {
                  return const Center(
                    child: Text(
                      'You are not a member of any ministry yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: userMinistries.length,
                  itemBuilder: (context, index) {
                    final ministry = userMinistries[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: ministry.imageUrl.isNotEmpty 
                          ? NetworkImage(ministry.imageUrl)
                          : null,
                        child: ministry.imageUrl.isEmpty 
                          ? const Icon(Icons.group) 
                          : null,
                      ),
                      title: Text(ministry.name),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MinistryFeedScreen(ministry: ministry),
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