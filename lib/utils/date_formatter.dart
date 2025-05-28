import 'package:intl/intl.dart';

class DateFormatter {
  // Formato simple dd/mm/yyyy
  static String formatDate(DateTime? date) {
    if (date == null) return '-'; // Opcional: devolver algo si la fecha es nula
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Podrías añadir más formatos aquí si los necesitas en otros lugares
  // Ejemplo: formato con hora
  // static String formatDateTime(DateTime? dateTime) {
  //   if (dateTime == null) return '-';
  //   return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  // }
} 