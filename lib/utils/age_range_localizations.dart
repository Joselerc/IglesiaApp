import '../l10n/app_localizations.dart';
import 'age_range.dart';

extension AgeRangeLocalizations on AgeRange {
  String label(AppLocalizations strings) {
    switch (this) {
      case AgeRange.from0To5:
        return strings.ageRange0To5;
      case AgeRange.from6To12:
        return strings.ageRange6To12;
      case AgeRange.from13To17:
        return strings.ageRange13To17;
      case AgeRange.from18To24:
        return strings.ageRange18To24;
      case AgeRange.from25To30:
        return strings.ageRange25To30;
      case AgeRange.from31To35:
        return strings.ageRange31To35;
      case AgeRange.from36To40:
        return strings.ageRange36To40;
      case AgeRange.from41To50:
        return strings.ageRange41To50;
      case AgeRange.from51To60:
        return strings.ageRange51To60;
      case AgeRange.from61Plus:
        return strings.ageRange61Plus;
    }
  }
}

