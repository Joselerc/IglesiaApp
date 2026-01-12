import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_group.dart';
import '../../services/family_group_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/age_range.dart';
import '../../utils/age_range_localizations.dart';
import '../families/widgets/family_card.dart';
import 'family_admin_detail_screen.dart';
import 'package:intl/intl.dart';

class FamiliesAdminScreen extends StatefulWidget {
  const FamiliesAdminScreen({super.key});

  @override
  State<FamiliesAdminScreen> createState() => _FamiliesAdminScreenState();
}

class _FamiliesAdminScreenState extends State<FamiliesAdminScreen> {
  final FamilyGroupService _familyService = FamilyGroupService();
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';
  _FamiliesAdminListFilter _listFilter = _FamiliesAdminListFilter.all;

  final Map<String, Future<AgeRange?>> _userAgeRangeCache = {};
  final Map<String, Future<_FamilyStructure>> _familyStructureCache = {};
  final Map<String, int> _familyStructureSignature = {};

  static const _childRoles = {'hijo', 'hija'};
  static const _parentRoles = {'padre', 'madre', 'tutor'};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<AgeRange?> _getUserAgeRange(String userId) {
    return _userAgeRangeCache.putIfAbsent(userId, () async {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final value = doc.data()?['ageRange'] as String?;
      return AgeRange.fromFirestoreValue(value);
    });
  }

  int _computeStructureSignature(FamilyGroup family) {
    return Object.hash(
      family.updatedAt.millisecondsSinceEpoch,
      family.memberIds.length,
      Object.hashAll(family.memberIds),
    );
  }

  Future<_FamilyStructure> _getFamilyStructure(FamilyGroup family) {
    final signature = _computeStructureSignature(family);
    final previousSignature = _familyStructureSignature[family.id];
    if (previousSignature != signature) {
      _familyStructureSignature[family.id] = signature;
      _familyStructureCache[family.id] = _computeStructure(family.memberIds);
    }
    return _familyStructureCache[family.id] ??= _computeStructure(family.memberIds);
  }

  Future<_FamilyStructure> _computeStructure(List<String> memberIds) async {
    final results = await Future.wait(memberIds.map(_getUserAgeRange));
    var adults = 0;
    var youth = 0;
    var unknown = 0;
    for (final range in results) {
      if (range == null) {
        unknown += 1;
      } else if (range.isAdult) {
        adults += 1;
      } else {
        youth += 1;
      }
    }
    return _FamilyStructure(adults: adults, youth: youth, unknown: unknown);
  }

  Future<_FamiliesAdminStats> _computeStats(List<FamilyGroup> families) async {
    final structures = await Future.wait(
      families.map(_getFamilyStructure),
    );

    final createdByDay = <DateTime, int>{};
    var familiesWithChildren = 0;
    var familiesSingleMember = 0;
    var familiesNoAdults = 0;
    var totalMembers = 0;

    final parentIds = <String>{};
    for (var i = 0; i < families.length; i++) {
      final family = families[i];
      totalMembers += family.memberIds.length;

      if (family.memberIds.length == 1) familiesSingleMember += 1;
      if (structures[i].adults == 0) familiesNoAdults += 1;

      final hasChildRole = family.memberRoles.values.any(_childRoles.contains);
      final hasYouth = structures[i].youth > 0;
      if (hasChildRole || hasYouth) {
        familiesWithChildren += 1;
      }

      final createdAt = family.createdAt;
      final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      createdByDay[createdDay] = (createdByDay[createdDay] ?? 0) + 1;

      family.memberRoles.forEach((userId, role) {
        if (_parentRoles.contains(role)) parentIds.add(userId);
      });
    }

    final parentAges = await Future.wait(parentIds.map(_getUserAgeRange));
    final parentsByAgeRange = <AgeRange, int>{};
    for (final range in parentAges) {
      if (range == null) continue;
      parentsByAgeRange[range] = (parentsByAgeRange[range] ?? 0) + 1;
    }

    return _FamiliesAdminStats(
      totalFamilies: families.length,
      totalMembers: totalMembers,
      familiesWithChildren: familiesWithChildren,
      familiesSingleMember: familiesSingleMember,
      familiesNoAdults: familiesNoAdults,
      createdByDay: createdByDay,
      parentsByAgeRange: parentsByAgeRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(strings.familiesTitle),
          bottom: TabBar(
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onPrimary,
            tabs: [
              Tab(text: strings.adminFamiliesTabList),
              Tab(text: strings.adminFamiliesTabStats),
            ],
          ),
        ),
        backgroundColor: AppColors.background,
        body: StreamBuilder<List<FamilyGroup>>(
          stream: _familyService.streamAllFamilies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(strings.somethingWentWrong));
            }

