import '../l10n/app_localizations.dart';

String familyRoleLabel(AppLocalizations strings, String role) {
  switch (role) {
    case 'padre':
      return strings.familyRoleFather;
    case 'madre':
      return strings.familyRoleMother;
    case 'abuelo':
      return strings.familyRoleGrandfather;
    case 'abuela':
      return strings.familyRoleGrandmother;
    case 'tio':
      return strings.familyRoleUncle;
    case 'tia':
      return strings.familyRoleAunt;
    case 'hijo':
      return strings.familyRoleChild;
    case 'hija':
      return strings.familyRoleDaughter;
    case 'tutor':
      return strings.familyRoleTutor;
    case 'admin':
      return strings.adminLabel;
    default:
      return strings.familyRoleOther;
  }
}

String requestStatusLabel(AppLocalizations strings, String status) {
  switch (status) {
    case 'accepted':
      return strings.statusAccepted;
    case 'rejected':
      return strings.statusRejected;
    default:
      return strings.statusPending;
  }
}
