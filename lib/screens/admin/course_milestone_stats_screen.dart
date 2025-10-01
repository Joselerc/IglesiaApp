import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/course_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'dart:math' as math;

class CourseMilestoneStatsScreen extends StatefulWidget {
  const CourseMilestoneStatsScreen({super.key});

  @override
  State<CourseMilestoneStatsScreen> createState() => _CourseMilestoneStatsScreenState();
}

class _CourseMilestoneStatsScreenState extends State<CourseMilestoneStatsScreen> {
  final CourseStatsService _statsService = CourseStatsService();
  late Future<Map<String, dynamic>> _statsFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Estado para ordenar la tabla
  String _sortBy = '100'; // Ordenar por completados (100%) por defecto
  bool _sortAscending = false;
  List<CourseStats> _allCourseStats = [];

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
    _allCourseStats = courseStats.where((s) => s.enrollmentCount > 0).toList();
    _sortCourseStats(); // Ordenar inicialmente
    final globalStats = _calculateGlobalMilestoneStats(_allCourseStats);

    return {
      'courseStats': _allCourseStats,
      'globalStats': globalStats,
    };
  }
  
  Map<String, dynamic> _calculateGlobalMilestoneStats(List<CourseStats> statsList) {
    if (statsList.isEmpty) {
      return {
        'globalMilestones': {'25': 0.0, '50': 0.0, '75': 0.0, '90': 0.0, '100': 0.0},
        'topCompletionCourse': null,
      };
    }

    Map<String, double> milestoneSums = {'25': 0, '50': 0, '75': 0, '90': 0, '100': 0};
    int totalEnrollments = 0;
    CourseStats? topCompletionC = statsList[0]; // Inicializar con el primero

    for (var stats in statsList) {
      totalEnrollments += stats.enrollmentCount;
      milestoneSums['25'] = milestoneSums['25']! + (stats.completionMilestones['25']! * stats.enrollmentCount);
      milestoneSums['50'] = milestoneSums['50']! + (stats.completionMilestones['50']! * stats.enrollmentCount);
      milestoneSums['75'] = milestoneSums['75']! + (stats.completionMilestones['75']! * stats.enrollmentCount);
      milestoneSums['90'] = milestoneSums['90']! + (stats.completionMilestones['90']! * stats.enrollmentCount);
      milestoneSums['100'] = milestoneSums['100']! + (stats.completionMilestones['100']! * stats.enrollmentCount);
      
      // Actualizar curso con mayor tasa de finalización (100%)
      if ((stats.completionMilestones['100'] ?? 0) > (topCompletionC!.completionMilestones['100'] ?? 0)) {
        topCompletionC = stats;
      }
    }

    final Map<String, double> globalMilestones = {
      '25': totalEnrollments > 0 ? milestoneSums['25']! / totalEnrollments : 0,
      '50': totalEnrollments > 0 ? milestoneSums['50']! / totalEnrollments : 0,
      '75': totalEnrollments > 0 ? milestoneSums['75']! / totalEnrollments : 0,
      '90': totalEnrollments > 0 ? milestoneSums['90']! / totalEnrollments : 0,
      '100': totalEnrollments > 0 ? milestoneSums['100']! / totalEnrollments : 0,
    };

    return {
      'globalMilestones': globalMilestones,
      'topCompletionCourse': topCompletionC,
    };
  }

  void _applyDateFilter() {
    setState(() => _statsFuture = _loadStats());
  }
  
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _statsFuture = _loadStats();
    });
  }

  int _compareStats(CourseStats a, CourseStats b, String sortBy, bool ascending) {
    int compare;
    switch (sortBy) {
      case 'title':
        compare = a.course.title.toLowerCase().compareTo(b.course.title.toLowerCase());
        break;
      case '25':
      case '50':
      case '75':
      case '90':
      case '100':
        compare = (a.completionMilestones[sortBy] ?? 0).compareTo(b.completionMilestones[sortBy] ?? 0);
        break;
      default:
        compare = 0;
    }
    return ascending ? compare : -compare;
  }
  
  void _sortCourseStats() {
    _allCourseStats.sort((a, b) => _compareStats(a, b, _sortBy, _sortAscending));
  }
  
  void _sortTable(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = false; // Descendente por defecto para hitos
      }
      _sortCourseStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitos de Conclusão por Curso'),
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
            return const Center(child: Text('Nenhuma estatística disponível.'));
          }
          
          final stats = snapshot.data!;
          final List<CourseStats> filteredCourseStats = _allCourseStats.where((stat) {
            final query = _searchQuery.toLowerCase();
            return stat.course.title.toLowerCase().contains(query);
          }).toList();
          final Map<String, dynamic> globalStats = stats['globalStats'] ?? {};

          return Column(
            children: [
              _buildHeaderCard(globalStats),
              Expanded(
                child: _buildMilestonesTable(filteredCourseStats),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> globalStats) {
    final Map<String, double> globalMilestones = Map<String, double>.from(globalStats['globalMilestones'] ?? {});
    final CourseStats? topCompletionCourse = globalStats['topCompletionCourse'];
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo Geral de Hitos', style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            _buildStatRow('Alcançam 25% (Média):', '${globalMilestones['25']?.toStringAsFixed(1) ?? '0'}%'),
            _buildStatRow('Alcançam 50% (Média):', '${globalMilestones['50']?.toStringAsFixed(1) ?? '0'}%'),
            _buildStatRow('Alcançam 75% (Média):', '${globalMilestones['75']?.toStringAsFixed(1) ?? '0'}%'),
            _buildStatRow('Alcançam 90% (Média):', '${globalMilestones['90']?.toStringAsFixed(1) ?? '0'}%'),
            _buildStatRow('Concluem 100% (Média):', '${globalMilestones['100']?.toStringAsFixed(1) ?? '0'}%'),
            if(topCompletionCourse != null)
              _buildStatRow('Maior Taxa de Conclusão:', '${topCompletionCourse.course.title} (${topCompletionCourse.completionMilestones['100']?.toStringAsFixed(1)}%)'),
            const Divider(height: 24, thickness: 0.5),
            
            // Filtros
            _buildDateFilterSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMilestonesTable(List<CourseStats> courseStats) {
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
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _getColumnIndex(_sortBy),
          sortAscending: _sortAscending,
          headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.05)),
          headingTextStyle: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
          dataRowMinHeight: 50,
          dataRowMaxHeight: 60,
          columnSpacing: 18,
          columns: [
            _buildSortableHeader('Curso', 'title'),
            _buildSortableHeader('>= 25%', '25', isNumeric: true),
            _buildSortableHeader('>= 50%', '50', isNumeric: true),
            _buildSortableHeader('>= 75%', '75', isNumeric: true),
            _buildSortableHeader('>= 90%', '90', isNumeric: true),
            _buildSortableHeader('100%', '100', isNumeric: true),
          ],
          rows: courseStats.map((stat) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150, 
                    child: Text(stat.course.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  onTap: () => Navigator.pushNamed(context, '/courses/detail', arguments: stat.course.id),
                ),
                DataCell(Text('${stat.completionMilestones['25']?.toStringAsFixed(1) ?? '0'}%')),
                DataCell(Text('${stat.completionMilestones['50']?.toStringAsFixed(1) ?? '0'}%')),
                DataCell(Text('${stat.completionMilestones['75']?.toStringAsFixed(1) ?? '0'}%')),
                DataCell(Text('${stat.completionMilestones['90']?.toStringAsFixed(1) ?? '0'}%')),
                DataCell(Text('${stat.completionMilestones['100']?.toStringAsFixed(1) ?? '0'}%')),
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
                    label: 'Data Final',
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
      label: Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
      numeric: isNumeric,
      onSort: (columnIndex, ascending) => _sortTable(columnName),
    );
  }

  int _getColumnIndex(String columnName) {
    switch (columnName) {
      case 'title': return 0;
      case '25': return 1;
      case '50': return 2;
      case '75': return 3;
      case '90': return 4;
      case '100': return 5;
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
          locale: const Locale('pt', 'BR'),
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