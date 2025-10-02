import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/course_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart'; // Opcional para carga

class CourseProgressStatsScreen extends StatefulWidget {
  const CourseProgressStatsScreen({super.key});

  @override
  State<CourseProgressStatsScreen> createState() => _CourseProgressStatsScreenState();
}

class _CourseProgressStatsScreenState extends State<CourseProgressStatsScreen> {
  final CourseStatsService _statsService = CourseStatsService();
  late Future<Map<String, dynamic>> _statsFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Estado para ordenar la tabla
  String _sortBy = 'averageProgressPercentage'; // Ordenar por progreso por defecto
  bool _sortAscending = false;
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
    // Reutilizar el método getAllCourseStats ya que contiene la info necesaria
    final courseStats = await _statsService.getAllCourseStats(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    // Filtrar cursos sin inscripciones para no mostrarlos en esta tabla
    _allCourseStats = courseStats.where((s) => s.enrollmentCount > 0).toList();
    _sortCourseStats(); // Ordenar inicialmente
    
    // Calcular los datos globales para el resumen
    final globalStats = _calculateGlobalStats(_allCourseStats);

    return {
      'courseStats': _allCourseStats,
      'globalStats': globalStats,
    };
  }
  
  // Calcular estadísticas globales (similar al dashboard, pero enfocado en progreso)
  Map<String, dynamic> _calculateGlobalStats(List<CourseStats> statsList) {
    if (statsList.isEmpty) {
      return {
        'globalAverageProgress': 0.0,
        'globalAverageLessons': 0.0,
        'highestProgressCourse': null,
        'lowestProgressCourse': null,
      };
    }

    double totalProgressSum = 0;
    double totalLessonsSum = 0;
    int totalEnrollmentsAcrossCourses = 0;
    CourseStats? highestProgressC = statsList[0];
    CourseStats? lowestProgressC = statsList[0];

    for (var stats in statsList) {
      // Ponderar por número de inscritos para obtener promedios globales más precisos
      totalEnrollmentsAcrossCourses += stats.enrollmentCount;
      totalProgressSum += stats.averageProgressPercentage * stats.enrollmentCount;
      totalLessonsSum += stats.averageCompletedLessons * stats.enrollmentCount;

      if (stats.averageProgressPercentage > highestProgressC!.averageProgressPercentage) {
        highestProgressC = stats;
      }
      if (stats.averageProgressPercentage < lowestProgressC!.averageProgressPercentage) {
        lowestProgressC = stats;
      }
    }

    final double globalAverageProgress = totalEnrollmentsAcrossCourses > 0 
        ? totalProgressSum / totalEnrollmentsAcrossCourses 
        : 0;
    final double globalAverageLessons = totalEnrollmentsAcrossCourses > 0 
        ? totalLessonsSum / totalEnrollmentsAcrossCourses 
        : 0;

    return {
      'globalAverageProgress': globalAverageProgress,
      'globalAverageLessons': globalAverageLessons,
      'highestProgressCourse': highestProgressC,
      'lowestProgressCourse': lowestProgressC,
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
      case 'averageProgressPercentage':
        compare = a.averageProgressPercentage.compareTo(b.averageProgressPercentage);
        break;
      case 'averageCompletedLessons':
        compare = a.averageCompletedLessons.compareTo(b.averageCompletedLessons);
        break;
      case 'totalLessons': // Ordenar por total de lecciones
        compare = a.course.totalLessons.compareTo(b.course.totalLessons);
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
        _sortAscending = false; // Descendente por defecto
      }
      _sortCourseStats(); // Reordenar la lista guardada
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.progressStatisticsTitle),
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
              
