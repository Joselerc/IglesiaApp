import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/pastor_availability.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class NewBookCounselingModal extends StatefulWidget {
  const NewBookCounselingModal({super.key});

  @override
  State<NewBookCounselingModal> createState() => _NewBookCounselingModalState();
}

class _NewBookCounselingModalState extends State<NewBookCounselingModal> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Estado actual del flujo
  int _currentStep = 0;
  
  // Selección de pastor y tipo de cita
  DocumentReference? _selectedPastorRef;
  PastorAvailability? _pastorAvailability;
  bool _onlineSelected = true;
  bool _inPersonSelected = false;
  
  // Calendario y fechas
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _availableDays = {};
  
  // Franjas horarias y selección
  List<TimeSlot> _availableTimeSlots = [];
  TimeSlot? _selectedTimeSlot;
  
  // Información de la cita
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _acceptsWhatsApp = true;
  
  // Estado de carga
  bool _isLoading = false;
  bool _isLoadingAvailability = false;

  @override
  void initState() {
    super.initState();
    
    // Asegurar que el teléfono se cargue correctamente al iniciar
    _phoneController.text = ''; // Limpiar valor inicial
    _loadUserPhone();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Cargar el número de teléfono del usuario si existe
  Future<void> _loadUserPhone() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      print('Buscando informações do usuário com ID: $userId');
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('Dados do usuário encontrados: ${userData['phone']}'); // Debug
        
        // Si el usuario tiene un número de teléfono, lo cargamos
        if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) {
          if (mounted) {
            setState(() {
              _phoneController.text = userData['phone'].toString();
              print('Telefone carregado: ${_phoneController.text}'); // Debug
            });
          }
        }
      } else {
        print('Documento do usuário não encontrado'); // Debug
      }
    } catch (e) {
      print('Erro ao carregar informações do usuário: $e');
    }
  }

  // Cargar la disponibilidad del pastor seleccionado
  Future<void> _loadPastorAvailability() async {
    if (_selectedPastorRef == null) return;

    setState(() {
      _isLoadingAvailability = true;
      _availableDays.clear();
      _selectedDay = null;
      _availableTimeSlots.clear();
      _selectedTimeSlot = null;
    });

    try {
      final availabilityDoc = await _firestore
          .collection('pastor_availability')
          .doc(_selectedPastorRef!.id)
          .get();

      if (!availabilityDoc.exists) {
        throw Exception('O pastor não configurou sua disponibilidade');
      }
      
      // Cargar la disponibilidad
      final availability = PastorAvailability.fromFirestore(availabilityDoc);
      
      // Actualizar el estado con la disponibilidad
      setState(() {
        _pastorAvailability = availability;
        
        // Si el pastor no acepta online o presencial, actualizar las selecciones
        _onlineSelected = availability.isAcceptingOnline && _onlineSelected;
        _inPersonSelected = availability.isAcceptingInPerson && _inPersonSelected;
        
        // Si ninguno está seleccionado pero el pastor acepta alguno, seleccionarlo
        if (!_onlineSelected && !_inPersonSelected) {
          if (availability.isAcceptingOnline) {
            _onlineSelected = true;
          } else if (availability.isAcceptingInPerson) {
            _inPersonSelected = true;
          }
        }
      });
      
      // Calcular los días disponibles para los próximos 60 días
      _calculateAvailableDays();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
        });
      }
    }
  }

  // Calcular los días disponibles para mostrar en el calendario
  void _calculateAvailableDays() {
    if (_pastorAvailability == null) return;
    
    Set<DateTime> availableDays = {};
    
    // Verificar la disponibilidad para los próximos 60 días
    final now = DateTime.now();
    for (int i = 0; i < 60; i++) {
      final date = now.add(Duration(days: i));
      
      // Verificar si el día está disponible según la configuración del pastor
      if (_pastorAvailability!.isDayAvailable(date)) {
        // Obtener el horario para este día
        final daySchedule = _pastorAvailability!.getScheduleForDay(date);
        
        // Verificar si tiene franjas horarias disponibles
        if (daySchedule.isWorking && daySchedule.timeSlots.isNotEmpty) {
          // Verificar si hay al menos una franja que coincida con el tipo de cita seleccionado
          bool hasMatchingSlot = false;
          
          for (final slot in daySchedule.timeSlots) {
            if ((_onlineSelected && slot.isOnline) || 
                (_inPersonSelected && slot.isInPerson)) {
              hasMatchingSlot = true;
              break;
            }
          }
          
          if (hasMatchingSlot) {
            // Añadir a los días disponibles (normalizado a medianoche)
            availableDays.add(DateTime(date.year, date.month, date.day));
          }
        }
      }
    }
    
    setState(() {
      _availableDays = availableDays;
    });
  }

  // Calcular las franjas horarias disponibles para el día seleccionado
  // Este método se llama cada vez que cambia el día seleccionado, el tipo de cita,
  // o el pastor seleccionado, garantizando que los horarios disponibles se actualicen.
  // Incluye la lógica para mostrar horarios previamente bloqueados por citas canceladas.
  void _calculateAvailableTimeSlots() {
    if (_pastorAvailability == null || _selectedDay == null) return;
    
    // Obtener el horario para el día seleccionado
    final daySchedule = _pastorAvailability!.getScheduleForDay(_selectedDay!);
    
    // Lista para almacenar las franjas calculadas
    List<TimeSlot> calculatedSlots = [];
    
    // Duración de la sesión en minutos
    final sessionDuration = _pastorAvailability!.sessionDuration;
    // No aplicamos el breakDuration aquí, lo aplicaremos solo después de citas existentes
    
    // Para cada franja configurada por el pastor
    for (final configuredSlot in daySchedule.timeSlots) {
      // Verificar si la franja coincide con el tipo de cita seleccionado
      if (!(_onlineSelected && configuredSlot.isOnline) && 
          !(_inPersonSelected && configuredSlot.isInPerson)) {
        continue;
      }
      
      // Convertir las horas de string a TimeOfDay
      final startParts = configuredSlot.start.split(':');
      final endParts = configuredSlot.end.split(':');
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      // Convertir a minutos desde medianoche para facilitar cálculos
      int startMinutes = startHour * 60 + startMinute;
      int endMinutes = endHour * 60 + endMinute;
      
      // Ajustar si el fin es al día siguiente
      if (endMinutes <= startMinutes) {
        endMinutes += 24 * 60; // Añadir un día completo
      }
      
      // Calcular todas las franjas posibles, SIN AÑADIR BREAK AUTOMÁTICAMENTE
      int currentStart = startMinutes;
      while (currentStart + sessionDuration <= endMinutes) {
        // Convertir minutos a formato de hora
        final startHour = (currentStart ~/ 60) % 24;
        final startMinute = currentStart % 60;
        final endHour = ((currentStart + sessionDuration) ~/ 60) % 24;
        final endMinute = (currentStart + sessionDuration) % 60;
        
        // Crear string de hora
        final startTimeStr = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
        final endTimeStr = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
        
        // Crear objeto TimeSlot para esta franja calculada
        calculatedSlots.add(
          TimeSlot(
            start: startTimeStr,
            end: endTimeStr,
            isOnline: configuredSlot.isOnline, 
            isInPerson: configuredSlot.isInPerson,
          )
        );
        
        // Avanzar al siguiente slot (SOLO sumando la duración de la sesión, SIN descanso)
        currentStart += sessionDuration;
      }
    }
    
    // Verificar si hay franjas disponibles y filtrar las que ya están reservadas
    if (calculatedSlots.isNotEmpty) {
      _checkBookedTimeSlots(calculatedSlots);
    } else {
      setState(() {
        _availableTimeSlots = [];
      });
    }
  }

  // Verificar qué franjas ya están reservadas y reorganizar las siguientes
  // Este método filtra los horarios disponibles excluyendo los que ya están ocupados
  // por citas pendientes o confirmadas. Las citas canceladas o completadas NO bloquean
  // el horario para futuras reservas.
  Future<void> _checkBookedTimeSlots(List<TimeSlot> calculatedSlots) async {
    if (_selectedPastorRef == null || _selectedDay == null || _pastorAvailability == null) return;
    
    try {
      // Crear fecha de inicio y fin para el día seleccionado
      final startOfDay = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );

      final endOfDay = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        23, 59, 59,
      );
      
      // Obtener el horario para el día seleccionado
      final daySchedule = _pastorAvailability!.getScheduleForDay(_selectedDay!);
      
      // Buscar citas existentes para este pastor en esta fecha
      final querySnapshot = await _firestore
          .collection('counseling_appointments')
          .where('pastorId', isEqualTo: _selectedPastorRef)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      // Duración de la sesión y descanso
      final sessionDuration = _pastorAvailability!.sessionDuration;
      final breakDuration = _pastorAvailability!.breakDuration;
      
      // Lista de horas reservadas (convertidas a minutos para facilitar cálculos)
      List<Map<String, int>> bookedSlots = [];
      
      // Recopilar todas las citas reservadas
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Solo considerar citas activas (pendientes o confirmadas)
        final String status = data['status'] as String? ?? 'pending';
        if (status == 'cancelled' || status == 'completed') {
          // Ignorar citas canceladas o completadas
          continue;
        }
        
        final DateTime startDate = (data['date'] as Timestamp).toDate();
        
        // Convertir a minutos desde medianoche
        final startMinutes = startDate.hour * 60 + startDate.minute;
        final endMinutes = startMinutes + sessionDuration;
        
        bookedSlots.add({
          'start': startMinutes,
          'end': endMinutes
        });
      }
      
      // Ordenar las citas por hora de inicio
      bookedSlots.sort((a, b) => a['start']!.compareTo(b['start']!));
      
      // Si no hay citas reservadas, devolvemos todas las franjas calculadas
      if (bookedSlots.isEmpty) {
        setState(() {
          _availableTimeSlots = calculatedSlots;
        });
        return;
      }
      
      // Lista de franjas finales ajustadas
      List<TimeSlot> adjustedSlots = [];
      
      // Para cada bloque horario disponible
      for (final configuredSlot in daySchedule.timeSlots) {
        // Verificar si la franja coincide con el tipo de cita seleccionado
        if (!(_onlineSelected && configuredSlot.isOnline) && 
            !(_inPersonSelected && configuredSlot.isInPerson)) {
          continue;
        }
        
        // Convertir horas a minutos
        final startParts = configuredSlot.start.split(':');
        final endParts = configuredSlot.end.split(':');
        
        int startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        
        // Generar nuevas franjas considerando las reservas y descansos
        int currentTime = startMinutes;
        
        while (currentTime + sessionDuration <= endMinutes) {
          // Verificar si esta franja coincide con alguna reserva
          bool isBooked = bookedSlots.any((bookedSlot) => 
            bookedSlot['start']! <= currentTime && 
            bookedSlot['end']! > currentTime);
          
          if (isBooked) {
            // Encontrar la reserva que afecta a esta franja
            var activeBooking = bookedSlots.firstWhere((bookedSlot) => 
              bookedSlot['start']! <= currentTime && 
              bookedSlot['end']! > currentTime);
            
            // Avanzar al final de la reserva + el tiempo de descanso
            currentTime = activeBooking['end']! + breakDuration;
          } else {
            // Si no está reservada, crear nueva franja disponible
            final startTimeStr = '${(currentTime ~/ 60).toString().padLeft(2, '0')}:${(currentTime % 60).toString().padLeft(2, '0')}';
            final endTimeStr = '${((currentTime + sessionDuration) ~/ 60).toString().padLeft(2, '0')}:${((currentTime + sessionDuration) % 60).toString().padLeft(2, '0')}';
            
            adjustedSlots.add(TimeSlot(
              start: startTimeStr,
              end: endTimeStr,
              isOnline: configuredSlot.isOnline,
              isInPerson: configuredSlot.isInPerson
            ));
            
            // Avanzar al siguiente slot
            currentTime += sessionDuration;
          }
        }
      }
      
      setState(() {
        _availableTimeSlots = adjustedSlots;
      });
    } catch (e) {
      print('Error al verificar franjas reservadas: $e');
      
      // En caso de error, usar las franjas calculadas sin filtrar
      setState(() {
        _availableTimeSlots = calculatedSlots;
      });
    }
  }

  // Reservar la cita con los datos seleccionados
  Future<void> _bookAppointment() async {
    if (_selectedPastorRef == null || _selectedDay == null || 
        _selectedTimeSlot == null || _reasonController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, preencha todos os campos, incluindo o motivo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuário não autenticado');
      
      final userRef = _firestore.collection('users').doc(userId);
      
      // Guardar el teléfono del usuario PRIMERO para futuras reservas
      if (_phoneController.text.trim().isNotEmpty) {
        await userRef.update({
          'phone': _phoneController.text.trim(),
        }).catchError((error) {
          print('Erro ao salvar o telefone: $error');
          // Continuamos con la reserva aunque falle la actualización del teléfono
        });
      }
      
      // Crear la fecha y hora de la cita
      final startTimeParts = _selectedTimeSlot!.start.split(':');
      final appointmentDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      // Duración de la sesión (para la hora de fin)
      final sessionDuration = _pastorAvailability?.sessionDuration ?? 60;

      // Crear la cita
      await _firestore.collection('counseling_appointments').add({
        'userId': userRef,
        'pastorId': _selectedPastorRef,
        'date': Timestamp.fromDate(appointmentDate),
        'endDate': Timestamp.fromDate(
          appointmentDate.add(Duration(minutes: sessionDuration)),
        ),
        'type': _getAppointmentType(),
        'status': 'pending', // pending, confirmed, cancelled, completed
        'reason': _reasonController.text.trim(),
        'phone': _phoneController.text.trim(),
        'acceptsWhatsApp': _acceptsWhatsApp,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Consulta solicitada com sucesso'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao agendar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Obtener el tipo de cita basado en las selecciones
  String _getAppointmentType() {
    if (_onlineSelected && _inPersonSelected) {
      return 'both'; // El usuario puede elegir entre online o presencial
    } else if (_onlineSelected) {
      return 'online';
    } else {
      return 'inPerson';
    }
  }

  // Widget para seleccionar pastor y modalidad
  Widget _buildPastorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione um Pastor',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selector de pastor
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('role', isEqualTo: 'pastor')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro: ${snapshot.error}',
                  style: AppTextStyles.bodyText2.copyWith(color: Colors.red),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Não há pastores disponíveis',
                  style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            final pastors = snapshot.data!.docs;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DocumentReference>(
                  isExpanded: true,
                  hint: Text(
                    'Selecione um pastor',
                    style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
                  ),
                  value: _selectedPastorRef,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPastorRef = value;
                      });
                      _loadPastorAvailability();
                    }
                  },
                  items: pastors.map((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final name = data?['name'] as String? ?? 'Sem nome';
                    final surname = data?['surname'] as String? ?? '';
                    return DropdownMenuItem<DocumentReference>(
                      value: doc.reference,
                      child: Text('$name $surname'),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Selector de modalidad
        if (_pastorAvailability != null) ...[
          Text(
            'Tipo de Aconselhamento',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Opción Online
              Expanded(
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.videocam, size: 18),
                      SizedBox(width: 8),
                      Text('Online'),
                    ],
                  ),
                  selected: _onlineSelected,
                  onSelected: _pastorAvailability!.isAcceptingOnline 
                      ? (selected) {
                          setState(() {
                            _onlineSelected = selected;
                            // Si desmarca ambos, activar el otro si está disponible
                            if (!selected && !_inPersonSelected && _pastorAvailability!.isAcceptingInPerson) {
                              _inPersonSelected = true;
                            }
                            
                            // Recalcular días disponibles
                            _calculateAvailableDays();
                          });
                        }
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  disabledColor: Colors.grey.shade300,
                  labelStyle: TextStyle(
                    color: _pastorAvailability!.isAcceptingOnline 
                        ? AppColors.textPrimary
                        : Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Opción Presencial
              Expanded(
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 8),
                      Text('Presencial'),
                    ],
                  ),
                  selected: _inPersonSelected,
                  onSelected: _pastorAvailability!.isAcceptingInPerson 
                      ? (selected) {
                          setState(() {
                            _inPersonSelected = selected;
                            // Si desmarca ambos, activar el otro si está disponible
                            if (!selected && !_onlineSelected && _pastorAvailability!.isAcceptingOnline) {
                              _onlineSelected = true;
                            }
                            
                            // Recalcular días disponibles
                            _calculateAvailableDays();
                          });
                        }
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  disabledColor: Colors.grey.shade300,
                  labelStyle: TextStyle(
                    color: _pastorAvailability!.isAcceptingInPerson 
                        ? AppColors.textPrimary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  // Widget para seleccionar fecha
  Widget _buildCalendarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione uma Data',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Calendario
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            enabledDayPredicate: (day) {
              // Solo permitir seleccionar días disponibles
              return _availableDays.contains(DateTime(day.year, day.month, day.day));
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: AppTextStyles.bodyText2.copyWith(color: Colors.red),
              disabledTextStyle: AppTextStyles.bodyText2.copyWith(
                color: Colors.grey, 
                decoration: TextDecoration.lineThrough
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _calculateAvailableTimeSlots();
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ),
      ],
    );
  }
  
  // Widget para seleccionar hora
  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione um Horário',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_availableTimeSlots.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.access_time, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _selectedDay == null 
                      ? 'Selecione um dia para ver os horários disponíveis'
                      : 'Não há horários disponíveis para o dia selecionado',
                  style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _availableTimeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${slot.start} - ${slot.end}',
                        style: AppTextStyles.bodyText2.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (slot.isOnline)
                            Icon(
                              Icons.videocam,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.blue.shade700,
                            ),
                          if (slot.isOnline && slot.isInPerson)
                            SizedBox(width: 4),
                          if (slot.isInPerson)
                            Icon(
                              Icons.person,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.green.shade700,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Método específico para el formulario de detalles
  Widget _buildScrollableDetailsForm() {
    // Si el teléfono está vacío, intentar cargarlo nuevamente
    if (_phoneController.text.isEmpty) {
      _loadUserPhone();
    }
    
    return ListView(
      shrinkWrap: true,
      children: [
        Text(
          'Detalhes do Aconselhamento',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Motivo de la consulta
        Text(
          'Motivo do Aconselhamento',
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: 'Descreva brevemente o motivo da sua consulta',
            hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          maxLines: 3,
          onTap: () => _scrollToFocusedInput(_reasonController),
          style: AppTextStyles.bodyText2,
        ),
        const SizedBox(height: 16),
        
        // Número de teléfono
        Text(
          'Número de Telefone',
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            hintText: 'Ex. +55 11 98765-4321',
            hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            suffixIcon: _isValidPhone(_phoneController.text) 
                ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                : null,
          ),
          keyboardType: TextInputType.phone,
          onTap: () => _scrollToFocusedInput(_phoneController),
          onChanged: (value) {
            setState(() {});
          },
          style: AppTextStyles.bodyText2,
        ),
        const SizedBox(height: 16),
        
        // Aceptación de comunicaciones
        CheckboxListTile(
          title: Text(
            'Aceito receber comunicações por WhatsApp ou chamada relacionadas à minha consulta',
            style: AppTextStyles.bodyText2,
          ),
          value: _acceptsWhatsApp,
          onChanged: (value) {
            setState(() {
              _acceptsWhatsApp = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          dense: true,
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }
  
  // Verificar si se puede avanzar al siguiente paso
  bool _canAdvanceToNextStep() {
    switch (_currentStep) {
      case 0:
        return _selectedPastorRef != null && (_onlineSelected || _inPersonSelected);
      case 1:
        return _selectedDay != null;
      case 2:
        return _selectedTimeSlot != null;
      default:
        return false;
    }
  }
  
  // Widget para indicador de paso
  Widget _buildStepIndicator(int step, String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentStep == step
                  ? AppColors.primary
                  : (isCompleted 
                      ? AppColors.primary.withOpacity(0.7) 
                      : Colors.grey.shade300),
            ),
            child: Center(
              child: _currentStep > step || isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _currentStep == step
                  ? AppColors.primary
                  : (isCompleted 
                      ? AppColors.primary.withOpacity(0.7) 
                      : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para conector entre pasos
  Widget _buildStepConnector() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.grey.shade300,
    );
  }

  // Método para hacer scroll al campo que tiene foco cuando aparece el teclado
  void _scrollToFocusedInput(TextEditingController controller) {
    // Dar tiempo para que el teclado se muestre
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      // Obtener el contexto actual y ajustar la vista
      Scrollable.ensureVisible(
        FocusScope.of(context).focusedChild?.context ?? context,
        alignment: 0.5, // Centrar el campo
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  // Función para validar formato de teléfono
  bool _isValidPhone(String phone) {
    // Validación básica: al menos 9 dígitos y puede tener el prefijo +
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.length >= 9;
  }
  
  @override
  Widget build(BuildContext context) {
    // Obtener el padding inferior del sistema
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Añadir padding inferior al contenedor principal
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Text(
                'Solicitar Aconselhamento',
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          // Indicador de pasos
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Pastor', _selectedPastorRef != null),
                _buildStepConnector(),
                _buildStepIndicator(1, 'Data', _selectedDay != null),
                _buildStepConnector(),
                _buildStepIndicator(2, 'Horário', _selectedTimeSlot != null),
                _buildStepConnector(),
                _buildStepIndicator(3, 'Detalhes', false),
              ],
            ),
          ),
          
          const Divider(),
          const SizedBox(height: 16),
          
          // Contenido principal basado en el paso actual
          Expanded(
            child: _isLoadingAvailability 
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _currentStep == 3
                ? _buildScrollableDetailsForm()
                : SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: [
                        _buildPastorSelection(),
                        _buildCalendarSelection(),
                        _buildTimeSlotSelection(),
                        Container(), 
                      ][_currentStep],
                    ),
                  ),
          ),
          
          // Botones de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Anterior'),
                ),
              const Spacer(),
              if (_currentStep < 3)
                ElevatedButton(
                  onPressed: _canAdvanceToNextStep() 
                      ? () {
                          setState(() {
                            _currentStep++;
                            
                            // Si estamos avanzando al paso de detalles, verificar que el teléfono esté cargado
                            if (_currentStep == 3 && _phoneController.text.isEmpty) {
                              _loadUserPhone(); // Cargar teléfono nuevamente por si falló la primera vez
                            }
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Próximo'),
                )
              else
                ElevatedButton(
                  onPressed: _isLoading ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Solicitar Consulta'),
                ),
            ],
          ),
        ],
      ),
    );
  }
} 