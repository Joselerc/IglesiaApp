import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_message.dart';
import '../../models/ministry.dart';

class MinistryChatScreen extends StatelessWidget {
  final Ministry ministry;
  final TextEditingController _messageController = TextEditingController();

  MinistryChatScreen({
    super.key,
    required this.ministry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${ministry.name} Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ministry_chat_messages')
                  .where('ministryId', isEqualTo: FirebaseFirestore.instance
                      .collection('ministries')
                      .doc(ministry.id))
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    try {
                      final message = ChatMessage.fromFirestore(messages[index]);
                      final isCurrentUser = message.authorId.id == 
                          FirebaseAuth.instance.currentUser?.uid;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisAlignment: isCurrentUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isCurrentUser) ...[
                              const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.blue[100]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: message.authorId.snapshots(),
                                    builder: (context, snapshot) {
                                      final userName = snapshot.hasData
                                          ? (snapshot.data!.data() 
                                              as Map<String, dynamic>)['name'] ?? 'Unknown'
                                          : 'Unknown';
                                      return Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(message.content),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      print('Error loading message: $e');
                      return const SizedBox(); // Skip invalid messages
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('ministry_chat_messages')
                          .add({
                            'content': _messageController.text.trim(),
                            'authorId': FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid),
                            'ministryId': FirebaseFirestore.instance
                                .collection('ministries')
                                .doc(ministry.id),
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 