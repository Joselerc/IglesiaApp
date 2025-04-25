import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para definir los filtros de un reporte personalizado
class ReportFilter {
  final String field;
  final String operator; // 'equals', 'greaterThan', 'lessThan', 'contains', 'between'
  final dynamic value;
  final dynamic secondValue; // Para el operador 'between'
  
  ReportFilter({
    required this.field,
    required this.operator,
    required this.value,
    this.secondValue,
  });
  
  factory ReportFilter.fromMap(Map<String, dynamic> map) {
    return ReportFilter(
      field: map['field'] ?? '',
      operator: map['operator'] ?? 'equals',
      value: map['value'],
      secondValue: map['secondValue'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'operator': operator,
      'value': value,
      'secondValue': secondValue,
    };
  }
}

/// Modelo para definir una columna en el reporte
class ReportColumn {
  final String field;
  final String displayName;
  final String dataType; // 'string', 'number', 'date', 'boolean'
  final String? format; // Formato de presentación
  final bool isCalculated;
  final String? calculationFormula;
  
  ReportColumn({
    required this.field,
    required this.displayName,
    required this.dataType,
    this.format,
    required this.isCalculated,
    this.calculationFormula,
  });
  
  factory ReportColumn.fromMap(Map<String, dynamic> map) {
    return ReportColumn(
      field: map['field'] ?? '',
      displayName: map['displayName'] ?? '',
      dataType: map['dataType'] ?? 'string',
      format: map['format'],
      isCalculated: map['isCalculated'] ?? false,
      calculationFormula: map['calculationFormula'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'displayName': displayName,
      'dataType': dataType,
      'format': format,
      'isCalculated': isCalculated,
      'calculationFormula': calculationFormula,
    };
  }
}

/// Modelo para definir una agrupación en el reporte
class ReportGrouping {
  final String field;
  final String aggregation; // 'count', 'sum', 'avg', 'min', 'max'
  final String? aggregationField; // Campo sobre el que se aplica la agregación
  
  ReportGrouping({
    required this.field,
    required this.aggregation,
    this.aggregationField,
  });
  
  factory ReportGrouping.fromMap(Map<String, dynamic> map) {
    return ReportGrouping(
      field: map['field'] ?? '',
      aggregation: map['aggregation'] ?? 'count',
      aggregationField: map['aggregationField'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'aggregation': aggregation,
      'aggregationField': aggregationField,
    };
  }
}

/// Modelo para representar la configuración de un reporte personalizado
class CustomReport {
  final String reportId;
  final String reportName;
  final String reportDescription;
  final String reportType; // 'members', 'ministries', 'groups', 'events', 'cults', etc.
  final String creatorId;
  final DateTime createdAt;
  final DateTime? lastRunAt;
  
  // Configuración de datos
  final List<ReportFilter> filters;
  final List<ReportColumn> columns;
  final List<ReportGrouping> groupings;
  final String? sortField;
  final bool sortAscending;
  final int? maxResults;
  
  // Métricas y filtros específicos
  final List<String>? metrics;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? filterId;
  final String? filterType;
  Map<String, dynamic> data;
  
  // Opciones de visualización
  final String displayType; // 'table', 'chart', 'combined'
  final String? chartType;  // 'bar', 'line', 'pie', etc.
  final Map<String, dynamic>? chartOptions;
  
  // Opciones de exportación
  final List<String> exportFormats; // 'pdf', 'csv', 'excel'
  
  CustomReport({
    required this.reportId,
    required this.reportName,
    required this.reportDescription,
    required this.reportType,
    required this.creatorId,
    required this.createdAt,
    this.lastRunAt,
    required this.filters,
    required this.columns,
    required this.groupings,
    this.sortField,
    required this.sortAscending,
    this.maxResults,
    this.metrics,
    this.startDate,
    this.endDate,
    this.filterId,
    this.filterType,
    this.data = const {},
    required this.displayType,
    this.chartType,
    this.chartOptions,
    required this.exportFormats,
  });
  
