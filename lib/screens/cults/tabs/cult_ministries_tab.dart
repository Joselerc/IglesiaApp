import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/cult.dart';
import '../../../models/cult_ministry.dart';
import '../modals/create_cult_ministry_modal.dart';
import '../cult_ministry_detail_screen.dart';

class CultMinistriesTab extends StatelessWidget {
  final Cult cult;
  
  const CultMinistriesTab({
    Key? key,
    required this.cult,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cult_ministries')
            .where('cultId', isEqualTo: FirebaseFirestore.instance.collection('cults').doc(cult.id))
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay ministerios asignados a este culto'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateMinistryModal(context),
                    child: const Text('Añadir Ministerio'),
                  ),
                ],
              ),
            );
          }
          
          final ministries = snapshot.data!.docs.map((doc) {
            try {
              return CultMinistry.fromFirestore(doc);
            } catch (e) {
              // Manejar el error, pero no interrumpir la carga
              print('Error al convertir documento: $e');
              return null;
            }
          }).where((ministry) => ministry != null).cast<CultMinistry>().toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ministries.length,
            itemBuilder: (context, index) {
              final ministry = ministries[index];
              
              // Formatear la hora para mostrarla
              final startTime = DateFormat('HH:mm').format(ministry.startTime);
              final endTime = ministry.endTime != null 
                  ? DateFormat('HH:mm').format(ministry.endTime!)
                  : 'No definido';
                  
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CultMinistryDetailScreen(
                          cultMinistry: ministry,
                          cult: cult,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ministry.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$startTime - $endTime',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ministry.description != null && ministry.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            ministry.description!,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMinistryModal(context),
        child: const Icon(Icons.add),
        tooltip: 'Añadir Ministerio',
      ),
    );
  }
  
  void _showCreateMinistryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateCultMinistryModal(
        cult: cult,
      ),
    );
  }
} 