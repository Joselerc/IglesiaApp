import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/ticket_model.dart';
import '../models/ticket_registration_model.dart';

/// Servicio para exportar el listado de participantes de un evento a Excel.
class EventAttendeesExportService {
  /// Genera un archivo Excel con todos los participantes del evento y sus
  /// detalles, agrupados por tipo de ticket. Devuelve la ruta del archivo
  /// generado o lanza una excepción si falla.
  static Future<String> exportToExcel({
    required String eventTitle,
    required DateTime? eventDate,
    required List<TicketModel> tickets,
    required Map<String, List<TicketRegistrationModel>> registrationsByTicket,
  }) async {
    final excel = Excel.createExcel();

    // Eliminar la hoja por defecto que crea la librería ("Sheet1")
    excel.delete('Sheet1');

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final ticketsById = {for (final t in tickets) t.id: t};

    // Recolectar todas las claves dinámicas de formData (preguntas custom)
    // y, en paralelo, mapear cada id de campo a su label (más legible).
    final Map<String, String> dynamicFieldLabels = {};
    for (final t in tickets) {
      for (final f in t.formFields) {
        // Saltar los campos que ya representamos como columnas fijas
        if (f.id == 'fullName' || f.id == 'name' ||
            f.id == 'email' ||
            f.id == 'phone') {
          continue;
        }
        dynamicFieldLabels[f.id] =
            f.label.isNotEmpty ? f.label : f.id;
      }
    }
    // También considerar claves que vengan en formData aunque no estén
    // declaradas en formFields (por si han cambiado los formularios).
    for (final regs in registrationsByTicket.values) {
      for (final r in regs) {
        for (final key in r.formData.keys) {
          if (key == 'fullName' || key == 'name' ||
              key == 'email' ||
              key == 'phone') continue;
          dynamicFieldLabels.putIfAbsent(key, () => key);
        }
      }
    }

    final dynamicFieldIds = dynamicFieldLabels.keys.toList();

    // 1) Hoja "Participantes" con todos los registros mezclados.
    final allSheet = excel['Participantes'];
    _writeAttendeesSheet(
      sheet: allSheet,
      eventTitle: eventTitle,
      eventDate: eventDate,
      dateFormat: dateFormat,
      registrations: _flattenRegistrations(registrationsByTicket),
      ticketsById: ticketsById,
      dynamicFieldIds: dynamicFieldIds,
      dynamicFieldLabels: dynamicFieldLabels,
      includeTicketColumn: true,
    );

    // 2) Una hoja extra por cada tipo de ticket (si hay más de uno).
    if (tickets.length > 1) {
      for (final ticket in tickets) {
        final regs = registrationsByTicket[ticket.id] ?? const [];
        if (regs.isEmpty) continue;
        final sheetName = _safeSheetName('${ticket.type}');
        final sheet = excel[sheetName];
        _writeAttendeesSheet(
          sheet: sheet,
          eventTitle: eventTitle,
          eventDate: eventDate,
          dateFormat: dateFormat,
          registrations: regs,
          ticketsById: ticketsById,
          dynamicFieldIds: dynamicFieldIds,
          dynamicFieldLabels: dynamicFieldLabels,
          includeTicketColumn: false,
          ticketSubtitle: ticket.type,
        );
      }
    }

    // Guardar
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    final fileName =
        'participantes_${_slug(eventTitle)}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    return _saveFile(bytes: bytes, fileName: fileName);
  }

  // ---------------------------------------------------------------------------

