import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para almacenar las estadísticas demográficas de los usuarios
class DemographicStats {
  // Distribución por edad
  final Map<String, int> ageDistribution;
  final double averageAge;
  final int minAge;
  final int maxAge;
  
  // Distribución por género
  final Map<String, int> genderDistribution;
  final List<double> genderPercentages;
  
  // Distribución por estado civil
  final Map<String, int> maritalStatusDistribution;
  final List<double> maritalStatusPercentages;
  
  // Distribución geográfica
  final Map<String, int> cityDistribution;
  final Map<String, int> stateDistribution;
  final Map<String, int> neighborhoodDistribution;
  
  // Otras estadísticas demográficas
  final Map<String, Map<String, int>> customFieldsDistribution;
  
  DemographicStats({
    required this.ageDistribution,
    required this.averageAge,
    required this.minAge,
    required this.maxAge,
    required this.genderDistribution,
    required this.genderPercentages,
    required this.maritalStatusDistribution,
    required this.maritalStatusPercentages,
    required this.cityDistribution,
    required this.stateDistribution,
    required this.neighborhoodDistribution,
    required this.customFieldsDistribution,
  });
  
  factory DemographicStats.fromMap(Map<String, dynamic> map) {
    return DemographicStats(
      ageDistribution: Map<String, int>.from(map['ageDistribution'] ?? {}),
      averageAge: map['averageAge']?.toDouble() ?? 0.0,
      minAge: map['minAge'] ?? 0,
      maxAge: map['maxAge'] ?? 0,
      genderDistribution: Map<String, int>.from(map['genderDistribution'] ?? {}),
      genderPercentages: List<double>.from(map['genderPercentages'] ?? []),
      maritalStatusDistribution: Map<String, int>.from(map['maritalStatusDistribution'] ?? {}),
      maritalStatusPercentages: List<double>.from(map['maritalStatusPercentages'] ?? []),
      cityDistribution: Map<String, int>.from(map['cityDistribution'] ?? {}),
      stateDistribution: Map<String, int>.from(map['stateDistribution'] ?? {}),
      neighborhoodDistribution: Map<String, int>.from(map['neighborhoodDistribution'] ?? {}),
      customFieldsDistribution: (map['customFieldsDistribution'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, Map<String, int>.from(value ?? {})),
      ) ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'ageDistribution': ageDistribution,
      'averageAge': averageAge,
      'minAge': minAge,
      'maxAge': maxAge,
      'genderDistribution': genderDistribution,
      'genderPercentages': genderPercentages,
      'maritalStatusDistribution': maritalStatusDistribution,
      'maritalStatusPercentages': maritalStatusPercentages,
      'cityDistribution': cityDistribution,
      'stateDistribution': stateDistribution,
      'neighborhoodDistribution': neighborhoodDistribution,
      'customFieldsDistribution': customFieldsDistribution,
    };
  }
  
  // Método para obtener las categorías de edad ordenadas
  List<String> getAgeRangesOrdered() {
    final List<String> ranges = ageDistribution.keys.toList();
    
    // Ordenar los rangos de edad
    ranges.sort((a, b) {
      // Extraer los números del formato "x-y"
      final aStart = int.parse(a.split('-').first);
      final bStart = int.parse(b.split('-').first);
      return aStart.compareTo(bStart);
    });
    
    return ranges;
  }
  
  // Método para obtener el top de ciudades por número de miembros (máximo n)
  List<MapEntry<String, int>> getTopCities(int n) {
    final List<MapEntry<String, int>> entries = cityDistribution.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).toList();
  }
  
  // Método para obtener la distribución para un campo personalizado específico
  Map<String, int> getCustomFieldDistribution(String fieldName) {
    return customFieldsDistribution[fieldName] ?? {};
  }
}

/// Modelo para encapsular un resumen de estadísticas demográficas
class DemographicStatsSummary {
  final DemographicStats? demographicStats;
  final int totalMembers;
  final int newMembersLastMonth;
  final double averageAge;
  final int medianAge;
  final Map<String, int> ageDistribution;
  final Map<String, int> ageGroupDistribution;
  final Map<String, double> ageGroupPercentages;
  final Map<String, int> genderDistribution;
  final Map<String, double> genderPercentages;
  final Map<String, int> regionDistribution;
  final Map<String, double> regionPercentages;
  final Map<String, int> maritalStatusDistribution;
  final Map<String, double> maritalStatusPercentages;
  final Map<String, int> occupationDistribution;
  final Map<String, int> membershipTimeDistribution;
  final Map<String, double> membershipTimePercentages;
  final List<Map<String, dynamic>> memberGrowthTrend;
  final Map<String, Map<String, int>> genderByAgeGroup;
  final Map<String, Map<String, int>> maritalStatusByAgeGroup;
  final Map<String, Map<String, int>> genderByRegion;
  
