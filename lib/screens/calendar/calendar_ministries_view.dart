import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/ministry_event.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarMinistriesView extends StatelessWidget {
  final DateTime selectedDate;
  final List<MinistryEvent> events;

  const CalendarMinistriesView({
    super.key,
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noMinistryEventsScheduled,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, MinistryEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/ministries/${event.ministryId.id}/events/${event.id}',
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            if (event.imageUrl.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16/9,
                    child: Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  // Indicador de fecha sobre la imagen
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('d MMM', 'pt_BR').format(event.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ministerio
                  FutureBuilder<DocumentSnapshot>(
                    future: event.ministryId.get(),
                    builder: (context, snapshot) {
                      final ministryName = snapshot.hasData && snapshot.data!.exists
                          ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Ministério'
                          : 'Ministério';
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ministryName,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Título del evento
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Fecha y hora
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE d MMMM yyyy, HH:mm', 'pt_BR').format(event.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Descripción
                  Text(
                    event.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mostrar número de asistentes
                  FutureBuilder<int>(
                    future: EventService().getEventAttendeesCount(
                      eventId: event.id,
                      eventType: 'ministry',
                    ),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '$count ${count == 1 ? 'participante' : 'participantes'}',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Botón para añadir recordatorio
                      TextButton.icon(
                        onPressed: () {
                          _addReminder(context, event);
                        },
                        icon: Icon(Icons.notifications_active, color: AppColors.primary),
                        label: const Text('Lembrar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Botón para ver detalles
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/ministries/${event.ministryId.id}/events/${event.id}',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.visibility,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Ver Detalhes',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Método para añadir un recordatorio del evento
  void _addReminder(BuildContext context, MinistryEvent event) async {
    try {
      // Obtener el nombre del ministerio
      final ministryDoc = await event.ministryId.get();
      final ministryName = ministryDoc.exists 
          ? (ministryDoc.data() as Map<String, dynamic>)['name'] ?? 'Ministério'
          : 'Ministério';
      
      await EventService().addEventReminder(
        eventId: event.id,
        eventTitle: event.title,
        eventDate: event.date,
        eventType: 'ministry',
        entityId: event.ministryId.id,
        entityName: ministryName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lembrete adicionado com sucesso'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao configurar lembrete: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // Método para marcar/desmarcar asistencia
  void _toggleAttendance(BuildContext context, MinistryEvent event, bool attending) async {
    try {
      await EventService().markAttendance(
        eventId: event.id,
        userId: FirebaseAuth.instance.currentUser!.uid,
        eventType: 'ministry',
        attending: attending,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attending 
              ? 'Confirmou sua participação em "${event.title}"'
              : 'Cancelou sua participação em "${event.title}"'),
          backgroundColor: attending ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar participação: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 