import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/event_model.dart';
import './register_ticket_form.dart';

class RegisterEventModal extends StatefulWidget {
  final EventModel event;

  const RegisterEventModal({
    super.key,
    required this.event,
  });

  @override
  State<RegisterEventModal> createState() => _RegisterEventModalState();
}

class _RegisterEventModalState extends State<RegisterEventModal> {
  String? _selectedTicketId;

  Future<bool> _checkTicketAvailability(String ticketId) async {
    final ticketDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('tickets')
        .doc(ticketId)
        .get();

    final ticketData = ticketDoc.data();
    if (ticketData == null) return false;

    if (ticketData['quantity'] == null) return true;

    final registrationsCount = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('registrations')
        .where('ticketId', isEqualTo: ticketId)
        .count()
        .get();

    return (registrationsCount.count as int) < (ticketData['quantity'] as int);
  }

  void _openRegistrationForm(String ticketId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegisterTicketForm(
        event: widget.event,
        ticketId: ticketId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Register for Event',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .doc(widget.event.id)
                  .collection('tickets')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tickets = snapshot.data!.docs;
                if (tickets.isEmpty) {
                  return const Center(child: Text('No tickets available'));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Select Ticket Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final doc = tickets[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final isSelected = _selectedTicketId == doc.id;

                            return FutureBuilder<bool>(
                              future: _checkTicketAvailability(doc.id),
                              builder: (context, availabilitySnapshot) {
                                final isAvailable = availabilitySnapshot.data ?? false;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: InkWell(
                                    onTap: isAvailable ? () {
                                      _openRegistrationForm(doc.id);
                                    } : null,
                                    child: Opacity(
                                      opacity: isAvailable ? 1.0 : 0.5,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            data['name'],
                                                            style: Theme.of(context).textTheme.titleMedium,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[100],
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            data['price'] > 0 
                                                              ? "${data['price']} ${data['currency']}"
                                                              : "Free",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.people_outline,
                                                          size: 16,
                                                          color: Colors.grey[600],
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          !isAvailable
                                                            ? 'Sold out'
                                                            : data['quantity'] != null 
                                                              ? '${data['quantity']} available'
                                                              : 'Unlimited',
                                                          style: TextStyle(
                                                            color: !isAvailable ? Colors.red : Colors.grey[600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
              },
            ),
          ),
        ],
      ),
    );
  }
} 