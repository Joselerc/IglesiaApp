import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/course_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart'; // Opcional para carga
import 'dart:math' as math;

class CourseCompletionStatsScreen extends StatefulWidget {
  const CourseCompletionStatsScreen({super.key});

  @override
  State<CourseCompletionStatsScreen> createState() => _CourseCompletionStatsScreenState();
}

class _CourseCompletionStatsScreenState extends State<CourseCompletionStatsScreen> {
  final CourseStatsService _statsService = CourseStatsService();
  late Future<Map<String, dynamic>> _statsFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Estado para ordenar la tabla
  String _sortBy = 'averageCompletionTime'; // Ordenar por tiempo por defecto
  bool _sortAscending = true; // Ascendente por defecto (más rápido primero)
  List<CourseStats> _allCourseStats = []; // Lista completa para filtrar/buscar

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final courseStats = await _statsService.getAllCourseStats(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    // Filtrar cursos SIN inscripciones para no calcular estadísticas vacías
    _allCourseStats = courseStats.where((s) => s.enrollmentCount > 0).toList();
    
    // Calcular estadísticas globales (podríamos mover esto al servicio si se vuelve complejo)
    final globalStats = _calculateGlobalCompletionStats(_allCourseStats);
    
    _sortCourseStats(); // Ordenar inicialmente

    return {
      'courseStats': _allCourseStats,
      'globalStats': globalStats,
    };
  }
  
  Map<String, dynamic> _calculateGlobalCompletionStats(List<CourseStats> statsList) {
     if (statsList.isEmpty) {
      return {
        'globalAverageCompletionTime': null,
        'overallCompletionRate': 0.0,
        'fastestCompletionCourse': null,
        'slowestCompletionCourse': null,
      };
    }
    
    Duration totalTimeSum = Duration.zero;
    int totalCompletions = 0;
    int totalEnrollments = 0;
    CourseStats? fastestC;
    CourseStats? slowestC;

    for (var stats in statsList) {
      totalEnrollments += stats.enrollmentCount;
      // Calcular total de completados basado en el hito 100%
      int completionsForCourse = (stats.completionMilestones['100']! / 100 * stats.enrollmentCount).round();
      totalCompletions += completionsForCourse;
      
      if (stats.averageCompletionTime != null && completionsForCourse > 0) {
        // Ponderar el tiempo promedio por el número de completados
        totalTimeSum += stats.averageCompletionTime! * completionsForCourse;
        
        if (fastestC == null || stats.averageCompletionTime! < fastestC.averageCompletionTime!) {
          fastestC = stats;
        }
        if (slowestC == null || stats.averageCompletionTime! > slowestC.averageCompletionTime!) {
          slowestC = stats;
        }
      }
    }

    final Duration? globalAverageCompletionTime = totalCompletions > 0
        ? totalTimeSum ~/ totalCompletions
        : null;
    final double overallCompletionRate = totalEnrollments > 0 
        ? (totalCompletions / totalEnrollments) * 100 
        : 0;
        
    return {
      'globalAverageCompletionTime': globalAverageCompletionTime,
      'overallCompletionRate': overallCompletionRate,
      'fastestCompletionCourse': fastestC,
      'slowestCompletionCourse': slowestC,
    };
  }

