import 'package:cloud_firestore/cloud_firestore.dart';

// Clase para representar una franja horaria
class TimeSlot {
  final String start;
  final String end;
  final bool isOnline;
  final bool isInPerson;

  TimeSlot({
    required this.start,
    required this.end,
    this.isOnline = true,
    this.isInPerson = true,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: map['start'] as String,
      end: map['end'] as String,
      isOnline: map['isOnline'] ?? true,
      isInPerson: map['isInPerson'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
      'isOnline': isOnline,
      'isInPerson': isInPerson,
    };
  }
}

// Clase para representar el horario de un día
class DaySchedule {
  final bool isWorking;
  final List<TimeSlot> timeSlots;
  final int sessionDuration;

  DaySchedule({
    required this.isWorking,
    this.timeSlots = const [],
    this.sessionDuration = 60,
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    List<TimeSlot> slots = [];
    if (map['timeSlots'] != null) {
      slots = (map['timeSlots'] as List).map((slot) => TimeSlot.fromMap(slot)).toList();
    } else if (map['onlineStart'] != null && map['onlineEnd'] != null) {
      // Compatibilidad con el formato anterior
      slots.add(TimeSlot(
        start: map['onlineStart'] as String,
        end: map['onlineEnd'] as String,
        isOnline: true,
        isInPerson: false,
      ));
      
      if (map['inPersonStart'] != null && map['inPersonEnd'] != null) {
        slots.add(TimeSlot(
          start: map['inPersonStart'] as String,
          end: map['inPersonEnd'] as String,
          isOnline: false,
          isInPerson: true,
        ));
      }
    }
    
    return DaySchedule(
      isWorking: map['isWorking'] ?? false,
      timeSlots: slots,
      sessionDuration: map['sessionDuration'] ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isWorking': isWorking,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'sessionDuration': sessionDuration,
    };
  }
  
  // Métodos de conveniencia para compatibilidad
  String? get onlineStart => timeSlots.firstWhere((slot) => slot.isOnline, orElse: () => TimeSlot(start: '', end: '')).start.isEmpty ? null : timeSlots.firstWhere((slot) => slot.isOnline, orElse: () => TimeSlot(start: '', end: '')).start;
  String? get onlineEnd => timeSlots.firstWhere((slot) => slot.isOnline, orElse: () => TimeSlot(start: '', end: '')).end.isEmpty ? null : timeSlots.firstWhere((slot) => slot.isOnline, orElse: () => TimeSlot(start: '', end: '')).end;
  String? get inPersonStart => timeSlots.firstWhere((slot) => slot.isInPerson, orElse: () => TimeSlot(start: '', end: '')).start.isEmpty ? null : timeSlots.firstWhere((slot) => slot.isInPerson, orElse: () => TimeSlot(start: '', end: '')).start;
  String? get inPersonEnd => timeSlots.firstWhere((slot) => slot.isInPerson, orElse: () => TimeSlot(start: '', end: '')).end.isEmpty ? null : timeSlots.firstWhere((slot) => slot.isInPerson, orElse: () => TimeSlot(start: '', end: '')).end;
}

// Clase para representar una semana específica
class WeekSchedule {
  final DateTime startDate;
  final Map<int, DaySchedule> days; // Clave: día de la semana (1-7), Valor: horario

  WeekSchedule({
    required this.startDate,
    required this.days,
  });

  factory WeekSchedule.fromMap(Map<String, dynamic> map) {
    print('WeekSchedule.fromMap - Tipo de startDate: ${map['startDate']?.runtimeType}');
    
    // Asegurarse de que startDate sea un DateTime
    DateTime startDate;
    try {
      if (map['startDate'] is Timestamp) {
        startDate = (map['startDate'] as Timestamp).toDate();
        print('Convertido Timestamp a DateTime: $startDate');
      } else if (map['startDate'] is int) {
        // Convertir timestamp en milisegundos a DateTime
        startDate = DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int);
        print('Convertido int a DateTime: $startDate');
      } else if (map['startDate'] is DateTime) {
        // Ya es un DateTime
        startDate = map['startDate'] as DateTime;
        print('Ya es DateTime: $startDate');
      } else if (map['startDate'] is String) {
        // Intentar parsear como string ISO
        startDate = DateTime.parse(map['startDate'] as String);
        print('Convertido String a DateTime: $startDate');
      } else {
        // Valor por defecto si no se puede convertir
        print('Tipo de startDate no reconocido: ${map['startDate']?.runtimeType}');
        startDate = DateTime.now();
        print('Usando fecha actual: $startDate');
      }
    } catch (e) {
      print('Error al convertir startDate: $e');
      startDate = DateTime.now();
      print('Usando fecha actual después de error: $startDate');
    }
    
