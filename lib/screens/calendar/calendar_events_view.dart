import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class CalendarEventsView extends StatelessWidget {
  final DateTime selectedDate;

  const CalendarEventsView({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noEventsScheduled,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Obtener eventos
        final allEvents = snapshot.data!.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList();

        // Filtrar eventos para la fecha seleccionada
        final eventsForSelectedDate = allEvents.where((event) {
          final eventDate = event.startDate;
          return eventDate.year == selectedDate.year &&
              eventDate.month == selectedDate.month &&
              eventDate.day == selectedDate.day;
        }).toList();

        if (eventsForSelectedDate.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noEventsFor(DateFormat('d MMMM yyyy', Localizations.localeOf(context).toString()).format(selectedDate)),
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
          itemCount: eventsForSelectedDate.length,
          itemBuilder: (context, index) {
            final event = eventsForSelectedDate[index];
            return _buildEventCard(context, event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
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
            '/events/${event.id}',
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
                        DateFormat('d MMM', 'pt_BR').format(event.startDate),
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
                        DateFormat('EEEE d MMMM yyyy, HH:mm', 'pt_BR').format(event.startDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Ubicación
                  if (_hasLocation(event)) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getLocationText(event),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
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
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _addReminder(context, event),
                        icon: Icon(Icons.notifications_active, color: AppColors.primary),
                        label: const Text('Lembrar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/events/${event.id}',
                          );
                        },
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        label: const Text(
                          'Ver Detalhes',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
  
  // Método para añadir un recordatorio
  void _addReminder(BuildContext context, EventModel event) async {
    try {
      await EventService().addEventReminder(
        eventId: event.id,
        eventTitle: event.title,
        eventDate: event.startDate,
        eventType: 'event',
        entityId: event.id,
        entityName: event.title,
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
  
  // Verifica si el evento tiene información de ubicación
  bool _hasLocation(EventModel event) {
    return event.city != null && event.city!.isNotEmpty ||
           event.street != null && event.street!.isNotEmpty ||
           event.churchLocationId != null && event.churchLocationId!.isNotEmpty;
  }
  
  // Devuelve un texto formateado con la ubicación del evento
  String _getLocationText(EventModel event) {
    final locationParts = <String>[];
    
    if (event.street != null && event.street!.isNotEmpty) {
      String streetText = event.street!;
      if (event.number != null && event.number!.isNotEmpty) {
        streetText += ' ${event.number!}';
      }
      locationParts.add(streetText);
    }
    
    if (event.city != null && event.city!.isNotEmpty) {
      locationParts.add(event.city!);
    }
    
    if (event.state != null && event.state!.isNotEmpty) {
      locationParts.add(event.state!);
    }
    
    if (locationParts.isEmpty && event.churchLocationId != null) {
      return 'Localização da igreja';
    }
    
    return locationParts.join(', ');
  }
} 