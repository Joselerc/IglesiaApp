enum AgeGroup {
  plus18('18_plus'),
  from13To17('13_17');

  const AgeGroup(this.firestoreValue);

  final String firestoreValue;

  bool get isYouth => this == AgeGroup.from13To17;

  static AgeGroup? fromFirestoreValue(String? value) {
    switch (value) {
      case '18_plus':
        return AgeGroup.plus18;
      case '13_17':
        return AgeGroup.from13To17;
      default:
        return null;
    }
  }
}

