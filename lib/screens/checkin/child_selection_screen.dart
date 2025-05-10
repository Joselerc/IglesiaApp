import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/child_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import './qr_scanner_screen.dart';

// Placeholder para la pantalla del scanner
// import './qr_scanner_screen.dart';

class ChildSelectionScreen extends StatefulWidget {
  final String familyId;

  const ChildSelectionScreen({super.key, required this.familyId});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen> {
  final List<String> _selectedChildIds = []; // Lista para guardar IDs de niños seleccionados

  void _toggleChildSelection(String childId) {
    setState(() {
      if (_selectedChildIds.contains(childId)) {
        _selectedChildIds.remove(childId);
      } else {
        _selectedChildIds.add(childId);
      }
    });
  }

  void _navigateToQrScanner() {
    if (_selectedChildIds.isEmpty) return;
    print('Crianças selecionadas: $_selectedChildIds');
    print('Navegando para QR Scanner...');
    // Navegar a la pantalla del scanner real
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => QRScannerScreen(selectedChildIds: _selectedChildIds))
    );
    // Eliminar SnackBar de placeholder
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Próximo passo: Ler QR Code para ${_selectedChildIds.length} criança(s)')),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Crianças para Check-in'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children')
            .where('familyId', isEqualTo: widget.familyId)
            .where('isActive', isEqualTo: true) // Solo mostrar niños activos
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar crianças: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma criança encontrada para esta família.'));
          }

          final childrenDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: childrenDocs.length,
            itemBuilder: (context, index) {
              final childDoc = childrenDocs[index];
              // Usar try-catch por si falla el mapeo del modelo
              try {
                  final child = ChildModel.fromFirestore(childDoc);
                  final bool isSelected = _selectedChildIds.contains(child.id);
                  
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1.0,
                      )
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: (child.photoUrl != null && child.photoUrl!.isNotEmpty)
                            ? NetworkImage(child.photoUrl!)
                            : null,
                        child: (child.photoUrl == null || child.photoUrl!.isEmpty)
                            ? Text('${child.firstName.isNotEmpty ? child.firstName[0] : ''}${child.lastName.isNotEmpty ? child.lastName[0] : ''}'.toUpperCase())
                            : null,
                      ),
                      title: Text('${child.firstName} ${child.lastName}', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
                      // Podríamos añadir edad u otra info si es útil
                      // subtitle: Text(...),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) => _toggleChildSelection(child.id),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onTap: () => _toggleChildSelection(child.id),
                    ),
                  );
              } catch (e) {
                  print("Erro ao processar criança ${childDoc.id}: $e");
                  return ListTile(title: Text("Erro ao carregar dados da criança ID: ${childDoc.id}"));
              }
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedChildIds.isEmpty ? Colors.grey.shade400 : AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _selectedChildIds.isEmpty ? null : _navigateToQrScanner,
          child: Text('CONFIRMAR SELEÇÃO (${_selectedChildIds.length})', style: AppTextStyles.button.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
} 