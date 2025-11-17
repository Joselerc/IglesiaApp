import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/cult.dart';
import '../models/time_slot.dart';

class CultSummaryExportService {
  /// Genera y descarga un PDF del resumen del culto
  /// Retorna la ruta del archivo guardado
  static Future<String> exportToPDF({
    required Cult cult,
    required List<TimeSlot> timeSlots,
    required Map<String, List<Map<String, dynamic>>> rolesData,
    required String churchName,
  }) async {
    final pdf = pw.Document();
    
    // Formato de fecha
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    churchName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Resumen del Culto',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    cult.name,
                    style: const pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Fecha: ${dateFormat.format(cult.date)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            
            pw.SizedBox(height: 16),
            
            // Contenido por franja horaria
            ...timeSlots.map((timeSlot) {
              final roles = rolesData[timeSlot.id] ?? [];
              
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Título de franja horaria
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe192), // schedule icon
                          size: 16,
                          color: PdfColors.blue800,
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          '${timeFormat.format(timeSlot.startTime)} - ${timeFormat.format(timeSlot.endTime)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        if (timeSlot.name.isNotEmpty) ...[
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '(${timeSlot.name})',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  pw.SizedBox(height: 8),
                  
                  // Tabla de roles
                  if (roles.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'No hay roles asignados',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2), // Ministerio
                        1: const pw.FlexColumnWidth(2), // Rol
                        2: const pw.FlexColumnWidth(3), // Persona
                        3: const pw.FlexColumnWidth(1.5), // Estado
                      },
                      children: [
                        // Encabezado
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey200,
                          ),
                          children: [
                            _buildTableCell('Ministerio', isHeader: true),
                            _buildTableCell('Rol', isHeader: true),
                            _buildTableCell('Persona', isHeader: true),
                            _buildTableCell('Estado', isHeader: true),
                          ],
                        ),
                        // Filas de datos
                        ...roles.expand((roleData) {
                          final roleName = roleData['roleName'] as String;
                          final ministryName = roleData['ministryName'] as String?;
                          final capacity = roleData['capacity'] as int;
                          final assignments = roleData['assignments'] as List<Map<String, dynamic>>;
                          
                          // Si no hay asignaciones, mostrar vacantes
                          if (assignments.isEmpty) {
                            return List.generate(capacity, (index) {
                              return pw.TableRow(
                                children: [
                                  _buildTableCell(index == 0 ? (ministryName ?? 'Sin ministerio') : ''),
                                  _buildTableCell(index == 0 ? roleName : ''),
                                  _buildTableCell('(Sin asignar)'),
                                  _buildTableCell('Vacante', color: PdfColors.grey),
                                ],
                              );
                            });
                          }
                          
                          // Mostrar asignaciones y vacantes restantes
                          final rows = <pw.TableRow>[];
                          
                          for (var i = 0; i < capacity; i++) {
                            if (i < assignments.length) {
                              final assignment = assignments[i];
                              final userName = assignment['userName'] as String;
                              final status = assignment['status'] as String;
                              
                              PdfColor statusColor;
                              String statusText;
                              
                              switch (status) {
                                case 'accepted':
                                  statusColor = PdfColors.green;
                                  statusText = 'Aceptado';
                                  break;
                                case 'pending':
                                  statusColor = PdfColors.orange;
                                  statusText = 'Pendiente';
                                  break;
                                case 'rejected':
                                  statusColor = PdfColors.red;
                                  statusText = 'Rechazó';
                                  break;
                                default:
                                  statusColor = PdfColors.grey;
                                  statusText = 'Desconocido';
                              }
                              
                              rows.add(
                                pw.TableRow(
                                  children: [
                                    _buildTableCell(i == 0 ? (ministryName ?? 'Sin ministerio') : ''),
                                    _buildTableCell(i == 0 ? roleName : ''),
                                    _buildTableCell(userName),
                                    _buildTableCell(statusText, color: statusColor),
                                  ],
                                ),
                              );
                            } else {
                              // Vacante
                              rows.add(
                                pw.TableRow(
                                  children: [
                                    _buildTableCell(i == 0 ? (ministryName ?? 'Sin ministerio') : ''),
                                    _buildTableCell(i == 0 ? roleName : ''),
                                    _buildTableCell('(Sin asignar)'),
                                    _buildTableCell('Vacante', color: PdfColors.grey),
                                  ],
                                ),
                              );
                            }
                          }
                          
                          return rows;
                        }),
                      ],
                    ),
                  
                  pw.SizedBox(height: 16),
                ],
              );
            }),
            
            // Pie de página con estadísticas
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _buildSummaryStats(timeSlots, rolesData),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
      ),
    );
    
    // Guardar archivo
    return await _saveAndShareFile(
      bytes: await pdf.save(),
      fileName: 'resumen_culto_${cult.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(cult.date)}.pdf',
      mimeType: 'application/pdf',
    );
  }
  
  /// Genera y descarga un archivo Excel del resumen del culto
  /// Retorna la ruta del archivo guardado
  static Future<String> exportToExcel({
    required Cult cult,
    required List<TimeSlot> timeSlots,
    required Map<String, List<Map<String, dynamic>>> rolesData,
    required String churchName,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Resumen del Culto'];
    
    // Formato de fecha
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    int currentRow = 0;
    
    // Encabezado
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue(churchName)
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: ExcelColor.blue,
      );
    currentRow++;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Resumen del Culto: ${cult.name}')
      ..cellStyle = CellStyle(bold: true, fontSize: 14);
    currentRow++;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('Fecha: ${dateFormat.format(cult.date)}')
      ..cellStyle = CellStyle(fontSize: 12);
    currentRow += 2;
    
    // Por cada franja horaria
    for (final timeSlot in timeSlots) {
      final roles = rolesData[timeSlot.id] ?? [];
      
      // Título de franja horaria
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = TextCellValue(
          '${timeFormat.format(timeSlot.startTime)} - ${timeFormat.format(timeSlot.endTime)}'
          '${timeSlot.name.isNotEmpty ? ' (${timeSlot.name})' : ''}',
        )
        ..cellStyle = CellStyle(
          bold: true,
          fontSize: 12,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
        );
      currentRow++;
      
      // Encabezado de tabla
      final headers = ['Ministerio', 'Rol', 'Persona', 'Estado'];
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
          );
      }
      currentRow++;
      
      // Datos de roles
      if (roles.isEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          ..value = TextCellValue('No hay roles asignados')
          ..cellStyle = CellStyle(fontColorHex: ExcelColor.fromHexString('#9E9E9E'));
        currentRow++;
      } else {
        for (final roleData in roles) {
          final roleName = roleData['roleName'] as String;
          final ministryName = roleData['ministryName'] as String?;
          final capacity = roleData['capacity'] as int;
          final assignments = roleData['assignments'] as List<Map<String, dynamic>>;
          
          // Si no hay asignaciones, mostrar vacantes
          if (assignments.isEmpty) {
            for (var i = 0; i < capacity; i++) {
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                .value = TextCellValue(i == 0 ? (ministryName ?? 'Sin ministerio') : '');
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
                .value = TextCellValue(i == 0 ? roleName : '');
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
                .value = TextCellValue('(Sin asignar)');
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
                ..value = TextCellValue('Vacante')
                ..cellStyle = CellStyle(fontColorHex: ExcelColor.fromHexString('#9E9E9E'));
              currentRow++;
            }
          } else {
            // Mostrar asignaciones y vacantes restantes
            for (var i = 0; i < capacity; i++) {
              if (i < assignments.length) {
                final assignment = assignments[i];
                final userName = assignment['userName'] as String;
                final status = assignment['status'] as String;
                
                String statusText;
                String? statusColorHex;
                
                switch (status) {
                  case 'accepted':
                    statusText = 'Aceptado';
                    statusColorHex = '#4CAF50';
                    break;
                  case 'pending':
                    statusText = 'Pendiente';
                    statusColorHex = '#FF9800';
                    break;
                  case 'rejected':
                    statusText = 'Rechazó';
                    statusColorHex = '#F44336';
                    break;
                  default:
                    statusText = 'Desconocido';
                    statusColorHex = '#9E9E9E';
                }
                
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                  .value = TextCellValue(i == 0 ? (ministryName ?? 'Sin ministerio') : '');
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
                  .value = TextCellValue(i == 0 ? roleName : '');
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
                  .value = TextCellValue(userName);
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
                  ..value = TextCellValue(statusText)
                  ..cellStyle = CellStyle(fontColorHex: ExcelColor.fromHexString(statusColorHex));
              } else {
                // Vacante
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
                  .value = TextCellValue(i == 0 ? (ministryName ?? 'Sin ministerio') : '');
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
                  .value = TextCellValue(i == 0 ? roleName : '');
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
                  .value = TextCellValue('(Sin asignar)');
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
                  ..value = TextCellValue('Vacante')
                  ..cellStyle = CellStyle(fontColorHex: ExcelColor.fromHexString('#9E9E9E'));
              }
              currentRow++;
            }
          }
        }
      }
      
      currentRow++; // Espacio entre franjas
    }
    
    // Ajustar ancho de columnas
    sheet.setColumnWidth(0, 20); // Ministerio
    sheet.setColumnWidth(1, 20); // Rol
    sheet.setColumnWidth(2, 25); // Persona
    sheet.setColumnWidth(3, 15); // Estado
    
    // Guardar archivo
    final bytes = excel.encode();
    if (bytes != null) {
      return await _saveAndShareFile(
        bytes: bytes,
        fileName: 'resumen_culto_${cult.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(cult.date)}.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
    throw Exception('No se pudo generar el archivo Excel');
  }
  
  // Helpers
  
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }
  
  static pw.Widget _buildSummaryStats(
    List<TimeSlot> timeSlots,
    Map<String, List<Map<String, dynamic>>> rolesData,
  ) {
    int totalRoles = 0;
    int filledRoles = 0;
    int acceptedRoles = 0;
    int pendingRoles = 0;
    int rejectedRoles = 0;
    
    for (final timeSlot in timeSlots) {
      final roles = rolesData[timeSlot.id] ?? [];
      for (final roleData in roles) {
        final capacity = roleData['capacity'] as int;
        final assignments = roleData['assignments'] as List<Map<String, dynamic>>;
        
        totalRoles += capacity;
        filledRoles += assignments.length;
        
        for (final assignment in assignments) {
          final status = assignment['status'] as String;
          switch (status) {
            case 'accepted':
              acceptedRoles++;
              break;
            case 'pending':
              pendingRoles++;
              break;
            case 'rejected':
              rejectedRoles++;
              break;
          }
        }
      }
    }
    
    final vacantRoles = totalRoles - filledRoles;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Estadísticas del Resumen',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total de Roles', totalRoles.toString(), PdfColors.blue),
            _buildStatItem('Aceptados', acceptedRoles.toString(), PdfColors.green),
            _buildStatItem('Pendientes', pendingRoles.toString(), PdfColors.orange),
            _buildStatItem('Rechazados', rejectedRoles.toString(), PdfColors.red),
            _buildStatItem('Vacantes', vacantRoles.toString(), PdfColors.grey),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }
  
  static Future<String> _saveAndShareFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    // Intentar guardar en Downloads primero
    String? downloadsPath;
    
    if (Platform.isAndroid) {
      // En Android, usar la carpeta Downloads
      downloadsPath = '/storage/emulated/0/Download';
      final downloadsDir = Directory(downloadsPath);
      
      if (await downloadsDir.exists()) {
        final file = File('$downloadsPath/$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      }
    }
    
    // Si no se puede acceder a Downloads, usar documentos de la app
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

