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
  /// **'Selecciona una fecha'**
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
  /// **'Gestionar vídeos'**
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
  /// **'Ministerio eliminado con éxito'**
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
  /// **'Error al cargar eventos: {error}'**
  String errorLoadingEvents(String error);

  /// No description provided for @calendars.
  ///
  /// In es, this message translates to:
  /// **'Calendarios'**
  String get calendars;

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
  /// **'Pendiente'**
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
  /// **'{count,plural, =1{1 Lección}other{{count} Lecciones}}'**
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
  /// **'Confirmar eliminación'**
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
  /// **'Asistencia registrada con éxito'**
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
  /// **'Error al publicar el comentario'**
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
  /// **'Fecha:'**
  String get date;

  /// No description provided for @select.
  ///
  /// In es, this message translates to:
  /// **'Selección'**
  String get select;

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
  /// **'Crear nuevo curso'**
  String get createNewCourse;

  /// No description provided for @noCoursesFound.
  ///
  /// In es, this message translates to:
  /// **'Ningún curso encontrado'**
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

  /// No description provided for @progress.
  ///
  /// In es, this message translates to:
  /// **'Progreso: {percentage}% ({completed}/{total})'**
  String progress(Object completed, Object percentage, Object total);

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
  /// **'Sin descripción.'**
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
  /// **'Sé el primero en comentar'**
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
  /// **'No tienes permiso para gestionar páginas.'**
  String get noPermissionManagePages;

  /// No description provided for @errorLoadingPages.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar páginas: {error}'**
  String errorLoadingPages(Object error);

  /// No description provided for @noCustomPagesYet.
  ///
  /// In es, this message translates to:
  /// **'Ninguna página personalizada creada aún.'**
  String get noCustomPagesYet;

  /// No description provided for @tapPlusToCreateFirst.
  ///
  /// In es, this message translates to:
  /// **'Toca el botón + para crear la primera.'**
  String get tapPlusToCreateFirst;

  /// No description provided for @pageWithoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Página sin Título'**
  String get pageWithoutTitle;

  /// No description provided for @noPermissionEditPages.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para editar páginas.'**
  String get noPermissionEditPages;

  /// No description provided for @noPermissionCreatePages.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso para crear páginas.'**
  String get noPermissionCreatePages;

  /// No description provided for @createNewPage.
  ///
  /// In es, this message translates to:
  /// **'Crear Nueva Página'**
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
  /// **'Por favor, introduce un título'**
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
  /// **'Error al eliminar: {error}'**
  String errorDeleting(Object error);

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
  /// **'Configuraciones de consulta'**
  String get consultationSettings;

  /// No description provided for @noPermissionManageAvailability.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para gestionar disponibilidad'**
  String get noPermissionManageAvailability;

  /// No description provided for @errorLoadingAvailability.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String errorLoadingAvailability(Object error);

  /// No description provided for @timeSlots.
  ///
  /// In es, this message translates to:
  /// **'Franjas de Horario'**
  String get timeSlots;

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
  /// **'Semana de'**
  String get weekOf;

  /// No description provided for @copyToNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Copiar para próxima semana'**
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
  /// **'Administrar Anuncios'**
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
  /// **'Anuncio creado con éxito'**
  String get announcementCreatedSuccessfully;

  /// No description provided for @errorCreatingAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Error al crear anuncio: {error}'**
  String errorCreatingAnnouncement(Object error);

  /// No description provided for @addImage.
  ///
  /// In es, this message translates to:
  /// **'Añadir imagen'**
  String get addImage;

  /// No description provided for @recommended16x9.
  ///
  /// In es, this message translates to:
  /// **'Recomendado: 16:9 (1920x1080)'**
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
  /// **'Por favor, introduce una descripción'**
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
  /// **'Por favor, selecciona una imagen para el anuncio'**
  String get pleaseSelectAnnouncementImage;

  /// No description provided for @publishAnnouncement.
  ///
  /// In es, this message translates to:
  /// **'Publicar Anuncio'**
  String get publishAnnouncement;

  /// No description provided for @createEvent.
  ///
  /// In es, this message translates to:
  /// **'Crear Evento'**
  String get createEvent;

  /// No description provided for @upcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
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
  /// **'Seleccionar todos'**
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

  /// No description provided for @confirmDeleteMinistry.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar el ministerio \"{name}\"? Esta acción no se puede deshacer.'**
  String confirmDeleteMinistry(Object name);

  /// No description provided for @errorDeletingMinistry.
  ///
  /// In es, this message translates to:
  /// **'Error al eliminar ministerio: {error}'**
  String errorDeletingMinistry(Object error);

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
  /// **'Confirmada'**
  String get confirmed;

  /// No description provided for @present.
  ///
  /// In es, this message translates to:
  /// **'Presentes'**
  String get present;

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
  /// **'Ningún miembro encontrado'**
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
  /// **'Añadir Participante'**
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
  /// **'Ningún resultado encontrado'**
  String get noResultsFound;

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
  /// **'Ubicación:'**
  String get location;

  /// No description provided for @selectLocation.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ubicación'**
  String get selectLocation;

  /// No description provided for @addNewLocation.
  ///
  /// In es, this message translates to:
  /// **'Añadir nueva ubicación'**
  String get addNewLocation;

  /// No description provided for @locationName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la ubicación'**
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
  /// **'Estado/Provincia'**
  String get state;

  /// No description provided for @postalCode.
  ///
  /// In es, this message translates to:
  /// **'Código Postal'**
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
  /// **'Descripción del Ministerio'**
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
  /// **'Seleccionar administradores (opcional)'**
  String get selectAdministrators;

  /// No description provided for @searchUsers.
  ///
  /// In es, this message translates to:
  /// **'Buscar usuarios...'**
  String get searchUsers;

  /// No description provided for @noUsersFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron usuarios'**
  String get noUsersFound;

  /// No description provided for @selectedAdministrators.
  ///
  /// In es, this message translates to:
  /// **'Administradores seleccionados'**
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
  String charactersRemaining(Object count);

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
  /// **'Cancelada'**
  String get cancelled;

  /// No description provided for @completed.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
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
  /// **'No hay oraciones pendientes'**
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
  /// **'Crear Mensaje Predefinido'**
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
  /// **'Ver Detalles'**
  String get viewDetails;

  /// No description provided for @lastActive.
  ///
  /// In es, this message translates to:
  /// **'Última actividad'**
  String get lastActive;

  /// No description provided for @joinedOn.
  ///
  /// In es, this message translates to:
  /// **'Se unió el'**
  String get joinedOn;

  /// No description provided for @role.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get role;

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
  /// **'Buscar Servicio'**
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
  /// **'Total de Asistencias'**
  String get totalAttendances;

  /// No description provided for @totalAbsences.
  ///
  /// In es, this message translates to:
  /// **'Total de Ausencias'**
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
  /// **'Fecha de Inicio'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Fin'**
  String get endDate;

  /// No description provided for @applyFilter.
  ///
  /// In es, this message translates to:
  /// **'Aplicar Filtro'**
  String get applyFilter;

  /// No description provided for @clearFilter.
  ///
  /// In es, this message translates to:
  /// **'Limpiar Filtro'**
  String get clearFilter;

  /// No description provided for @noServicesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron servicios'**
  String get noServicesFound;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;
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
