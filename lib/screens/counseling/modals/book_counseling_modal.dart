import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/pastor_availability.dart';
import '../../../l10n/app_localizations.dart';

class BookCounselingModal extends StatefulWidget {
  const BookCounselingModal({super.key});

  @override
  State<BookCounselingModal> createState() => _BookCounselingModalState();
}

class _BookCounselingModalState extends State<BookCounselingModal> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Estados para la selección
  DocumentReference? _selectedPastorRef;
  String _appointmentType = 'online'; // 'online' o 'inPerson'
  bool _hasSelectedType = false; // Para rastrear si el usuario ha seleccionado activamente un tipo
  DateTime? _selectedDate;
  String? _selectedTime;
  
  // Estados de carga
  bool _isLoadingAvailability = false;
  bool _isBooking = false;
  
  // Datos de disponibilidad
  PastorAvailability? _pastorAvailability;
  List<String> _availableTimes = [];
  
  // Controlador para el campo de razón
  final TextEditingController _reasonController = TextEditingController();
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPastorAvailability() async {
    if (_selectedPastorRef == null) return;

    setState(() {
      _isLoadingAvailability = true;
      _selectedDate = null;
      _selectedTime = null;
      _pastorAvailability = null;
      _availableTimes = [];
      _hasSelectedType = false;
      _appointmentType = 'online';
    });

    try {
      final availabilityDoc = await _firestore
          .collection('pastor_availability')
          .doc(_selectedPastorRef!.id)
          .get();

      if (!availabilityDoc.exists) {
        throw Exception(AppLocalizations.of(context)!.pastorHasNotConfiguredAvailability);
      }
      
      _pastorAvailability = PastorAvailability.fromFirestore(availabilityDoc);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString()))),
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
  
  Future<void> _selectDate(BuildContext context) async {
    if (_pastorAvailability == null) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _getNextAvailableDate(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) {
        // Solo permitir seleccionar días disponibles
        return _pastorAvailability!.isDayAvailable(day);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _loadAvailableTimesForDate();
      });
    }
  }

  DateTime _getNextAvailableDate() {
    if (_pastorAvailability == null) return DateTime.now();
    
    DateTime date = DateTime.now();
    // Buscar el próximo día disponible
    for (int i = 0; i < 90; i++) {
      if (_pastorAvailability!.isDayAvailable(date)) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    return DateTime.now();
  }
  
  void _loadAvailableTimesForDate() {
    if (_pastorAvailability == null || _selectedDate == null) return;
    
    setState(() {
      _availableTimes = [];
    });
    
    // Obtener el horario para el día seleccionado
    final daySchedule = _pastorAvailability!.getScheduleForDay(_selectedDate!);
    
    if (!daySchedule.isWorking || daySchedule.timeSlots.isEmpty) return;
    
    // Generar slots para cada franja horaria
    for (final timeSlot in daySchedule.timeSlots) {
      // Verificar si la franja es del tipo seleccionado (online o presencial)
      if ((_appointmentType == 'online' && !timeSlot.isOnline) ||
          (_appointmentType == 'inPerson' && !timeSlot.isInPerson)) {
        continue;
      }
      
      // Convertir las horas de string a TimeOfDay
      final startParts = timeSlot.start.split(':');
      final endParts = timeSlot.end.split(':');
      
      final start = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      
      final end = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      
      // Duración de la sesión en minutos
      final sessionDuration = _pastorAvailability!.sessionDuration;
      final breakDuration = _pastorAvailability!.breakDuration;
      
      // Generar slots de tiempo disponibles para esta franja
      final slots = _generateTimeSlots(start, end, sessionDuration, breakDuration);
      
      // Añadir a la lista de slots disponibles
      _availableTimes.addAll(slots);
    }
    
    // Verificar qué slots ya están reservados
    _checkAvailableSlots(_availableTimes);
  }
  
  List<String> _generateTimeSlots(
    TimeOfDay start,
    TimeOfDay end,
    int sessionDuration,
    int breakDuration
  ) {
    final slots = <String>[];
    
    // Convertir a minutos desde medianoche para facilitar cálculos
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;
    
    // Si el fin es antes que el inicio (por ejemplo, 17:00 a 9:00), ajustar
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Añadir un día completo
    }
    
    // Calcular slots
    int currentMinutes = startMinutes;
    while (currentMinutes + sessionDuration <= endMinutes) {
      // Convertir minutos a formato de hora
      final hour = (currentMinutes ~/ 60) % 24;
      final minute = currentMinutes % 60;
      
      final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      slots.add(timeString);
      
      // Avanzar al siguiente slot
      currentMinutes += sessionDuration + breakDuration;
    }
    
    return slots;
  }
  
  Future<void> _checkAvailableSlots(List<String> slots) async {
    if (_selectedPastorRef == null || _selectedDate == null) return;
    
    try {
      // Crear fecha de inicio y fin para el día seleccionado
      final startOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      final endOfDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        23,
        59,
        59,
      );
      
      // Buscar citas existentes para este pastor en esta fecha
      final querySnapshot = await _firestore
          .collection('counseling_appointments')
          .where('pastorId', isEqualTo: _selectedPastorRef)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      // Crear un conjunto de horas ya reservadas
      final bookedTimes = <String>{};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        bookedTimes.add('$hour:$minute');
      }
      
      // Filtrar los slots disponibles
      final availableSlots = slots.where((slot) => !bookedTimes.contains(slot)).toList();
      
      setState(() {
        _availableTimes = availableSlots;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorCheckingAvailability(e.toString()))),
        );
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedPastorRef == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseCompleteAllFields)),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception(AppLocalizations.of(context)!.userNotAuthenticated);
      
      final userRef = _firestore.collection('users').doc(userId);
      
      // Crear la fecha y hora de la cita
      final appointmentTime = _selectedTime!.split(':');
      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.parse(appointmentTime[0]),
        int.parse(appointmentTime[1]),
      );

      // Duración de la sesión
      final sessionDuration = _pastorAvailability?.sessionDuration ?? 60;

      // Crear la cita
      await _firestore.collection('counseling_appointments').add({
        'userId': userRef,
        'pastorId': _selectedPastorRef,
        'date': Timestamp.fromDate(appointmentDate),
        'endDate': Timestamp.fromDate(
          appointmentDate.add(Duration(minutes: sessionDuration)),
        ),
        'type': _appointmentType,
        'status': 'pending', // pending, confirmed, cancelled, completed
        'reason': _reasonController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.appointmentRequestedSuccessfully)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorBooking(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.requestCounseling,
                style: const TextStyle(
                  fontSize: 20,
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
          
          // Indicador de progreso
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(1, AppLocalizations.of(context)!.pastor, _selectedPastorRef != null),
                _buildStepConnector(),
                _buildStepIndicator(2, AppLocalizations.of(context)!.type, _hasSelectedType),
                _buildStepConnector(),
                _buildStepIndicator(3, AppLocalizations.of(context)!.date, _selectedDate != null),
                _buildStepConnector(),
                _buildStepIndicator(4, AppLocalizations.of(context)!.time, _selectedTime != null),
              ],
            ),
          ),
          
          const Divider(),
          const SizedBox(height: 16),
          
          // Contenido principal
          Expanded(
            child: _isLoadingAvailability 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selección de pastor
                    _buildSectionTitle(AppLocalizations.of(context)!.selectAPastor),
                    const SizedBox(height: 8),
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
                          return Center(child: Text(AppLocalizations.of(context)!.errorWithMessage(snapshot.error.toString())));
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text(AppLocalizations.of(context)!.noPastorsAvailable));
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
                              hint: Text(AppLocalizations.of(context)!.selectAPastor),
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
                                final name = data?['name'] as String? ?? AppLocalizations.of(context)!.noName;
                                return DropdownMenuItem<DocumentReference>(
                                  value: doc.reference,
                                  child: Text(name),
                                );
                              }).toList(),
                            ),
                          ),
                  );
                },
              ),
                    
                    const SizedBox(height: 24),
                    
                    // Tipo de cita
                    _buildSectionTitle(AppLocalizations.of(context)!.appointmentType),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                const Icon(Icons.video_call, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.online),
                              ],
                            ),
                            subtitle: Text(AppLocalizations.of(context)!.videoCallSession),
                            value: 'online',
                            groupValue: _appointmentType,
                            onChanged: (_pastorAvailability?.isAcceptingOnline ?? false)
                                ? (value) {
                                    if (value != null) {
                  setState(() {
                                      _appointmentType = value;
                                      _hasSelectedType = true;
                    _selectedTime = null;
                  });
                                    if (_selectedDate != null) {
                                      _loadAvailableTimesForDate();
                                    }
                                  }
                                }
                              : null,
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                const Icon(Icons.person, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.inPerson),
                              ],
                            ),
                            subtitle: Text(AppLocalizations.of(context)!.inPersonSession),
                            value: 'inPerson',
                            groupValue: _appointmentType,
                            onChanged: (_pastorAvailability?.isAcceptingInPerson ?? false)
                                ? (value) {
                                    if (value != null) {
                                      setState(() {
                                        _appointmentType = value;
                                        _hasSelectedType = true;
                                        _selectedTime = null;
                                      });
                                      if (_selectedDate != null) {
                                        _loadAvailableTimesForDate();
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    
                    if (_appointmentType == 'inPerson' && _pastorAvailability != null) ...[
                      const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                  ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                    children: [
                                const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                                Text(
                                  '${AppLocalizations.of(context)!.address}:',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_pastorAvailability!.location),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Fecha y hora
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(AppLocalizations.of(context)!.date),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pastorAvailability != null
                                    ? () => _selectDate(context)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, 
                                        size: 18, 
                                        color: _pastorAvailability != null 
                                          ? Theme.of(context).primaryColor 
                                          : Colors.grey
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selectedDate != null
                                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                            : AppLocalizations.of(context)!.selectDate,
                                        style: TextStyle(
                                          color: _pastorAvailability == null 
                                            ? Colors.grey 
                                            : Colors.black
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(AppLocalizations.of(context)!.time),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text(AppLocalizations.of(context)!.selectTime),
                                    value: _selectedTime,
                                    onChanged: _availableTimes.isNotEmpty
                                        ? (value) {
                                            setState(() {
                                              _selectedTime = value;
                                            });
                                          }
                                        : null,
                                    items: _availableTimes.map((time) {
                                      return DropdownMenuItem<String>(
                                        value: time,
                                        child: Text(time),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Razón de la cita
                    _buildSectionTitle(AppLocalizations.of(context)!.reasonForCounseling),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.brieflyDescribeReason,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón de reserva
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
              onPressed: _isBooking ? null : _bookAppointment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isBooking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.requestAppointment),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildStepIndicator(int step, String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade300,
            ),
            child: Center(
              child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
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
              color: isCompleted 
                ? Theme.of(context).primaryColor 
                : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepConnector() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.grey.shade300,
    );
  }
}
