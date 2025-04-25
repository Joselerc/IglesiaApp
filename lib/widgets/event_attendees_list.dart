import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/event_service.dart';

class EventAttendeesList extends StatelessWidget {
  final String eventId;
  final String eventType; // 'ministry' o 'group'
  final Color? primaryColor;
  final bool showTitle;
  final bool showActions;
  final bool isCompact;
  final VoidCallback? onAttendingToggled;

  const EventAttendeesList({
    Key? key,
    required this.eventId,
    required this.eventType,
    this.primaryColor,
    this.showTitle = true,
    this.showActions = false,
    this.isCompact = false,
    this.onAttendingToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MaterialColor defaultColor = eventType == 'ministry' ? Colors.blue : Colors.green;
    final Color baseColor = primaryColor ?? defaultColor;
    final Color titleColor = primaryColor ?? defaultColor.shade700;
    final Color lightColor = primaryColor?.withOpacity(0.2) ?? defaultColor.shade100;
    final Color darkColor = primaryColor ?? defaultColor.shade700;
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: EventService().getEventAttendees(
        eventId: eventId,
        eventType: eventType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar asistentes: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          );
        }
        
        final attendees = snapshot.data ?? [];
        
        if (attendees.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (showTitle)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.people, color: titleColor),
                          const SizedBox(width: 8),
                          Text(
                            'Asistentes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nadie ha confirmado asistencia aún',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (showActions) 
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: _buildAttendanceButton(context, defaultColor, baseColor),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTitle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: titleColor),
                            const SizedBox(width: 8),
                            Text(
                              'Asistentes (${attendees.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                        if (showActions) 
                          _buildAttendanceButton(context, defaultColor, baseColor),
                      ],
                    ),
                  ),
                
                if (isCompact)
                  // Vista compacta con avatares horizontales
                  SizedBox(
                    height: 60,
                    child: attendees.isEmpty 
                      ? Center(
                          child: Text(
                            'Nadie ha confirmado asistencia',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            ...attendees.take(8).map((attendee) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Tooltip(
                                message: attendee['displayName'] ?? 'Usuario',
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: attendee['photoUrl'] != null && attendee['photoUrl'].isNotEmpty
                                      ? NetworkImage(attendee['photoUrl'])
                                      : null,
                                  backgroundColor: lightColor,
                                  child: attendee['photoUrl'] == null || attendee['photoUrl'].isEmpty
                                      ? Icon(Icons.person, color: darkColor)
                                      : null,
                                ),
                              ),
                            )),
                            if (attendees.length > 8)
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: lightColor,
                                child: Text(
                                  '+${attendees.length - 8}',
                                  style: TextStyle(
                                    color: darkColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  )
                else
                  // Vista completa con lista de asistentes
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendees.length,
                    itemBuilder: (context, index) {
                      final attendee = attendees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: attendee['photoUrl'] != null && attendee['photoUrl'].isNotEmpty
                              ? NetworkImage(attendee['photoUrl'])
                              : null,
                          backgroundColor: lightColor,
                          child: attendee['photoUrl'] == null || attendee['photoUrl'].isEmpty
                              ? Icon(Icons.person, color: darkColor)
                              : null,
                        ),
                        title: Text(
                          attendee['displayName'] ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: attendee['email'] != null && attendee['email'].isNotEmpty
                            ? Text(attendee['email'])
                            : null,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAttendanceButton(BuildContext context, MaterialColor defaultColor, Color baseColor) {
    return FutureBuilder<bool>(
      future: EventService().isUserAttending(
        eventId: eventId,
        eventType: eventType,
      ),
      builder: (context, snapshot) {
        final isAttending = snapshot.data ?? false;
        
        return ElevatedButton.icon(
          onPressed: () => _toggleAttendance(context, !isAttending),
          style: ElevatedButton.styleFrom(
            backgroundColor: isAttending ? Colors.red.shade700 : const Color(0xFF673AB7),
            foregroundColor: Colors.white,
            elevation: 1.5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          icon: Icon(isAttending 
            ? Icons.person_remove_rounded 
            : Icons.person_add_rounded,
            color: Colors.white),
          label: Text(isAttending 
            ? 'Cancelar asistencia' 
            : 'Confirmar asistencia',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
        );
      },
    );
  }
  
  void _toggleAttendance(BuildContext context, bool attending) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      await EventService().markAttendance(
        eventId: eventId,
        userId: userId,
        eventType: eventType,
        attending: attending,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attending 
              ? 'Has confirmado tu asistencia al evento'
              : 'Has cancelado tu asistencia al evento'),
          backgroundColor: attending ? Colors.green : Colors.amber,
        ),
      );
      
      if (onAttendingToggled != null) {
        onAttendingToggled!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 