    final daysMap = <int, DaySchedule>{};
    
    try {
      final daysData = map['days'] as Map<String, dynamic>?;
      if (daysData != null) {
        daysData.forEach((key, value) {
          try {
            final dayNumber = int.parse(key);
            daysMap[dayNumber] = DaySchedule.fromMap(value);
            print('Día $dayNumber cargado correctamente');
          } catch (e) {
            print('Error al procesar día $key: $e');
          }
        });
      } else {
        print('No se encontraron datos de días en el mapa');
      }
    } catch (e) {
      print('Error al procesar días: $e');
    }
    
    return WeekSchedule(
      startDate: startDate,
      days: daysMap,
    );
  }

  Map<String, dynamic> toMap() {
    print('WeekSchedule.toMap - Convirtiendo startDate: $startDate');
    
    final daysMap = <String, dynamic>{};
    days.forEach((key, value) {
      daysMap[key.toString()] = value.toMap();
    });
    
    // Asegurarse de que startDate se convierta correctamente a Timestamp
    try {
      final timestamp = Timestamp.fromDate(startDate);
      print('Convertido DateTime a Timestamp: $timestamp');
      
      return {
        'startDate': timestamp,
        'days': daysMap,
      };
    } catch (e) {
      print('Error al convertir startDate a Timestamp: $e');
      // En caso de error, usar la fecha actual
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      print('Usando fecha actual como respaldo: $timestamp');
      
      return {
        'startDate': timestamp,
        'days': daysMap,
      };
    }
  }
  
  // Obtener el horario para un día específico
  DaySchedule? getScheduleForDay(DateTime date) {
    final dayOfWeek = date.weekday; // 1 = lunes, 7 = domingo
    return days[dayOfWeek];
  }
}

class PastorAvailability {
  final String id;
  final DocumentReference userId;
  final DaySchedule monday;
  final DaySchedule tuesday;
  final DaySchedule wednesday;
  final DaySchedule thursday;
  final DaySchedule friday;
  final DaySchedule saturday;
  final DaySchedule sunday;
  final List<DateTime> unavailableDates;
  final List<WeekSchedule> weekSchedules; // Nuevo: horarios por semana específica
  final String location;
  final bool isAcceptingOnline;
  final bool isAcceptingInPerson;
  final int sessionDuration;
  final int breakDuration;
  final DateTime updatedAt;

  PastorAvailability({
    required this.id,
    required this.userId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.unavailableDates,
    this.weekSchedules = const [],
    required this.location,
    required this.isAcceptingOnline,
    required this.isAcceptingInPerson,
    required this.sessionDuration,
    this.breakDuration = 0,
    required this.updatedAt,
  });

  factory PastorAvailability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception('Documento no contiene datos');
    }
    
    // Convertir fechas bloqueadas
    List<DateTime> unavailableDates = [];
    if (data['unavailableDates'] != null) {
      unavailableDates = (data['unavailableDates'] as List<dynamic>)
          .map((date) => (date as Timestamp).toDate())
          .toList();
    }
    
    // Convertir horarios por semana
    List<WeekSchedule> weekSchedules = [];
    if (data['weekSchedules'] != null) {
      weekSchedules = (data['weekSchedules'] as List<dynamic>)
          .map((week) => WeekSchedule.fromMap(week as Map<String, dynamic>))
          .toList();
    }
    
