import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/private_prayer.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/private_prayer_card.dart';
import 'modals/create_private_prayer_modal.dart';

class PrivatePrayerScreen extends StatefulWidget {
  const PrivatePrayerScreen({super.key});

  @override
  State<PrivatePrayerScreen> createState() => _PrivatePrayerScreenState();
}

class _PrivatePrayerScreenState extends State<PrivatePrayerScreen> {
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
      _loadMorePrayers();
    }
  }

  Future<void> _loadMorePrayers() async {
    if (!_isLoadingMore && _lastDocument != null) {
      setState(() {
        _isLoadingMore = true;
      });

      // Cargar más prayers
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Prayer'),
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
                builder: (context) => const CreatePrivatePrayerModal(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Ask for prayer'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('private_prayers')
            .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid))
            .orderBy('createdAt', descending: true)
            .limit(_limit)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (!snapshot.hasData) {
            return const LoadingIndicator();
          }

          final prayers = snapshot.data!.docs;
          if (prayers.isEmpty) {
            return const Center(child: Text('No private prayers yet'));
          }

          _lastDocument = prayers.last;

          return ListView.builder(
            controller: _scrollController,
            itemCount: prayers.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == prayers.length) {
                return const LoadingIndicator();
              }

              final prayer = PrivatePrayer.fromFirestore(prayers[index]);
              return PrivatePrayerCard(prayer: prayer);
            },
          );
        },
      ),
    );
  }
} 