  DemographicStatsSummary({
    this.demographicStats,
    required this.totalMembers,
    required this.newMembersLastMonth,
    required this.averageAge,
    required this.medianAge,
    required this.ageDistribution,
    required this.ageGroupDistribution,
    required this.ageGroupPercentages,
    required this.genderDistribution,
    required this.genderPercentages,
    required this.regionDistribution,
    required this.regionPercentages,
    required this.maritalStatusDistribution,
    required this.maritalStatusPercentages,
    required this.occupationDistribution,
    required this.membershipTimeDistribution,
    required this.membershipTimePercentages,
    required this.memberGrowthTrend,
    required this.genderByAgeGroup,
    required this.maritalStatusByAgeGroup,
    required this.genderByRegion,
  });
  
  factory DemographicStatsSummary.fromMap(Map<String, dynamic> map) {
    return DemographicStatsSummary(
      demographicStats: map['demographicStats'] != null 
          ? DemographicStats.fromMap(map['demographicStats'] as Map<String, dynamic>) 
          : null,
      totalMembers: map['totalMembers'] ?? 0,
      newMembersLastMonth: map['newMembersLastMonth'] ?? 0,
      averageAge: map['averageAge']?.toDouble() ?? 0.0,
      medianAge: map['medianAge'] ?? 0,
      ageDistribution: Map<String, int>.from(map['ageDistribution'] ?? {}),
      ageGroupDistribution: Map<String, int>.from(map['ageGroupDistribution'] ?? {}),
      ageGroupPercentages: Map<String, double>.from(map['ageGroupPercentages'] ?? {}),
      genderDistribution: Map<String, int>.from(map['genderDistribution'] ?? {}),
      genderPercentages: Map<String, double>.from(map['genderPercentages'] ?? {}),
      regionDistribution: Map<String, int>.from(map['regionDistribution'] ?? {}),
      regionPercentages: Map<String, double>.from(map['regionPercentages'] ?? {}),
      maritalStatusDistribution: Map<String, int>.from(map['maritalStatusDistribution'] ?? {}),
      maritalStatusPercentages: Map<String, double>.from(map['maritalStatusPercentages'] ?? {}),
      occupationDistribution: Map<String, int>.from(map['occupationDistribution'] ?? {}),
      membershipTimeDistribution: Map<String, int>.from(map['membershipTimeDistribution'] ?? {}),
      membershipTimePercentages: Map<String, double>.from(map['membershipTimePercentages'] ?? {}),
      memberGrowthTrend: List<Map<String, dynamic>>.from(map['memberGrowthTrend'] ?? []),
      genderByAgeGroup: (map['genderByAgeGroup'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value ?? {})),
        ) ?? {},
      maritalStatusByAgeGroup: (map['maritalStatusByAgeGroup'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value ?? {})),
        ) ?? {},
      genderByRegion: (map['genderByRegion'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, Map<String, int>.from(value ?? {})),
        ) ?? {},
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'demographicStats': demographicStats?.toMap(),
      'totalMembers': totalMembers,
      'newMembersLastMonth': newMembersLastMonth,
      'averageAge': averageAge,
      'medianAge': medianAge,
      'ageDistribution': ageDistribution,
      'ageGroupDistribution': ageGroupDistribution,
      'ageGroupPercentages': ageGroupPercentages,
      'genderDistribution': genderDistribution,
      'genderPercentages': genderPercentages,
      'regionDistribution': regionDistribution,
      'regionPercentages': regionPercentages,
      'maritalStatusDistribution': maritalStatusDistribution,
      'maritalStatusPercentages': maritalStatusPercentages,
      'occupationDistribution': occupationDistribution,
      'membershipTimeDistribution': membershipTimeDistribution,
      'membershipTimePercentages': membershipTimePercentages,
      'memberGrowthTrend': memberGrowthTrend,
      'genderByAgeGroup': genderByAgeGroup,
      'maritalStatusByAgeGroup': maritalStatusByAgeGroup,
      'genderByRegion': genderByRegion,
    };
  }
} 