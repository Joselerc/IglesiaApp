import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/work_assignment.dart';
import '../../models/time_slot.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class CalendarServicesView extends StatefulWidget {
  final DateTime selectedDate;
  
  const CalendarServicesView({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<CalendarServicesView> createState() => _CalendarServicesViewState();
}

class _CalendarServicesViewState extends State<CalendarServicesView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignmentsWithDetails = [];

  @override
  void initState() {
    super.initState();
    _loadAcceptedAssignments();
  }
  
  @override
  void didUpdateWidget(CalendarServicesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadAcceptedAssignments();
    }
  }

  Future<void> _loadAcceptedAssignments() async {
    setState(() {
      _isLoading = true;
    });
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Normalizar la fecha seleccionada para comparar solo día, mes y año
      final selectedDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
      
      // La fecha siguiente (para crear un rango)
      final nextDay = selectedDay.add(const Duration(days: 1));
      
      // Referencia al documento del usuario
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      debugPrint('[Servicios] Cargando para fecha: ${selectedDay.toIso8601String()}');
      debugPrint('Buscando serviços para: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}');
      
      // Primero, obtener todos los time_slots para este día específico
      final timeSlotSnapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('entityType', isEqualTo: 'cult')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDay))
          .where('startTime', isLessThan: Timestamp.fromDate(nextDay))
          .get();
          
      debugPrint('[Servicios] Query de TimeSlots: startTime >= ${Timestamp.fromDate(selectedDay)} && startTime < ${Timestamp.fromDate(nextDay)}');
      debugPrint('Encontrados ${timeSlotSnapshot.docs.length} time slots para o dia selecionado');
      
      if (timeSlotSnapshot.docs.isEmpty) {
        setState(() {
          _assignmentsWithDetails = [];
          _isLoading = false;
        });
        return;
      }
      
      // Obtener IDs de los time slots
      final timeSlotIds = timeSlotSnapshot.docs.map((doc) => doc.id).toList();
      
      // Ahora, obtener todas las asignaciones que:
      // 1. Pertenecen al usuario actual
      // 2. Están aceptadas
      // 3. Son para alguno de los time slots de este día
      final assignmentsWithDetails = <Map<String, dynamic>>[];
      
      // Buscar asignaciones para estos time slots
      for (final timeSlotId in timeSlotIds) {
        debugPrint('[Servicios] Verificando asignaciones para timeSlotId: $timeSlotId');
        final assignmentSnapshot = await FirebaseFirestore.instance
            .collection('work_assignments')
            .where('timeSlotId', isEqualTo: timeSlotId)
            .where('userId', isEqualTo: userRef)
            .where('status', isEqualTo: 'accepted')
            .where('isActive', isEqualTo: true)
            .get();
            
        debugPrint('[Servicios] Asignaciones encontradas para $timeSlotId: ${assignmentSnapshot.docs.length}');
        if (assignmentSnapshot.docs.isEmpty) continue;
        
        debugPrint('Encontradas ${assignmentSnapshot.docs.length} atribuições para time slot $timeSlotId');
        
        // Para cada asignación, cargar detalles adicionales
        for (final doc in assignmentSnapshot.docs) {
          try {
            final assignment = WorkAssignment.fromFirestore(doc);
            
            // Obtener el time slot
            final timeSlotDoc = await FirebaseFirestore.instance
                .collection('time_slots')
                .doc(assignment.timeSlotId)
                .get();
                
            if (!timeSlotDoc.exists) continue;
            
            final timeSlot = TimeSlot.fromFirestore(timeSlotDoc);
            
            // Obtener nombre del ministerio
            String ministryName = '';
            try {
              final ministryDoc = await FirebaseFirestore.instance
                  .collection('ministries')
                  .doc(assignment.ministryId)
                  .get();
              
              if (ministryDoc.exists) {
                ministryName = ministryDoc.data()?['name'] ?? '';
              }
            } catch (e) {
              debugPrint('Erro ao obter ministério: $e');
            }
            
            // Obtener nombre del culto
            String cultName = '';
            try {
              final cultDoc = await FirebaseFirestore.instance
                  .collection('cults')
                  .doc(timeSlot.entityId)
                  .get();
              
              if (cultDoc.exists) {
                cultName = cultDoc.data()?['name'] ?? '';
              }
            } catch (e) {
              debugPrint('Erro ao obter culto: $e');
            }
            
            // Agregar a la lista con todos los detalles
            assignmentsWithDetails.add({
              'assignment': assignment,
              'timeSlot': timeSlot,
              'ministryName': ministryName,
              'entityName': cultName,
            });
            
            debugPrint('Atribuição adicionada para culto: $cultName, ministério: $ministryName, função: ${assignment.role}');
          } catch (e) {
            debugPrint('Erro ao processar atribuição: $e');
          }
        }
      }
      
      setState(() {
        _assignmentsWithDetails = assignmentsWithDetails;
        _isLoading = false;
      });
      
      debugPrint('Total de atribuições para mostrar: ${_assignmentsWithDetails.length}');
    } catch (e) {
      debugPrint('Erro ao carregar atribuições: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_assignmentsWithDetails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noServicesAssignedForThisDay,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar la lista de servicios asignados
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignmentsWithDetails.length,
      itemBuilder: (context, index) {
        final item = _assignmentsWithDetails[index];
        final assignment = item['assignment'] as WorkAssignment;
        final timeSlot = item['timeSlot'] as TimeSlot;
        final ministryName = item['ministryName'] as String;
        final cultName = item['entityName'] as String;

        // Formatear la hora para mostrar
        final startTime = DateFormat('HH:mm').format(timeSlot.startTime);
        final endTime = DateFormat('HH:mm').format(timeSlot.endTime);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () => _showAssignmentDetails(context, item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera con el nombre del culto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    cultName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                // Detalles del servicio
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila con icono para el rol
                      Row(
                        children: [
                          Icon(Icons.person, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Função: ${assignment.role}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Fila con icono para el ministerio
                      Row(
                        children: [
                          Icon(Icons.groups, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Ministério: $ministryName',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Fila con icono para el horario
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Horário: $startTime - $endTime',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Botón para ver detalles
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAssignmentDetails(context, item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                          label: const Text(
                            'Ver Detalhes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAssignmentDetails(BuildContext context, Map<String, dynamic> item) {
    final assignment = item['assignment'] as WorkAssignment;
    final timeSlot = item['timeSlot'] as TimeSlot;
    final ministryName = item['ministryName'] as String;
    final cultName = item['entityName'] as String;

    // Formatear la fecha y hora
    final date = DateFormat('EEEE d MMMM yyyy', 'pt_BR').format(timeSlot.startTime);
    final startTime = DateFormat('HH:mm').format(timeSlot.startTime);
    final endTime = DateFormat('HH:mm').format(timeSlot.endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.work, color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    ministryName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    assignment.role,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _detailItem(Icons.event, 'Culto', cultName),
                _detailItem(Icons.calendar_today, 'Data', date),
                _detailItem(Icons.access_time, 'Horário', '$startTime - $endTime'),
                _detailItem(Icons.notes, 'Detalhes', timeSlot.description.isNotEmpty 
                  ? timeSlot.description 
                  : 'Sem detalhes adicionais'),
                if (assignment.notes != null && assignment.notes!.isNotEmpty)
                  _detailItem(Icons.comment, 'Notas', assignment.notes!),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _detailItem(Icons.check_circle, AppLocalizations.of(context)!.status, AppLocalizations.of(context)!.accepted),
                _detailItem(Icons.calendar_today, AppLocalizations.of(context)!.acceptedOn, 
                  assignment.respondedAt != null 
                      ? DateFormat('dd/MM/yyyy HH:mm').format(assignment.respondedAt!)
                      : AppLocalizations.of(context)!.dateNotAvailable),
                const SizedBox(height: 30),
                
                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'Fechar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 