# Refactorización de TimeSlotDetailScreen

Este directorio contiene componentes extraídos de `time_slot_detail_screen.dart` para reducir el tamaño del archivo y mejorar la mantenibilidad.

## Problema Original
El archivo `time_slot_detail_screen.dart` tenía más de 3000 líneas y varios errores de lint, incluyendo métodos duplicados.

## Solución
Hemos extraído la lógica a componentes independientes:

1. `AttendanceManager`: Gestiona la confirmación y cambios de asistencia
2. `RoleManager`: Maneja la creación y actualización de roles

## Uso

### En TimeSlotDetailScreen

```dart
import 'time_slot_components/attendance_manager.dart';
import 'time_slot_components/role_manager.dart';

class _TimeSlotDetailScreenState extends State<TimeSlotDetailScreen> {
  late AttendanceManager _attendanceManager;
  late RoleManager _roleManager;
  
  @override
  void initState() {
    super.initState();
    _attendanceManager = AttendanceManager(
      timeSlot: widget.timeSlot,
      context: context,
    );
    _roleManager = RoleManager(
      timeSlot: widget.timeSlot,
      context: context,
    );
  }
  
  // Reemplazar llamadas a métodos internos con:
  void _confirmAttendance(String assignmentId, String userId, String userName, bool changeAttendee) {
    _attendanceManager.confirmAttendance(assignmentId, userId, userName, changeAttendee);
  }
  
  void _unconfirmAttendance(String assignmentId, String userId, String userName) {
    _attendanceManager.unconfirmAttendance(assignmentId, userId, userName);
  }
  
  void _changeAttendee(String assignmentId, String newUserId, String newUserName) {
    _attendanceManager.changeAttendee(assignmentId, newUserId, newUserName);
  }
  
  // Para los métodos de gestión de roles:
  void _createRole(dynamic ministryId, String ministryName, String roleName, int capacity, 
                   bool isTemporary, bool saveAsPredefined) {
    _roleManager.createRole(
      ministryId: ministryId,
      ministryName: ministryName,
      roleName: roleName,
      capacity: capacity,
      isTemporary: isTemporary,
      saveAsPredefined: saveAsPredefined,
    );
  }
}
```

## Siguientes Pasos

Para reducir aún más las líneas de código:

1. Extraer las pestañas a componentes independientes
2. Crear un servicio específico para invitaciones
3. Mover la UI relacionada con roles a un widget separado
4. Convertir los métodos de utilidad en un archivo utils.dart

Este enfoque reduciría considerablemente el tamaño del archivo principal y facilitaría el mantenimiento. 