  static List<TicketRegistrationModel> _flattenRegistrations(
    Map<String, List<TicketRegistrationModel>> byTicket,
  ) {
    final out = <TicketRegistrationModel>[];
    byTicket.values.forEach(out.addAll);
    // Ordenar por fecha de registro descendente
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static void _writeAttendeesSheet({
    required Sheet sheet,
    required String eventTitle,
    required DateTime? eventDate,
    required DateFormat dateFormat,
    required List<TicketRegistrationModel> registrations,
    required Map<String, TicketModel> ticketsById,
    required List<String> dynamicFieldIds,
    required Map<String, String> dynamicFieldLabels,
    required bool includeTicketColumn,
    String? ticketSubtitle,
  }) {
    int row = 0;

    // Cabecera del documento
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(eventTitle)
      ..cellStyle = CellStyle(bold: true, fontSize: 14);
    row++;

    if (ticketSubtitle != null) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue('Tipo de ingresso: $ticketSubtitle')
        ..cellStyle = CellStyle(italic: true, fontSize: 11);
      row++;
    }

    if (eventDate != null) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        ..value = TextCellValue(
            'Data do evento: ${DateFormat('dd/MM/yyyy HH:mm').format(eventDate)}')
        ..cellStyle = CellStyle(fontSize: 11);
      row++;
    }

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue(
          'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}')
      ..cellStyle = CellStyle(fontSize: 10, italic: true);
    row += 2;

    // Encabezados de tabla
    final headers = <String>[
      if (includeTicketColumn) 'Tipo de ingresso',
      'Nome',
      'Email',
      'Telefone',
      'Data de inscrição',
      'Compareceu',
      'Data de check-in',
      'Tipo de presença',
      'Forma de inscrição',
      'Código QR',
      for (final id in dynamicFieldIds) dynamicFieldLabels[id] ?? id,
    ];

    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        ..value = TextCellValue(headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
        );
    }
    row++;

    // Filas de datos
    for (final reg in registrations) {
      int col = 0;
      if (includeTicketColumn) {
        final ticket = ticketsById[reg.ticketId];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(ticket?.type ?? reg.ticketId);
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(reg.userName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(reg.userEmail);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(reg.userPhone);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(dateFormat.format(reg.createdAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(_attendedLabel(reg));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(
        reg.usedAt != null ? dateFormat.format(reg.usedAt!) : '',
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(_attendanceTypeLabel(reg.attendanceType));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(_registrationType(reg));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
          .value = TextCellValue(reg.qrCode);

      for (final id in dynamicFieldIds) {
        final raw = reg.formData[id];
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(_stringify(raw));
      }
      row++;
    }

    // Resumen al final
    row++;
    final total = registrations.length;
    final attended = registrations
        .where((r) => r.attendanceConfirmed || r.isUsed)
        .length;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Total de inscritos: $total')
      ..cellStyle = CellStyle(bold: true);
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Total de presentes: $attended')
      ..cellStyle = CellStyle(bold: true);
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = TextCellValue('Pendentes: ${total - attended}')
      ..cellStyle = CellStyle(bold: true);
  }

  static String _attendedLabel(TicketRegistrationModel reg) {
    if (reg.attendanceConfirmed || reg.isUsed) return 'Sim';
    return 'Não';
  }

  static String _attendanceTypeLabel(String? type) {
    if (type == null || type.isEmpty) return '';
    switch (type) {
      case 'presential':
        return 'Presencial';
      case 'online':
        return 'Online';
      default:
        return type;
    }
  }

  static String _registrationType(TicketRegistrationModel reg) {
    final raw = reg.formData['registrationType'];
    if (raw is String && raw.isNotEmpty) return raw;
    return reg.qrCode.contains('-manual-') ? 'Manual' : 'Online';
  }

  static String _stringify(Object? value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (value is DateTime) return DateFormat('dd/MM/yyyy HH:mm').format(value);
    if (value is List) return value.join(', ');
    return value.toString();
  }

  static String _safeSheetName(String name) {
    // Excel limita los nombres de hoja a 31 caracteres y no admite ciertos chars
    var clean = name.replaceAll(RegExp(r'[\\/:*?\[\]]'), '_');
    if (clean.length > 31) clean = clean.substring(0, 31);
    if (clean.isEmpty) clean = 'Ingresso';
    return clean;
  }

  static String _slug(String value) {
    final lower = value.toLowerCase();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final trimmed = replaced.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed.isEmpty ? 'evento' : trimmed;
  }

  static Future<String> _saveFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    if (Platform.isAndroid) {
      try {
        await Permission.storage.request();
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final file = File('${downloadsDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          return file.path;
        }
      } catch (e) {
        debugPrint('Error guardando en Downloads: $e');
      }
      try {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(bytes);
          return file.path;
        }
      } catch (e) {
        debugPrint('Error guardando en almacenamiento externo: $e');
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