  factory CustomReport.fromMap(Map<String, dynamic> map) {
    return CustomReport(
      reportId: map['reportId'] ?? '',
      reportName: map['reportName'] ?? 'Reporte sin nombre',
      reportDescription: map['reportDescription'] ?? '',
      reportType: map['reportType'] ?? 'general',
      creatorId: map['creatorId'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastRunAt: map['lastRunAt'] is Timestamp 
          ? (map['lastRunAt'] as Timestamp).toDate() 
          : (map['lastRunAt'] != null ? DateTime.parse(map['lastRunAt']) : null),
      filters: (map['filters'] as List<dynamic>?)
          ?.map((e) => ReportFilter.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      columns: (map['columns'] as List<dynamic>?)
          ?.map((e) => ReportColumn.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      groupings: (map['groupings'] as List<dynamic>?)
          ?.map((e) => ReportGrouping.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      sortField: map['sortField'],
      sortAscending: map['sortAscending'] ?? true,
      maxResults: map['maxResults'],
      metrics: List<String>.from(map['metrics'] ?? []),
      startDate: map['startDate'] is Timestamp 
          ? (map['startDate'] as Timestamp).toDate() 
          : (map['startDate'] != null ? DateTime.parse(map['startDate']) : null),
      endDate: map['endDate'] is Timestamp 
          ? (map['endDate'] as Timestamp).toDate() 
          : (map['endDate'] != null ? DateTime.parse(map['endDate']) : null),
      filterId: map['filterId'],
      filterType: map['filterType'],
      data: map['data'] as Map<String, dynamic>? ?? {},
      displayType: map['displayType'] ?? 'table',
      chartType: map['chartType'],
      chartOptions: map['chartOptions'] as Map<String, dynamic>?,
      exportFormats: List<String>.from(map['exportFormats'] ?? ['pdf']),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'reportName': reportName,
      'reportDescription': reportDescription,
      'reportType': reportType,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastRunAt': lastRunAt != null ? Timestamp.fromDate(lastRunAt!) : null,
      'filters': filters.map((e) => e.toMap()).toList(),
      'columns': columns.map((e) => e.toMap()).toList(),
      'groupings': groupings.map((e) => e.toMap()).toList(),
      'sortField': sortField,
      'sortAscending': sortAscending,
      'maxResults': maxResults,
      'metrics': metrics,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'filterId': filterId,
      'filterType': filterType,
      'data': data,
      'displayType': displayType,
      'chartType': chartType,
      'chartOptions': chartOptions,
      'exportFormats': exportFormats,
    };
  }
}

/// Modelo para representar los resultados de un reporte personalizado
class ReportResult {
  final String reportId;
  final String reportName;
  final DateTime runDate;
  final int totalRecords;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? chartData;
  
  ReportResult({
    required this.reportId,
    required this.reportName,
    required this.runDate,
    required this.totalRecords,
    required this.rows,
    this.summary,
    this.chartData,
  });
  
  factory ReportResult.fromMap(Map<String, dynamic> map) {
    return ReportResult(
      reportId: map['reportId'] ?? '',
      reportName: map['reportName'] ?? '',
      runDate: map['runDate'] is Timestamp 
          ? (map['runDate'] as Timestamp).toDate() 
          : DateTime.parse(map['runDate'] ?? DateTime.now().toIso8601String()),
      totalRecords: map['totalRecords'] ?? 0,
      rows: List<Map<String, dynamic>>.from(map['rows'] ?? []),
      summary: map['summary'] as Map<String, dynamic>?,
      chartData: map['chartData'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'reportName': reportName,
      'runDate': Timestamp.fromDate(runDate),
      'totalRecords': totalRecords,
      'rows': rows,
      'summary': summary,
      'chartData': chartData,
    };
  }
} 