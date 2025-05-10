import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../services/course_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CourseEnrollmentStatsScreen extends StatefulWidget {
  const CourseEnrollmentStatsScreen({super.key});

  @override
  State<CourseEnrollmentStatsScreen> createState() => _CourseEnrollmentStatsScreenState();
}

class _CourseEnrollmentStatsScreenState extends State<CourseEnrollmentStatsScreen> {
  final CourseStatsService _statsService = CourseStatsService();
  late Future<Map<String, dynamic>> _statsFuture;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Estado para ordenar la tabla
  String _sortBy = 'enrollmentCount';
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
    final totalEnrollments = await _statsService.getTotalEnrollments();
    final courseStats = await _statsService.getAllCourseStats(
      startDate: _startDate,
      endDate: _endDate,
    );
    _allCourseStats = courseStats; // Guardar la lista completa
    _sortCourseStats(); // Ordenar inicialmente
    return {
      'totalEnrollments': totalEnrollments,
      'courseStats': _allCourseStats, // Usar la lista guardada
    };
  }
  
  void _applyDateFilter() {
    setState(() {
      _statsFuture = _loadStats(); // Recargar datos con el filtro
    });
  }
  
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _statsFuture = _loadStats(); // Recargar datos sin filtro
    });
  }

  // Comparador genérico para ordenar
  int _compareStats(CourseStats a, CourseStats b, String sortBy, bool ascending) {
    int compare;
    switch (sortBy) {
      case 'title':
        compare = a.course.title.toLowerCase().compareTo(b.course.title.toLowerCase());
        break;
      case 'enrollmentCount':
        compare = a.enrollmentCount.compareTo(b.enrollmentCount);
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
        title: const Text('Inscrições por Curso'),
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
          final int totalEnrollments = stats['totalEnrollments'] ?? 0;
          final filteredCourseStats = _allCourseStats.where((stat) {
            final query = _searchQuery.toLowerCase();
            return stat.course.title.toLowerCase().contains(query);
          }).toList();
          final int coursesWithEnrollment = filteredCourseStats.where((s) => s.enrollmentCount > 0).length;

          return Column(
            children: [
              // Resumen general y Filtros (combinados en una tarjeta)
              _buildHeaderCard(totalEnrollments, coursesWithEnrollment),
              
              // Tabla de Inscripciones
              Expanded(
                child: _buildEnrollmentTable(filteredCourseStats),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Widgets Reutilizables --- 

  Widget _buildHeaderCard(int totalEnrollments, int coursesWithEnrollment) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo Geral', style: AppTextStyles.headline3),
            const SizedBox(height: 12),
            _buildStatRow('Total de Inscrições:', '$totalEnrollments'),
            _buildStatRow('Cursos com Inscrições:', '$coursesWithEnrollment'),
            const Divider(height: 24, thickness: 0.5),
            
            // Filtros (integrados)
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
                // Botón para filtro de fecha
                IconButton(
                  icon: Icon(Icons.calendar_today, 
                         color: (_startDate != null || _endDate != null) ? AppColors.primary : Colors.grey[600]),
                  tooltip: 'Filtrar por Data',
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
  
  Widget _buildEnrollmentTable(List<CourseStats> filteredCourseStats) {
    if (filteredCourseStats.isEmpty) {
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
      child: DataTable(
        sortColumnIndex: _getColumnIndex(_sortBy),
        sortAscending: _sortAscending,
        headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.05)),
        headingTextStyle: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.w600),
        dataRowMinHeight: 50,
        dataRowMaxHeight: 60,
        columnSpacing: 24,
        columns: [
          _buildSortableHeader('Curso', 'title'),
          _buildSortableHeader('Inscritos', 'enrollmentCount', isNumeric: true),
        ],
        rows: filteredCourseStats.map((stat) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  stat.course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pushNamed(context, '/admin/course-stats/detail', arguments: stat.course.id),
              ),
              DataCell(Text(stat.enrollmentCount.toString())),
            ],
          );
        }).toList(),
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
          const SizedBox(width: 16), // Espacio entre etiqueta y valor
          Text(value, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w600)),
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
        // Aplicar tema si es necesario
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary, // Color primario
              onPrimary: Colors.white, // Texto sobre primario
            ),
            // Puedes personalizar más elementos aquí
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        // Añadir un día al final para incluir el día completo
        _endDate = picked.end.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      });
      _applyDateFilter();
    }
  }

  DataColumn _buildSortableHeader(String label, String columnName, {bool isNumeric = false}) {
    return DataColumn(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      numeric: isNumeric,
      onSort: (columnIndex, ascending) => _sortTable(columnName),
    );
  }

  int _getColumnIndex(String columnName) {
    switch (columnName) {
      case 'title': return 0;
      case 'enrollmentCount': return 1;
      default: return 0;
    }
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
                        _applyDateFilter(); // Aplicar automáticamente
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
                            _startDate != null ? formatter.format(_startDate!) : 'Data inicial',
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
                        _applyDateFilter(); // Aplicar automáticamente
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
                            _endDate != null ? formatter.format(_endDate!) : 'Data final',
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
            // No hay botón "Aplicar" - se aplica al seleccionar fecha
          ],
        ),
      ),
    );
  }
} 