import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/course_stats_service.dart';
import '../../models/course.dart'; // Importar Course
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CourseDetailStatsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailStatsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailStatsScreen> createState() => _CourseDetailStatsScreenState();
}

class _CourseDetailStatsScreenState extends State<CourseDetailStatsScreen> {
  final CourseStatsService _statsService = CourseStatsService();
  late Future<DetailedCourseStats?> _statsFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadDetailedStats();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<DetailedCourseStats?> _loadDetailedStats() {
    return _statsService.getDetailedCourseStats(
      widget.courseId,
      startDate: _startDate,
      endDate: _endDate,
    );
  }
  
  void _applyDateFilter() {
    setState(() {
      _statsFuture = _loadDetailedStats();
    });
  }
  
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _statsFuture = _loadDetailedStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.detailedStatistics),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DetailedCourseStats?>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar estatísticas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nenhuma estatística disponível para este curso.'));
          }
          
          final stats = snapshot.data!;
          final course = stats.course;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildCourseHeader(course),
              const SizedBox(height: 16),
              _buildDateFilterSection(),
              const SizedBox(height: 24),
              
              // Secciones de estadísticas
              _buildEnrollmentSection(stats),
              const SizedBox(height: 16),
              _buildProgressSection(stats),
              const SizedBox(height: 16),
              _buildCompletionSection(stats),
              const SizedBox(height: 16),
              _buildMilestonesSection(stats),
              // TODO: Añadir gráficos si se desea
            ],
          );
        },
      ),
    );
  }

  // --- Widgets de Sección --- 

  Widget _buildCourseHeader(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(course.title, style: AppTextStyles.headline2),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${AppLocalizations.of(context)!.publishedOn} ${DateFormat('dd/MM/yyyy').format(course.publishedAt ?? course.createdAt)}', style: AppTextStyles.caption),
            const SizedBox(width: 16),
            const Icon(Icons.menu_book, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${course.totalLessons} ${AppLocalizations.of(context)!.lessonsLabel}', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildEnrollmentSection(DetailedCourseStats stats) {
    return _buildStatsCard(
      title: AppLocalizations.of(context)!.enrollments,
      icon: Icons.group_add_outlined,
      iconColor: Colors.blue,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.totalEnrolledPeriod, '${stats.enrollmentCount}'),
        // Aquí iría el gráfico de evolución si se implementa
      ],
    );
  }

  Widget _buildProgressSection(DetailedCourseStats stats) {
    return _buildStatsCard(
      title: AppLocalizations.of(context)!.progress,
      icon: Icons.show_chart_outlined,
      iconColor: Colors.green,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.averageProgress, '${stats.averageProgressPercentage.toStringAsFixed(1)}%'),
        _buildStatRow(AppLocalizations.of(context)!.averageLessonsCompleted, stats.averageCompletedLessons.toStringAsFixed(1)),
        // Aquí iría el gráfico de distribución
      ],
    );
  }

  Widget _buildCompletionSection(DetailedCourseStats stats) {
    return _buildStatsCard(
      title: AppLocalizations.of(context)!.completion,
      icon: Icons.hourglass_bottom_outlined,
      iconColor: Colors.orange,
      children: [
        _buildStatRow('Tempo Médio de Conclusão:', _formatDuration(stats.averageCompletionTime) ?? 'N/A'),
        _buildStatRow('Taxa de Conclusão:', '${stats.completionRate.toStringAsFixed(1)}%'),
        _buildStatRow('Total que Concluíram:', '${stats.completedUsersCount}'),
        if (stats.fastestCompletionTime != null)
          _buildStatRow('Tempo Mais Rápido:', _formatDuration(stats.fastestCompletionTime)!),
        if (stats.slowestCompletionTime != null)
          _buildStatRow('Tempo Mais Lento:', _formatDuration(stats.slowestCompletionTime)!),
      ],
    );
  }
  
  Widget _buildMilestonesSection(DetailedCourseStats stats) {
    return _buildStatsCard(
      title: AppLocalizations.of(context)!.completionMilestones,
      icon: Icons.flag_outlined,
      iconColor: Colors.purple,
      children: [
        _buildStatRow(AppLocalizations.of(context)!.reached25Percent, '${stats.completionMilestones['25']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reached50Percent, '${stats.completionMilestones['50']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reached75Percent, '${stats.completionMilestones['75']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.reached90Percent, '${stats.completionMilestones['90']?.toStringAsFixed(1) ?? '0'}%'),
        _buildStatRow(AppLocalizations.of(context)!.completed100Percent, '${stats.completionMilestones['100']?.toStringAsFixed(1) ?? '0'}%'),
        // Aquí iría el gráfico de hitos
      ],
    );
  }

  // --- Widgets Helpers --- 

  Widget _buildStatsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.headline3.copyWith(fontSize: 18)),
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

  // Widget para el filtro de fecha (reutilizado)
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
                Text(AppLocalizations.of(context)!.filterByEnrollmentDate, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
                if (_startDate != null || _endDate != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(AppLocalizations.of(context)!.clear),
                    onPressed: _clearDateFilter,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
                    onDatePicked: (pickedDate) => setState(() => _startDate = pickedDate),
                    firstDate: DateTime(2020),
                    lastDate: _endDate ?? DateTime.now(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePickerField(
                    label: AppLocalizations.of(context)!.endDate,
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
                label: Text(AppLocalizations.of(context)!.applyFilter),
                onPressed: (_startDate != null || _endDate != null) ? _applyDateFilter : null,
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
  
  String? _formatDuration(Duration? duration) {
    if (duration == null) return null;
    if (duration.inDays > 0) return '${duration.inDays} d';
    if (duration.inHours > 0) return '${duration.inHours} h';
    if (duration.inMinutes > 0) return '${duration.inMinutes} min';
    return AppLocalizations.of(context)!.lessThan1Min;
  }
} 