  void _applyDateFilter() {
    setState(() {
      _statsFuture = _loadStats(); 
    });
  }
  
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _statsFuture = _loadStats(); 
    });
  }

  // Comparador genérico para ordenar
  int _compareStats(CourseStats a, CourseStats b, String sortBy, bool ascending) {
    int compare;
    switch (sortBy) {
      case 'title':
        compare = a.course.title.toLowerCase().compareTo(b.course.title.toLowerCase());
        break;
      case 'averageCompletionTime':
        if (a.averageCompletionTime == null && b.averageCompletionTime == null) compare = 0;
        else if (a.averageCompletionTime == null) compare = 1; // Nulos al final
        else if (b.averageCompletionTime == null) compare = -1; // Nulos al final
        else compare = a.averageCompletionTime!.compareTo(b.averageCompletionTime!);
        break;
      case 'completionRate':
        compare = (a.completionMilestones['100'] ?? 0).compareTo(b.completionMilestones['100'] ?? 0);
        break;
      case 'completedCount': // Necesitamos calcularlo o añadirlo a CourseStats
         int completedA = (a.completionMilestones['100']! / 100 * a.enrollmentCount).round();
         int completedB = (b.completionMilestones['100']! / 100 * b.enrollmentCount).round();
         compare = completedA.compareTo(completedB);
        break;
      default:
        compare = 0;
    }
    return ascending ? compare : -compare;
  }
  
  // Ordena la lista actual (_allCourseStats)
  void _sortCourseStats() {
    _allCourseStats.sort((a, b) => _compareStats(a, b, _sortBy, _sortAscending));
  }
  
  // Cambia la columna de ordenamiento y reordena
  void _sortTable(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = (column == 'averageCompletionTime'); // Ascendente por defecto para tiempo
      }
      _sortCourseStats(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.completionStatisticsTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar estatísticas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(AppLocalizations.of(context)!.noStatisticsAvailable));
          }
          
          final stats = snapshot.data!;
          final List<CourseStats> filteredCourseStats = _allCourseStats.where((stat) {
            final query = _searchQuery.toLowerCase();
            return stat.course.title.toLowerCase().contains(query);
          }).toList();
          final Map<String, dynamic> globalStats = stats['globalStats'] ?? {};

          return Column(
            children: [
              // Resumen general y Filtros
              _buildHeaderCard(globalStats),
              
              // Tabla de Finalización
              Expanded(
                child: _buildCompletionTable(filteredCourseStats),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Widgets Reutilizables --- 

  Widget _buildHeaderCard(Map<String, dynamic> globalStats) {
    final Duration? globalAverageTime = globalStats['globalAverageCompletionTime'];
    final double overallRate = globalStats['overallCompletionRate'] ?? 0.0;
    final CourseStats? fastest = globalStats['fastestCompletionCourse'];
    final CourseStats? slowest = globalStats['slowestCompletionCourse'];
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.completionSummary, style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            _buildStatRow(AppLocalizations.of(context)!.globalAverageTime, _formatDuration(globalAverageTime) ?? 'N/A'),
            _buildStatRow(AppLocalizations.of(context)!.globalCompletionRate, '${overallRate.toStringAsFixed(1)}%'),
            if (fastest != null) 
              _buildStatRow(AppLocalizations.of(context)!.fastestCompletion, '${fastest.course.title} (${_formatDuration(fastest.averageCompletionTime)})'),
            if (slowest != null) 
              _buildStatRow(AppLocalizations.of(context)!.slowestCompletion, '${slowest.course.title} (${_formatDuration(slowest.averageCompletionTime)})'),
            const Divider(height: 24, thickness: 0.5),
            
            // Filtros
            _buildDateFilterSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompletionTable(List<CourseStats> courseStats) {
    if (courseStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _searchQuery.isNotEmpty 
              ? 'Nenhum curso encontrado para "$_searchQuery".' 
              : 'Nenhum curso encontrado com os filtros aplicados.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: DataTable(
          sortColumnIndex: _getColumnIndex(_sortBy),
          sortAscending: _sortAscending,
          headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.05)),
          headingTextStyle: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
          dataRowMinHeight: 50,
          dataRowMaxHeight: 60,
          columnSpacing: 16,
          columns: [
            _buildSortableHeader(AppLocalizations.of(context)!.course, 'title'),
            _buildSortableHeader(AppLocalizations.of(context)!.averageTime, 'averageCompletionTime'),
            _buildSortableHeader(AppLocalizations.of(context)!.completed, 'completedCount', isNumeric: true),
            _buildSortableHeader(AppLocalizations.of(context)!.completionRate, 'completionRate', isNumeric: true),
          ],
          rows: courseStats.map((stat) {
            final completionRate = stat.completionMilestones['100'] ?? 0;
            final completedCount = (completionRate / 100 * stat.enrollmentCount).round();
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(stat.course.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/admin/course-stats/detail', arguments: stat.course.id),
                ),
                DataCell(Text(_formatDuration(stat.averageCompletionTime) ?? 'N/A')),
                DataCell(Text(completedCount.toString())),
                DataCell(Text('${completionRate.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para el filtro de fecha con estilo mejorado
  Widget _buildDateFilterSection() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.filterByEnrollmentDate, 
                    style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                    label: Text(AppLocalizations.of(context)!.clear, style: const TextStyle(color: Colors.red)),
                    onPressed: _clearDateFilter,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerField(
                    label: AppLocalizations.of(context)!.startDate,
                    date: _startDate,
                    onDatePicked: (pickedDate) => setState(() {
                      _startDate = pickedDate;
                      // Aplicar filtro automáticamente solo si ambas fechas están seleccionadas
                      if (_endDate != null) _applyDateFilter(); 
                    }),
                    firstDate: DateTime(2020),
                    lastDate: _endDate ?? DateTime.now(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerField(
                    label: AppLocalizations.of(context)!.endDate,
                    date: _endDate,
                    onDatePicked: (pickedDate) => setState(() {
                      _endDate = pickedDate;
                       // Aplicar filtro automáticamente solo si ambas fechas están seleccionadas
                      if (_startDate != null) _applyDateFilter();
                    }),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  ),
                ),
              ],
            ),
            // Eliminar botón "Aplicar Filtro"
          ],
        ),
      ),
    );
  }

  DataColumn _buildSortableHeader(String label, String columnName, {bool isNumeric = false}) {
    return DataColumn(
      label: Flexible(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      numeric: isNumeric,
      onSort: (columnIndex, ascending) => _sortTable(columnName),
    );
  }

  int _getColumnIndex(String columnName) {
    switch (columnName) {
      case 'title': return 0;
      case 'averageCompletionTime': return 1;
      case 'completedCount': return 2;
      case 'completionRate': return 3;
      default: return 0;
    }
  }
  
  String? _formatDuration(Duration? duration) {
    if (duration == null) return null;
    if (duration.inDays > 0) return '${duration.inDays} d';
    if (duration.inHours > 0) return '${duration.inHours} h';
    if (duration.inMinutes > 0) return '${duration.inMinutes} min';
    return 'Menos de 1 min';
  }

  // Helper para crear el campo de fecha
  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onDatePicked,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: lastDate,
          locale: Localizations.localeOf(context),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary, 
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          onDatePicked(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(
          date != null ? formatter.format(date) : '--/--/----',
          style: TextStyle(color: date != null ? AppColors.textPrimary : Colors.grey),
        ),
      ),
    );
  }
} 