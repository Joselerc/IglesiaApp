import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class CreateGroupModal extends StatefulWidget {
  const CreateGroupModal({super.key});

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<DocumentReference> _selectedAdmins = [];

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Create Group'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}