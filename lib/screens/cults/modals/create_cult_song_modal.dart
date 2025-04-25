import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/cult.dart';
import '../../../theme/app_colors.dart';

class CreateCultSongModal extends StatefulWidget {
  final Cult cult;
  
  const CreateCultSongModal({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<CreateCultSongModal> createState() => _CreateCultSongModalState();
}

class _CreateCultSongModalState extends State<CreateCultSongModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _minutes = 3;
  int _seconds = 0;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _createCultSong() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      // Calcular la duración total en segundos
      final durationInSeconds = _minutes * 60 + _seconds;
      
      // Obtener el orden actual (último + 1)
      final snapshot = await FirebaseFirestore.instance
          .collection('cult_songs')
          .where('cultId', isEqualTo: FirebaseFirestore.instance.collection('cults').doc(widget.cult.id))
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      
      int order = 0;
      if (snapshot.docs.isNotEmpty) {
        final lastSong = snapshot.docs.first.data();
        order = (lastSong['order'] as int?) ?? 0;
        order += 1;
      }
      
      // Crear la canción
      await FirebaseFirestore.instance.collection('cult_songs').add({
        'cultId': FirebaseFirestore.instance.collection('cults').doc(widget.cult.id),
        'name': _nameController.text.trim(),
        'duration': durationInSeconds,
        'order': order,
        'files': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Música adicionada com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar música: $e')),
        );
      }
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Música ao Culto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Música',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira um nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Duração',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Minutos',
                      border: OutlineInputBorder(),
                    ),
                    value: _minutes,
                    items: List.generate(11, (index) => index).map((minute) {
                      return DropdownMenuItem<int>(
                        value: minute,
                        child: Text('$minute'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _minutes = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Segundos',
                      border: OutlineInputBorder(),
                    ),
                    value: _seconds,
                    items: List.generate(60, (index) => index).map((second) {
                      return DropdownMenuItem<int>(
                        value: second,
                        child: Text('$second'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _seconds = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCultSong,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : const Text('Adicionar Música'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
} 