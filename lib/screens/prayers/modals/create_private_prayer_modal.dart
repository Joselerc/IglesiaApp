import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePrivatePrayerModal extends StatefulWidget {
  const CreatePrivatePrayerModal({super.key});

  @override
  State<CreatePrivatePrayerModal> createState() => _CreatePrivatePrayerModalState();
}

class _CreatePrivatePrayerModalState extends State<CreatePrivatePrayerModal> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  DocumentReference? _selectedPastorId;
  final List<String> _preferredMethods = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPrayer() async {
    if (!_formKey.currentState!.validate() || _selectedPastorId == null || _preferredMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);

      await FirebaseFirestore.instance.collection('private_prayers').add({
        'pastorId': _selectedPastorId,
        'userId': userRef,
        'content': _contentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isAccepted': false,
        'preferredMethods': _preferredMethods,
        'selectedMethod': null,
        'scheduledAt': null,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating prayer')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, // 85% de la altura de la pantalla
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ask for private prayer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Pastor selector
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'pastor')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final pastors = snapshot.data!.docs;

                        return DropdownButtonFormField<DocumentReference>(
                          decoration: const InputDecoration(
                            labelText: 'Select Pastor',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedPastorId,
                          items: pastors.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.reference,
                              child: Text('Pastor ${data['name'] ?? 'Unknown'}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPastorId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a pastor';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Content field
                    TextFormField(
                      controller: _contentController,
                      maxLength: 400,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Prayer request',
                        hintText: 'Write your prayer request...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your prayer request';
                        }
                        if (value.length > 400) {
                          return 'Maximum 400 characters allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Contact methods
                    const Text(
                      'Preferred contact methods:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: const Text('Phone call'),
                      value: _preferredMethods.contains('call'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _preferredMethods.add('call');
                          } else {
                            _preferredMethods.remove('call');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('WhatsApp'),
                      value: _preferredMethods.contains('whatsapp'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _preferredMethods.add('whatsapp');
                          } else {
                            _preferredMethods.remove('whatsapp');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPrayer,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
              const SizedBox(height: 40), // Añadimos espacio extra al final
            ],
          ),
        ),
      ),
    );
  }
} 