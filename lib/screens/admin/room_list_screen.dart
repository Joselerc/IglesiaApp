import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/scheduled_room_model.dart'; // Usaremos este modelo
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import './scheduled_room_details_screen.dart'; // <-- AÑADIR IMPORT
import 'package:intl/intl.dart'; // <-- AÑADIR IMPORT PARA DateFormat
import './create_edit_room_screen.dart'; // Asegurar que es este el que se importa
import '../checkin/checkout_qr_scanner_screen.dart'; // <-- AÑADIR IMPORT PARA CHECKOUT

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // void _navigateToScheduleRoom(KidRoomModel room, {String? meetingId}) { 
  //   // Esta navegación se hará desde el FAB o al tocar una programación específica
  // }
  void _navigateToCreateEditScheduledRoom({String? meetingId}) { 
    print(meetingId != null 
        ? 'Navegar para editar PROGRAMAÇÃO ID: $meetingId' 
        : 'Navegar para criar nova PROGRAMAÇÃO');
    Navigator.push(context, MaterialPageRoute(builder: (_) => 
      CreateEditRoomScreen( // Esta es la pantalla con el form complejo (antes ScheduleRoomScreen)
        meetingId: meetingId, 
      )
    ));
  }


  void _openCheckoutOptions() {
    print('Abrir opções de Checkout Geral');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutQRScannerScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Programações de Sala'), // Título actualizado
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController, // Asignar controlador
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'ABERTAS'),
              Tab(text: 'PREVISTAS'),
              Tab(text: 'ENCERRADAS'),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text('Checkout', style: TextStyle(color: Colors.white)),
              onPressed: _openCheckoutOptions,
            )
          ],
        ),
        backgroundColor: AppColors.background,
        body: TabBarView(
          controller: _tabController, // Asignar controlador
          children: [
            _buildScheduledRoomList('abertas'), // Pestaña para salas abiertas
            _buildScheduledRoomList('previstas'), // Pestaña para salas previstas
            _buildScheduledRoomList('encerradas'), // Pestaña para salas encerradas
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_add_schedule', 
              onPressed: () => _navigateToCreateEditScheduledRoom(), // Llama sin meetingId para crear nueva programación
              label: const Text('NOVA PROGRAMAÇÃO'), 
              icon: const Icon(Icons.add_alarm_outlined),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir la lista de programaciones para cada pestaña
  Widget _buildScheduledRoomList(String tabStatus) {
    Query query = FirebaseFirestore.instance.collection('scheduledRooms');
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day); 
    TimeOfDay currentTime = TimeOfDay.fromDateTime(now);

    if (tabStatus == 'abertas') {
      query = query.where('isOpen', isEqualTo: true)
                   .orderBy('date').orderBy('startTime'); // Ordenar como prefieras
    } else if (tabStatus == 'encerradas') {
      query = query.where('isOpen', isEqualTo: false)
                   .orderBy('date', descending: true).orderBy('startTime', descending: true);
    } else if (tabStatus == 'previstas') {
      // Para "Previstas", la lógica es: NO está en Abertas Y NO está en Encerradas (según el admin) Y es futura.
      // La forma más simple de obtener esto es consultar las que tienen fecha futura y isOpen=false.
      // Si una futura tiene isOpen=true por el switch de creación, aparecerá en "Abertas" según tu última aclaración.
      // Si el admin la cierra manualmente, irá a "Encerradas".
      // Por lo tanto, "Previstas" son simplemente las que tienen isOpen=false Y su fecha/hora de inicio es futura.
      query = query
          .where('isOpen', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today)) // Desde hoy en adelante
          .orderBy('date').orderBy('startTime');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar programações: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Nenhuma programação "${tabStatus.toUpperCase()}" por aqui.'));
        }

        List<ScheduledRoomModel> allFetchedSchedules = snapshot.data!.docs
            .map((doc) => ScheduledRoomModel.fromFirestore(doc))
            .toList();
        
        List<ScheduledRoomModel> displaySchedules = [];

        for (var schedule in allFetchedSchedules) {
          bool isToday = schedule.date.toDate().year == today.year && schedule.date.toDate().month == today.month && schedule.date.toDate().day == today.day;
          bool isDateFuture = schedule.date.toDate().isAfter(today);
          bool isTimeCurrent = isToday && (currentTime.hour * 60.0 + currentTime.minute >= TimeOfDay.fromDateTime(schedule.startTime.toDate()).hour * 60.0 + TimeOfDay.fromDateTime(schedule.startTime.toDate()).minute && currentTime.hour * 60.0 + currentTime.minute <= TimeOfDay.fromDateTime(schedule.endTime.toDate()).hour * 60.0 + TimeOfDay.fromDateTime(schedule.endTime.toDate()).minute);
          bool isTimeFutureToday = isToday && (currentTime.hour * 60.0 + currentTime.minute < TimeOfDay.fromDateTime(schedule.startTime.toDate()).hour * 60.0 + TimeOfDay.fromDateTime(schedule.startTime.toDate()).minute);

          if (tabStatus == 'abertas') {
            if (schedule.isOpen) { 
              displaySchedules.add(schedule);
            }
          } else if (tabStatus == 'previstas') {
            bool actuallyOpenNow = schedule.isOpen && isTimeCurrent;
            if (!actuallyOpenNow && (isDateFuture || isTimeFutureToday)) {
              // Aplicar filtro de 2 semanas para "Previstas"
              DateTime twoWeeksFromNow = today.add(const Duration(days: 14));
              if (schedule.date.toDate().isBefore(twoWeeksFromNow) || schedule.date.toDate().isAtSameMomentAs(twoWeeksFromNow)) {
                displaySchedules.add(schedule);
              }
            }
          } else if (tabStatus == 'encerradas') {
            bool isDatePast = schedule.date.toDate().isBefore(today);
            bool timeHasPassedToday = isToday && (currentTime.hour * 60.0 + currentTime.minute > TimeOfDay.fromDateTime(schedule.endTime.toDate()).hour * 60.0 + TimeOfDay.fromDateTime(schedule.endTime.toDate()).minute);
            if (!schedule.isOpen && (isDatePast || timeHasPassedToday || (isToday && !isTimeFutureToday && !isTimeCurrent) )) {
              displaySchedules.add(schedule);
            }
          }
        }
        
        if (displaySchedules.isEmpty) {
           return Center(child: Text('Nenhuma programação "${tabStatus.toUpperCase()}" para exibir.'));
        }

        // Ordenar
        if (tabStatus == 'encerradas') {
          // Ya ordenadas por Firestore
        } else { // Abertas y Previstas
            displaySchedules.sort((a, b) {
                int dateComp = a.date.compareTo(b.date);
                if (dateComp != 0) return dateComp;
                return a.startTime.compareTo(b.startTime);
            });
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: displaySchedules.length,
          itemBuilder: (context, index) {
            final schedule = displaySchedules[index];
            int childrenInScheduleCount = schedule.checkedInChildIds.length;
            
            String timeRange = '';
            try {
              timeRange = '${DateFormat.Hm().format(schedule.startTime.toDate())} - ${DateFormat.Hm().format(schedule.endTime.toDate())}';
            } catch (e) {
              print('Error formateando hora para schedule ${schedule.id}: $e');
              timeRange = 'Horário inválido';
            }

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: schedule.isOpen && tabStatus == 'abertas' ? Colors.green.shade100 : AppColors.primary.withOpacity(0.15),
                  child: Text(
                    childrenInScheduleCount.toString(), 
                    style: AppTextStyles.subtitle1.copyWith(
                        color: schedule.isOpen && tabStatus == 'abertas' ? Colors.green.shade700 : AppColors.primary, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18
                    )
                  ),
                ),
                title: Text(schedule.description, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  // Aquí mostramos la fecha y hora, el roomName (que es la descripción) ya está en el title.
                  '${DateFormat('dd/MM/yyyy').format(schedule.date.toDate())} às $timeRange\n${schedule.ageRange ?? "N/A"} - ${schedule.isOpen ? "Aberta" : (schedule.repeatWeekly ? "Repete Semanalmente" : "Programada")}',
                  style: AppTextStyles.caption.copyWith(color: AppTextStyles.caption.color?.withOpacity(0.8) ?? AppColors.textSecondary, height: 1.3),
                ),
                isThreeLine: true,
                trailing: Icon(Icons.arrow_forward_ios, color: AppTextStyles.caption.color ?? AppColors.textSecondary, size: 18),
                onTap: () {
                  // Navegar a la PANTALLA DE DETALLES de la programación
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    ScheduledRoomDetailsScreen(
                      scheduledRoomId: schedule.id, 
                      // roomId: schedule.roomId, // Ya no está en ScheduledRoomModel, y Details no lo necesita directamente ahora
                      // roomName: schedule.description, // Details lo tomará de la descripción del schedule
                    )
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }
} 