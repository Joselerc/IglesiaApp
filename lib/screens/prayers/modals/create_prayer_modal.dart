import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePrayerModal extends StatefulWidget {
  const CreatePrayerModal({super.key});

  @override
  State<CreatePrayerModal> createState() => _CreatePrayerModalState();
}

class _CreatePrayerModalState extends State<CreatePrayerModal> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPrayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);

      await FirebaseFirestore.instance.collection('prayers').add({
        'content': _contentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': userRef,
        'isAnonymous': _isAnonymous,
        'upVotedBy': [],
        'downVotedBy': [],
        'isAccepted': false,
        'acceptedBy': null,
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ask for prayer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _contentController,
              maxLength: 200,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your prayer request...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your prayer request';
                }
                if (value.length > 200) {
                  return 'Maximum 200 characters allowed';
                }
                return null;
              },
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
              ),
              const Text('Post anonymously'),
            ],
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}