import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../l10n/app_localizations.dart';
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
  late final Stream<QuerySnapshot> _pastorAvailabilityStream;
  final Map<String, Future<DocumentSnapshot>> _userDocFutures = {};

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
  bool _filterOnline = true;
  bool _filterInPerson = true;
  String? _selectedMode;
  final ScrollController _pastorListController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Asegurar que el teléfono se cargue correctamente al iniciar
    _phoneController.text = ''; // Limpiar valor inicial
    _loadUserPhone();
    _pastorAvailabilityStream = _firestore
        .collection('pastor_availability')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _phoneController.dispose();
    _pastorListController.dispose();
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
        if (userData['phone'] != null &&
            userData['phone'].toString().isNotEmpty) {
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
        if (_selectedMode == 'online' && !availability.isAcceptingOnline) {
          _selectedMode = availability.isAcceptingInPerson ? 'inPerson' : null;
        } else if (_selectedMode == 'inPerson' &&
            !availability.isAcceptingInPerson) {
          _selectedMode = availability.isAcceptingOnline ? 'online' : null;
        }

        _onlineSelected = _selectedMode == 'online';
        _inPersonSelected = _selectedMode == 'inPerson';
        _selectedDay = null;
        _availableDays.clear();
        _availableTimeSlots.clear();
        _selectedTimeSlot = null;
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
    } finally {}
  }

  void _clearSelectionState() {
    setState(() {
      _selectedPastorRef = null;
      _pastorAvailability = null;
      _selectedMode = null;
      _onlineSelected = false;
      _inPersonSelected = false;
      _selectedDay = null;
      _availableDays.clear();
      _availableTimeSlots.clear();
      _selectedTimeSlot = null;
    });
  }

  void _selectMode(String mode) {
    setState(() {
      _selectedMode = mode;
      _onlineSelected = mode == 'online';
      _inPersonSelected = mode == 'inPerson';
      _selectedDay = null;
      _availableDays.clear();
      _availableTimeSlots.clear();
      _selectedTimeSlot = null;
    });

    if (_pastorAvailability != null) _calculateAvailableDays();
  }

  void _toggleFilter({required bool online}) {
    setState(() {
      if (online) {
        _filterOnline = !_filterOnline;
      } else {
        _filterInPerson = !_filterInPerson;
      }

      if (!_filterOnline && !_filterInPerson) {
        if (online) {
          _filterInPerson = true;
        } else {
          _filterOnline = true;
        }
      }
    });
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
        final startTimeStr =
            '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
        final endTimeStr =
            '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

        // Crear objeto TimeSlot para esta franja calculada
        calculatedSlots.add(TimeSlot(
          start: startTimeStr,
          end: endTimeStr,
          isOnline: configuredSlot.isOnline,
          isInPerson: configuredSlot.isInPerson,
        ));

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
    if (_selectedPastorRef == null ||
        _selectedDay == null ||
        _pastorAvailability == null) return;

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
        23,
        59,
        59,
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

        bookedSlots.add({'start': startMinutes, 'end': endMinutes});
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

        int startMinutes =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
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
            final startTimeStr =
                '${(currentTime ~/ 60).toString().padLeft(2, '0')}:${(currentTime % 60).toString().padLeft(2, '0')}';
            final endTimeStr =
                '${((currentTime + sessionDuration) ~/ 60).toString().padLeft(2, '0')}:${((currentTime + sessionDuration) % 60).toString().padLeft(2, '0')}';

            adjustedSlots.add(TimeSlot(
                start: startTimeStr,
                end: endTimeStr,
                isOnline: configuredSlot.isOnline,
                isInPerson: configuredSlot.isInPerson));

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
    if (_selectedPastorRef == null ||
        _selectedDay == null ||
        _selectedTimeSlot == null ||
        _reasonController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Por favor, preencha todos os campos, incluindo o motivo'),
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
    switch (_selectedMode) {
      case 'online':
        return 'online';
      case 'inPerson':
        return 'inPerson';
      default:
        return 'both';
    }
  }

  // Widget para seleccionar pastor y modalidad
  Widget _buildPastorSelection() {
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione um Pastor',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'Online',
              Icons.videocam,
              _filterOnline,
              () => _toggleFilter(online: true),
            ),
            _buildFilterChip(
              'Presencial',
              Icons.person,
              _filterInPerson,
              () => _toggleFilter(online: false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _pastorAvailabilityStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
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

            final rawDocs = snapshot.data?.docs ?? [];
            final availableOptions = rawDocs
                .map((doc) {
                  try {
                    final availability = PastorAvailability.fromFirestore(doc);
                    if (!availability.hasUpcomingAvailability()) return null;
                    return _AvailabilityOption(
                      availability: availability,
                      userRef: availability.userId,
                    );
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<_AvailabilityOption>()
                .toList();

            if (availableOptions.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noPastorsAvailable,
                  style: AppTextStyles.bodyText1
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            final filteredOptions = availableOptions.where((option) {
              final acceptsOnline = option.availability.isAcceptingOnline;
              final acceptsInPerson = option.availability.isAcceptingInPerson;
              return (acceptsOnline && _filterOnline) ||
                  (acceptsInPerson && _filterInPerson);
            }).toList();

            final selectedOption = _findSelectedOption(availableOptions);
            if (selectedOption == null && _selectedPastorRef != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _clearSelectionState();
                }
              });
            }

            final displayOptions =
                selectedOption != null ? [selectedOption] : filteredOptions;

            if (displayOptions.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noPastorsAvailable,
                  style: AppTextStyles.bodyText1
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }

            final maxListHeight = MediaQuery.of(context).size.height * 0.45;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Scrollbar(
                  controller: _pastorListController,
                  thumbVisibility: true,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxListHeight),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      controller: _pastorListController,
                      padding: EdgeInsets.zero,
                      itemCount: displayOptions.length,
                      itemBuilder: (context, index) =>
                          _buildPastorAvailabilityTile(
                        displayOptions[index],
                        locale,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
                  ),
                ),
                if (selectedOption != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Tipo de Aconselhamento',
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeChip(
                          'Online',
                          Icons.videocam,
                          _selectedMode == 'online',
                          selectedOption.availability.isAcceptingOnline
                              ? () => _selectMode('online')
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModeChip(
                          'Presencial',
                          Icons.person,
                          _selectedMode == 'inPerson',
                          selectedOption.availability.isAcceptingInPerson
                              ? () => _selectMode('inPerson')
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPastorAvailabilityTile(
      _AvailabilityOption option, Locale locale) {
    final isSelected = _selectedPastorRef?.id == option.userRef.id;
    final nextAvailable = option.availability.getNextAvailableDate();
    final formattedDate = nextAvailable != null
        ? DateFormat('EEE, d MMM', locale.toLanguageTag()).format(nextAvailable)
        : null;

    final userFuture = _userDocFutures.putIfAbsent(
      option.userRef.id,
      () => option.userRef.get(),
    );

    return FutureBuilder<DocumentSnapshot>(
      future: userFuture,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final displayName = _extractDisplayName(userData);
        final photoUrl = userData?['photoUrl'] as String? ?? '';
        final isLoadingUser =
            snapshot.connectionState == ConnectionState.waiting;

        return InkWell(
          onTap: () {
            if (isSelected) {
              _clearSelectionState();
              return;
            }

            setState(() {
              _selectedPastorRef = option.userRef;
              _selectedMode = null;
              _onlineSelected = false;
              _inPersonSelected = false;
            });
            _loadPastorAvailability();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade200,
                width: isSelected ? 0 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Icon(Icons.person, color: AppColors.primary, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoadingUser && displayName.isEmpty
                            ? AppLocalizations.of(context)!.loadingPastorInfo
                            : (displayName.isNotEmpty
                                ? displayName
                                : AppLocalizations.of(context)!.pastor),
                        style: AppTextStyles.bodyText2
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (formattedDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(formattedDate, style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (option.availability.isAcceptingOnline)
                              _buildAvailabilityBadge('Online', Icons.videocam),
                            if (option.availability.isAcceptingOnline &&
                                option.availability.isAcceptingInPerson)
                              const SizedBox(width: 8),
                            if (option.availability.isAcceptingInPerson)
                              _buildAvailabilityBadge(
                                  'Presencial', Icons.person),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeChip(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback? onTap,
  ) {
    final enabled = onTap != null;
    final bg = !enabled
        ? Colors.grey.shade200
        : (isActive ? AppColors.primary : Colors.grey.shade100);
    final fg = !enabled
        ? Colors.grey
        : (isActive ? Colors.white : AppColors.textSecondary);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyText2.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return enabled
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: child,
          )
        : child;
  }

  Widget _buildAvailabilityBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.primary.withOpacity(0.16),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  _AvailabilityOption? _findSelectedOption(List<_AvailabilityOption> options) {
    if (_selectedPastorRef == null) return null;
    for (final option in options) {
      if (option.userRef.id == _selectedPastorRef!.id) {
        return option;
      }
    }
    return null;
  }

  String _extractDisplayName(Map<String, dynamic>? data) {
    if (data == null) return '';
    final displayName = (data['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final first = (data['name'] as String?)?.trim() ?? '';
    final last = (data['surname'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    return (data['email'] as String?) ?? '';
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
              return _availableDays
                  .contains(DateTime(day.year, day.month, day.day));
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
                  AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: AppColors.primary),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: AppColors.primary),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle:
                  AppTextStyles.bodyText2.copyWith(color: Colors.red),
              disabledTextStyle:
                  AppTextStyles.bodyText2.copyWith(color: Colors.grey),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final normalized = DateTime(day.year, day.month, day.day);
                final isAvailable = _availableDays.contains(normalized);
                if (!isAvailable) return null;
                if (isSameDay(_selectedDay, day)) return null;
                if (isSameDay(DateTime.now(), day)) return null;

                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
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
                  style: AppTextStyles.bodyText1
                      .copyWith(color: AppColors.textSecondary),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${slot.start} - ${slot.end}',
                        style: AppTextStyles.bodyText2.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue.shade700,
                            ),
                          if (slot.isOnline && slot.isInPerson)
                            SizedBox(width: 4),
                          if (slot.isInPerson)
                            Icon(
                              Icons.person,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.green.shade700,
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

  // Widget para el formulario de detalles (ya no es un ListView para evitar conflictos de scroll)
  Widget _buildDetailsForm() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.counselingDetailsTitle,
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Motivo de la consulta
        Text(
          loc.counselingReasonLabel,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: loc.counselingReasonHint,
            hintStyle: AppTextStyles.bodyText2
                .copyWith(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          maxLines: 3,
          style: AppTextStyles.bodyText2,
        ),
        const SizedBox(height: 16),

        // Número de teléfono
        Text(
          loc.counselingPhoneLabel,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _phoneController,
          builder: (context, value, _) {
            final phoneText = value.text;
            return TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: loc.counselingPhoneExample,
                hintStyle: AppTextStyles.bodyText2
                    .copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                suffixIcon: _isValidPhone(phoneText)
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 20)
                    : null,
              ),
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyText2,
            );
          },
        ),
        const SizedBox(height: 16),

        // Aceptación de comunicaciones
        CheckboxListTile(
          title: Text(
            loc.counselingWhatsappConsent,
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
        return _selectedPastorRef != null && _selectedMode != null;
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
  /*
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
  */

  // Función para validar formato de teléfono
  bool _isValidPhone(String phone) {
    // Validación básica: al menos 9 dígitos y puede tener el prefijo +
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return cleanPhone.length >= 9;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Text(
                  loc.requestCounselingTitle,
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
                  _buildStepIndicator(0, loc.stepPastor, _selectedPastorRef != null),
                  _buildStepConnector(),
                  _buildStepIndicator(1, loc.date, _selectedDay != null),
                  _buildStepConnector(),
                  _buildStepIndicator(2, loc.time, _selectedTimeSlot != null),
                  _buildStepConnector(),
                  _buildStepIndicator(3, loc.stepDetails, false),
                ],
              ),
            ),

            const Divider(),
            const SizedBox(height: 16),

            // Contenido principal basado en el paso actual
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: [
                      _buildPastorSelection(),
                      _buildCalendarSelection(),
                      _buildTimeSlotSelection(),
                      _buildDetailsForm(),
                    ][_currentStep],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botones de navegación
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(loc.buttonPrevious),
                    ),
                  const Spacer(),
                  if (_currentStep < 3)
                    ElevatedButton(
                      onPressed: _canAdvanceToNextStep()
                          ? () {
                              setState(() {
                                _currentStep++;

                                // Si estamos avanzando al paso de detalles, verificar que el teléfono esté cargado
                                if (_currentStep == 3 &&
                                    _phoneController.text.isEmpty) {
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(loc.buttonNext),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(loc.buttonRequestAppointment),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityOption {
  final PastorAvailability availability;
  final DocumentReference userRef;

  const _AvailabilityOption({
    required this.availability,
    required this.userRef,
  });
}
