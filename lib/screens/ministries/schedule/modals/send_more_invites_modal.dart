import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/work_schedule.dart';

class SendMoreInvitesModal extends StatefulWidget {
  final WorkSchedule schedule;
  final String ministryId;

  const SendMoreInvitesModal({
    super.key,
    required this.schedule,
    required this.ministryId,
  });

  @override
  State<SendMoreInvitesModal> createState() => _SendMoreInvitesModalState();
}

class _SendMoreInvitesModalState extends State<SendMoreInvitesModal> {
  final Set<DocumentReference> _selectedWorkers = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Verificar si ya tenemos el número requerido de trabajadores
    final bool isFullyStaffed = widget.schedule.acceptedWorkersCount >= widget.schedule.requiredWorkers;

    // Si ya está completo, mostrar un mensaje en lugar del modal
    if (isFullyStaffed) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'All positions filled',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This schedule already has all required workers (${widget.schedule.requiredWorkers})',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    }

    // Si no está completo, mostrar el modal normal
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title and Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Select Workers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Select All
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ministries')
                .doc(widget.ministryId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final ministryData = snapshot.data!.data() as Map<String, dynamic>;
              final members = (ministryData['members'] as List?)?.map((member) {
                if (member is DocumentReference) {
                  return member;
                } else if (member is Map) {
                  return FirebaseFirestore.instance.collection('users').doc(member['id']);
                }
                return FirebaseFirestore.instance.collection('users').doc(member.toString().split('/').last);
              }).toList() ?? [];

              // Primero, en el filtrado inicial, incluir TODOS excepto aceptados
              final eligibleMembers = members.where((memberRef) {
                final status = widget.schedule.workersStatus[memberRef];
                return status != 'accepted';  // Solo excluir los aceptados
              }).toList();

              return Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Select All'),
                    value: _selectedWorkers.length == eligibleMembers.length,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedWorkers.clear();
                          _selectedWorkers.addAll(eligibleMembers);
                        } else {
                          _selectedWorkers.clear();
                        }
                      });
                    },
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          ),
          // Workers list
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ministries')
                  .doc(widget.ministryId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ministryData = snapshot.data!.data() as Map<String, dynamic>;
                final members = (ministryData['members'] as List?)?.map((member) {
                  if (member is DocumentReference) {
                    return member;
                  } else if (member is Map) {
                    return FirebaseFirestore.instance.collection('users').doc(member['id']);
                  }
                  return FirebaseFirestore.instance.collection('users').doc(member.toString().split('/').last);
                }).toList() ?? [];

                // Primero, en el filtrado inicial, incluir TODOS excepto aceptados
                final eligibleMembers = members.where((memberRef) {
                  final status = widget.schedule.workersStatus[memberRef];
                  return status != 'accepted';  // Solo excluir los aceptados
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: eligibleMembers.length,
                  itemBuilder: (context, index) {
                    final memberRef = eligibleMembers[index];
                    final status = widget.schedule.workersStatus[memberRef];

                    return FutureBuilder<DocumentSnapshot>(
                      future: memberRef.get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();

                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final displayName = userData['displayName'] ?? 'Unknown';
                        final photoUrl = userData['photoUrl'] as String?;

                        if (_searchQuery.isNotEmpty &&
                            !displayName.toLowerCase().contains(_searchQuery.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: photoUrl == null || photoUrl.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'pending')
                                const Icon(Icons.pending, color: Colors.orange, size: 20)
                              else if (status == 'cancelled')
                                const Icon(Icons.cancel, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: _selectedWorkers.contains(memberRef),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedWorkers.add(memberRef);
                                    } else {
                                      _selectedWorkers.remove(memberRef);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Send invites button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: ElevatedButton(
              onPressed: _selectedWorkers.isEmpty
                  ? null
                  : () async {
                      try {
                        final scheduleRef = FirebaseFirestore.instance
                            .collection('work_schedules')
                            .doc(widget.schedule.id);

                        await FirebaseFirestore.instance.runTransaction((transaction) async {
                          final doc = await transaction.get(scheduleRef);
                          final currentSchedule = WorkSchedule.fromFirestore(doc);

                          // Convertir las referencias a paths con el formato correcto
                          final updatedStatus = Map<String, String>.from(
                            currentSchedule.workersStatus.map((key, value) => MapEntry(key.path, value))
                          );
                          for (final workerRef in _selectedWorkers) {
                            updatedStatus[workerRef.path] = 'pending';
                          }

                          // Mantener las referencias para invitedWorkers
                          final updatedWorkers = Set<DocumentReference>.from(currentSchedule.invitedWorkers)
                            ..addAll(_selectedWorkers);

                          transaction.update(scheduleRef, {
                            'invitedWorkers': updatedWorkers.toList(),
                            'workersStatus': updatedStatus,
                          });
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invitations sent successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error sending invitations: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedWorkers.isEmpty 
                    ? 'Select Workers to Invite'
                    : 'Send ${_selectedWorkers.length == 1 ? '1 Invitation' : '${_selectedWorkers.length} Invitations'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
} 