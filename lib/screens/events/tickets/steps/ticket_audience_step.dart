import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketAudienceStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const TicketAudienceStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<TicketAudienceStep> createState() => _TicketAudienceStepState();
}

class _TicketAudienceStepState extends State<TicketAudienceStep> {
  bool _isPublic = true;
  String? _selectedGroupId;
  bool _isUnlimited = true;
  final _ticketLimitController = TextEditingController();
  final _newGroupController = TextEditingController();

  @override
  void dispose() {
    _ticketLimitController.dispose();
    _newGroupController.dispose();
    super.dispose();
  }

  Future<void> _createNewGroup() async {
    if (_newGroupController.text.isEmpty) return;

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('audience_groups')
          .add({
            'name': _newGroupController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _selectedGroupId = docRef.id;
        _newGroupController.clear();
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: _newGroupController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            hintText: 'e.g., Church Members, Youth Group, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _createNewGroup,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (!_isPublic && _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a group')),
      );
      return;
    }

    if (!_isUnlimited && _ticketLimitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a ticket limit')),
      );
      return;
    }

    widget.onNext({
      'isPublic': _isPublic,
      'groupId': _selectedGroupId,
      'ticketLimit': _isUnlimited ? null : int.parse(_ticketLimitController.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Audience',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Sección de Permiso de Registro
          Text(
            'Registration Permission',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('Open to Public'),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Exclusive'),
              ),
            ],
            selected: {_isPublic},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isPublic = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 24),

          if (!_isPublic) ...[
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('audience_groups')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error loading groups');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final groups = snapshot.data?.docs ?? [];

                      return DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Select Group',
                        ),
                        items: groups.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(data['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGroupId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showCreateGroupDialog,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Sección de Límite de Tickets
          Text(
            'Ticket Limit per User',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('Unlimited'),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Limited'),
              ),
            ],
            selected: {_isUnlimited},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isUnlimited = newSelection.first;
              });
            },
          ),
          if (!_isUnlimited) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _ticketLimitController,
              decoration: const InputDecoration(
                labelText: 'Tickets per User',
                hintText: 'Enter maximum number of tickets',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: _handleNext,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 