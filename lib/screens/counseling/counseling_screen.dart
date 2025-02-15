import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/counseling_appointment.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/counseling_appointment_card.dart';
import 'modals/book_counseling_modal.dart';

class CounselingScreen extends StatefulWidget {
  const CounselingScreen({super.key});

  @override
  State<CounselingScreen> createState() => _CounselingScreenState();
}

class _CounselingScreenState extends State<CounselingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.95) {
      _loadMoreAppointments();
    }
  }

  Future<void> _loadMoreAppointments() async {
    if (!_isLoadingMore && _lastDocument != null) {
      setState(() {
        _isLoadingMore = true;
      });
      // Implementar carga de más citas
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counseling'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const BookCounselingModal(),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('Book Counseling'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid))
            .orderBy('date', descending: false) // Primero las citas futuras
            .limit(_limit)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData) {
            return const LoadingIndicator();
          }

          final appointments = snapshot.data!.docs;
          
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No appointments yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book your first counseling session',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => const BookCounselingModal(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Book Counseling'),
                  ),
                ],
              ),
            );
          }

          _lastDocument = appointments.last;

          // Separar citas futuras y pasadas
          final upcomingAppointments = appointments
              .map((doc) => CounselingAppointment.fromFirestore(doc))
              .where((appointment) => appointment.isUpcoming)
              .toList();

          final pastAppointments = appointments
              .map((doc) => CounselingAppointment.fromFirestore(doc))
              .where((appointment) => !appointment.isUpcoming)
              .toList();

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (upcomingAppointments.isNotEmpty) ...[
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...upcomingAppointments.map((appointment) => 
                  CounselingAppointmentCard(appointment: appointment)
                ),
                const SizedBox(height: 32),
              ],
              
              if (pastAppointments.isNotEmpty) ...[
                const Text(
                  'Past Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...pastAppointments.map((appointment) => 
                  CounselingAppointmentCard(
                    appointment: appointment,
                    isPast: true,
                  )
                ),
              ],
              
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
} 