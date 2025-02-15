import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/group_event.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class GroupEventDetailScreen extends StatelessWidget {
  final GroupEvent event;

  const GroupEventDetailScreen({
    super.key,
    required this.event,
  });

  Future<void> _deleteEvent(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('group_events')
          .doc(event.id)
          .delete();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento eliminado correctamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el evento: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isCreator = event.createdBy.id == currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar Evento'),
                    content: const Text('¿Estás seguro de que quieres eliminar este evento?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteEvent(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            Image.network(
              event.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                );
              },
            ),

            // Botón de recordatorio
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar funcionalidad de recordatorio
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Agregar Recordatorio'),
                ),
              ),
            ),

            // Título del evento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                event.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Fecha del evento
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Fecha: ${DateFormat('dd/MM/yyyy, HH:mm').format(event.date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // Descripción del evento
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                event.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 