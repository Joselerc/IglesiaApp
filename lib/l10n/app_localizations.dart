import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @myProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get myProfile;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Cuenta'**
  String get deleteAccount;

  /// No description provided for @completeYourProfile.
  ///
  /// In es, this message translates to:
  /// **'Completa tu perfil'**
  String get completeYourProfile;

  /// No description provided for @personalInformation.
  ///
  /// In es, this message translates to:
  /// **'Información Personal'**
  String get personalInformation;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @name.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get name;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu nombre'**
  String get pleaseEnterYourName;

  /// No description provided for @surname.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get surname;

  /// No description provided for @pleaseEnterYourSurname.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu apellido'**
  String get pleaseEnterYourSurname;

  /// No description provided for @birthDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get birthDate;

  /// No description provided for @selectDate.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar fecha'**
  String get selectDate;

  /// No description provided for @gender.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get male;

  /// No description provided for @female.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get female;

  /// No description provided for @preferNotToSay.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no decirlo'**
  String get preferNotToSay;

  /// No description provided for @phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phone;

  /// No description provided for @optional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get optional;

  /// No description provided for @invalidPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono inválido'**
  String get invalidPhone;

  /// No description provided for @currentNumber.
  ///
  /// In es, this message translates to:
  /// **'Número actual: {number}'**
  String currentNumber(String number);

  /// No description provided for @participation.
  ///
  /// In es, this message translates to:
  /// **'Participación'**
  String get participation;

  /// No description provided for @ministries.
  ///
  /// In es, this message translates to:
  /// **'Ministerios'**
  String get ministries;

  /// No description provided for @errorLoadingMinistries.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los ministerios'**
  String get errorLoadingMinistries;

  /// No description provided for @mySchedules.
  ///
  /// In es, this message translates to:
  /// **'Mis Turnos'**
  String get mySchedules;

  /// No description provided for @manageAssignmentsAndInvitations.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus asignaciones e invitaciones de trabajo en los ministerios'**
  String get manageAssignmentsAndInvitations;

  /// No description provided for @joinAnotherMinistry.
  ///
  /// In es, this message translates to:
  /// **'Unirse a otro Ministerio'**
  String get joinAnotherMinistry;

  /// No description provided for @youDoNotBelongToAnyMinistry.
  ///
  /// In es, this message translates to:
  /// **'No perteneces a ningún ministerio'**
  String get youDoNotBelongToAnyMinistry;

  /// No description provided for @joinAMinistryToParticipate.
  ///
  /// In es, this message translates to:
  /// **'Únete a un ministerio para participar en el servicio de la iglesia'**
  String get joinAMinistryToParticipate;

  /// No description provided for @joinAMinistry.
  ///
  /// In es, this message translates to:
  /// **'Unirse a un Ministerio'**
  String get joinAMinistry;

  /// No description provided for @groups.
  ///
  /// In es, this message translates to:
  /// **'Grupos'**
  String get groups;

  /// No description provided for @errorLoadingGroups.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los grupos'**
  String get errorLoadingGroups;

  /// No description provided for @joinAnotherGroup.
  ///
  /// In es, this message translates to:
  /// **'Unirse a otro Grupo'**
  String get joinAnotherGroup;

  /// No description provided for @youDoNotBelongToAnyGroup.
  ///
  /// In es, this message translates to:
  /// **'No perteneces a ningún grupo'**
  String get youDoNotBelongToAnyGroup;

  /// No description provided for @joinAGroupToParticipate.
  ///
  /// In es, this message translates to:
  /// **'Únete a un grupo para participar en la vida comunitaria'**
  String get joinAGroupToParticipate;

  /// No description provided for @joinAGroup.
  ///
  /// In es, this message translates to:
  /// **'Unirse a un Grupo'**
  String get joinAGroup;

  /// No description provided for @administration.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get administration;

  /// No description provided for @manageDonations.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Donaciones'**
  String get manageDonations;

  /// No description provided for @configureDonationSection.
  ///
  /// In es, this message translates to:
  /// **'Configura la sección y formas de donación'**
  String get configureDonationSection;

  /// No description provided for @manageLiveStreams.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Transmisiones en Vivo'**
  String get manageLiveStreams;

  /// No description provided for @createEditControlStreams.
  ///
  /// In es, this message translates to:
  /// **'Crear, editar y controlar transmisiones'**
  String get createEditControlStreams;

  /// No description provided for @manageOnlineCourses.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Cursos en Línea'**
  String get manageOnlineCourses;

  /// No description provided for @createEditConfigureCourses.
  ///
  /// In es, this message translates to:
  /// **'Crear, editar y configurar cursos'**
  String get createEditConfigureCourses;

  /// No description provided for @manageHomeScreen.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Pantalla de Inicio'**
  String get manageHomeScreen;

  /// No description provided for @managePages.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Páginas'**
  String get managePages;

  /// No description provided for @createEditInfoContent.
  ///
  /// In es, this message translates to:
  /// **'Crear y editar contenido informativo'**
  String get createEditInfoContent;

  /// No description provided for @manageAvailability.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Disponibilidad'**
  String get manageAvailability;

  /// No description provided for @configureCounselingHours.
  ///
  /// In es, this message translates to:
  /// **'Configura tus horarios para asesoramiento'**
  String get configureCounselingHours;

  /// No description provided for @manageProfileFields.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Campos de Perfil'**
  String get manageProfileFields;

  /// No description provided for @configureAdditionalUserFields.
  ///
  /// In es, this message translates to:
  /// **'Configura los campos adicionales para los usuarios'**
  String get configureAdditionalUserFields;

  /// No description provided for @manageRoles.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Roles'**
  String get manageRoles;

  /// No description provided for @assignPastorRoles.
  ///
  /// In es, this message translates to:
  /// **'Asigna roles de pastor a otros usuarios'**
  String get assignPastorRoles;

  /// No description provided for @createEditRoles.
  ///
  /// In es, this message translates to:
  /// **'Crear/Editar Roles'**
  String get createEditRoles;

  /// No description provided for @createEditRolesAndPermissions.
  ///
  /// In es, this message translates to:
  /// **'Crear/editar roles y permisos'**
  String get createEditRolesAndPermissions;

  /// No description provided for @createAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Crear Anuncios'**
  String get createAnnouncements;

  /// No description provided for @createEditChurchAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Crea y edita anuncios para la iglesia'**
  String get createEditChurchAnnouncements;

  /// No description provided for @manageEvents.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Eventos'**
  String get manageEvents;

  /// No description provided for @createManageChurchEvents.
  ///
  /// In es, this message translates to:
  /// **'Crear y gestionar eventos de la iglesia'**
  String get createManageChurchEvents;

  /// No description provided for @manageVideos.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Videos'**
  String get manageVideos;

  /// No description provided for @administerChurchSectionsVideos.
  ///
  /// In es, this message translates to:
  /// **'Administra las secciones y videos de la iglesia'**
  String get administerChurchSectionsVideos;

  /// No description provided for @administerCults.
  ///
  /// In es, this message translates to:
  /// **'Administrar Cultos'**
  String get administerCults;

  /// No description provided for @manageCultsMinistriesSongs.
  ///
  /// In es, this message translates to:
  /// **'Gestionar cultos, ministerios y canciones'**
  String get manageCultsMinistriesSongs;

  /// No description provided for @createMinistry.
  ///
  /// In es, this message translates to:
  /// **'Crear Ministerio'**
  String get createMinistry;

  /// No description provided for @createConnect.
  ///
  /// In es, this message translates to:
  /// **'Crear Conexión'**
  String get createConnect;

  /// No description provided for @counselingRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de Asesoramiento'**
  String get counselingRequests;

  /// No description provided for @manageMemberRequests.
  ///
  /// In es, this message translates to:
  /// **'Gestiona las solicitudes de los miembros'**
  String get manageMemberRequests;

  /// No description provided for @privatePrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones Privadas'**
  String get privatePrayers;

  /// No description provided for @managePrivatePrayerRequests.
  ///
  /// In es, this message translates to:
  /// **'Gestiona las solicitudes de oración privada'**
  String get managePrivatePrayerRequests;

  /// No description provided for @sendPushNotification.
  ///
  /// In es, this message translates to:
  /// **'Enviar Notificación Push'**
  String get sendPushNotification;

  /// No description provided for @sendMessagesToChurchMembers.
  ///
  /// In es, this message translates to:
  /// **'Envía mensajes a los miembros de la iglesia'**
  String get sendMessagesToChurchMembers;

  /// No description provided for @deleteMinistries.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Ministerios'**
  String get deleteMinistries;

  /// No description provided for @removeExistingMinistries.
  ///
  /// In es, this message translates to:
  /// **'Eliminar ministerios existentes'**
  String get removeExistingMinistries;

  /// No description provided for @deleteGroups.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Grupos'**
  String get deleteGroups;

  /// No description provided for @removeExistingGroups.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupos existentes'**
  String get removeExistingGroups;

  /// No description provided for @reportsAndAttendance.
  ///
  /// In es, this message translates to:
  /// **'Informes y Asistencia'**
  String get reportsAndAttendance;

  /// No description provided for @manageEventAttendance.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Asistencia a Eventos'**
  String get manageEventAttendance;

  /// No description provided for @checkAttendanceGenerateReports.
  ///
  /// In es, this message translates to:
  /// **'Verificar asistencia y generar informes'**
  String get checkAttendanceGenerateReports;

  /// No description provided for @ministryStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Ministerios'**
  String get ministryStatistics;

  /// No description provided for @participationMembersAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis de participación y miembros'**
  String get participationMembersAnalysis;

  /// No description provided for @groupStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Grupos'**
  String get groupStatistics;

  /// No description provided for @scheduleStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Turnos'**
  String get scheduleStatistics;

  /// No description provided for @participationInvitationsAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis de participación e invitaciones'**
  String get participationInvitationsAnalysis;

  /// No description provided for @courseStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Cursos'**
  String get courseStatistics;

  /// No description provided for @enrollmentProgressAnalysis.
  ///
  /// In es, this message translates to:
  /// **'Análisis de inscripciones y progreso'**
  String get enrollmentProgressAnalysis;

  /// No description provided for @userInfo.
  ///
  /// In es, this message translates to:
  /// **'Información de Usuarios'**
  String get userInfo;

  /// No description provided for @consultParticipationDetails.
  ///
  /// In es, this message translates to:
  /// **'Consultar detalles de participación'**
  String get consultParticipationDetails;

  /// No description provided for @churchStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de la Iglesia'**
  String get churchStatistics;

  /// No description provided for @membersActivitiesOverview.
  ///
  /// In es, this message translates to:
  /// **'Visión general de los miembros y actividades'**
  String get membersActivitiesOverview;

  /// No description provided for @noGroupsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay grupos disponibles'**
  String get noGroupsAvailable;

  /// No description provided for @unnamedGroup.
  ///
  /// In es, this message translates to:
  /// **'Grupo sin nombre'**
  String get unnamedGroup;

  /// No description provided for @noMinistriesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay ministerios disponibles'**
  String get noMinistriesAvailable;

  /// No description provided for @unnamedMinistry.
  ///
  /// In es, this message translates to:
  /// **'Ministerio sin nombre'**
  String get unnamedMinistry;

  /// No description provided for @deleteGroup.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Grupo'**
  String get deleteGroup;

  /// No description provided for @confirmDeleteGroupQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro que desea eliminar el grupo '**
  String get confirmDeleteGroupQuestion;

  /// No description provided for @deleteGroupWarning.
  ///
  /// In es, this message translates to:
  /// **'\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.'**
  String get deleteGroupWarning;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @groupDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Grupo \"{groupName}\" eliminado con éxito'**
  String groupDeletedSuccessfully(String groupName);

  /// No description provided for @errorDeletingGroup.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el grupo: {error}'**
  String errorDeletingGroup(String error);

  /// No description provided for @deleteMinistry.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Ministerio'**
  String get deleteMinistry;

  /// No description provided for @confirmDeleteMinistryQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Está seguro que desea eliminar el ministerio '**
  String get confirmDeleteMinistryQuestion;

  /// No description provided for @deleteMinistryWarning.
  ///
  /// In es, this message translates to:
  /// **'\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.'**
  String get deleteMinistryWarning;

  /// No description provided for @ministryDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Ministerio \"{ministryName}\" eliminado con éxito'**
  String ministryDeletedSuccessfully(String ministryName);

  /// No description provided for @errorDeletingMinistry.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el ministerio: {error}'**
  String errorDeletingMinistry(Object error);

  /// No description provided for @logOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get logOut;

  /// No description provided for @errorLoggingOut.
  ///
  /// In es, this message translates to:
  /// **'Error al Cerrar Sesión: {error}'**
  String errorLoggingOut(String error);

  /// No description provided for @additionalInfoSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Información adicional guardada con éxito'**
  String get additionalInfoSavedSuccessfully;

  /// No description provided for @errorSaving.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String errorSaving(String error);

  /// No description provided for @unsupportedFieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de campo no soportado: {type}'**
  String unsupportedFieldType(String type);

  /// No description provided for @thisFieldIsRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get thisFieldIsRequired;

  /// No description provided for @requiredField.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get requiredField;

  /// No description provided for @selectLanguage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Idioma'**
  String get selectLanguage;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In es, this message translates to:
  /// **'Elige tu idioma preferido'**
  String get choosePreferredLanguage;

  /// No description provided for @somethingWentWrong.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal!'**
  String get somethingWentWrong;

  /// No description provided for @tryAgainLater.
  ///
  /// In es, this message translates to:
  /// **'Intenta de nuevo más tarde'**
  String get tryAgainLater;

  /// No description provided for @welcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido'**
  String get welcome;

  /// No description provided for @connectingToYourCommunity.
  ///
  /// In es, this message translates to:
  /// **'Conectándote a tu comunidad'**
  String get connectingToYourCommunity;

  /// No description provided for @errorLoadingSections.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar las secciones: {error}'**
  String errorLoadingSections(String error);

  /// No description provided for @unknownSectionError.
  ///
  /// In es, this message translates to:
  /// **'Sección desconocida o con error: {sectionType}'**
  String unknownSectionError(String sectionType);

  /// No description provided for @additionalInformationNeeded.
  ///
  /// In es, this message translates to:
  /// **'Información adicional necesaria'**
  String get additionalInformationNeeded;

  /// No description provided for @pleaseCompleteYourAdditionalInfo.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa tu información adicional para mejorar tu experiencia en la iglesia.'**
  String get pleaseCompleteYourAdditionalInfo;

  /// No description provided for @completeNow.
  ///
  /// In es, this message translates to:
  /// **'Completar ahora'**
  String get completeNow;

  /// No description provided for @doNotShowAgain.
  ///
  /// In es, this message translates to:
  /// **'No mostrar más'**
  String get doNotShowAgain;

  /// No description provided for @skipForNow.
  ///
  /// In es, this message translates to:
  /// **'Omitir por ahora'**
  String get skipForNow;

  /// No description provided for @user.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get user;

  /// No description provided for @workInvites.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones de Trabajo'**
  String get workInvites;

  /// No description provided for @serviceStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Servicios'**
  String get serviceStatistics;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @calendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calendar;

  /// No description provided for @videos.
  ///
  /// In es, this message translates to:
  /// **'videos'**
  String get videos;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @unread.
  ///
  /// In es, this message translates to:
  /// **'No leídas'**
  String get unread;

  /// No description provided for @markAllAsRead.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get markAllAsRead;

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In es, this message translates to:
  /// **'Todas las notificaciones marcadas como leídas'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @moreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptions;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas las notificaciones'**
  String get deleteAllNotifications;

  /// No description provided for @areYouSureYouWantToDeleteAllNotifications.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar todas las notificaciones?'**
  String get areYouSureYouWantToDeleteAllNotifications;

  /// No description provided for @deleteAll.
  ///
  /// In es, this message translates to:
  /// **'Eliminar todas'**
  String get deleteAll;

  /// No description provided for @allNotificationsDeleted.
  ///
  /// In es, this message translates to:
  /// **'Todas las notificaciones eliminadas'**
  String get allNotificationsDeleted;

  /// No description provided for @youHaveNoNotifications.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones'**
  String get youHaveNoNotifications;

  /// No description provided for @youHaveNoNotificationsOfType.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones de este tipo'**
  String get youHaveNoNotificationsOfType;

  /// No description provided for @removeFilter.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtro'**
  String get removeFilter;

  /// No description provided for @youHaveNoUnreadNotifications.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones no leídas'**
  String get youHaveNoUnreadNotifications;

  /// No description provided for @youHaveNoUnreadNotificationsOfType.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones no leídas de este tipo'**
  String get youHaveNoUnreadNotificationsOfType;

  /// No description provided for @notificationDeleted.
  ///
  /// In es, this message translates to:
  /// **'Notificación eliminada'**
  String get notificationDeleted;

  /// No description provided for @errorLoadingEvents.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los eventos'**
  String errorLoadingEvents(String error);

  /// No description provided for @calendars.
  ///
  /// In es, this message translates to:
  /// **'Calendarios'**
  String get calendars;

  /// No description provided for @events.
  ///
  /// In es, this message translates to:
  /// **'eventos'**
  String get events;

  /// No description provided for @services.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get services;

  /// No description provided for @counseling.
  ///
  /// In es, this message translates to:
  /// **'Asesoramiento'**
  String get counseling;

  /// No description provided for @manageSections.
  ///
  /// In es, this message translates to:
  /// **'Gestionar secciones'**
  String get manageSections;

  /// No description provided for @recentVideos.
  ///
  /// In es, this message translates to:
  /// **'Videos Recientes'**
  String get recentVideos;

  /// No description provided for @errorInSection.
  ///
  /// In es, this message translates to:
  /// **'Error en la sección: {error}'**
  String errorInSection(Object error);

  /// No description provided for @noVideosAvailableInSection.
  ///
  /// In es, this message translates to:
  /// **'No hay videos disponibles en esta sección'**
  String get noVideosAvailableInSection;

  /// No description provided for @errorInCustomSection.
  ///
  /// In es, this message translates to:
  /// **'Error en la sección personalizada: {error}'**
  String errorInCustomSection(Object error);

  /// No description provided for @noVideosInCustomSection.
  ///
  /// In es, this message translates to:
  /// **'No hay videos en esta sección personalizada'**
  String get noVideosInCustomSection;

  /// No description provided for @addVideo.
  ///
  /// In es, this message translates to:
  /// **'Añadir video'**
  String get addVideo;

  /// No description provided for @cultsSchedule.
  ///
  /// In es, this message translates to:
  /// **'Programación de Cultos'**
  String get cultsSchedule;

  /// No description provided for @noScheduledCults.
  ///
  /// In es, this message translates to:
  /// **'No hay cultos programados'**
  String get noScheduledCults;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get tomorrow;

  /// No description provided for @loginToYourAccount.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en tu cuenta'**
  String get loginToYourAccount;

  /// No description provided for @welcomeBackPleaseLogin.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido de nuevo! Por favor, inicia sesión para continuar'**
  String get welcomeBackPleaseLogin;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @yourEmailExample.
  ///
  /// In es, this message translates to:
  /// **'tu.email@ejemplo.com'**
  String get yourEmailExample;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe un email válido'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña'**
  String get enterYourPassword;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu contraseña'**
  String get pleaseEnterYourPassword;

  /// No description provided for @forgotYourPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotYourPassword;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get login;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes una cuenta?'**
  String get dontHaveAnAccount;

  /// No description provided for @signUp.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get signUp;

  /// No description provided for @welcomeBack.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido de nuevo!'**
  String get welcomeBack;

  /// No description provided for @noAccountWithThisEmail.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con este email'**
  String get noAccountWithThisEmail;

  /// No description provided for @incorrectPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta'**
  String get incorrectPassword;

  /// No description provided for @tooManyFailedAttempts.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos fallidos. Por favor, inténtalo más tarde.'**
  String get tooManyFailedAttempts;

  /// No description provided for @invalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Credenciales inválidas. Verifica tu email y contraseña.'**
  String get invalidCredentials;

  /// No description provided for @accountDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ha sido desactivada.'**
  String get accountDisabled;

  /// No description provided for @loginNotEnabled.
  ///
  /// In es, this message translates to:
  /// **'El inicio de sesión con email y contraseña no está habilitado.'**
  String get loginNotEnabled;

  /// No description provided for @connectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verifica tu conexión a Internet.'**
  String get connectionError;

  /// No description provided for @verificationError.
  ///
  /// In es, this message translates to:
  /// **'Error de verificación. Por favor, inténtalo de nuevo.'**
  String get verificationError;

  /// No description provided for @recaptchaFailed.
  ///
  /// In es, this message translates to:
  /// **'La verificación de reCAPTCHA falló. Por favor, inténtalo de nuevo.'**
  String get recaptchaFailed;

  /// No description provided for @errorLoggingIn.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión: {error}'**
  String errorLoggingIn(String error);

  /// No description provided for @operationTimedOut.
  ///
  /// In es, this message translates to:
  /// **'La operación tardó demasiado. Por favor, inténtalo de nuevo.'**
  String get operationTimedOut;

  /// No description provided for @platformError.
  ///
  /// In es, this message translates to:
  /// **'Error de plataforma. Por favor, contacta al administrador.'**
  String get platformError;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado. Por favor, inténtalo más tarde.'**
  String get unexpectedError;

  /// No description provided for @unauthenticatedUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario no autenticado'**
  String get unauthenticatedUser;

  /// No description provided for @noAdditionalFields.
  ///
  /// In es, this message translates to:
  /// **'No hay campos adicionales para completar'**
  String get noAdditionalFields;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @additionalInformation.
  ///
  /// In es, this message translates to:
  /// **'Información Adicional'**
  String get additionalInformation;

  /// No description provided for @pleaseCompleteTheFollowingInfo.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa la siguiente información:'**
  String get pleaseCompleteTheFollowingInfo;

  /// No description provided for @otherInformation.
  ///
  /// In es, this message translates to:
  /// **'Otra Información'**
  String get otherInformation;

  /// No description provided for @pleaseCorrectErrorsBeforeSaving.
  ///
  /// In es, this message translates to:
  /// **'Por favor, corrige los errores antes de guardar.'**
  String get pleaseCorrectErrorsBeforeSaving;

  /// No description provided for @pleaseFillAllRequiredBasicFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor, rellena todos los campos básicos obligatorios.'**
  String get pleaseFillAllRequiredBasicFields;

  /// No description provided for @pleaseFillAllRequiredAdditionalFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor, rellena todos los campos adicionales obligatorios (*)'**
  String get pleaseFillAllRequiredAdditionalFields;

  /// No description provided for @informationSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Información guardada con éxito'**
  String get informationSavedSuccessfully;

  /// No description provided for @birthDateLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get birthDateLabel;

  /// No description provided for @genderLabel.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get genderLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: 612345678'**
  String get phoneHint;

  /// No description provided for @selectAnOption.
  ///
  /// In es, this message translates to:
  /// **'Seleccione una opción'**
  String get selectAnOption;

  /// No description provided for @enterAValidNumber.
  ///
  /// In es, this message translates to:
  /// **'Inserta un número válido'**
  String get enterAValidNumber;

  /// No description provided for @enterAValidEmail.
  ///
  /// In es, this message translates to:
  /// **'Inserta un email válido'**
  String get enterAValidEmail;

  /// No description provided for @enterAValidPhoneNumber.
  ///
  /// In es, this message translates to:
  /// **'Inserta un número de teléfono válido'**
  String get enterAValidPhoneNumber;

  /// No description provided for @recoverPassword.
  ///
  /// In es, this message translates to:
  /// **'Recuperar Contraseña'**
  String get recoverPassword;

  /// No description provided for @enterEmailToReceiveInstructions.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu email para recibir las instrucciones'**
  String get enterEmailToReceiveInstructions;

  /// No description provided for @sendEmail.
  ///
  /// In es, this message translates to:
  /// **'Enviar Email'**
  String get sendEmail;

  /// No description provided for @emailSent.
  ///
  /// In es, this message translates to:
  /// **'¡Email Enviado!'**
  String get emailSent;

  /// No description provided for @checkYourInbox.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.'**
  String get checkYourInbox;

  /// No description provided for @gotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get gotIt;

  /// No description provided for @recoveryEmailSentSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Email de recuperación enviado con éxito!'**
  String get recoveryEmailSentSuccessfully;

  /// No description provided for @invalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get invalidEmail;

  /// No description provided for @errorSendingEmail.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar email: {error}'**
  String errorSendingEmail(String error);

  /// No description provided for @createANewAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear una nueva cuenta'**
  String get createANewAccount;

  /// No description provided for @fillYourDetailsToRegister.
  ///
  /// In es, this message translates to:
  /// **'Rellena tus datos para registrarte'**
  String get fillYourDetailsToRegister;

  /// No description provided for @enterYourName.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre'**
  String get enterYourName;

  /// No description provided for @enterYourSurname.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu apellido'**
  String get enterYourSurname;

  /// No description provided for @phoneNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de teléfono'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In es, this message translates to:
  /// **'(00) 00000-0000'**
  String get phoneNumberHint;

  /// No description provided for @pleaseEnterYourPhone.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu teléfono'**
  String get pleaseEnterYourPhone;

  /// No description provided for @pleaseEnterAValidPhone.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe un teléfono válido'**
  String get pleaseEnterAValidPhone;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe una contraseña'**
  String get pleaseEnterAPassword;

  /// No description provided for @passwordMustBeAtLeast6Chars.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get passwordMustBeAtLeast6Chars;

  /// No description provided for @confirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contraseña'**
  String get confirmPassword;

  /// No description provided for @enterYourPasswordAgain.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña de nuevo'**
  String get enterYourPasswordAgain;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In es, this message translates to:
  /// **'Por favor, confirma tu contraseña'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get passwordsDoNotMatch;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get createAccount;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @byRegisteringYouAccept.
  ///
  /// In es, this message translates to:
  /// **'Al registrarte, aceptas nuestros términos y condiciones y nuestra política de privacidad.'**
  String get byRegisteringYouAccept;

  /// No description provided for @welcomeCompleteProfile.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido! Completa tu perfil para disfrutar de todas las funciones.'**
  String get welcomeCompleteProfile;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este email'**
  String get emailAlreadyInUse;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In es, this message translates to:
  /// **'El formato del email no es válido'**
  String get invalidEmailFormat;

  /// No description provided for @registrationNotEnabled.
  ///
  /// In es, this message translates to:
  /// **'El registro con email y contraseña no está habilitado'**
  String get registrationNotEnabled;

  /// No description provided for @weakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil, intenta una más segura'**
  String get weakPassword;

  /// No description provided for @errorRegistering.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar: {error}'**
  String errorRegistering(String error);

  /// No description provided for @pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptados'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazados'**
  String get rejected;

  /// No description provided for @youHaveNoWorkInvites.
  ///
  /// In es, this message translates to:
  /// **'No tienes invitaciones de trabajo'**
  String get youHaveNoWorkInvites;

  /// No description provided for @youHaveNoInvitesOfType.
  ///
  /// In es, this message translates to:
  /// **'No tienes invitaciones {status}'**
  String youHaveNoInvitesOfType(String status);

  /// No description provided for @acceptedStatus.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get acceptedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get rejectedStatus;

  /// No description provided for @seenStatus.
  ///
  /// In es, this message translates to:
  /// **'Visto'**
  String get seenStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pendingStatus;

  /// No description provided for @reject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @inviteAcceptedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Invitación aceptada con éxito'**
  String get inviteAcceptedSuccessfully;

  /// No description provided for @inviteRejectedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Invitación rechazada con éxito'**
  String get inviteRejectedSuccessfully;

  /// No description provided for @errorRespondingToInvite.
  ///
  /// In es, this message translates to:
  /// **'Error al responder a la invitación: {error}'**
  String errorRespondingToInvite(String error);

  /// No description provided for @invitationDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles de Invitación'**
  String get invitationDetails;

  /// No description provided for @invitationAccepted.
  ///
  /// In es, this message translates to:
  /// **'Invitación aceptada exitosamente'**
  String get invitationAccepted;

  /// No description provided for @invitationRejected.
  ///
  /// In es, this message translates to:
  /// **'Invitación rechazada exitosamente'**
  String get invitationRejected;

  /// No description provided for @workInvitation.
  ///
  /// In es, this message translates to:
  /// **'Invitación de Trabajo'**
  String get workInvitation;

  /// No description provided for @jobDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles del Trabajo'**
  String get jobDetails;

  /// No description provided for @roleToPerform.
  ///
  /// In es, this message translates to:
  /// **'Rol a desempeñar'**
  String get roleToPerform;

  /// No description provided for @invitationInfo.
  ///
  /// In es, this message translates to:
  /// **'Información de la Invitación'**
  String get invitationInfo;

  /// No description provided for @sentBy.
  ///
  /// In es, this message translates to:
  /// **'Enviado por'**
  String get sentBy;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @sentDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de envío'**
  String get sentDate;

  /// No description provided for @responseDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de respuesta'**
  String get responseDate;

  /// No description provided for @announcements.
  ///
  /// In es, this message translates to:
  /// **'anuncios'**
  String get announcements;

  /// No description provided for @errorLoadingAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los anuncios'**
  String get errorLoadingAnnouncements;

  /// No description provided for @noAnnouncementsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay anuncios disponibles'**
  String get noAnnouncementsAvailable;

  /// No description provided for @seeMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get seeMore;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos futuros en este momento'**
  String get noUpcomingEvents;

  /// No description provided for @online.
  ///
  /// In es, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @inPerson.
  ///
  /// In es, this message translates to:
  /// **'Presencial'**
  String get inPerson;

  /// No description provided for @hybrid.
  ///
  /// In es, this message translates to:
  /// **'Híbrido'**
  String get hybrid;

  /// No description provided for @schedulePastoralCounseling.
  ///
  /// In es, this message translates to:
  /// **'Agenda una cita pastoral'**
  String get schedulePastoralCounseling;

  /// No description provided for @talkToAPastor.
  ///
  /// In es, this message translates to:
  /// **'Habla con un pastor para orientación espiritual'**
  String get talkToAPastor;

  /// No description provided for @viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get viewAll;

  /// No description provided for @swipeToSeeFeaturedCourses.
  ///
  /// In es, this message translates to:
  /// **'Desliza para ver cursos destacados'**
  String get swipeToSeeFeaturedCourses;

  /// No description provided for @lessons.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 lección} other{{count} lecciones}}'**
  String lessons(int count);

  /// No description provided for @minutes.
  ///
  /// In es, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @hours.
  ///
  /// In es, this message translates to:
  /// **'{count} h'**
  String hours(int count);

  /// No description provided for @hoursAndMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String hoursAndMinutes(int hours, int minutes);

  /// No description provided for @viewDonationOptions.
  ///
  /// In es, this message translates to:
  /// **'Ver opciones de donación'**
  String get viewDonationOptions;

  /// No description provided for @participateInChurchMinistries.
  ///
  /// In es, this message translates to:
  /// **'Participa en los ministerios de la iglesia'**
  String get participateInChurchMinistries;

  /// No description provided for @connect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get connect;

  /// No description provided for @connectWithChurchGroups.
  ///
  /// In es, this message translates to:
  /// **'Conéctate con los grupos de la iglesia'**
  String get connectWithChurchGroups;

  /// No description provided for @privatePrayer.
  ///
  /// In es, this message translates to:
  /// **'Oración Privada'**
  String get privatePrayer;

  /// No description provided for @sendPrivatePrayerRequests.
  ///
  /// In es, this message translates to:
  /// **'Envía peticiones de oración privadas'**
  String get sendPrivatePrayerRequests;

  /// No description provided for @publicPrayer.
  ///
  /// In es, this message translates to:
  /// **'Oración Pública'**
  String get publicPrayer;

  /// No description provided for @shareAndPrayWithTheCommunity.
  ///
  /// In es, this message translates to:
  /// **'Comparte y ora con la comunidad'**
  String get shareAndPrayWithTheCommunity;

  /// No description provided for @eventNotFound.
  ///
  /// In es, this message translates to:
  /// **'Evento no encontrado'**
  String get eventNotFound;

  /// No description provided for @errorLoadingEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el evento'**
  String get errorLoadingEvent;

  /// No description provided for @errorLoadingEventDetails.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar detalles del evento: {error}'**
  String errorLoadingEventDetails(String error);

  /// No description provided for @eventNotFoundOrInvalid.
  ///
  /// In es, this message translates to:
  /// **'Evento no encontrado o inválido.'**
  String get eventNotFoundOrInvalid;

  /// No description provided for @errorOpeningEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir el evento: {error}'**
  String errorOpeningEvent(String error);

  /// No description provided for @errorNavigatingToEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al navegar al evento: {error}'**
  String errorNavigatingToEvent(String error);

  /// No description provided for @announcementReloaded.
  ///
  /// In es, this message translates to:
  /// **'Datos del anuncio recargados (implementar actualización de estado si es necesario)'**
  String get announcementReloaded;

  /// No description provided for @errorReloadingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al recargar anuncio: {error}'**
  String errorReloadingAnnouncement(String error);

  /// No description provided for @confirmDeletion.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Eliminación'**
  String get confirmDeletion;

  /// No description provided for @confirmDeleteAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar este anuncio? Esta acción no se puede deshacer.'**
  String get confirmDeleteAnnouncement;

  /// No description provided for @deletingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Eliminando anuncio...'**
  String get deletingAnnouncement;

  /// No description provided for @errorDeletingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar imagen del Storage: {error}'**
  String errorDeletingImage(String error);

  /// No description provided for @announcementDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Anuncio eliminado con éxito.'**
  String get announcementDeletedSuccessfully;

  /// No description provided for @errorDeletingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar anuncio: {error}'**
  String errorDeletingAnnouncement(String error);

  /// No description provided for @cultAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Anuncio de Culto'**
  String get cultAnnouncement;

  /// No description provided for @announcement.
  ///
  /// In es, this message translates to:
  /// **'Anuncio'**
  String get announcement;

  /// No description provided for @editAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Editar Anuncio'**
  String get editAnnouncement;

  /// No description provided for @deleteAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Anuncio'**
  String get deleteAnnouncement;

  /// No description provided for @cult.
  ///
  /// In es, this message translates to:
  /// **'Culto'**
  String get cult;

  /// No description provided for @publishedOn.
  ///
  /// In es, this message translates to:
  /// **'Publicado el: {date}'**
  String publishedOn(String date);

  /// No description provided for @cultDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha del culto: {date}'**
  String cultDate(String date);

  /// No description provided for @linkedEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento Vinculado'**
  String get linkedEvent;

  /// No description provided for @tapToSeeDetails.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver detalles'**
  String get tapToSeeDetails;

  /// No description provided for @noEventLinkedToThisCult.
  ///
  /// In es, this message translates to:
  /// **'Ningún evento vinculado a este culto.'**
  String get noEventLinkedToThisCult;

  /// No description provided for @errorVerifyingRegistration.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar registro: {error}'**
  String errorVerifyingRegistration(String error);

  /// No description provided for @errorVerifyingUserRole.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar el rol del usuario: {error}'**
  String errorVerifyingUserRole(String error);

  /// No description provided for @updateEventLink.
  ///
  /// In es, this message translates to:
  /// **'Actualizar enlace del evento'**
  String get updateEventLink;

  /// No description provided for @addEventLink.
  ///
  /// In es, this message translates to:
  /// **'Añadir enlace del evento'**
  String get addEventLink;

  /// No description provided for @enterOnlineEventLink.
  ///
  /// In es, this message translates to:
  /// **'Introduce el enlace para que los asistentes accedan al evento online:'**
  String get enterOnlineEventLink;

  /// No description provided for @eventUrl.
  ///
  /// In es, this message translates to:
  /// **'URL del evento'**
  String get eventUrl;

  /// No description provided for @eventUrlHint.
  ///
  /// In es, this message translates to:
  /// **'https://zoom.us/meeting/...'**
  String get eventUrlHint;

  /// No description provided for @invalidUrlFormat.
  ///
  /// In es, this message translates to:
  /// **'El enlace debe comenzar con http:// o https://'**
  String get invalidUrlFormat;

  /// No description provided for @deleteLink.
  ///
  /// In es, this message translates to:
  /// **'Eliminar enlace'**
  String get deleteLink;

  /// No description provided for @linkDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Enlace del evento eliminado correctamente'**
  String get linkDeletedSuccessfully;

  /// No description provided for @linkUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Enlace del evento actualizado correctamente'**
  String get linkUpdatedSuccessfully;

  /// No description provided for @linkAddedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Enlace del evento añadido correctamente'**
  String get linkAddedSuccessfully;

  /// No description provided for @errorUpdatingLink.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el enlace: {error}'**
  String errorUpdatingLink(String error);

  /// No description provided for @errorSendingNotifications.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar notificaciones: {error}'**
  String errorSendingNotifications(String error);

  /// No description provided for @mustLoginToRegisterAttendance.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para registrar tu asistencia'**
  String get mustLoginToRegisterAttendance;

  /// No description provided for @attendanceRegisteredSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Asistencia registrada correctamente!'**
  String get attendanceRegisteredSuccessfully;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace'**
  String get couldNotOpenLink;

  /// No description provided for @errorOpeningLink.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir el enlace: {error}'**
  String errorOpeningLink(String error);

  /// No description provided for @noPermissionToDeleteEvent.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para eliminar este evento'**
  String get noPermissionToDeleteEvent;

  /// No description provided for @deleteEvent.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Evento'**
  String get deleteEvent;

  /// No description provided for @confirmDeleteEvent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar este evento?'**
  String get confirmDeleteEvent;

  /// No description provided for @eventDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Evento eliminado con éxito'**
  String get eventDeletedSuccessfully;

  /// No description provided for @deleteTicket.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Entrada'**
  String get deleteTicket;

  /// No description provided for @confirmDeleteTicket.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar esta entrada? Esta acción no se puede deshacer.'**
  String get confirmDeleteTicket;

  /// No description provided for @ticketDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Entrada eliminada con éxito'**
  String get ticketDeletedSuccessfully;

  /// No description provided for @errorDeletingTicket.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar: {error}'**
  String errorDeletingTicket(String error);

  /// No description provided for @deleteMyTicket.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi entrada'**
  String get deleteMyTicket;

  /// No description provided for @confirmDeleteMyTicket.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar tu entrada? Esta acción no se puede deshacer.'**
  String get confirmDeleteMyTicket;

  /// No description provided for @errorDeletingMyTicket.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar la entrada: {error}'**
  String errorDeletingMyTicket(String error);

  /// No description provided for @notDefined.
  ///
  /// In es, this message translates to:
  /// **'No definido'**
  String get notDefined;

  /// No description provided for @onlineEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento online'**
  String get onlineEvent;

  /// No description provided for @accessEvent.
  ///
  /// In es, this message translates to:
  /// **'Acceder al evento'**
  String get accessEvent;

  /// No description provided for @copyEventLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace del evento'**
  String get copyEventLink;

  /// No description provided for @linkCopied.
  ///
  /// In es, this message translates to:
  /// **'¡Enlace copiado!'**
  String get linkCopied;

  /// No description provided for @linkNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Enlace no configurado'**
  String get linkNotConfigured;

  /// No description provided for @addLinkForAttendees.
  ///
  /// In es, this message translates to:
  /// **'Añade un enlace para que los asistentes puedan acceder al evento'**
  String get addLinkForAttendees;

  /// No description provided for @addLink.
  ///
  /// In es, this message translates to:
  /// **'Añadir enlace'**
  String get addLink;

  /// No description provided for @physicalLocationNotSpecified.
  ///
  /// In es, this message translates to:
  /// **'Ubicación física no especificada'**
  String get physicalLocationNotSpecified;

  /// No description provided for @physicalLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación física'**
  String get physicalLocation;

  /// No description provided for @accessOnline.
  ///
  /// In es, this message translates to:
  /// **'Acceder online'**
  String get accessOnline;

  /// No description provided for @addLinkForOnlineAttendance.
  ///
  /// In es, this message translates to:
  /// **'Añade un enlace para la asistencia online'**
  String get addLinkForOnlineAttendance;

  /// No description provided for @locationNotSpecified.
  ///
  /// In es, this message translates to:
  /// **'Lugar no especificado'**
  String get locationNotSpecified;

  /// No description provided for @manageAttendees.
  ///
  /// In es, this message translates to:
  /// **'Gestionar asistentes'**
  String get manageAttendees;

  /// No description provided for @scanTickets.
  ///
  /// In es, this message translates to:
  /// **'Escanear entradas'**
  String get scanTickets;

  /// No description provided for @updateLink.
  ///
  /// In es, this message translates to:
  /// **'Actualizar enlace'**
  String get updateLink;

  /// No description provided for @createNewTicket.
  ///
  /// In es, this message translates to:
  /// **'Crear nuevo ticket'**
  String get createNewTicket;

  /// No description provided for @noPermissionToCreateTickets.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear tickets'**
  String get noPermissionToCreateTickets;

  /// No description provided for @deleteEventTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar evento'**
  String get deleteEventTooltip;

  /// No description provided for @start.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get start;

  /// No description provided for @end.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get end;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @updatingTickets.
  ///
  /// In es, this message translates to:
  /// **'Actualizando entradas...'**
  String get updatingTickets;

  /// No description provided for @loadingTickets.
  ///
  /// In es, this message translates to:
  /// **'Cargando entradas...'**
  String get loadingTickets;

  /// No description provided for @availableTickets.
  ///
  /// In es, this message translates to:
  /// **'Entradas disponibles'**
  String get availableTickets;

  /// No description provided for @createTicket.
  ///
  /// In es, this message translates to:
  /// **'Crear entrada'**
  String get createTicket;

  /// No description provided for @noTicketsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay entradas disponibles'**
  String get noTicketsAvailable;

  /// No description provided for @createTicketForUsers.
  ///
  /// In es, this message translates to:
  /// **'Crea una entrada para que los usuarios puedan registrarse'**
  String get createTicketForUsers;

  /// No description provided for @errorLoadingTickets.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar entradas: {error}'**
  String errorLoadingTickets(String error);

  /// No description provided for @alreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Ya registrado'**
  String get alreadyRegistered;

  /// No description provided for @viewQr.
  ///
  /// In es, this message translates to:
  /// **'Ver QR'**
  String get viewQr;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get register;

  /// No description provided for @presential.
  ///
  /// In es, this message translates to:
  /// **'Presencial'**
  String get presential;

  /// No description provided for @unknown.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get unknown;

  /// No description provided for @cults.
  ///
  /// In es, this message translates to:
  /// **'Cultos'**
  String get cults;

  /// No description provided for @unknownSectionType.
  ///
  /// In es, this message translates to:
  /// **'Sección desconocida o error: {sectionType}'**
  String unknownSectionType(String sectionType);

  /// No description provided for @additionalInformationRequired.
  ///
  /// In es, this message translates to:
  /// **'Información adicional necesaria'**
  String get additionalInformationRequired;

  /// No description provided for @pleaseCompleteAdditionalInfo.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa tu información adicional para mejorar tu experiencia en la iglesia.'**
  String get pleaseCompleteAdditionalInfo;

  /// No description provided for @churchName.
  ///
  /// In es, this message translates to:
  /// **'Amor en Movimiento'**
  String get churchName;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get navNotifications;

  /// No description provided for @navCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get navCalendar;

  /// No description provided for @navVideos.
  ///
  /// In es, this message translates to:
  /// **'Videos'**
  String get navVideos;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @errorPublishingComment.
  ///
  /// In es, this message translates to:
  /// **'Error al publicar el comentario: {error}'**
  String errorPublishingComment(String error);

  /// No description provided for @deleteOwnCommentsOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo puedes eliminar tus propios comentarios'**
  String get deleteOwnCommentsOnly;

  /// No description provided for @deleteComment.
  ///
  /// In es, this message translates to:
  /// **'Eliminar comentario'**
  String get deleteComment;

  /// No description provided for @deleteCommentConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este comentario?'**
  String get deleteCommentConfirmation;

  /// No description provided for @commentDeleted.
  ///
  /// In es, this message translates to:
  /// **'Comentario eliminado'**
  String get commentDeleted;

  /// No description provided for @errorDeletingComment.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el comentario: {error}'**
  String errorDeletingComment(String error);

  /// No description provided for @errorTitle.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @cultNotFound.
  ///
  /// In es, this message translates to:
  /// **'Culto no encontrado'**
  String get cultNotFound;

  /// No description provided for @totalLessons.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, one {# lección} other {# lecciones}}'**
  String totalLessons(int count);

  /// No description provided for @myKidsManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión MyKids'**
  String get myKidsManagement;

  /// No description provided for @familyProfiles.
  ///
  /// In es, this message translates to:
  /// **'Perfiles Familiares'**
  String get familyProfiles;

  /// No description provided for @manageFamilyProfiles.
  ///
  /// In es, this message translates to:
  /// **'Gestionar perfiles de padres y niños'**
  String get manageFamilyProfiles;

  /// No description provided for @manageRoomsAndCheckin.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Salas y Check-in'**
  String get manageRoomsAndCheckin;

  /// No description provided for @manageRoomsCheckinDescription.
  ///
  /// In es, this message translates to:
  /// **'Administrar salas, check-in/out y asistencia'**
  String get manageRoomsCheckinDescription;

  /// No description provided for @permissionsDiagnostics.
  ///
  /// In es, this message translates to:
  /// **'Diagnóstico de Permisos'**
  String get permissionsDiagnostics;

  /// No description provided for @availablePermissions.
  ///
  /// In es, this message translates to:
  /// **'Permisos Disponibles'**
  String get availablePermissions;

  /// No description provided for @noUserData.
  ///
  /// In es, this message translates to:
  /// **'No hay datos de usuario'**
  String get noUserData;

  /// No description provided for @noName.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get noName;

  /// No description provided for @noEmail.
  ///
  /// In es, this message translates to:
  /// **'Sin email'**
  String get noEmail;

  /// No description provided for @roleIdLabel.
  ///
  /// In es, this message translates to:
  /// **'ID del Rol'**
  String get roleIdLabel;

  /// No description provided for @noRole.
  ///
  /// In es, this message translates to:
  /// **'Sin rol'**
  String get noRole;

  /// No description provided for @superUser.
  ///
  /// In es, this message translates to:
  /// **'SuperUsuario'**
  String get superUser;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @rolePermissionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Permisos del rol'**
  String get rolePermissionsTitle;

  /// No description provided for @roleNoPermissions.
  ///
  /// In es, this message translates to:
  /// **'Este rol no tiene permisos asignados'**
  String get roleNoPermissions;

  /// No description provided for @noRoleInfo.
  ///
  /// In es, this message translates to:
  /// **'No hay información de rol disponible'**
  String get noRoleInfo;

  /// No description provided for @deleteGroupConfirmationPrefix.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar el grupo '**
  String get deleteGroupConfirmationPrefix;

  /// No description provided for @deleteMinistryConfirmationPrefix.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar el ministerio '**
  String get deleteMinistryConfirmationPrefix;

  /// No description provided for @errorFetchingDiagnostics.
  ///
  /// In es, this message translates to:
  /// **'Error al obtener diagnóstico: {error}'**
  String errorFetchingDiagnostics(String error);

  /// No description provided for @roleNotFound.
  ///
  /// In es, this message translates to:
  /// **'Rol no encontrado: {roleId}'**
  String roleNotFound(String roleId);

  /// No description provided for @idLabel.
  ///
  /// In es, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @personalInformationSection.
  ///
  /// In es, this message translates to:
  /// **'Información Personal'**
  String get personalInformationSection;

  /// No description provided for @birthDateField.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Nacimiento'**
  String get birthDateField;

  /// No description provided for @genderField.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get genderField;

  /// No description provided for @phoneField.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phoneField;

  /// No description provided for @mySchedulesSection.
  ///
  /// In es, this message translates to:
  /// **'Mis Turnos'**
  String get mySchedulesSection;

  /// No description provided for @manageMinistriesAssignments.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus asignaciones e invitaciones de trabajo en los ministerios'**
  String get manageMinistriesAssignments;

  /// No description provided for @errorSavingInfo.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar: {error}'**
  String errorSavingInfo(String error);

  /// No description provided for @requiredFieldTooltip.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get requiredFieldTooltip;

  /// No description provided for @navigateToFamilyProfiles.
  ///
  /// In es, this message translates to:
  /// **'Navegar para Perfiles Familiares'**
  String get navigateToFamilyProfiles;

  /// No description provided for @personalInfoUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Información personal actualizada con éxito!'**
  String get personalInfoUpdatedSuccessfully;

  /// No description provided for @errorSavingPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar datos personales: {error}'**
  String errorSavingPersonalData(String error);

  /// No description provided for @errorLoadingPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar datos personales: {error}'**
  String errorLoadingPersonalData(String error);

  /// No description provided for @manageDonationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Donaciones'**
  String get manageDonationsTitle;

  /// No description provided for @noPermissionToSaveSettings.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para guardar configuraciones.'**
  String get noPermissionToSaveSettings;

  /// No description provided for @errorUploadingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al subir imagen'**
  String get errorUploadingImage;

  /// No description provided for @donationConfigSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuraciones de donación guardadas'**
  String get donationConfigSaved;

  /// No description provided for @errorCheckingPermission.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar permiso: {error}'**
  String errorCheckingPermission(String error);

  /// No description provided for @accessDenied.
  ///
  /// In es, this message translates to:
  /// **'Acceso Denegado'**
  String get accessDenied;

  /// No description provided for @noPermissionManageDonations.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar las configuraciones de donación.'**
  String get noPermissionManageDonations;

  /// No description provided for @configureDonationsSection.
  ///
  /// In es, this message translates to:
  /// **'Configura cómo aparecerá la sección de donaciones en la Pantalla de Inicio.'**
  String get configureDonationsSection;

  /// No description provided for @sectionTitleOptional.
  ///
  /// In es, this message translates to:
  /// **'Título de la Sección (Opcional)'**
  String get sectionTitleOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In es, this message translates to:
  /// **'Descripción (Opcional)'**
  String get descriptionOptional;

  /// No description provided for @backgroundImageOptional.
  ///
  /// In es, this message translates to:
  /// **'Imagen de Fondo (Opcional)'**
  String get backgroundImageOptional;

  /// No description provided for @tapToAddImage.
  ///
  /// In es, this message translates to:
  /// **'Toca para agregar imagen\n(Recomendado 16:9)'**
  String get tapToAddImage;

  /// No description provided for @removeImage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Imagen'**
  String get removeImage;

  /// No description provided for @bankAccountsOptional.
  ///
  /// In es, this message translates to:
  /// **'Cuentas Bancarias (Opcional)'**
  String get bankAccountsOptional;

  /// No description provided for @bankingInformation.
  ///
  /// In es, this message translates to:
  /// **'Información Bancaria'**
  String get bankingInformation;

  /// No description provided for @bankAccountsHint.
  ///
  /// In es, this message translates to:
  /// **'Banco: XXX\nAgencia: YYYY\nCuenta: ZZZZZZ\nNombre Titular\n\n(Separa cuentas con línea en blanco)'**
  String get bankAccountsHint;

  /// No description provided for @pixKeysOptional.
  ///
  /// In es, this message translates to:
  /// **'Claves Pix (Opcional)'**
  String get pixKeysOptional;

  /// No description provided for @noPixKeysAdded.
  ///
  /// In es, this message translates to:
  /// **'Ninguna clave Pix agregada.'**
  String get noPixKeysAdded;

  /// No description provided for @pixKey.
  ///
  /// In es, this message translates to:
  /// **'Clave Pix'**
  String get pixKey;

  /// No description provided for @removeKey.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Clave'**
  String get removeKey;

  /// No description provided for @keyRequired.
  ///
  /// In es, this message translates to:
  /// **'Clave obligatoria'**
  String get keyRequired;

  /// No description provided for @addPixKey.
  ///
  /// In es, this message translates to:
  /// **'Agregar Clave Pix'**
  String get addPixKey;

  /// No description provided for @saveSettings.
  ///
  /// In es, this message translates to:
  /// **'Guardar Configuraciones'**
  String get saveSettings;

  /// No description provided for @manageLiveStreamTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Transmisión'**
  String get manageLiveStreamTitle;

  /// No description provided for @errorLoadingData.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar datos: {error}'**
  String errorLoadingData(String error);

  /// No description provided for @noPermissionManageLiveStream.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar la configuración de transmisión.'**
  String get noPermissionManageLiveStream;

  /// No description provided for @sectionTitleHome.
  ///
  /// In es, this message translates to:
  /// **'Título de la Sección (Home)'**
  String get sectionTitleHome;

  /// No description provided for @sectionTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Transmisión En Vivo'**
  String get sectionTitleHint;

  /// No description provided for @pleaseEnterSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un título para la sección'**
  String get pleaseEnterSectionTitle;

  /// No description provided for @additionalTextOptional.
  ///
  /// In es, this message translates to:
  /// **'Texto Adicional (opcional)'**
  String get additionalTextOptional;

  /// No description provided for @transmissionImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen de la Transmisión'**
  String get transmissionImage;

  /// No description provided for @titleOverImage.
  ///
  /// In es, this message translates to:
  /// **'Título sobre la Imagen'**
  String get titleOverImage;

  /// No description provided for @titleOverImageHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Culto de Domingo'**
  String get titleOverImageHint;

  /// No description provided for @transmissionLink.
  ///
  /// In es, this message translates to:
  /// **'Link de la Transmisión'**
  String get transmissionLink;

  /// No description provided for @urlYouTubeVimeo.
  ///
  /// In es, this message translates to:
  /// **'URL (YouTube, Vimeo, etc.)'**
  String get urlYouTubeVimeo;

  /// No description provided for @pasteFullLinkHere.
  ///
  /// In es, this message translates to:
  /// **'Pega el link completo aquí'**
  String get pasteFullLinkHere;

  /// No description provided for @pleaseEnterValidUrl.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa una URL válida (comenzando con http o https)'**
  String get pleaseEnterValidUrl;

  /// No description provided for @activateTransmissionHome.
  ///
  /// In es, this message translates to:
  /// **'Activar Transmisión en Home'**
  String get activateTransmissionHome;

  /// No description provided for @visibleInHome.
  ///
  /// In es, this message translates to:
  /// **'Visible en Home'**
  String get visibleInHome;

  /// No description provided for @hiddenInHome.
  ///
  /// In es, this message translates to:
  /// **'Oculto en Home'**
  String get hiddenInHome;

  /// No description provided for @saveConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Guardar Configuración'**
  String get saveConfiguration;

  /// No description provided for @configurationSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada'**
  String get configurationSaved;

  /// No description provided for @errorUploadingImageStream.
  ///
  /// In es, this message translates to:
  /// **'Error al subir la imagen'**
  String get errorUploadingImageStream;

  /// No description provided for @manageHomeScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Pantalla de Inicio'**
  String get manageHomeScreenTitle;

  /// No description provided for @noPermissionReorderSections.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para reordenar secciones.'**
  String get noPermissionReorderSections;

  /// No description provided for @errorSavingNewOrder.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar el nuevo orden: {error}'**
  String errorSavingNewOrder(String error);

  /// No description provided for @noPermissionEditSections.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para editar secciones.'**
  String get noPermissionEditSections;

  /// No description provided for @editSectionName.
  ///
  /// In es, this message translates to:
  /// **'Editar Nombre de la Sección'**
  String get editSectionName;

  /// No description provided for @sectionNameUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Nombre de la sección actualizado con éxito!'**
  String get sectionNameUpdatedSuccessfully;

  /// No description provided for @errorUpdatingName.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar nombre: {error}'**
  String errorUpdatingName(String error);

  /// No description provided for @configureVisibility.
  ///
  /// In es, this message translates to:
  /// **'Configurar Visibilidad'**
  String get configureVisibility;

  /// No description provided for @sectionWillBeHiddenWhen.
  ///
  /// In es, this message translates to:
  /// **'La sección será ocultada cuando no haya {contentType} para mostrar.'**
  String sectionWillBeHiddenWhen(String contentType);

  /// No description provided for @visibilityConfigurationUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Configuración de visibilidad actualizada!'**
  String get visibilityConfigurationUpdated;

  /// No description provided for @errorUpdatingConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar configuración: {error}'**
  String errorUpdatingConfiguration(String error);

  /// No description provided for @noPermissionChangeStatus.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para cambiar estado.'**
  String get noPermissionChangeStatus;

  /// No description provided for @errorUpdatingStatus.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar estado: {error}'**
  String errorUpdatingStatus(String error);

  /// No description provided for @thisSectionCannotBeEditedHere.
  ///
  /// In es, this message translates to:
  /// **'Esta sección no puede ser editada aquí.'**
  String get thisSectionCannotBeEditedHere;

  /// No description provided for @noPermissionCreateSections.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para crear secciones.'**
  String get noPermissionCreateSections;

  /// No description provided for @noSectionsFound.
  ///
  /// In es, this message translates to:
  /// **'Ninguna sección encontrada.'**
  String get noSectionsFound;

  /// No description provided for @scheduledCults.
  ///
  /// In es, this message translates to:
  /// **'cultos programados'**
  String get scheduledCults;

  /// No description provided for @pages.
  ///
  /// In es, this message translates to:
  /// **'páginas'**
  String get pages;

  /// No description provided for @content.
  ///
  /// In es, this message translates to:
  /// **'contenido'**
  String get content;

  /// No description provided for @manageProfileFieldsTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Campos de Perfil'**
  String get manageProfileFieldsTitle;

  /// No description provided for @noPermissionManageProfileFields.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar campos de perfil.'**
  String get noPermissionManageProfileFields;

  /// No description provided for @createField.
  ///
  /// In es, this message translates to:
  /// **'Crear Campo'**
  String get createField;

  /// No description provided for @confirmDeleteField.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar el campo \"{fieldName}\"?'**
  String confirmDeleteField(String fieldName);

  /// No description provided for @fieldDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Campo eliminado con éxito'**
  String get fieldDeletedSuccessfully;

  /// No description provided for @errorDeletingField.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el campo: {error}'**
  String errorDeletingField(String error);

  /// No description provided for @pleaseAddAtLeastOneOption.
  ///
  /// In es, this message translates to:
  /// **'Por favor, añade al menos una opción para el campo de selección.'**
  String get pleaseAddAtLeastOneOption;

  /// No description provided for @noPermissionManageFields.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para gestionar campos de perfil.'**
  String get noPermissionManageFields;

  /// No description provided for @manageRolesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Perfiles'**
  String get manageRolesTitle;

  /// No description provided for @confirmDeletionRole.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Eliminación'**
  String get confirmDeletionRole;

  /// No description provided for @confirmDeleteRole.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar el perfil \"{roleName}\"?'**
  String confirmDeleteRole(String roleName);

  /// No description provided for @warningDeleteRole.
  ///
  /// In es, this message translates to:
  /// **'Atención: Esto puede afectar a usuarios que tienen este perfil asignado.'**
  String get warningDeleteRole;

  /// No description provided for @noPermissionDeleteRoles.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para eliminar perfiles'**
  String get noPermissionDeleteRoles;

  /// No description provided for @roleDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Perfil eliminado con éxito'**
  String get roleDeletedSuccessfully;

  /// No description provided for @errorDeletingRole.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar perfil: {error}'**
  String errorDeletingRole(String error);

  /// No description provided for @noPermissionManageRoles.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar perfiles y permisos.'**
  String get noPermissionManageRoles;

  /// No description provided for @errorLoadingRoles.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar perfiles: {error}'**
  String errorLoadingRoles(String error);

  /// No description provided for @noRolesFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún perfil encontrado. ¡Crea el primero!'**
  String get noRolesFound;

  /// No description provided for @manageUserRolesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Perfiles de Usuarios'**
  String get manageUserRolesTitle;

  /// No description provided for @noPermissionAccessPage.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para acceder a esta página'**
  String get noPermissionAccessPage;

  /// No description provided for @errorCheckingPermissions.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar permisos: {error}'**
  String errorCheckingPermissions(String error);

  /// No description provided for @errorLoadingRolesData.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar perfiles: {error}'**
  String errorLoadingRolesData(String error);

  /// No description provided for @errorLoadingUsers.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar usuarios: {error}'**
  String errorLoadingUsers(String error);

  /// No description provided for @noPermissionUpdateRoles.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para actualizar perfiles.'**
  String get noPermissionUpdateRoles;

  /// No description provided for @cannotChangeOwnRole.
  ///
  /// In es, this message translates to:
  /// **'No es posible cambiar tu propio perfil'**
  String get cannotChangeOwnRole;

  /// No description provided for @userRoleUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Perfil del usuario actualizado con éxito'**
  String get userRoleUpdatedSuccessfully;

  /// No description provided for @errorUpdatingRole.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar perfil: {error}'**
  String errorUpdatingRole(String error);

  /// No description provided for @selectUserRole.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar perfil del usuario'**
  String get selectUserRole;

  /// No description provided for @manageCoursesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Cursos'**
  String get manageCoursesTitle;

  /// No description provided for @noPermissionManageCourses.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar cursos.'**
  String get noPermissionManageCourses;

  /// No description provided for @errorLoadingCourses.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar cursos: {error}'**
  String errorLoadingCourses(String error);

  /// No description provided for @published.
  ///
  /// In es, this message translates to:
  /// **'Publicados'**
  String get published;

  /// No description provided for @drafts.
  ///
  /// In es, this message translates to:
  /// **'Borradores'**
  String get drafts;

  /// No description provided for @archived.
  ///
  /// In es, this message translates to:
  /// **'Archivados'**
  String get archived;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @unpublish.
  ///
  /// In es, this message translates to:
  /// **'Despublicar'**
  String get unpublish;

  /// No description provided for @publish.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get publish;

  /// No description provided for @publishCourse.
  ///
  /// In es, this message translates to:
  /// **'Publicar curso'**
  String get publishCourse;

  /// No description provided for @makeCourseVisibleToAllUsers.
  ///
  /// In es, this message translates to:
  /// **'Hacer el curso visible para todos los usuarios'**
  String get makeCourseVisibleToAllUsers;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
