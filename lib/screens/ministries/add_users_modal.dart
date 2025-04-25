// Este archivo ya no se utiliza y la funcionalidad se ha implementado 
// directamente en manage_requests_screen.dart en el método _showAddUsersModal

// Archivo mantenido temporalmente para compatibilidad pero será eliminado en futuras versiones.

import 'package:flutter/material.dart';
import '../../models/ministry.dart';

class AddUsersModal extends StatefulWidget {
  final Ministry ministry;

  const AddUsersModal({
    super.key,
    required this.ministry,
  });

  @override
  State<AddUsersModal> createState() => _AddUsersModalState();
}

class _AddUsersModalState extends State<AddUsersModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Esta funcionalidad ha sido actualizada.'),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
} 