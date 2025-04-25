import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectWorkersModal extends StatefulWidget {
  final String ministryId;
  final List<String> selectedWorkers;
  final Function(List<String>) onWorkersSelected;

  const SelectWorkersModal({
    super.key,
    required this.ministryId,
    required this.selectedWorkers,
    required this.onWorkersSelected,
  });

  @override
  State<SelectWorkersModal> createState() => _SelectWorkersModalState();
}

class _SelectWorkersModalState extends State<SelectWorkersModal> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedWorkers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedWorkers = List.from(widget.selectedWorkers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Trabajadores'),
        actions: [
          TextButton.icon(
            onPressed: () {
              widget.onWorkersSelected(_selectedWorkers);
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.check),
            label: const Text('Listo'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar miembros...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Lista horizontal de seleccionados
          if (_selectedWorkers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedWorkers.length} trabajadores seleccionados',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedWorkers.length > 1)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedWorkers.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Borrar todos'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedWorkers.map((workerId) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(workerId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text('Cargando...'),
                                  avatar: CircleAvatar(
                                    child: CircularProgressIndicator(strokeWidth: 1),
                                  ),
                                ),
                              );
                            }
                            
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            if (userData == null) return const SizedBox.shrink();
                            
                            final name = userData['name'] ?? userData['displayName'] ?? 'Usuario';
                            final photoUrl = userData['photoUrl'] ?? '';
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                avatar: CircleAvatar(
                                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                  child: photoUrl.isEmpty ? const Icon(Icons.person, size: 16) : null,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                                label: Text(name),
                                labelStyle: const TextStyle(fontSize: 12),
                                deleteIconColor: Colors.red,
                                onDeleted: () {
                                  setState(() {
                                    _selectedWorkers.remove(workerId);
                                  });
                                },
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.grey.shade300),
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Lista de miembros
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('ministryIds', arrayContains: widget.ministryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay miembros disponibles',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No se encontraron resultados',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text('Limpiar búsqueda'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = doc.id;
                    final name = data['name'] ?? data['displayName'] ?? 'Usuario';
                    final email = data['email'] ?? '';
                    final photoUrl = data['photoUrl'] ?? '';
                    final isSelected = _selectedWorkers.contains(userId);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      title: Text(name),
                      subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isSelected) {
                              _selectedWorkers.remove(userId);
                            } else {
                              _selectedWorkers.add(userId);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedWorkers.remove(userId);
                          } else {
                            _selectedWorkers.add(userId);
                          }
                        });
                      },
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
    super.dispose();
  }
} 