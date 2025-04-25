import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../../models/private_prayer.dart';

class PrivatePrayerCard extends StatelessWidget {
  final PrivatePrayer prayer;

  const PrivatePrayerCard({
    super.key,
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser != null && prayer.userId.id == currentUser.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Encabezado con estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: prayer.pastorResponse != null
                  ? Colors.green.withOpacity(0.1)
                  : prayer.isAccepted
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  prayer.pastorResponse != null
                      ? Icons.check_circle
                      : prayer.isAccepted
                          ? Icons.pending_actions
                          : Icons.watch_later_outlined,
                  color: prayer.pastorResponse != null
                      ? Colors.green
                      : prayer.isAccepted
                          ? Colors.blue
                          : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(
                        prayer.pastorResponse != null
                            ? 'Respondida'
                            : prayer.isAccepted
                                ? 'Aceitada'
                                : 'Pendente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: prayer.pastorResponse != null
                              ? Colors.green
                              : prayer.isAccepted
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                      ),
                      Text(
                        'Enviada el ${DateFormat('dd MMM yyyy - HH:mm', 'es').format(prayer.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: prayer.pastorResponse != null 
                        ? Colors.green
                          : prayer.isAccepted 
                            ? Colors.blue
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      prayer.pastorResponse != null 
                        ? 'Respondida'
                          : prayer.isAccepted 
                            ? 'Aceitada'
                              : 'Pendente',
                    style: const TextStyle(
                        fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pastor asignado (si está aceptada o respondida)
                if (prayer.acceptedBy != null || prayer.pastorId != null) ...[
                  FutureBuilder<DocumentSnapshot>(
                    future: (prayer.acceptedBy ?? prayer.pastorId)!.get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final pastorData = snapshot.data!.data() as Map<String, dynamic>?;
                      final pastorName = pastorData?['displayName'] as String? ?? 'Pastor';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: pastorData?['photoUrl'] != null
                                  ? NetworkImage(pastorData!['photoUrl'])
                                  : null,
                              child: pastorData?['photoUrl'] == null
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prayer.pastorResponse != null
                                        ? 'Respondida por:'
                                        : 'Atribuída a:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    pastorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],

                // Contenido de la oración
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Minha oração:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
              ),
              const SizedBox(height: 8),
              Text(
                prayer.content,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Respuesta del pastor
              if (prayer.pastorResponse != null) ...[
                const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resposta do pastor:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prayer.pastorResponse!,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        if (prayer.respondedAt != null) ...[
                          const SizedBox(height: 8),
                      Text(
                            'Respondido el ${DateFormat('dd MMM yyyy - HH:mm', 'es').format(prayer.respondedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                              fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Fecha de resposta se está aceita mas não respondida ainda
                if (prayer.isAccepted && prayer.pastorResponse == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Sua solicitação foi aceita e será atendida em breve.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
            ],
          ),
        ),
        ],
      ),
    );
  }
} 