            final List<FamilyGroup> allFamilies =
                List<FamilyGroup>.from(snapshot.data ?? const <FamilyGroup>[])
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final List<FamilyGroup> searchFilteredFamilies = _searchTerm.isEmpty
                ? allFamilies
                : allFamilies
                    .where((family) =>
                        family.name.toLowerCase().contains(_searchTerm))
                    .toList();

            List<FamilyGroup> visibleFamilies = searchFilteredFamilies;
            switch (_listFilter) {
              case _FamiliesAdminListFilter.all:
                break;
              case _FamiliesAdminListFilter.recent7d:
                visibleFamilies = visibleFamilies
                    .where((family) =>
                        DateTime.now().difference(family.createdAt).inDays <= 7)
                    .toList();
                break;
              case _FamiliesAdminListFilter.singleMember:
                visibleFamilies = visibleFamilies
                    .where((family) => family.memberIds.length == 1)
                    .toList();
                break;
              case _FamiliesAdminListFilter.withChildren:
                visibleFamilies = visibleFamilies
                    .where((family) =>
                        family.memberRoles.values.any(_childRoles.contains))
                    .toList();
                break;
            }

            return TabBarView(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: strings.searchFamilies,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: strings.adminFamiliesFilterAll,
                              selected:
                                  _listFilter == _FamiliesAdminListFilter.all,
                              onTap: () => setState(() {
                                _listFilter = _FamiliesAdminListFilter.all;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: strings.adminFamiliesFilterRecent,
                              selected: _listFilter ==
                                  _FamiliesAdminListFilter.recent7d,
                              onTap: () => setState(() {
                                _listFilter = _FamiliesAdminListFilter.recent7d;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: strings.adminFamiliesFilterSingleMember,
                              selected: _listFilter ==
                                  _FamiliesAdminListFilter.singleMember,
                              onTap: () => setState(() {
                                _listFilter =
                                    _FamiliesAdminListFilter.singleMember;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: strings.adminFamiliesFilterWithChildren,
                              selected: _listFilter ==
                                  _FamiliesAdminListFilter.withChildren,
                              onTap: () => setState(() {
                                _listFilter =
                                    _FamiliesAdminListFilter.withChildren;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: visibleFamilies.isEmpty
                          ? Center(
                              child: Text(
                                strings.noFamiliesFound,
                                style: AppTextStyles.subtitle2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : FutureBuilder<List<_FamilyStructure>>(
                              future: Future.wait(
                                visibleFamilies.map(_getFamilyStructure),
                              ),
                              builder: (context, structureSnapshot) {
                                if (structureSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final structures = structureSnapshot.data;
                                if (structures == null) {
                                  return Center(
                                    child: Text(strings.somethingWentWrong),
                                  );
                                }

                                final indices = <int>[];
                                for (var i = 0; i < visibleFamilies.length; i++) {
                                  indices.add(i);
                                }

                                if (indices.isEmpty) {
                                  return Center(
                                    child: Text(
                                      strings.noFamiliesFound,
                                      style: AppTextStyles.subtitle2.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  itemCount: indices.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, rowIndex) {
                                    final index = indices[rowIndex];
                                    final family = visibleFamilies[index];
                                    final structure = structures[index];

                                    final createdText = strings.created(
                                      localizations
                                          .formatShortDate(family.createdAt),
                                    );

                                    final baseSubtitle = [
                                      strings.familyMembersCount(
                                        family.memberIds.length,
                                      ),
                                      createdText,
                                    ].join(' · ');

                                    final structureText = [
                                      strings.familyStructureSummary(
                                        structure.adults,
                                        structure.youth,
                                      ),
                                      if (structure.unknown > 0)
                                        strings.familyStructureUnknown(
                                          structure.unknown,
                                        ),
                                    ].join(' • ');

                                    final subtitle =
                                        '$baseSubtitle\n$structureText';

                                    final badge = () {
                                      if (structure.adults == 0) {
                                        return strings.familyBadgeNoAdults;
                                      }
                                      if (family.memberIds.length == 1) {
                                        return strings.familyBadgeSingleMember;
                                      }
                                      if (structure.unknown > 0) {
                                        return strings.familyBadgeIncomplete;
                                      }
                                      return null;
                                    }();

                                    final badgeColor = () {
                                      if (structure.adults == 0) {
                                        return colorScheme.error;
                                      }
                                      if (family.memberIds.length == 1) {
                                        return colorScheme.primary
                                            .withValues(alpha: 0.85);
                                      }
                                      if (structure.unknown > 0) {
                                        return colorScheme.tertiary
                                            .withValues(alpha: 0.85);
                                      }
                                      return null;
                                    }();

                                    return FamilyCard(
                                      title: family.name.isNotEmpty
                                          ? family.name
                                          : strings.familyFallbackName,
                                      subtitle: subtitle,
                                      photoUrl: family.photoUrl,
                                      badge: badge,
                                      badgeColor: badgeColor,
                                      titleMaxLines: 2,
                                      subtitleMaxLines: 3,
                                      surfaceTint:
                                          colorScheme.surfaceContainerLow,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FamilyAdminDetailScreen(
                                            familyId: family.id,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
                _FamiliesAdminStatsTab(
                  families: allFamilies,
                  computeStats: _computeStats,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _FamiliesAdminListFilter {
  all,
  recent7d,
  singleMember,
  withChildren,
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.bodyText2.copyWith(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? Colors.transparent : colorScheme.outlineVariant,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}

class _FamilyStructure {
  const _FamilyStructure({
    required this.adults,
    required this.youth,
    required this.unknown,
  });

  final int adults;
  final int youth;
  final int unknown;
}

class _FamiliesAdminStats {
  const _FamiliesAdminStats({
    required this.totalFamilies,
    required this.totalMembers,
    required this.familiesWithChildren,
    required this.familiesSingleMember,
    required this.familiesNoAdults,
    required this.createdByDay,
    required this.parentsByAgeRange,
  });

  final int totalFamilies;
  final int totalMembers;
  final int familiesWithChildren;
  final int familiesSingleMember;
  final int familiesNoAdults;
  final Map<DateTime, int> createdByDay;
  final Map<AgeRange, int> parentsByAgeRange;
}

class _FamiliesAdminStatsTab extends StatefulWidget {
  const _FamiliesAdminStatsTab({
    required this.families,
    required this.computeStats,
  });

  final List<FamilyGroup> families;
  final Future<_FamiliesAdminStats> Function(List<FamilyGroup>) computeStats;

  @override
  State<_FamiliesAdminStatsTab> createState() => _FamiliesAdminStatsTabState();
}

class _FamiliesAdminStatsTabState extends State<_FamiliesAdminStatsTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateFilterActive = false;

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isDateFilterActive = false;
    });
  }

  List<FamilyGroup> _applyDateFilter(List<FamilyGroup> families) {
    if (!_isDateFilterActive) return families;

    final now = DateTime.now();
    final defaultEnd = DateTime(now.year, now.month, now.day);
    final defaultStart = defaultEnd.subtract(const Duration(days: 13));
    var start = _startDate ?? defaultStart;
    var end = _endDate ?? defaultEnd;

    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    if (normalizedEnd.isBefore(normalizedStart)) {
      final temp = start;
      start = end;
      end = temp;
    }

    final effectiveStart =
        DateTime(start.year, start.month, start.day);
    final effectiveEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    );

    return families
        .where((family) =>
            !family.createdAt.isBefore(effectiveStart) &&
            !family.createdAt.isAfter(effectiveEnd))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    final filteredFamilies = _applyDateFilter(widget.families);

    return FutureBuilder<_FamiliesAdminStats>(
      future: widget.computeStats(filteredFamilies),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data;
        if (stats == null) {
          return Center(child: Text(strings.somethingWentWrong));
        }

        final totalFamilies = stats.totalFamilies;
        final familiesWithoutChildren =
            totalFamilies - stats.familiesWithChildren;

        String countWithPercent(int value) {
          if (totalFamilies <= 0) return '$value (0%)';
          final percent = ((value / totalFamilies) * 100).round();
          return '$value ($percent%)';
        }

        const lastDays = 14;
        final now = DateTime.now();
        final defaultEnd = DateTime(now.year, now.month, now.day);
        final defaultStart =
            defaultEnd.subtract(const Duration(days: lastDays - 1));
        var chartStart = defaultStart;
        var chartEnd = defaultEnd;
        if (_isDateFilterActive &&
            (_startDate != null || _endDate != null)) {
          chartStart = _startDate ?? defaultStart;
          chartEnd = _endDate ?? defaultEnd;
          if (chartEnd.isBefore(chartStart)) {
            final temp = chartStart;
            chartStart = chartEnd;
            chartEnd = temp;
          }
        }

        chartStart = DateTime(
          chartStart.year,
          chartStart.month,
          chartStart.day,
        );
        chartEnd = DateTime(
          chartEnd.year,
          chartEnd.month,
          chartEnd.day,
        );

        final totalDays = chartEnd.difference(chartStart).inDays + 1;
        final series = List.generate(totalDays, (i) {
          final day = chartStart.add(Duration(days: i));
          return stats.createdByDay[day] ?? 0;
        });
        final maxCount = series.fold<int>(0, (m, v) => v > m ? v : m);

        final sortedParentRanges = AgeRange.values.toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

        final dateRangeLabel = _isDateFilterActive &&
                (_startDate != null || _endDate != null)
            ? '${DateFormat('dd/MM/yyyy', locale.toString()).format(chartStart)} - '
                '${DateFormat('dd/MM/yyyy', locale.toString()).format(chartEnd)}'
            : null;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.filterByDate,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                          if (_isDateFilterActive)
                            TextButton.icon(
                              onPressed: _clearDateFilter,
                              icon: const Icon(Icons.clear, size: 16),
                              label: Text(strings.clearFilter),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  locale: locale,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors.primary,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (selectedDate != null) {
                                  setState(() {
                                    _startDate = selectedDate;
                                    _isDateFilterActive = true;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startDate != null
                                          ? DateFormat('dd/MM/yyyy',
                                                  locale.toString())
                                              .format(_startDate!)
                                          : strings.initialDate,
                                      style: TextStyle(
                                        color: _startDate != null
                                            ? Colors.black87
                                            : Colors.grey[600],
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
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  locale: locale,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors.primary,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (selectedDate != null) {
                                  setState(() {
                                    _endDate = selectedDate;
                                    _isDateFilterActive = true;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _endDate != null
                                          ? DateFormat('dd/MM/yyyy',
                                                  locale.toString())
                                              .format(_endDate!)
                                          : strings.finalDate,
                                      style: TextStyle(
                                        color: _endDate != null
                                            ? Colors.black87
                                            : Colors.grey[600],
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
                    ],
                  ),
                ),
              ),
            ),
            _StatsCard(
              title: strings.adminFamiliesStatsOverview,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(
                    label: strings.adminFamiliesStatsTotalFamilies,
                    value: stats.totalFamilies.toString(),
                  ),
                  const SizedBox(height: 6),
                  _StatRow(
                    label: strings.adminFamiliesStatsTotalMembers,
                    value: stats.totalMembers.toString(),
                  ),
                  const SizedBox(height: 6),
                  _StatRow(
                    label: strings.adminFamiliesStatsFamiliesWithChildren,
                    value: countWithPercent(stats.familiesWithChildren),
                  ),
                  const SizedBox(height: 6),
                  _StatRow(
                    label: strings.adminFamiliesStatsFamiliesWithoutChildren,
                    value: countWithPercent(familiesWithoutChildren),
                  ),
                  const SizedBox(height: 6),
                  _StatRow(
                    label: strings.adminFamiliesStatsFamiliesNoAdults,
                    value: countWithPercent(stats.familiesNoAdults),
                    valueColor: stats.familiesNoAdults > 0
                        ? colorScheme.error
                        : null,
                  ),
                  const SizedBox(height: 6),
                  _StatRow(
                    label: strings.adminFamiliesStatsFamiliesSingleMember,
                    value: countWithPercent(stats.familiesSingleMember),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatsCard(
              title: strings.adminFamiliesStatsDistribution,
              child: Column(
                children: [
                  _ProgressRow(
                    label: strings.adminFamiliesStatsFamiliesWithChildren,
                    value: stats.familiesWithChildren,
                    total: totalFamilies,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _ProgressRow(
                    label: strings.adminFamiliesStatsFamiliesWithoutChildren,
                    value: familiesWithoutChildren,
                    total: totalFamilies,
                    color: colorScheme.primary.withValues(alpha: 0.65),
                  ),
                  const SizedBox(height: 12),
                  _ProgressRow(
                    label: strings.adminFamiliesStatsFamiliesNoAdults,
                    value: stats.familiesNoAdults,
                    total: totalFamilies,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  _ProgressRow(
                    label: strings.adminFamiliesStatsFamiliesSingleMember,
                    value: stats.familiesSingleMember,
                    total: totalFamilies,
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _StatsCard(
              title: strings.adminFamiliesStatsFamiliesOverTime,
              subtitle: dateRangeLabel ??
                  strings.adminFamiliesStatsLastDays(lastDays),
              child: SizedBox(
                height: 84,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < series.length; i++)
                      Expanded(
                        child: Tooltip(
                          message: '${series[i]}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  series[i].toString(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: maxCount == 0
                                      ? 2
                                      : (series[i] / maxCount) * 56,
                                  decoration: BoxDecoration(
                                    color:
                                        colorScheme.primary.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StatsCard(
              title: strings.adminFamiliesStatsParentsByAgeRange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final range in sortedParentRanges)
                    if ((stats.parentsByAgeRange[range] ?? 0) > 0) ...[
                      _StatRow(
                        label: range.label(strings),
                        value: stats.parentsByAgeRange[range]!.toString(),
                      ),
                      const SizedBox(height: 6),
                    ],
                  if (stats.parentsByAgeRange.isEmpty)
                    Text(
                      strings.adminFamiliesStatsNoData,
                      style: AppTextStyles.bodyText2.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTextStyles.bodyText2.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyText2.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTextStyles.subtitle2.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = total <= 0 ? 0 : ((value / total) * 100).round();
    final progress = total <= 0 ? 0.0 : value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyText2.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$value ($percent%)',
              style: AppTextStyles.subtitle2.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