              // Tabla de Progreso
              Expanded(
                child: _buildProgressTable(filteredCourseStats),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Widgets Reutilizables --- 

  Widget _buildHeaderCard(Map<String, dynamic> globalStats) {
    final double globalAverageProgress = globalStats['globalAverageProgress'] ?? 0.0;
    final double globalAverageLessons = globalStats['globalAverageLessons'] ?? 0.0;
    final CourseStats? highest = globalStats['highestProgressCourse'];
    final CourseStats? lowest = globalStats['lowestProgressCourse'];
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo Geral de Progresso', style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            _buildStatRow(AppLocalizations.of(context)!.globalAverageProgress, '${globalAverageProgress.toStringAsFixed(1)}%'),
            _buildStatRow(AppLocalizations.of(context)!.averageLessonsCompleted, globalAverageLessons.toStringAsFixed(1)),
            if (highest != null) 
              _buildStatRow(AppLocalizations.of(context)!.highestProgress, '${highest.course.title} (${highest.averageProgressPercentage.toStringAsFixed(1)}%)'),
            if (lowest != null) 
              _buildStatRow('Menor Progresso:', '${lowest.course.title} (${lowest.averageProgressPercentage.toStringAsFixed(1)}%)'),
            const Divider(height: 24, thickness: 0.5),
            
            // Filtros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar curso...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty ? 
                        IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        }) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.calendar_today, 
                         color: (_startDate != null || _endDate != null) ? AppColors.primary : Colors.grey[600]),
                  tooltip: 'Filtrar por Data de Inscrição',
                  onPressed: _showDateFilterDialog,
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off, color: Colors.red, size: 20),
                    tooltip: 'Limpar Filtro de Data',
                    onPressed: _clearDateFilter,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressTable(List<CourseStats> courseStats) {
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
      // Scroll vertical para la tabla entera si excede la altura
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
          columnSpacing: 18, // Reducir un poco el espacio entre columnas
          columns: [
            _buildSortableHeader(AppLocalizations.of(context)!.course, 'title'),
            _buildSortableHeader(AppLocalizations.of(context)!.progressPercentage, 'averageProgressPercentage', isNumeric: true),
            _buildSortableHeader(AppLocalizations.of(context)!.averageLessons, 'averageCompletedLessons', isNumeric: true),
            _buildSortableHeader(AppLocalizations.of(context)!.totalLessonsHeader, 'totalLessons', isNumeric: true),
          ],
          rows: courseStats.map((stat) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(stat.course.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/admin/course-stats/detail', arguments: stat.course.id),
                ),
                DataCell(Text('${stat.averageProgressPercentage.toStringAsFixed(1)}%')),
                DataCell(Text(stat.averageCompletedLessons.toStringAsFixed(1))),
                DataCell(Text(stat.course.totalLessons.toString())),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  // Helper para fila de estadística simple
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

  Future<void> _showDateFilterDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'), // Asegurar localización
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
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      });
      _applyDateFilter();
    }
  }

  DataColumn _buildSortableHeader(String label, String columnName, {bool isNumeric = false}) {
    return DataColumn(
      label: Flexible( // Envolver con Flexible
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      numeric: isNumeric,
      onSort: (columnIndex, ascending) => _sortTable(columnName),
    );
  }

  int _getColumnIndex(String columnName) {
    switch (columnName) {
      case 'title': return 0;
      case 'averageProgressPercentage': return 1;
      case 'averageCompletedLessons': return 2;
      case 'totalLessons': return 3;
      default: return 0;
    }
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
                Text('Filtrar por Data de Inscrição', style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
                if (_startDate != null || _endDate != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                    label: const Text('Limpar', style: TextStyle(color: Colors.red)),
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
                    label: 'Data Inicial',
                    date: _startDate,
                    onDatePicked: (pickedDate) => setState(() => _startDate = pickedDate),
                    firstDate: DateTime(2020),
                    lastDate: _endDate ?? DateTime.now(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePickerField(
                    label: 'Data Final',
                    date: _endDate,
                    onDatePicked: (pickedDate) => setState(() => _endDate = pickedDate),
                    firstDate: _startDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Aplicar Filtro'),
                // Habilitar solo si ambas fechas están seleccionadas
                onPressed: (_startDate != null && _endDate != null) ? _applyDateFilter : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para crear el campo de fecha (Mover aquí desde la pantalla principal si no existe)
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