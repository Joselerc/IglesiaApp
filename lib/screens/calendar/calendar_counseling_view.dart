import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CalendarCounselingView extends StatefulWidget {
  final DateTime selectedDate;
  
  const CalendarCounselingView({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<CalendarCounselingView> createState() => _CalendarCounselingViewState();
}

class _CalendarCounselingViewState extends State<CalendarCounselingView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadCounselingAppointments();
  }
  
  @override
  void didUpdateWidget(CalendarCounselingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadCounselingAppointments();
    }
  }

  Future<void> _loadCounselingAppointments() async {
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
      // Normalizar a data selecionada para comparar apenas dia, mês e ano
      final selectedDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
      
      // A data seguinte (para criar um intervalo)
      final nextDay = selectedDay.add(const Duration(days: 1));
      
      // Referência ao documento do usuário
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      debugPrint('Buscando consultas de aconselhamento para: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}');
      
      // Verificar se o usuário é pastor para determinar a consulta correta
      final userDoc = await userRef.get();
      final userData = userDoc.data();
      final isUserPastor = userData?['role'] == 'pastor';
      
      QuerySnapshot appointmentsSnapshot;
      
      if (isUserPastor) {
        // Se for pastor, buscar consultas onde ele é o pastor
        appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('pastorId', isEqualTo: userRef)
            .where('status', isEqualTo: 'confirmed')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDay))
            .where('date', isLessThan: Timestamp.fromDate(nextDay))
            .get();
      } else {
        // Se for membro regular, buscar consultas onde ele é o usuário
        appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('counseling_appointments')
            .where('userId', isEqualTo: userRef)
            .where('status', isEqualTo: 'confirmed')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDay))
            .where('date', isLessThan: Timestamp.fromDate(nextDay))
            .get();
      }
      
      debugPrint('Encontradas ${appointmentsSnapshot.docs.length} consultas confirmadas para o dia selecionado');
      
      final appointments = <Map<String, dynamic>>[];
      
      for (final doc in appointmentsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final date = (data['date'] as Timestamp).toDate();
          // Calcular data de fim se existir endDate ou usando a duração
          final endDate = data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate()
              : date.add(Duration(minutes: data['sessionDuration'] as int? ?? 60));
          
          // Obter referência do outro participante (pastor ou usuário)
          final otherPersonRef = isUserPastor 
              ? data['userId'] as DocumentReference
              : data['pastorId'] as DocumentReference;
          
          // Obter dados do outro participante
          final otherPersonDoc = await otherPersonRef.get();
          final otherPersonData = otherPersonDoc.data() as Map<String, dynamic>?;
          final otherPersonName = otherPersonData?['name'] as String? ?? 'Sem nome';
          
          // Adicionar a consulta com todos os detalhes necessários
          appointments.add({
            'id': doc.id,
            'date': date,
            'endDate': endDate,
            'type': data['type'] as String? ?? 'online',
            'reason': data['reason'] as String? ?? 'Não especificado',
            'location': data['location'] as String? ?? '',
            'otherPersonName': otherPersonName,
            'isUserPastor': isUserPastor,
          });
          
        } catch (e) {
          debugPrint('Erro ao processar consulta de aconselhamento: $e');
        }
      }
      
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Erro ao carregar consultas de aconselhamento: $e');
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

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Você não tem consultas de aconselhamento confirmadas para este dia',
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

    // Mostrar la lista de citas
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        final date = appointment['date'] as DateTime;
        final endDate = appointment['endDate'] as DateTime;
        final type = appointment['type'] as String;
        final reason = appointment['reason'] as String;
        final otherPersonName = appointment['otherPersonName'] as String;
        final isUserPastor = appointment['isUserPastor'] as bool;
        final location = appointment['location'] as String;

        // Formatar a hora para exibição
        final startTime = DateFormat('HH:mm').format(date);
        final endTime = DateFormat('HH:mm').format(endDate);
        
        final title = isUserPastor 
            ? 'Aconselhamento com $otherPersonName' 
            : 'Aconselhamento com Pastor $otherPersonName';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con el tipo de cita
              // Cabeçalho com o tipo de consulta
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type == 'online' ? Colors.blue[100] : Colors.green[100],
                ),
                child: Row(
                  children: [
                    Icon(
                      type == 'online' ? Icons.video_call : Icons.person,
                      color: type == 'online' ? Colors.blue[700] : Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type == 'online' ? 'Aconselhamento Online' : 'Aconselhamento Presencial',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: type == 'online' ? Colors.blue[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Detalles de la cita
              // Detalhes da consulta
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la cita
                    // Título da consulta
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Fila con icono para el horario
                    // Linha com ícone para o horário
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
                    const SizedBox(height: 8),
                    
                    // Ubicación (si es presencial)
                    // Localização (se for presencial)
                    if (type == 'inPerson' && location.isNotEmpty) 
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Localização: $location',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (type == 'inPerson' && location.isNotEmpty)
                      const SizedBox(height: 8),
                    
                    // Motivo (opcional)
                    // Motivo (opcional)
                    if (reason != 'Não especificado')
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Motivo: $reason',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    
                    // Botón para ir a detalles (opcional)
                    // Botão para ir aos detalhes (opcional)
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/counseling');
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ver Detalhes'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 