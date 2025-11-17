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
  /// **'Seleccionar Fecha'**
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
  /// **'Error al cargar ministerios'**
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
  /// **'Error al cargar grupos: {error}'**
  String errorLoadingGroups(Object error);

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
  /// **'Gestionar Vídeos'**
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
  /// **'Crear Ministerios'**
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
  /// **'No se encontraron ministerios disponibles'**
  String get noMinistriesAvailable;

  /// No description provided for @unnamedMinistry.
  ///
  /// In es, this message translates to:
  /// **'Ministerio sin nombre'**
  String get unnamedMinistry;

  /// No description provided for @deleteGroup.
  ///
  /// In es, this message translates to:
  /// **'Eliminar grupo'**
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
  /// **'Grupo eliminado con éxito'**
  String groupDeletedSuccessfully(String groupName);

  /// No description provided for @errorDeletingGroup.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar grupo: {error}'**
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
  /// **'Campo Obligatorio'**
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
  /// **'Estadísticas de Escalas'**
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
  /// **'Vídeos'**
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
  /// **'Error al cargar eventos'**
  String errorLoadingEvents(String error);

  /// No description provided for @calendars.
  ///
  /// In es, this message translates to:
  /// **'Calendarios'**
  String get calendars;

  /// No description provided for @globalView.
  ///
  /// In es, this message translates to:
  /// **'Global'**
  String get globalView;

  /// No description provided for @allActivities.
  ///
  /// In es, this message translates to:
  /// **'Todas las Actividades'**
  String get allActivities;

  /// No description provided for @noActivitiesForThisDay.
  ///
  /// In es, this message translates to:
  /// **'No hay actividades para este día'**
  String get noActivitiesForThisDay;

  /// No description provided for @events.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
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
  /// **'Vídeos Recientes'**
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
  /// **'Información adicional'**
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
  /// **'Informaciones guardadas con éxito!'**
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
  /// **'Pendiente'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptado'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
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
  /// **'Anuncios'**
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
  /// **'En persona'**
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
  /// **'Lecciones'**
  String lessons(int count);

  /// No description provided for @minutes.
  ///
  /// In es, this message translates to:
  /// **'minutos'**
  String minutes(int count);

  /// No description provided for @hours.
  ///
  /// In es, this message translates to:
  /// **'horas'**
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
  /// **'Connect'**
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
  /// **'Anuncio eliminado correctamente'**
  String get announcementDeletedSuccessfully;

  /// No description provided for @errorDeletingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el anuncio: {error}'**
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
  /// **'Culto: {cultName}'**
  String cult(Object cultName);

  /// No description provided for @publishedOn.
  ///
  /// In es, this message translates to:
  /// **'Publicado el:'**
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
  /// **'Error al actualizar el enlace'**
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
  String couldNotOpenLink(String url);

  /// No description provided for @errorOpeningLink.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir el enlace'**
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
  /// **'Eliminar entrada'**
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
  /// **'Copiar link del evento'**
  String get copyEventLink;

  /// No description provided for @linkCopied.
  ///
  /// In es, this message translates to:
  /// **'Link copiado!'**
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
  /// **'Error al cargar entradas'**
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
  /// **'{count} cultos'**
  String cults(Object count);

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
  /// **'Error al publicar comentario: {error}'**
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
  /// **'Error al eliminar comentario: {error}'**
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
  /// **'{count} Lecciones'**
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
  /// **'Gestionar Perfiles Familiares'**
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
  /// **'SuperUser'**
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
  /// **'Error al guardar info.'**
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
  /// **'Descripción (opcional)'**
  String get descriptionOptional;

  /// No description provided for @backgroundImageOptional.
  ///
  /// In es, this message translates to:
  /// **'Imagen de Fondo (Opcional)'**
  String get backgroundImageOptional;

  /// No description provided for @tapToAddImage.
  ///
  /// In es, this message translates to:
  /// **'Toca para añadir una imagen'**
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
  /// **'Error al cargar datos'**
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
  /// **'Por favor ingresa un URL válido'**
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
  /// **'Cultos programados'**
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
  /// **'¿Estás seguro de que quieres eliminar el campo \'{fieldName}\'?'**
  String confirmDeleteField(String fieldName);

  /// No description provided for @fieldDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Campo eliminado con éxito'**
  String get fieldDeletedSuccessfully;

  /// No description provided for @errorDeletingField.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar campo: {error}'**
  String errorDeletingField(String error);

  /// No description provided for @pleaseAddAtLeastOneOption.
  ///
  /// In es, this message translates to:
  /// **'Por favor, añade al menos una opción para el campo de selección.'**
  String get pleaseAddAtLeastOneOption;

  /// No description provided for @noPermissionManageFields.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar campos.'**
  String get noPermissionManageFields;

  /// No description provided for @manageRolesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Perfiles'**
  String get manageRolesTitle;

  /// No description provided for @confirmDeletionRole.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Eliminación de Rol'**
  String get confirmDeletionRole;

  /// No description provided for @confirmDeleteRole.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar el rol \"{roleName}\"? Todas las asignaciones asociadas serán eliminadas.'**
  String confirmDeleteRole(String roleName);

  /// No description provided for @warningDeleteRole.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer y afectará a todos los usuarios con este rol.'**
  String get warningDeleteRole;

  /// No description provided for @noPermissionDeleteRoles.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para eliminar perfiles'**
  String get noPermissionDeleteRoles;

  /// No description provided for @roleDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Rol \"{roleName}\" eliminado exitosamente'**
  String roleDeletedSuccessfully(String roleName);

  /// No description provided for @errorDeletingRole.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar rol: {error}'**
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
  /// **'No tienes permiso para acceder a esta página.'**
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
  /// **'No es posible cambiar tu propio rol'**
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
  /// **'Publicado'**
  String get published;

  /// No description provided for @drafts.
  ///
  /// In es, this message translates to:
  /// **'Borradores'**
  String get drafts;

  /// No description provided for @archived.
  ///
  /// In es, this message translates to:
  /// **'Archivado'**
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

  /// No description provided for @createProfileField.
  ///
  /// In es, this message translates to:
  /// **'Crear Campo de Perfil'**
  String get createProfileField;

  /// No description provided for @editProfileField.
  ///
  /// In es, this message translates to:
  /// **'Editar Campo de Perfil'**
  String get editProfileField;

  /// No description provided for @fieldActive.
  ///
  /// In es, this message translates to:
  /// **'Campo Activo'**
  String get fieldActive;

  /// No description provided for @showThisFieldInProfile.
  ///
  /// In es, this message translates to:
  /// **'Mostrar este campo en el perfil'**
  String get showThisFieldInProfile;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get saveChanges;

  /// No description provided for @fieldCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Campo creado con éxito'**
  String get fieldCreatedSuccessfully;

  /// No description provided for @fieldUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Campo actualizado con éxito'**
  String get fieldUpdatedSuccessfully;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In es, this message translates to:
  /// **'Usuario no autenticado'**
  String get userNotAuthenticated;

  /// No description provided for @noProfileFieldsDefined.
  ///
  /// In es, this message translates to:
  /// **'No hay campos de perfil definidos'**
  String get noProfileFieldsDefined;

  /// No description provided for @fieldType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Campo'**
  String get fieldType;

  /// No description provided for @text.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get text;

  /// No description provided for @number.
  ///
  /// In es, this message translates to:
  /// **'Número'**
  String get number;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @select.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ({count})'**
  String select(Object count);

  /// No description provided for @donationSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Donaciones'**
  String get donationSettings;

  /// No description provided for @enableDonations.
  ///
  /// In es, this message translates to:
  /// **'Habilitar donaciones'**
  String get enableDonations;

  /// No description provided for @showDonationSection.
  ///
  /// In es, this message translates to:
  /// **'Mostrar sección de donaciones en la aplicación'**
  String get showDonationSection;

  /// No description provided for @bankName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Banco'**
  String get bankName;

  /// No description provided for @accountNumber.
  ///
  /// In es, this message translates to:
  /// **'Número de Cuenta'**
  String get accountNumber;

  /// No description provided for @clabe.
  ///
  /// In es, this message translates to:
  /// **'CLABE (México)'**
  String get clabe;

  /// No description provided for @paypalMeLink.
  ///
  /// In es, this message translates to:
  /// **'Enlace PayPal.Me'**
  String get paypalMeLink;

  /// No description provided for @mercadoPagoAlias.
  ///
  /// In es, this message translates to:
  /// **'Alias Mercado Pago'**
  String get mercadoPagoAlias;

  /// No description provided for @stripePublishableKey.
  ///
  /// In es, this message translates to:
  /// **'Clave Publicable de Stripe'**
  String get stripePublishableKey;

  /// No description provided for @donationInformation.
  ///
  /// In es, this message translates to:
  /// **'Información de Donación'**
  String get donationInformation;

  /// No description provided for @saveDonationSettings.
  ///
  /// In es, this message translates to:
  /// **'Guardar Configuración de Donaciones'**
  String get saveDonationSettings;

  /// No description provided for @donationSettingsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Configuración de donaciones actualizada con éxito.'**
  String get donationSettingsUpdated;

  /// No description provided for @errorUpdatingDonationSettings.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar la configuración de donaciones: {error}'**
  String errorUpdatingDonationSettings(Object error);

  /// No description provided for @enterBankName.
  ///
  /// In es, this message translates to:
  /// **'Ingrese el nombre del banco'**
  String get enterBankName;

  /// No description provided for @enterAccountNumber.
  ///
  /// In es, this message translates to:
  /// **'Ingrese el número de cuenta'**
  String get enterAccountNumber;

  /// No description provided for @enterClabe.
  ///
  /// In es, this message translates to:
  /// **'Ingrese la CLABE'**
  String get enterClabe;

  /// No description provided for @enterPaypalMeLink.
  ///
  /// In es, this message translates to:
  /// **'Ingrese el enlace de PayPal.Me'**
  String get enterPaypalMeLink;

  /// No description provided for @enterMercadoPagoAlias.
  ///
  /// In es, this message translates to:
  /// **'Ingrese el alias de Mercado Pago'**
  String get enterMercadoPagoAlias;

  /// No description provided for @enterStripePublishableKey.
  ///
  /// In es, this message translates to:
  /// **'Ingrese la clave publicable de Stripe'**
  String get enterStripePublishableKey;

  /// No description provided for @cnpj.
  ///
  /// In es, this message translates to:
  /// **'CNPJ'**
  String get cnpj;

  /// No description provided for @cpf.
  ///
  /// In es, this message translates to:
  /// **'CPF'**
  String get cpf;

  /// No description provided for @random.
  ///
  /// In es, this message translates to:
  /// **'Aleatoria'**
  String get random;

  /// No description provided for @filterBy.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por:'**
  String get filterBy;

  /// No description provided for @createNewCourse.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Curso'**
  String get createNewCourse;

  /// No description provided for @noCoursesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron cursos'**
  String get noCoursesFound;

  /// No description provided for @clickToCreateNewCourse.
  ///
  /// In es, this message translates to:
  /// **'Haz clic en el botón \'+\' para crear un nuevo curso'**
  String get clickToCreateNewCourse;

  /// No description provided for @draft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get draft;

  /// No description provided for @featured.
  ///
  /// In es, this message translates to:
  /// **'Destacado'**
  String get featured;

  /// No description provided for @modules.
  ///
  /// In es, this message translates to:
  /// **'{count,plural, =1{1 Módulo}other{{count} Módulos}}'**
  String modules(num count);

  /// No description provided for @optionsFor.
  ///
  /// In es, this message translates to:
  /// **'Opciones para \"{courseTitle}\"'**
  String optionsFor(Object courseTitle);

  /// No description provided for @unpublishCourse.
  ///
  /// In es, this message translates to:
  /// **'Despublicar (volver a borrador)'**
  String get unpublishCourse;

  /// No description provided for @makeCourseInvisible.
  ///
  /// In es, this message translates to:
  /// **'Hacer el curso invisible para los usuarios'**
  String get makeCourseInvisible;

  /// No description provided for @removeFeatured.
  ///
  /// In es, this message translates to:
  /// **'Quitar de destacados'**
  String get removeFeatured;

  /// No description provided for @addFeatured.
  ///
  /// In es, this message translates to:
  /// **'Destacar curso'**
  String get addFeatured;

  /// No description provided for @removeFromFeatured.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la sección de destacados'**
  String get removeFromFeatured;

  /// No description provided for @addToFeatured.
  ///
  /// In es, this message translates to:
  /// **'Mostrar el curso en la sección de destacados'**
  String get addToFeatured;

  /// No description provided for @deleteCourse.
  ///
  /// In es, this message translates to:
  /// **'Eliminar curso'**
  String get deleteCourse;

  /// No description provided for @thisActionIsIrreversible.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no puede ser deshecha'**
  String get thisActionIsIrreversible;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar el curso \"{courseTitle}\"?'**
  String areYouSureYouWantToDelete(Object courseTitle);

  /// No description provided for @irreversibleActionWarning.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible y eliminará todos los módulos, lecciones, materiales y progreso de los usuarios asociados a este curso.'**
  String get irreversibleActionWarning;

  /// No description provided for @courseDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Curso eliminado con éxito'**
  String get courseDeletedSuccessfully;

  /// No description provided for @errorDeletingCourse.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el curso: {error}'**
  String errorDeletingCourse(Object error);

  /// No description provided for @coursePublishedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Curso publicado con éxito'**
  String get coursePublishedSuccessfully;

  /// No description provided for @courseUnpublishedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Curso despublicado con éxito'**
  String get courseUnpublishedSuccessfully;

  /// No description provided for @courseFeaturedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Curso destacado con éxito'**
  String get courseFeaturedSuccessfully;

  /// No description provided for @featuredRemovedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Destacado eliminado con éxito'**
  String get featuredRemovedSuccessfully;

  /// No description provided for @errorUpdatingFeatured.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el destacado: {error}'**
  String errorUpdatingFeatured(Object error);

  /// No description provided for @instructor.
  ///
  /// In es, this message translates to:
  /// **'Instructor'**
  String get instructor;

  /// No description provided for @duration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get duration;

  /// No description provided for @lessonsLabel.
  ///
  /// In es, this message translates to:
  /// **'Lecciones'**
  String get lessonsLabel;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @enroll.
  ///
  /// In es, this message translates to:
  /// **'Inscribirse'**
  String get enroll;

  /// No description provided for @alreadyEnrolled.
  ///
  /// In es, this message translates to:
  /// **'Ya estás inscrito'**
  String get alreadyEnrolled;

  /// No description provided for @courseContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido del Curso'**
  String get courseContent;

  /// No description provided for @lesson.
  ///
  /// In es, this message translates to:
  /// **'Lección'**
  String get lesson;

  /// No description provided for @materials.
  ///
  /// In es, this message translates to:
  /// **'Materiales'**
  String get materials;

  /// No description provided for @comments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get comments;

  /// No description provided for @course.
  ///
  /// In es, this message translates to:
  /// **'Curso'**
  String get course;

  /// No description provided for @markAsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Marcar como completada'**
  String get markAsCompleted;

  /// No description provided for @processing.
  ///
  /// In es, this message translates to:
  /// **'Procesando...'**
  String get processing;

  /// No description provided for @evaluateThisLesson.
  ///
  /// In es, this message translates to:
  /// **'Evaluar esta lección'**
  String get evaluateThisLesson;

  /// No description provided for @averageRating.
  ///
  /// In es, this message translates to:
  /// **'Evaluación media'**
  String get averageRating;

  /// No description provided for @lessonCompleted.
  ///
  /// In es, this message translates to:
  /// **'Lección completada'**
  String get lessonCompleted;

  /// No description provided for @alreadyCompleted.
  ///
  /// In es, this message translates to:
  /// **'Ya has completado esta lección'**
  String get alreadyCompleted;

  /// No description provided for @errorCompletingLesson.
  ///
  /// In es, this message translates to:
  /// **'Error al marcar la lección como completada'**
  String get errorCompletingLesson;

  /// No description provided for @noMaterialsForThisLesson.
  ///
  /// In es, this message translates to:
  /// **'No hay materiales para esta lección'**
  String get noMaterialsForThisLesson;

  /// No description provided for @noCommentsForThisLesson.
  ///
  /// In es, this message translates to:
  /// **'No hay comentarios para esta lección'**
  String get noCommentsForThisLesson;

  /// No description provided for @addYourComment.
  ///
  /// In es, this message translates to:
  /// **'Añade tu comentario...'**
  String get addYourComment;

  /// No description provided for @commentPublished.
  ///
  /// In es, this message translates to:
  /// **'Comentario publicado'**
  String get commentPublished;

  /// No description provided for @loginToComment.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para comentar'**
  String get loginToComment;

  /// No description provided for @rateTheLesson.
  ///
  /// In es, this message translates to:
  /// **'Evalúa la lección'**
  String get rateTheLesson;

  /// No description provided for @ratingSaved.
  ///
  /// In es, this message translates to:
  /// **'Evaluación guardada'**
  String get ratingSaved;

  /// No description provided for @errorSavingRating.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar la evaluación'**
  String get errorSavingRating;

  /// No description provided for @loginToRate.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para evaluar'**
  String get loginToRate;

  /// No description provided for @courseNotFound.
  ///
  /// In es, this message translates to:
  /// **'Curso no encontrado'**
  String get courseNotFound;

  /// No description provided for @courseNotFoundDetails.
  ///
  /// In es, this message translates to:
  /// **'El curso no existe o fue eliminado'**
  String get courseNotFoundDetails;

  /// No description provided for @errorLoadingLessonCount.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar el conteo de lecciones'**
  String get errorLoadingLessonCount;

  /// No description provided for @errorTogglingFavorite.
  ///
  /// In es, this message translates to:
  /// **'Error al cambiar favorito: {error}'**
  String errorTogglingFavorite(Object error);

  /// No description provided for @errorLoadingModules.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar módulos: {error}'**
  String errorLoadingModules(Object error);

  /// No description provided for @noModulesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay módulos disponibles'**
  String get noModulesAvailable;

  /// No description provided for @errorLoadingLessons.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar lecciones: {error}'**
  String errorLoadingLessons(Object error);

  /// No description provided for @noLessonsAvailableInModule.
  ///
  /// In es, this message translates to:
  /// **'No hay lecciones disponibles'**
  String get noLessonsAvailableInModule;

  /// No description provided for @errorEnrolling.
  ///
  /// In es, this message translates to:
  /// **'Error al inscribirse: {error}'**
  String errorEnrolling(Object error);

  /// No description provided for @enrollToAccessLesson.
  ///
  /// In es, this message translates to:
  /// **'Inscríbete al curso para acceder a esta lección'**
  String get enrollToAccessLesson;

  /// No description provided for @noLessonsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay lecciones disponibles en este curso'**
  String get noLessonsAvailable;

  /// No description provided for @loginToEnroll.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para inscribirte'**
  String get loginToEnroll;

  /// No description provided for @enrolledSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Te has inscrito al curso!'**
  String get enrolledSuccess;

  /// No description provided for @startCourse.
  ///
  /// In es, this message translates to:
  /// **'Comenzar Curso'**
  String get startCourse;

  /// No description provided for @continueCourse.
  ///
  /// In es, this message translates to:
  /// **'Continuar Curso'**
  String get continueCourse;

  /// No description provided for @progressWithDetails.
  ///
  /// In es, this message translates to:
  /// **'Progreso: {percentage}% ({completed}/{total})'**
  String progressWithDetails(Object completed, Object percentage, Object total);

  /// No description provided for @instructorLabel.
  ///
  /// In es, this message translates to:
  /// **'Instructor: {name}'**
  String instructorLabel(Object name);

  /// No description provided for @lessonNotFound.
  ///
  /// In es, this message translates to:
  /// **'Lección no encontrada'**
  String get lessonNotFound;

  /// No description provided for @lessonNotFoundDetails.
  ///
  /// In es, this message translates to:
  /// **'No fue posible encontrar la lección solicitada'**
  String get lessonNotFoundDetails;

  /// No description provided for @durationLabel.
  ///
  /// In es, this message translates to:
  /// **'Duración: {duration}'**
  String durationLabel(Object duration);

  /// No description provided for @unmarkAsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Desmarcar como completada'**
  String get unmarkAsCompleted;

  /// No description provided for @lessonUnmarked.
  ///
  /// In es, this message translates to:
  /// **'Lección desmarcada como completada'**
  String get lessonUnmarked;

  /// No description provided for @noVideoAvailable.
  ///
  /// In es, this message translates to:
  /// **'Ningún vídeo disponible'**
  String get noVideoAvailable;

  /// No description provided for @clickToWatchVideo.
  ///
  /// In es, this message translates to:
  /// **'Haz clic para ver el vídeo'**
  String get clickToWatchVideo;

  /// No description provided for @noDescription.
  ///
  /// In es, this message translates to:
  /// **'Sin descripción'**
  String get noDescription;

  /// No description provided for @commentsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Los comentarios están desactivados para esta lección'**
  String get commentsDisabled;

  /// No description provided for @noCommentsYet.
  ///
  /// In es, this message translates to:
  /// **'Ningún comentario aún'**
  String get noCommentsYet;

  /// No description provided for @beTheFirstToComment.
  ///
  /// In es, this message translates to:
  /// **'¡Sé el primero en comentar!'**
  String get beTheFirstToComment;

  /// No description provided for @you.
  ///
  /// In es, this message translates to:
  /// **'Tú'**
  String get you;

  /// No description provided for @reply.
  ///
  /// In es, this message translates to:
  /// **'respuesta'**
  String get reply;

  /// No description provided for @replies.
  ///
  /// In es, this message translates to:
  /// **'respuestas'**
  String get replies;

  /// No description provided for @repliesFunctionality.
  ///
  /// In es, this message translates to:
  /// **'Funcionalidad de respuestas en desarrollo'**
  String get repliesFunctionality;

  /// No description provided for @confirmDeleteComment.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que quieres eliminar este comentario?'**
  String get confirmDeleteComment;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {days} días'**
  String daysAgo(Object days);

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In es, this message translates to:
  /// **'Enlace copiado al portapapeles'**
  String get linkCopiedToClipboard;

  /// No description provided for @open.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get open;

  /// No description provided for @copyLink.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get copyLink;

  /// No description provided for @managePagesTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Páginas'**
  String get managePagesTitle;

  /// No description provided for @noPermissionManagePages.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar páginas personalizadas.'**
  String get noPermissionManagePages;

  /// No description provided for @errorLoadingPages.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar páginas: {error}'**
  String errorLoadingPages(Object error);

  /// No description provided for @noCustomPagesYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay páginas personalizadas.'**
  String get noCustomPagesYet;

  /// No description provided for @tapPlusToCreateFirst.
  ///
  /// In es, this message translates to:
  /// **'Toca el botón + para crear la primera.'**
  String get tapPlusToCreateFirst;

  /// No description provided for @pageWithoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Página sin título'**
  String get pageWithoutTitle;

  /// No description provided for @noPermissionEditPages.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para editar páginas.'**
  String get noPermissionEditPages;

  /// No description provided for @noPermissionCreatePages.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear páginas.'**
  String get noPermissionCreatePages;

  /// No description provided for @createNewPage.
  ///
  /// In es, this message translates to:
  /// **'Crear nueva página'**
  String get createNewPage;

  /// No description provided for @editPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Página'**
  String get editPageTitle;

  /// No description provided for @pageTitle.
  ///
  /// In es, this message translates to:
  /// **'Título de la Página'**
  String get pageTitle;

  /// No description provided for @pageTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Sobre Nosotros'**
  String get pageTitleHint;

  /// No description provided for @appearanceInPageList.
  ///
  /// In es, this message translates to:
  /// **'Apariencia en la Lista de Páginas'**
  String get appearanceInPageList;

  /// No description provided for @visualizationType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Visualización en la Lista'**
  String get visualizationType;

  /// No description provided for @iconAndTitle.
  ///
  /// In es, this message translates to:
  /// **'Ícono y Título'**
  String get iconAndTitle;

  /// No description provided for @coverImage16x9.
  ///
  /// In es, this message translates to:
  /// **'Imagen de Portada (16:9)'**
  String get coverImage16x9;

  /// No description provided for @icon.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get icon;

  /// No description provided for @coverImageLabel.
  ///
  /// In es, this message translates to:
  /// **'Imagen de Portada (16:9)'**
  String get coverImageLabel;

  /// No description provided for @changeImage.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Imagen'**
  String get changeImage;

  /// No description provided for @selectImage.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Imagen'**
  String get selectImage;

  /// No description provided for @pageContentLabel.
  ///
  /// In es, this message translates to:
  /// **'Contenido de la Página'**
  String get pageContentLabel;

  /// No description provided for @typePageContentHere.
  ///
  /// In es, this message translates to:
  /// **'Escribe el contenido de la página aquí...'**
  String get typePageContentHere;

  /// No description provided for @insertImage.
  ///
  /// In es, this message translates to:
  /// **'Insertar Imagen'**
  String get insertImage;

  /// No description provided for @savePage.
  ///
  /// In es, this message translates to:
  /// **'Guardar Página'**
  String get savePage;

  /// No description provided for @pleaseEnterPageTitle.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un título para la página.'**
  String get pleaseEnterPageTitle;

  /// No description provided for @pleaseSelectIcon.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona un icono para la página.'**
  String get pleaseSelectIcon;

  /// No description provided for @pleaseUploadCoverImage.
  ///
  /// In es, this message translates to:
  /// **'Por favor, sube una imagen para la portada.'**
  String get pleaseUploadCoverImage;

  /// No description provided for @errorInsertingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al insertar imagen: {error}'**
  String errorInsertingImage(Object error);

  /// No description provided for @coverImageUploaded.
  ///
  /// In es, this message translates to:
  /// **'¡Imagen de portada cargada!'**
  String get coverImageUploaded;

  /// No description provided for @errorUploadingCoverImage.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar imagen de portada: {error}'**
  String errorUploadingCoverImage(Object error);

  /// No description provided for @pageSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Página guardada con éxito!'**
  String get pageSavedSuccessfully;

  /// No description provided for @errorSavingPage.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar página: {error}'**
  String errorSavingPage(Object error);

  /// No description provided for @discardChanges.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar Cambios?'**
  String get discardChanges;

  /// No description provided for @unsavedChangesConfirm.
  ///
  /// In es, this message translates to:
  /// **'Tienes cambios sin guardar. ¿Quieres salir de todos modos?'**
  String get unsavedChangesConfirm;

  /// No description provided for @discardAndExit.
  ///
  /// In es, this message translates to:
  /// **'Descartar y Salir'**
  String get discardAndExit;

  /// No description provided for @restoreDraft.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar Borrador?'**
  String get restoreDraft;

  /// No description provided for @unsavedChangesFound.
  ///
  /// In es, this message translates to:
  /// **'Encontramos cambios no guardados. ¿Quieres restaurarlos?'**
  String get unsavedChangesFound;

  /// No description provided for @discardDraft.
  ///
  /// In es, this message translates to:
  /// **'Descartar Borrador'**
  String get discardDraft;

  /// No description provided for @restore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @imageUploadFailed.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar la imagen.'**
  String get imageUploadFailed;

  /// No description provided for @errorLoadingPage.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar página: {error}'**
  String errorLoadingPage(Object error);

  /// No description provided for @editSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Sección'**
  String get editSectionTitle;

  /// No description provided for @createNewSection.
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Sección'**
  String get createNewSection;

  /// No description provided for @deleteSection.
  ///
  /// In es, this message translates to:
  /// **'Eliminar sección'**
  String get deleteSection;

  /// No description provided for @sectionTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título de la Sección'**
  String get sectionTitleLabel;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un título'**
  String get pleaseEnterTitle;

  /// No description provided for @pagesIncludedInSection.
  ///
  /// In es, this message translates to:
  /// **'Páginas Incluidas en esta Sección'**
  String get pagesIncludedInSection;

  /// No description provided for @noCustomPagesFound.
  ///
  /// In es, this message translates to:
  /// **'Ninguna página personalizada encontrada para seleccionar.'**
  String get noCustomPagesFound;

  /// No description provided for @pageWithoutTitleShort.
  ///
  /// In es, this message translates to:
  /// **'Página sin título ({id}...)'**
  String pageWithoutTitleShort(Object id);

  /// No description provided for @selectAtLeastOnePage.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos una página.'**
  String get selectAtLeastOnePage;

  /// No description provided for @errorSavingSection.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar sección: {error}'**
  String errorSavingSection(Object error);

  /// No description provided for @deleteSectionConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar Sección?'**
  String get deleteSectionConfirm;

  /// No description provided for @deleteSectionMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar la sección \"{title}\"? Esta acción no se puede deshacer.'**
  String deleteSectionMessage(Object title);

  /// No description provided for @errorDeleting.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar'**
  String errorDeleting(String error);

  /// No description provided for @sectionNameUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Nombre de la sección actualizado con éxito!'**
  String get sectionNameUpdated;

  /// No description provided for @typeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo: {type}'**
  String typeLabel(Object type);

  /// No description provided for @sectionName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Sección'**
  String get sectionName;

  /// No description provided for @sectionLabel.
  ///
  /// In es, this message translates to:
  /// **'Sección: {title}'**
  String sectionLabel(Object title);

  /// No description provided for @hideWhenNoContent.
  ///
  /// In es, this message translates to:
  /// **'Ocultar sección cuando no haya contenido:'**
  String get hideWhenNoContent;

  /// No description provided for @visibilityConfigUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Configuración de visibilidad actualizada!'**
  String get visibilityConfigUpdated;

  /// No description provided for @errorUpdatingConfig.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar configuración: {error}'**
  String errorUpdatingConfig(Object error);

  /// No description provided for @sectionCannotBeEditedHere.
  ///
  /// In es, this message translates to:
  /// **'Esta sección no se puede editar aquí.'**
  String get sectionCannotBeEditedHere;

  /// No description provided for @createNewPageSection.
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Sección de Páginas'**
  String get createNewPageSection;

  /// No description provided for @noPermissionManageHomeSections.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar las secciones de la pantalla de inicio.'**
  String get noPermissionManageHomeSections;

  /// No description provided for @editName.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre'**
  String get editName;

  /// No description provided for @hiddenWhenEmpty.
  ///
  /// In es, this message translates to:
  /// **'Oculta cuando vacía'**
  String get hiddenWhenEmpty;

  /// No description provided for @alwaysVisible.
  ///
  /// In es, this message translates to:
  /// **'Siempre visible'**
  String get alwaysVisible;

  /// No description provided for @liveStreamLabel.
  ///
  /// In es, this message translates to:
  /// **'En Vivo'**
  String get liveStreamLabel;

  /// No description provided for @donations.
  ///
  /// In es, this message translates to:
  /// **'Donaciones'**
  String get donations;

  /// No description provided for @onlineCourses.
  ///
  /// In es, this message translates to:
  /// **'Cursos Online'**
  String get onlineCourses;

  /// No description provided for @customPages.
  ///
  /// In es, this message translates to:
  /// **'Páginas Personalizadas'**
  String get customPages;

  /// No description provided for @unknownSection.
  ///
  /// In es, this message translates to:
  /// **'Sección Desconocida'**
  String get unknownSection;

  /// No description provided for @servicesGridObsolete.
  ///
  /// In es, this message translates to:
  /// **'Cuadrícula de Servicios (Obsoleto)'**
  String get servicesGridObsolete;

  /// No description provided for @liveStreamType.
  ///
  /// In es, this message translates to:
  /// **'Transmisión en vivo'**
  String get liveStreamType;

  /// No description provided for @courses.
  ///
  /// In es, this message translates to:
  /// **'Cursos'**
  String get courses;

  /// No description provided for @pageList.
  ///
  /// In es, this message translates to:
  /// **'Lista de Páginas'**
  String get pageList;

  /// No description provided for @sectionWillBeDisplayed.
  ///
  /// In es, this message translates to:
  /// **'La sección se mostrará siempre, aunque no haya contenido.'**
  String get sectionWillBeDisplayed;

  /// No description provided for @errorVerifyingPermission.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar permiso: {error}'**
  String errorVerifyingPermission(Object error);

  /// No description provided for @configureAvailability.
  ///
  /// In es, this message translates to:
  /// **'Configurar Disponibilidad'**
  String get configureAvailability;

  /// No description provided for @consultationSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Consultas'**
  String get consultationSettings;

  /// No description provided for @noPermissionManageAvailability.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar la disponibilidad.'**
  String get noPermissionManageAvailability;

  /// No description provided for @errorLoadingAvailability.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar disponibilidad: {error}'**
  String errorLoadingAvailability(Object error);

  /// No description provided for @confirmDeleteAllTimeSlots.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar todas las franjas de horario?'**
  String get confirmDeleteAllTimeSlots;

  /// No description provided for @deleteSlot.
  ///
  /// In es, this message translates to:
  /// **'Eliminar franja'**
  String get deleteSlot;

  /// No description provided for @unavailableForConsultations.
  ///
  /// In es, this message translates to:
  /// **'No disponible para consultas'**
  String get unavailableForConsultations;

  /// No description provided for @dayMarkedAvailableAddTimeSlots.
  ///
  /// In es, this message translates to:
  /// **'Día marcado como disponible, añade franjas de horario'**
  String get dayMarkedAvailableAddTimeSlots;

  /// No description provided for @weekOf.
  ///
  /// In es, this message translates to:
  /// **'Semana del {date}'**
  String weekOf(Object date);

  /// No description provided for @copyToNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Copiar a la próxima semana'**
  String get copyToNextWeek;

  /// No description provided for @counselingConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Configuración de Asesoramiento'**
  String get counselingConfiguration;

  /// No description provided for @counselingDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración del Asesoramiento'**
  String get counselingDuration;

  /// No description provided for @configureCounselingDuration.
  ///
  /// In es, this message translates to:
  /// **'Configura cuánto tiempo durará cada Asesoramiento'**
  String get configureCounselingDuration;

  /// No description provided for @intervalBetweenConsultations.
  ///
  /// In es, this message translates to:
  /// **'Intervalo entre Consultas'**
  String get intervalBetweenConsultations;

  /// No description provided for @configureRestTimeBetweenConsultations.
  ///
  /// In es, this message translates to:
  /// **'Configura cuánto tiempo de descanso habrá entre consultas'**
  String get configureRestTimeBetweenConsultations;

  /// No description provided for @configurationSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada con éxito'**
  String get configurationSavedSuccessfully;

  /// No description provided for @dayUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Día actualizado con éxito'**
  String get dayUpdatedSuccessfully;

  /// No description provided for @errorCopying.
  ///
  /// In es, this message translates to:
  /// **'Error al copiar: {error}'**
  String errorCopying(Object error);

  /// No description provided for @addTimeSlots.
  ///
  /// In es, this message translates to:
  /// **'Añadir franjas de horario'**
  String get addTimeSlots;

  /// No description provided for @editAvailability.
  ///
  /// In es, this message translates to:
  /// **'Editar disponibilidad'**
  String get editAvailability;

  /// No description provided for @manageAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Anuncios'**
  String get manageAnnouncements;

  /// No description provided for @active.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get active;

  /// No description provided for @inactiveExpired.
  ///
  /// In es, this message translates to:
  /// **'Inactivos/Vencidos'**
  String get inactiveExpired;

  /// No description provided for @regular.
  ///
  /// In es, this message translates to:
  /// **'Regulares'**
  String get regular;

  /// No description provided for @confirmAnnouncementDeletion.
  ///
  /// In es, this message translates to:
  /// **'Confirmar eliminación'**
  String get confirmAnnouncementDeletion;

  /// No description provided for @confirmDeleteAnnouncementMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar este anuncio? Esta acción no se puede deshacer.'**
  String get confirmDeleteAnnouncementMessage;

  /// No description provided for @noActiveAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'No hay anuncios activos'**
  String get noActiveAnnouncements;

  /// No description provided for @noInactiveExpiredAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'No hay anuncios inactivos/vencidos'**
  String get noInactiveExpiredAnnouncements;

  /// No description provided for @managedEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos Administrados'**
  String get managedEvents;

  /// No description provided for @update.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get update;

  /// No description provided for @noPermissionManageEventAttendance.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar la asistencia de eventos.'**
  String get noPermissionManageEventAttendance;

  /// No description provided for @manageAttendance.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Asistencia'**
  String get manageAttendance;

  /// No description provided for @noEventsMinistries.
  ///
  /// In es, this message translates to:
  /// **'de ministerios'**
  String get noEventsMinistries;

  /// No description provided for @noEventsGroups.
  ///
  /// In es, this message translates to:
  /// **'de grupos'**
  String get noEventsGroups;

  /// No description provided for @noEventsMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos {filter}'**
  String noEventsMessage(Object filter);

  /// No description provided for @eventsYouAdministerWillAppearHere.
  ///
  /// In es, this message translates to:
  /// **'Los eventos que administras aparecerán aquí'**
  String get eventsYouAdministerWillAppearHere;

  /// No description provided for @noTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get noTitle;

  /// No description provided for @ministry.
  ///
  /// In es, this message translates to:
  /// **'Ministerio'**
  String get ministry;

  /// No description provided for @group.
  ///
  /// In es, this message translates to:
  /// **'Grupo'**
  String get group;

  /// No description provided for @noPermissionManageVideos.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar vídeos.'**
  String get noPermissionManageVideos;

  /// No description provided for @noVideosFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún vídeo encontrado'**
  String get noVideosFound;

  /// No description provided for @deleteVideo.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Vídeo'**
  String get deleteVideo;

  /// No description provided for @deleteVideoConfirmation.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar el vídeo \"{title}\"?'**
  String deleteVideoConfirmation(Object title);

  /// No description provided for @videoDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Vídeo eliminado con éxito'**
  String get videoDeletedSuccessfully;

  /// No description provided for @errorDeletingVideo.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar vídeo: {error}'**
  String errorDeletingVideo(Object error);

  /// No description provided for @minutesAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {minutes} minutos'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {hours} horas'**
  String hoursAgo(Object hours);

  /// No description provided for @createAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Crear Anuncio'**
  String get createAnnouncement;

  /// No description provided for @errorVerifyingPermissionAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar permiso: {error}'**
  String errorVerifyingPermissionAnnouncement(Object error);

  /// No description provided for @noPermissionCreateAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear anuncios.'**
  String get noPermissionCreateAnnouncements;

  /// No description provided for @errorSelectingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen: {error}'**
  String errorSelectingImage(Object error);

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @announcementCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Anuncio creado correctamente'**
  String get announcementCreatedSuccessfully;

  /// No description provided for @errorCreatingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al crear anuncio: {error}'**
  String errorCreatingAnnouncement(Object error);

  /// No description provided for @addImage.
  ///
  /// In es, this message translates to:
  /// **'Agregar imagen'**
  String get addImage;

  /// No description provided for @recommended16x9.
  ///
  /// In es, this message translates to:
  /// **'Recomendado: formato 16:9'**
  String get recommended16x9;

  /// No description provided for @announcementTitle.
  ///
  /// In es, this message translates to:
  /// **'Título del Anuncio'**
  String get announcementTitle;

  /// No description provided for @enterClearConciseTitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce un título claro y conciso'**
  String get enterClearConciseTitle;

  /// No description provided for @pleasEnterTitle.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un título'**
  String get pleasEnterTitle;

  /// No description provided for @provideAnnouncementDetails.
  ///
  /// In es, this message translates to:
  /// **'Proporciona detalles sobre el anuncio'**
  String get provideAnnouncementDetails;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa una descripción'**
  String get pleaseEnterDescription;

  /// No description provided for @announcementExpirationDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha del anuncio/expiración'**
  String get announcementExpirationDate;

  /// No description provided for @optionalSelectDate.
  ///
  /// In es, this message translates to:
  /// **'Opcional: Selecciona una fecha'**
  String get optionalSelectDate;

  /// No description provided for @pleaseSelectAnnouncementImage.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona una imagen para el anuncio'**
  String get pleaseSelectAnnouncementImage;

  /// No description provided for @publishAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Publicar Anuncio'**
  String get publishAnnouncement;

  /// No description provided for @createEvent.
  ///
  /// In es, this message translates to:
  /// **'CREAR EVENTO'**
  String get createEvent;

  /// No description provided for @upcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximas'**
  String get upcoming;

  /// No description provided for @thisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get thisMonth;

  /// No description provided for @noEventsFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún evento encontrado'**
  String get noEventsFound;

  /// No description provided for @tryAnotherFilterOrCreateEvent.
  ///
  /// In es, this message translates to:
  /// **'Prueba otro filtro o crea un nuevo evento'**
  String get tryAnotherFilterOrCreateEvent;

  /// No description provided for @trySelectingAnotherFilter.
  ///
  /// In es, this message translates to:
  /// **'Prueba seleccionando otro filtro'**
  String get trySelectingAnotherFilter;

  /// No description provided for @noLocation.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación'**
  String get noLocation;

  /// No description provided for @tickets.
  ///
  /// In es, this message translates to:
  /// **'Entradas'**
  String get tickets;

  /// No description provided for @seeDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver Detalles'**
  String get seeDetails;

  /// No description provided for @videoSections.
  ///
  /// In es, this message translates to:
  /// **'Secciones de Vídeos'**
  String get videoSections;

  /// No description provided for @reorderSections.
  ///
  /// In es, this message translates to:
  /// **'Reordenar secciones'**
  String get reorderSections;

  /// No description provided for @saveOrder.
  ///
  /// In es, this message translates to:
  /// **'Guardar orden'**
  String get saveOrder;

  /// No description provided for @dragSectionsToReorder.
  ///
  /// In es, this message translates to:
  /// **'Arrastra las secciones para reordenarlas'**
  String get dragSectionsToReorder;

  /// No description provided for @noSectionCreated.
  ///
  /// In es, this message translates to:
  /// **'Ninguna sección creada'**
  String get noSectionCreated;

  /// No description provided for @createFirstSection.
  ///
  /// In es, this message translates to:
  /// **'Crear Primera Sección'**
  String get createFirstSection;

  /// No description provided for @dragToReorderPressWhenDone.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para reordenar. Presiona el botón concluido cuando termines.'**
  String get dragToReorderPressWhenDone;

  /// No description provided for @defaultSectionNotEditable.
  ///
  /// In es, this message translates to:
  /// **'Sección por defecto (no editable)'**
  String get defaultSectionNotEditable;

  /// No description provided for @allVideos.
  ///
  /// In es, this message translates to:
  /// **'Todos los vídeos'**
  String get allVideos;

  /// No description provided for @defaultSection.
  ///
  /// In es, this message translates to:
  /// **'• Sección por defecto'**
  String get defaultSection;

  /// No description provided for @editSection.
  ///
  /// In es, this message translates to:
  /// **'Editar sección'**
  String get editSection;

  /// No description provided for @newSection.
  ///
  /// In es, this message translates to:
  /// **'Nueva Sección'**
  String get newSection;

  /// No description provided for @mostRecent.
  ///
  /// In es, this message translates to:
  /// **'Más recientes'**
  String get mostRecent;

  /// No description provided for @mostPopular.
  ///
  /// In es, this message translates to:
  /// **'Más populares'**
  String get mostPopular;

  /// No description provided for @custom.
  ///
  /// In es, this message translates to:
  /// **'Personalizada'**
  String get custom;

  /// No description provided for @recentVideosCannotBeReordered.
  ///
  /// In es, this message translates to:
  /// **'La sección \"Vídeos Recientes\" no puede ser reordenada'**
  String get recentVideosCannotBeReordered;

  /// No description provided for @deleteVideoSection.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Sección'**
  String get deleteVideoSection;

  /// No description provided for @confirmDeleteSection.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar la sección \"{title}\"?'**
  String confirmDeleteSection(Object title);

  /// No description provided for @sectionDeleted.
  ///
  /// In es, this message translates to:
  /// **'Sección eliminada'**
  String get sectionDeleted;

  /// No description provided for @sendPushNotifications.
  ///
  /// In es, this message translates to:
  /// **'Enviar Notificaciones Push'**
  String get sendPushNotifications;

  /// No description provided for @errorVerifyingPermissionNotification.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar permiso: {error}'**
  String errorVerifyingPermissionNotification(Object error);

  /// No description provided for @accessNotAuthorized.
  ///
  /// In es, this message translates to:
  /// **'Acceso no autorizado'**
  String get accessNotAuthorized;

  /// No description provided for @noPermissionSendNotifications.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para enviar notificaciones push.'**
  String get noPermissionSendNotifications;

  /// No description provided for @sendNotification.
  ///
  /// In es, this message translates to:
  /// **'Enviar notificación'**
  String get sendNotification;

  /// No description provided for @title.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get title;

  /// No description provided for @message.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get message;

  /// No description provided for @pleaseEnterMessage.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un mensaje'**
  String get pleaseEnterMessage;

  /// No description provided for @recipients.
  ///
  /// In es, this message translates to:
  /// **'Destinatarios'**
  String get recipients;

  /// No description provided for @allMembers.
  ///
  /// In es, this message translates to:
  /// **'Todos los miembros'**
  String get allMembers;

  /// No description provided for @membersOfMinistry.
  ///
  /// In es, this message translates to:
  /// **'Miembros de un ministerio'**
  String get membersOfMinistry;

  /// No description provided for @selectMinistry.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ministerio'**
  String get selectMinistry;

  /// No description provided for @pleaseSelectMinistry.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona un ministerio'**
  String get pleaseSelectMinistry;

  /// No description provided for @selectMembers.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar miembros ({selected}/{total})'**
  String selectMembers(Object selected, Object total);

  /// No description provided for @selectAll.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Todos'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In es, this message translates to:
  /// **'Deseleccionar todos'**
  String get deselectAll;

  /// No description provided for @membersOfGroup.
  ///
  /// In es, this message translates to:
  /// **'Miembros de un grupo'**
  String get membersOfGroup;

  /// No description provided for @selectGroup.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar grupo'**
  String get selectGroup;

  /// No description provided for @pleaseSelectGroup.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona un grupo'**
  String get pleaseSelectGroup;

  /// No description provided for @receiveThisNotificationToo.
  ///
  /// In es, this message translates to:
  /// **'Recibir también esta notificación'**
  String get receiveThisNotificationToo;

  /// No description provided for @sendNotificationButton.
  ///
  /// In es, this message translates to:
  /// **'ENVIAR NOTIFICACIÓN'**
  String get sendNotificationButton;

  /// No description provided for @noPermissionSendNotificationsSnack.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para enviar notificaciones.'**
  String get noPermissionSendNotificationsSnack;

  /// No description provided for @noUsersMatchCriteria.
  ///
  /// In es, this message translates to:
  /// **'No hay usuarios que cumplan con los criterios seleccionados'**
  String get noUsersMatchCriteria;

  /// No description provided for @errorSending.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar: {error}'**
  String errorSending(Object error);

  /// No description provided for @notificationSentSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'✅ Notificación enviada con éxito'**
  String get notificationSentSuccessfully;

  /// No description provided for @notificationSentPartially.
  ///
  /// In es, this message translates to:
  /// **'⚠️ Notificación enviada parcialmente'**
  String get notificationSentPartially;

  /// No description provided for @sentTo.
  ///
  /// In es, this message translates to:
  /// **'Enviada a {count} usuarios'**
  String sentTo(Object count);

  /// No description provided for @failedTo.
  ///
  /// In es, this message translates to:
  /// **'Falló para {count} usuarios'**
  String failedTo(Object count);

  /// No description provided for @noPermissionDeleteMinistries.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para eliminar ministerios'**
  String get noPermissionDeleteMinistries;

  /// No description provided for @errorText.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get errorText;

  /// No description provided for @confirmDeleteMinistry.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar el ministerio \"{ministryName}\" de esta franja horaria? Todas las asignaciones asociadas serán eliminadas.'**
  String confirmDeleteMinistry(String ministryName);

  /// No description provided for @errorDeletingMinistry.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar ministerio: {error}'**
  String errorDeletingMinistry(String error);

  /// No description provided for @noPermissionDeleteGroups.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para eliminar grupos'**
  String get noPermissionDeleteGroups;

  /// No description provided for @confirmDeleteGroup.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar el grupo \"{name}\"? Esta acción no se puede deshacer.'**
  String confirmDeleteGroup(Object name);

  /// No description provided for @kidsAdministration.
  ///
  /// In es, this message translates to:
  /// **'Administración Kids'**
  String get kidsAdministration;

  /// No description provided for @attendance.
  ///
  /// In es, this message translates to:
  /// **'Asistencia'**
  String get attendance;

  /// No description provided for @reload.
  ///
  /// In es, this message translates to:
  /// **'Recargar'**
  String get reload;

  /// No description provided for @attendanceChart.
  ///
  /// In es, this message translates to:
  /// **'Gráfico de Asistencia (pendiente)'**
  String get attendanceChart;

  /// No description provided for @weeklyBirthdays.
  ///
  /// In es, this message translates to:
  /// **'Cumpleañeros de la Semana'**
  String get weeklyBirthdays;

  /// No description provided for @birthdayCarousel.
  ///
  /// In es, this message translates to:
  /// **'Carrusel de Cumpleañeros (pendiente)'**
  String get birthdayCarousel;

  /// No description provided for @family.
  ///
  /// In es, this message translates to:
  /// **'Familia'**
  String get family;

  /// No description provided for @visitor.
  ///
  /// In es, this message translates to:
  /// **'Visitante'**
  String get visitor;

  /// No description provided for @rooms.
  ///
  /// In es, this message translates to:
  /// **'Salas'**
  String get rooms;

  /// No description provided for @checkin.
  ///
  /// In es, this message translates to:
  /// **'Check-in'**
  String get checkin;

  /// No description provided for @absenceRegisteredSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Ausencia registrada con éxito'**
  String get absenceRegisteredSuccessfully;

  /// No description provided for @errorRegisteringAttendance.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar asistencia: {error}'**
  String errorRegisteringAttendance(Object error);

  /// No description provided for @searchParticipants.
  ///
  /// In es, this message translates to:
  /// **'Buscar participantes'**
  String get searchParticipants;

  /// No description provided for @confirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get confirmed;

  /// No description provided for @present.
  ///
  /// In es, this message translates to:
  /// **'Presentes: {count}'**
  String present(Object count);

  /// No description provided for @absent.
  ///
  /// In es, this message translates to:
  /// **'Ausentes'**
  String get absent;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get add;

  /// No description provided for @noMembersFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún miembro encontrado en este grupo/ministerio.'**
  String get noMembersFound;

  /// No description provided for @confirmedStatus.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get confirmedStatus;

  /// No description provided for @presentStatus.
  ///
  /// In es, this message translates to:
  /// **'Presente'**
  String get presentStatus;

  /// No description provided for @absentStatus.
  ///
  /// In es, this message translates to:
  /// **'Ausente'**
  String get absentStatus;

  /// No description provided for @errorSearchingUsers.
  ///
  /// In es, this message translates to:
  /// **'Error al buscar usuarios: {error}'**
  String errorSearchingUsers(Object error);

  /// No description provided for @participantAddedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Participante añadido con éxito'**
  String get participantAddedSuccessfully;

  /// No description provided for @errorAddingParticipant.
  ///
  /// In es, this message translates to:
  /// **'Error al añadir participante: {error}'**
  String errorAddingParticipant(Object error);

  /// No description provided for @addParticipant.
  ///
  /// In es, this message translates to:
  /// **'Agregar participante'**
  String get addParticipant;

  /// No description provided for @searchUserByName.
  ///
  /// In es, this message translates to:
  /// **'Buscar usuario por nombre'**
  String get searchUserByName;

  /// No description provided for @typeAtLeastTwoCharacters.
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos 2 caracteres para buscar'**
  String get typeAtLeastTwoCharacters;

  /// No description provided for @noResultsFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún resultado encontrado para \"{query}\"'**
  String noResultsFound(Object query);

  /// No description provided for @tryAnotherName.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otro nombre o apellido'**
  String get tryAnotherName;

  /// No description provided for @recentUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios recientes:'**
  String get recentUsers;

  /// No description provided for @createNewCult.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Culto'**
  String get createNewCult;

  /// No description provided for @cultName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Culto'**
  String get cultName;

  /// No description provided for @startTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio:'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In es, this message translates to:
  /// **'Hora de fin:'**
  String get endTime;

  /// No description provided for @endTimeMustBeAfterStart.
  ///
  /// In es, this message translates to:
  /// **'La hora de fin debe ser posterior a la hora de inicio'**
  String get endTimeMustBeAfterStart;

  /// No description provided for @pleaseEnterCultName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un nombre para el culto'**
  String get pleaseEnterCultName;

  /// No description provided for @noPermissionCreateLocations.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear ubicaciones'**
  String get noPermissionCreateLocations;

  /// No description provided for @noCultsFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron cultos'**
  String get noCultsFound;

  /// No description provided for @createFirstCult.
  ///
  /// In es, this message translates to:
  /// **'Crear Primer Culto'**
  String get createFirstCult;

  /// No description provided for @location.
  ///
  /// In es, this message translates to:
  /// **'Localización'**
  String get location;

  /// No description provided for @selectLocation.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar localización'**
  String get selectLocation;

  /// No description provided for @addNewLocation.
  ///
  /// In es, this message translates to:
  /// **'Añadir nueva ubicación'**
  String get addNewLocation;

  /// No description provided for @locationName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del local'**
  String get locationName;

  /// No description provided for @street.
  ///
  /// In es, this message translates to:
  /// **'Calle'**
  String get street;

  /// No description provided for @complement.
  ///
  /// In es, this message translates to:
  /// **'Complemento'**
  String get complement;

  /// No description provided for @neighborhood.
  ///
  /// In es, this message translates to:
  /// **'Barrio'**
  String get neighborhood;

  /// No description provided for @city.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get city;

  /// No description provided for @state.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get state;

  /// No description provided for @postalCode.
  ///
  /// In es, this message translates to:
  /// **'CP'**
  String get postalCode;

  /// No description provided for @country.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get country;

  /// No description provided for @saveThisLocation.
  ///
  /// In es, this message translates to:
  /// **'Guardar esta ubicación para uso futuro'**
  String get saveThisLocation;

  /// No description provided for @createCult.
  ///
  /// In es, this message translates to:
  /// **'Crear Culto'**
  String get createCult;

  /// No description provided for @noUpcomingCults.
  ///
  /// In es, this message translates to:
  /// **'No hay cultos próximos'**
  String get noUpcomingCults;

  /// No description provided for @noAvailableCults.
  ///
  /// In es, this message translates to:
  /// **'No hay cultos disponibles'**
  String get noAvailableCults;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In es, this message translates to:
  /// **'El nombre no puede estar vacío'**
  String get nameCannotBeEmpty;

  /// No description provided for @documentsExistButCouldNotProcess.
  ///
  /// In es, this message translates to:
  /// **'Existen documentos, pero no pudieron ser procesados. {message}'**
  String documentsExistButCouldNotProcess(Object message);

  /// No description provided for @noPermissionCreateMinistries.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para crear ministerios.'**
  String get noPermissionCreateMinistries;

  /// No description provided for @ministryCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Ministerio creado con éxito!'**
  String get ministryCreatedSuccessfully;

  /// No description provided for @errorCreatingMinistry.
  ///
  /// In es, this message translates to:
  /// **'Error al crear ministerio: {error}'**
  String errorCreatingMinistry(Object error);

  /// No description provided for @noPermissionCreateMinistriesLong.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear ministerios.'**
  String get noPermissionCreateMinistriesLong;

  /// No description provided for @ministryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Ministerio'**
  String get ministryName;

  /// No description provided for @enterMinistryName.
  ///
  /// In es, this message translates to:
  /// **'Introduce el nombre del ministerio'**
  String get enterMinistryName;

  /// No description provided for @pleaseEnterMinistryName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un nombre para el ministerio'**
  String get pleaseEnterMinistryName;

  /// No description provided for @ministryDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get ministryDescription;

  /// No description provided for @describeMinistryPurpose.
  ///
  /// In es, this message translates to:
  /// **'Describe el propósito y actividades del ministerio'**
  String get describeMinistryPurpose;

  /// No description provided for @administrators.
  ///
  /// In es, this message translates to:
  /// **'Administradores'**
  String get administrators;

  /// No description provided for @selectAdministrators.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Administradores'**
  String get selectAdministrators;

  /// No description provided for @searchUsers.
  ///
  /// In es, this message translates to:
  /// **'Buscar usuarios...'**
  String get searchUsers;

  /// No description provided for @noUsersFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún usuario encontrado'**
  String get noUsersFound;

  /// No description provided for @selectedAdministrators.
  ///
  /// In es, this message translates to:
  /// **'Administradores seleccionados:'**
  String get selectedAdministrators;

  /// No description provided for @noAdministratorsSelected.
  ///
  /// In es, this message translates to:
  /// **'Ningún administrador seleccionado'**
  String get noAdministratorsSelected;

  /// No description provided for @creating.
  ///
  /// In es, this message translates to:
  /// **'Creando...'**
  String get creating;

  /// No description provided for @charactersRemaining.
  ///
  /// In es, this message translates to:
  /// **'{count} caracteres restantes'**
  String charactersRemaining(int count);

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @cancelConsultation.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Consulta'**
  String get cancelConsultation;

  /// No description provided for @sureToCancel.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cancelar esta consulta?'**
  String get sureToCancel;

  /// No description provided for @yesCancelConsultation.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get yesCancelConsultation;

  /// No description provided for @consultationCancelledSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Consulta cancelada con éxito'**
  String get consultationCancelledSuccessfully;

  /// No description provided for @myAppointments.
  ///
  /// In es, this message translates to:
  /// **'Mis Citas'**
  String get myAppointments;

  /// No description provided for @requestAppointment.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Cita'**
  String get requestAppointment;

  /// No description provided for @pastorAvailability.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad del Pastor'**
  String get pastorAvailability;

  /// No description provided for @noAppointmentsScheduled.
  ///
  /// In es, this message translates to:
  /// **'No hay citas programadas'**
  String get noAppointmentsScheduled;

  /// No description provided for @scheduleFirstAppointment.
  ///
  /// In es, this message translates to:
  /// **'Programa tu primera cita'**
  String get scheduleFirstAppointment;

  /// No description provided for @scheduleAppointment.
  ///
  /// In es, this message translates to:
  /// **'Programar Cita'**
  String get scheduleAppointment;

  /// No description provided for @cancelled.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get cancelled;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get completed;

  /// No description provided for @withPreposition.
  ///
  /// In es, this message translates to:
  /// **'con'**
  String get withPreposition;

  /// No description provided for @requestedOn.
  ///
  /// In es, this message translates to:
  /// **'Solicitada el'**
  String get requestedOn;

  /// No description provided for @scheduledFor.
  ///
  /// In es, this message translates to:
  /// **'Programada para'**
  String get scheduledFor;

  /// No description provided for @reason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get reason;

  /// No description provided for @contactPastor.
  ///
  /// In es, this message translates to:
  /// **'Contactar Pastor'**
  String get contactPastor;

  /// No description provided for @cancelAppointment.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Cita'**
  String get cancelAppointment;

  /// No description provided for @noPermissionRespondPrivatePrayers.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para responder oraciones privadas'**
  String get noPermissionRespondPrivatePrayers;

  /// No description provided for @noPermissionCreatePredefinedMessages.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear mensajes predefinidos'**
  String get noPermissionCreatePredefinedMessages;

  /// No description provided for @noPermissionManagePrivatePrayers.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar oraciones privadas'**
  String get noPermissionManagePrivatePrayers;

  /// No description provided for @prayerRequestAcceptedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de oración aceptada con éxito'**
  String get prayerRequestAcceptedSuccessfully;

  /// No description provided for @pendingPrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones Pendientes'**
  String get pendingPrayers;

  /// No description provided for @acceptedPrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones Aceptadas'**
  String get acceptedPrayers;

  /// No description provided for @rejectedPrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones Rechazadas'**
  String get rejectedPrayers;

  /// No description provided for @noPendingPrayers.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración pendiente'**
  String get noPendingPrayers;

  /// No description provided for @noAcceptedPrayers.
  ///
  /// In es, this message translates to:
  /// **'No hay oraciones aceptadas'**
  String get noAcceptedPrayers;

  /// No description provided for @noRejectedPrayers.
  ///
  /// In es, this message translates to:
  /// **'No hay oraciones rechazadas'**
  String get noRejectedPrayers;

  /// No description provided for @requestedBy.
  ///
  /// In es, this message translates to:
  /// **'Solicitada por'**
  String get requestedBy;

  /// No description provided for @acceptPrayer.
  ///
  /// In es, this message translates to:
  /// **'Aceptar Oración'**
  String get acceptPrayer;

  /// No description provided for @rejectPrayer.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Oración'**
  String get rejectPrayer;

  /// No description provided for @respondToPrayer.
  ///
  /// In es, this message translates to:
  /// **'Responder a Oración'**
  String get respondToPrayer;

  /// No description provided for @viewResponse.
  ///
  /// In es, this message translates to:
  /// **'Ver Respuesta'**
  String get viewResponse;

  /// No description provided for @predefinedMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes Predefinidos'**
  String get predefinedMessages;

  /// No description provided for @createPredefinedMessage.
  ///
  /// In es, this message translates to:
  /// **'Crear mensaje predefinido'**
  String get createPredefinedMessage;

  /// No description provided for @prayerStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Oraciones'**
  String get prayerStats;

  /// No description provided for @totalRequests.
  ///
  /// In es, this message translates to:
  /// **'Total de Solicitudes'**
  String get totalRequests;

  /// No description provided for @acceptedRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes Aceptadas'**
  String get acceptedRequests;

  /// No description provided for @rejectedRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes Rechazadas'**
  String get rejectedRequests;

  /// No description provided for @responseRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Respuesta'**
  String get responseRate;

  /// No description provided for @userInformation.
  ///
  /// In es, this message translates to:
  /// **'Información de Usuarios'**
  String get userInformation;

  /// No description provided for @unauthorizedAccess.
  ///
  /// In es, this message translates to:
  /// **'Acceso no autorizado'**
  String get unauthorizedAccess;

  /// No description provided for @noPermissionViewUserInfo.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para ver información de usuarios.'**
  String get noPermissionViewUserInfo;

  /// No description provided for @totalUsers.
  ///
  /// In es, this message translates to:
  /// **'Total de Usuarios'**
  String get totalUsers;

  /// No description provided for @activeUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios Activos'**
  String get activeUsers;

  /// No description provided for @inactiveUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios Inactivos'**
  String get inactiveUsers;

  /// No description provided for @userDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles del Usuario'**
  String get userDetails;

  /// No description provided for @viewDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver detalles'**
  String get viewDetails;

  /// No description provided for @lastActive.
  ///
  /// In es, this message translates to:
  /// **'Última actividad'**
  String get lastActive;

  /// No description provided for @joinedOn.
  ///
  /// In es, this message translates to:
  /// **'Entró el'**
  String get joinedOn;

  /// No description provided for @role.
  ///
  /// In es, this message translates to:
  /// **'Función: {role}'**
  String role(Object role);

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @inactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get inactive;

  /// No description provided for @servicesStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Servicios'**
  String get servicesStatistics;

  /// No description provided for @searchService.
  ///
  /// In es, this message translates to:
  /// **'Buscar servicio...'**
  String get searchService;

  /// No description provided for @users.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get users;

  /// No description provided for @totalInvitations.
  ///
  /// In es, this message translates to:
  /// **'Total de Invitaciones'**
  String get totalInvitations;

  /// No description provided for @acceptedInvitations.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones Aceptadas'**
  String get acceptedInvitations;

  /// No description provided for @rejectedInvitations.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones Rechazadas'**
  String get rejectedInvitations;

  /// No description provided for @totalAttendances.
  ///
  /// In es, this message translates to:
  /// **'Total de asistencias'**
  String get totalAttendances;

  /// No description provided for @totalAbsences.
  ///
  /// In es, this message translates to:
  /// **'Total de ausencias'**
  String get totalAbsences;

  /// No description provided for @acceptanceRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Aceptación'**
  String get acceptanceRate;

  /// No description provided for @attendanceRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Asistencia'**
  String get attendanceRate;

  /// No description provided for @sortBy.
  ///
  /// In es, this message translates to:
  /// **'Ordenar por'**
  String get sortBy;

  /// No description provided for @invitations.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones'**
  String get invitations;

  /// No description provided for @acceptances.
  ///
  /// In es, this message translates to:
  /// **'Aceptaciones'**
  String get acceptances;

  /// No description provided for @attendances.
  ///
  /// In es, this message translates to:
  /// **'Asistencias'**
  String get attendances;

  /// No description provided for @ascending.
  ///
  /// In es, this message translates to:
  /// **'Ascendente'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In es, this message translates to:
  /// **'Descendente'**
  String get descending;

  /// No description provided for @dateFilter.
  ///
  /// In es, this message translates to:
  /// **'Filtro de Fecha'**
  String get dateFilter;

  /// No description provided for @startDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha inicial'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha final'**
  String get endDate;

  /// No description provided for @applyFilter.
  ///
  /// In es, this message translates to:
  /// **'Aplicar Filtro'**
  String get applyFilter;

  /// No description provided for @clearFilter.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtro'**
  String get clearFilter;

  /// No description provided for @noServicesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron escalas'**
  String get noServicesFound;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @myCounseling.
  ///
  /// In es, this message translates to:
  /// **'Mis Consultas'**
  String get myCounseling;

  /// No description provided for @cancelCounseling.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Consulta'**
  String get cancelCounseling;

  /// No description provided for @confirmCancelCounseling.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cancelar esta consulta?'**
  String get confirmCancelCounseling;

  /// No description provided for @yesCancelCounseling.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get yesCancelCounseling;

  /// No description provided for @counselingCancelledSuccess.
  ///
  /// In es, this message translates to:
  /// **'Consulta cancelada con éxito'**
  String get counselingCancelledSuccess;

  /// No description provided for @loadingPastorInfo.
  ///
  /// In es, this message translates to:
  /// **'Cargando información del pastor...'**
  String get loadingPastorInfo;

  /// No description provided for @unknownPastor.
  ///
  /// In es, this message translates to:
  /// **'Pastor desconocido'**
  String get unknownPastor;

  /// No description provided for @pastor.
  ///
  /// In es, this message translates to:
  /// **'Pastor'**
  String get pastor;

  /// No description provided for @type.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get type;

  /// No description provided for @contact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get contact;

  /// No description provided for @couldNotOpenPhone.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el teléfono'**
  String get couldNotOpenPhone;

  /// No description provided for @call.
  ///
  /// In es, this message translates to:
  /// **'Llamada'**
  String get call;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir WhatsApp'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @whatsApp.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @address.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get address;

  /// No description provided for @notConnected.
  ///
  /// In es, this message translates to:
  /// **'No estás conectado'**
  String get notConnected;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes consultas programadas'**
  String get noUpcomingAppointments;

  /// No description provided for @noCancelledAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes consultas canceladas'**
  String get noCancelledAppointments;

  /// No description provided for @noCompletedAppointments.
  ///
  /// In es, this message translates to:
  /// **'No hay citas completadas'**
  String get noCompletedAppointments;

  /// No description provided for @noAppointmentsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay citas disponibles'**
  String get noAppointmentsAvailable;

  /// No description provided for @viewRequests.
  ///
  /// In es, this message translates to:
  /// **'Ver Solicitudes'**
  String get viewRequests;

  /// No description provided for @editCourse.
  ///
  /// In es, this message translates to:
  /// **'Editar Curso'**
  String get editCourse;

  /// No description provided for @fillCourseInfo.
  ///
  /// In es, this message translates to:
  /// **'Completa la información del curso para ponerlo a disposición de los estudiantes'**
  String get fillCourseInfo;

  /// No description provided for @courseTitle.
  ///
  /// In es, this message translates to:
  /// **'Título del Curso'**
  String get courseTitle;

  /// No description provided for @courseTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Fundamentos de la Biblia'**
  String get courseTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get titleRequired;

  /// No description provided for @descriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Describe el contenido y objetivos del curso...'**
  String get descriptionHint;

  /// No description provided for @descriptionRequired.
  ///
  /// In es, this message translates to:
  /// **'La descripción es obligatoria'**
  String get descriptionRequired;

  /// No description provided for @coverImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen de Portada'**
  String get coverImage;

  /// No description provided for @coverImageDescription.
  ///
  /// In es, this message translates to:
  /// **'Esta imagen se mostrará en la página de detalles del curso'**
  String get coverImageDescription;

  /// No description provided for @tapToChange.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar'**
  String get tapToChange;

  /// No description provided for @recommendedSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño recomendado: 1920x1080'**
  String get recommendedSize;

  /// No description provided for @categoryHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Teología, Discipulado, Liderazgo'**
  String get categoryHint;

  /// No description provided for @categoryRequired.
  ///
  /// In es, this message translates to:
  /// **'La categoría es obligatoria'**
  String get categoryRequired;

  /// No description provided for @instructorName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Instructor'**
  String get instructorName;

  /// No description provided for @instructorNameHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo del instructor'**
  String get instructorNameHint;

  /// No description provided for @instructorRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre del instructor es obligatorio'**
  String get instructorRequired;

  /// No description provided for @courseStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del Curso'**
  String get courseStatus;

  /// No description provided for @allowComments.
  ///
  /// In es, this message translates to:
  /// **'Permitir Comentarios'**
  String get allowComments;

  /// No description provided for @studentsCanComment.
  ///
  /// In es, this message translates to:
  /// **'Los estudiantes podrán comentar en las lecciones'**
  String get studentsCanComment;

  /// No description provided for @updateCourse.
  ///
  /// In es, this message translates to:
  /// **'Actualizar Curso'**
  String get updateCourse;

  /// No description provided for @createCourse.
  ///
  /// In es, this message translates to:
  /// **'Crear Curso'**
  String get createCourse;

  /// No description provided for @courseDurationNote.
  ///
  /// In es, this message translates to:
  /// **'La duración total del curso se calcula automáticamente basándose en la duración de las lecciones.'**
  String get courseDurationNote;

  /// No description provided for @manageModulesAndLessons.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Módulos y Lecciones'**
  String get manageModulesAndLessons;

  /// No description provided for @courseUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Curso actualizado con éxito!'**
  String get courseUpdatedSuccess;

  /// No description provided for @courseCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Curso creado con éxito!'**
  String get courseCreatedSuccess;

  /// No description provided for @addModules.
  ///
  /// In es, this message translates to:
  /// **'Añadir Módulos'**
  String get addModules;

  /// No description provided for @addModulesNow.
  ///
  /// In es, this message translates to:
  /// **'¿Quieres añadir módulos al curso ahora?'**
  String get addModulesNow;

  /// No description provided for @later.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get later;

  /// No description provided for @yesAddNow.
  ///
  /// In es, this message translates to:
  /// **'Sí, añadir ahora'**
  String get yesAddNow;

  /// No description provided for @uploadingImages.
  ///
  /// In es, this message translates to:
  /// **'Subiendo imágenes...'**
  String get uploadingImages;

  /// No description provided for @savingCourse.
  ///
  /// In es, this message translates to:
  /// **'Guardando curso...'**
  String get savingCourse;

  /// No description provided for @addModule.
  ///
  /// In es, this message translates to:
  /// **'Añadir Módulo'**
  String get addModule;

  /// No description provided for @moduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Módulo: {title}'**
  String moduleTitle(Object title);

  /// No description provided for @moduleTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del módulo'**
  String get moduleTitleHint;

  /// No description provided for @moduleTitleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título del módulo es obligatorio'**
  String get moduleTitleRequired;

  /// No description provided for @summary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get summary;

  /// No description provided for @summaryOptional.
  ///
  /// In es, this message translates to:
  /// **'Resumen (Opcional)'**
  String get summaryOptional;

  /// No description provided for @summaryHint.
  ///
  /// In es, this message translates to:
  /// **'Breve descripción del módulo...'**
  String get summaryHint;

  /// No description provided for @moduleCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Módulo creado con éxito!'**
  String get moduleCreatedSuccess;

  /// No description provided for @addLesson.
  ///
  /// In es, this message translates to:
  /// **'Añadir Lección'**
  String get addLesson;

  /// No description provided for @lessonTitle.
  ///
  /// In es, this message translates to:
  /// **'Título de la Lección'**
  String get lessonTitle;

  /// No description provided for @lessonTitleHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la lección'**
  String get lessonTitleHint;

  /// No description provided for @lessonTitleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título de la lección es obligatorio'**
  String get lessonTitleRequired;

  /// No description provided for @lessonDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción de la Lección'**
  String get lessonDescription;

  /// No description provided for @lessonDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Describe el contenido de esta lección...'**
  String get lessonDescriptionHint;

  /// No description provided for @lessonDescriptionRequired.
  ///
  /// In es, this message translates to:
  /// **'La descripción de la lección es obligatoria'**
  String get lessonDescriptionRequired;

  /// No description provided for @durationHint.
  ///
  /// In es, this message translates to:
  /// **'Duración en minutos'**
  String get durationHint;

  /// No description provided for @durationRequired.
  ///
  /// In es, this message translates to:
  /// **'La duración es obligatoria'**
  String get durationRequired;

  /// No description provided for @durationMustBeNumber.
  ///
  /// In es, this message translates to:
  /// **'La duración debe ser un número válido'**
  String get durationMustBeNumber;

  /// No description provided for @videoUrl.
  ///
  /// In es, this message translates to:
  /// **'URL del Vídeo (YouTube o Vimeo)'**
  String get videoUrl;

  /// No description provided for @videoUrlHint.
  ///
  /// In es, this message translates to:
  /// **'URL de YouTube o Vimeo'**
  String get videoUrlHint;

  /// No description provided for @videoUrlRequired.
  ///
  /// In es, this message translates to:
  /// **'La URL del vídeo es obligatoria'**
  String get videoUrlRequired;

  /// No description provided for @lessonCreatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Lección creada con éxito!'**
  String get lessonCreatedSuccess;

  /// No description provided for @noModulesYet.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay módulos en este curso.'**
  String get noModulesYet;

  /// No description provided for @tapAddToCreateFirst.
  ///
  /// In es, this message translates to:
  /// **'Toca \'Añadir Módulo\' para crear el primero.'**
  String get tapAddToCreateFirst;

  /// No description provided for @noLessonsInModule.
  ///
  /// In es, this message translates to:
  /// **'No hay lecciones en este módulo aún.'**
  String get noLessonsInModule;

  /// No description provided for @tapToAddLesson.
  ///
  /// In es, this message translates to:
  /// **'Toca + para añadir una lección.'**
  String get tapToAddLesson;

  /// No description provided for @min.
  ///
  /// In es, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @video.
  ///
  /// In es, this message translates to:
  /// **'Vídeo'**
  String get video;

  /// No description provided for @manageMaterials.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Materiales'**
  String get manageMaterials;

  /// No description provided for @deleteModule.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Módulo'**
  String get deleteModule;

  /// No description provided for @confirmDeleteModule.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar este módulo?'**
  String get confirmDeleteModule;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @yesDelete.
  ///
  /// In es, this message translates to:
  /// **'Sí, eliminar'**
  String get yesDelete;

  /// No description provided for @moduleDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Módulo eliminado con éxito'**
  String get moduleDeletedSuccess;

  /// No description provided for @deleteLesson.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Lección'**
  String get deleteLesson;

  /// No description provided for @confirmDeleteLesson.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar esta lección?'**
  String get confirmDeleteLesson;

  /// No description provided for @lessonDeletedSuccess.
  ///
  /// In es, this message translates to:
  /// **'Lección eliminada con éxito'**
  String get lessonDeletedSuccess;

  /// No description provided for @reorderModules.
  ///
  /// In es, this message translates to:
  /// **'Reordenar Módulos'**
  String get reorderModules;

  /// No description provided for @reorderLessons.
  ///
  /// In es, this message translates to:
  /// **'Reordenar Lecciones'**
  String get reorderLessons;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get done;

  /// No description provided for @dragToReorder.
  ///
  /// In es, this message translates to:
  /// **'Arrastra para reordenar'**
  String get dragToReorder;

  /// No description provided for @orderUpdatedSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Orden actualizado con éxito!'**
  String get orderUpdatedSuccess;

  /// No description provided for @loadingCourse.
  ///
  /// In es, this message translates to:
  /// **'Cargando curso...'**
  String get loadingCourse;

  /// No description provided for @savingModule.
  ///
  /// In es, this message translates to:
  /// **'Guardando módulo...'**
  String get savingModule;

  /// No description provided for @savingLesson.
  ///
  /// In es, this message translates to:
  /// **'Guardando lección...'**
  String get savingLesson;

  /// No description provided for @errorLoadingFields.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los campos: {error}'**
  String errorLoadingFields(Object error);

  /// No description provided for @required.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get required;

  /// No description provided for @fieldName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Campo'**
  String get fieldName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un nombre'**
  String get pleaseEnterName;

  /// No description provided for @selectFieldType.
  ///
  /// In es, this message translates to:
  /// **'Selección'**
  String get selectFieldType;

  /// No description provided for @newOption.
  ///
  /// In es, this message translates to:
  /// **'Nueva Opción'**
  String get newOption;

  /// No description provided for @enterOption.
  ///
  /// In es, this message translates to:
  /// **'Introduce una opción...'**
  String get enterOption;

  /// No description provided for @optionAlreadyAdded.
  ///
  /// In es, this message translates to:
  /// **'Esta opción ya fue añadida.'**
  String get optionAlreadyAdded;

  /// No description provided for @noOptionsAddedYet.
  ///
  /// In es, this message translates to:
  /// **'Ninguna opción añadida aún.'**
  String get noOptionsAddedYet;

  /// No description provided for @usersMustFillField.
  ///
  /// In es, this message translates to:
  /// **'Los usuarios deben rellenar este campo'**
  String get usersMustFillField;

  /// No description provided for @copyToPreviousWeek.
  ///
  /// In es, this message translates to:
  /// **'Copiar a la semana anterior'**
  String get copyToPreviousWeek;

  /// No description provided for @monday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get sunday;

  /// No description provided for @unavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get unavailable;

  /// No description provided for @available.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @timeSlots.
  ///
  /// In es, this message translates to:
  /// **'{count} franjas horarias'**
  String timeSlots(Object count);

  /// No description provided for @sessionDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración de la Sesión'**
  String get sessionDuration;

  /// No description provided for @breakBetweenSessions.
  ///
  /// In es, this message translates to:
  /// **'Descanso entre Sesiones'**
  String get breakBetweenSessions;

  /// No description provided for @appointmentTypes.
  ///
  /// In es, this message translates to:
  /// **'Tipos de Cita'**
  String get appointmentTypes;

  /// No description provided for @onlineAppointments.
  ///
  /// In es, this message translates to:
  /// **'Citas en Línea'**
  String get onlineAppointments;

  /// No description provided for @inPersonAppointments.
  ///
  /// In es, this message translates to:
  /// **'Citas Presenciales'**
  String get inPersonAppointments;

  /// No description provided for @locationHint.
  ///
  /// In es, this message translates to:
  /// **'Dirección para citas presenciales'**
  String get locationHint;

  /// No description provided for @globalSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración Global'**
  String get globalSettings;

  /// No description provided for @settingsSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada con éxito'**
  String get settingsSavedSuccessfully;

  /// No description provided for @notAvailableForConsultations.
  ///
  /// In es, this message translates to:
  /// **'No disponible para consultas'**
  String get notAvailableForConsultations;

  /// No description provided for @configureAvailabilityForThisDay.
  ///
  /// In es, this message translates to:
  /// **'Configura la disponibilidad para este día'**
  String get configureAvailabilityForThisDay;

  /// No description provided for @thisDayMarkedUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Este día está marcado como no disponible para consultas'**
  String get thisDayMarkedUnavailable;

  /// No description provided for @unavailableDay.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get unavailableDay;

  /// No description provided for @thisDayMarkedAvailable.
  ///
  /// In es, this message translates to:
  /// **'Este día está marcado como disponible para consultas'**
  String get thisDayMarkedAvailable;

  /// No description provided for @timeSlotsSingular.
  ///
  /// In es, this message translates to:
  /// **'Franjas Horarias'**
  String get timeSlotsSingular;

  /// No description provided for @timeSlot.
  ///
  /// In es, this message translates to:
  /// **'Franja {number}'**
  String timeSlot(Object number);

  /// No description provided for @consultationType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de consulta:'**
  String get consultationType;

  /// No description provided for @onlineConsultation.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get onlineConsultation;

  /// No description provided for @inPersonConsultation.
  ///
  /// In es, this message translates to:
  /// **'Presencial'**
  String get inPersonConsultation;

  /// No description provided for @addTimeSlot.
  ///
  /// In es, this message translates to:
  /// **'Añadir Franja Horaria'**
  String get addTimeSlot;

  /// No description provided for @searchUser.
  ///
  /// In es, this message translates to:
  /// **'Buscar usuario'**
  String get searchUser;

  /// No description provided for @enterNameOrEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce nombre o email'**
  String get enterNameOrEmail;

  /// No description provided for @noPermissionAccessThisPage.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para acceder a esta página'**
  String get noPermissionAccessThisPage;

  /// No description provided for @noPermissionChangeRoles.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para cambiar roles'**
  String get noPermissionChangeRoles;

  /// No description provided for @selectRoleToAssign.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el rol para asignar al usuario:'**
  String get selectRoleToAssign;

  /// No description provided for @permissionsAssigned.
  ///
  /// In es, this message translates to:
  /// **'{count} permisos asignados'**
  String permissionsAssigned(Object count);

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editProfile;

  /// No description provided for @deleteRole.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Rol'**
  String get deleteRole;

  /// No description provided for @createNewRole.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Rol'**
  String get createNewRole;

  /// No description provided for @failedDeleteRole.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar rol'**
  String get failedDeleteRole;

  /// No description provided for @editModule.
  ///
  /// In es, this message translates to:
  /// **'Editar Módulo'**
  String get editModule;

  /// No description provided for @moduleUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Módulo actualizado con éxito'**
  String get moduleUpdatedSuccessfully;

  /// No description provided for @sureDeleteModule.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar el módulo \"{title}\"?\n\nEsta acción no se puede deshacer y eliminará todas las lecciones asociadas.'**
  String sureDeleteModule(Object title);

  /// No description provided for @moduleDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Módulo eliminado con éxito'**
  String get moduleDeletedSuccessfully;

  /// No description provided for @moduleNotFound.
  ///
  /// In es, this message translates to:
  /// **'Módulo no encontrado'**
  String get moduleNotFound;

  /// No description provided for @lessonAddedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Lección añadida con éxito'**
  String get lessonAddedSuccessfully;

  /// No description provided for @optionalDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción (Opcional)'**
  String get optionalDescription;

  /// No description provided for @durationMinutes.
  ///
  /// In es, this message translates to:
  /// **'Duración (minutos)'**
  String get durationMinutes;

  /// No description provided for @videoUrlExample.
  ///
  /// In es, this message translates to:
  /// **'Ej: https://www.youtube.com/watch?v=...'**
  String get videoUrlExample;

  /// No description provided for @manageModules.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Módulos'**
  String get manageModules;

  /// No description provided for @finishReorder.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finishReorder;

  /// No description provided for @orderLessons.
  ///
  /// In es, this message translates to:
  /// **'Orden: {order} • {count} lecciones'**
  String orderLessons(Object count, Object order);

  /// No description provided for @editLesson.
  ///
  /// In es, this message translates to:
  /// **'Editar Lección'**
  String get editLesson;

  /// No description provided for @lessonUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Lección actualizada con éxito'**
  String get lessonUpdatedSuccessfully;

  /// No description provided for @sureDeleteLesson.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar la lección \"{title}\"?\n\nEsta acción no se puede deshacer.'**
  String sureDeleteLesson(Object title);

  /// No description provided for @lessonDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Lección eliminada con éxito'**
  String get lessonDeletedSuccessfully;

  /// No description provided for @moduleOrderUpdated.
  ///
  /// In es, this message translates to:
  /// **'Orden de los módulos actualizado'**
  String get moduleOrderUpdated;

  /// No description provided for @lessonOrderUpdated.
  ///
  /// In es, this message translates to:
  /// **'Orden de las lecciones actualizado'**
  String get lessonOrderUpdated;

  /// No description provided for @durationVideo.
  ///
  /// In es, this message translates to:
  /// **'{duration} • Vídeo'**
  String durationVideo(Object duration);

  /// No description provided for @durationVideoMaterials.
  ///
  /// In es, this message translates to:
  /// **'{duration} • Vídeo • Materiales: {count}'**
  String durationVideoMaterials(Object count, Object duration);

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @sureDeleteModuleWithTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar el módulo \"{title}\"?\n\nEsta acción no se puede deshacer y eliminará todas las lecciones asociadas.'**
  String sureDeleteModuleWithTitle(Object title);

  /// No description provided for @sureDeleteLessonWithTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar la lección \"{title}\"?\n\nEsta acción no se puede deshacer.'**
  String sureDeleteLessonWithTitle(Object title);

  /// No description provided for @moduleTitleLabel.
  ///
  /// In es, this message translates to:
  /// **'Título del Módulo'**
  String get moduleTitleLabel;

  /// No description provided for @createNewProfile.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Perfil'**
  String get createNewProfile;

  /// No description provided for @roleName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Rol'**
  String get roleName;

  /// No description provided for @roleNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Líder de Grupo, Editor'**
  String get roleNameHint;

  /// No description provided for @roleNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre del rol es obligatorio.'**
  String get roleNameRequired;

  /// No description provided for @optionalDescriptionRole.
  ///
  /// In es, this message translates to:
  /// **'Descripción (Opcional)'**
  String get optionalDescriptionRole;

  /// No description provided for @roleDescriptionHint.
  ///
  /// In es, this message translates to:
  /// **'Responsabilidades de este rol...'**
  String get roleDescriptionHint;

  /// No description provided for @permissions.
  ///
  /// In es, this message translates to:
  /// **'Permisos'**
  String get permissions;

  /// No description provided for @saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get saving;

  /// No description provided for @createRole.
  ///
  /// In es, this message translates to:
  /// **'Crear Rol'**
  String get createRole;

  /// No description provided for @roleSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Rol guardado con éxito!'**
  String get roleSavedSuccessfully;

  /// No description provided for @errorSavingRole.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar rol.'**
  String get errorSavingRole;

  /// No description provided for @generalAdministration.
  ///
  /// In es, this message translates to:
  /// **'Administración General'**
  String get generalAdministration;

  /// No description provided for @homeConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Configuración Home'**
  String get homeConfiguration;

  /// No description provided for @contentAndEvents.
  ///
  /// In es, this message translates to:
  /// **'Contenido y Eventos'**
  String get contentAndEvents;

  /// No description provided for @community.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get community;

  /// No description provided for @counselingAndPrayer.
  ///
  /// In es, this message translates to:
  /// **'Asesoramiento y Oración'**
  String get counselingAndPrayer;

  /// No description provided for @reportsAndStatistics.
  ///
  /// In es, this message translates to:
  /// **'Informes y Estadísticas'**
  String get reportsAndStatistics;

  /// No description provided for @myKids.
  ///
  /// In es, this message translates to:
  /// **'MyKids (Gestión Infantil)'**
  String get myKids;

  /// No description provided for @others.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get others;

  /// No description provided for @assignUserRoles.
  ///
  /// In es, this message translates to:
  /// **'Asignar Roles a Usuarios'**
  String get assignUserRoles;

  /// No description provided for @manageUsers.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Usuarios'**
  String get manageUsers;

  /// No description provided for @viewUserList.
  ///
  /// In es, this message translates to:
  /// **'Ver Lista de Usuarios'**
  String get viewUserList;

  /// No description provided for @viewUserDetails.
  ///
  /// In es, this message translates to:
  /// **'Ver Detalles de Usuarios'**
  String get viewUserDetails;

  /// No description provided for @manageHomeSections.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Secciones de la Tela Inicial'**
  String get manageHomeSections;

  /// No description provided for @manageCults.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Cultos'**
  String get manageCults;

  /// No description provided for @manageEventTickets.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Entradas de Eventos'**
  String get manageEventTickets;

  /// No description provided for @createEvents.
  ///
  /// In es, this message translates to:
  /// **'Crear Eventos'**
  String get createEvents;

  /// No description provided for @deleteEvents.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Eventos'**
  String get deleteEvents;

  /// No description provided for @manageCourses.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Cursos'**
  String get manageCourses;

  /// No description provided for @createGroup.
  ///
  /// In es, this message translates to:
  /// **'Crear Grupo'**
  String get createGroup;

  /// No description provided for @manageCounselingAvailability.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Disponibilidad para Asesoramiento'**
  String get manageCounselingAvailability;

  /// No description provided for @manageCounselingRequests.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Solicitudes de Asesoramiento'**
  String get manageCounselingRequests;

  /// No description provided for @managePrivatePrayers.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Oraciones Privadas'**
  String get managePrivatePrayers;

  /// No description provided for @assignCultToPrayer.
  ///
  /// In es, this message translates to:
  /// **'Asignar Culto a la Oración'**
  String get assignCultToPrayer;

  /// No description provided for @viewMinistryStats.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de Ministerios'**
  String get viewMinistryStats;

  /// No description provided for @viewGroupStats.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de Grupos'**
  String get viewGroupStats;

  /// No description provided for @viewScheduleStats.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de Escalas'**
  String get viewScheduleStats;

  /// No description provided for @viewCourseStats.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de Cursos'**
  String get viewCourseStats;

  /// No description provided for @viewChurchStatistics.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de la Iglesia'**
  String get viewChurchStatistics;

  /// No description provided for @viewCultStats.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de Cultos'**
  String get viewCultStats;

  /// No description provided for @viewWorkStats.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas de Trabajo'**
  String get viewWorkStats;

  /// No description provided for @manageCheckinRooms.
  ///
  /// In es, this message translates to:
  /// **'Gestionar Salas y Check-in'**
  String get manageCheckinRooms;

  /// No description provided for @manageDonationsConfig.
  ///
  /// In es, this message translates to:
  /// **'Configurar Donaciones'**
  String get manageDonationsConfig;

  /// No description provided for @manageLivestreamConfig.
  ///
  /// In es, this message translates to:
  /// **'Configurar Transmisiones en Vivo'**
  String get manageLivestreamConfig;

  /// No description provided for @lessonsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} lecciones'**
  String lessonsCount(Object count);

  /// No description provided for @averageProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso Medio'**
  String get averageProgress;

  /// No description provided for @averageLessonsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Lecciones Medias Completadas:'**
  String get averageLessonsCompleted;

  /// No description provided for @globalAverageProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso Medio Global:'**
  String get globalAverageProgress;

  /// No description provided for @highestProgress.
  ///
  /// In es, this message translates to:
  /// **'Mayor Progreso'**
  String get highestProgress;

  /// No description provided for @progressPercentage.
  ///
  /// In es, this message translates to:
  /// **'Progreso (%)'**
  String get progressPercentage;

  /// No description provided for @averageLessons.
  ///
  /// In es, this message translates to:
  /// **'Lecciones Medias'**
  String get averageLessons;

  /// No description provided for @totalLessonsHeader.
  ///
  /// In es, this message translates to:
  /// **'Total Lecciones'**
  String get totalLessonsHeader;

  /// No description provided for @allModuleLessonsWillBeDeleted.
  ///
  /// In es, this message translates to:
  /// **'Todas las lecciones de este módulo también serán eliminadas. Esta acción no se puede deshacer.'**
  String get allModuleLessonsWillBeDeleted;

  /// No description provided for @groupName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Grupo'**
  String get groupName;

  /// No description provided for @enterGroupName.
  ///
  /// In es, this message translates to:
  /// **'Introduce el nombre del grupo'**
  String get enterGroupName;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce un nombre'**
  String get pleaseEnterGroupName;

  /// No description provided for @groupDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get groupDescription;

  /// No description provided for @enterGroupDescription.
  ///
  /// In es, this message translates to:
  /// **'Introduce la descripción del grupo'**
  String get enterGroupDescription;

  /// No description provided for @administratorsCanManage.
  ///
  /// In es, this message translates to:
  /// **'Los administradores pueden gestionar el grupo, sus miembros y eventos.'**
  String get administratorsCanManage;

  /// No description provided for @addAdministrators.
  ///
  /// In es, this message translates to:
  /// **'Añadir administradores'**
  String get addAdministrators;

  /// No description provided for @administratorsSelected.
  ///
  /// In es, this message translates to:
  /// **'{count} administradores seleccionados'**
  String administratorsSelected(Object count);

  /// No description provided for @unknownUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario desconocido'**
  String get unknownUser;

  /// No description provided for @autoMemberInfo.
  ///
  /// In es, this message translates to:
  /// **'Al crear un grupo, serás automáticamente miembro y administrador. Podrás personalizar la imagen y otras configuraciones después de la creación.'**
  String get autoMemberInfo;

  /// No description provided for @groupCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Grupo creado con éxito!'**
  String get groupCreatedSuccessfully;

  /// No description provided for @errorCreatingGroup.
  ///
  /// In es, this message translates to:
  /// **'Error al crear grupo: {error}'**
  String errorCreatingGroup(Object error);

  /// No description provided for @noPermissionCreateGroups.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para crear grupos.'**
  String get noPermissionCreateGroups;

  /// No description provided for @noPermissionCreateGroupsLong.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear grupos.'**
  String get noPermissionCreateGroupsLong;

  /// No description provided for @noUsersAvailable.
  ///
  /// In es, this message translates to:
  /// **'Ningún usuario disponible'**
  String get noUsersAvailable;

  /// No description provided for @enterMinistryDescription.
  ///
  /// In es, this message translates to:
  /// **'Introduce la descripción del ministerio'**
  String get enterMinistryDescription;

  /// No description provided for @pleaseEnterMinistryDescription.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce una descripción'**
  String get pleaseEnterMinistryDescription;

  /// No description provided for @administratorsCanManageMinistry.
  ///
  /// In es, this message translates to:
  /// **'Los administradores pueden gestionar el ministerio, sus miembros y eventos.'**
  String get administratorsCanManageMinistry;

  /// No description provided for @autoMemberMinistryInfo.
  ///
  /// In es, this message translates to:
  /// **'Al crear un ministerio, serás automáticamente miembro y administrador. Podrás personalizar la imagen y otras configuraciones después de la creación.'**
  String get autoMemberMinistryInfo;

  /// No description provided for @textFieldType.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get textFieldType;

  /// No description provided for @numberFieldType.
  ///
  /// In es, this message translates to:
  /// **'Número'**
  String get numberFieldType;

  /// No description provided for @dateFieldType.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get dateFieldType;

  /// No description provided for @emailFieldType.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get emailFieldType;

  /// No description provided for @phoneFieldType.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phoneFieldType;

  /// No description provided for @selectionOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones de Selección'**
  String get selectionOptions;

  /// No description provided for @noResultsFoundSimple.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get noResultsFoundSimple;

  /// No description provided for @progress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get progress;

  /// No description provided for @detailedStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas Detalladas'**
  String get detailedStatistics;

  /// No description provided for @enrollments.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones'**
  String get enrollments;

  /// No description provided for @completion.
  ///
  /// In es, this message translates to:
  /// **'Finalización'**
  String get completion;

  /// No description provided for @completionMilestones.
  ///
  /// In es, this message translates to:
  /// **'Hitos de Conclusión'**
  String get completionMilestones;

  /// No description provided for @filterByEnrollmentDate.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por Fecha de Inscripción'**
  String get filterByEnrollmentDate;

  /// No description provided for @clear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get clear;

  /// No description provided for @lessThan1Min.
  ///
  /// In es, this message translates to:
  /// **'Menos de 1 min'**
  String get lessThan1Min;

  /// No description provided for @totalEnrolledPeriod.
  ///
  /// In es, this message translates to:
  /// **'Total de Inscritos (período):'**
  String get totalEnrolledPeriod;

  /// No description provided for @reached25Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaron 25%:'**
  String get reached25Percent;

  /// No description provided for @reached50Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaron 50%:'**
  String get reached50Percent;

  /// No description provided for @reached75Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaron 75%:'**
  String get reached75Percent;

  /// No description provided for @reached90Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzaron 90%:'**
  String get reached90Percent;

  /// No description provided for @completed100Percent.
  ///
  /// In es, this message translates to:
  /// **'Completaron 100%:'**
  String get completed100Percent;

  /// No description provided for @counselingRequestsTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de Asesoramiento'**
  String get counselingRequestsTitle;

  /// No description provided for @noPermissionManageCounselingRequests.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar solicitudes de asesoramiento'**
  String get noPermissionManageCounselingRequests;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Cita confirmada'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cita cancelada'**
  String get appointmentCancelled;

  /// No description provided for @appointmentCompleted.
  ///
  /// In es, this message translates to:
  /// **'Cita completada'**
  String get appointmentCompleted;

  /// No description provided for @errorLabel.
  ///
  /// In es, this message translates to:
  /// **'Error:'**
  String get errorLabel;

  /// No description provided for @noPendingRequests.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes pendientes'**
  String get noPendingRequests;

  /// No description provided for @noConfirmedAppointments.
  ///
  /// In es, this message translates to:
  /// **'No hay citas confirmadas'**
  String get noConfirmedAppointments;

  /// No description provided for @loadingUser.
  ///
  /// In es, this message translates to:
  /// **'Cargando usuario...'**
  String get loadingUser;

  /// No description provided for @callTooltip.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get callTooltip;

  /// No description provided for @whatsAppTooltip.
  ///
  /// In es, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppTooltip;

  /// No description provided for @reasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo:'**
  String get reasonLabel;

  /// No description provided for @noReasonSpecified.
  ///
  /// In es, this message translates to:
  /// **'Ningún motivo especificado'**
  String get noReasonSpecified;

  /// No description provided for @complete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get complete;

  /// No description provided for @appointmentStatus.
  ///
  /// In es, this message translates to:
  /// **'Cita {status}'**
  String appointmentStatus(Object status);

  /// No description provided for @myPrivatePrayers.
  ///
  /// In es, this message translates to:
  /// **'Mis Oraciones Privadas'**
  String get myPrivatePrayers;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @noApprovedPrayers.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración aprobada'**
  String get noApprovedPrayers;

  /// No description provided for @noAnsweredPrayers.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración respondida'**
  String get noAnsweredPrayers;

  /// No description provided for @noPrayers.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración'**
  String get noPrayers;

  /// No description provided for @allPrayerRequestsAttended.
  ///
  /// In es, this message translates to:
  /// **'Todas sus solicitudes de oración han sido atendidas'**
  String get allPrayerRequestsAttended;

  /// No description provided for @noApprovedPrayersWithoutResponse.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración fue aprobada sin respuesta'**
  String get noApprovedPrayersWithoutResponse;

  /// No description provided for @noResponsesFromPastors.
  ///
  /// In es, this message translates to:
  /// **'Aún no ha recibido respuestas de los pastores'**
  String get noResponsesFromPastors;

  /// No description provided for @requestPrivatePrayerFromPastors.
  ///
  /// In es, this message translates to:
  /// **'Solicite oración privada a los pastores'**
  String get requestPrivatePrayerFromPastors;

  /// No description provided for @approved.
  ///
  /// In es, this message translates to:
  /// **'Aprobadas'**
  String get approved;

  /// No description provided for @answered.
  ///
  /// In es, this message translates to:
  /// **'Respondidas'**
  String get answered;

  /// No description provided for @requestPrayer.
  ///
  /// In es, this message translates to:
  /// **'Pedir oración'**
  String get requestPrayer;

  /// No description provided for @errorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar: {error}'**
  String errorLoading(Object error);

  /// No description provided for @loadingError.
  ///
  /// In es, this message translates to:
  /// **'Error cargando más oraciones para tab {tabIndex}: {error}'**
  String loadingError(Object error, Object tabIndex);

  /// No description provided for @privatePrayersTitle.
  ///
  /// In es, this message translates to:
  /// **'Oraciones Privadas'**
  String get privatePrayersTitle;

  /// No description provided for @errorAcceptingRequest.
  ///
  /// In es, this message translates to:
  /// **'Error al aceptar la solicitud'**
  String get errorAcceptingRequest;

  /// No description provided for @errorAcceptingRequestWithDetails.
  ///
  /// In es, this message translates to:
  /// **'Error al aceptar la solicitud: {error}'**
  String errorAcceptingRequestWithDetails(Object error);

  /// No description provided for @loadingEllipsis.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loadingEllipsis;

  /// No description provided for @responded.
  ///
  /// In es, this message translates to:
  /// **'Respondido'**
  String get responded;

  /// No description provided for @requestLabel.
  ///
  /// In es, this message translates to:
  /// **'Solicitud:'**
  String get requestLabel;

  /// No description provided for @yourResponse.
  ///
  /// In es, this message translates to:
  /// **'Tu respuesta:'**
  String get yourResponse;

  /// No description provided for @respondedOn.
  ///
  /// In es, this message translates to:
  /// **'Respondido el {date}'**
  String respondedOn(Object date);

  /// No description provided for @acceptAction.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get acceptAction;

  /// No description provided for @respondAction.
  ///
  /// In es, this message translates to:
  /// **'Responder'**
  String get respondAction;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @prayersOverview.
  ///
  /// In es, this message translates to:
  /// **'Visión General de las Oraciones'**
  String get prayersOverview;

  /// No description provided for @noPendingPrayersMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay oraciones pendientes'**
  String get noPendingPrayersMessage;

  /// No description provided for @allRequestsAttended.
  ///
  /// In es, this message translates to:
  /// **'Todas las solicitudes han sido atendidas'**
  String get allRequestsAttended;

  /// No description provided for @noApprovedPrayersWithoutResponseMessage.
  ///
  /// In es, this message translates to:
  /// **'No hay oraciones aprobadas sin respuesta'**
  String get noApprovedPrayersWithoutResponseMessage;

  /// No description provided for @acceptRequestsToRespond.
  ///
  /// In es, this message translates to:
  /// **'Acepte solicitudes para responder a los hermanos'**
  String get acceptRequestsToRespond;

  /// No description provided for @noAnsweredPrayersMessage.
  ///
  /// In es, this message translates to:
  /// **'No ha respondido a ninguna oración'**
  String get noAnsweredPrayersMessage;

  /// No description provided for @responsesWillAppearHere.
  ///
  /// In es, this message translates to:
  /// **'Sus respuestas aparecerán aquí'**
  String get responsesWillAppearHere;

  /// No description provided for @groupStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Grupos'**
  String get groupStatisticsTitle;

  /// No description provided for @members.
  ///
  /// In es, this message translates to:
  /// **'miembros'**
  String get members;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// No description provided for @noPermissionViewGroupStats.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para visualizar estadísticas de grupos'**
  String get noPermissionViewGroupStats;

  /// No description provided for @filterByDate.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por Fecha'**
  String get filterByDate;

  /// No description provided for @initialDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha inicial'**
  String get initialDate;

  /// No description provided for @finalDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha final'**
  String get finalDate;

  /// No description provided for @totalUniqueMembers.
  ///
  /// In es, this message translates to:
  /// **'Total de Miembros Únicos'**
  String get totalUniqueMembers;

  /// No description provided for @creationDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de creación'**
  String get creationDate;

  /// No description provided for @memberCount.
  ///
  /// In es, this message translates to:
  /// **'{count} miembros'**
  String memberCount(Object count);

  /// No description provided for @errorLoadingMembers.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar miembros'**
  String get errorLoadingMembers;

  /// No description provided for @noMembersInGroup.
  ///
  /// In es, this message translates to:
  /// **'No hay miembros en este grupo'**
  String get noMembersInGroup;

  /// No description provided for @attendancePercentage.
  ///
  /// In es, this message translates to:
  /// **'% Asistencia'**
  String get attendancePercentage;

  /// No description provided for @eventsLabel.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get eventsLabel;

  /// No description provided for @admin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @eventsAttended.
  ///
  /// In es, this message translates to:
  /// **'Eventos Asistidos'**
  String get eventsAttended;

  /// No description provided for @ministryStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Ministerios'**
  String get ministryStatisticsTitle;

  /// No description provided for @noPermissionViewMinistryStats.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para visualizar estadísticas de ministerios'**
  String get noPermissionViewMinistryStats;

  /// No description provided for @noMembersInMinistry.
  ///
  /// In es, this message translates to:
  /// **'No hay miembros en este ministerio'**
  String get noMembersInMinistry;

  /// No description provided for @noHistoryToShow.
  ///
  /// In es, this message translates to:
  /// **'No hay historial de miembros para mostrar'**
  String get noHistoryToShow;

  /// No description provided for @recordsFound.
  ///
  /// In es, this message translates to:
  /// **'Registros encontrados: {count}'**
  String recordsFound(Object count);

  /// No description provided for @exits.
  ///
  /// In es, this message translates to:
  /// **'Salidas'**
  String get exits;

  /// No description provided for @noHistoricalRecords.
  ///
  /// In es, this message translates to:
  /// **'No hay registros históricos para este grupo'**
  String get noHistoricalRecords;

  /// No description provided for @noRecordsOf.
  ///
  /// In es, this message translates to:
  /// **'No hay registros de {filterName}'**
  String noRecordsOf(Object filterName);

  /// No description provided for @currentMembers.
  ///
  /// In es, this message translates to:
  /// **'Miembros actuales'**
  String get currentMembers;

  /// No description provided for @totalEntries.
  ///
  /// In es, this message translates to:
  /// **'Total de entradas'**
  String get totalEntries;

  /// No description provided for @totalExits.
  ///
  /// In es, this message translates to:
  /// **'Total de salidas'**
  String get totalExits;

  /// No description provided for @entriesIn.
  ///
  /// In es, this message translates to:
  /// **'Entradas en {groupName}'**
  String entriesIn(Object groupName);

  /// No description provided for @addedByAdmin.
  ///
  /// In es, this message translates to:
  /// **'Añadidos por admin'**
  String get addedByAdmin;

  /// No description provided for @byRequest.
  ///
  /// In es, this message translates to:
  /// **'Por solicitud'**
  String get byRequest;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @exitsFrom.
  ///
  /// In es, this message translates to:
  /// **'Salidas de {groupName}'**
  String exitsFrom(Object groupName);

  /// No description provided for @removedByAdmin.
  ///
  /// In es, this message translates to:
  /// **'Removidos por admin'**
  String get removedByAdmin;

  /// No description provided for @voluntaryExits.
  ///
  /// In es, this message translates to:
  /// **'Salidas voluntarias'**
  String get voluntaryExits;

  /// No description provided for @exitedStatus.
  ///
  /// In es, this message translates to:
  /// **'Salió'**
  String get exitedStatus;

  /// No description provided for @unknownStatus.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get unknownStatus;

  /// No description provided for @unknownDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha desconocida'**
  String get unknownDate;

  /// No description provided for @addedBy.
  ///
  /// In es, this message translates to:
  /// **'Añadido por'**
  String get addedBy;

  /// No description provided for @administrator.
  ///
  /// In es, this message translates to:
  /// **'Administrador'**
  String get administrator;

  /// No description provided for @mode.
  ///
  /// In es, this message translates to:
  /// **'Modo:'**
  String get mode;

  /// No description provided for @requestAccepted.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada'**
  String get requestAccepted;

  /// No description provided for @acceptedBy.
  ///
  /// In es, this message translates to:
  /// **'Aceptado por:'**
  String get acceptedBy;

  /// No description provided for @rejectedBy.
  ///
  /// In es, this message translates to:
  /// **'Rechazado por:'**
  String get rejectedBy;

  /// No description provided for @exitType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de salida:'**
  String get exitType;

  /// No description provided for @voluntary.
  ///
  /// In es, this message translates to:
  /// **'Voluntaria'**
  String get voluntary;

  /// No description provided for @removed.
  ///
  /// In es, this message translates to:
  /// **'Eliminado'**
  String get removed;

  /// No description provided for @removedBy.
  ///
  /// In es, this message translates to:
  /// **'Eliminado por'**
  String get removedBy;

  /// No description provided for @exitReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo de salida:'**
  String get exitReason;

  /// No description provided for @noEventsToShow.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos para mostrar'**
  String get noEventsToShow;

  /// No description provided for @eventsFound.
  ///
  /// In es, this message translates to:
  /// **'Eventos encontrados: {count}'**
  String eventsFound(Object count);

  /// No description provided for @unknownMinistry.
  ///
  /// In es, this message translates to:
  /// **'Ministerio desconocido'**
  String get unknownMinistry;

  /// No description provided for @eventsInPeriod.
  ///
  /// In es, this message translates to:
  /// **'{count} eventos en el período'**
  String eventsInPeriod(Object count);

  /// No description provided for @event.
  ///
  /// In es, this message translates to:
  /// **'Evento: {eventName}'**
  String event(Object eventName);

  /// No description provided for @locationNotInformed.
  ///
  /// In es, this message translates to:
  /// **'Local no informado'**
  String get locationNotInformed;

  /// No description provided for @registered.
  ///
  /// In es, this message translates to:
  /// **'Registrados: {count}'**
  String registered(Object count);

  /// No description provided for @eventsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} eventos'**
  String eventsCount(Object count);

  /// No description provided for @eventsOf.
  ///
  /// In es, this message translates to:
  /// **'Eventos de {groupName}'**
  String eventsOf(Object groupName);

  /// No description provided for @time.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get time;

  /// No description provided for @registeredCount.
  ///
  /// In es, this message translates to:
  /// **'Registrados: {count}'**
  String registeredCount(Object count);

  /// No description provided for @attendeesCount.
  ///
  /// In es, this message translates to:
  /// **'Asistentes: {count}'**
  String attendeesCount(Object count);

  /// No description provided for @noEventsFor.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos para {date}'**
  String noEventsFor(Object date);

  /// No description provided for @loadingUsers.
  ///
  /// In es, this message translates to:
  /// **'Cargando usuarios...'**
  String get loadingUsers;

  /// No description provided for @registeredUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios Registrados'**
  String get registeredUsers;

  /// No description provided for @confirmedAttendees.
  ///
  /// In es, this message translates to:
  /// **'Asistentes Confirmados'**
  String get confirmedAttendees;

  /// No description provided for @noUsersToShow.
  ///
  /// In es, this message translates to:
  /// **'No hay usuarios para mostrar'**
  String get noUsersToShow;

  /// No description provided for @noRecordsInSelectedDates.
  ///
  /// In es, this message translates to:
  /// **'No hay registros en las fechas seleccionadas'**
  String get noRecordsInSelectedDates;

  /// No description provided for @noEventsInSelectedDates.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos en las fechas seleccionadas'**
  String get noEventsInSelectedDates;

  /// No description provided for @recordsInPeriod.
  ///
  /// In es, this message translates to:
  /// **'{count} registros en el período'**
  String recordsInPeriod(Object count);

  /// No description provided for @scaleStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Escalas'**
  String get scaleStatisticsTitle;

  /// No description provided for @noPermissionViewScaleStats.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para visualizar estadísticas de escalas.'**
  String get noPermissionViewScaleStats;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @viewCults.
  ///
  /// In es, this message translates to:
  /// **'Ver cultos'**
  String get viewCults;

  /// No description provided for @cultsOf.
  ///
  /// In es, this message translates to:
  /// **'Cultos de {serviceName}'**
  String cultsOf(Object serviceName);

  /// No description provided for @noCultsAvailableForService.
  ///
  /// In es, this message translates to:
  /// **'Ningún culto disponible para esta escala'**
  String get noCultsAvailableForService;

  /// No description provided for @courseStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Cursos'**
  String get courseStatisticsTitle;

  /// No description provided for @noPermissionViewCourseStats.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para visualizar estadísticas de cursos.'**
  String get noPermissionViewCourseStats;

  /// No description provided for @noStatisticsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay estadísticas disponibles.'**
  String get noStatisticsAvailable;

  /// No description provided for @errorLoadingStatistics.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar estadísticas: {error}'**
  String errorLoadingStatistics(Object error);

  /// No description provided for @top3CoursesEnrolled.
  ///
  /// In es, this message translates to:
  /// **'Top 3 Cursos (Inscritos):'**
  String get top3CoursesEnrolled;

  /// No description provided for @noCourseToShow.
  ///
  /// In es, this message translates to:
  /// **'Ningún curso para mostrar.'**
  String get noCourseToShow;

  /// No description provided for @detailsScreenNotImplemented.
  ///
  /// In es, this message translates to:
  /// **'Pantalla de detalles aún no implementada.'**
  String get detailsScreenNotImplemented;

  /// No description provided for @enrollmentStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Inscripciones'**
  String get enrollmentStatisticsTitle;

  /// No description provided for @progressStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Progreso'**
  String get progressStatisticsTitle;

  /// No description provided for @completionStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Finalización'**
  String get completionStatisticsTitle;

  /// No description provided for @milestoneStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de Hitos'**
  String get milestoneStatisticsTitle;

  /// No description provided for @searchCourses.
  ///
  /// In es, this message translates to:
  /// **'Buscar cursos...'**
  String get searchCourses;

  /// No description provided for @totalEnrollments.
  ///
  /// In es, this message translates to:
  /// **'Total de Inscripciones:'**
  String get totalEnrollments;

  /// No description provided for @averageEnrollmentsPerCourse.
  ///
  /// In es, this message translates to:
  /// **'Promedio de Inscripciones por Curso'**
  String get averageEnrollmentsPerCourse;

  /// No description provided for @courseWithMostEnrollments.
  ///
  /// In es, this message translates to:
  /// **'Curso con Más Inscripciones'**
  String get courseWithMostEnrollments;

  /// No description provided for @courseWithFewestEnrollments.
  ///
  /// In es, this message translates to:
  /// **'Curso con Menos Inscripciones'**
  String get courseWithFewestEnrollments;

  /// No description provided for @enrollmentsOverTime.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones a lo Largo del Tiempo'**
  String get enrollmentsOverTime;

  /// No description provided for @enrollmentDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Inscripción'**
  String get enrollmentDate;

  /// No description provided for @globalAverageTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo Medio Global:'**
  String get globalAverageTime;

  /// No description provided for @fastestCompletion.
  ///
  /// In es, this message translates to:
  /// **'Conclusión Más Rápida:'**
  String get fastestCompletion;

  /// No description provided for @slowestCompletion.
  ///
  /// In es, this message translates to:
  /// **'Conclusión Más Lenta:'**
  String get slowestCompletion;

  /// No description provided for @completionTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de Finalización'**
  String get completionTime;

  /// No description provided for @completionRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Conclusión'**
  String get completionRate;

  /// No description provided for @reach25Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzan 25% (Media):'**
  String get reach25Percent;

  /// No description provided for @reach50Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzan 50% (Media):'**
  String get reach50Percent;

  /// No description provided for @reach75Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzan 75% (Media):'**
  String get reach75Percent;

  /// No description provided for @reach90Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzan 90% (Media):'**
  String get reach90Percent;

  /// No description provided for @complete100Percent.
  ///
  /// In es, this message translates to:
  /// **'Completan 100%:'**
  String get complete100Percent;

  /// No description provided for @milestonePercentage.
  ///
  /// In es, this message translates to:
  /// **'Porcentaje de Hito'**
  String get milestonePercentage;

  /// No description provided for @studentsReached.
  ///
  /// In es, this message translates to:
  /// **'Estudiantes que Alcanzaron'**
  String get studentsReached;

  /// No description provided for @userNotFound.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get userNotFound;

  /// No description provided for @servicesPerformed.
  ///
  /// In es, this message translates to:
  /// **'Servicios Realizados'**
  String get servicesPerformed;

  /// No description provided for @noConfirmedServicesInMinistry.
  ///
  /// In es, this message translates to:
  /// **'No realizó servicios confirmados en este ministerio'**
  String get noConfirmedServicesInMinistry;

  /// No description provided for @service.
  ///
  /// In es, this message translates to:
  /// **'Servicio: {serviceName}'**
  String service(Object serviceName);

  /// No description provided for @assignedBy.
  ///
  /// In es, this message translates to:
  /// **'Designado por: {pastorName}'**
  String assignedBy(Object pastorName);

  /// No description provided for @notAttendedMinistryEvents.
  ///
  /// In es, this message translates to:
  /// **'No asistió a eventos de este ministerio'**
  String get notAttendedMinistryEvents;

  /// No description provided for @notAttendedGroupEvents.
  ///
  /// In es, this message translates to:
  /// **'No asistió a eventos de este grupo'**
  String get notAttendedGroupEvents;

  /// No description provided for @churchStatisticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de la Iglesia'**
  String get churchStatisticsTitle;

  /// No description provided for @dataNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Datos no disponibles'**
  String get dataNotAvailable;

  /// No description provided for @requestApproved.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aprobada'**
  String get requestApproved;

  /// No description provided for @userNotInAnyGroup.
  ///
  /// In es, this message translates to:
  /// **'El usuario no pertenece a ningún grupo'**
  String get userNotInAnyGroup;

  /// No description provided for @generalStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas Generales'**
  String get generalStatistics;

  /// No description provided for @totalServicesPerformed.
  ///
  /// In es, this message translates to:
  /// **'Total de servicios realizados'**
  String get totalServicesPerformed;

  /// No description provided for @ministryEventsAttended.
  ///
  /// In es, this message translates to:
  /// **'Eventos de ministerio asistidos'**
  String get ministryEventsAttended;

  /// No description provided for @groupEventsAttended.
  ///
  /// In es, this message translates to:
  /// **'Eventos de grupo asistidos'**
  String get groupEventsAttended;

  /// No description provided for @userNotInAnyMinistry.
  ///
  /// In es, this message translates to:
  /// **'El usuario no pertenece a ningún ministerio'**
  String get userNotInAnyMinistry;

  /// No description provided for @statusConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Estado: Confirmado'**
  String get statusConfirmed;

  /// No description provided for @statusPresent.
  ///
  /// In es, this message translates to:
  /// **'Estado: Presente'**
  String get statusPresent;

  /// No description provided for @notAvailable.
  ///
  /// In es, this message translates to:
  /// **'N/D'**
  String get notAvailable;

  /// No description provided for @allMinistries.
  ///
  /// In es, this message translates to:
  /// **'Todos los Ministerios'**
  String get allMinistries;

  /// No description provided for @serviceWithoutName.
  ///
  /// In es, this message translates to:
  /// **'Servicio sin nombre'**
  String get serviceWithoutName;

  /// No description provided for @errorLoadingUserStats.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar estadísticas de usuarios: {error}'**
  String errorLoadingUserStats(Object error);

  /// No description provided for @errorLoadingStats.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar estadísticas: {error}'**
  String errorLoadingStats(Object error);

  /// No description provided for @serviceName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Servicio'**
  String get serviceName;

  /// No description provided for @serviceNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Culto Dominical'**
  String get serviceNameHint;

  /// No description provided for @scales.
  ///
  /// In es, this message translates to:
  /// **'Escalas'**
  String get scales;

  /// No description provided for @noServiceFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún servicio encontrado'**
  String get noServiceFound;

  /// No description provided for @tryAnotherFilter.
  ///
  /// In es, this message translates to:
  /// **'Intenta con otro filtro de búsqueda'**
  String get tryAnotherFilter;

  /// No description provided for @created.
  ///
  /// In es, this message translates to:
  /// **'Creado: {date}'**
  String created(Object date);

  /// No description provided for @invitesSent.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones enviadas'**
  String get invitesSent;

  /// No description provided for @globalSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen Global'**
  String get globalSummary;

  /// No description provided for @absences.
  ///
  /// In es, this message translates to:
  /// **'Ausencias'**
  String get absences;

  /// No description provided for @invites.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones'**
  String get invites;

  /// No description provided for @invitesAccepted.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones aceptadas'**
  String get invitesAccepted;

  /// No description provided for @invitesRejected.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones rechazadas'**
  String get invitesRejected;

  /// No description provided for @finished.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get finished;

  /// No description provided for @errorLoadingCults.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar servicios: {error}'**
  String errorLoadingCults(String error);

  /// No description provided for @cultsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} cultos'**
  String cultsCount(Object count);

  /// No description provided for @userList.
  ///
  /// In es, this message translates to:
  /// **'Lista de usuarios'**
  String get userList;

  /// No description provided for @generalSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen General'**
  String get generalSummary;

  /// No description provided for @enrollmentSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Inscripciones'**
  String get enrollmentSummary;

  /// No description provided for @progressSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen General de Progreso'**
  String get progressSummary;

  /// No description provided for @completionSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen General de Finalización'**
  String get completionSummary;

  /// No description provided for @milestoneSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen General de Hitos'**
  String get milestoneSummary;

  /// No description provided for @coursesWithEnrollments.
  ///
  /// In es, this message translates to:
  /// **'Cursos con Inscripciones:'**
  String get coursesWithEnrollments;

  /// No description provided for @globalCompletionRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de Conclusión Global:'**
  String get globalCompletionRate;

  /// No description provided for @reach100Percent.
  ///
  /// In es, this message translates to:
  /// **'Alcanzan 100% (Media):'**
  String get reach100Percent;

  /// No description provided for @highestCompletionRate.
  ///
  /// In es, this message translates to:
  /// **'Mayor Tasa de Conclusión:'**
  String get highestCompletionRate;

  /// No description provided for @enrolled.
  ///
  /// In es, this message translates to:
  /// **'Inscritos'**
  String get enrolled;

  /// No description provided for @averageTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo Medio'**
  String get averageTime;

  /// No description provided for @progressPercent.
  ///
  /// In es, this message translates to:
  /// **'Progreso (%)'**
  String get progressPercent;

  /// No description provided for @moreThan1Min.
  ///
  /// In es, this message translates to:
  /// **'Más de 1 min'**
  String get moreThan1Min;

  /// No description provided for @searchCourse.
  ///
  /// In es, this message translates to:
  /// **'Buscar curso...'**
  String get searchCourse;

  /// No description provided for @errorLoadingCourseStats.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar estadísticas: {error}'**
  String errorLoadingCourseStats(Object error);

  /// No description provided for @noStatsAvailable.
  ///
  /// In es, this message translates to:
  /// **'Ninguna estadística disponible para este curso.'**
  String get noStatsAvailable;

  /// No description provided for @lowestProgress.
  ///
  /// In es, this message translates to:
  /// **'Menor Progreso'**
  String get lowestProgress;

  /// No description provided for @courseRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking de Cursos'**
  String get courseRanking;

  /// No description provided for @enterNameSurnameEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingrese nombre, apellido o email'**
  String get enterNameSurnameEmail;

  /// No description provided for @totalRegisteredUsers.
  ///
  /// In es, this message translates to:
  /// **'Total de Usuarios Registrados'**
  String get totalRegisteredUsers;

  /// No description provided for @genderDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución por Género'**
  String get genderDistribution;

  /// No description provided for @ageDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución por Edad'**
  String get ageDistribution;

  /// No description provided for @masculine.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get masculine;

  /// No description provided for @feminine.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get feminine;

  /// No description provided for @notInformed.
  ///
  /// In es, this message translates to:
  /// **'No informado'**
  String get notInformed;

  /// No description provided for @years.
  ///
  /// In es, this message translates to:
  /// **'años'**
  String get years;

  /// No description provided for @ageNotInformed.
  ///
  /// In es, this message translates to:
  /// **'Edad no informada'**
  String get ageNotInformed;

  /// No description provided for @usersInMinistries.
  ///
  /// In es, this message translates to:
  /// **'Usuarios en Ministerios'**
  String get usersInMinistries;

  /// No description provided for @usersInConnects.
  ///
  /// In es, this message translates to:
  /// **'Usuarios en Grupos'**
  String get usersInConnects;

  /// No description provided for @usersInCourses.
  ///
  /// In es, this message translates to:
  /// **'Usuarios en Cursos'**
  String get usersInCourses;

  /// No description provided for @ofUsers.
  ///
  /// In es, this message translates to:
  /// **'de {total} usuarios'**
  String ofUsers(Object total);

  /// No description provided for @noPermissionViewStatistics.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para visualizar estas estadísticas.'**
  String get noPermissionViewStatistics;

  /// No description provided for @errorLoadingCultsColon.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar los cultos: {error}'**
  String errorLoadingCultsColon(Object error);

  /// No description provided for @tryAgain.
  ///
  /// In es, this message translates to:
  /// **'Intentar nuevamente'**
  String get tryAgain;

  /// No description provided for @saveLocationForFuture.
  ///
  /// In es, this message translates to:
  /// **'Guardar esta localización para uso futuro'**
  String get saveLocationForFuture;

  /// No description provided for @noSavedLocations.
  ///
  /// In es, this message translates to:
  /// **'No hay localizaciones guardadas. Por favor, ingresa una nueva localización abajo.'**
  String get noSavedLocations;

  /// No description provided for @selectExistingLocation.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar localización existente'**
  String get selectExistingLocation;

  /// No description provided for @chooseLocation.
  ///
  /// In es, this message translates to:
  /// **'Elige una localización'**
  String get chooseLocation;

  /// No description provided for @enterNewLocation.
  ///
  /// In es, this message translates to:
  /// **'Ingresar nueva localización'**
  String get enterNewLocation;

  /// No description provided for @createNewLocation.
  ///
  /// In es, this message translates to:
  /// **'Crear nueva localización'**
  String get createNewLocation;

  /// No description provided for @timeSlotsTab.
  ///
  /// In es, this message translates to:
  /// **'Franjas Horarias'**
  String get timeSlotsTab;

  /// No description provided for @music.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get music;

  /// No description provided for @createTimeSlot.
  ///
  /// In es, this message translates to:
  /// **'Crear franja horaria'**
  String get createTimeSlot;

  /// No description provided for @newSchedule.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Horario'**
  String get newSchedule;

  /// No description provided for @scheduleName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del horario'**
  String get scheduleName;

  /// No description provided for @startHour.
  ///
  /// In es, this message translates to:
  /// **'Hora de inicio'**
  String get startHour;

  /// No description provided for @endHour.
  ///
  /// In es, this message translates to:
  /// **'Hora de fin'**
  String get endHour;

  /// No description provided for @endTimeMustBeAfterStartTime.
  ///
  /// In es, this message translates to:
  /// **'La hora de fin debe ser posterior a la hora de inicio'**
  String get endTimeMustBeAfterStartTime;

  /// No description provided for @scheduleColor.
  ///
  /// In es, this message translates to:
  /// **'Color del horario'**
  String get scheduleColor;

  /// No description provided for @scheduleCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Horario creado con éxito'**
  String get scheduleCreatedSuccessfully;

  /// No description provided for @errorCreatingSchedule.
  ///
  /// In es, this message translates to:
  /// **'Error al crear horario: {error}'**
  String errorCreatingSchedule(Object error);

  /// No description provided for @createSchedule.
  ///
  /// In es, this message translates to:
  /// **'Crear Horario'**
  String get createSchedule;

  /// No description provided for @noSongsAssignedToCult.
  ///
  /// In es, this message translates to:
  /// **'No hay canciones asignadas a este culto'**
  String get noSongsAssignedToCult;

  /// No description provided for @addMusic.
  ///
  /// In es, this message translates to:
  /// **'Agregar Canción'**
  String get addMusic;

  /// No description provided for @errorReorderingSongs.
  ///
  /// In es, this message translates to:
  /// **'Error al reordenar canciones: {error}'**
  String errorReorderingSongs(Object error);

  /// No description provided for @files.
  ///
  /// In es, this message translates to:
  /// **'archivos'**
  String get files;

  /// No description provided for @addSongToCult.
  ///
  /// In es, this message translates to:
  /// **'Agregar Canción al Culto'**
  String get addSongToCult;

  /// No description provided for @songName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Canción'**
  String get songName;

  /// No description provided for @minutesLabel.
  ///
  /// In es, this message translates to:
  /// **'Minutos'**
  String get minutesLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In es, this message translates to:
  /// **'Segundos'**
  String get secondsLabel;

  /// No description provided for @songAddedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Canción agregada con éxito'**
  String get songAddedSuccessfully;

  /// No description provided for @errorAddingSong.
  ///
  /// In es, this message translates to:
  /// **'Error al agregar canción: {error}'**
  String errorAddingSong(Object error);

  /// No description provided for @editSchedule.
  ///
  /// In es, this message translates to:
  /// **'Editar Horario'**
  String get editSchedule;

  /// No description provided for @scheduleDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles de la Escala'**
  String get scheduleDetails;

  /// No description provided for @timeSlotName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la franja horaria'**
  String get timeSlotName;

  /// No description provided for @deleteSchedule.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Horario'**
  String get deleteSchedule;

  /// No description provided for @confirmDeleteSchedule.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este horario? Todas las asignaciones asociadas también serán eliminadas.'**
  String get confirmDeleteSchedule;

  /// No description provided for @scheduleDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Horario eliminado con éxito'**
  String get scheduleDeletedSuccessfully;

  /// No description provided for @errorDeletingSchedule.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar horario: {error}'**
  String errorDeletingSchedule(Object error);

  /// No description provided for @scheduleUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Horario actualizado con éxito'**
  String get scheduleUpdatedSuccessfully;

  /// No description provided for @errorUpdatingSchedule.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar horario: {error}'**
  String errorUpdatingSchedule(Object error);

  /// No description provided for @startTimeMustBeBeforeEnd.
  ///
  /// In es, this message translates to:
  /// **'La hora de inicio debe ser anterior a la hora de fin'**
  String get startTimeMustBeBeforeEnd;

  /// No description provided for @assignMinistry.
  ///
  /// In es, this message translates to:
  /// **'Asignar Ministerio'**
  String get assignMinistry;

  /// No description provided for @noMinistriesAssigned.
  ///
  /// In es, this message translates to:
  /// **'No hay ministerios asignados'**
  String get noMinistriesAssigned;

  /// No description provided for @temporaryMinistry.
  ///
  /// In es, this message translates to:
  /// **'Ministerio temporal'**
  String get temporaryMinistry;

  /// No description provided for @addRole.
  ///
  /// In es, this message translates to:
  /// **'Agregar Función'**
  String get addRole;

  /// No description provided for @thisMinistryHasNoRoles.
  ///
  /// In es, this message translates to:
  /// **'Este ministerio no tiene funciones definidas'**
  String get thisMinistryHasNoRoles;

  /// No description provided for @defineRoles.
  ///
  /// In es, this message translates to:
  /// **'Definir Funciones'**
  String get defineRoles;

  /// No description provided for @editCapacity.
  ///
  /// In es, this message translates to:
  /// **'Editar capacidad'**
  String get editCapacity;

  /// No description provided for @noPersonsAssigned.
  ///
  /// In es, this message translates to:
  /// **'No hay personas designadas para esta función'**
  String get noPersonsAssigned;

  /// No description provided for @addPerson.
  ///
  /// In es, this message translates to:
  /// **'Agregar Persona'**
  String get addPerson;

  /// No description provided for @deleteAssignment.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Asignación'**
  String get deleteAssignment;

  /// No description provided for @noInvitesSent.
  ///
  /// In es, this message translates to:
  /// **'Ninguna invitación enviada'**
  String get noInvitesSent;

  /// No description provided for @songNotFound.
  ///
  /// In es, this message translates to:
  /// **'Canción no encontrada'**
  String get songNotFound;

  /// No description provided for @errorUploadingFile.
  ///
  /// In es, this message translates to:
  /// **'Error al subir el archivo'**
  String get errorUploadingFile;

  /// No description provided for @uploadingProgress.
  ///
  /// In es, this message translates to:
  /// **'Enviando: {progress}%'**
  String uploadingProgress(Object progress);

  /// No description provided for @fileUploadedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Archivo enviado con éxito'**
  String get fileUploadedSuccessfully;

  /// No description provided for @errorPlayback.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar reproducción: {error}'**
  String errorPlayback(Object error);

  /// No description provided for @rewind10Seconds.
  ///
  /// In es, this message translates to:
  /// **'Retroceder 10 segundos'**
  String get rewind10Seconds;

  /// No description provided for @pause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In es, this message translates to:
  /// **'Reproducir'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get stop;

  /// No description provided for @forward10Seconds.
  ///
  /// In es, this message translates to:
  /// **'Avanzar 10 segundos'**
  String get forward10Seconds;

  /// No description provided for @orderLabel.
  ///
  /// In es, this message translates to:
  /// **'Orden: {order}'**
  String orderLabel(Object order);

  /// No description provided for @noFilesAssociated.
  ///
  /// In es, this message translates to:
  /// **'No hay archivos asociados a esta canción'**
  String get noFilesAssociated;

  /// No description provided for @uploadFile.
  ///
  /// In es, this message translates to:
  /// **'Subir Archivo'**
  String get uploadFile;

  /// No description provided for @fileNameless.
  ///
  /// In es, this message translates to:
  /// **'Archivo sin nombre'**
  String get fileNameless;

  /// No description provided for @uploadedOn.
  ///
  /// In es, this message translates to:
  /// **'Subido el {date}'**
  String uploadedOn(Object date);

  /// No description provided for @score.
  ///
  /// In es, this message translates to:
  /// **'Partitura/Documento'**
  String get score;

  /// No description provided for @audio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @errorSelectingFile.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar archivo: {error}'**
  String errorSelectingFile(Object error);

  /// No description provided for @loadingAudio.
  ///
  /// In es, this message translates to:
  /// **'Cargando audio...'**
  String get loadingAudio;

  /// No description provided for @preparingDocument.
  ///
  /// In es, this message translates to:
  /// **'Preparando documento...'**
  String get preparingDocument;

  /// No description provided for @cannotOpenDocument.
  ///
  /// In es, this message translates to:
  /// **'No es posible abrir el documento'**
  String get cannotOpenDocument;

  /// No description provided for @errorOpeningDocument.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir documento: {error}'**
  String errorOpeningDocument(Object error);

  /// No description provided for @downloadingProgress.
  ///
  /// In es, this message translates to:
  /// **'Descargando: {progress}%'**
  String downloadingProgress(Object progress);

  /// No description provided for @cannotOpenDownloadedFile.
  ///
  /// In es, this message translates to:
  /// **'No es posible abrir el archivo descargado'**
  String get cannotOpenDownloadedFile;

  /// No description provided for @errorDownloadingFile.
  ///
  /// In es, this message translates to:
  /// **'Error al descargar y abrir archivo: {error}'**
  String errorDownloadingFile(Object error);

  /// No description provided for @deleteFile.
  ///
  /// In es, this message translates to:
  /// **'Eliminar archivo'**
  String get deleteFile;

  /// No description provided for @confirmDeleteFile.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este archivo?'**
  String get confirmDeleteFile;

  /// No description provided for @fileDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Archivo eliminado con éxito'**
  String get fileDeletedSuccessfully;

  /// No description provided for @errorDeletingFile.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar archivo: {error}'**
  String errorDeletingFile(Object error);

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @cultsTab.
  ///
  /// In es, this message translates to:
  /// **'Cultos'**
  String get cultsTab;

  /// No description provided for @noGroupEventsScheduled.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos de grupos programados'**
  String get noGroupEventsScheduled;

  /// No description provided for @noMinistryEventsScheduled.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos de ministerios programados'**
  String get noMinistryEventsScheduled;

  /// No description provided for @noEventsScheduled.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos programados'**
  String get noEventsScheduled;

  /// No description provided for @attendanceSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Asistencia'**
  String get attendanceSummary;

  /// No description provided for @roleLabel.
  ///
  /// In es, this message translates to:
  /// **'Función: {role}'**
  String roleLabel(Object role);

  /// No description provided for @confirmedCount.
  ///
  /// In es, this message translates to:
  /// **'Confirmados: {count}'**
  String confirmedCount(Object count);

  /// No description provided for @absentCount.
  ///
  /// In es, this message translates to:
  /// **'Ausentes: {count}'**
  String absentCount(Object count);

  /// No description provided for @presentLabel.
  ///
  /// In es, this message translates to:
  /// **'PRESENTE'**
  String get presentLabel;

  /// No description provided for @originallyAssigned.
  ///
  /// In es, this message translates to:
  /// **'Atribuido originalmente'**
  String get originallyAssigned;

  /// No description provided for @didNotAttend.
  ///
  /// In es, this message translates to:
  /// **'No asistió'**
  String get didNotAttend;

  /// No description provided for @roleId.
  ///
  /// In es, this message translates to:
  /// **'Role ID'**
  String get roleId;

  /// No description provided for @noRoleInfoAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay información de rol disponible'**
  String get noRoleInfoAvailable;

  /// No description provided for @rolePermissions.
  ///
  /// In es, this message translates to:
  /// **'Permisos del rol:'**
  String get rolePermissions;

  /// No description provided for @thisRoleHasNoPermissions.
  ///
  /// In es, this message translates to:
  /// **'Este rol no tiene permisos asignados'**
  String get thisRoleHasNoPermissions;

  /// No description provided for @errorObtainingDiagnostic.
  ///
  /// In es, this message translates to:
  /// **'Error al obtener diagnóstico: {error}'**
  String errorObtainingDiagnostic(Object error);

  /// No description provided for @id.
  ///
  /// In es, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @noCultsScheduled.
  ///
  /// In es, this message translates to:
  /// **'No hay cultos programados'**
  String get noCultsScheduled;

  /// No description provided for @noCultsFor.
  ///
  /// In es, this message translates to:
  /// **'No hay cultos para {date}'**
  String noCultsFor(Object date);

  /// No description provided for @errorColon.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorColon(Object error);

  /// No description provided for @dateNotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Fecha no disponible'**
  String get dateNotAvailable;

  /// No description provided for @acceptedOn.
  ///
  /// In es, this message translates to:
  /// **'Aceptado el'**
  String get acceptedOn;

  /// No description provided for @notSpecified.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get notSpecified;

  /// No description provided for @noServicesAssignedForThisDay.
  ///
  /// In es, this message translates to:
  /// **'No tienes servicios asignados para este día'**
  String get noServicesAssignedForThisDay;

  /// No description provided for @noCounselingAppointmentsForThisDay.
  ///
  /// In es, this message translates to:
  /// **'No tienes consultas de asesoramiento confirmadas para este día'**
  String get noCounselingAppointmentsForThisDay;

  /// No description provided for @basicInformation.
  ///
  /// In es, this message translates to:
  /// **'Información Básica'**
  String get basicInformation;

  /// No description provided for @dateAndTime.
  ///
  /// In es, this message translates to:
  /// **'Fecha y Hora'**
  String get dateAndTime;

  /// No description provided for @recurrence.
  ///
  /// In es, this message translates to:
  /// **'Recurrencia'**
  String get recurrence;

  /// No description provided for @basicInfo.
  ///
  /// In es, this message translates to:
  /// **'Informaciones Básicas'**
  String get basicInfo;

  /// No description provided for @defineEssentialEventData.
  ///
  /// In es, this message translates to:
  /// **'Define los datos esenciales de tu evento'**
  String get defineEssentialEventData;

  /// No description provided for @addBasicInfoAboutEvent.
  ///
  /// In es, this message translates to:
  /// **'Añade las informaciones básicas sobre tu evento.'**
  String get addBasicInfoAboutEvent;

  /// No description provided for @addEventImage.
  ///
  /// In es, this message translates to:
  /// **'Añadir Imagen del Evento (16:9)'**
  String get addEventImage;

  /// No description provided for @uploadingImage.
  ///
  /// In es, this message translates to:
  /// **'Subiendo imagen...'**
  String get uploadingImage;

  /// No description provided for @deleteImage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get deleteImage;

  /// No description provided for @eventName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Evento'**
  String get eventName;

  /// No description provided for @writeClearDescriptiveTitle.
  ///
  /// In es, this message translates to:
  /// **'Escribe un título claro y descriptivo'**
  String get writeClearDescriptiveTitle;

  /// No description provided for @pleaseEnterEventName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa el nombre del evento'**
  String get pleaseEnterEventName;

  /// No description provided for @selectCategory.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una categoría'**
  String get selectCategory;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona una categoría'**
  String get pleaseSelectCategory;

  /// No description provided for @createNewCategory.
  ///
  /// In es, this message translates to:
  /// **'Crear nueva categoría'**
  String get createNewCategory;

  /// No description provided for @hideCategory.
  ///
  /// In es, this message translates to:
  /// **'Ocultar categoría'**
  String get hideCategory;

  /// No description provided for @categoryWillNotAppear.
  ///
  /// In es, this message translates to:
  /// **'La categoría \"{category}\" no aparecerá más en la lista de categorías disponibles. Esta acción no afecta eventos existentes.\n\n¿Deseas continuar?'**
  String categoryWillNotAppear(String category);

  /// No description provided for @hide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar'**
  String get hide;

  /// No description provided for @categoryHidden.
  ///
  /// In es, this message translates to:
  /// **'Categoría \"{category}\" ocultada'**
  String categoryHidden(String category);

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar categorías: {error}'**
  String errorLoadingCategories(String error);

  /// No description provided for @createNewCategoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Categoría'**
  String get createNewCategoryTitle;

  /// No description provided for @categoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Categoría'**
  String get categoryName;

  /// No description provided for @enterCategoryName.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre de la categoría'**
  String get enterCategoryName;

  /// No description provided for @errorCreatingCategory.
  ///
  /// In es, this message translates to:
  /// **'Error al crear categoría: {error}'**
  String errorCreatingCategory(String error);

  /// No description provided for @describeEventDetails.
  ///
  /// In es, this message translates to:
  /// **'Describe los detalles del evento'**
  String get describeEventDetails;

  /// No description provided for @advance.
  ///
  /// In es, this message translates to:
  /// **'Avanzar'**
  String get advance;

  /// No description provided for @cancelCreation.
  ///
  /// In es, this message translates to:
  /// **'Cancelar creación'**
  String get cancelCreation;

  /// No description provided for @sureWantToCancel.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cancelar? Toda la información se perderá.'**
  String get sureWantToCancel;

  /// No description provided for @continueEditing.
  ///
  /// In es, this message translates to:
  /// **'Continuar editando'**
  String get continueEditing;

  /// No description provided for @eventsCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'{count} eventos creados con éxito'**
  String eventsCreatedSuccessfully(int count);

  /// No description provided for @eventCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Evento creado con éxito'**
  String get eventCreatedSuccessfully;

  /// No description provided for @errorCreatingEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al crear evento'**
  String errorCreatingEvent(String error);

  /// No description provided for @creatingEvent.
  ///
  /// In es, this message translates to:
  /// **'Creando evento...'**
  String get creatingEvent;

  /// No description provided for @pleaseWaitProcessingData.
  ///
  /// In es, this message translates to:
  /// **'Por favor, espera mientras procesamos los datos'**
  String get pleaseWaitProcessingData;

  /// No description provided for @eventLocation.
  ///
  /// In es, this message translates to:
  /// **'Localización del Evento'**
  String get eventLocation;

  /// No description provided for @defineWhereEventWillHappen.
  ///
  /// In es, this message translates to:
  /// **'Define dónde ocurrirá el evento'**
  String get defineWhereEventWillHappen;

  /// No description provided for @eventType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Evento'**
  String get eventType;

  /// No description provided for @churchLocations.
  ///
  /// In es, this message translates to:
  /// **'Localizaciones de la Iglesia'**
  String get churchLocations;

  /// No description provided for @useChurchLocation.
  ///
  /// In es, this message translates to:
  /// **'Usar localización de la iglesia'**
  String get useChurchLocation;

  /// No description provided for @selectRegisteredLocation.
  ///
  /// In es, this message translates to:
  /// **'Selecciona uno de los locales registrados'**
  String get selectRegisteredLocation;

  /// No description provided for @noChurchLocationsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay localizaciones de la iglesia disponibles'**
  String get noChurchLocationsAvailable;

  /// No description provided for @churchLocation.
  ///
  /// In es, this message translates to:
  /// **'Localización de la Iglesia'**
  String get churchLocation;

  /// No description provided for @pleaseSelectALocation.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona una localización'**
  String get pleaseSelectALocation;

  /// No description provided for @mySavedLocations.
  ///
  /// In es, this message translates to:
  /// **'Mis Localizaciones Guardadas'**
  String get mySavedLocations;

  /// No description provided for @useSavedLocation.
  ///
  /// In es, this message translates to:
  /// **'Usar localización guardada'**
  String get useSavedLocation;

  /// No description provided for @selectSavedLocation.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una de tus localizaciones guardadas'**
  String get selectSavedLocation;

  /// No description provided for @noSavedLocationsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay localizaciones guardadas disponibles'**
  String get noSavedLocationsAvailable;

  /// No description provided for @savedLocation.
  ///
  /// In es, this message translates to:
  /// **'Localización Guardada'**
  String get savedLocation;

  /// No description provided for @errorLoadingLocations.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar ubicaciones: {error}'**
  String errorLoadingLocations(Object error);

  /// No description provided for @errorLoadingSavedLocations.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar ubicaciones guardadas: {error}'**
  String errorLoadingSavedLocations(String error);

  /// No description provided for @pleaseSelectChurchLocation.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona una ubicación de iglesia'**
  String get pleaseSelectChurchLocation;

  /// No description provided for @pleaseSelectASavedLocation.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona una localización guardada'**
  String get pleaseSelectASavedLocation;

  /// No description provided for @eventAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección del Evento'**
  String get eventAddress;

  /// No description provided for @cityRequired.
  ///
  /// In es, this message translates to:
  /// **'Ciudad *'**
  String get cityRequired;

  /// No description provided for @enterEventCity.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la ciudad del evento'**
  String get enterEventCity;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa la ciudad'**
  String get pleaseEnterCity;

  /// No description provided for @stateRequired.
  ///
  /// In es, this message translates to:
  /// **'Estado *'**
  String get stateRequired;

  /// No description provided for @enterEventState.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el estado del evento'**
  String get enterEventState;

  /// No description provided for @pleaseEnterState.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa el estado'**
  String get pleaseEnterState;

  /// No description provided for @streetRequired.
  ///
  /// In es, this message translates to:
  /// **'Calle *'**
  String get streetRequired;

  /// No description provided for @enterEventStreet.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la calle del evento'**
  String get enterEventStreet;

  /// No description provided for @pleaseEnterStreet.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa la calle'**
  String get pleaseEnterStreet;

  /// No description provided for @numberRequired.
  ///
  /// In es, this message translates to:
  /// **'Número *'**
  String get numberRequired;

  /// No description provided for @exampleNumber.
  ///
  /// In es, this message translates to:
  /// **'Ej: 123'**
  String get exampleNumber;

  /// No description provided for @pleaseEnterNumber.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa el número'**
  String get pleaseEnterNumber;

  /// No description provided for @examplePostalCode.
  ///
  /// In es, this message translates to:
  /// **'Ej: 28001'**
  String get examplePostalCode;

  /// No description provided for @enterNeighborhood.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el barrio'**
  String get enterNeighborhood;

  /// No description provided for @apartmentRoomEtc.
  ///
  /// In es, this message translates to:
  /// **'Apartamento, sala, etc.'**
  String get apartmentRoomEtc;

  /// No description provided for @saveLocationForFutureUse.
  ///
  /// In es, this message translates to:
  /// **'Guardar esta localización para uso futuro'**
  String get saveLocationForFutureUse;

  /// No description provided for @locationNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la localización *'**
  String get locationNameRequired;

  /// No description provided for @exampleLocationName.
  ///
  /// In es, this message translates to:
  /// **'Ej: Mi Local Favorito'**
  String get exampleLocationName;

  /// No description provided for @pleaseEnterLocationName.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un nombre para la localización'**
  String get pleaseEnterLocationName;

  /// No description provided for @saveAsChurchLocationAdmin.
  ///
  /// In es, this message translates to:
  /// **'Guardar como localización de la iglesia (admin)'**
  String get saveAsChurchLocationAdmin;

  /// No description provided for @saveLocation.
  ///
  /// In es, this message translates to:
  /// **'Guardar Localización'**
  String get saveLocation;

  /// No description provided for @pleaseEnterLocationNameForSave.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un nombre para la ubicación'**
  String get pleaseEnterLocationNameForSave;

  /// No description provided for @locationSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Ubicación guardada correctamente'**
  String get locationSavedSuccessfully;

  /// No description provided for @errorSavingLocation.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar ubicación: {error}'**
  String errorSavingLocation(String error);

  /// No description provided for @churchLocationSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de iglesia guardada correctamente'**
  String get churchLocationSavedSuccessfully;

  /// No description provided for @onlineEventLink.
  ///
  /// In es, this message translates to:
  /// **'Link del Evento En Línea'**
  String get onlineEventLink;

  /// No description provided for @meetingUrlRequired.
  ///
  /// In es, this message translates to:
  /// **'URL de la Reunión *'**
  String get meetingUrlRequired;

  /// No description provided for @exampleZoomUrl.
  ///
  /// In es, this message translates to:
  /// **'Ej: https://zoom.us/j/12345678'**
  String get exampleZoomUrl;

  /// No description provided for @accessInstructionsOptional.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones de Acceso (opcional)'**
  String get accessInstructionsOptional;

  /// No description provided for @instructionsToJoinMeeting.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones para entrar a la reunión en línea, contraseñas, etc.'**
  String get instructionsToJoinMeeting;

  /// No description provided for @onlineOptionHybrid.
  ///
  /// In es, this message translates to:
  /// **'Opción En Línea (Híbrido)'**
  String get onlineOptionHybrid;

  /// No description provided for @forHybridEventsPleaseEnterValidUrl.
  ///
  /// In es, this message translates to:
  /// **'Para eventos híbridos, por favor ingresa un URL válido'**
  String get forHybridEventsPleaseEnterValidUrl;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get next;

  /// No description provided for @eventDateAndTime.
  ///
  /// In es, this message translates to:
  /// **'Fecha y Hora del Evento'**
  String get eventDateAndTime;

  /// No description provided for @defineWhenEventStartsAndEnds.
  ///
  /// In es, this message translates to:
  /// **'Define cuándo el evento comienza y termina'**
  String get defineWhenEventStartsAndEnds;

  /// No description provided for @selectTime.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora'**
  String get selectTime;

  /// No description provided for @eventRecurrence.
  ///
  /// In es, this message translates to:
  /// **'Recurrencia del Evento'**
  String get eventRecurrence;

  /// No description provided for @defineIfEventWillBeOnceOrRecurring.
  ///
  /// In es, this message translates to:
  /// **'Define si tu evento ocurrirá una única vez o será recurrente'**
  String get defineIfEventWillBeOnceOrRecurring;

  /// No description provided for @recurrenceSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuraciones de Recurrencia'**
  String get recurrenceSettings;

  /// No description provided for @defineFrequencyOfRecurringEvent.
  ///
  /// In es, this message translates to:
  /// **'Define la frecuencia de tu evento recurrente'**
  String get defineFrequencyOfRecurringEvent;

  /// No description provided for @frequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get frequency;

  /// No description provided for @numberIndicatesInterval.
  ///
  /// In es, this message translates to:
  /// **'El número indica el intervalo de repetición. Por ejemplo: \"2 Semanalmente\" significa que el evento se repetirá cada 2 semanas.'**
  String get numberIndicatesInterval;

  /// No description provided for @repeatEvery.
  ///
  /// In es, this message translates to:
  /// **'Repetir cada:'**
  String get repeatEvery;

  /// No description provided for @days.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get days;

  /// No description provided for @day.
  ///
  /// In es, this message translates to:
  /// **'día'**
  String get day;

  /// No description provided for @weeks.
  ///
  /// In es, this message translates to:
  /// **'semanas'**
  String get weeks;

  /// No description provided for @week.
  ///
  /// In es, this message translates to:
  /// **'semana'**
  String get week;

  /// No description provided for @months.
  ///
  /// In es, this message translates to:
  /// **'meses'**
  String get months;

  /// No description provided for @month.
  ///
  /// In es, this message translates to:
  /// **'mes'**
  String get month;

  /// No description provided for @year.
  ///
  /// In es, this message translates to:
  /// **'año'**
  String get year;

  /// No description provided for @ends.
  ///
  /// In es, this message translates to:
  /// **'Termina'**
  String get ends;

  /// No description provided for @after.
  ///
  /// In es, this message translates to:
  /// **'Después de'**
  String get after;

  /// No description provided for @occurrences.
  ///
  /// In es, this message translates to:
  /// **'repeticiones'**
  String get occurrences;

  /// No description provided for @onDate.
  ///
  /// In es, this message translates to:
  /// **'En fecha'**
  String get onDate;

  /// No description provided for @onSpecificDate.
  ///
  /// In es, this message translates to:
  /// **'En fecha'**
  String get onSpecificDate;

  /// No description provided for @single.
  ///
  /// In es, this message translates to:
  /// **'Único'**
  String get single;

  /// No description provided for @recurring.
  ///
  /// In es, this message translates to:
  /// **'Recurrente'**
  String get recurring;

  /// No description provided for @singleEventNonRecurring.
  ///
  /// In es, this message translates to:
  /// **'Evento único (no recurrente)'**
  String get singleEventNonRecurring;

  /// No description provided for @repeatsEveryXDays.
  ///
  /// In es, this message translates to:
  /// **'Repite cada {interval} días'**
  String repeatsEveryXDays(Object interval);

  /// No description provided for @repeatsDaily.
  ///
  /// In es, this message translates to:
  /// **'Repite diariamente'**
  String get repeatsDaily;

  /// No description provided for @repeatsEveryXWeeks.
  ///
  /// In es, this message translates to:
  /// **'Repite cada {interval} semanas'**
  String repeatsEveryXWeeks(Object interval);

  /// No description provided for @repeatsWeekly.
  ///
  /// In es, this message translates to:
  /// **'Repite semanalmente'**
  String get repeatsWeekly;

  /// No description provided for @repeatsEveryXMonths.
  ///
  /// In es, this message translates to:
  /// **'Repite cada {interval} meses'**
  String repeatsEveryXMonths(Object interval);

  /// No description provided for @repeatsMonthly.
  ///
  /// In es, this message translates to:
  /// **'Repite mensualmente'**
  String get repeatsMonthly;

  /// No description provided for @repeatsEveryXYears.
  ///
  /// In es, this message translates to:
  /// **'Repite cada {interval} años'**
  String repeatsEveryXYears(Object interval);

  /// No description provided for @repeatsYearly.
  ///
  /// In es, this message translates to:
  /// **'Repite anualmente'**
  String get repeatsYearly;

  /// No description provided for @noEndDefined.
  ///
  /// In es, this message translates to:
  /// **'sin fin definido'**
  String get noEndDefined;

  /// No description provided for @untilSpecificDate.
  ///
  /// In es, this message translates to:
  /// **'hasta fecha específica'**
  String get untilSpecificDate;

  /// No description provided for @untilDate.
  ///
  /// In es, this message translates to:
  /// **'hasta {date}'**
  String untilDate(Object date);

  /// No description provided for @errorUploadingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al hacer upload de la imagen: {error}'**
  String errorUploadingImage(String error);

  /// No description provided for @defineRecurringEventFrequency.
  ///
  /// In es, this message translates to:
  /// **'Define la frecuencia de tu evento recurrente'**
  String get defineRecurringEventFrequency;

  /// No description provided for @intervalExplanation.
  ///
  /// In es, this message translates to:
  /// **'El número indica el intervalo de repetición. Por ejemplo: \"2 semanas\" significa que el evento se repetirá cada 2 semanas.'**
  String get intervalExplanation;

  /// No description provided for @singleEventNotRecurring.
  ///
  /// In es, this message translates to:
  /// **'Evento único (no recurrente)'**
  String get singleEventNotRecurring;

  /// No description provided for @repeats.
  ///
  /// In es, this message translates to:
  /// **'Repite'**
  String get repeats;

  /// No description provided for @everyXDays.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} días'**
  String everyXDays(int interval);

  /// No description provided for @daily.
  ///
  /// In es, this message translates to:
  /// **'diariamente'**
  String get daily;

  /// No description provided for @everyXWeeks.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} semanas'**
  String everyXWeeks(int interval);

  /// No description provided for @weekly.
  ///
  /// In es, this message translates to:
  /// **'semanalmente'**
  String get weekly;

  /// No description provided for @everyXMonths.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} meses'**
  String everyXMonths(int interval);

  /// No description provided for @monthly.
  ///
  /// In es, this message translates to:
  /// **'mensualmente'**
  String get monthly;

  /// No description provided for @everyXYears.
  ///
  /// In es, this message translates to:
  /// **'cada {interval} años'**
  String everyXYears(int interval);

  /// No description provided for @yearly.
  ///
  /// In es, this message translates to:
  /// **'anualmente'**
  String get yearly;

  /// No description provided for @untilXOccurrences.
  ///
  /// In es, this message translates to:
  /// **'hasta {count} repeticiones'**
  String untilXOccurrences(int count);

  /// No description provided for @from.
  ///
  /// In es, this message translates to:
  /// **'De'**
  String get from;

  /// No description provided for @until.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get until;

  /// No description provided for @defineEventOccurrenceType.
  ///
  /// In es, this message translates to:
  /// **'Define si tu evento ocurrirá una única vez o será recurrente'**
  String get defineEventOccurrenceType;

  /// No description provided for @liveTransmission.
  ///
  /// In es, this message translates to:
  /// **'Transmisión En Vivo'**
  String get liveTransmission;

  /// No description provided for @tapToWatchNow.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver ahora'**
  String get tapToWatchNow;

  /// No description provided for @streamLinkComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Link de transmisión próximamente...'**
  String get streamLinkComingSoon;

  /// No description provided for @live.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get live;

  /// No description provided for @sureWantToLogout.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cerrar sesión?'**
  String get sureWantToLogout;

  /// No description provided for @notificationDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la notificación'**
  String get notificationDetail;

  /// No description provided for @areYouSureYouWantToDeleteThisNotification.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar esta notificación?'**
  String get areYouSureYouWantToDeleteThisNotification;

  /// No description provided for @filterByType.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por tipo'**
  String get filterByType;

  /// No description provided for @generalAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Anuncios generales'**
  String get generalAnnouncements;

  /// No description provided for @cultAnnouncements.
  ///
  /// In es, this message translates to:
  /// **'Anuncios de cultos'**
  String get cultAnnouncements;

  /// No description provided for @newMinistries.
  ///
  /// In es, this message translates to:
  /// **'Nuevos ministerios'**
  String get newMinistries;

  /// No description provided for @joinRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes para entrar'**
  String get joinRequests;

  /// No description provided for @approvedRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes aprobadas'**
  String get approvedRequests;

  /// No description provided for @ministryEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos de los ministerios'**
  String get ministryEvents;

  /// No description provided for @ministryPosts.
  ///
  /// In es, this message translates to:
  /// **'Publicaciones de los ministerios'**
  String get ministryPosts;

  /// No description provided for @workSchedules.
  ///
  /// In es, this message translates to:
  /// **'Escalas'**
  String get workSchedules;

  /// No description provided for @ministryMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes de los ministerios'**
  String get ministryMessages;

  /// No description provided for @newGroups.
  ///
  /// In es, this message translates to:
  /// **'Nuevos grupos'**
  String get newGroups;

  /// No description provided for @groupEvents.
  ///
  /// In es, this message translates to:
  /// **'Eventos de los grupos'**
  String get groupEvents;

  /// No description provided for @groupPosts.
  ///
  /// In es, this message translates to:
  /// **'Publicaciones de los grupos'**
  String get groupPosts;

  /// No description provided for @groupMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes de los grupos'**
  String get groupMessages;

  /// No description provided for @prayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones'**
  String get prayers;

  /// No description provided for @privatePrayerRequests.
  ///
  /// In es, this message translates to:
  /// **'Pedidos de oración particular'**
  String get privatePrayerRequests;

  /// No description provided for @completedPrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones completadas'**
  String get completedPrayers;

  /// No description provided for @approvedPublicPrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones públicas aprobadas'**
  String get approvedPublicPrayers;

  /// No description provided for @newEvents.
  ///
  /// In es, this message translates to:
  /// **'Nuevos eventos'**
  String get newEvents;

  /// No description provided for @eventReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de eventos'**
  String get eventReminders;

  /// No description provided for @newRequests.
  ///
  /// In es, this message translates to:
  /// **'Nuevos pedidos'**
  String get newRequests;

  /// No description provided for @confirmedAppointments.
  ///
  /// In es, this message translates to:
  /// **'Agendamientos confirmados'**
  String get confirmedAppointments;

  /// No description provided for @rejectedAppointments.
  ///
  /// In es, this message translates to:
  /// **'Agendamientos rechazados'**
  String get rejectedAppointments;

  /// No description provided for @cancelledAppointments.
  ///
  /// In es, this message translates to:
  /// **'Agendamientos cancelados'**
  String get cancelledAppointments;

  /// No description provided for @newVideos.
  ///
  /// In es, this message translates to:
  /// **'Nuevos vídeos'**
  String get newVideos;

  /// No description provided for @notifTypeNewAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Nuevo anuncio'**
  String get notifTypeNewAnnouncement;

  /// No description provided for @notifTypeNewCultAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Nuevo anuncio de culto'**
  String get notifTypeNewCultAnnouncement;

  /// No description provided for @notifTypeNewMinistry.
  ///
  /// In es, this message translates to:
  /// **'Nuevo ministerio'**
  String get notifTypeNewMinistry;

  /// No description provided for @notifTypeMinistryJoinRequestAccepted.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de ministerio aceptada'**
  String get notifTypeMinistryJoinRequestAccepted;

  /// No description provided for @notifTypeMinistryJoinRequestRejected.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de ministerio rechazada'**
  String get notifTypeMinistryJoinRequestRejected;

  /// No description provided for @notifTypeMinistryJoinRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitud para entrar al ministerio'**
  String get notifTypeMinistryJoinRequest;

  /// No description provided for @notifTypeMinistryManuallyAdded.
  ///
  /// In es, this message translates to:
  /// **'Agregado al ministerio'**
  String get notifTypeMinistryManuallyAdded;

  /// No description provided for @notifTypeMinistryNewEvent.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento del ministerio'**
  String get notifTypeMinistryNewEvent;

  /// No description provided for @notifTypeMinistryNewPost.
  ///
  /// In es, this message translates to:
  /// **'Nueva publicación en el ministerio'**
  String get notifTypeMinistryNewPost;

  /// No description provided for @notifTypeMinistryNewWorkSchedule.
  ///
  /// In es, this message translates to:
  /// **'Nueva escala de trabajo'**
  String get notifTypeMinistryNewWorkSchedule;

  /// No description provided for @notifTypeMinistryWorkScheduleAccepted.
  ///
  /// In es, this message translates to:
  /// **'Escala de trabajo aceptada'**
  String get notifTypeMinistryWorkScheduleAccepted;

  /// No description provided for @notifTypeMinistryWorkScheduleRejected.
  ///
  /// In es, this message translates to:
  /// **'Escala de trabajo rechazada'**
  String get notifTypeMinistryWorkScheduleRejected;

  /// No description provided for @notifTypeMinistryWorkSlotFilled.
  ///
  /// In es, this message translates to:
  /// **'Vacante de trabajo ocupada'**
  String get notifTypeMinistryWorkSlotFilled;

  /// No description provided for @notifTypeMinistryWorkSlotAvailable.
  ///
  /// In es, this message translates to:
  /// **'Vacante de trabajo disponible'**
  String get notifTypeMinistryWorkSlotAvailable;

  /// No description provided for @notifTypeMinistryEventReminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio de evento del ministerio'**
  String get notifTypeMinistryEventReminder;

  /// No description provided for @notifTypeMinistryNewChat.
  ///
  /// In es, this message translates to:
  /// **'Nuevo mensaje en el ministerio'**
  String get notifTypeMinistryNewChat;

  /// No description provided for @notifTypeMinistryPromotedToAdmin.
  ///
  /// In es, this message translates to:
  /// **'Promovido a admin del ministerio'**
  String get notifTypeMinistryPromotedToAdmin;

  /// No description provided for @notifTypeNewGroup.
  ///
  /// In es, this message translates to:
  /// **'Nuevo grupo'**
  String get notifTypeNewGroup;

  /// No description provided for @notifTypeGroupJoinRequestAccepted.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de grupo aceptada'**
  String get notifTypeGroupJoinRequestAccepted;

  /// No description provided for @notifTypeGroupJoinRequestRejected.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de grupo rechazada'**
  String get notifTypeGroupJoinRequestRejected;

  /// No description provided for @notifTypeGroupJoinRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitud para entrar al grupo'**
  String get notifTypeGroupJoinRequest;

  /// No description provided for @notifTypeGroupManuallyAdded.
  ///
  /// In es, this message translates to:
  /// **'Agregado al grupo'**
  String get notifTypeGroupManuallyAdded;

  /// No description provided for @notifTypeGroupNewEvent.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento del grupo'**
  String get notifTypeGroupNewEvent;

  /// No description provided for @notifTypeGroupNewPost.
  ///
  /// In es, this message translates to:
  /// **'Nueva publicación en el grupo'**
  String get notifTypeGroupNewPost;

  /// No description provided for @notifTypeGroupEventReminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio de evento del grupo'**
  String get notifTypeGroupEventReminder;

  /// No description provided for @notifTypeGroupNewChat.
  ///
  /// In es, this message translates to:
  /// **'Nuevo mensaje en el grupo'**
  String get notifTypeGroupNewChat;

  /// No description provided for @notifTypeGroupPromotedToAdmin.
  ///
  /// In es, this message translates to:
  /// **'Promovido a admin del grupo'**
  String get notifTypeGroupPromotedToAdmin;

  /// No description provided for @notifTypeNewPrivatePrayer.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pedido de oración particular'**
  String get notifTypeNewPrivatePrayer;

  /// No description provided for @notifTypePrivatePrayerPrayed.
  ///
  /// In es, this message translates to:
  /// **'Oración particular completada'**
  String get notifTypePrivatePrayerPrayed;

  /// No description provided for @notifTypePublicPrayerAccepted.
  ///
  /// In es, this message translates to:
  /// **'Oración pública aceptada'**
  String get notifTypePublicPrayerAccepted;

  /// No description provided for @notifTypeNewEvent.
  ///
  /// In es, this message translates to:
  /// **'Nuevo evento'**
  String get notifTypeNewEvent;

  /// No description provided for @notifTypeEventReminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio de evento'**
  String get notifTypeEventReminder;

  /// No description provided for @notifTypeNewCounselingRequest.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pedido de consejería'**
  String get notifTypeNewCounselingRequest;

  /// No description provided for @notifTypeCounselingAccepted.
  ///
  /// In es, this message translates to:
  /// **'Agendamiento confirmado'**
  String get notifTypeCounselingAccepted;

  /// No description provided for @notifTypeCounselingRejected.
  ///
  /// In es, this message translates to:
  /// **'Agendamiento rechazado'**
  String get notifTypeCounselingRejected;

  /// No description provided for @notifTypeCounselingCancelled.
  ///
  /// In es, this message translates to:
  /// **'Agendamiento cancelado'**
  String get notifTypeCounselingCancelled;

  /// No description provided for @notifTypeNewVideo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo vídeo'**
  String get notifTypeNewVideo;

  /// No description provided for @notifTypeMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje'**
  String get notifTypeMessage;

  /// No description provided for @notifTypeGeneric.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get notifTypeGeneric;

  /// No description provided for @notifTypeCustom.
  ///
  /// In es, this message translates to:
  /// **'Notificación personalizada'**
  String get notifTypeCustom;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor, rellena todos los campos'**
  String get pleaseFillAllFields;

  /// No description provided for @requestPrivatePrayer.
  ///
  /// In es, this message translates to:
  /// **'Solicitar oración privada'**
  String get requestPrivatePrayer;

  /// No description provided for @yourPrayerWillBeSharedOnlyWithPastors.
  ///
  /// In es, this message translates to:
  /// **'Tu oración será compartida solo con los pastores de la iglesia para atención personal.'**
  String get yourPrayerWillBeSharedOnlyWithPastors;

  /// No description provided for @requestDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles de tu pedido'**
  String get requestDetails;

  /// No description provided for @writeYourPrayerRequestHere.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu pedido de oración aquí...'**
  String get writeYourPrayerRequestHere;

  /// No description provided for @pleaseWriteYourRequest.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu pedido'**
  String get pleaseWriteYourRequest;

  /// No description provided for @maximum400CharactersAllowed.
  ///
  /// In es, this message translates to:
  /// **'Máximo 400 caracteres permitidos'**
  String get maximum400CharactersAllowed;

  /// No description provided for @sendRequest.
  ///
  /// In es, this message translates to:
  /// **'Enviar pedido'**
  String get sendRequest;

  /// No description provided for @prayerRequestSentSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Pedido de oración enviado con éxito'**
  String get prayerRequestSentSuccessfully;

  /// No description provided for @errorCreatingRequest.
  ///
  /// In es, this message translates to:
  /// **'Error al crear el pedido: {error}'**
  String errorCreatingRequest(String error);

  /// No description provided for @publicPrayers.
  ///
  /// In es, this message translates to:
  /// **'Oraciones Públicas'**
  String get publicPrayers;

  /// No description provided for @mostVoted.
  ///
  /// In es, this message translates to:
  /// **'Más votadas'**
  String get mostVoted;

  /// No description provided for @recent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get recent;

  /// No description provided for @assigned.
  ///
  /// In es, this message translates to:
  /// **'Asignada'**
  String get assigned;

  /// No description provided for @errorLoadingMore.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar más: {error}'**
  String errorLoadingMore(String error);

  /// No description provided for @errorLoadingPrayers.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar oraciones: {error}'**
  String errorLoadingPrayers(String error);

  /// No description provided for @noAssignedPrayers.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración atribuida'**
  String get noAssignedPrayers;

  /// No description provided for @noPrayersAvailable.
  ///
  /// In es, this message translates to:
  /// **'Ninguna oración disponible'**
  String get noPrayersAvailable;

  /// No description provided for @noPrayersAssignedToCultsYet.
  ///
  /// In es, this message translates to:
  /// **'No se atribuyeron oraciones a cultos todavía'**
  String get noPrayersAssignedToCultsYet;

  /// No description provided for @beTheFirstToRequestPrayer.
  ///
  /// In es, this message translates to:
  /// **'Sé el primero en pedir oración'**
  String get beTheFirstToRequestPrayer;

  /// No description provided for @prayerRequest.
  ///
  /// In es, this message translates to:
  /// **'Pedido de Oración'**
  String get prayerRequest;

  /// No description provided for @yourPrayerWillBeSharedWithCommunity.
  ///
  /// In es, this message translates to:
  /// **'Tu oración será compartida con toda la comunidad para que puedan orar por ti.'**
  String get yourPrayerWillBeSharedWithCommunity;

  /// No description provided for @whyDoYouNeedPrayer.
  ///
  /// In es, this message translates to:
  /// **'¿Por qué necesitas oración?'**
  String get whyDoYouNeedPrayer;

  /// No description provided for @pleaseWriteYourPrayerRequest.
  ///
  /// In es, this message translates to:
  /// **'Por favor, escribe tu pedido de oración'**
  String get pleaseWriteYourPrayerRequest;

  /// No description provided for @publishAnonymously.
  ///
  /// In es, this message translates to:
  /// **'Publicar anónimamente'**
  String get publishAnonymously;

  /// No description provided for @yourNameWillRemainHidden.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre permanecerá oculto para todos'**
  String get yourNameWillRemainHidden;

  /// No description provided for @publishRequest.
  ///
  /// In es, this message translates to:
  /// **'Publicar pedido'**
  String get publishRequest;

  /// No description provided for @youMustBeLoggedInToSendPrayer.
  ///
  /// In es, this message translates to:
  /// **'Debes estar conectado para enviar una oración'**
  String get youMustBeLoggedInToSendPrayer;

  /// No description provided for @prayerSentSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Oración enviada con éxito!'**
  String get prayerSentSuccessfully;

  /// No description provided for @errorSendingPrayer.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar la oración: {error}'**
  String errorSendingPrayer(String error);

  /// No description provided for @sureYouWantToCancelAppointment.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas cancelar esta cita?'**
  String get sureYouWantToCancelAppointment;

  /// No description provided for @yesCancelIt.
  ///
  /// In es, this message translates to:
  /// **'Sí, cancelar'**
  String get yesCancelIt;

  /// No description provided for @appointmentCancelledSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Cita cancelada con éxito'**
  String get appointmentCancelledSuccessfully;

  /// No description provided for @errorWithMessage.
  ///
  /// In es, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @youAreNotLoggedIn.
  ///
  /// In es, this message translates to:
  /// **'No estás conectado'**
  String get youAreNotLoggedIn;

  /// No description provided for @youHaveNoScheduledAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas agendadas'**
  String get youHaveNoScheduledAppointments;

  /// No description provided for @youHaveNoCancelledAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas canceladas'**
  String get youHaveNoCancelledAppointments;

  /// No description provided for @youHaveNoCompletedAppointments.
  ///
  /// In es, this message translates to:
  /// **'No tienes citas concluidas'**
  String get youHaveNoCompletedAppointments;

  /// No description provided for @cancelledTab.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get cancelledTab;

  /// No description provided for @completedTab.
  ///
  /// In es, this message translates to:
  /// **'Concluidas'**
  String get completedTab;

  /// No description provided for @requestCounseling.
  ///
  /// In es, this message translates to:
  /// **'Solicitar Consejería'**
  String get requestCounseling;

  /// No description provided for @selectAPastor.
  ///
  /// In es, this message translates to:
  /// **'Seleccione un pastor'**
  String get selectAPastor;

  /// No description provided for @noPastorsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay pastores disponibles'**
  String get noPastorsAvailable;

  /// No description provided for @appointmentType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Cita'**
  String get appointmentType;

  /// No description provided for @videoCallSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión por videollamada'**
  String get videoCallSession;

  /// No description provided for @inPersonSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión en persona'**
  String get inPersonSession;

  /// No description provided for @reasonForCounseling.
  ///
  /// In es, this message translates to:
  /// **'Motivo de la Consejería'**
  String get reasonForCounseling;

  /// No description provided for @brieflyDescribeReason.
  ///
  /// In es, this message translates to:
  /// **'Describa brevemente el motivo de su consulta'**
  String get brieflyDescribeReason;

  /// No description provided for @pastorHasNotConfiguredAvailability.
  ///
  /// In es, this message translates to:
  /// **'El pastor no ha configurado su disponibilidad'**
  String get pastorHasNotConfiguredAvailability;

  /// No description provided for @errorCheckingAvailability.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar disponibilidad: {error}'**
  String errorCheckingAvailability(String error);

  /// No description provided for @pleaseCompleteAllFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa todos los campos'**
  String get pleaseCompleteAllFields;

  /// No description provided for @appointmentRequestedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Cita solicitada correctamente'**
  String get appointmentRequestedSuccessfully;

  /// No description provided for @errorBooking.
  ///
  /// In es, this message translates to:
  /// **'Error al reservar: {error}'**
  String errorBooking(String error);

  /// No description provided for @anonymous.
  ///
  /// In es, this message translates to:
  /// **'Anónimo'**
  String get anonymous;

  /// No description provided for @unassignPrayer.
  ///
  /// In es, this message translates to:
  /// **'Desasignar oración'**
  String get unassignPrayer;

  /// No description provided for @sureYouWantToUnassignPrayer.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas desasignar esta oración del servicio?'**
  String get sureYouWantToUnassignPrayer;

  /// No description provided for @unassign.
  ///
  /// In es, this message translates to:
  /// **'Desasignar'**
  String get unassign;

  /// No description provided for @prayerUnassignedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Oración desasignada correctamente'**
  String get prayerUnassignedSuccessfully;

  /// No description provided for @errorUnassigningPrayer.
  ///
  /// In es, this message translates to:
  /// **'Error al desasignar la oración'**
  String get errorUnassigningPrayer;

  /// No description provided for @deletePrayer.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Oración'**
  String get deletePrayer;

  /// No description provided for @sureYouWantToDeletePrayer.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar esta oración? Esta acción no se puede deshacer.'**
  String get sureYouWantToDeletePrayer;

  /// No description provided for @prayerDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Oración eliminada con éxito'**
  String get prayerDeletedSuccessfully;

  /// No description provided for @errorDeletingPrayer.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar oración: {error}'**
  String errorDeletingPrayer(String error);

  /// No description provided for @assignToCult.
  ///
  /// In es, this message translates to:
  /// **'Asignar al culto'**
  String get assignToCult;

  /// No description provided for @unassignFromCult.
  ///
  /// In es, this message translates to:
  /// **'Desasignar del servicio'**
  String get unassignFromCult;

  /// No description provided for @assignedToCult.
  ///
  /// In es, this message translates to:
  /// **'Asignada al servicio: {cultName}'**
  String assignedToCult(String cultName);

  /// No description provided for @options.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get options;

  /// No description provided for @youMustBeLoggedInToVote.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para votar'**
  String get youMustBeLoggedInToVote;

  /// No description provided for @errorRegisteringVote.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar el voto: {error}'**
  String errorRegisteringVote(String error);

  /// No description provided for @commentsCount.
  ///
  /// In es, this message translates to:
  /// **'Comentarios ({count})'**
  String commentsCount(int count);

  /// No description provided for @sureYouWantToDeleteComment.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este comentario?'**
  String get sureYouWantToDeleteComment;

  /// No description provided for @youDontHavePermissionToDeleteComment.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para eliminar este comentario'**
  String get youDontHavePermissionToDeleteComment;

  /// No description provided for @addComment.
  ///
  /// In es, this message translates to:
  /// **'Agregar un comentario...'**
  String get addComment;

  /// No description provided for @youNeedToBeLoggedInToLike.
  ///
  /// In es, this message translates to:
  /// **'Necesitas estar conectado para dar me gusta'**
  String get youNeedToBeLoggedInToLike;

  /// No description provided for @errorProcessingLike.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar me gusta: {error}'**
  String errorProcessingLike(String error);

  /// No description provided for @mostLikedFirst.
  ///
  /// In es, this message translates to:
  /// **'Más gustados primero'**
  String get mostLikedFirst;

  /// No description provided for @leastLikedFirst.
  ///
  /// In es, this message translates to:
  /// **'Menos gustados primero'**
  String get leastLikedFirst;

  /// No description provided for @mostRecentFirst.
  ///
  /// In es, this message translates to:
  /// **'Más recientes primero'**
  String get mostRecentFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In es, this message translates to:
  /// **'Más antiguos primero'**
  String get oldestFirst;

  /// No description provided for @sentOn.
  ///
  /// In es, this message translates to:
  /// **'Enviada el {date}'**
  String sentOn(String date);

  /// No description provided for @respondedBy.
  ///
  /// In es, this message translates to:
  /// **'Respondida por:'**
  String get respondedBy;

  /// No description provided for @assignedTo.
  ///
  /// In es, this message translates to:
  /// **'Asignada a:'**
  String get assignedTo;

  /// No description provided for @myPrayer.
  ///
  /// In es, this message translates to:
  /// **'Mi oración:'**
  String get myPrayer;

  /// No description provided for @pastorResponse.
  ///
  /// In es, this message translates to:
  /// **'Respuesta del pastor:'**
  String get pastorResponse;

  /// No description provided for @respondedOnDate.
  ///
  /// In es, this message translates to:
  /// **'Respondido el {date}'**
  String respondedOnDate(String date);

  /// No description provided for @yourRequestWasAcceptedWillBeAttended.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud fue aceptada y será atendida en breve.'**
  String get yourRequestWasAcceptedWillBeAttended;

  /// No description provided for @predefinedMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje Predefinido'**
  String get predefinedMessage;

  /// No description provided for @messageSavedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Mensaje guardado con éxito'**
  String get messageSavedSuccessfully;

  /// No description provided for @errorSavingMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar el mensaje'**
  String get errorSavingMessage;

  /// No description provided for @errorLoadingMessages.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar mensajes: {error}'**
  String errorLoadingMessages(String error);

  /// No description provided for @sureYouWantToDeleteThisMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este mensaje?'**
  String get sureYouWantToDeleteThisMessage;

  /// No description provided for @messageDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Mensaje eliminado con éxito'**
  String get messageDeletedSuccessfully;

  /// No description provided for @errorDeleting2.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar: {error}'**
  String errorDeleting2(String error);

  /// No description provided for @createMessageYouCanUseRepeatedly.
  ///
  /// In es, this message translates to:
  /// **'Crea un mensaje que podrás usar repetidamente como respuesta a oraciones privadas.'**
  String get createMessageYouCanUseRepeatedly;

  /// No description provided for @messageContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido del mensaje'**
  String get messageContent;

  /// No description provided for @writeHereThePredefinedMessageContent.
  ///
  /// In es, this message translates to:
  /// **'Escribe aquí el contenido del mensaje predefinido...'**
  String get writeHereThePredefinedMessageContent;

  /// No description provided for @pleaseEnterMessageContent.
  ///
  /// In es, this message translates to:
  /// **'Por favor, introduce el contenido del mensaje'**
  String get pleaseEnterMessageContent;

  /// No description provided for @savedMessages.
  ///
  /// In es, this message translates to:
  /// **'Mensajes Guardados'**
  String get savedMessages;

  /// No description provided for @noPredefinedMessagesSavedYet.
  ///
  /// In es, this message translates to:
  /// **'Ningún mensaje predefinido guardado aún.'**
  String get noPredefinedMessagesSavedYet;

  /// No description provided for @deleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mensaje'**
  String get deleteMessage;

  /// No description provided for @respondPrayer.
  ///
  /// In es, this message translates to:
  /// **'Responder Oración'**
  String get respondPrayer;

  /// No description provided for @responseSentSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Respuesta enviada correctamente'**
  String get responseSentSuccessfully;

  /// No description provided for @errorSendingResponse.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar la respuesta'**
  String get errorSendingResponse;

  /// No description provided for @loadingRequesterData.
  ///
  /// In es, this message translates to:
  /// **'Cargando datos del solicitante...'**
  String get loadingRequesterData;

  /// No description provided for @prayerRequest2.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de oración:'**
  String get prayerRequest2;

  /// No description provided for @receivedOn.
  ///
  /// In es, this message translates to:
  /// **'Recibida el {date}'**
  String receivedOn(String date);

  /// No description provided for @predefinedMessages2.
  ///
  /// In es, this message translates to:
  /// **'Mensajes predefinidos:'**
  String get predefinedMessages2;

  /// No description provided for @reloadMessages.
  ///
  /// In es, this message translates to:
  /// **'Recargar mensajes'**
  String get reloadMessages;

  /// No description provided for @writeYourResponseHere.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu respuesta aquí...'**
  String get writeYourResponseHere;

  /// No description provided for @sendResponse.
  ///
  /// In es, this message translates to:
  /// **'Enviar Respuesta'**
  String get sendResponse;

  /// No description provided for @noPredefinedMessages.
  ///
  /// In es, this message translates to:
  /// **'No hay mensajes predefinidos'**
  String get noPredefinedMessages;

  /// No description provided for @pleaseSelectACult.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona un servicio'**
  String get pleaseSelectACult;

  /// No description provided for @youMustBeLoggedInToAssignPrayers.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para asignar oraciones'**
  String get youMustBeLoggedInToAssignPrayers;

  /// No description provided for @prayerAssignedSuccessfullyToCult.
  ///
  /// In es, this message translates to:
  /// **'Oración asignada exitosamente al servicio {cultName}'**
  String prayerAssignedSuccessfullyToCult(String cultName);

  /// No description provided for @errorAssigningPrayerToCult.
  ///
  /// In es, this message translates to:
  /// **'Error al asignar oración al servicio'**
  String get errorAssigningPrayerToCult;

  /// No description provided for @errorAssigningPrayer.
  ///
  /// In es, this message translates to:
  /// **'Error al asignar oración: {error}'**
  String errorAssigningPrayer(String error);

  /// No description provided for @searchCultByNameOrDate.
  ///
  /// In es, this message translates to:
  /// **'Buscar servicio por nombre o fecha'**
  String get searchCultByNameOrDate;

  /// No description provided for @prayerDetail.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la Oración'**
  String get prayerDetail;

  /// No description provided for @received.
  ///
  /// In es, this message translates to:
  /// **'Recibida:'**
  String get received;

  /// No description provided for @yourPrayerRequest.
  ///
  /// In es, this message translates to:
  /// **'Tu petición de oración:'**
  String get yourPrayerRequest;

  /// No description provided for @scheduledPrayer.
  ///
  /// In es, this message translates to:
  /// **'Oración programada'**
  String get scheduledPrayer;

  /// No description provided for @method.
  ///
  /// In es, this message translates to:
  /// **'Método:'**
  String get method;

  /// No description provided for @pastorResponse2.
  ///
  /// In es, this message translates to:
  /// **'Respuesta del pastor'**
  String get pastorResponse2;

  /// No description provided for @learnWithOurExclusiveCourses.
  ///
  /// In es, this message translates to:
  /// **'Aprende con nuestros cursos exclusivos'**
  String get learnWithOurExclusiveCourses;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @selectYourPreferredLanguage.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu idioma preferido'**
  String get selectYourPreferredLanguage;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @portugueseBrazil.
  ///
  /// In es, this message translates to:
  /// **'Português (Brasil)'**
  String get portugueseBrazil;

  /// No description provided for @languageChangedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Idioma cambiado exitosamente'**
  String get languageChangedSuccessfully;

  /// No description provided for @endDateMustBeAfterStartDate.
  ///
  /// In es, this message translates to:
  /// **'La fecha de término debe ser posterior a la fecha de inicio'**
  String get endDateMustBeAfterStartDate;

  /// No description provided for @createGroupEvent.
  ///
  /// In es, this message translates to:
  /// **'Crear Evento del Grupo'**
  String get createGroupEvent;

  /// No description provided for @createMinistryEvent.
  ///
  /// In es, this message translates to:
  /// **'Crear Evento del Ministerio'**
  String get createMinistryEvent;

  /// No description provided for @eventTitle.
  ///
  /// In es, this message translates to:
  /// **'Título del evento'**
  String get eventTitle;

  /// No description provided for @exWeeklyMeeting.
  ///
  /// In es, this message translates to:
  /// **'Ej: Reunión semanal'**
  String get exWeeklyMeeting;

  /// No description provided for @eventDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles sobre el evento...'**
  String get eventDetails;

  /// No description provided for @startDateAndTime.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora de inicio'**
  String get startDateAndTime;

  /// No description provided for @endDateAndTime.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora de término'**
  String get endDateAndTime;

  /// No description provided for @exMainHall.
  ///
  /// In es, this message translates to:
  /// **'Ej: Salón principal'**
  String get exMainHall;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa una localización'**
  String get pleaseEnterLocation;

  /// No description provided for @imageOptional.
  ///
  /// In es, this message translates to:
  /// **'Imagen (opcional)'**
  String get imageOptional;

  /// No description provided for @addImageIn16x9.
  ///
  /// In es, this message translates to:
  /// **'Adicionar imagen en formato 16:9'**
  String get addImageIn16x9;

  /// No description provided for @eventCoverImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen de portada del evento'**
  String get eventCoverImage;

  /// No description provided for @saveInformation.
  ///
  /// In es, this message translates to:
  /// **'Guardar Información'**
  String get saveInformation;

  /// No description provided for @saveAll.
  ///
  /// In es, this message translates to:
  /// **'Guardar Todo'**
  String get saveAll;

  /// No description provided for @featuredMembersSection.
  ///
  /// In es, this message translates to:
  /// **'Sección \"Miembros Destacados\"'**
  String get featuredMembersSection;

  /// No description provided for @showThisSection.
  ///
  /// In es, this message translates to:
  /// **'¿Mostrar esta sección?'**
  String get showThisSection;

  /// No description provided for @sectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Título de la Sección'**
  String get sectionTitle;

  /// No description provided for @exLeadershipContacts.
  ///
  /// In es, this message translates to:
  /// **'Ej: Liderazgo, Contactos...'**
  String get exLeadershipContacts;

  /// No description provided for @selectMembersToHighlight.
  ///
  /// In es, this message translates to:
  /// **'Selecciona miembros para destacar y edita sus informaciones:'**
  String get selectMembersToHighlight;

  /// No description provided for @mainDescriptionOf.
  ///
  /// In es, this message translates to:
  /// **'Descripción Principal del'**
  String get mainDescriptionOf;

  /// No description provided for @optionalDescriptionTitle.
  ///
  /// In es, this message translates to:
  /// **'Título Opcional de la Descripción'**
  String get optionalDescriptionTitle;

  /// No description provided for @exAboutUsPurpose.
  ///
  /// In es, this message translates to:
  /// **'Ej: Sobre Nosotros, Nuestro Propósito...'**
  String get exAboutUsPurpose;

  /// No description provided for @typeMainDescriptionHere.
  ///
  /// In es, this message translates to:
  /// **'Escribe la descripción principal aquí...'**
  String get typeMainDescriptionHere;

  /// No description provided for @noAdditionalInfo.
  ///
  /// In es, this message translates to:
  /// **'(Sin info adicional)'**
  String get noAdditionalInfo;

  /// No description provided for @infoDefined.
  ///
  /// In es, this message translates to:
  /// **'(Info definida)'**
  String get infoDefined;

  /// No description provided for @errorReadingInfo.
  ///
  /// In es, this message translates to:
  /// **'(Error al leer info)'**
  String get errorReadingInfo;

  /// No description provided for @editInfo.
  ///
  /// In es, this message translates to:
  /// **'Editar Info'**
  String get editInfo;

  /// No description provided for @editInfoFor.
  ///
  /// In es, this message translates to:
  /// **'Editar Info:'**
  String get editInfoFor;

  /// No description provided for @editContent.
  ///
  /// In es, this message translates to:
  /// **'Editar Contenido'**
  String get editContent;

  /// No description provided for @typeContentHere.
  ///
  /// In es, this message translates to:
  /// **'Escribe el contenido aquí...'**
  String get typeContentHere;

  /// No description provided for @errorSavingInformation.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar informaciones.'**
  String get errorSavingInformation;

  /// No description provided for @errorInitializingEditor.
  ///
  /// In es, this message translates to:
  /// **'Error al inicializar editor.'**
  String get errorInitializingEditor;

  /// No description provided for @notFound.
  ///
  /// In es, this message translates to:
  /// **'no encontrado.'**
  String get notFound;

  /// No description provided for @createNewService.
  ///
  /// In es, this message translates to:
  /// **'Crear Nuevo Servicio'**
  String get createNewService;

  /// No description provided for @pleaseEnterServiceName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un nombre para el servicio'**
  String get pleaseEnterServiceName;

  /// No description provided for @noPermissionToCreateServices.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para crear servicios'**
  String get noPermissionToCreateServices;

  /// No description provided for @serviceCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Servicio creado con éxito'**
  String get serviceCreatedSuccessfully;

  /// No description provided for @errorCreatingService.
  ///
  /// In es, this message translates to:
  /// **'Error al crear el servicio'**
  String get errorCreatingService;

  /// No description provided for @editService.
  ///
  /// In es, this message translates to:
  /// **'Editar Servicio'**
  String get editService;

  /// No description provided for @noPermissionToUpdateServices.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para actualizar servicios'**
  String get noPermissionToUpdateServices;

  /// No description provided for @serviceUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Servicio actualizado con éxito'**
  String get serviceUpdatedSuccessfully;

  /// No description provided for @errorUpdatingService.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar el servicio'**
  String get errorUpdatingService;

  /// No description provided for @deleteService.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Servicio'**
  String get deleteService;

  /// No description provided for @sureDeleteServiceAndContent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar el servicio \"{serviceName}\" y todo su contenido? Esta acción no se puede deshacer.'**
  String sureDeleteServiceAndContent(Object serviceName);

  /// No description provided for @noPermissionToDeleteServices.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para eliminar servicios'**
  String get noPermissionToDeleteServices;

  /// No description provided for @deletingServiceAndContent.
  ///
  /// In es, this message translates to:
  /// **'Eliminando servicio y todo su contenido...'**
  String get deletingServiceAndContent;

  /// No description provided for @serviceDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Servicio eliminado con éxito'**
  String get serviceDeletedSuccessfully;

  /// No description provided for @errorDeletingService.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el servicio'**
  String get errorDeletingService;

  /// No description provided for @noPermissionToManageCults.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar cultos.'**
  String get noPermissionToManageCults;

  /// No description provided for @noServicesAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay servicios disponibles'**
  String get noServicesAvailable;

  /// No description provided for @createService.
  ///
  /// In es, this message translates to:
  /// **'Crear Servicio'**
  String get createService;

  /// No description provided for @createCultAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Crear Anuncio del Culto'**
  String get createCultAnnouncement;

  /// No description provided for @pleaseEnterTitle2.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un título'**
  String get pleaseEnterTitle2;

  /// No description provided for @cultInformation.
  ///
  /// In es, this message translates to:
  /// **'Información sobre el culto...'**
  String get cultInformation;

  /// No description provided for @pleaseEnterDescription2.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa una descripción'**
  String get pleaseEnterDescription2;

  /// No description provided for @linkedEventOptional.
  ///
  /// In es, this message translates to:
  /// **'Evento Vinculado (Opcional)'**
  String get linkedEventOptional;

  /// No description provided for @selectEvent.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Evento'**
  String get selectEvent;

  /// No description provided for @eventLinkedToAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Evento vinculado a este anuncio'**
  String get eventLinkedToAnnouncement;

  /// No description provided for @announcementStartDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de inicio del anuncio'**
  String get announcementStartDate;

  /// No description provided for @willBeAdaptedTo16x9.
  ///
  /// In es, this message translates to:
  /// **'Será adaptada automáticamente al formato 16:9'**
  String get willBeAdaptedTo16x9;

  /// No description provided for @processingImage.
  ///
  /// In es, this message translates to:
  /// **'Procesando imagen...'**
  String get processingImage;

  /// No description provided for @pleaseSelectOrEnterLocation.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona o ingresa una localización'**
  String get pleaseSelectOrEnterLocation;

  /// No description provided for @selectingEvent.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Evento'**
  String get selectingEvent;

  /// No description provided for @selectEventToLink.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar evento'**
  String get selectEventToLink;

  /// No description provided for @noEventsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos disponibles'**
  String get noEventsAvailable;

  /// No description provided for @eventWithoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Evento sin título'**
  String get eventWithoutTitle;

  /// No description provided for @createTicketForRegistration.
  ///
  /// In es, this message translates to:
  /// **'Crea una entrada para que los usuarios puedan registrarse'**
  String get createTicketForRegistration;

  /// No description provided for @viewQR.
  ///
  /// In es, this message translates to:
  /// **'Ver QR'**
  String get viewQR;

  /// No description provided for @mustBeLoggedToRegisterAttendance.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión para registrar tu asistencia'**
  String get mustBeLoggedToRegisterAttendance;

  /// No description provided for @sureDeleteEvent.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar este evento?'**
  String get sureDeleteEvent;

  /// No description provided for @sureDeleteTicket.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar esta entrada? Esta acción no se puede deshacer.'**
  String get sureDeleteTicket;

  /// No description provided for @sureDeleteYourTicket.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar tu entrada? Esta acción no se puede deshacer.'**
  String get sureDeleteYourTicket;

  /// No description provided for @enterLinkForOnlineAccess.
  ///
  /// In es, this message translates to:
  /// **'Introduce el enlace para que los asistentes accedan al evento online:'**
  String get enterLinkForOnlineAccess;

  /// No description provided for @eventURL.
  ///
  /// In es, this message translates to:
  /// **'URL del evento'**
  String get eventURL;

  /// No description provided for @linkMustStartWithHttp.
  ///
  /// In es, this message translates to:
  /// **'El enlace debe comenzar con http:// o https://'**
  String get linkMustStartWithHttp;

  /// No description provided for @removeLink.
  ///
  /// In es, this message translates to:
  /// **'Eliminar enlace'**
  String get removeLink;

  /// No description provided for @eventLinkRemovedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Enlace del evento eliminado correctamente'**
  String get eventLinkRemovedSuccessfully;

  /// No description provided for @eventLinkUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Enlace del evento actualizado correctamente'**
  String get eventLinkUpdatedSuccessfully;

  /// No description provided for @eventLinkAddedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Enlace del evento añadido correctamente'**
  String get eventLinkAddedSuccessfully;

  /// No description provided for @noPermissionToDeleteThisEvent.
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para eliminar este evento'**
  String get noPermissionToDeleteThisEvent;

  /// No description provided for @eventDeletedSuccessfully2.
  ///
  /// In es, this message translates to:
  /// **'Evento eliminado con éxito'**
  String get eventDeletedSuccessfully2;

  /// No description provided for @errorDeletingEvent.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar el evento: {error}'**
  String errorDeletingEvent(String error);

  /// No description provided for @youConfirmedAttendance.
  ///
  /// In es, this message translates to:
  /// **'Confirmaste tu presencia'**
  String get youConfirmedAttendance;

  /// No description provided for @youCancelledAttendance.
  ///
  /// In es, this message translates to:
  /// **'Cancelaste tu presencia'**
  String get youCancelledAttendance;

  /// No description provided for @errorUpdatingAttendance.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar presencia: {error}'**
  String errorUpdatingAttendance(String error);

  /// No description provided for @addReminder.
  ///
  /// In es, this message translates to:
  /// **'Adicionar Lembrete'**
  String get addReminder;

  /// No description provided for @reminderAdded.
  ///
  /// In es, this message translates to:
  /// **'Lembrete Adicionado'**
  String get reminderAdded;

  /// No description provided for @errorSettingReminder.
  ///
  /// In es, this message translates to:
  /// **'Error al configurar recordatorio: {error}'**
  String errorSettingReminder(String error);

  /// No description provided for @decline.
  ///
  /// In es, this message translates to:
  /// **'Declinar'**
  String get decline;

  /// No description provided for @participate.
  ///
  /// In es, this message translates to:
  /// **'Participar'**
  String get participate;

  /// No description provided for @participants.
  ///
  /// In es, this message translates to:
  /// **'Participantes'**
  String get participants;

  /// No description provided for @attendees.
  ///
  /// In es, this message translates to:
  /// **'Asistentes ({count})'**
  String attendees(int count);

  /// No description provided for @noOneConfirmedYet.
  ///
  /// In es, this message translates to:
  /// **'Nadie confirmó presencia aún'**
  String get noOneConfirmedYet;

  /// No description provided for @appCustomization.
  ///
  /// In es, this message translates to:
  /// **'Personalización de la App'**
  String get appCustomization;

  /// No description provided for @appCustomizationDescription.
  ///
  /// In es, this message translates to:
  /// **'Personaliza el nombre y logo de la app'**
  String get appCustomizationDescription;

  /// No description provided for @churchNameConfig.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Iglesia'**
  String get churchNameConfig;

  /// No description provided for @churchLogoConfig.
  ///
  /// In es, this message translates to:
  /// **'Logo de la Iglesia'**
  String get churchLogoConfig;

  /// No description provided for @uploadLogo.
  ///
  /// In es, this message translates to:
  /// **'Subir Logo'**
  String get uploadLogo;

  /// No description provided for @errorSelectingImageText.
  ///
  /// In es, this message translates to:
  /// **'Error al seleccionar imagen'**
  String get errorSelectingImageText;

  /// No description provided for @changeLinkedEvent.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Evento Vinculado'**
  String get changeLinkedEvent;

  /// No description provided for @currentlyLinkedEvent.
  ///
  /// In es, this message translates to:
  /// **'Evento vinculado actualmente'**
  String get currentlyLinkedEvent;

  /// No description provided for @unlinkEvent.
  ///
  /// In es, this message translates to:
  /// **'Desvincular evento'**
  String get unlinkEvent;

  /// No description provided for @selectFutureEventToLink.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un evento futuro para vincularlo con este anuncio.'**
  String get selectFutureEventToLink;

  /// No description provided for @selectOtherFutureEventToLink.
  ///
  /// In es, this message translates to:
  /// **'Selecciona otro evento futuro para cambiar el vínculo.'**
  String get selectOtherFutureEventToLink;

  /// No description provided for @noFutureEventsAvailable.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos futuros disponibles'**
  String get noFutureEventsAvailable;

  /// No description provided for @fillAllRequiredFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor, rellena todos los campos obligatorios.'**
  String get fillAllRequiredFields;

  /// No description provided for @pleaseSelectDateForAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Por favor selecciona una fecha para el anuncio.'**
  String get pleaseSelectDateForAnnouncement;

  /// No description provided for @errorDeletingPreviousImage.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar imagen anterior'**
  String get errorDeletingPreviousImage;

  /// No description provided for @errorDeletingPreviousImageMayNotExist.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar imagen anterior (puede que ya no exista)'**
  String get errorDeletingPreviousImageMayNotExist;

  /// No description provided for @announcementUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Anuncio actualizado con éxito'**
  String get announcementUpdatedSuccessfully;

  /// No description provided for @errorUpdatingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar anuncio'**
  String get errorUpdatingAnnouncement;

  /// No description provided for @editCultAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Editar Anuncio de Culto'**
  String get editCultAnnouncement;

  /// No description provided for @regularAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Anuncio Regular'**
  String get regularAnnouncement;

  /// No description provided for @announcementImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen del Anuncio'**
  String get announcementImage;

  /// No description provided for @announcementTitlePlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Título del anuncio'**
  String get announcementTitlePlaceholder;

  /// No description provided for @detailedAnnouncementDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción detallada del anuncio'**
  String get detailedAnnouncementDescription;

  /// No description provided for @announcementDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha del Anuncio'**
  String get announcementDate;

  /// No description provided for @savingText.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get savingText;

  /// No description provided for @errorLoadingImage.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar imagen'**
  String get errorLoadingImage;

  /// No description provided for @tapToChangeImage.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar la imagen'**
  String get tapToChangeImage;

  /// No description provided for @beFirstToPublish.
  ///
  /// In es, this message translates to:
  /// **'¡Sé el primero en publicar!'**
  String get beFirstToPublish;

  /// No description provided for @ministryNoPostsYet.
  ///
  /// In es, this message translates to:
  /// **'Este ministerio aún no tiene publicaciones. ¿Qué tal compartir algo inspirador para la comunidad?'**
  String get ministryNoPostsYet;

  /// No description provided for @groupNoPostsYet.
  ///
  /// In es, this message translates to:
  /// **'Este grupo aún no tiene publicaciones. Inicia la conversación compartiendo algo interesante con los otros miembros.'**
  String get groupNoPostsYet;

  /// No description provided for @shareWithGroup.
  ///
  /// In es, this message translates to:
  /// **'¡Comparte algo con tu grupo!'**
  String get shareWithGroup;

  /// No description provided for @createPost.
  ///
  /// In es, this message translates to:
  /// **'Crear publicación'**
  String get createPost;

  /// No description provided for @newItem.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newItem;

  /// No description provided for @memberManagement.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Miembros'**
  String get memberManagement;

  /// No description provided for @hideStatistics.
  ///
  /// In es, this message translates to:
  /// **'Ocultar estadísticas'**
  String get hideStatistics;

  /// No description provided for @viewStatistics.
  ///
  /// In es, this message translates to:
  /// **'Ver estadísticas'**
  String get viewStatistics;

  /// No description provided for @requestStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de solicitudes'**
  String get requestStatistics;

  /// No description provided for @allUpToDate.
  ///
  /// In es, this message translates to:
  /// **'¡Todo al día!'**
  String get allUpToDate;

  /// No description provided for @noApprovedRequests.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes aprobadas'**
  String get noApprovedRequests;

  /// No description provided for @noRejectedRequests.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes rechazadas'**
  String get noRejectedRequests;

  /// No description provided for @noExitsRecorded.
  ///
  /// In es, this message translates to:
  /// **'No hay salidas registradas'**
  String get noExitsRecorded;

  /// No description provided for @chat.
  ///
  /// In es, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @info.
  ///
  /// In es, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @requested.
  ///
  /// In es, this message translates to:
  /// **'Solicitado'**
  String get requested;

  /// No description provided for @responseTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de respuesta'**
  String get responseTime;

  /// No description provided for @noMemberExitsMinistry.
  ///
  /// In es, this message translates to:
  /// **'Ningún miembro ha salido del ministerio'**
  String get noMemberExitsMinistry;

  /// No description provided for @noMemberExitsGroup.
  ///
  /// In es, this message translates to:
  /// **'Ningún miembro ha salido del grupo'**
  String get noMemberExitsGroup;

  /// No description provided for @exitedOn.
  ///
  /// In es, this message translates to:
  /// **'Salió el'**
  String get exitedOn;

  /// No description provided for @approvedOn.
  ///
  /// In es, this message translates to:
  /// **'Aprobado el'**
  String get approvedOn;

  /// No description provided for @rejectedOn.
  ///
  /// In es, this message translates to:
  /// **'Rechazado el'**
  String get rejectedOn;

  /// No description provided for @voluntaryExit.
  ///
  /// In es, this message translates to:
  /// **'Salida voluntaria'**
  String get voluntaryExit;

  /// No description provided for @timeInMinistry.
  ///
  /// In es, this message translates to:
  /// **'Tiempo en el ministerio'**
  String get timeInMinistry;

  /// No description provided for @timeInGroup.
  ///
  /// In es, this message translates to:
  /// **'Tiempo en el grupo'**
  String get timeInGroup;

  /// No description provided for @addUsers.
  ///
  /// In es, this message translates to:
  /// **'Agregar usuarios'**
  String get addUsers;

  /// No description provided for @showOnlyNonMembers.
  ///
  /// In es, this message translates to:
  /// **'Mostrar solo usuarios que no son miembros'**
  String get showOnlyNonMembers;

  /// No description provided for @usersSelected.
  ///
  /// In es, this message translates to:
  /// **'Usuarios seleccionados'**
  String get usersSelected;

  /// No description provided for @member.
  ///
  /// In es, this message translates to:
  /// **'Miembro'**
  String get member;

  /// No description provided for @addSelectedUsers.
  ///
  /// In es, this message translates to:
  /// **'Agregar usuarios seleccionados'**
  String get addSelectedUsers;

  /// No description provided for @manageRequests.
  ///
  /// In es, this message translates to:
  /// **'Gestionar solicitudes'**
  String get manageRequests;

  /// No description provided for @hour.
  ///
  /// In es, this message translates to:
  /// **'hora'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In es, this message translates to:
  /// **'minuto'**
  String get minute;

  /// No description provided for @second.
  ///
  /// In es, this message translates to:
  /// **'segundo'**
  String get second;

  /// No description provided for @seconds.
  ///
  /// In es, this message translates to:
  /// **'segundos'**
  String get seconds;

  /// No description provided for @usersAddedToMinistry.
  ///
  /// In es, this message translates to:
  /// **'{count} usuarios agregados al ministerio'**
  String usersAddedToMinistry(int count);

  /// No description provided for @usersAddedToGroup.
  ///
  /// In es, this message translates to:
  /// **'{count} usuarios agregados al grupo'**
  String usersAddedToGroup(int count);

  /// No description provided for @requestAcceptedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Solicitud aceptada correctamente'**
  String get requestAcceptedSuccessfully;

  /// No description provided for @requestRejected.
  ///
  /// In es, this message translates to:
  /// **'Solicitud rechazada'**
  String get requestRejected;

  /// No description provided for @groupInformation.
  ///
  /// In es, this message translates to:
  /// **'Información del grupo'**
  String get groupInformation;

  /// No description provided for @ministryInformation.
  ///
  /// In es, this message translates to:
  /// **'Información del ministerio'**
  String get ministryInformation;

  /// No description provided for @addDescription.
  ///
  /// In es, this message translates to:
  /// **'Agregar descripción...'**
  String get addDescription;

  /// No description provided for @addMinistryDescription.
  ///
  /// In es, this message translates to:
  /// **'Agregar descripción del ministerio...'**
  String get addMinistryDescription;

  /// No description provided for @createdBy.
  ///
  /// In es, this message translates to:
  /// **'Creado por {name} · {date}'**
  String createdBy(String name, String date);

  /// No description provided for @filesLinksAndDocuments.
  ///
  /// In es, this message translates to:
  /// **'Archivos, enlaces y documentos'**
  String get filesLinksAndDocuments;

  /// No description provided for @noSharedFiles.
  ///
  /// In es, this message translates to:
  /// **'No hay archivos compartidos'**
  String get noSharedFiles;

  /// No description provided for @searchMember.
  ///
  /// In es, this message translates to:
  /// **'Buscar miembro'**
  String get searchMember;

  /// No description provided for @leaveGroup.
  ///
  /// In es, this message translates to:
  /// **'Salir del grupo'**
  String get leaveGroup;

  /// No description provided for @leaveMinistry.
  ///
  /// In es, this message translates to:
  /// **'Salir del ministerio'**
  String get leaveMinistry;

  /// No description provided for @viewProfileOf.
  ///
  /// In es, this message translates to:
  /// **'Ver perfil de'**
  String get viewProfileOf;

  /// No description provided for @remove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get remove;

  /// No description provided for @groupAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin. del grupo'**
  String get groupAdmin;

  /// No description provided for @ministryAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin. del ministerio'**
  String get ministryAdmin;

  /// No description provided for @cannotLeaveAsOnlyAdmin.
  ///
  /// In es, this message translates to:
  /// **'No puedes salir porque eres el único administrador'**
  String get cannotLeaveAsOnlyAdmin;

  /// No description provided for @areYouSureLeaveGroup.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas salir de este grupo?'**
  String get areYouSureLeaveGroup;

  /// No description provided for @areYouSureLeaveMinistry.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas salir de este ministerio?'**
  String get areYouSureLeaveMinistry;

  /// No description provided for @leave.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get leave;

  /// No description provided for @youLeftTheGroup.
  ///
  /// In es, this message translates to:
  /// **'Has salido del grupo'**
  String get youLeftTheGroup;

  /// No description provided for @youLeftTheMinistry.
  ///
  /// In es, this message translates to:
  /// **'Has salido del ministerio'**
  String get youLeftTheMinistry;

  /// No description provided for @errorLeavingGroup.
  ///
  /// In es, this message translates to:
  /// **'Error al salir del grupo'**
  String get errorLeavingGroup;

  /// No description provided for @errorLeavingMinistry.
  ///
  /// In es, this message translates to:
  /// **'Error al salir del ministerio'**
  String get errorLeavingMinistry;

  /// No description provided for @areYouSureDeleteGroup.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro? Esta acción no se puede deshacer y eliminará todo el contenido del grupo.'**
  String get areYouSureDeleteGroup;

  /// No description provided for @areYouSureDeleteMinistry.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro? Esta acción no se puede deshacer y eliminará todo el contenido del ministerio.'**
  String get areYouSureDeleteMinistry;

  /// No description provided for @groupDeleted.
  ///
  /// In es, this message translates to:
  /// **'Grupo eliminado'**
  String get groupDeleted;

  /// No description provided for @ministryDeleted.
  ///
  /// In es, this message translates to:
  /// **'Ministerio eliminado'**
  String get ministryDeleted;

  /// No description provided for @removeMember.
  ///
  /// In es, this message translates to:
  /// **'Eliminar miembro'**
  String get removeMember;

  /// No description provided for @areYouSureRemoveMemberMinistry.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar a {name} del ministerio?'**
  String areYouSureRemoveMemberMinistry(String name);

  /// No description provided for @memberRemovedFromGroup.
  ///
  /// In es, this message translates to:
  /// **'Miembro eliminado del grupo'**
  String get memberRemovedFromGroup;

  /// No description provided for @memberRemovedFromMinistry.
  ///
  /// In es, this message translates to:
  /// **'Miembro eliminado del ministerio'**
  String get memberRemovedFromMinistry;

  /// No description provided for @errorRemovingMember.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar miembro'**
  String get errorRemovingMember;

  /// No description provided for @cannotOpenInvalidFileUrl.
  ///
  /// In es, this message translates to:
  /// **'No se puede abrir: URL de archivo inválida'**
  String get cannotOpenInvalidFileUrl;

  /// No description provided for @downloadFile.
  ///
  /// In es, this message translates to:
  /// **'Descargar archivo'**
  String get downloadFile;

  /// No description provided for @download.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get download;

  /// No description provided for @noMemberFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún miembro encontrado'**
  String get noMemberFound;

  /// No description provided for @noMembersMatchingSearch.
  ///
  /// In es, this message translates to:
  /// **'No hay miembros que correspondan a \'{query}\''**
  String noMembersMatchingSearch(String query);

  /// No description provided for @thisGroupNoLongerExists.
  ///
  /// In es, this message translates to:
  /// **'Este grupo ya no existe'**
  String get thisGroupNoLongerExists;

  /// No description provided for @thisMinistryNoLongerExists.
  ///
  /// In es, this message translates to:
  /// **'Este ministerio ya no existe'**
  String get thisMinistryNoLongerExists;

  /// No description provided for @notificationsEnabled.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones activadas'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones desactivadas'**
  String get notificationsDisabled;

  /// No description provided for @errorUpdatingNotificationSettings.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar configuración de notificaciones'**
  String get errorUpdatingNotificationSettings;

  /// No description provided for @makeAdmin.
  ///
  /// In es, this message translates to:
  /// **'Hacer administrador'**
  String get makeAdmin;

  /// No description provided for @makeGroupAdmin.
  ///
  /// In es, this message translates to:
  /// **'Hacer administrador del grupo'**
  String get makeGroupAdmin;

  /// No description provided for @makeMinistryAdmin.
  ///
  /// In es, this message translates to:
  /// **'Hacer administrador del ministerio'**
  String get makeMinistryAdmin;

  /// No description provided for @confirmMakeAdmin.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nuevo administrador'**
  String get confirmMakeAdmin;

  /// No description provided for @confirmMakeGroupAdmin.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas hacer a {name} administrador del grupo?'**
  String confirmMakeGroupAdmin(String name);

  /// No description provided for @confirmMakeMinistryAdmin.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas hacer a {name} administrador del ministerio?'**
  String confirmMakeMinistryAdmin(String name);

  /// No description provided for @userIsNowGroupAdmin.
  ///
  /// In es, this message translates to:
  /// **'{name} ahora es administrador del grupo'**
  String userIsNowGroupAdmin(String name);

  /// No description provided for @userIsNowMinistryAdmin.
  ///
  /// In es, this message translates to:
  /// **'{name} ahora es administrador del ministerio'**
  String userIsNowMinistryAdmin(String name);

  /// No description provided for @errorMakingGroupAdmin.
  ///
  /// In es, this message translates to:
  /// **'Error al hacer administrador del grupo'**
  String get errorMakingGroupAdmin;

  /// No description provided for @errorMakingMinistryAdmin.
  ///
  /// In es, this message translates to:
  /// **'Error al hacer administrador del ministerio'**
  String get errorMakingMinistryAdmin;

  /// No description provided for @cannotLeaveOnlyAdmin.
  ///
  /// In es, this message translates to:
  /// **'No puedes salir porque eres el único administrador'**
  String get cannotLeaveOnlyAdmin;

  /// No description provided for @youLeftMinistry.
  ///
  /// In es, this message translates to:
  /// **'Has salido del ministerio'**
  String get youLeftMinistry;

  /// No description provided for @errorDeletingMinistry2.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar ministerio'**
  String get errorDeletingMinistry2;

  /// No description provided for @ministryNoName.
  ///
  /// In es, this message translates to:
  /// **'Ministerio sin nombre'**
  String get ministryNoName;

  /// No description provided for @ministryMembers.
  ///
  /// In es, this message translates to:
  /// **'Ministerio · {count} miembros'**
  String ministryMembers(int count);

  /// No description provided for @adminOfMinistry.
  ///
  /// In es, this message translates to:
  /// **'Admin. del ministerio'**
  String get adminOfMinistry;

  /// No description provided for @selectedUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios seleccionados: {count}'**
  String selectedUsers(int count);

  /// No description provided for @noUserFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún usuario encontrado'**
  String get noUserFound;

  /// No description provided for @errorProcessingUserAddition.
  ///
  /// In es, this message translates to:
  /// **'Error al procesar la adición de usuarios'**
  String get errorProcessingUserAddition;

  /// No description provided for @filesLinksDocuments.
  ///
  /// In es, this message translates to:
  /// **'Archivos, enlaces y documentos'**
  String get filesLinksDocuments;

  /// No description provided for @xMembers.
  ///
  /// In es, this message translates to:
  /// **'{count} miembros'**
  String xMembers(int count);

  /// No description provided for @errorLoadingMembers2.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar miembros'**
  String get errorLoadingMembers2;

  /// No description provided for @newPost.
  ///
  /// In es, this message translates to:
  /// **'Nueva publicación'**
  String get newPost;

  /// No description provided for @whatDoYouWantToShare.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres compartilhar?'**
  String get whatDoYouWantToShare;

  /// No description provided for @selectedImages.
  ///
  /// In es, this message translates to:
  /// **'Imágenes seleccionadas:'**
  String get selectedImages;

  /// No description provided for @imageAspectRatio.
  ///
  /// In es, this message translates to:
  /// **'Proporción de la imagen:'**
  String get imageAspectRatio;

  /// No description provided for @square.
  ///
  /// In es, this message translates to:
  /// **'Cuadrada'**
  String get square;

  /// No description provided for @vertical.
  ///
  /// In es, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// No description provided for @horizontal.
  ///
  /// In es, this message translates to:
  /// **'Horizontal'**
  String get horizontal;

  /// No description provided for @addImages.
  ///
  /// In es, this message translates to:
  /// **'Agregar imágenes'**
  String get addImages;

  /// No description provided for @addMoreImages.
  ///
  /// In es, this message translates to:
  /// **'Agregar más imágenes'**
  String get addMoreImages;

  /// No description provided for @pleaseAddContentOrImages.
  ///
  /// In es, this message translates to:
  /// **'Por favor, agrega texto o imágenes a tu publicación'**
  String get pleaseAddContentOrImages;

  /// No description provided for @pleaseAddContent.
  ///
  /// In es, this message translates to:
  /// **'Por favor, agrega contenido a tu publicación'**
  String get pleaseAddContent;

  /// No description provided for @postCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'¡Publicación creada con éxito!'**
  String get postCreatedSuccessfully;

  /// No description provided for @errorCreatingPost.
  ///
  /// In es, this message translates to:
  /// **'Error al crear publicación'**
  String get errorCreatingPost;

  /// No description provided for @onlyAdminsCanSendFiles.
  ///
  /// In es, this message translates to:
  /// **'Solo los administradores pueden enviar archivos'**
  String get onlyAdminsCanSendFiles;

  /// No description provided for @sendImage.
  ///
  /// In es, this message translates to:
  /// **'Enviar imagen'**
  String get sendImage;

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @audioDownloadNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'No se permite la descarga de archivos de audio'**
  String get audioDownloadNotAllowed;

  /// No description provided for @downloadFile2.
  ///
  /// In es, this message translates to:
  /// **'Descargar archivo'**
  String get downloadFile2;

  /// No description provided for @doYouWantToDownloadFile.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas descargar \"{filename}\"?'**
  String doYouWantToDownloadFile(String filename);

  /// No description provided for @areYouSureDeleteMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar este mensaje?'**
  String get areYouSureDeleteMessage;

  /// No description provided for @errorDeletingMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar mensaje'**
  String get errorDeletingMessage;

  /// No description provided for @errorSendingMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar mensaje'**
  String get errorSendingMessage;

  /// No description provided for @messageDeleted.
  ///
  /// In es, this message translates to:
  /// **'Mensaje eliminado'**
  String get messageDeleted;

  /// No description provided for @errorUploadingAudio.
  ///
  /// In es, this message translates to:
  /// **'Error al subir el audio'**
  String get errorUploadingAudio;

  /// No description provided for @couldNotStartRecording.
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar la grabación'**
  String get couldNotStartRecording;

  /// No description provided for @recordingTooShort.
  ///
  /// In es, this message translates to:
  /// **'La grabación es demasiado corta'**
  String get recordingTooShort;

  /// No description provided for @noMessagesYet.
  ///
  /// In es, this message translates to:
  /// **'Sin mensajes aún'**
  String get noMessagesYet;

  /// No description provided for @writeMessage.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje...'**
  String get writeMessage;

  /// No description provided for @noMembers.
  ///
  /// In es, this message translates to:
  /// **'Sin miembros'**
  String get noMembers;

  /// No description provided for @addMessageOptional.
  ///
  /// In es, this message translates to:
  /// **'Agregar un mensaje (opcional)'**
  String get addMessageOptional;

  /// No description provided for @assignRoleIn.
  ///
  /// In es, this message translates to:
  /// **'Asignar Rol en {ministryName}'**
  String assignRoleIn(String ministryName);

  /// No description provided for @enterRoleExample.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un rol (ej. \"Director\", \"Músico\")'**
  String get enterRoleExample;

  /// No description provided for @roleCapacity.
  ///
  /// In es, this message translates to:
  /// **'Capacidad del rol'**
  String get roleCapacity;

  /// No description provided for @numberOfPeople.
  ///
  /// In es, this message translates to:
  /// **'Número de personas'**
  String get numberOfPeople;

  /// No description provided for @roleToAssign.
  ///
  /// In es, this message translates to:
  /// **'Rol a asignar'**
  String get roleToAssign;

  /// No description provided for @selectPerson.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Persona'**
  String get selectPerson;

  /// No description provided for @searchPerson.
  ///
  /// In es, this message translates to:
  /// **'Buscar persona...'**
  String get searchPerson;

  /// No description provided for @selectedPeople.
  ///
  /// In es, this message translates to:
  /// **'Personas seleccionadas: {count}'**
  String selectedPeople(int count);

  /// No description provided for @createRoleOnly.
  ///
  /// In es, this message translates to:
  /// **'Crear Solo Rol'**
  String get createRoleOnly;

  /// No description provided for @assignPerson.
  ///
  /// In es, this message translates to:
  /// **'Asignar Persona'**
  String get assignPerson;

  /// No description provided for @assignRoleAndPerson.
  ///
  /// In es, this message translates to:
  /// **'Asignar Rol y Persona'**
  String get assignRoleAndPerson;

  /// No description provided for @capacityUpdatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Capacidad actualizada con éxito'**
  String get capacityUpdatedSuccessfully;

  /// No description provided for @invalidCapacityOrLessThanAssigned.
  ///
  /// In es, this message translates to:
  /// **'Capacidad inválida o menor que personas asignadas'**
  String get invalidCapacityOrLessThanAssigned;

  /// No description provided for @capacity.
  ///
  /// In es, this message translates to:
  /// **'Capacidad'**
  String get capacity;

  /// No description provided for @noRolesDefined.
  ///
  /// In es, this message translates to:
  /// **'No hay roles definidos para esta franja horaria'**
  String get noRolesDefined;

  /// No description provided for @assignedOriginally.
  ///
  /// In es, this message translates to:
  /// **'Asignado originalmente'**
  String get assignedOriginally;

  /// No description provided for @declined.
  ///
  /// In es, this message translates to:
  /// **'Declinado'**
  String get declined;

  /// No description provided for @seen.
  ///
  /// In es, this message translates to:
  /// **'Visto'**
  String get seen;

  /// No description provided for @notAttended.
  ///
  /// In es, this message translates to:
  /// **'No asistió'**
  String get notAttended;

  /// No description provided for @deleteInvite.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Invitación'**
  String get deleteInvite;

  /// No description provided for @confirmDeleteInviteFor.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar la invitación enviada a \"{userName}\"?'**
  String confirmDeleteInviteFor(String userName);

  /// No description provided for @confirmDeleteAssignment.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar la asignación de \"{userName}\"?'**
  String confirmDeleteAssignment(String userName);

  /// No description provided for @deletingMinistry.
  ///
  /// In es, this message translates to:
  /// **'Eliminando ministerio...'**
  String get deletingMinistry;

  /// No description provided for @errorDeletingMinistry3.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar ministerio'**
  String get errorDeletingMinistry3;

  /// No description provided for @deletingAssignment.
  ///
  /// In es, this message translates to:
  /// **'Eliminando asignación...'**
  String get deletingAssignment;

  /// No description provided for @assignmentDeletedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Asignación de \"{userName}\" eliminada con éxito'**
  String assignmentDeletedSuccessfully(String userName);

  /// No description provided for @errorDeletingAssignment.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar asignación'**
  String get errorDeletingAssignment;

  /// No description provided for @inviteDeleted.
  ///
  /// In es, this message translates to:
  /// **'Invitación para \"{userName}\" eliminada'**
  String inviteDeleted(String userName);

  /// No description provided for @errorDeletingInvite.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar invitación'**
  String get errorDeletingInvite;

  /// No description provided for @editCapacityFor.
  ///
  /// In es, this message translates to:
  /// **'Editar capacidad para \"{role}\"'**
  String editCapacityFor(String role);

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa un número válido mayor que cero'**
  String get pleaseEnterValidNumber;

  /// No description provided for @capacityCannotBeLessThanAssigned.
  ///
  /// In es, this message translates to:
  /// **'La capacidad no puede ser menor que el número de personas asignadas'**
  String get capacityCannotBeLessThanAssigned;

  /// No description provided for @updatingCapacity.
  ///
  /// In es, this message translates to:
  /// **'Actualizando capacidad...'**
  String get updatingCapacity;

  /// No description provided for @capacityUpdatedSuccessfully2.
  ///
  /// In es, this message translates to:
  /// **'Capacidad del rol \"{roleName}\" actualizada con éxito'**
  String capacityUpdatedSuccessfully2(String roleName);

  /// No description provided for @errorUpdatingCapacity.
  ///
  /// In es, this message translates to:
  /// **'Error al actualizar capacidad: {error}'**
  String errorUpdatingCapacity(String error);

  /// No description provided for @deletingRole.
  ///
  /// In es, this message translates to:
  /// **'Eliminando rol...'**
  String get deletingRole;

  /// No description provided for @selectExistingRole.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar rol existente'**
  String get selectExistingRole;

  /// No description provided for @capacityMustBeAtLeast1.
  ///
  /// In es, this message translates to:
  /// **'La capacidad debe ser al menos 1'**
  String get capacityMustBeAtLeast1;

  /// No description provided for @errorCreatingRole.
  ///
  /// In es, this message translates to:
  /// **'Error al crear rol: {error}'**
  String errorCreatingRole(String error);

  /// No description provided for @attendanceUpdated.
  ///
  /// In es, this message translates to:
  /// **'Asistencia de {userName} actualizada'**
  String attendanceUpdated(String userName);

  /// No description provided for @errorRegisteringAttendee.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar participante'**
  String get errorRegisteringAttendee;

  /// No description provided for @attendanceConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Asistencia de {userName} confirmada'**
  String attendanceConfirmed(String userName);

  /// No description provided for @errorConfirmingAttendance.
  ///
  /// In es, this message translates to:
  /// **'Error al confirmar asistencia'**
  String get errorConfirmingAttendance;

  /// No description provided for @errorRestoringState.
  ///
  /// In es, this message translates to:
  /// **'Error al restaurar estado'**
  String get errorRestoringState;

  /// No description provided for @attendanceChangedTo.
  ///
  /// In es, this message translates to:
  /// **'Asistencia cambiada a {newUserName}'**
  String attendanceChangedTo(String newUserName);

  /// No description provided for @errorChangingAttendee.
  ///
  /// In es, this message translates to:
  /// **'Error al cambiar participante'**
  String get errorChangingAttendee;

  /// No description provided for @errorMarkingAsAbsent.
  ///
  /// In es, this message translates to:
  /// **'Error al marcar como ausente'**
  String get errorMarkingAsAbsent;

  /// No description provided for @deleteInviteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar invitación'**
  String get deleteInviteTooltip;

  /// No description provided for @confirmTooltip.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirmTooltip;

  /// No description provided for @unconfirmTooltip.
  ///
  /// In es, this message translates to:
  /// **'Desconfirmar'**
  String get unconfirmTooltip;

  /// No description provided for @didNotAttendTooltip.
  ///
  /// In es, this message translates to:
  /// **'No asistió'**
  String get didNotAttendTooltip;

  /// No description provided for @resetTooltip.
  ///
  /// In es, this message translates to:
  /// **'Resetear'**
  String get resetTooltip;

  /// No description provided for @roleCreatedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Rol \"{roleName}\" creado con éxito'**
  String roleCreatedSuccessfully(String roleName);

  /// No description provided for @stateRestored.
  ///
  /// In es, this message translates to:
  /// **'Estado de {userName} restaurado'**
  String stateRestored(String userName);

  /// No description provided for @assignMinistries.
  ///
  /// In es, this message translates to:
  /// **'Asignar Ministerios'**
  String get assignMinistries;

  /// No description provided for @selectMinistriesForTimeSlot.
  ///
  /// In es, this message translates to:
  /// **'Selecciona los ministerios que participarán en esta franja horaria'**
  String get selectMinistriesForTimeSlot;

  /// No description provided for @canSelectMultipleMinistries.
  ///
  /// In es, this message translates to:
  /// **'Puedes seleccionar varios ministerios al mismo tiempo. Después podrás definir los roles específicos para cada ministerio.'**
  String get canSelectMultipleMinistries;

  /// No description provided for @searchMinistry.
  ///
  /// In es, this message translates to:
  /// **'Buscar ministerio...'**
  String get searchMinistry;

  /// No description provided for @createTemporaryMinistry.
  ///
  /// In es, this message translates to:
  /// **'Crear ministerio temporal'**
  String get createTemporaryMinistry;

  /// No description provided for @temporaryMinistryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del ministerio temporal'**
  String get temporaryMinistryName;

  /// No description provided for @ministriesSelected.
  ///
  /// In es, this message translates to:
  /// **'{count} ministerios seleccionados'**
  String ministriesSelected(int count);

  /// No description provided for @assignSelectedMinistries.
  ///
  /// In es, this message translates to:
  /// **'Asignar ministerios seleccionados'**
  String get assignSelectedMinistries;

  /// No description provided for @pleaseEnterTemporaryMinistryName.
  ///
  /// In es, this message translates to:
  /// **'Por favor, ingresa un nombre para el ministerio temporal'**
  String get pleaseEnterTemporaryMinistryName;

  /// No description provided for @pleaseSelectAtLeastOneMinistry.
  ///
  /// In es, this message translates to:
  /// **'Por favor, selecciona al menos un ministerio'**
  String get pleaseSelectAtLeastOneMinistry;

  /// No description provided for @ministryAssignedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Ministerio \"{ministryName}\" asignado con éxito'**
  String ministryAssignedSuccessfully(String ministryName);

  /// No description provided for @ministriesAssignedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'{count} ministerios asignados con éxito'**
  String ministriesAssignedSuccessfully(int count);

  /// No description provided for @noNewMinistriesAssigned.
  ///
  /// In es, this message translates to:
  /// **'Ningún ministerio nuevo fue asignado'**
  String get noNewMinistriesAssigned;

  /// No description provided for @errorAssigningMinistries.
  ///
  /// In es, this message translates to:
  /// **'Error al asignar ministerios'**
  String get errorAssigningMinistries;

  /// No description provided for @addNewRoleIn.
  ///
  /// In es, this message translates to:
  /// **'Agregar Nuevo Rol en {ministryName}'**
  String addNewRoleIn(String ministryName);

  /// No description provided for @selectPredefinedRole.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un rol predefinido:'**
  String get selectPredefinedRole;

  /// No description provided for @orCreateNewRole.
  ///
  /// In es, this message translates to:
  /// **'O crea un nuevo rol:'**
  String get orCreateNewRole;

  /// No description provided for @saveAsPredefinedRole.
  ///
  /// In es, this message translates to:
  /// **'Guardar como rol predefinido'**
  String get saveAsPredefinedRole;

  /// No description provided for @predefinedRoleDescription.
  ///
  /// In es, this message translates to:
  /// **'Si desactivas esta opción, el rol solo será creado para este ministerio y no aparecerá en la lista de roles predefinidos'**
  String get predefinedRoleDescription;

  /// No description provided for @numberOfPeopleForRole.
  ///
  /// In es, this message translates to:
  /// **'Número de personas para este rol'**
  String get numberOfPeopleForRole;

  /// No description provided for @roleDeletedSuccessfully2.
  ///
  /// In es, this message translates to:
  /// **'Rol eliminado con éxito'**
  String get roleDeletedSuccessfully2;

  /// No description provided for @manageYourServiceSchedules.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tus escalas y horarios de servicio'**
  String get manageYourServiceSchedules;

  /// No description provided for @myWorkSchedules.
  ///
  /// In es, this message translates to:
  /// **'Mis Escalas'**
  String get myWorkSchedules;

  /// No description provided for @pendingSchedules.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pendingSchedules;

  /// No description provided for @acceptedSchedules.
  ///
  /// In es, this message translates to:
  /// **'Aceptadas'**
  String get acceptedSchedules;

  /// No description provided for @rejectedSchedules.
  ///
  /// In es, this message translates to:
  /// **'Rechazadas'**
  String get rejectedSchedules;

  /// No description provided for @allSchedules.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get allSchedules;

  /// No description provided for @scheduleHistory.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get scheduleHistory;

  /// No description provided for @noSchedulesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron escalas'**
  String get noSchedulesFound;

  /// No description provided for @noPendingSchedules.
  ///
  /// In es, this message translates to:
  /// **'No tienes escalas pendientes'**
  String get noPendingSchedules;

  /// No description provided for @noAcceptedSchedules.
  ///
  /// In es, this message translates to:
  /// **'No tienes escalas aceptadas'**
  String get noAcceptedSchedules;

  /// No description provided for @noRejectedSchedules.
  ///
  /// In es, this message translates to:
  /// **'No tienes escalas rechazadas'**
  String get noRejectedSchedules;

  /// No description provided for @acceptSchedule.
  ///
  /// In es, this message translates to:
  /// **'Aceptar Escala'**
  String get acceptSchedule;

  /// No description provided for @rejectSchedule.
  ///
  /// In es, this message translates to:
  /// **'Rechazar Escala'**
  String get rejectSchedule;

  /// No description provided for @scheduleAcceptedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Escala aceptada con éxito'**
  String get scheduleAcceptedSuccessfully;

  /// No description provided for @scheduleRejectedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Escala rechazada con éxito'**
  String get scheduleRejectedSuccessfully;

  /// No description provided for @errorAcceptingSchedule.
  ///
  /// In es, this message translates to:
  /// **'Error al aceptar la escala'**
  String get errorAcceptingSchedule;

  /// No description provided for @errorRejectingSchedule.
  ///
  /// In es, this message translates to:
  /// **'Error al rechazar la escala'**
  String get errorRejectingSchedule;

  /// No description provided for @confirmAcceptSchedule.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar aceptación?'**
  String get confirmAcceptSchedule;

  /// No description provided for @confirmRejectSchedule.
  ///
  /// In es, this message translates to:
  /// **'¿Confirmar rechazo?'**
  String get confirmRejectSchedule;

  /// No description provided for @confirmAcceptScheduleMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres aceptar esta escala?'**
  String get confirmAcceptScheduleMessage;

  /// No description provided for @confirmRejectScheduleMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres rechazar esta escala?'**
  String get confirmRejectScheduleMessage;

  /// No description provided for @viewScheduleCalendar.
  ///
  /// In es, this message translates to:
  /// **'Ver Calendario'**
  String get viewScheduleCalendar;

  /// No description provided for @upcomingSchedules.
  ///
  /// In es, this message translates to:
  /// **'Próximas Escalas'**
  String get upcomingSchedules;

  /// No description provided for @pastSchedules.
  ///
  /// In es, this message translates to:
  /// **'Escalas Pasadas'**
  String get pastSchedules;

  /// No description provided for @pendingSchedule.
  ///
  /// In es, this message translates to:
  /// **'pendiente'**
  String get pendingSchedule;

  /// No description provided for @pendingSchedulesLowercase.
  ///
  /// In es, this message translates to:
  /// **'pendientes'**
  String get pendingSchedulesLowercase;

  /// No description provided for @newServiceInvitation.
  ///
  /// In es, this message translates to:
  /// **'Nueva invitación de trabajo'**
  String get newServiceInvitation;

  /// No description provided for @invitedToServeAs.
  ///
  /// In es, this message translates to:
  /// **'Has sido invitado para servir como {role}'**
  String invitedToServeAs(String role);

  /// No description provided for @assignmentCancelled.
  ///
  /// In es, this message translates to:
  /// **'Asignación cancelada'**
  String get assignmentCancelled;

  /// No description provided for @assignmentCancelledMinistryRemoved.
  ///
  /// In es, this message translates to:
  /// **'Tu asignación fue cancelada porque el ministerio fue removido de la franja horaria'**
  String get assignmentCancelledMinistryRemoved;

  /// No description provided for @invitationCancelled.
  ///
  /// In es, this message translates to:
  /// **'Invitación cancelada'**
  String get invitationCancelled;

  /// No description provided for @invitationCancelledMinistryRemoved.
  ///
  /// In es, this message translates to:
  /// **'Tu invitación fue cancelada porque el ministerio fue removido de la franja horaria'**
  String get invitationCancelledMinistryRemoved;

  /// No description provided for @invitationCancelledEventCancelled.
  ///
  /// In es, this message translates to:
  /// **'Tu invitación para participar en un evento fue cancelada'**
  String get invitationCancelledEventCancelled;

  /// No description provided for @roleAlreadyExists.
  ///
  /// In es, this message translates to:
  /// **'Este rol ya existe'**
  String get roleAlreadyExists;

  /// No description provided for @noPersonSelected.
  ///
  /// In es, this message translates to:
  /// **'No has seleccionado ninguna persona para asignar'**
  String get noPersonSelected;

  /// No description provided for @peopleAssignedSuccessfully.
  ///
  /// In es, this message translates to:
  /// **'Personas asignadas correctamente'**
  String get peopleAssignedSuccessfully;

  /// No description provided for @errorAssigningPeople.
  ///
  /// In es, this message translates to:
  /// **'Error al asignar personas: {error}'**
  String errorAssigningPeople(String error);

  /// No description provided for @savedRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles guardados'**
  String get savedRoles;

  /// No description provided for @createRoleWithoutAssigningPerson.
  ///
  /// In es, this message translates to:
  /// **'Crear función sin atribuir persona (puedes atribuir personas después)'**
  String get createRoleWithoutAssigningPerson;

  /// No description provided for @noUsersInMinistry.
  ///
  /// In es, this message translates to:
  /// **'No hay usuarios registrados en este ministerio'**
  String get noUsersInMinistry;

  /// No description provided for @viewAllUsers.
  ///
  /// In es, this message translates to:
  /// **'Ver todos los usuarios'**
  String get viewAllUsers;

  /// No description provided for @showingAllUsers.
  ///
  /// In es, this message translates to:
  /// **'Mostrando todos los usuarios. Considera agregar miembros al ministerio para una mejor organización.'**
  String get showingAllUsers;

  /// No description provided for @userRejectedInvitation.
  ///
  /// In es, this message translates to:
  /// **'Usuario rechazó anteriormente esta invitación'**
  String get userRejectedInvitation;

  /// No description provided for @userHasActiveInvitation.
  ///
  /// In es, this message translates to:
  /// **'Ya tiene una invitación activa'**
  String get userHasActiveInvitation;

  /// No description provided for @currentlyAssigned.
  ///
  /// In es, this message translates to:
  /// **'Asignados actualmente: {count}'**
  String currentlyAssigned(int count);

  /// No description provided for @sureDeleteRole.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro que deseas eliminar el rol \"{roleName}\"?'**
  String sureDeleteRole(String roleName);

  /// No description provided for @tapToEditCapacity.
  ///
  /// In es, this message translates to:
  /// **'Toca para editar capacidad'**
  String get tapToEditCapacity;

  /// No description provided for @cultSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get cultSummary;

  /// No description provided for @downloadSummary.
  ///
  /// In es, this message translates to:
  /// **'Descargar Resumen'**
  String get downloadSummary;

  /// No description provided for @summaryView.
  ///
  /// In es, this message translates to:
  /// **'Vista:'**
  String get summaryView;

  /// No description provided for @compact.
  ///
  /// In es, this message translates to:
  /// **'Compacta'**
  String get compact;

  /// No description provided for @detailed.
  ///
  /// In es, this message translates to:
  /// **'Detallada'**
  String get detailed;

  /// No description provided for @filterVacant.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get filterVacant;

  /// No description provided for @noTimeSlotsCreated.
  ///
  /// In es, this message translates to:
  /// **'No hay franjas horarias creadas'**
  String get noTimeSlotsCreated;

  /// No description provided for @noRolesAssigned.
  ///
  /// In es, this message translates to:
  /// **'No hay roles asignados'**
  String get noRolesAssigned;

  /// No description provided for @noMinistry.
  ///
  /// In es, this message translates to:
  /// **'Sin ministerio'**
  String get noMinistry;

  /// No description provided for @filled.
  ///
  /// In es, this message translates to:
  /// **'cubiertos'**
  String get filled;

  /// No description provided for @unassigned.
  ///
  /// In es, this message translates to:
  /// **'(Sin asignar)'**
  String get unassigned;

  /// No description provided for @vacantStatus.
  ///
  /// In es, this message translates to:
  /// **'Vacante'**
  String get vacantStatus;

  /// No description provided for @downloadPDF.
  ///
  /// In es, this message translates to:
  /// **'Descargar PDF'**
  String get downloadPDF;

  /// No description provided for @printableDocument.
  ///
  /// In es, this message translates to:
  /// **'Documento imprimible'**
  String get printableDocument;

  /// No description provided for @downloadExcel.
  ///
  /// In es, this message translates to:
  /// **'Descargar Excel'**
  String get downloadExcel;

  /// No description provided for @editableSpreadsheet.
  ///
  /// In es, this message translates to:
  /// **'Hoja de cálculo editable'**
  String get editableSpreadsheet;

  /// No description provided for @pdfFunctionalityInDevelopment.
  ///
  /// In es, this message translates to:
  /// **'Funcionalidad de PDF en desarrollo...'**
  String get pdfFunctionalityInDevelopment;

  /// No description provided for @excelFunctionalityInDevelopment.
  ///
  /// In es, this message translates to:
  /// **'Funcionalidad de Excel en desarrollo...'**
  String get excelFunctionalityInDevelopment;
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