    return PastorAvailability(
      id: doc.id,
      userId: data['userId'] as DocumentReference,
      monday: data['monday'] != null 
          ? DaySchedule.fromMap(data['monday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      tuesday: data['tuesday'] != null 
          ? DaySchedule.fromMap(data['tuesday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      wednesday: data['wednesday'] != null 
          ? DaySchedule.fromMap(data['wednesday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      thursday: data['thursday'] != null 
          ? DaySchedule.fromMap(data['thursday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      friday: data['friday'] != null 
          ? DaySchedule.fromMap(data['friday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      saturday: data['saturday'] != null 
          ? DaySchedule.fromMap(data['saturday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      sunday: data['sunday'] != null 
          ? DaySchedule.fromMap(data['sunday'] as Map<String, dynamic>) 
          : DaySchedule(isWorking: false),
      unavailableDates: unavailableDates,
      weekSchedules: weekSchedules,
      location: data['location'] as String? ?? '',
      isAcceptingOnline: data['isAcceptingOnline'] as bool? ?? true,
      isAcceptingInPerson: data['isAcceptingInPerson'] as bool? ?? true,
      sessionDuration: data['sessionDuration'] as int? ?? 60,
      breakDuration: data['breakDuration'] as int? ?? 0,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'monday': monday.toMap(),
      'tuesday': tuesday.toMap(),
      'wednesday': wednesday.toMap(),
      'thursday': thursday.toMap(),
      'friday': friday.toMap(),
      'saturday': saturday.toMap(),
      'sunday': sunday.toMap(),
      'unavailableDates': unavailableDates.map((date) => Timestamp.fromDate(date)).toList(),
      'weekSchedules': weekSchedules.map((week) => week.toMap()).toList(),
      'location': location,
      'isAcceptingOnline': isAcceptingOnline,
      'isAcceptingInPerson': isAcceptingInPerson,
      'sessionDuration': sessionDuration,
      'breakDuration': breakDuration,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Método para verificar si un día específico está disponible
  bool isDayAvailable(DateTime date) {
    // Verificar si la fecha está en la lista de fechas no disponibles
    if (unavailableDates.any((blockedDate) => 
        blockedDate.year == date.year && 
        blockedDate.month == date.month && 
        blockedDate.day == date.day)) {
      return false;
    }
    
    // Verificar si hay un horario específico para esta semana
    for (final weekSchedule in weekSchedules) {
      final weekStart = DateTime(
        weekSchedule.startDate.year,
        weekSchedule.startDate.month,
        weekSchedule.startDate.day,
      );
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      if (date.isAfter(weekStart.subtract(const Duration(days: 1))) && 
          date.isBefore(weekEnd.add(const Duration(days: 1)))) {
        final daySchedule = weekSchedule.getScheduleForDay(date);
        if (daySchedule != null) {
          return daySchedule.isWorking && daySchedule.timeSlots.isNotEmpty;
        }
      }
    }
    
    // Si no hay horario específico para esta semana, usar el horario predeterminado
    final dayOfWeek = date.weekday;
    switch (dayOfWeek) {
      case DateTime.monday:
        return monday.isWorking && monday.timeSlots.isNotEmpty;
      case DateTime.tuesday:
        return tuesday.isWorking && tuesday.timeSlots.isNotEmpty;
      case DateTime.wednesday:
        return wednesday.isWorking && wednesday.timeSlots.isNotEmpty;
      case DateTime.thursday:
        return thursday.isWorking && thursday.timeSlots.isNotEmpty;
      case DateTime.friday:
        return friday.isWorking && friday.timeSlots.isNotEmpty;
      case DateTime.saturday:
        return saturday.isWorking && saturday.timeSlots.isNotEmpty;
      case DateTime.sunday:
        return sunday.isWorking && sunday.timeSlots.isNotEmpty;
      default:
        return false;
    }
  }

  // Obtener el horario para un día específico
  DaySchedule getScheduleForDay(DateTime date) {
    // Verificar si hay un horario específico para esta semana
    for (final weekSchedule in weekSchedules) {
      final weekStart = DateTime(
        weekSchedule.startDate.year,
        weekSchedule.startDate.month,
        weekSchedule.startDate.day,
      );
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      if (date.isAfter(weekStart.subtract(const Duration(days: 1))) && 
          date.isBefore(weekEnd.add(const Duration(days: 1)))) {
        final daySchedule = weekSchedule.getScheduleForDay(date);
        if (daySchedule != null) {
          return daySchedule;
        }
      }
    }
    
    // Si no hay horario específico para esta semana, usar el horario predeterminado
    final dayOfWeek = date.weekday;
    switch (dayOfWeek) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return DaySchedule(isWorking: false);
    }
  }
} 