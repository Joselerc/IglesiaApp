// lib/screens/cults/cult_ministry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/cult.dart';
import '../../models/cult_ministry.dart';
import './modals/add_ministry_member_modal.dart';
import '../../theme/app_colors.dart';

class CultMinistryDetailScreen extends StatefulWidget {
  final CultMinistry cultMinistry;
  final Cult cult;
  
  const CultMinistryDetailScreen({
    Key? key,
    required this.cultMinistry,
    required this.cult,
  }) : super(key: key);

  @override
  State<CultMinistryDetailScreen> createState() => _CultMinistryDetailScreenState();
}

class _CultMinistryDetailScreenState extends State<CultMinistryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cultMinistry.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Informações do ministério
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('HH:mm').format(widget.cultMinistry.startTime)} - ${DateFormat('HH:mm').format(widget.cultMinistry.endTime)}',
                      style: TextStyle(
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.cultMinistry.isTemporary ? Colors.orange[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.cultMinistry.isTemporary ? 'Temporário' : 'Permanente',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.cultMinistry.isTemporary ? Colors.orange[800] : Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de membros
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cult_ministries')
                  .doc(widget.cultMinistry.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
                }
                
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('Ministério não encontrado'),
                  );
                }
                
                final ministryData = snapshot.data!.data() as Map<String, dynamic>;
                final members = ministryData['members'] as List<dynamic>? ?? [];
                
                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Não há membros atribuídos a este ministério'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showAddMemberModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Adicionar Membro'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index] as Map<String, dynamic>;
                    final userId = member['userId'] as String? ?? '';
                    final role = member['role'] as String? ?? '';
                    final startTime = (member['startTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final endTime = (member['endTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        String userName = 'Carregando...';
                        String photoUrl = '';
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          userName = userData['name'] ?? 'Usuário desconhecido';
                          photoUrl = userData['photoUrl'] ?? '';
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(userName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Função: $role'),
                                Text('${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _removeMember(index),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
  
  void _showAddMemberModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddMinistryMemberModal(
        cultMinistry: widget.cultMinistry,
        cult: widget.cult,
      ),
    );
  }
  
  Future<void> _removeMember(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover membro'),
        content: const Text('Tem certeza que deseja remover este membro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remover', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // Obter os membros atuais
      final doc = await FirebaseFirestore.instance
          .collection('cult_ministries')
          .doc(widget.cultMinistry.id)
          .get();
      
      if (!doc.exists) return;
      
      final ministryData = doc.data() as Map<String, dynamic>;
      final members = List<dynamic>.from(ministryData['members'] as List<dynamic>? ?? []);
      
      // Remover o membro
      if (index >= 0 && index < members.length) {
        members.removeAt(index);
        
        // Atualizar no Firestore
        await FirebaseFirestore.instance
            .collection('cult_ministries')
            .doc(widget.cultMinistry.id)
            .update({'members': members});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Membro removido com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover membro: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}