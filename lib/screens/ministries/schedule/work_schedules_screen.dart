import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/work_schedule.dart';
import 'package:intl/intl.dart';
import 'modals/create_work_schedule_modal.dart';
import 'modals/assignees_modal.dart';

class WorkSchedulesScreen extends StatelessWidget {
  final String ministryId;
  final bool isLeader;

  const WorkSchedulesScreen({
    super.key,
    required this.ministryId,
    required this.isLeader,
  });

  void _showCreateScheduleModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CreateWorkScheduleModal(
          ministryId: ministryId,
        ),
      ),
    );
  }

  void _showDescriptionModal(BuildContext context, WorkSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.jobName),
        content: Text(schedule.description ?? 'No hay descripción disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WorkSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Horario'),
        content: Text('¿Estás seguro que deseas eliminar "${schedule.jobName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('work_schedules')
                  .doc(schedule.id)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Horario eliminado exitosamente')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAssigneesModal(BuildContext context, WorkSchedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssigneesModal(
        schedule: schedule,
        ministryId: ministryId,
        isLeader: isLeader,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios de Trabajo'),
        actions: [
          if (isLeader)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateScheduleModal(context),
              tooltip: 'Crear Nuevo Horario',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lista de horarios
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('work_schedules')
                    .where('ministryId', isEqualTo: ministryId)
                    .orderBy('date', descending: false) // Ordenar por fecha ascendente
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final schedules = snapshot.data!.docs
                      .map((doc) => WorkSchedule.fromFirestore(doc))
                      .toList();

                  if (schedules.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No hay horarios de trabajo',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          if (isLeader) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateScheduleModal(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Horario'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  // Agrupar horarios por fecha
                  final Map<String, List<WorkSchedule>> groupedSchedules = {};
                  
                  for (var schedule in schedules) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(schedule.date);
                    if (!groupedSchedules.containsKey(dateKey)) {
                      groupedSchedules[dateKey] = [];
                    }
                    groupedSchedules[dateKey]!.add(schedule);
                  }
                  
                  // Convertir a lista ordenada
                  final sortedDates = groupedSchedules.keys.toList()..sort();
                  
                  return ListView.builder(
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final dateKey = sortedDates[dateIndex];
                      final dateSchedules = groupedSchedules[dateKey]!;
                      final date = DateTime.parse(dateKey);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado de fecha
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, 
                                  size: 18, 
                                  color: Theme.of(context).primaryColor
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Lista de horarios para esta fecha
                          ...dateSchedules.map((schedule) {
                            final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
                            final isPast = schedule.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Indicador de arrastre
                                        Container(
                                          width: 40,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        
                                        // Título
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            schedule.jobName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        
                                        const Divider(height: 1),
                                        
                                        // Opciones
                                        ListTile(
                                          leading: const Icon(Icons.description),
                                          title: const Text('Ver Descripción'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showDescriptionModal(context, schedule);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.people),
                                          title: const Text('Ver Asignados'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showAssigneesModal(context, schedule);
                                          },
                                        ),
                                        if (isLeader && !isPast) ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('Eliminar Horario', 
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _showDeleteConfirmation(context, schedule);
                                          },
                                        ),
                                        
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Icono y título
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isPast 
                                                ? Colors.grey.shade200 
                                                : isToday 
                                                  ? Colors.green.shade50 
                                                  : Colors.blue.shade50,
                                              radius: 20,
                                              child: Icon(
                                                Icons.work,
                                                color: isPast 
                                                  ? Colors.grey 
                                                  : isToday 
                                                    ? Colors.green 
                                                    : Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    schedule.jobName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isPast ? Colors.grey : Colors.black,
                                                    ),
                                                  ),
                                                  if (schedule.description != null && schedule.description!.isNotEmpty)
                                                    Text(
                                                      schedule.description!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Asignados
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: schedule.acceptedWorkersCount / schedule.requiredWorkers,
                                                backgroundColor: Colors.grey.shade200,
                                                color: schedule.acceptedWorkersCount >= schedule.requiredWorkers
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                              Text(
                                                '${schedule.acceptedWorkersCount}/${schedule.requiredWorkers}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Fecha (ya mostrada en el encabezado)
                                      const Expanded(
                                        flex: 2,
                                        child: SizedBox.shrink(),
                                      ),
                                      
                                      // Horario
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            '${DateFormat('HH:mm').format(schedule.timeSlot.startTime)} - ${DateFormat('HH:mm').format(schedule.timeSlot.endTime)}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isPast ? Colors.grey : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Botón flotante para crear horarios (alternativa para dispositivos más grandes)
      floatingActionButton: isLeader ? FloatingActionButton(
        onPressed: () => _showCreateScheduleModal(context),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
} 