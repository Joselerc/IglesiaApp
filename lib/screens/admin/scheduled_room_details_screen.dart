import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/scheduled_room_model.dart';
import '../../models/child_model.dart'; // Para listar niños
import '../../models/user_model.dart'; // Para responsables (si fuera necesario aquí)
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import './create_edit_room_screen.dart'; // Para Editar Programação
import './child_details_screen.dart'; // Para ChildDetailsScreen
import './child_attendance_details_screen.dart'; // Para detalles de asistencia
// import '../checkin/child_selection_screen.dart'; // Para Check-in na Sala

class ScheduledRoomDetailsScreen extends StatefulWidget {
  final String scheduledRoomId; 

  const ScheduledRoomDetailsScreen({
    super.key, 
    required this.scheduledRoomId,
  });

  @override
  State<ScheduledRoomDetailsScreen> createState() => _ScheduledRoomDetailsScreenState();
}

class _ScheduledRoomDetailsScreenState extends State<ScheduledRoomDetailsScreen> {
  final TextEditingController _searchChildController = TextEditingController();
  String _searchChildTerm = '';

  @override
  void initState() {
    super.initState();
    _searchChildController.addListener(() {
      setState(() {
        _searchChildTerm = _searchChildController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchChildController.dispose();
    super.dispose();
  }

  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return '';
    final birth = birthDate.toDate();
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age > 0 ? '$age anos' : (age == 0 ? 'Menos de 1 ano' : '');
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String initials = parts.first[0];
    if (parts.length > 1) initials += parts.last[0];
    return initials.toUpperCase();
  }

  void _navigateToEditSchedule(ScheduledRoomModel schedule) {
     Navigator.push(context, MaterialPageRoute(builder: (_) => 
        CreateEditRoomScreen(
          meetingId: schedule.id,
        )
      ));
  }
  
  void _handleOpenOrCloseRoom(ScheduledRoomModel schedule, bool shouldOpen) async {
    final actionText = shouldOpen ? "abrir" : "encerrar";
    print('Tentando $actionText a sala: ${schedule.id}');
    try {
      await FirebaseFirestore.instance.collection('scheduledRooms').doc(schedule.id).update({
        'isOpen': shouldOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sala ${shouldOpen ? "aberta" : "encerrada"} com sucesso.'), backgroundColor: Colors.green));
      // El StreamBuilder en RoomListScreen y en esta pantalla debería actualizar la UI.
    } catch (e) {
      print('Erro ao $actionText sala: $e');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao $actionText sala: $e'), backgroundColor: Colors.red));
    }
  }

  void _handleCheckInRoom(ScheduledRoomModel schedule) {
    print('Check-in para programação: ${schedule.id}');
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ChildSelectionScreen(scheduledRoomId: schedule.id, familyId: null /* O el de la familia si es checkin familiar */ )));
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navegar para seleção de crianças para check-in na sala: ${schedule.description}')));
  }

  void _handleSendSummary() {
    print('Enviar Resumo - Pendente');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviar Resumo (Pendente)')));
  }

  void _showRoomInformation(ScheduledRoomModel schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detalhes da Programação"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Programação: ${schedule.description}', style: AppTextStyles.subtitle1),
            Text('Data: ${DateFormat('dd/MM/yyyy').format(schedule.date.toDate())}'),
            Text('Horário: ${DateFormat.Hm().format(schedule.startTime.toDate())} - ${DateFormat.Hm().format(schedule.endTime.toDate())}'),
            Text('Faixa Etária: ${schedule.ageRange ?? "N/A"}'),
            Text('Capacidade Máx.: ${schedule.maxChildren ?? "Ilimitada"}'),
            Text('Status: ${schedule.isOpen ? "Aberta" : "Programada/Encerrada"}'),
            Text('Repete Semanalmente: ${schedule.repeatWeekly ? "Sim" : "Não"}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR'))],
      )
    );
  }

  void _showChildOptionsModal(BuildContext context, ChildModel child, ScheduledRoomModel schedule) {
    // TODO: Obtener información del responsable principal del niño (de family/visitor, luego de user)
    // String primaryGuardianContactInfo = "Contato do responsável pendente";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.0, 
            left: 16.0, right: 16.0, top: 20.0,
          ),
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility_outlined, color: AppColors.textPrimary),
                title: const Text('Ver detalhes do Menino/a'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    ChildDetailsScreen(
                      childId: child.id,
                      familyId: child.familyId, // ChildModel tiene familyId
                    )
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_edu_outlined, color: AppColors.textPrimary),
                title: const Text('Ver detalhes de Assistência'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    ChildAttendanceDetailsScreen(
                      childId: child.id,
                      scheduledRoomId: schedule.id,
                    )
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_forwarded_outlined, color: AppColors.textPrimary),
                title: const Text('Ligar para o responsável'),
                onTap: () {
                  Navigator.pop(ctx);
                  print('Ligar para o responsável da criança: ${child.id}');
                  // TODO: Obtener el UserModel del responsable y llamar a _showGuardianContactOptions que ya tenemos
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ligar para responsável (Pendente)')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync_alt_outlined, color: AppColors.textPrimary),
                title: const Text('Transferir menino/a (Reimprimir etiqueta)'),
                onTap: () {
                  Navigator.pop(ctx);
                  print('Transferir menino/a: ${child.id}');
                  // TODO: Implementar lógica de transferencia y reimpresión
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transferir (Pendente)')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.multiple_stop_outlined, color: AppColors.textPrimary),
                title: const Text('Traslado de meninos/as'),
                onTap: () {
                  Navigator.pop(ctx);
                  print('Traslado de meninos/as (sala inteira ou grupo?): ${child.id}');
                  // TODO: Implementar lógica de traslado de grupo de niños
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Traslado (Pendente)')));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteScheduleDialog(ScheduledRoomModel schedule) async {
    final String scheduleName = schedule.description;
    bool? deleteThisOnly;
    bool? deleteAllFuture;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Eliminar Programação'),
          content: Text('Você deseja eliminar apenas "$scheduleName" desta data ou esta e todas as futuras repetições desta série?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Apenas Esta'),
              onPressed: () {
                deleteThisOnly = true;
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Esta e Futuras', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () {
                deleteAllFuture = true;
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );

    if (deleteThisOnly == true) {
      await _deleteSingleScheduleInstance(schedule.id, scheduleName);
    } else if (deleteAllFuture == true) {
      await _deleteAllFutureSchedules(schedule, scheduleName);
    }
  }

  Future<void> _deleteSingleScheduleInstance(String scheduleId, String scheduleName) async {
    if (!mounted) return;
    // TODO: Mostrar indicador de loading
    try {
      print('[DELETE_DEBUG] Eliminando instancia individual: $scheduleId');
      await FirebaseFirestore.instance.collection('scheduledRooms').doc(scheduleId).delete();
      print('[DELETE_DEBUG] Instancia eliminada exitosamente');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programação "$scheduleName" eliminada.'), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        )
      );
      Navigator.pop(context); // Volver a la lista si la eliminación fue exitosa
    } catch (e) {
      print('[DELETE_DEBUG] ERRO ao eliminar programação individual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao eliminar: ${e.toString()}'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          )
        );
      }
    }
    // TODO: Ocultar indicador de loading
  }

  Future<void> _deleteAllFutureSchedules(ScheduledRoomModel currentSchedule, String scheduleName) async {
    if (!mounted) return;
    // TODO: Mostrar indicador de loading
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      String idToQuery = currentSchedule.originalScheduleId ?? currentSchedule.id;
      
      print('[DELETE_DEBUG] Iniciando eliminación de futuras...');
      print('[DELETE_DEBUG] ID para consulta: $idToQuery');
      print('[DELETE_DEBUG] Fecha actual de la instancia: ${currentSchedule.date.toDate()}');

      // 1. Primero, verificar si existe una plantilla
      DocumentSnapshot plantillaDoc = await FirebaseFirestore.instance
          .collection('scheduledRooms')
          .doc(idToQuery)
          .get();
      
      bool plantillaExists = plantillaDoc.exists;
      print('[DELETE_DEBUG] ¿Plantilla existe?: $plantillaExists');

      // 2. Eliminar todas las instancias futuras (incluyendo la actual)
      QuerySnapshot futureInstances = await FirebaseFirestore.instance
          .collection('scheduledRooms')
          .where('originalScheduleId', isEqualTo: idToQuery)
          .where('date', isGreaterThanOrEqualTo: currentSchedule.date)
          .get();

      print('[DELETE_DEBUG] Instancias futuras encontradas: ${futureInstances.docs.length}');
      
      for (var doc in futureInstances.docs) {
        print('[DELETE_DEBUG] Eliminando instancia: ${doc.id} - fecha: ${(doc.data() as Map<String, dynamic>)['date']?.toDate()}');
        batch.delete(doc.reference);
      }
      
      // 3. Si estamos eliminando la instancia actual y es la plantilla misma
      if (currentSchedule.id == idToQuery) {
        print('[DELETE_DEBUG] La instancia actual ES la plantilla. Será eliminada.');
        batch.delete(FirebaseFirestore.instance.collection('scheduledRooms').doc(idToQuery));
      } else if (plantillaExists) {
        // 4. Si la plantilla existe y es diferente de la actual, actualizarla
        print('[DELETE_DEBUG] Actualizando plantilla para marcar fin de repetición');
        batch.update(plantillaDoc.reference, {
          'repeatWeekly': false,
          'repetitionEndDate': currentSchedule.date,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('[DELETE_DEBUG] Ejecutando batch.commit()...');
      await batch.commit();
      print('[DELETE_DEBUG] Batch commit completado exitosamente');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programação "$scheduleName" e todas as futuras repetições foram eliminadas.'), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        )
      );
      Navigator.pop(context); // Volver a la lista
    } catch (e, stackTrace) {
      print('[DELETE_DEBUG] ERRO ao eliminar programações futuras: $e');
      print('[DELETE_DEBUG] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao eliminar futuras: ${e.toString()}'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          )
        );
      }
    }
    // TODO: Ocultar indicador de loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Programação'), 
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('scheduledRooms').doc(widget.scheduledRoomId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
              final schedule = ScheduledRoomModel.fromFirestore(snapshot.data!);
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                tooltip: 'Eliminar Programação',
                onPressed: () => _deleteScheduleDialog(schedule),
              );
            }
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('scheduledRooms').doc(widget.scheduledRoomId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final schedule = ScheduledRoomModel.fromFirestore(snapshot.data!);

          bool canOpenManually = !schedule.isOpen; // Se puede abrir si no está abierta
          bool canCheckIn = schedule.isOpen; // Solo se puede hacer check-in si está abierta
          
          // Lógica adicional para `canOpenManually` si una "encerrada" pasada no debería poder reabrirse tal cual
          // DateTime now = DateTime.now();
          // DateTime scheduleEndDateTime = schedule.endTime.toDate();
          // if (scheduleDate.isBefore(today) || (scheduleDate.isAtSameMomentAs(today) && scheduleEndDateTime.isBefore(now))) {
          //   canOpenManually = false; // No permitir reabrir si ya pasó completamente (a menos que se quiera "clonar" o "reprogramar")
          // }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la Sala/Programación
                Text(schedule.description, style: AppTextStyles.subtitle1.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                  '${DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(schedule.date.toDate())}  ${DateFormat.Hm().format(schedule.startTime.toDate())} às ${DateFormat.Hm().format(schedule.endTime.toDate())}',
                  style: AppTextStyles.bodyText1?.copyWith(color: AppColors.textSecondary)
                ),
                const SizedBox(height: 16),

                // Botones Principales de Acción Condicionales
                if (schedule.isOpen) // Si está ABIERTA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.lock_outline, color: Colors.red), // Icono de candado cerrado
                      label: Text('ENCERRAR SALA', style: AppTextStyles.button.copyWith(color: Colors.red.shade700)),
                      onPressed: () => _handleOpenOrCloseRoom(schedule, false), // Pasa false para cerrar
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade700, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  )
                else if (canOpenManually) // Si está PREVISTA o ENCERRADA (y se permite reabrir)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open_outlined, color: Colors.white), // Icono de candado abierto
                      label: Text('ABRIR SALA AGORA', style: AppTextStyles.button.copyWith(color: Colors.white)),
                      onPressed: () => _handleOpenOrCloseRoom(schedule, true), // Pasa true para abrir
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canCheckIn ? () => _handleCheckInRoom(schedule) : null, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCheckIn ? AppColors.primary : Colors.grey.shade400, 
                      padding: const EdgeInsets.symmetric(vertical: 12), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: Text('CHECK-IN NA SALA', style: AppTextStyles.button.copyWith(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                // Botones de Acciones Secundarias
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionChip(Icons.edit_calendar_outlined, 'Editar\nprogramação', () => _navigateToEditSchedule(schedule)),
                    _buildActionChip(Icons.send_outlined, 'Enviar\nresumo', _handleSendSummary),
                    _buildActionChip(Icons.info_outline, 'Informação', () => _showRoomInformation(schedule)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),

                // Lista de Crianças
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total de crianças: ${schedule.checkedInChildIds.length}', style: AppTextStyles.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
                      // Aquí podría ir un botón para filtrar si la lista es muy larga
                    ],
                  ),
                ),
                TextField(
                  controller: _searchChildController,
                  decoration: InputDecoration(
                    hintText: 'Nome da criança / cód. etiqueta...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                  ),
                ),
                const SizedBox(height: 12),
                _buildCheckedInChildrenList(schedule.checkedInChildIds, _searchChildTerm, schedule),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,)
          ],
        ),
      ),
    );
  }

  Widget _buildCheckedInChildrenList(List<String> childIds, String searchTerm, ScheduledRoomModel currentSchedule) {
    if (childIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('Nenhuma criança com check-in nesta sala.', style: TextStyle(color: Colors.grey))),
      );
    }
    // Para la búsqueda, necesitaríamos fetchear todos los ChildModel y luego filtrar.
    // Por ahora, mostramos todos.
    // TODO: Implementar filtrado por searchTerm
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: childIds.length,
      itemBuilder: (context, index) {
        final childId = childIds[index];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('children').doc(childId).get(),
          builder: (context, childSnap) {
            if (!childSnap.hasData || !childSnap.data!.exists) {
              return ListTile(title: Text('Criança não encontrada: $childId'));
            }
            final child = ChildModel.fromFirestore(childSnap.data!);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: child.photoUrl != null && child.photoUrl!.isNotEmpty ? NetworkImage(child.photoUrl!) : null,
                  child: child.photoUrl == null || child.photoUrl!.isEmpty ? Text(_getInitials('${child.firstName} ${child.lastName}'), style: AppTextStyles.subtitle1.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)) : null,
                ),
                title: Text('${child.firstName} ${child.lastName}'),
                subtitle: Text(_calculateAge(child.dateOfBirth)),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                  onPressed: () => _showChildOptionsModal(context, child, currentSchedule),
                ),
                onTap: () => _showChildOptionsModal(context, child, currentSchedule),
              ),
            );
          },
        );
      },
    );
  }
} 