// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get myProfile => 'Mi Perfil';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get completeYourProfile => 'Completa tu perfil';

  @override
  String get personalInformation => 'Información Personal';

  @override
  String get save => 'Guardar';

  @override
  String get name => 'Nombre';

  @override
  String get pleaseEnterYourName => 'Por favor, escribe tu nombre';

  @override
  String get surname => 'Apellido';

  @override
  String get pleaseEnterYourSurname => 'Por favor, escribe tu apellido';

  @override
  String get birthDate => 'Fecha de Nacimiento';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get gender => 'Sexo';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String get preferNotToSay => 'Prefiero no decirlo';

  @override
  String get phone => 'Teléfono';

  @override
  String get optional => 'Opcional';

  @override
  String get invalidPhone => 'Teléfono inválido';

  @override
  String currentNumber(String number) {
    return 'Número actual: $number';
  }

  @override
  String get participation => 'Participación';

  @override
  String get ministries => 'Ministerios';

  @override
  String get errorLoadingMinistries => 'Error al cargar los ministerios';

  @override
  String get mySchedules => 'Mis Turnos';

  @override
  String get manageAssignmentsAndInvitations =>
      'Gestiona tus asignaciones e invitaciones de trabajo en los ministerios';

  @override
  String get joinAnotherMinistry => 'Unirse a otro Ministerio';

  @override
  String get youDoNotBelongToAnyMinistry => 'No perteneces a ningún ministerio';

  @override
  String get joinAMinistryToParticipate =>
      'Únete a un ministerio para participar en el servicio de la iglesia';

  @override
  String get joinAMinistry => 'Unirse a un Ministerio';

  @override
  String get groups => 'Grupos';

  @override
  String get errorLoadingGroups => 'Error al cargar los grupos';

  @override
  String get joinAnotherGroup => 'Unirse a otro Grupo';

  @override
  String get youDoNotBelongToAnyGroup => 'No perteneces a ningún grupo';

  @override
  String get joinAGroupToParticipate =>
      'Únete a un grupo para participar en la vida comunitaria';

  @override
  String get joinAGroup => 'Unirse a un Grupo';

  @override
  String get administration => 'Administración';

  @override
  String get manageDonations => 'Gestionar Donaciones';

  @override
  String get configureDonationSection =>
      'Configura la sección y formas de donación';

  @override
  String get manageLiveStreams => 'Gestionar Transmisiones en Vivo';

  @override
  String get createEditControlStreams =>
      'Crear, editar y controlar transmisiones';

  @override
  String get manageOnlineCourses => 'Gestionar Cursos en Línea';

  @override
  String get createEditConfigureCourses => 'Crear, editar y configurar cursos';

  @override
  String get manageHomeScreen => 'Gestionar Pantalla de Inicio';

  @override
  String get managePages => 'Gestionar Páginas';

  @override
  String get createEditInfoContent => 'Crear y editar contenido informativo';

  @override
  String get manageAvailability => 'Gestionar Disponibilidad';

  @override
  String get configureCounselingHours =>
      'Configura tus horarios para asesoramiento';

  @override
  String get manageProfileFields => 'Gestionar Campos de Perfil';

  @override
  String get configureAdditionalUserFields =>
      'Configura los campos adicionales para los usuarios';

  @override
  String get manageRoles => 'Gestionar Roles';

  @override
  String get assignPastorRoles => 'Asigna roles de pastor a otros usuarios';

  @override
  String get createEditRoles => 'Crear/Editar Roles';

  @override
  String get createEditRolesAndPermissions => 'Crear/editar roles y permisos';

  @override
  String get createAnnouncements => 'Crear Anuncios';

  @override
  String get createEditChurchAnnouncements =>
      'Crea y edita anuncios para la iglesia';

  @override
  String get manageEvents => 'Gestionar Eventos';

  @override
  String get createManageChurchEvents =>
      'Crear y gestionar eventos de la iglesia';

  @override
  String get manageVideos => 'Gestionar Videos';

  @override
  String get administerChurchSectionsVideos =>
      'Administra las secciones y videos de la iglesia';

  @override
  String get administerCults => 'Administrar Cultos';

  @override
  String get manageCultsMinistriesSongs =>
      'Gestionar cultos, ministerios y canciones';

  @override
  String get createMinistry => 'Crear Ministerio';

  @override
  String get createConnect => 'Crear Conexión';

  @override
  String get counselingRequests => 'Solicitudes de Asesoramiento';

  @override
  String get manageMemberRequests => 'Gestiona las solicitudes de los miembros';

  @override
  String get privatePrayers => 'Oraciones Privadas';

  @override
  String get managePrivatePrayerRequests =>
      'Gestiona las solicitudes de oración privada';

  @override
  String get sendPushNotification => 'Enviar Notificación Push';

  @override
  String get sendMessagesToChurchMembers =>
      'Envía mensajes a los miembros de la iglesia';

  @override
  String get deleteMinistries => 'Eliminar Ministerios';

  @override
  String get removeExistingMinistries => 'Eliminar ministerios existentes';

  @override
  String get deleteGroups => 'Eliminar Grupos';

  @override
  String get removeExistingGroups => 'Eliminar grupos existentes';

  @override
  String get reportsAndAttendance => 'Informes y Asistencia';

  @override
  String get manageEventAttendance => 'Gestionar Asistencia a Eventos';

  @override
  String get checkAttendanceGenerateReports =>
      'Verificar asistencia y generar informes';

  @override
  String get ministryStatistics => 'Estadísticas de Ministerios';

  @override
  String get participationMembersAnalysis =>
      'Análisis de participación y miembros';

  @override
  String get groupStatistics => 'Estadísticas de Grupos';

  @override
  String get scheduleStatistics => 'Estadísticas de Turnos';

  @override
  String get participationInvitationsAnalysis =>
      'Análisis de participación e invitaciones';

  @override
  String get courseStatistics => 'Estadísticas de Cursos';

  @override
  String get enrollmentProgressAnalysis =>
      'Análisis de inscripciones y progreso';

  @override
  String get userInfo => 'Información de Usuarios';

  @override
  String get consultParticipationDetails =>
      'Consultar detalles de participación';

  @override
  String get churchStatistics => 'Estadísticas de la Iglesia';

  @override
  String get membersActivitiesOverview =>
      'Visión general de los miembros y actividades';

  @override
  String get noGroupsAvailable => 'No hay grupos disponibles';

  @override
  String get unnamedGroup => 'Grupo sin nombre';

  @override
  String get noMinistriesAvailable => 'No hay ministerios disponibles';

  @override
  String get unnamedMinistry => 'Ministerio sin nombre';

  @override
  String get deleteGroup => 'Eliminar Grupo';

  @override
  String get confirmDeleteGroupQuestion =>
      '¿Está seguro que desea eliminar el grupo ';

  @override
  String get deleteGroupWarning =>
      '\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String groupDeletedSuccessfully(String groupName) {
    return 'Grupo \"$groupName\" eliminado con éxito';
  }

  @override
  String errorDeletingGroup(String error) {
    return 'Error al eliminar el grupo: $error';
  }

  @override
  String get deleteMinistry => 'Eliminar Ministerio';

  @override
  String get confirmDeleteMinistryQuestion =>
      '¿Está seguro que desea eliminar el ministerio ';

  @override
  String get deleteMinistryWarning =>
      '\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.';

  @override
  String ministryDeletedSuccessfully(String ministryName) {
    return 'Ministerio \"$ministryName\" eliminado con éxito';
  }

  @override
  String errorDeletingMinistry(Object error) {
    return 'Error al eliminar el ministerio: $error';
  }

  @override
  String get logOut => 'Cerrar Sesión';

  @override
  String errorLoggingOut(String error) {
    return 'Error al Cerrar Sesión: $error';
  }

  @override
  String get additionalInfoSavedSuccessfully =>
      'Información adicional guardada con éxito';

  @override
  String errorSaving(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String unsupportedFieldType(String type) {
    return 'Tipo de campo no soportado: $type';
  }

  @override
  String get thisFieldIsRequired => 'Este campo es obligatorio';

  @override
  String get requiredField => 'Campo obligatorio';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get choosePreferredLanguage => 'Elige tu idioma preferido';

  @override
  String get somethingWentWrong => 'Algo salió mal!';

  @override
  String get tryAgainLater => 'Intenta de nuevo más tarde';

  @override
  String get welcome => 'Bienvenido';

  @override
  String get connectingToYourCommunity => 'Conectándote a tu comunidad';

  @override
  String errorLoadingSections(String error) {
    return 'Error al cargar las secciones: $error';
  }

  @override
  String unknownSectionError(String sectionType) {
    return 'Sección desconocida o con error: $sectionType';
  }

  @override
  String get additionalInformationNeeded => 'Información adicional necesaria';

  @override
  String get pleaseCompleteYourAdditionalInfo =>
      'Por favor, completa tu información adicional para mejorar tu experiencia en la iglesia.';

  @override
  String get completeNow => 'Completar ahora';

  @override
  String get doNotShowAgain => 'No mostrar más';

  @override
  String get skipForNow => 'Omitir por ahora';

  @override
  String get user => 'Usuario';

  @override
  String get workInvites => 'Invitaciones de Trabajo';

  @override
  String get serviceStatistics => 'Estadísticas de Servicios';

  @override
  String get home => 'Inicio';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get calendar => 'Calendario';

  @override
  String get videos => 'videos';

  @override
  String get profile => 'Perfil';

  @override
  String get all => 'Todos';

  @override
  String get unread => 'No leídas';

  @override
  String get markAllAsRead => 'Marcar todas como leídas';

  @override
  String get allNotificationsMarkedAsRead =>
      'Todas las notificaciones marcadas como leídas';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get deleteAllNotifications => 'Eliminar todas las notificaciones';

  @override
  String get areYouSureYouWantToDeleteAllNotifications =>
      '¿Estás seguro de que quieres eliminar todas las notificaciones?';

  @override
  String get deleteAll => 'Eliminar todas';

  @override
  String get allNotificationsDeleted => 'Todas las notificaciones eliminadas';

  @override
  String get youHaveNoNotifications => 'No tienes notificaciones';

  @override
  String get youHaveNoNotificationsOfType =>
      'No tienes notificaciones de este tipo';

  @override
  String get removeFilter => 'Quitar filtro';

  @override
  String get youHaveNoUnreadNotifications =>
      'No tienes notificaciones no leídas';

  @override
  String get youHaveNoUnreadNotificationsOfType =>
      'No tienes notificaciones no leídas de este tipo';

  @override
  String get notificationDeleted => 'Notificación eliminada';

  @override
  String errorLoadingEvents(String error) {
    return 'Error al cargar los eventos';
  }

  @override
  String get calendars => 'Calendarios';

  @override
  String get events => 'eventos';

  @override
  String get services => 'Servicios';

  @override
  String get counseling => 'Asesoramiento';

  @override
  String get manageSections => 'Gestionar secciones';

  @override
  String get recentVideos => 'Videos Recientes';

  @override
  String errorInSection(Object error) {
    return 'Error en la sección: $error';
  }

  @override
  String get noVideosAvailableInSection =>
      'No hay videos disponibles en esta sección';

  @override
  String errorInCustomSection(Object error) {
    return 'Error en la sección personalizada: $error';
  }

  @override
  String get noVideosInCustomSection =>
      'No hay videos en esta sección personalizada';

  @override
  String get addVideo => 'Añadir video';

  @override
  String get cultsSchedule => 'Programación de Cultos';

  @override
  String get noScheduledCults => 'No hay cultos programados';

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get loginToYourAccount => 'Inicia sesión en tu cuenta';

  @override
  String get welcomeBackPleaseLogin =>
      '¡Bienvenido de nuevo! Por favor, inicia sesión para continuar';

  @override
  String get email => 'Email';

  @override
  String get yourEmailExample => 'tu.email@ejemplo.com';

  @override
  String get pleaseEnterYourEmail => 'Por favor, escribe tu email';

  @override
  String get pleaseEnterAValidEmail => 'Por favor, escribe un email válido';

  @override
  String get password => 'Contraseña';

  @override
  String get enterYourPassword => 'Escribe tu contraseña';

  @override
  String get pleaseEnterYourPassword => 'Por favor, escribe tu contraseña';

  @override
  String get forgotYourPassword => '¿Olvidaste tu contraseña?';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get dontHaveAnAccount => '¿No tienes una cuenta?';

  @override
  String get signUp => 'Regístrate';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo!';

  @override
  String get noAccountWithThisEmail => 'No existe una cuenta con este email';

  @override
  String get incorrectPassword => 'Contraseña incorrecta';

  @override
  String get tooManyFailedAttempts =>
      'Demasiados intentos fallidos. Por favor, inténtalo más tarde.';

  @override
  String get invalidCredentials =>
      'Credenciales inválidas. Verifica tu email y contraseña.';

  @override
  String get accountDisabled => 'Esta cuenta ha sido desactivada.';

  @override
  String get loginNotEnabled =>
      'El inicio de sesión con email y contraseña no está habilitado.';

  @override
  String get connectionError =>
      'Error de conexión. Verifica tu conexión a Internet.';

  @override
  String get verificationError =>
      'Error de verificación. Por favor, inténtalo de nuevo.';

  @override
  String get recaptchaFailed =>
      'La verificación de reCAPTCHA falló. Por favor, inténtalo de nuevo.';

  @override
  String errorLoggingIn(String error) {
    return 'Error al iniciar sesión: $error';
  }

  @override
  String get operationTimedOut =>
      'La operación tardó demasiado. Por favor, inténtalo de nuevo.';

  @override
  String get platformError =>
      'Error de plataforma. Por favor, contacta al administrador.';

  @override
  String get unexpectedError =>
      'Error inesperado. Por favor, inténtalo más tarde.';

  @override
  String get unauthenticatedUser => 'Usuario no autenticado';

  @override
  String get noAdditionalFields => 'No hay campos adicionales para completar';

  @override
  String get back => 'Volver';

  @override
  String get additionalInformation => 'Información Adicional';

  @override
  String get pleaseCompleteTheFollowingInfo =>
      'Por favor, completa la siguiente información:';

  @override
  String get otherInformation => 'Otra Información';

  @override
  String get pleaseCorrectErrorsBeforeSaving =>
      'Por favor, corrige los errores antes de guardar.';

  @override
  String get pleaseFillAllRequiredBasicFields =>
      'Por favor, rellena todos los campos básicos obligatorios.';

  @override
  String get pleaseFillAllRequiredAdditionalFields =>
      'Por favor, rellena todos los campos adicionales obligatorios (*)';

  @override
  String get informationSavedSuccessfully => 'Información guardada con éxito';

  @override
  String get birthDateLabel => 'Fecha de Nacimiento';

  @override
  String get genderLabel => 'Género';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get phoneHint => 'Ej: 612345678';

  @override
  String get selectAnOption => 'Seleccione una opción';

  @override
  String get enterAValidNumber => 'Inserta un número válido';

  @override
  String get enterAValidEmail => 'Inserta un email válido';

  @override
  String get enterAValidPhoneNumber => 'Inserta un número de teléfono válido';

  @override
  String get recoverPassword => 'Recuperar Contraseña';

  @override
  String get enterEmailToReceiveInstructions =>
      'Escribe tu email para recibir las instrucciones';

  @override
  String get sendEmail => 'Enviar Email';

  @override
  String get emailSent => '¡Email Enviado!';

  @override
  String get checkYourInbox =>
      'Verifica tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.';

  @override
  String get gotIt => 'Entendido';

  @override
  String get recoveryEmailSentSuccessfully =>
      '¡Email de recuperación enviado con éxito!';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String errorSendingEmail(String error) {
    return 'Error al enviar email: $error';
  }

  @override
  String get createANewAccount => 'Crear una nueva cuenta';

  @override
  String get fillYourDetailsToRegister => 'Rellena tus datos para registrarte';

  @override
  String get enterYourName => 'Escribe tu nombre';

  @override
  String get enterYourSurname => 'Escribe tu apellido';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get phoneNumberHint => '(00) 00000-0000';

  @override
  String get pleaseEnterYourPhone => 'Por favor, escribe tu teléfono';

  @override
  String get pleaseEnterAValidPhone => 'Por favor, escribe un teléfono válido';

  @override
  String get pleaseEnterAPassword => 'Por favor, escribe una contraseña';

  @override
  String get passwordMustBeAtLeast6Chars =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get enterYourPasswordAgain => 'Escribe tu contraseña de nuevo';

  @override
  String get pleaseConfirmYourPassword => 'Por favor, confirma tu contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get alreadyHaveAnAccount => '¿Ya tienes una cuenta?';

  @override
  String get byRegisteringYouAccept =>
      'Al registrarte, aceptas nuestros términos y condiciones y nuestra política de privacidad.';

  @override
  String get welcomeCompleteProfile =>
      '¡Bienvenido! Completa tu perfil para disfrutar de todas las funciones.';

  @override
  String get emailAlreadyInUse => 'Ya existe una cuenta con este email';

  @override
  String get invalidEmailFormat => 'El formato del email no es válido';

  @override
  String get registrationNotEnabled =>
      'El registro con email y contraseña no está habilitado';

  @override
  String get weakPassword =>
      'La contraseña es muy débil, intenta una más segura';

  @override
  String errorRegistering(String error) {
    return 'Error al registrar: $error';
  }

  @override
  String get pending => 'Pendientes';

  @override
  String get accepted => 'Aceptados';

  @override
  String get rejected => 'Rechazados';

  @override
  String get youHaveNoWorkInvites => 'No tienes invitaciones de trabajo';

  @override
  String youHaveNoInvitesOfType(String status) {
    return 'No tienes invitaciones $status';
  }

  @override
  String get acceptedStatus => 'Aceptado';

  @override
  String get rejectedStatus => 'Rechazado';

  @override
  String get seenStatus => 'Visto';

  @override
  String get pendingStatus => 'Pendiente';

  @override
  String get reject => 'Rechazar';

  @override
  String get accept => 'Aceptar';

  @override
  String get inviteAcceptedSuccessfully => 'Invitación aceptada con éxito';

  @override
  String get inviteRejectedSuccessfully => 'Invitación rechazada con éxito';

  @override
  String errorRespondingToInvite(String error) {
    return 'Error al responder a la invitación: $error';
  }

  @override
  String get invitationDetails => 'Detalles de Invitación';

  @override
  String get invitationAccepted => 'Invitación aceptada exitosamente';

  @override
  String get invitationRejected => 'Invitación rechazada exitosamente';

  @override
  String get workInvitation => 'Invitación de Trabajo';

  @override
  String get jobDetails => 'Detalles del Trabajo';

  @override
  String get roleToPerform => 'Rol a desempeñar';

  @override
  String get invitationInfo => 'Información de la Invitación';

  @override
  String get sentBy => 'Enviado por';

  @override
  String get loading => 'Cargando...';

  @override
  String get sentDate => 'Fecha de envío';

  @override
  String get responseDate => 'Fecha de respuesta';

  @override
  String get announcements => 'anuncios';

  @override
  String get errorLoadingAnnouncements => 'Error al cargar los anuncios';

  @override
  String get noAnnouncementsAvailable => 'No hay anuncios disponibles';

  @override
  String get seeMore => 'Ver más';

  @override
  String get noUpcomingEvents => 'No hay eventos futuros en este momento';

  @override
  String get online => 'Online';

  @override
  String get inPerson => 'Presencial';

  @override
  String get hybrid => 'Híbrido';

  @override
  String get schedulePastoralCounseling => 'Agenda una cita pastoral';

  @override
  String get talkToAPastor => 'Habla con un pastor para orientación espiritual';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get swipeToSeeFeaturedCourses => 'Desliza para ver cursos destacados';

  @override
  String lessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lecciones',
      one: '1 lección',
    );
    return '$_temp0';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String hours(int count) {
    return '$count h';
  }

  @override
  String hoursAndMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get viewDonationOptions => 'Ver opciones de donación';

  @override
  String get participateInChurchMinistries =>
      'Participa en los ministerios de la iglesia';

  @override
  String get connect => 'Conectar';

  @override
  String get connectWithChurchGroups =>
      'Conéctate con los grupos de la iglesia';

  @override
  String get privatePrayer => 'Oración Privada';

  @override
  String get sendPrivatePrayerRequests =>
      'Envía peticiones de oración privadas';

  @override
  String get publicPrayer => 'Oración Pública';

  @override
  String get shareAndPrayWithTheCommunity => 'Comparte y ora con la comunidad';

  @override
  String get eventNotFound => 'Evento no encontrado';

  @override
  String get errorLoadingEvent => 'Error al cargar el evento';

  @override
  String errorLoadingEventDetails(String error) {
    return 'Error al cargar detalles del evento: $error';
  }

  @override
  String get eventNotFoundOrInvalid => 'Evento no encontrado o inválido.';

  @override
  String errorOpeningEvent(String error) {
    return 'Error al abrir el evento: $error';
  }

  @override
  String errorNavigatingToEvent(String error) {
    return 'Error al navegar al evento: $error';
  }

  @override
  String get announcementReloaded =>
      'Datos del anuncio recargados (implementar actualización de estado si es necesario)';

  @override
  String errorReloadingAnnouncement(String error) {
    return 'Error al recargar anuncio: $error';
  }

  @override
  String get confirmDeletion => 'Confirmar Eliminación';

  @override
  String get confirmDeleteAnnouncement =>
      '¿Estás seguro de que quieres eliminar este anuncio? Esta acción no se puede deshacer.';

  @override
  String get deletingAnnouncement => 'Eliminando anuncio...';

  @override
  String errorDeletingImage(String error) {
    return 'Error al eliminar imagen del Storage: $error';
  }

  @override
  String get announcementDeletedSuccessfully => 'Anuncio eliminado con éxito.';

  @override
  String errorDeletingAnnouncement(String error) {
    return 'Error al eliminar anuncio: $error';
  }

  @override
  String get cultAnnouncement => 'Anuncio de Culto';

  @override
  String get announcement => 'Anuncio';

  @override
  String get editAnnouncement => 'Editar Anuncio';

  @override
  String get deleteAnnouncement => 'Eliminar Anuncio';

  @override
  String get cult => 'Culto';

  @override
  String publishedOn(String date) {
    return 'Publicado el: $date';
  }

  @override
  String cultDate(String date) {
    return 'Fecha del culto: $date';
  }

  @override
  String get linkedEvent => 'Evento Vinculado';

  @override
  String get tapToSeeDetails => 'Toca para ver detalles';

  @override
  String get noEventLinkedToThisCult => 'Ningún evento vinculado a este culto.';

  @override
  String errorVerifyingRegistration(String error) {
    return 'Error al verificar registro: $error';
  }

  @override
  String errorVerifyingUserRole(String error) {
    return 'Error al verificar el rol del usuario: $error';
  }

  @override
  String get updateEventLink => 'Actualizar enlace del evento';

  @override
  String get addEventLink => 'Añadir enlace del evento';

  @override
  String get enterOnlineEventLink =>
      'Introduce el enlace para que los asistentes accedan al evento online:';

  @override
  String get eventUrl => 'URL del evento';

  @override
  String get eventUrlHint => 'https://zoom.us/meeting/...';

  @override
  String get invalidUrlFormat =>
      'El enlace debe comenzar con http:// o https://';

  @override
  String get deleteLink => 'Eliminar enlace';

  @override
  String get linkDeletedSuccessfully =>
      'Enlace del evento eliminado correctamente';

  @override
  String get linkUpdatedSuccessfully =>
      'Enlace del evento actualizado correctamente';

  @override
  String get linkAddedSuccessfully => 'Enlace del evento añadido correctamente';

  @override
  String errorUpdatingLink(String error) {
    return 'Error al actualizar el enlace: $error';
  }

  @override
  String errorSendingNotifications(String error) {
    return 'Error al enviar notificaciones: $error';
  }

  @override
  String get mustLoginToRegisterAttendance =>
      'Debes iniciar sesión para registrar tu asistencia';

  @override
  String get attendanceRegisteredSuccessfully =>
      '¡Asistencia registrada correctamente!';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace';

  @override
  String errorOpeningLink(String error) {
    return 'Error al abrir el enlace: $error';
  }

  @override
  String get noPermissionToDeleteEvent =>
      'No tienes permiso para eliminar este evento';

  @override
  String get deleteEvent => 'Eliminar Evento';

  @override
  String get confirmDeleteEvent =>
      '¿Estás seguro que deseas eliminar este evento?';

  @override
  String get eventDeletedSuccessfully => 'Evento eliminado con éxito';

  @override
  String get deleteTicket => 'Eliminar Entrada';

  @override
  String get confirmDeleteTicket =>
      '¿Estás seguro que deseas eliminar esta entrada? Esta acción no se puede deshacer.';

  @override
  String get ticketDeletedSuccessfully => 'Entrada eliminada con éxito';

  @override
  String errorDeletingTicket(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get deleteMyTicket => 'Eliminar mi entrada';

  @override
  String get confirmDeleteMyTicket =>
      '¿Estás seguro que deseas eliminar tu entrada? Esta acción no se puede deshacer.';

  @override
  String errorDeletingMyTicket(String error) {
    return 'Error al eliminar la entrada: $error';
  }

  @override
  String get notDefined => 'No definido';

  @override
  String get onlineEvent => 'Evento online';

  @override
  String get accessEvent => 'Acceder al evento';

  @override
  String get copyEventLink => 'Copiar enlace del evento';

  @override
  String get linkCopied => '¡Enlace copiado!';

  @override
  String get linkNotConfigured => 'Enlace no configurado';

  @override
  String get addLinkForAttendees =>
      'Añade un enlace para que los asistentes puedan acceder al evento';

  @override
  String get addLink => 'Añadir enlace';

  @override
  String get physicalLocationNotSpecified => 'Ubicación física no especificada';

  @override
  String get physicalLocation => 'Ubicación física';

  @override
  String get accessOnline => 'Acceder online';

  @override
  String get addLinkForOnlineAttendance =>
      'Añade un enlace para la asistencia online';

  @override
  String get locationNotSpecified => 'Lugar no especificado';

  @override
  String get manageAttendees => 'Gestionar asistentes';

  @override
  String get scanTickets => 'Escanear entradas';

  @override
  String get updateLink => 'Actualizar enlace';

  @override
  String get createNewTicket => 'Crear nuevo ticket';

  @override
  String get noPermissionToCreateTickets =>
      'No tienes permiso para crear tickets';

  @override
  String get deleteEventTooltip => 'Eliminar evento';

  @override
  String get start => 'Inicio';

  @override
  String get end => 'Fin';

  @override
  String get description => 'Descripción';

  @override
  String get updatingTickets => 'Actualizando entradas...';

  @override
  String get loadingTickets => 'Cargando entradas...';

  @override
  String get availableTickets => 'Entradas disponibles';

  @override
  String get createTicket => 'Crear entrada';

  @override
  String get noTicketsAvailable => 'No hay entradas disponibles';

  @override
  String get createTicketForUsers =>
      'Crea una entrada para que los usuarios puedan registrarse';

  @override
  String errorLoadingTickets(String error) {
    return 'Error al cargar entradas: $error';
  }

  @override
  String get alreadyRegistered => 'Ya registrado';

  @override
  String get viewQr => 'Ver QR';

  @override
  String get register => 'Registrarse';

  @override
  String get presential => 'Presencial';

  @override
  String get unknown => 'Desconocido';

  @override
  String get cults => 'Cultos';

  @override
  String unknownSectionType(String sectionType) {
    return 'Sección desconocida o error: $sectionType';
  }

  @override
  String get additionalInformationRequired => 'Información adicional necesaria';

  @override
  String get pleaseCompleteAdditionalInfo =>
      'Por favor, completa tu información adicional para mejorar tu experiencia en la iglesia.';

  @override
  String get churchName => 'Amor en Movimiento';

  @override
  String get navHome => 'Inicio';

  @override
  String get navNotifications => 'Notificaciones';

  @override
  String get navCalendar => 'Calendario';

  @override
  String get navVideos => 'Videos';

  @override
  String get navProfile => 'Perfil';

  @override
  String errorPublishingComment(String error) {
    return 'Error al publicar el comentario: $error';
  }

  @override
  String get deleteOwnCommentsOnly =>
      'Solo puedes eliminar tus propios comentarios';

  @override
  String get deleteComment => 'Eliminar comentario';

  @override
  String get deleteCommentConfirmation =>
      '¿Estás seguro de que deseas eliminar este comentario?';

  @override
  String get commentDeleted => 'Comentario eliminado';

  @override
  String errorDeletingComment(String error) {
    return 'Error al eliminar el comentario: $error';
  }

  @override
  String get errorTitle => 'Error';

  @override
  String get cultNotFound => 'Culto no encontrado';

  @override
  String totalLessons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# lecciones',
      one: '# lección',
    );
    return '$_temp0';
  }

  @override
  String get myKidsManagement => 'Gestión MyKids';

  @override
  String get familyProfiles => 'Perfiles Familiares';

  @override
  String get manageFamilyProfiles => 'Gestionar perfiles de padres y niños';

  @override
  String get manageRoomsAndCheckin => 'Gestionar Salas y Check-in';

  @override
  String get manageRoomsCheckinDescription =>
      'Administrar salas, check-in/out y asistencia';

  @override
  String get permissionsDiagnostics => 'Diagnóstico de Permisos';

  @override
  String get availablePermissions => 'Permisos Disponibles';

  @override
  String get noUserData => 'No hay datos de usuario';

  @override
  String get noName => 'Sin nombre';

  @override
  String get noEmail => 'Sin email';

  @override
  String get roleIdLabel => 'ID del Rol';

  @override
  String get noRole => 'Sin rol';

  @override
  String get superUser => 'SuperUsuario';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get rolePermissionsTitle => 'Permisos del rol';

  @override
  String get roleNoPermissions => 'Este rol no tiene permisos asignados';

  @override
  String get noRoleInfo => 'No hay información de rol disponible';

  @override
  String get deleteGroupConfirmationPrefix =>
      '¿Estás seguro que deseas eliminar el grupo ';

  @override
  String get deleteMinistryConfirmationPrefix =>
      '¿Estás seguro que deseas eliminar el ministerio ';

  @override
  String errorFetchingDiagnostics(String error) {
    return 'Error al obtener diagnóstico: $error';
  }

  @override
  String roleNotFound(String roleId) {
    return 'Rol no encontrado: $roleId';
  }

  @override
  String get idLabel => 'ID';

  @override
  String get personalInformationSection => 'Información Personal';

  @override
  String get birthDateField => 'Fecha de Nacimiento';

  @override
  String get genderField => 'Sexo';

  @override
  String get phoneField => 'Teléfono';

  @override
  String get mySchedulesSection => 'Mis Turnos';

  @override
  String get manageMinistriesAssignments =>
      'Gestiona tus asignaciones e invitaciones de trabajo en los ministerios';

  @override
  String errorSavingInfo(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get requiredFieldTooltip => 'Campo obligatorio';

  @override
  String get navigateToFamilyProfiles => 'Navegar para Perfiles Familiares';

  @override
  String get personalInfoUpdatedSuccessfully =>
      '¡Información personal actualizada con éxito!';

  @override
  String errorSavingPersonalData(String error) {
    return 'Error al guardar datos personales: $error';
  }

  @override
  String errorLoadingPersonalData(String error) {
    return 'Error al cargar datos personales: $error';
  }

  @override
  String get manageDonationsTitle => 'Gestionar Donaciones';

  @override
  String get noPermissionToSaveSettings =>
      'Sin permiso para guardar configuraciones.';

  @override
  String get errorUploadingImage => 'Error al subir imagen';

  @override
  String get donationConfigSaved => 'Configuraciones de donación guardadas';

  @override
  String errorCheckingPermission(String error) {
    return 'Error al verificar permiso: $error';
  }

  @override
  String get accessDenied => 'Acceso Denegado';

  @override
  String get noPermissionManageDonations =>
      'No tienes permiso para gestionar las configuraciones de donación.';

  @override
  String get configureDonationsSection =>
      'Configura cómo aparecerá la sección de donaciones en la Pantalla de Inicio.';

  @override
  String get sectionTitleOptional => 'Título de la Sección (Opcional)';

  @override
  String get descriptionOptional => 'Descripción (Opcional)';

  @override
  String get backgroundImageOptional => 'Imagen de Fondo (Opcional)';

  @override
  String get tapToAddImage => 'Toca para agregar imagen\n(Recomendado 16:9)';

  @override
  String get removeImage => 'Eliminar Imagen';

  @override
  String get bankAccountsOptional => 'Cuentas Bancarias (Opcional)';

  @override
  String get bankingInformation => 'Información Bancaria';

  @override
  String get bankAccountsHint =>
      'Banco: XXX\nAgencia: YYYY\nCuenta: ZZZZZZ\nNombre Titular\n\n(Separa cuentas con línea en blanco)';

  @override
  String get pixKeysOptional => 'Claves Pix (Opcional)';

  @override
  String get noPixKeysAdded => 'Ninguna clave Pix agregada.';

  @override
  String get pixKey => 'Clave Pix';

  @override
  String get removeKey => 'Eliminar Clave';

  @override
  String get keyRequired => 'Clave obligatoria';

  @override
  String get addPixKey => 'Agregar Clave Pix';

  @override
  String get saveSettings => 'Guardar Configuraciones';

  @override
  String get manageLiveStreamTitle => 'Gestionar Transmisión';

  @override
  String errorLoadingData(String error) {
    return 'Error al cargar datos: $error';
  }

  @override
  String get noPermissionManageLiveStream =>
      'No tienes permiso para gestionar la configuración de transmisión.';

  @override
  String get sectionTitleHome => 'Título de la Sección (Home)';

  @override
  String get sectionTitleHint => 'Ej: Transmisión En Vivo';

  @override
  String get pleaseEnterSectionTitle =>
      'Por favor, ingresa un título para la sección';

  @override
  String get additionalTextOptional => 'Texto Adicional (opcional)';

  @override
  String get transmissionImage => 'Imagen de la Transmisión';

  @override
  String get titleOverImage => 'Título sobre la Imagen';

  @override
  String get titleOverImageHint => 'Ej: Culto de Domingo';

  @override
  String get transmissionLink => 'Link de la Transmisión';

  @override
  String get urlYouTubeVimeo => 'URL (YouTube, Vimeo, etc.)';

  @override
  String get pasteFullLinkHere => 'Pega el link completo aquí';

  @override
  String get pleaseEnterValidUrl =>
      'Por favor, ingresa una URL válida (comenzando con http o https)';

  @override
  String get activateTransmissionHome => 'Activar Transmisión en Home';

  @override
  String get visibleInHome => 'Visible en Home';

  @override
  String get hiddenInHome => 'Oculto en Home';

  @override
  String get saveConfiguration => 'Guardar Configuración';

  @override
  String get configurationSaved => 'Configuración guardada';

  @override
  String get errorUploadingImageStream => 'Error al subir la imagen';

  @override
  String get manageHomeScreenTitle => 'Gestionar Pantalla de Inicio';

  @override
  String get noPermissionReorderSections =>
      'Sin permiso para reordenar secciones.';

  @override
  String errorSavingNewOrder(String error) {
    return 'Error al guardar el nuevo orden: $error';
  }

  @override
  String get noPermissionEditSections => 'Sin permiso para editar secciones.';

  @override
  String get editSectionName => 'Editar Nombre de la Sección';

  @override
  String get sectionNameUpdatedSuccessfully =>
      '¡Nombre de la sección actualizado con éxito!';

  @override
  String errorUpdatingName(String error) {
    return 'Error al actualizar nombre: $error';
  }

  @override
  String get configureVisibility => 'Configurar Visibilidad';

  @override
  String sectionWillBeHiddenWhen(String contentType) {
    return 'La sección será ocultada cuando no haya $contentType para mostrar.';
  }

  @override
  String get visibilityConfigurationUpdated =>
      '¡Configuración de visibilidad actualizada!';

  @override
  String errorUpdatingConfiguration(String error) {
    return 'Error al actualizar configuración: $error';
  }

  @override
  String get noPermissionChangeStatus => 'Sin permiso para cambiar estado.';

  @override
  String errorUpdatingStatus(String error) {
    return 'Error al actualizar estado: $error';
  }

  @override
  String get thisSectionCannotBeEditedHere =>
      'Esta sección no puede ser editada aquí.';

  @override
  String get noPermissionCreateSections => 'Sin permiso para crear secciones.';

  @override
  String get noSectionsFound => 'Ninguna sección encontrada.';

  @override
  String get scheduledCults => 'cultos programados';

  @override
  String get pages => 'páginas';

  @override
  String get content => 'contenido';

  @override
  String get manageProfileFieldsTitle => 'Gestionar Campos de Perfil';

  @override
  String get noPermissionManageProfileFields =>
      'No tienes permiso para gestionar campos de perfil.';

  @override
  String get createField => 'Crear Campo';

  @override
  String confirmDeleteField(String fieldName) {
    return '¿Estás seguro de que deseas eliminar el campo \"$fieldName\"?';
  }

  @override
  String get fieldDeletedSuccessfully => 'Campo eliminado con éxito';

  @override
  String errorDeletingField(String error) {
    return 'Error al eliminar el campo: $error';
  }

  @override
  String get pleaseAddAtLeastOneOption =>
      'Por favor, añade al menos una opción para el campo de selección.';

  @override
  String get noPermissionManageFields =>
      'Sin permiso para gestionar campos de perfil.';

  @override
  String get manageRolesTitle => 'Gestionar Perfiles';

  @override
  String get confirmDeletionRole => 'Confirmar Eliminación';

  @override
  String confirmDeleteRole(String roleName) {
    return '¿Estás seguro de que quieres eliminar el perfil \"$roleName\"?';
  }

  @override
  String get warningDeleteRole =>
      'Atención: Esto puede afectar a usuarios que tienen este perfil asignado.';

  @override
  String get noPermissionDeleteRoles => 'Sin permiso para eliminar perfiles';

  @override
  String get roleDeletedSuccessfully => 'Perfil eliminado con éxito';

  @override
  String errorDeletingRole(String error) {
    return 'Error al eliminar perfil: $error';
  }

  @override
  String get noPermissionManageRoles =>
      'No tienes permiso para gestionar perfiles y permisos.';

  @override
  String errorLoadingRoles(String error) {
    return 'Error al cargar perfiles: $error';
  }

  @override
  String get noRolesFound => 'Ningún perfil encontrado. ¡Crea el primero!';

  @override
  String get manageUserRolesTitle => 'Gestionar Perfiles de Usuarios';

  @override
  String get noPermissionAccessPage =>
      'No tienes permiso para acceder a esta página';

  @override
  String errorCheckingPermissions(String error) {
    return 'Error al verificar permisos: $error';
  }

  @override
  String errorLoadingRolesData(String error) {
    return 'Error al cargar perfiles: $error';
  }

  @override
  String errorLoadingUsers(String error) {
    return 'Error al cargar usuarios: $error';
  }

  @override
  String get noPermissionUpdateRoles =>
      'No tienes permiso para actualizar perfiles.';

  @override
  String get cannotChangeOwnRole => 'No es posible cambiar tu propio perfil';

  @override
  String get userRoleUpdatedSuccessfully =>
      'Perfil del usuario actualizado con éxito';

  @override
  String errorUpdatingRole(String error) {
    return 'Error al actualizar perfil: $error';
  }

  @override
  String get selectUserRole => 'Seleccionar perfil del usuario';

  @override
  String get manageCoursesTitle => 'Gestionar Cursos';

  @override
  String get noPermissionManageCourses =>
      'No tienes permiso para gestionar cursos.';

  @override
  String errorLoadingCourses(String error) {
    return 'Error al cargar cursos: $error';
  }

  @override
  String get published => 'Publicados';

  @override
  String get drafts => 'Borradores';

  @override
  String get archived => 'Archivados';

  @override
  String get edit => 'Editar';

  @override
  String get unpublish => 'Despublicar';

  @override
  String get publish => 'Publicar';

  @override
  String get publishCourse => 'Publicar curso';

  @override
  String get makeCourseVisibleToAllUsers =>
      'Hacer el curso visible para todos los usuarios';
}
