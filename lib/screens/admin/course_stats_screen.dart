import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/course_stats_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/shimmer_loading.dart';
import 'package:fl_chart/fl_chart.dart'; // Para gráficos (si se usa)
import 'dart:math' as math;

class CourseStatsScreen extends StatefulWidget {
  const CourseStatsScreen({super.key});

  @override
  State<CourseStatsScreen> createState() => _CourseStatsScreenState();
}

class _CourseStatsScreenState extends State<CourseStatsScreen> {
  final CourseStatsService _statsService = CourseStatsService();
  final PermissionService _permissionService = PermissionService();
  late Future<Map<String, dynamic>> _statsFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Estado para ordenar la tabla de ranking
  String _rankingSortBy = 'enrollmentCount';
  bool _rankingSortAscending = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final totalEnrollments = await _statsService.getTotalEnrollments();
    final courseStatsList = await _statsService.getAllCourseStats(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    // Calcular estadísticas globales y top/bottom aquí
    Map<String, dynamic> globalStats = _calculateGlobalStats(courseStatsList);
    
    // Ordenar para el ranking inicial
    courseStatsList.sort((a, b) => _compareStats(a, b, _rankingSortBy, _rankingSortAscending));
    
    return {
      'totalEnrollments': totalEnrollments,
      'courseStatsList': courseStatsList,
      ...globalStats, // Añadir estadísticas globales calculadas
    };
  }

  // NUEVO: Calcular estadísticas globales y top/bottom
  Map<String, dynamic> _calculateGlobalStats(List<CourseStats> statsList) {
    if (statsList.isEmpty) {
      return {
        'globalAverageProgress': 0.0,
        'globalAverageLessons': 0.0,
        'globalAverageCompletionTime': null,
        'globalMilestones': {'25': 0.0, '50': 0.0, '75': 0.0, '90': 0.0, '100': 0.0},
        'topEnrollmentCourses': [],
        'highestProgressCourse': null,
        'lowestProgressCourse': null,
        'fastestCompletionCourse': null,
        'slowestCompletionCourse': null,
      };
    }

    double totalProgressSum = 0;
    double totalLessonsSum = 0;
    Duration totalTimeSum = Duration.zero;
    int coursesWithCompletionData = 0;
    int totalEnrollmentsAcrossCourses = 0;
    Map<String, double> milestoneSums = {'25': 0, '50': 0, '75': 0, '90': 0, '100': 0};

    CourseStats? highestProgressC = statsList[0];
    CourseStats? lowestProgressC = statsList[0];
    CourseStats? fastestCompletionC;
    CourseStats? slowestCompletionC;

    for (var stats in statsList) {
      totalEnrollmentsAcrossCourses += stats.enrollmentCount;
      totalProgressSum += stats.averageProgressPercentage * stats.enrollmentCount; // Ponderado
      totalLessonsSum += stats.averageCompletedLessons * stats.enrollmentCount; // Ponderado

      if (stats.averageCompletionTime != null) {
        totalTimeSum += stats.averageCompletionTime! * stats.enrollmentCount; // Ponderado
        coursesWithCompletionData += stats.enrollmentCount;
        if (fastestCompletionC == null || stats.averageCompletionTime! < fastestCompletionC.averageCompletionTime!) {
          fastestCompletionC = stats;
        }
        if (slowestCompletionC == null || stats.averageCompletionTime! > slowestCompletionC.averageCompletionTime!) {
          slowestCompletionC = stats;
        }
      }

      if (stats.averageProgressPercentage > highestProgressC!.averageProgressPercentage) {
        highestProgressC = stats;
      }
      if (stats.averageProgressPercentage < lowestProgressC!.averageProgressPercentage) {
        lowestProgressC = stats;
      }
      
      milestoneSums['25'] = milestoneSums['25']! + (stats.completionMilestones['25']! * stats.enrollmentCount);
      milestoneSums['50'] = milestoneSums['50']! + (stats.completionMilestones['50']! * stats.enrollmentCount);
      milestoneSums['75'] = milestoneSums['75']! + (stats.completionMilestones['75']! * stats.enrollmentCount);
      milestoneSums['90'] = milestoneSums['90']! + (stats.completionMilestones['90']! * stats.enrollmentCount);
      milestoneSums['100'] = milestoneSums['100']! + (stats.completionMilestones['100']! * stats.enrollmentCount);
    }

    final double globalAverageProgress = totalEnrollmentsAcrossCourses > 0 
        ? totalProgressSum / totalEnrollmentsAcrossCourses 
        : 0;
    final double globalAverageLessons = totalEnrollmentsAcrossCourses > 0 
        ? totalLessonsSum / totalEnrollmentsAcrossCourses 
        : 0;
    final Duration? globalAverageCompletionTime = coursesWithCompletionData > 0 
        ? totalTimeSum ~/ coursesWithCompletionData 
        : null;
    final Map<String, double> globalMilestones = {
      '25': totalEnrollmentsAcrossCourses > 0 ? milestoneSums['25']! / totalEnrollmentsAcrossCourses : 0,
      '50': totalEnrollmentsAcrossCourses > 0 ? milestoneSums['50']! / totalEnrollmentsAcrossCourses : 0,
      '75': totalEnrollmentsAcrossCourses > 0 ? milestoneSums['75']! / totalEnrollmentsAcrossCourses : 0,
      '90': totalEnrollmentsAcrossCourses > 0 ? milestoneSums['90']! / totalEnrollmentsAcrossCourses : 0,
      '100': totalEnrollmentsAcrossCourses > 0 ? milestoneSums['100']! / totalEnrollmentsAcrossCourses : 0,
    };
    
    // Top 3 inscritos
    List<CourseStats> sortedByEnrollment = List.from(statsList);
    sortedByEnrollment.sort((a, b) => b.enrollmentCount.compareTo(a.enrollmentCount));
    List<CourseStats> topEnrollmentCourses = sortedByEnrollment.take(3).toList();

    return {
      'globalAverageProgress': globalAverageProgress,
      'globalAverageLessons': globalAverageLessons,
      'globalAverageCompletionTime': globalAverageCompletionTime,
      'globalMilestones': globalMilestones,
      'topEnrollmentCourses': topEnrollmentCourses,
      'highestProgressCourse': highestProgressC,
      'lowestProgressCourse': lowestProgressC,
      'fastestCompletionCourse': fastestCompletionC,
      'slowestCompletionCourse': slowestCompletionC,
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
        compare = a.course.title.compareTo(b.course.title);
        break;
      case 'enrollmentCount':
        compare = a.enrollmentCount.compareTo(b.enrollmentCount);
        break;
      case 'averageProgressPercentage':
        compare = a.averageProgressPercentage.compareTo(b.averageProgressPercentage);
        break;
      case 'averageCompletedLessons':
        compare = a.averageCompletedLessons.compareTo(b.averageCompletedLessons);
        break;
      case 'averageCompletionTime':
        if (a.averageCompletionTime == null && b.averageCompletionTime == null) compare = 0;
        else if (a.averageCompletionTime == null) compare = 1;
        else if (b.averageCompletionTime == null) compare = -1;
        else compare = a.averageCompletionTime!.compareTo(b.averageCompletionTime!);
        break;
      case 'milestone100':
        compare = (a.completionMilestones['100'] ?? 0).compareTo(b.completionMilestones['100'] ?? 0);
        break;
      default:
        compare = 0;
    }
    return ascending ? compare : -compare;
  }

