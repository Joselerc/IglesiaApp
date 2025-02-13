import 'package:flutter/material.dart';
import '../../models/ministry_event.dart';
import 'package:intl/intl.dart';

class MinistryEventDetailScreen extends StatelessWidget {
  final MinistryEvent event;

  const MinistryEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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