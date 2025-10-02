import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/pastor_availability.dart' as model;
import 'widgets/day_schedule_dialog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';

class PastorAvailabilityScreen extends StatefulWidget {
  const PastorAvailabilityScreen({super.key});

  @override
  State<PastorAvailabilityScreen> createState() => _PastorAvailabilityScreenState();
}

class _PastorAvailabilityScreenState extends State<PastorAvailabilityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PermissionService _permissionService = PermissionService();
  
  bool _isLoading = true;
  String _pastorId = '';
  DocumentReference? _availabilityRef;
  
  // Datos de disponibilidad
  model.PastorAvailability? _availability;
  
  // Controladores para la dirección
  final TextEditingController _locationController = TextEditingController();
  
  // Valores para la duración de la sesión
  int _selectedDuration = 60;
  
  // Valores para los tipos de citas
  bool _acceptsOnline = true;
  bool _acceptsInPerson = true;
  
  // Valores para el descanso entre citas
  int _selectedBreakDuration = 0;
  
  // Semana seleccionada para configuración
  DateTime _selectedWeek = DateTime.now();
  Map<DateTime, model.DaySchedule> _weekSchedule = {};

  @override
  void initState() {
    super.initState();
    _selectedWeek = _getStartOfWeek(DateTime.now());
    _selectedDuration = 30;
    _selectedBreakDuration = 5;
    _loadAvailability();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // Obtener el inicio de la semana (lunes)
  DateTime _getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  // Obtener el fin de la semana (domingo)
  DateTime _getEndOfWeek(DateTime startOfWeek) {
    return startOfWeek.add(const Duration(days: 6));
  }

  // Obtener los días de la semana actual
  List<DateTime> _getDaysOfWeek() {
    final days = <DateTime>[];
    final startOfWeek = _selectedWeek;
    
    for (int i = 0; i < 7; i++) {
      days.add(startOfWeek.add(Duration(days: i)));
    }
    
    return days;
  }

  // Obtener el nombre del día en español
  String _getDayName(DateTime date) {
    final dayNames = [
      AppLocalizations.of(context)!.monday,
      AppLocalizations.of(context)!.tuesday,
      AppLocalizations.of(context)!.wednesday,
      AppLocalizations.of(context)!.thursday,
      AppLocalizations.of(context)!.friday,
      AppLocalizations.of(context)!.saturday,
      AppLocalizations.of(context)!.sunday,
    ];
    
    final dayName = dayNames[date.weekday - 1];
    final dayNumber = date.day;
    final monthName = DateFormat('MMMM', 'es_ES').format(date);
    
    return '$dayName, $dayNumber de $monthName';
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception(AppLocalizations.of(context)!.userNotAuthenticated);
      }
      
      _pastorId = user.uid;
      
      // Verificar si el usuario tiene permiso
      final hasPermission = await _permissionService.hasPermission('manage_counseling_availability');
      if (!hasPermission) {
        throw Exception(AppLocalizations.of(context)!.noPermissionManageAvailability);
      }
      
      // Buscar disponibilidad existente
      final availabilityDoc = await _firestore
          .collection('pastor_availability')
          .doc(_pastorId)
          .get();

      if (availabilityDoc.exists) {
        _availabilityRef = availabilityDoc.reference;
        _availability = model.PastorAvailability.fromFirestore(availabilityDoc);
        
        // Cargar valores
        _locationController.text = _availability!.location;
        _selectedDuration = _availability!.sessionDuration;
        _selectedBreakDuration = _availability!.breakDuration;
        _acceptsOnline = _availability!.isAcceptingOnline;
        _acceptsInPerson = _availability!.isAcceptingInPerson;
        
        // Cargar horario de la semana seleccionada
        _loadWeekSchedule();
      } else {
        // Crear disponibilidad por defecto
        _availabilityRef = _firestore.collection('pastor_availability').doc(_pastorId);
        
        final userRef = _firestore.collection('users').doc(_pastorId);
        
        // Horario por defecto (sin disponibilidad)
        final defaultSchedule = model.DaySchedule(
          isWorking: false,  // Por defecto, no disponible
          timeSlots: [],     // Sin franjas horarias
        );
        
        _availability = model.PastorAvailability(
          id: _pastorId,
          userId: userRef,
          monday: defaultSchedule,
          tuesday: defaultSchedule,
          wednesday: defaultSchedule,
          thursday: defaultSchedule,
          friday: defaultSchedule,
          saturday: defaultSchedule,
          sunday: defaultSchedule,
          unavailableDates: [],
          weekSchedules: [],
          location: 'Church Avenue 32, Pinheiros',
          isAcceptingOnline: true,
          isAcceptingInPerson: true,
          sessionDuration: 60,
          breakDuration: 0,
          updatedAt: DateTime.now(),
        );
        
        _locationController.text = _availability!.location;
        
        // Inicializar horario de la semana
        _initializeWeekSchedule();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingAvailability(e.toString()))),
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

  // Cargar el horario de la semana seleccionada
  void _loadWeekSchedule() {
    if (_availability == null) return;
    
    try {
      // print('Carregando horário para a semana: ${DateFormat('yyyy-MM-dd').format(_selectedWeek)}'); // Comentado para produção
      
      // Limpiar el horario actual
      _weekSchedule.clear();
      
      // Buscar si existe un horario específico para esta semana
      final weekSchedule = _findWeekSchedule(_selectedWeek);
      
      if (weekSchedule != null) {
        // print('Encontrado horário específico para esta semana'); // Comentado
        // Usar el horario específico de la semana
        try {
          // Convertir el mapa de días a un mapa de fechas
          final days = _getDaysOfWeek();
          for (final day in days) {
            final dayOfWeek = day.weekday;
            if (weekSchedule.days.containsKey(dayOfWeek)) {
              _weekSchedule[day] = weekSchedule.days[dayOfWeek]!;
              // print('Dia ${DateFormat('EEEE', 'pt_BR').format(day)}: ${weekSchedule.days[dayOfWeek]!.isWorking ? 'Disponível' : 'Indisponível'}, ${weekSchedule.days[dayOfWeek]!.timeSlots.length} faixas'); // Comentado
            }
          }
          // print('Horário carregado: ${_weekSchedule.length} dias'); // Comentado
        } catch (e) {
          // print('Erro ao copiar horário da semana: $e'); // Comentado
          // En caso de error, inicializar con el horario predeterminado
          _initializeWeekSchedule();
        }
      } else {
        // print('Não foi encontrado horário específico, usando o padrão'); // Comentado
        // Inicializar con el horario predeterminado
        _initializeWeekSchedule();
      }
      
      setState(() {});
    } catch (e) {
      // print('Erro ao carregar horário da semana: $e'); // Comentado
      // En caso de error, inicializar con el horario predeterminado
      _initializeWeekSchedule();
      setState(() {});
    }
  }

  // Inicializar el horario de la semana con los valores predeterminados
  void _initializeWeekSchedule() {
    if (_availability == null) return;
    
    // print('Inicializando horário com valores padrão (todos indisponíveis)'); // Comentado
    
    final days = _getDaysOfWeek();
    // print('Dias da semana: ${days.length}'); // Comentado
    
    // Limpiar el horario actual
    _weekSchedule.clear();
    
    for (final day in days) {
      // Crear un horario sin disponibilidad para cada día
      final newSchedule = model.DaySchedule(
        isWorking: false,  // Por defecto, no disponible
        timeSlots: [],     // Sin franjas horarias
      );
      
      _weekSchedule[day] = newSchedule;
      
      // print('Dia ${DateFormat('EEEE', 'pt_BR').format(day)}: Indisponível, 0 faixas'); // Comentado
    }
    
    // print('Horário inicializado: ${_weekSchedule.length} dias (todos indisponíveis)'); // Comentado
  }

  // Encontrar si existe un horario para la semana seleccionada
  model.WeekSchedule? _findWeekSchedule(DateTime weekStart) {
    if (_availability == null) return null;
    
    try {
      // print('Buscando horário para a semana: ${DateFormat('yyyy-MM-dd').format(weekStart)}'); // Comentado
      // print('Total de horários disponíveis: ${_availability!.weekSchedules.length}'); // Comentado
      
      // Normalizar la fecha de inicio de la semana
      final normalizedWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      // print('Data normalizada: ${DateFormat('yyyy-MM-dd').format(normalizedWeekStart)}'); // Comentado
      
      for (final weekSchedule in _availability!.weekSchedules) {
        try {
          // Normalizar la fecha de inicio del horario
          final scheduleDate = weekSchedule.startDate;
          final normalizedScheduleDate = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
          // print('Comparando com: ${DateFormat('yyyy-MM-dd').format(normalizedScheduleDate)}'); // Comentado
          
          // Obtener el inicio de la semana
          final scheduleWeekStart = _getStartOfWeek(normalizedScheduleDate);
          // print('Início da semana: ${DateFormat('yyyy-MM-dd').format(scheduleWeekStart)}'); // Comentado
          
          // Comparar año, mes y día para determinar si es la misma semana
          if (scheduleWeekStart.year == normalizedWeekStart.year && 
              scheduleWeekStart.month == normalizedWeekStart.month && 
              scheduleWeekStart.day == normalizedWeekStart.day) {
            // print('Encontrado horário para a semana!'); // Comentado
            return weekSchedule;
          }
        } catch (e) {
          // print('Erro ao processar horário da semana: $e'); // Comentado
          // Continuar con el siguiente horario si hay un error
          continue;
        }
      }
      
      // print('Não foi encontrado horário para a semana'); // Comentado
    } catch (e) {
      // print('Erro ao buscar horário da semana: $e'); // Comentado
    }
    
    return null;
  }

  // Método para guardar silenciosamente sin mostrar indicadores ni notificaciones
  Future<void> _saveWeekScheduleSilently() async {
    if (_availability == null || _availabilityRef == null) return;
    
    try {
      // print('Salvando horário silenciosamente para a semana: ${DateFormat('yyyy-MM-dd').format(_selectedWeek)}'); // Comentado
      
      // Verificar que el horario tenga datos
      if (_weekSchedule.isEmpty) {
        // print('Erro: Não há dados de horário para salvar'); // Comentado
        return;
      }
      
      // print('Horário atual: ${_weekSchedule.length} dias'); // Comentado
      for (final entry in _weekSchedule.entries) {
        final date = entry.key;
        final schedule = entry.value;
        // print('Dia ${DateFormat('EEEE', 'pt_BR').format(date)}: ${schedule.isWorking ? 'Disponível' : 'Indisponível'}, ${schedule.timeSlots.length} faixas'); // Comentado
      }
      
      // Crear una nueva lista de horarios por semana
      final List<model.WeekSchedule> weekSchedules = List.from(_availability!.weekSchedules);
      // print('Horários existentes: ${weekSchedules.length}'); // Comentado
      
      // Eliminar el horario anterior para esta semana si existe
      int removedCount = 0;
      weekSchedules.removeWhere((schedule) {
        try {
          // Normalizar las fechas para comparación
          final scheduleDate = schedule.startDate;
          final normalizedScheduleDate = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
          final scheduleWeekStart = _getStartOfWeek(normalizedScheduleDate);
          
          final normalizedSelectedWeek = DateTime(_selectedWeek.year, _selectedWeek.month, _selectedWeek.day);
          
          final result = scheduleWeekStart.year == normalizedSelectedWeek.year && 
                 scheduleWeekStart.month == normalizedSelectedWeek.month && 
                 scheduleWeekStart.day == normalizedSelectedWeek.day;
          
          if (result) {
            removedCount++;
            // print('Removendo horário existente para a semana: ${DateFormat('yyyy-MM-dd').format(scheduleWeekStart)}'); // Comentado
          }
          
          return result;
        } catch (e) {
          // print('Erro ao comparar datas: $e'); // Comentado
          return false;
        }
      });
      
      // print('Foram removidos $removedCount horários existentes'); // Comentado
      
      // Convertir el mapa de días a un mapa de enteros para el modelo
      final Map<int, model.DaySchedule> daySchedules = {};
      _weekSchedule.forEach((date, schedule) {
        daySchedules[date.weekday] = schedule;
        // print('Salvando dia ${date.weekday} (${DateFormat('EEEE', 'pt_BR').format(date)}): ${schedule.isWorking ? 'Disponível' : 'Indisponível'}, ${schedule.timeSlots.length} faixas'); // Comentado
      });
      
      // print('Dias configurados: ${daySchedules.keys.toList()}'); // Comentado
      
      // Añadir el nuevo horario
      final newWeekSchedule = model.WeekSchedule(
        startDate: _selectedWeek,
        days: daySchedules,
      );
      
      weekSchedules.add(newWeekSchedule);
      // print('Novo horário adicionado. Total de horários: ${weekSchedules.length}'); // Comentado
      
      // Crear una copia de la disponibilidad actual
      final updatedAvailability = model.PastorAvailability(
        id: _availability!.id,
        userId: _availability!.userId,
        monday: _availability!.monday,
        tuesday: _availability!.tuesday,
        wednesday: _availability!.wednesday,
        thursday: _availability!.thursday,
        friday: _availability!.friday,
        saturday: _availability!.saturday,
        sunday: _availability!.sunday,
        unavailableDates: _availability!.unavailableDates,
        weekSchedules: weekSchedules,
        location: _locationController.text.trim(),
        isAcceptingOnline: _acceptsOnline,
        isAcceptingInPerson: _acceptsInPerson,
        sessionDuration: _selectedDuration,
        breakDuration: _selectedBreakDuration,
        updatedAt: DateTime.now(),
      );
      
      // Convertir a mapa para verificar los datos
      final dataToSave = updatedAvailability.toFirestore();
      // print('Dados a salvar: ${dataToSave.keys.toList()}'); // Comentado
      // print('Horários a salvar: ${dataToSave['weekSchedules']?.length}'); // Comentado
      
      // Guardar en Firestore sin mostrar indicadores
      await _availabilityRef!.set(dataToSave);
      
      // Actualizar la referencia local
      _availability = updatedAvailability;
      
      // print('Horário salvo com sucesso'); // Comentado
    } catch (e) {
      // print('Erro ao salvar horário silenciosamente: $e'); // Comentado
      // Si hay un error, intentar mostrar un mensaje al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSaving(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDayScheduleDialog(DateTime date, model.DaySchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => DayScheduleDialog(
        date: date,
        schedule: schedule,
        onSave: (newSchedule) {
          setState(() {
            _weekSchedule[date] = newSchedule;
          });
          
          // Mostrar indicador de carga
          setState(() {
            _isLoading = true;
          });
          
          // Guardar silenciosamente cuando se modifica un día
          _saveWeekScheduleSilently().then((_) {
            // Ocultar indicador de carga
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              // Mostrar mensaje de confirmación
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.dayUpdatedSuccessfully),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }).catchError((error) {
            // Ocultar indicador de carga
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              
              // Mostrar mensaje de error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.errorSaving(error.toString())),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        },
      ),
    );
  }

  // Copiar el horario a la siguiente semana
  void _copyToNextWeek() {
    try {
      // print('Copiando horário para a próxima semana'); // Comentado
      
      // Guardar el horario actual antes de cambiar de semana
      final currentWeekStart = _selectedWeek;
      // print('Semana atual: ${DateFormat('yyyy-MM-dd').format(currentWeekStart)}'); // Comentado
      
      // Guardar silenciosamente la semana actual primero
      _saveWeekScheduleSilently().then((_) {
        // Calcular la siguiente semana
        final nextWeekStart = _selectedWeek.add(const Duration(days: 7));
        // print('Próxima semana: ${DateFormat('yyyy-MM-dd').format(nextWeekStart)}'); // Comentado
        
        // Guardar una copia del horario actual
        final Map<DateTime, model.DaySchedule> currentSchedule = Map<DateTime, model.DaySchedule>.from(_weekSchedule);
        // print('Horário atual copiado: ${currentSchedule.length} dias'); // Comentado
        
        // Cambiar a la siguiente semana
    setState(() {
          _selectedWeek = nextWeekStart;
        });
        
        // Inicializar el horario de la nueva semana
        _loadWeekSchedule();
        
        // Esperar a que se cargue el horario de la nueva semana
        Future.delayed(const Duration(milliseconds: 300), () {
          // Copiar el horario de la semana anterior
          if (currentSchedule.isNotEmpty) {
            final days = _getDaysOfWeek();
            // print('Dias na nova semana: ${days.length}'); // Comentado
            // print('Dias no horário anterior: ${currentSchedule.keys.length}'); // Comentado
            
            // Determinar cuántos días copiar
            final int maxDays = days.length < currentSchedule.keys.length ? 
                                days.length : currentSchedule.keys.length;
            
            // print('Copiando $maxDays dias'); // Comentado
            
            // Crear un nuevo mapa para el horario
            final Map<DateTime, model.DaySchedule> newSchedule = {};
            
            // Copiar día por día
            for (int i = 0; i < maxDays; i++) {
              try {
                // Obtener el día de la semana (1-7)
                final int dayOfWeek = i + 1; // 1 = lunes, 7 = domingo
                
                // Encontrar la fecha correspondiente en la nueva semana
                final DateTime newDate = days[i];
                
                // Encontrar el horario del día correspondiente en la semana anterior
                model.DaySchedule? daySchedule;
                
                // Buscar por día de la semana
                for (final DateTime date in currentSchedule.keys) {
                  if (date.weekday == dayOfWeek) {
                    daySchedule = currentSchedule[date];
                    break;
                  }
                }
                
                // Si no se encontró, usar el primero disponible
                if (daySchedule == null && currentSchedule.isNotEmpty) {
                  final previousDay = currentSchedule.keys.elementAt(i % currentSchedule.keys.length);
                  daySchedule = currentSchedule[previousDay];
                }
                
                // Si se encontró un horario, copiarlo
                if (daySchedule != null) {
                  newSchedule[newDate] = daySchedule;
                  // print('Copiado dia ${dayOfWeek} (${DateFormat('EEEE', 'pt_BR').format(newDate)})'); // Comentado
                }
              } catch (e) {
                // print('Erro ao copiar dia $i: $e'); // Comentado
              }
            }
            
            // Actualizar el horario
            setState(() {
              _weekSchedule = newSchedule;
            });
            
            // Guardar silenciosamente
            _saveWeekScheduleSilently();
          }
        });
      });
    } catch (e) {
      // print('Erro ao copiar para a próxima semana: $e'); // Comentado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSaving(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDayScheduleCard(DateTime date, model.DaySchedule schedule) {
    // Formatear el nombre del día con la fecha
    final dayName = _getDayName(date);
    final isToday = DateTime.now().day == date.day && 
                    DateTime.now().month == date.month && 
                    DateTime.now().year == date.year;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Encabezado del día
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.today,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                child: Text(
                    dayName.replaceRange(0, 1, dayName[0].toUpperCase()),
                    style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                      color: isToday ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ),
                // Indicador más discreto
                Icon(
                  schedule.isWorking 
                    ? Icons.check_circle_outline 
                    : Icons.do_not_disturb_on_outlined,
                  size: 18,
                  color: schedule.isWorking ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                // Botón simplificado (sin lápiz)
                IconButton(
                  icon: Icon(
                    schedule.isWorking && schedule.timeSlots.isEmpty 
                      ? Icons.add 
                      : Icons.edit_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDayScheduleDialog(date, schedule),
                  tooltip: schedule.isWorking && schedule.timeSlots.isEmpty 
                    ? 'Adicionar faixas de horário'
                    : 'Editar disponibilidade',
                ),
              ],
            ),
          ),
          
          // Contenido del día
          if (schedule.isWorking && schedule.timeSlots.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.timeSlots(schedule.timeSlots.length.toString()),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${schedule.timeSlots.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (schedule.timeSlots.length > 1)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 14),
                          label: Text(AppLocalizations.of(context)!.deleteAll, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(AppLocalizations.of(context)!.confirmDeletion),
                                content: Text(AppLocalizations.of(context)!.confirmDeleteAllTimeSlots),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _weekSchedule[date] = model.DaySchedule(
                                          isWorking: false,
                                          timeSlots: [],
                                        );
                                      });
                                      // Guardar silenciosamente cuando se eliminan todas las franjas
                                      _saveWeekScheduleSilently();
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Lista de franjas horarias
                  ...schedule.timeSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${slot.start} - ${slot.end}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Iconos en lugar de espacio
                          if (slot.isOnline)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.videocam_outlined, size: 16, color: Colors.blue.shade700),
                            ),
                          if (slot.isInPerson)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.person_outline, size: 16, color: Colors.green.shade700),
                            ),
                          // Corregido el overflow
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                                final newTimeSlots = List<model.TimeSlot>.from(schedule.timeSlots);
                                newTimeSlots.removeAt(index);
                                _weekSchedule[date] = model.DaySchedule(
                                  isWorking: newTimeSlots.isNotEmpty,
                                  timeSlots: newTimeSlots,
                                );
                              });
                              // Guardar silenciosamente cuando se elimina una franja
                              _saveWeekScheduleSilently();
                            },
                            tooltip: 'Excluir faixa',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ] else if (!schedule.isWorking) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.event_busy, size: 20, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.unavailableForConsultations,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (schedule.isWorking && schedule.timeSlots.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.access_time, size: 20, color: Colors.orange.shade400),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.dayMarkedAvailableAddTimeSlots,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.configureAvailability),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppLocalizations.of(context)!.consultationSettings,
            onPressed: _showGlobalSettingsDialog,
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_counseling_availability'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorVerifyingPermission(permissionSnapshot.error.toString())));
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Acesso Negado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Você não tem permissão para gerenciar a disponibilidade para aconselhamento.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          return Stack(
            children: [
              Column(
                children: [
                  // Selector de semana con diseño mejorado
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Selector de semana
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  setState(() {
                                    _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
                                    _loadWeekSchedule();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.weekOf(DateFormat('dd/MM/yyyy').format(_selectedWeek)),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${DateFormat('d MMM', 'pt_BR').format(_selectedWeek)} a ${DateFormat('d MMM', 'pt_BR').format(_getEndOfWeek(_selectedWeek))}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  setState(() {
                                    _selectedWeek = _selectedWeek.add(const Duration(days: 7));
                                    _loadWeekSchedule();
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Botón de copiar a siguiente semana
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy_all_rounded, size: 16),
                          label: Text(AppLocalizations.of(context)!.copyToNextWeek),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _copyToNextWeek,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Lista de días de la semana
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _getDaysOfWeek().length,
                      itemBuilder: (context, index) {
                        final date = _getDaysOfWeek()[index];
                        final schedule = _weekSchedule[date] ?? model.DaySchedule(isWorking: false);
                        
                        return _buildDayScheduleCard(date, schedule);
                      },
                    ),
                  ),
                ],
              ),
              // Indicador de carga sutil que solo cubre la parte superior de la pantalla
              if (_isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Método para mostrar el diálogo de configuración global
  void _showGlobalSettingsDialog() {
    // Crear variables locales para mantener el estado dentro del modal
    int localSelectedDuration = _selectedDuration;
    int localSelectedBreakDuration = _selectedBreakDuration;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Widget para la opción de duración de cita dentro del modal
          Widget buildDurationOptionLocal(int duration) {
            final isSelected = localSelectedDuration == duration;
            
            return InkWell(
              onTap: () {
                // Actualizar el estado local y la UI del diálogo
                setDialogState(() {
                  localSelectedDuration = duration;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$duration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'min',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Widget para la opción de tiempo entre citas dentro del modal
          Widget buildBreakOptionLocal(int duration) {
            final isSelected = localSelectedBreakDuration == duration;
            
            return InkWell(
              onTap: () {
                // Actualizar el estado local y la UI del diálogo
                setDialogState(() {
                  localSelectedBreakDuration = duration;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$duration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'min',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.counselingConfiguration),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duración de la cita
                  Text(
                    AppLocalizations.of(context)!.counselingDuration,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.configureCounselingDuration,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildDurationOptionLocal(15),
                        const SizedBox(width: 8),
                        buildDurationOptionLocal(30),
                        const SizedBox(width: 8),
                        buildDurationOptionLocal(45),
                        const SizedBox(width: 8),
                        buildDurationOptionLocal(60),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tiempo entre citas
                  Text(
                    AppLocalizations.of(context)!.intervalBetweenConsultations,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.configureRestTimeBetweenConsultations,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildBreakOptionLocal(0),
                        const SizedBox(width: 8),
                        buildBreakOptionLocal(5),
                        const SizedBox(width: 8),
                        buildBreakOptionLocal(10),
                        const SizedBox(width: 8),
                        buildBreakOptionLocal(15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Actualizar los valores globales con los seleccionados en el modal
                  setState(() {
                    _selectedDuration = localSelectedDuration;
                    _selectedBreakDuration = localSelectedBreakDuration;
                  });
                  _saveGlobalSettings();
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.guardar),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
  
  // Método para guardar la configuración global
  Future<void> _saveGlobalSettings() async {
    if (_availabilityRef == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Actualizar la disponibilidad con los nuevos valores
      await _availabilityRef!.update({
        'sessionDuration': _selectedDuration,
        'breakDuration': _selectedBreakDuration,
      });
      
      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settingsSavedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSaving(e.toString())),
            behavior: SnackBarBehavior.floating,
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
}