  // Ordenar tabla de ranking
  void _sortRankingTable(String column) {
    setState(() {
      if (_rankingSortBy == column) {
        _rankingSortAscending = !_rankingSortAscending;
      } else {
        _rankingSortBy = column;
        _rankingSortAscending = false;
      }
      // Reordenar la lista dentro del FutureBuilder usando el comparador
      _statsFuture = _statsFuture.then((stats) {
        List<CourseStats> currentStats = List.from(stats['courseStatsList']);
        currentStats.sort((a, b) => _compareStats(a, b, _rankingSortBy, _rankingSortAscending));
        return {
          ...stats, // Mantener otras estadísticas
          'courseStatsList': currentStats,
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.courseStatisticsTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('view_course_stats'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(
              child: Text('${AppLocalizations.of(context)!.errorCheckingPermissions}: ${permissionSnapshot.error}'),
            );
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
                    Text(AppLocalizations.of(context)!.accessDenied, 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.noPermissionViewCourseStats,
                      textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _statsFuture = _loadStats();
              });
            },
            child: FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(AppLocalizations.of(context)!.errorLoadingCourseStats(snapshot.error.toString())));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: Text(AppLocalizations.of(context)!.noStatisticsAvailable));
                }
                
                final stats = snapshot.data!;
                final int totalEnrollments = stats['totalEnrollments'] ?? 0;
                final List<CourseStats> courseStatsList = List.from(stats['courseStatsList'] ?? []);
                
                // Extraer estadísticas globales calculadas
                final double globalAverageProgress = stats['globalAverageProgress'] ?? 0.0;
                final double globalAverageLessons = stats['globalAverageLessons'] ?? 0.0;
                final Duration? globalAverageCompletionTime = stats['globalAverageCompletionTime'];
                final Map<String, double> globalMilestones = Map<String, double>.from(stats['globalMilestones'] ?? {});
                final List<CourseStats> topEnrollmentCourses = List<CourseStats>.from(stats['topEnrollmentCourses'] ?? []);
                final CourseStats? highestProgressCourse = stats['highestProgressCourse'];
                final CourseStats? lowestProgressCourse = stats['lowestProgressCourse'];
                final CourseStats? fastestCompletionCourse = stats['fastestCompletionCourse'];
                final CourseStats? slowestCompletionCourse = stats['slowestCompletionCourse'];
                
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  children: [
                    _buildDateFilterSection(),
                    const SizedBox(height: 24),
                    
                    // --- Sección 1: Resumo de Inscripciones ---
                    _buildEnrollmentSummary(totalEnrollments, topEnrollmentCourses),
                    const SizedBox(height: 24),
                    
                    // --- Sección 2: Progreso Medio ---
                    _buildProgressSummary(globalAverageProgress, globalAverageLessons, highestProgressCourse, lowestProgressCourse),
                    const SizedBox(height: 24),
                    
                    // --- Sección 3: Finalización ---
                    _buildCompletionSummary(globalAverageCompletionTime, fastestCompletionCourse, slowestCompletionCourse),
                    const SizedBox(height: 24),
                    
                    // --- Sección 4: Hitos de Completado ---
                    _buildMilestonesSummary(globalMilestones),
                    const SizedBox(height: 24),
                    
                    // --- Sección 5: Ranking de Cursos ---
                    _buildRankingTable(courseStatsList),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  // --- Widgets para cada sección del Dashboard ---
  
  Widget _buildEnrollmentSummary(int totalEnrollments, List<CourseStats> topCourses) {
    return _buildDashboardCard(
      title: AppLocalizations.of(context)!.enrollmentSummary,
      icon: Icons.group_add_outlined,
      iconColor: Colors.blue,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.totalEnrollments, '$totalEnrollments'),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context)!.top3CoursesEnrolled, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (topCourses.isEmpty)
          Text(AppLocalizations.of(context)!.noCourseToShow, style: TextStyle(color: Colors.grey))
        else
          ...topCourses.map((stat) => 
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ' • ${stat.course.title}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppTextStyles.bodyText2,
                    )
                  ),
                  Text(
                    stat.enrollmentCount.toString(), 
                    style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            )
          ),
      ],
      onSeeMore: () {
        // Navegar a la pantalla de detalles de inscripciones
        Navigator.pushNamed(context, '/admin/course-stats/enrollments');
        //_showNotImplemented();
      },
    );
  }

  Widget _buildProgressSummary(double globalAvgProgress, double globalAvgLessons, CourseStats? highest, CourseStats? lowest) {
    return _buildDashboardCard(
      title: AppLocalizations.of(context)!.averageProgress,
      icon: Icons.show_chart_outlined,
      iconColor: Colors.green,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.globalAverageProgress, '${globalAvgProgress.toStringAsFixed(1)}%'),
        _buildStatRow(AppLocalizations.of(context)!.averageLessonsCompleted, globalAvgLessons.toStringAsFixed(1)),
        const SizedBox(height: 12),
        if (highest != null) 
          _buildStatRow('${AppLocalizations.of(context)!.highestProgress}:', '${highest.course.title} (${highest.averageProgressPercentage.toStringAsFixed(1)}%)'),
        if (lowest != null) 
          _buildStatRow('${AppLocalizations.of(context)!.lowestProgress}:', '${lowest.course.title} (${lowest.averageProgressPercentage.toStringAsFixed(1)}%)'),
      ],
      onSeeMore: () {
        // Navegar a la pantalla de detalles de progreso
        Navigator.pushNamed(context, '/admin/course-stats/progress');
        //_showNotImplemented();
      },
    );
  }

  Widget _buildCompletionSummary(Duration? globalAvgTime, CourseStats? fastest, CourseStats? slowest) {
    return _buildDashboardCard(
      title: AppLocalizations.of(context)!.completion,
      icon: Icons.hourglass_bottom_outlined,
      iconColor: Colors.orange,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.globalAverageTime, _formatDuration(globalAvgTime) ?? 'N/A'),
        const SizedBox(height: 12),
        if (fastest != null)
          _buildStatRow(AppLocalizations.of(context)!.fastestCompletion, '${fastest.course.title} (${_formatDuration(fastest.averageCompletionTime)})'),
        if (slowest != null)
          _buildStatRow(AppLocalizations.of(context)!.slowestCompletion, '${slowest.course.title} (${_formatDuration(slowest.averageCompletionTime)})')
      ],
      onSeeMore: () {
        // Navegar a la pantalla de detalles de finalización
        Navigator.pushNamed(context, '/admin/course-stats/completion');
        //_showNotImplemented();
      },
    );
  }

  Widget _buildMilestonesSummary(Map<String, double> milestones) {
    return _buildDashboardCard(
      title: AppLocalizations.of(context)!.completionMilestones,
      icon: Icons.flag_outlined,
      iconColor: Colors.purple,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.reach25Percent, '${milestones['25']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reach50Percent, '${milestones['50']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reach75Percent, '${milestones['75']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reach90Percent, '${milestones['90']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reach100Percent, '${milestones['100']?.toStringAsFixed(1) ?? '0'}%'),
      ],
      onSeeMore: () {
        // Navegar a la pantalla de detalles de hitos
        Navigator.pushNamed(context, '/admin/course-stats/milestones');
        //_showNotImplemented();
      },
    );
  }

  Widget _buildRankingTable(List<CourseStats> courseStatsList) {
    final top5Courses = courseStatsList.take(5).toList();
    
    return _buildDashboardCard(
      title: AppLocalizations.of(context)!.courseRanking,
      icon: Icons.emoji_events_outlined,
      iconColor: Colors.teal,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _getColumnIndex(_rankingSortBy),
            sortAscending: _rankingSortAscending,
            columnSpacing: 20, // Ajustar espacio entre columnas
            columns: [
              _buildSortableHeader(AppLocalizations.of(context)!.course, 'title', isNumeric: false),
              _buildSortableHeader(AppLocalizations.of(context)!.enrolled, 'enrollmentCount', isNumeric: true),
              _buildSortableHeader(AppLocalizations.of(context)!.progressPercent, 'averageProgressPercentage', isNumeric: true),
              _buildSortableHeader(AppLocalizations.of(context)!.averageTime, 'averageCompletionTime', isNumeric: false),
            ],
            rows: top5Courses.map((stat) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(stat.course.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                    // Navegar al detalle de estadísticas del curso
                    onTap: () => Navigator.pushNamed(context, '/admin/course-stats/detail', arguments: stat.course.id),
                  ),
                  DataCell(Text(stat.enrollmentCount.toString())),
                  DataCell(Text('${stat.averageProgressPercentage.toStringAsFixed(1)}%')),
                  DataCell(Text(_formatDuration(stat.averageCompletionTime) ?? 'N/A')),
                ],
                onSelectChanged: (_) {
                  // Navigator.pushNamed(context, '/courses/detail', arguments: stat.course.id);
                },
              );
            }).toList(),
          ),
        ),
      ],
      onSeeMore: null,
    );
  }

  // --- Widgets Helpers --- 

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    VoidCallback? onSeeMore,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16), // Quitar margen horizontal
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title, 
                          style: AppTextStyles.headline3.copyWith(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSeeMore != null)
                  TextButton(
                    onPressed: onSeeMore,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.seeMore),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children,
          ],
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
          const SizedBox(width: 16), // Espacio entre etiqueta y valor
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end, // Alinear valor a la derecha
              overflow: TextOverflow.ellipsis, // Evitar overflow en valores largos
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
                    label: Text(AppLocalizations.of(context)!.clear, style: TextStyle(color: Colors.red)),
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
                  child: InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: _endDate ?? DateTime.now(),
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
                        setState(() => _startDate = pickedDate);
                        _applyDateFilter(); // Aplicar automáticamente al seleccionar fecha
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate != null ? formatter.format(_startDate!) : AppLocalizations.of(context)!.startDate,
                            style: TextStyle(
                              color: _startDate != null ? AppColors.textPrimary : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
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
                        setState(() => _endDate = pickedDate);
                        _applyDateFilter(); // Aplicar automáticamente al seleccionar fecha
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endDate != null ? formatter.format(_endDate!) : AppLocalizations.of(context)!.endDate,
                            style: TextStyle(
                              color: _endDate != null ? AppColors.textPrimary : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Eliminar el botón "Aplicar Filtro"
          ],
        ),
      ),
    );
  }

  // Helper para construir cabeceras de tabla ordenables (añadido isNumeric)
  DataColumn _buildSortableHeader(String label, String columnName, {bool isNumeric = false}) {
    return DataColumn(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      numeric: isNumeric,
      onSort: (columnIndex, ascending) => _sortRankingTable(columnName),
    );
  }

  // Actualizar _getColumnIndex para la tabla de ranking simplificada
  int _getColumnIndex(String columnName) {
    switch (columnName) {
      case 'title': return 0;
      case 'enrollmentCount': return 1;
      case 'averageProgressPercentage': return 2;
      case 'averageCompletionTime': return 3;
      default: return 0;
    }
  }

  // Helper para formatear duración (ajustado para null safety)
  String? _formatDuration(Duration? duration) {
    if (duration == null) return null;
    if (duration.inDays > 0) return '${duration.inDays} d';
    if (duration.inHours > 0) return '${duration.inHours} h';
    if (duration.inMinutes > 0) return '${duration.inMinutes} min';
    return 'Menos de 1 min';
  }

  void _showNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.detailsScreenNotImplemented),
        duration: const Duration(seconds: 1),
      ),
    );
  }
} 