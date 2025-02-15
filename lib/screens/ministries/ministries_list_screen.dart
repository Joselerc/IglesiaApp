import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/ministry.dart';
import '../../services/auth_service.dart';
import 'ministry_feed_screen.dart';
import '../../modals/create_ministry_modal.dart';

class MinistriesListScreen extends StatefulWidget {
  const MinistriesListScreen({super.key});

  @override
  State<MinistriesListScreen> createState() => _MinistriesListScreenState();
}

class _MinistriesListScreenState extends State<MinistriesListScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  void _showCreateMinistryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const CreateMinistryModal(),
    );
  }

  List<Ministry> _filterMinistries(List<Ministry> ministries) {
    if (_searchQuery.isEmpty) return ministries;
    return ministries.where((ministry) => 
      ministry.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 