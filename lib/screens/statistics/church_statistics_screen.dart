import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Para gráficos futuros
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart'; // Asumiendo que existe
import '../../services/permission_service.dart'; // <-- IMPORTAR PermissionService
import '../../l10n/app_localizations.dart';
import '../../utils/age_range.dart';
import '../../utils/age_range_localizations.dart';

class ChurchStatisticsScreen extends StatefulWidget {
  const ChurchStatisticsScreen({super.key});

  @override
  State<ChurchStatisticsScreen> createState() => _ChurchStatisticsScreenState();
}

class _ChurchStatisticsScreenState extends State<ChurchStatisticsScreen> {
  final PermissionService _permissionService = PermissionService(); // <-- INSTANCIA
  bool _hasPermission = false; // <-- NUEVO ESTADO
  bool _isCheckingPermission = true; // <-- NUEVO ESTADO

  bool _isLoading = true;
  int _totalUsers = 0;
  Map<String, int> _genderDistribution = {};
  Map<String, int> _ageDistribution = {}; // ageRange -> Conteo
  int _usersInMinistries = 0;
  int _usersInConnects = 0;
  int _usersInCourses = 0; // El valor real se calculará

  List<UserModel> _allUsers = []; // DESCOMENTADO
  Set<String> _userIdsInMinistries = {}; // Para contar usuarios únicos en ministerios
  Set<String> _userIdsInConnects = {};   // Para contar usuarios únicos en Connects
  Set<String> _userIdsInCourses = {};    // Para contar usuarios únicos en Cursos

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadData(); // <-- CAMBIAR A NUEVA FUNCIÓN
  }

  Future<void> _checkPermissionsAndLoadData() async {
    bool hasPermission = await _permissionService.hasPermission('view_church_statistics');
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
        _isCheckingPermission = false;
      });
      if (hasPermission) {
        _loadAllData();
      }
    }
  }

  Future<void> _fetchAllUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      _allUsers = usersSnapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>..['id'] = doc.id)).toList();
      debugPrint('Usuarios cargados: ${_allUsers.length}');
    } catch (e) {
      debugPrint('Error al cargar todos los usuarios: $e');
      // Considerar mostrar un error al usuario si es crítico
    }
  }

  Future<void> _fetchMinistryMemberships() async {
    _userIdsInMinistries.clear();
    try {
      final ministriesSnapshot = await FirebaseFirestore.instance.collection('ministries').get();
      for (var ministryDoc in ministriesSnapshot.docs) {
        final members = ministryDoc.data()['members'] as List<dynamic>?;
        if (members != null) {
          for (var memberRef in members) {
            if (memberRef is DocumentReference) {
              _userIdsInMinistries.add(memberRef.id);
            } else if (memberRef is String) {
              // Asumir que si es String, puede ser solo el ID o un path completo
              if (memberRef.contains('/')) {
                 _userIdsInMinistries.add(memberRef.split('/').last); 
              } else {
                _userIdsInMinistries.add(memberRef);
              }
            }
          }
        }
      }
      debugPrint('Usuarios únicos en ministerios: ${_userIdsInMinistries.length}');
    } catch (e) {
      debugPrint('Error al cargar membresías de ministerios: $e');
    }
  }

  Future<void> _fetchConnectMemberships() async {
    _userIdsInConnects.clear();
    try {
      final groupsSnapshot = await FirebaseFirestore.instance.collection('groups').get(); // Asumiendo colección 'groups'
      for (var groupDoc in groupsSnapshot.docs) {
        final members = groupDoc.data()['members'] as List<dynamic>?;
        if (members != null) {
          for (var memberRef in members) {
            if (memberRef is DocumentReference) {
              _userIdsInConnects.add(memberRef.id);
            } else if (memberRef is String) {
              if (memberRef.contains('/')) {
                 _userIdsInConnects.add(memberRef.split('/').last); 
              } else {
                _userIdsInConnects.add(memberRef);
              }
            }
          }
        }
      }
      debugPrint('Usuarios únicos en Connects: ${_userIdsInConnects.length}');
    } catch (e) {
      debugPrint('Error al cargar membresías de Connects (grupos): $e');
    }
  }

  Future<void> _fetchCourseEnrollments() async {
    _userIdsInCourses.clear();
    try {
      final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      for (var courseDoc in coursesSnapshot.docs) {
        final enrolledUsers = courseDoc.data()['enrolledUsers'] as List<dynamic>?;
        if (enrolledUsers != null) {
          for (var userIdObj in enrolledUsers) {
            if (userIdObj is String && userIdObj.isNotEmpty) {
              // Si userId es un path completo como 'users/ID', extraer solo el ID
              // Aunque has dicho que son IDs directamente, esta salvaguarda no hace daño.
              if (userIdObj.contains('/')) {
                _userIdsInCourses.add(userIdObj.split('/').last);
              } else {
                _userIdsInCourses.add(userIdObj);
              }
            }
          }
        }
      }
      debugPrint('Usuarios únicos en cursos (desde colección courses): ${_userIdsInCourses.length}');
    } catch (e) {
      debugPrint('Error al cargar inscripciones de cursos desde la colección courses: $e');
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await _fetchAllUsers(); // Cargar todos los usuarios
      await _fetchMinistryMemberships(); // Cargar datos de ministerios
      await _fetchConnectMemberships(); // Cargar datos de Connects
      await _fetchCourseEnrollments(); // Cargar datos de Cursos
      
      _calculateStatistics(); // Calcular estadísticas con los datos cargados

      // La siguiente línea asignaba un valor de ejemplo y debe ser eliminada o comentada.
      // _usersInCourses = 30; // Esta línea causaba que siempre se mostrara 30.

    } catch (e) {
      debugPrint('Error al cargar estadísticas de la iglesia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingData(e.toString())))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStatistics() {
    _totalUsers = _allUsers.length;
    _genderDistribution = {};
    _ageDistribution = {}; 
    _usersInMinistries = _userIdsInMinistries.length;
    _usersInConnects = _userIdsInConnects.length;
    _usersInCourses = _userIdsInCourses.length;
    final ageRangeCounts = <AgeRange, int>{};
    int usersWithoutAgeRange = 0;

    for (var user in _allUsers) {
      // Género
      final gender = user.gender?.isNotEmpty == true ? user.gender! : AppLocalizations.of(context)!.notInformed;
      _genderDistribution[gender] = (_genderDistribution[gender] ?? 0) + 1;

      // Edad (por rango)
      final range = AgeRange.fromFirestoreValue(user.ageRange);
      if (range == null) {
        usersWithoutAgeRange++;
      } else {
        ageRangeCounts[range] = (ageRangeCounts[range] ?? 0) + 1;
      }
    }

    final sortedRanges = AgeRange.values.toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    _ageDistribution = {
      for (final range in sortedRanges)
        if ((ageRangeCounts[range] ?? 0) > 0)
          range.firestoreValue: ageRangeCounts[range]!,
      if (usersWithoutAgeRange > 0) 'not_informed': usersWithoutAgeRange,
    };

    // Ordenar _genderDistribution: Masculino, Feminino, Não informado
    Map<String, int> sortedGenderMap = {};
    final masculine = AppLocalizations.of(context)!.masculine;
    final feminine = AppLocalizations.of(context)!.feminine;
    final notInformed = AppLocalizations.of(context)!.notInformed;
    
    if (_genderDistribution.containsKey(masculine)) {
      sortedGenderMap[masculine] = _genderDistribution[masculine]!;
    }
    if (_genderDistribution.containsKey(feminine)) {
      sortedGenderMap[feminine] = _genderDistribution[feminine]!;
    }
    if (_genderDistribution.containsKey(notInformed)) {
      sortedGenderMap[notInformed] = _genderDistribution[notInformed]!;
    }
    // Añadir cualquier otra categoría de género que pudiera existir
    _genderDistribution.forEach((key, value) {
      if (!sortedGenderMap.containsKey(key)) {
        sortedGenderMap[key] = value;
      }
    });
    _genderDistribution = sortedGenderMap;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.churchStatisticsTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      // Mostrar mensaje de acceso denegado simple
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.churchStatisticsTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.accessDenied,
                  style: AppTextStyles.headline3.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.noPermissionViewStatistics,
                  style: AppTextStyles.bodyText1.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.churchStatisticsTitle),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  _buildTotalUsersStatisticCard(),
                  const SizedBox(height: 16),
                  _buildDistributionCard(
                    title: AppLocalizations.of(context)!.genderDistribution,
                    distribution: _genderDistribution,
                    icon: Icons.wc,
                    color: Colors.pink,
                  ),
                  const SizedBox(height: 16),
                  _buildDistributionCard(
                    title: AppLocalizations.of(context)!.ageDistribution,
                    distribution: _ageDistribution,
                    icon: Icons.cake,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticCard(
                    title: AppLocalizations.of(context)!.usersInMinistries,
                    value: '${_usersInMinistries}',
                    icon: Icons.work,
                    color: Colors.green,
                    subtitle: _totalUsers > 0 ? AppLocalizations.of(context)!.ofUsers(_totalUsers.toString()) : null,
                    percentage: _totalUsers > 0 ? (_usersInMinistries / _totalUsers) * 100 : 0,
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticCard(
                    title: AppLocalizations.of(context)!.usersInConnects,
                    value: '${_usersInConnects}',
                    icon: Icons.group_work,
                    color: Colors.purple,
                    subtitle: _totalUsers > 0 ? AppLocalizations.of(context)!.ofUsers(_totalUsers.toString()) : null,
                    percentage: _totalUsers > 0 ? (_usersInConnects / _totalUsers) * 100 : 0,
                  ),
                  const SizedBox(height: 16),
                  _buildStatisticCard(
                    title: AppLocalizations.of(context)!.usersInCourses,
                    value: '${_usersInCourses}',
                    icon: Icons.school,
                    color: Colors.teal,
                    subtitle: _totalUsers > 0 ? AppLocalizations.of(context)!.ofUsers(_totalUsers.toString()) : null,
                    percentage: _totalUsers > 0 ? (_usersInCourses / _totalUsers) * 100 : 0,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalUsersStatisticCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.2),
              radius: 28,
              child: const Icon(Icons.people, color: Colors.blue, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.totalRegisteredUsers,
              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  _totalUsers.toString(),
                  style: AppTextStyles.headline1.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    double? percentage,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value, 
                        style: AppTextStyles.headline2.copyWith(color: color, fontWeight: FontWeight.bold, height: 1.1),
                      ),
                      if (percentage != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0, top: 2.0),
                          child: Text(
                            '(${percentage.toStringAsFixed(1)}%)',
                            style: AppTextStyles.caption.copyWith(color: color, fontSize: 11, height: 1.1),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard({
    required String title,
    required Map<dynamic, int> distribution,
    required IconData icon,
    required Color color,
  }) {
    final displayDistribution = Map<dynamic, int>.from(distribution);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  radius: 20,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            if (displayDistribution.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(AppLocalizations.of(context)!.dataNotAvailable, style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary)),
              )
            else
              ...displayDistribution.entries.map((entry) {
                IconData? genderIcon;
                if (title == AppLocalizations.of(context)!.genderDistribution) {
                  if (entry.key.toString() == AppLocalizations.of(context)!.masculine) genderIcon = Icons.male;
                  if (entry.key.toString() == AppLocalizations.of(context)!.feminine) genderIcon = Icons.female;
                  // Para 'Não informado' u otros, genderIcon seguirá siendo null
                }

                Widget leadingWidget = const SizedBox.shrink(); // Widget por defecto (nada)
                if (genderIcon != null) {
                  leadingWidget = Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(genderIcon, color: color.withOpacity(0.7), size: 18),
                  );
                } else if (title == AppLocalizations.of(context)!.ageDistribution) {
                  // Para Edad, queremos un espacio vacío para alinear con otros que podrían tener icono
                  leadingWidget = const SizedBox(width: 18 + 8.0); // Ancho del icono + padding
                } else if (title != AppLocalizations.of(context)!.genderDistribution) {
                  // Icono genérico para otras distribuciones (si no es Género y no es Edad)
                  leadingWidget = Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.circle, size: 10, color: color.withOpacity(0.5)),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), 
                  child: Row(
                    children: [
                      leadingWidget,
                      Expanded(
                        child: Text(
                          _getDistributionKeyLabel(title, entry.key),
                          style: AppTextStyles.bodyText1.copyWith(color: AppColors.textPrimary)
                        ),
                      ),
                      Text(
                        _getDistributionValueLabel(
                          entry.value,
                          showPercentage:
                              title == AppLocalizations.of(context)!.ageDistribution,
                        ),
                        style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                      ),
                    ],
                  ),
                );
              }).toList(),
            // Mostrar el gráfico de barras si es la distribución por rango de edad y hay datos
            if (title == AppLocalizations.of(context)!.ageDistribution &&
                distribution.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
                child: SizedBox(
                  height: 220,
                  child: _buildAgeRangeBarChart(
                    Map<String, int>.fromEntries(
                      distribution.entries
                          .where((entry) => entry.key is String)
                          .map((entry) =>
                              MapEntry(entry.key as String, entry.value)),
                    ),
                    color,
                  ),
                ),
              ),
            // Mostrar el gráfico de barras para Género
            if (title == AppLocalizations.of(context)!.genderDistribution && distribution.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 10.0),
                child: SizedBox(
                  height: 220, 
                  child: _buildGenderBarChart(distribution as Map<String, int>, color),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDistributionKeyLabel(String cardTitle, dynamic key) {
    final strings = AppLocalizations.of(context)!;
    if (cardTitle == strings.ageDistribution) {
      if (key == 'not_informed') return strings.ageNotInformed;
      final range = AgeRange.fromFirestoreValue(key.toString());
      return range?.label(strings) ?? strings.ageNotInformed;
    }
    return key.toString();
  }

  String _getDistributionValueLabel(int count, {required bool showPercentage}) {
    if (showPercentage && _totalUsers > 0) {
      double percentage = (count / _totalUsers) * 100;
      return '$count (${percentage.toStringAsFixed(1)}%)';
    }
    return count.toString();
  }

  Widget _buildAgeRangeBarChart(Map<String, int> ageRangeData, Color chartColor) {
    final strings = AppLocalizations.of(context)!;

    final ranges = AgeRange.values.toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final data = <AgeRange, int>{
      for (final range in ranges) range: ageRangeData[range.firestoreValue] ?? 0,
    };
    final nonZero = data.entries.where((e) => e.value > 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    final maxY =
        nonZero.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    final double yInterval =
        maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble().clamp(1.0, maxY).toDouble();

    final barGroups = <BarChartGroupData>[
      for (var index = 0; index < ranges.length; index++)
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data[ranges[index]]!.toDouble(),
              color: chartColor,
              width: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
    ];

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final index = group.x.toInt().clamp(0, ranges.length - 1);
              final label = ranges[index].label(strings);
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.round().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= ranges.length) return const SizedBox.shrink();
                final text = ranges[index].label(strings);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0 && maxY == 0) return const Text('');
                if (value % yInterval == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 0.5);
          },
        ),
        barGroups: barGroups,
      ),
    );
  }
  Widget _buildGenderBarChart(Map<String, int> genderData, Color chartColor) {
    // Filtrar "Não informado" solo para el gráfico
    Map<String, int> chartGenderData = Map.from(genderData);
    chartGenderData.remove(AppLocalizations.of(context)!.notInformed);

    if (chartGenderData.isEmpty) return const SizedBox.shrink();

    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    int i = 0; 

    // Usar las claves tal como vienen del mapa ordenado (_genderDistribution)
    final genderKeys = chartGenderData.keys.toList();

    for (var genderKey in genderKeys) {
      final count = chartGenderData[genderKey]!;
      if (count.toDouble() > maxY) {
        maxY = count.toDouble();
      }
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: chartColor,
              width: 35, // Barras un poco más anchas para pocas categorías
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              rodStackItems: [ // Intento de mostrar valor en la barra (puede no ser ideal)
                BarChartRodStackItem(
                    0, count.toDouble(), chartColor.withValues(alpha: 0.7)),
              ]
            ),
          ],
        ),
      );
      i++;
    }

    if (barGroups.isEmpty) return const SizedBox.shrink();

    double yInterval = 1;
    if (maxY <= 5) {
      yInterval = 1;
    } else if (maxY <= 10) {
      yInterval = 2;
    } else if (maxY <= 50) {
      yInterval = 5;
    } else {
      yInterval = (maxY / 5).ceilToDouble();
    }
    if (yInterval == 0) yInterval = 1;

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2, 
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String genderLabel = genderKeys[group.x.toInt()];
              return BarTooltipItem(
                '$genderLabel\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.round().toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < genderKeys.length) {
                  final String text = genderKeys[value.toInt()];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                  );
                }
                return const Text('');
              },
              reservedSize: 38,
              interval: 1, 
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, 
              interval: yInterval,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0 && maxY == 0) return const Text('');
                if (value % yInterval == 0) { 
                   return Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) {
                return FlLine(color: Colors.grey.shade300, strokeWidth: 0.5,);
            },
        ),
        barGroups: barGroups,
      ),
    );
  }
} 
