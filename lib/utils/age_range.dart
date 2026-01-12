enum AgeRange {
  from0To5('0_5', sortIndex: 0, minAge: 0, maxAge: 5),
  from6To12('6_12', sortIndex: 1, minAge: 6, maxAge: 12),
  from13To17('13_17', sortIndex: 2, minAge: 13, maxAge: 17),
  from18To24('18_24', sortIndex: 3, minAge: 18, maxAge: 24),
  from25To30('25_30', sortIndex: 4, minAge: 25, maxAge: 30),
  from31To35('31_35', sortIndex: 5, minAge: 31, maxAge: 35),
  from36To40('36_40', sortIndex: 6, minAge: 36, maxAge: 40),
  from41To50('41_50', sortIndex: 7, minAge: 41, maxAge: 50),
  from51To60('51_60', sortIndex: 8, minAge: 51, maxAge: 60),
  from61Plus('61_plus', sortIndex: 9, minAge: 61, maxAge: null);

  const AgeRange(
    this.firestoreValue, {
    required this.sortIndex,
    required this.minAge,
    required this.maxAge,
  });

  final String firestoreValue;
  final int sortIndex;
  final int minAge;
  final int? maxAge;

  bool get isUnder13 => maxAge != null && maxAge! < 13;
  bool get isUnder18 => maxAge != null && maxAge! < 18;
  bool get isAdult => minAge >= 18;

  static AgeRange? fromFirestoreValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case '0_5':
      case '0-5':
      case '0–5':
        return AgeRange.from0To5;
      case '6_12':
      case '6-12':
      case '6–12':
        return AgeRange.from6To12;
      case '13_17':
      case '13-17':
      case '13–17':
        return AgeRange.from13To17;
      case '18_24':
      case '18-24':
      case '18–24':
        return AgeRange.from18To24;
      case '25_30':
      case '25-30':
      case '25–30':
        return AgeRange.from25To30;
      case '31_35':
      case '31-35':
      case '31–35':
        return AgeRange.from31To35;
      case '36_40':
      case '36-40':
      case '36–40':
        return AgeRange.from36To40;
      case '41_50':
      case '41-50':
      case '41–50':
        return AgeRange.from41To50;
      case '51_60':
      case '51-60':
      case '51–60':
        return AgeRange.from51To60;
      case '61_plus':
      case '61+':
      case '61_plus_years':
        return AgeRange.from61Plus;
      default:
        return null;
    }
  }
}

