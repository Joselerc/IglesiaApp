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
  String get selectDate => 'Selecciona una fecha';

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
  String errorLoadingMinistries(Object error) {
    return 'Error al cargar ministerios: $error';
  }

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
  String errorLoadingGroups(Object error) {
    return 'Error al cargar grupos: $error';
  }

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
  String get manageVideos => 'Gestionar Vídeos';

  @override
  String get administerChurchSectionsVideos =>
      'Administra las secciones y videos de la iglesia';

  @override
  String get administerCults => 'Administrar Cultos';

  @override
  String get manageCultsMinistriesSongs =>
      'Gestionar cultos, ministerios y canciones';

  @override
  String get createMinistry => 'Crear Ministerios';

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
  String get deleteGroup => 'Eliminar Connect';

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
    return 'Grupo eliminado con éxito';
  }

  @override
  String errorDeletingGroup(String error) {
    return 'Error al eliminar grupo: $error';
  }

  @override
  String get deleteMinistry => 'Eliminar Ministerios';

  @override
  String get confirmDeleteMinistryQuestion =>
      '¿Está seguro que desea eliminar el ministerio ';

  @override
  String get deleteMinistryWarning =>
      '\n\nEsta acción no se puede deshacer y eliminará todos los mensajes y eventos asociados.';

  @override
  String ministryDeletedSuccessfully(String ministryName) {
    return 'Ministerio eliminado con éxito';
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
  String get requiredField => 'Campo Obligatorio';

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
  String get serviceStatistics => 'Estadísticas de Escalas';

  @override
  String get home => 'Inicio';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get calendar => 'Calendario';

  @override
  String get videos => 'Vídeos';

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
    return 'Error al cargar eventos: $error';
  }

  @override
  String get calendars => 'Calendarios';

  @override
  String get events => 'Eventos';

  @override
  String get services => 'Escalas';

  @override
  String get counseling => 'Asesoramiento';

  @override
  String get manageSections => 'Gestionar secciones';

  @override
  String get recentVideos => 'Vídeos Recientes';

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
  String get email => 'Correo Electrónico';

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
  String get announcements => 'Anuncios';

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
    return 'Lecciones';
  }

  @override
  String minutes(int count) {
    return 'minutos';
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
  String get connect => 'Connect';

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
  String get announcementDeletedSuccessfully =>
      'Anuncio eliminado correctamente';

  @override
  String errorDeletingAnnouncement(String error) {
    return 'Error al eliminar el anuncio: $error';
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
  String cult(Object cultName) {
    return 'Culto: $cultName';
  }

  @override
  String publishedOn(String date) {
    return 'Publicado el:';
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
      'Asistencia registrada con éxito';

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
  String cults(Object count) {
    return '$count cultos';
  }

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
    return 'Error al publicar el comentario';
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
    return '$count Lecciones';
  }

  @override
  String get myKidsManagement => 'Gestión MyKids';

  @override
  String get familyProfiles => 'Perfiles Familiares';

  @override
  String get manageFamilyProfiles => 'Gestionar Perfiles Familiares';

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
  String get noRole => 'Sin Rol';

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
  String get tapToAddImage => 'Toca para añadir una imagen';

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
  String get scheduledCults => 'Cultos programados';

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
    return '¿Estás seguro de que quieres eliminar el campo \'$fieldName\'?';
  }

  @override
  String get fieldDeletedSuccessfully => 'Campo eliminado con éxito';

  @override
  String errorDeletingField(String error) {
    return 'Error al eliminar campo: $error';
  }

  @override
  String get pleaseAddAtLeastOneOption =>
      'Por favor, añade al menos una opción para el campo de selección.';

  @override
  String get noPermissionManageFields =>
      'No tienes permiso para gestionar campos.';

  @override
  String get manageRolesTitle => 'Gestionar Perfiles';

  @override
  String get confirmDeletionRole => 'Confirmar Eliminación de Rol';

  @override
  String confirmDeleteRole(String roleName) {
    return '¿Estás seguro de que quieres eliminar el rol \'$roleName\'?';
  }

  @override
  String get warningDeleteRole =>
      'Esta acción no se puede deshacer y afectará a todos los usuarios con este rol.';

  @override
  String get noPermissionDeleteRoles => 'Sin permiso para eliminar perfiles';

  @override
  String get roleDeletedSuccessfully => 'Rol eliminado con éxito';

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
      'No tienes permiso para acceder a esta página.';

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
  String get cannotChangeOwnRole => 'No es posible cambiar tu propio rol';

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
  String get published => 'Publicado';

  @override
  String get drafts => 'Borradores';

  @override
  String get archived => 'Archivado';

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

  @override
  String get createProfileField => 'Crear Campo de Perfil';

  @override
  String get editProfileField => 'Editar Campo de Perfil';

  @override
  String get fieldActive => 'Campo Activo';

  @override
  String get showThisFieldInProfile => 'Mostrar este campo en el perfil';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get fieldCreatedSuccessfully => 'Campo creado con éxito';

  @override
  String get fieldUpdatedSuccessfully => 'Campo actualizado con éxito';

  @override
  String get userNotAuthenticated => 'Usuario no autenticado';

  @override
  String get noProfileFieldsDefined => 'No hay campos de perfil definidos';

  @override
  String get fieldType => 'Tipo de Campo';

  @override
  String get text => 'Texto';

  @override
  String get number => 'Número';

  @override
  String get date => 'Fecha:';

  @override
  String select(Object count) {
    return 'Seleccionar ($count)';
  }

  @override
  String get donationSettings => 'Configuración de Donaciones';

  @override
  String get enableDonations => 'Habilitar donaciones';

  @override
  String get showDonationSection =>
      'Mostrar sección de donaciones en la aplicación';

  @override
  String get bankName => 'Nombre del Banco';

  @override
  String get accountNumber => 'Número de Cuenta';

  @override
  String get clabe => 'CLABE (México)';

  @override
  String get paypalMeLink => 'Enlace PayPal.Me';

  @override
  String get mercadoPagoAlias => 'Alias Mercado Pago';

  @override
  String get stripePublishableKey => 'Clave Publicable de Stripe';

  @override
  String get donationInformation => 'Información de Donación';

  @override
  String get saveDonationSettings => 'Guardar Configuración de Donaciones';

  @override
  String get donationSettingsUpdated =>
      'Configuración de donaciones actualizada con éxito.';

  @override
  String errorUpdatingDonationSettings(Object error) {
    return 'Error al actualizar la configuración de donaciones: $error';
  }

  @override
  String get enterBankName => 'Ingrese el nombre del banco';

  @override
  String get enterAccountNumber => 'Ingrese el número de cuenta';

  @override
  String get enterClabe => 'Ingrese la CLABE';

  @override
  String get enterPaypalMeLink => 'Ingrese el enlace de PayPal.Me';

  @override
  String get enterMercadoPagoAlias => 'Ingrese el alias de Mercado Pago';

  @override
  String get enterStripePublishableKey =>
      'Ingrese la clave publicable de Stripe';

  @override
  String get cnpj => 'CNPJ';

  @override
  String get cpf => 'CPF';

  @override
  String get random => 'Aleatoria';

  @override
  String get filterBy => 'Filtrar por:';

  @override
  String get createNewCourse => 'Crear Nuevo Curso';

  @override
  String get noCoursesFound => 'Ningún curso encontrado';

  @override
  String get clickToCreateNewCourse =>
      'Haz clic en el botón \'+\' para crear un nuevo curso';

  @override
  String get draft => 'Borrador';

  @override
  String get featured => 'Destacado';

  @override
  String modules(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Módulos',
      one: '1 Módulo',
    );
    return '$_temp0';
  }

  @override
  String optionsFor(Object courseTitle) {
    return 'Opciones para \"$courseTitle\"';
  }

  @override
  String get unpublishCourse => 'Despublicar (volver a borrador)';

  @override
  String get makeCourseInvisible =>
      'Hacer el curso invisible para los usuarios';

  @override
  String get removeFeatured => 'Quitar de destacados';

  @override
  String get addFeatured => 'Destacar curso';

  @override
  String get removeFromFeatured => 'Quitar de la sección de destacados';

  @override
  String get addToFeatured => 'Mostrar el curso en la sección de destacados';

  @override
  String get deleteCourse => 'Eliminar curso';

  @override
  String get thisActionIsIrreversible => 'Esta acción no puede ser deshecha';

  @override
  String areYouSureYouWantToDelete(Object courseTitle) {
    return '¿Seguro que quieres eliminar el curso \"$courseTitle\"?';
  }

  @override
  String get irreversibleActionWarning =>
      'Esta acción es irreversible y eliminará todos los módulos, lecciones, materiales y progreso de los usuarios asociados a este curso.';

  @override
  String get courseDeletedSuccessfully => 'Curso eliminado con éxito';

  @override
  String errorDeletingCourse(Object error) {
    return 'Error al eliminar el curso: $error';
  }

  @override
  String get coursePublishedSuccessfully => 'Curso publicado con éxito';

  @override
  String get courseUnpublishedSuccessfully => 'Curso despublicado con éxito';

  @override
  String get courseFeaturedSuccessfully => 'Curso destacado con éxito';

  @override
  String get featuredRemovedSuccessfully => 'Destacado eliminado con éxito';

  @override
  String errorUpdatingFeatured(Object error) {
    return 'Error al actualizar el destacado: $error';
  }

  @override
  String get instructor => 'Instructor';

  @override
  String get duration => 'Duración';

  @override
  String get lessonsLabel => 'Lecciones';

  @override
  String get category => 'Categoría';

  @override
  String get enroll => 'Inscribirse';

  @override
  String get alreadyEnrolled => 'Ya estás inscrito';

  @override
  String get courseContent => 'Contenido del Curso';

  @override
  String get lesson => 'Lección';

  @override
  String get materials => 'Materiales';

  @override
  String get comments => 'Comentarios';

  @override
  String get course => 'Curso';

  @override
  String get markAsCompleted => 'Marcar como completada';

  @override
  String get processing => 'Procesando...';

  @override
  String get evaluateThisLesson => 'Evaluar esta lección';

  @override
  String get averageRating => 'Evaluación media';

  @override
  String get lessonCompleted => 'Lección completada';

  @override
  String get alreadyCompleted => 'Ya has completado esta lección';

  @override
  String get errorCompletingLesson =>
      'Error al marcar la lección como completada';

  @override
  String get noMaterialsForThisLesson => 'No hay materiales para esta lección';

  @override
  String get noCommentsForThisLesson => 'No hay comentarios para esta lección';

  @override
  String get addYourComment => 'Añade tu comentario...';

  @override
  String get commentPublished => 'Comentario publicado';

  @override
  String get loginToComment => 'Inicia sesión para comentar';

  @override
  String get rateTheLesson => 'Evalúa la lección';

  @override
  String get ratingSaved => 'Evaluación guardada';

  @override
  String get errorSavingRating => 'Error al guardar la evaluación';

  @override
  String get loginToRate => 'Inicia sesión para evaluar';

  @override
  String get courseNotFound => 'Curso no encontrado';

  @override
  String get courseNotFoundDetails => 'El curso no existe o fue eliminado';

  @override
  String get errorLoadingLessonCount =>
      'Error al cargar el conteo de lecciones';

  @override
  String errorTogglingFavorite(Object error) {
    return 'Error al cambiar favorito: $error';
  }

  @override
  String errorLoadingModules(Object error) {
    return 'Error al cargar módulos: $error';
  }

  @override
  String get noModulesAvailable => 'No hay módulos disponibles';

  @override
  String errorLoadingLessons(Object error) {
    return 'Error al cargar lecciones: $error';
  }

  @override
  String get noLessonsAvailableInModule => 'No hay lecciones disponibles';

  @override
  String errorEnrolling(Object error) {
    return 'Error al inscribirse: $error';
  }

  @override
  String get enrollToAccessLesson =>
      'Inscríbete al curso para acceder a esta lección';

  @override
  String get noLessonsAvailable => 'No hay lecciones disponibles en este curso';

  @override
  String get loginToEnroll => 'Debes iniciar sesión para inscribirte';

  @override
  String get enrolledSuccess => '¡Te has inscrito al curso!';

  @override
  String get startCourse => 'Comenzar Curso';

  @override
  String get continueCourse => 'Continuar Curso';

  @override
  String progressWithDetails(
      Object completed, Object percentage, Object total) {
    return 'Progreso: $percentage% ($completed/$total)';
  }

  @override
  String instructorLabel(Object name) {
    return 'Instructor: $name';
  }

  @override
  String get lessonNotFound => 'Lección no encontrada';

  @override
  String get lessonNotFoundDetails =>
      'No fue posible encontrar la lección solicitada';

  @override
  String durationLabel(Object duration) {
    return 'Duración: $duration';
  }

  @override
  String get unmarkAsCompleted => 'Desmarcar como completada';

  @override
  String get lessonUnmarked => 'Lección desmarcada como completada';

  @override
  String get noVideoAvailable => 'Ningún vídeo disponible';

  @override
  String get clickToWatchVideo => 'Haz clic para ver el vídeo';

  @override
  String get noDescription => 'Sin descripción';

  @override
  String get commentsDisabled =>
      'Los comentarios están desactivados para esta lección';

  @override
  String get noCommentsYet => 'Ningún comentario aún';

  @override
  String get beTheFirstToComment => 'Sé el primero en comentar';

  @override
  String get you => 'Tú';

  @override
  String get reply => 'respuesta';

  @override
  String get replies => 'respuestas';

  @override
  String get repliesFunctionality =>
      'Funcionalidad de respuestas en desarrollo';

  @override
  String get confirmDeleteComment =>
      '¿Seguro que quieres eliminar este comentario?';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(Object days) {
    return 'Hace $days días';
  }

  @override
  String get linkCopiedToClipboard => 'Enlace copiado al portapapeles';

  @override
  String get open => 'Abrir';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get managePagesTitle => 'Gestionar Páginas';

  @override
  String get noPermissionManagePages =>
      'No tienes permiso para gestionar páginas personalizadas.';

  @override
  String errorLoadingPages(Object error) {
    return 'Error al cargar páginas: $error';
  }

  @override
  String get noCustomPagesYet => 'Aún no hay páginas personalizadas.';

  @override
  String get tapPlusToCreateFirst => 'Toca el botón + para crear la primera.';

  @override
  String get pageWithoutTitle => 'Página sin título';

  @override
  String get noPermissionEditPages => 'No tienes permiso para editar páginas.';

  @override
  String get noPermissionCreatePages => 'No tienes permiso para crear páginas.';

  @override
  String get createNewPage => 'Crear nueva página';

  @override
  String get editPageTitle => 'Editar Página';

  @override
  String get pageTitle => 'Título de la Página';

  @override
  String get pageTitleHint => 'Ej: Sobre Nosotros';

  @override
  String get appearanceInPageList => 'Apariencia en la Lista de Páginas';

  @override
  String get visualizationType => 'Tipo de Visualización en la Lista';

  @override
  String get iconAndTitle => 'Ícono y Título';

  @override
  String get coverImage16x9 => 'Imagen de Portada (16:9)';

  @override
  String get icon => 'Ícono';

  @override
  String get coverImageLabel => 'Imagen de Portada (16:9)';

  @override
  String get changeImage => 'Cambiar Imagen';

  @override
  String get selectImage => 'Seleccionar Imagen';

  @override
  String get pageContentLabel => 'Contenido de la Página';

  @override
  String get typePageContentHere => 'Escribe el contenido de la página aquí...';

  @override
  String get insertImage => 'Insertar Imagen';

  @override
  String get savePage => 'Guardar Página';

  @override
  String get pleaseEnterPageTitle =>
      'Por favor, introduce un título para la página.';

  @override
  String get pleaseSelectIcon =>
      'Por favor, selecciona un icono para la página.';

  @override
  String get pleaseUploadCoverImage =>
      'Por favor, sube una imagen para la portada.';

  @override
  String errorInsertingImage(Object error) {
    return 'Error al insertar imagen: $error';
  }

  @override
  String get coverImageUploaded => '¡Imagen de portada cargada!';

  @override
  String errorUploadingCoverImage(Object error) {
    return 'Error al cargar imagen de portada: $error';
  }

  @override
  String get pageSavedSuccessfully => '¡Página guardada con éxito!';

  @override
  String errorSavingPage(Object error) {
    return 'Error al guardar página: $error';
  }

  @override
  String get discardChanges => '¿Descartar Cambios?';

  @override
  String get unsavedChangesConfirm =>
      'Tienes cambios sin guardar. ¿Quieres salir de todos modos?';

  @override
  String get discardAndExit => 'Descartar y Salir';

  @override
  String get restoreDraft => '¿Restaurar Borrador?';

  @override
  String get unsavedChangesFound =>
      'Encontramos cambios no guardados. ¿Quieres restaurarlos?';

  @override
  String get discardDraft => 'Descartar Borrador';

  @override
  String get restore => 'Restaurar';

  @override
  String get imageUploadFailed => 'Error al cargar la imagen.';

  @override
  String errorLoadingPage(Object error) {
    return 'Error al cargar página: $error';
  }

  @override
  String get editSectionTitle => 'Editar Sección';

  @override
  String get createNewSection => 'Crear Nueva Sección';

  @override
  String get deleteSection => 'Eliminar sección';

  @override
  String get sectionTitleLabel => 'Título de la Sección';

  @override
  String get pleaseEnterTitle => 'Por favor, introduce un título';

  @override
  String get pagesIncludedInSection => 'Páginas Incluidas en esta Sección';

  @override
  String get noCustomPagesFound =>
      'Ninguna página personalizada encontrada para seleccionar.';

  @override
  String pageWithoutTitleShort(Object id) {
    return 'Página sin título ($id...)';
  }

  @override
  String get selectAtLeastOnePage => 'Selecciona al menos una página.';

  @override
  String errorSavingSection(Object error) {
    return 'Error al guardar sección: $error';
  }

  @override
  String get deleteSectionConfirm => '¿Eliminar Sección?';

  @override
  String deleteSectionMessage(Object title) {
    return '¿Estás seguro de que quieres eliminar la sección \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String errorDeleting(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get sectionNameUpdated =>
      '¡Nombre de la sección actualizado con éxito!';

  @override
  String typeLabel(Object type) {
    return 'Tipo: $type';
  }

  @override
  String get sectionName => 'Nombre de la Sección';

  @override
  String sectionLabel(Object title) {
    return 'Sección: $title';
  }

  @override
  String get hideWhenNoContent => 'Ocultar sección cuando no haya contenido:';

  @override
  String get visibilityConfigUpdated =>
      '¡Configuración de visibilidad actualizada!';

  @override
  String errorUpdatingConfig(Object error) {
    return 'Error al actualizar configuración: $error';
  }

  @override
  String get sectionCannotBeEditedHere =>
      'Esta sección no se puede editar aquí.';

  @override
  String get createNewPageSection => 'Crear Nueva Sección de Páginas';

  @override
  String get noPermissionManageHomeSections =>
      'No tienes permiso para gestionar las secciones de la pantalla de inicio.';

  @override
  String get editName => 'Editar nombre';

  @override
  String get hiddenWhenEmpty => 'Oculta cuando vacía';

  @override
  String get alwaysVisible => 'Siempre visible';

  @override
  String get liveStreamLabel => 'En Vivo';

  @override
  String get donations => 'Donaciones';

  @override
  String get onlineCourses => 'Cursos Online';

  @override
  String get customPages => 'Páginas Personalizadas';

  @override
  String get unknownSection => 'Sección Desconocida';

  @override
  String get servicesGridObsolete => 'Cuadrícula de Servicios (Obsoleto)';

  @override
  String get liveStreamType => 'Transmisión en vivo';

  @override
  String get courses => 'Cursos';

  @override
  String get pageList => 'Lista de Páginas';

  @override
  String get sectionWillBeDisplayed =>
      'La sección se mostrará siempre, aunque no haya contenido.';

  @override
  String errorVerifyingPermission(Object error) {
    return 'Error al verificar permiso: $error';
  }

  @override
  String get configureAvailability => 'Configurar Disponibilidad';

  @override
  String get consultationSettings => 'Configuración de Consultas';

  @override
  String get noPermissionManageAvailability =>
      'No tienes permiso para gestionar la disponibilidad.';

  @override
  String errorLoadingAvailability(Object error) {
    return 'Error al cargar disponibilidad: $error';
  }

  @override
  String timeSlots(Object count) {
    return '$count franjas horarias';
  }

  @override
  String get confirmDeleteAllTimeSlots =>
      '¿Estás seguro de que quieres eliminar todas las franjas de horario?';

  @override
  String get deleteSlot => 'Eliminar franja';

  @override
  String get unavailableForConsultations => 'No disponible para consultas';

  @override
  String get dayMarkedAvailableAddTimeSlots =>
      'Día marcado como disponible, añade franjas de horario';

  @override
  String weekOf(Object date) {
    return 'Semana del $date';
  }

  @override
  String get copyToNextWeek => 'Copiar a la próxima semana';

  @override
  String get counselingConfiguration => 'Configuración de Asesoramiento';

  @override
  String get counselingDuration => 'Duración del Asesoramiento';

  @override
  String get configureCounselingDuration =>
      'Configura cuánto tiempo durará cada Asesoramiento';

  @override
  String get intervalBetweenConsultations => 'Intervalo entre Consultas';

  @override
  String get configureRestTimeBetweenConsultations =>
      'Configura cuánto tiempo de descanso habrá entre consultas';

  @override
  String get configurationSavedSuccessfully =>
      'Configuración guardada con éxito';

  @override
  String get dayUpdatedSuccessfully => 'Día actualizado con éxito';

  @override
  String errorCopying(Object error) {
    return 'Error al copiar: $error';
  }

  @override
  String get addTimeSlots => 'Añadir franjas de horario';

  @override
  String get editAvailability => 'Editar disponibilidad';

  @override
  String get manageAnnouncements => 'Gestionar Anuncios';

  @override
  String get active => 'Activo';

  @override
  String get inactiveExpired => 'Inactivos/Vencidos';

  @override
  String get regular => 'Regulares';

  @override
  String get confirmAnnouncementDeletion => 'Confirmar eliminación';

  @override
  String get confirmDeleteAnnouncementMessage =>
      '¿Estás seguro de que quieres eliminar este anuncio? Esta acción no se puede deshacer.';

  @override
  String get noActiveAnnouncements => 'No hay anuncios activos';

  @override
  String get noInactiveExpiredAnnouncements =>
      'No hay anuncios inactivos/vencidos';

  @override
  String get managedEvents => 'Eventos Administrados';

  @override
  String get update => 'Actualizar';

  @override
  String get noPermissionManageEventAttendance =>
      'No tienes permiso para gestionar la asistencia de eventos.';

  @override
  String get manageAttendance => 'Gestionar Asistencia';

  @override
  String get noEventsMinistries => 'de ministerios';

  @override
  String get noEventsGroups => 'de grupos';

  @override
  String noEventsMessage(Object filter) {
    return 'No hay eventos $filter';
  }

  @override
  String get eventsYouAdministerWillAppearHere =>
      'Los eventos que administras aparecerán aquí';

  @override
  String get noTitle => 'Sin título';

  @override
  String get ministry => 'Ministerio';

  @override
  String get group => 'Grupo';

  @override
  String get noPermissionManageVideos =>
      'No tienes permiso para gestionar vídeos.';

  @override
  String get noVideosFound => 'Ningún vídeo encontrado';

  @override
  String get deleteVideo => 'Eliminar Vídeo';

  @override
  String deleteVideoConfirmation(Object title) {
    return '¿Estás seguro de que quieres eliminar el vídeo \"$title\"?';
  }

  @override
  String get videoDeletedSuccessfully => 'Vídeo eliminado con éxito';

  @override
  String errorDeletingVideo(Object error) {
    return 'Error al eliminar vídeo: $error';
  }

  @override
  String minutesAgo(Object minutes) {
    return 'Hace $minutes minutos';
  }

  @override
  String hoursAgo(Object hours) {
    return 'Hace $hours horas';
  }

  @override
  String get createAnnouncement => 'Crear Anuncio';

  @override
  String errorVerifyingPermissionAnnouncement(Object error) {
    return 'Error al verificar permiso: $error';
  }

  @override
  String get noPermissionCreateAnnouncements =>
      'No tienes permiso para crear anuncios.';

  @override
  String errorSelectingImage(Object error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get announcementCreatedSuccessfully => 'Anuncio creado con éxito';

  @override
  String errorCreatingAnnouncement(Object error) {
    return 'Error al crear anuncio: $error';
  }

  @override
  String get addImage => 'Añadir imagen';

  @override
  String get recommended16x9 => 'Recomendado: 16:9 (1920x1080)';

  @override
  String get announcementTitle => 'Título del Anuncio';

  @override
  String get enterClearConciseTitle => 'Introduce un título claro y conciso';

  @override
  String get pleasEnterTitle => 'Por favor, introduce un título';

  @override
  String get provideAnnouncementDetails =>
      'Proporciona detalles sobre el anuncio';

  @override
  String get pleaseEnterDescription => 'Por favor, introduce una descripción';

  @override
  String get announcementExpirationDate => 'Fecha del anuncio/expiración';

  @override
  String get optionalSelectDate => 'Opcional: Selecciona una fecha';

  @override
  String get pleaseSelectAnnouncementImage =>
      'Por favor, selecciona una imagen para el anuncio';

  @override
  String get publishAnnouncement => 'Publicar Anuncio';

  @override
  String get createEvent => 'Crear Evento';

  @override
  String get upcoming => 'Próximamente';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get thisMonth => 'Este mes';

  @override
  String get noEventsFound => 'Ningún evento encontrado';

  @override
  String get tryAnotherFilterOrCreateEvent =>
      'Prueba otro filtro o crea un nuevo evento';

  @override
  String get trySelectingAnotherFilter => 'Prueba seleccionando otro filtro';

  @override
  String get noLocation => 'Sin ubicación';

  @override
  String get tickets => 'Entradas';

  @override
  String get seeDetails => 'Ver Detalles';

  @override
  String get videoSections => 'Secciones de Vídeos';

  @override
  String get reorderSections => 'Reordenar secciones';

  @override
  String get saveOrder => 'Guardar orden';

  @override
  String get dragSectionsToReorder =>
      'Arrastra las secciones para reordenarlas';

  @override
  String get noSectionCreated => 'Ninguna sección creada';

  @override
  String get createFirstSection => 'Crear Primera Sección';

  @override
  String get dragToReorderPressWhenDone =>
      'Arrastra para reordenar. Presiona el botón concluido cuando termines.';

  @override
  String get defaultSectionNotEditable => 'Sección por defecto (no editable)';

  @override
  String get allVideos => 'Todos los vídeos';

  @override
  String get defaultSection => '• Sección por defecto';

  @override
  String get editSection => 'Editar sección';

  @override
  String get newSection => 'Nueva Sección';

  @override
  String get mostRecent => 'Más recientes';

  @override
  String get mostPopular => 'Más populares';

  @override
  String get custom => 'Personalizada';

  @override
  String get recentVideosCannotBeReordered =>
      'La sección \"Vídeos Recientes\" no puede ser reordenada';

  @override
  String get deleteVideoSection => 'Eliminar Sección';

  @override
  String confirmDeleteSection(Object title) {
    return '¿Estás seguro de que quieres eliminar la sección \"$title\"?';
  }

  @override
  String get sectionDeleted => 'Sección eliminada';

  @override
  String get sendPushNotifications => 'Enviar Notificaciones Push';

  @override
  String errorVerifyingPermissionNotification(Object error) {
    return 'Error al verificar permiso: $error';
  }

  @override
  String get accessNotAuthorized => 'Acceso no autorizado';

  @override
  String get noPermissionSendNotifications =>
      'No tienes permiso para enviar notificaciones push.';

  @override
  String get sendNotification => 'Enviar notificación';

  @override
  String get title => 'Título';

  @override
  String get message => 'Mensaje:';

  @override
  String get pleaseEnterMessage => 'Por favor, introduce un mensaje';

  @override
  String get recipients => 'Destinatarios';

  @override
  String get allMembers => 'Todos los miembros';

  @override
  String get membersOfMinistry => 'Miembros de un ministerio';

  @override
  String get selectMinistry => 'Seleccionar ministerio';

  @override
  String get pleaseSelectMinistry => 'Por favor, selecciona un ministerio';

  @override
  String selectMembers(Object selected, Object total) {
    return 'Seleccionar miembros ($selected/$total)';
  }

  @override
  String get selectAll => 'Seleccionar Todos';

  @override
  String get deselectAll => 'Deseleccionar todos';

  @override
  String get membersOfGroup => 'Miembros de un grupo';

  @override
  String get selectGroup => 'Seleccionar grupo';

  @override
  String get pleaseSelectGroup => 'Por favor, selecciona un grupo';

  @override
  String get receiveThisNotificationToo => 'Recibir también esta notificación';

  @override
  String get sendNotificationButton => 'ENVIAR NOTIFICACIÓN';

  @override
  String get noPermissionSendNotificationsSnack =>
      'No tienes permiso para enviar notificaciones.';

  @override
  String get noUsersMatchCriteria =>
      'No hay usuarios que cumplan con los criterios seleccionados';

  @override
  String errorSending(Object error) {
    return 'Error al enviar: $error';
  }

  @override
  String get notificationSentSuccessfully => '✅ Notificación enviada con éxito';

  @override
  String get notificationSentPartially =>
      '⚠️ Notificación enviada parcialmente';

  @override
  String sentTo(Object count) {
    return 'Enviada a $count usuarios';
  }

  @override
  String failedTo(Object count) {
    return 'Falló para $count usuarios';
  }

  @override
  String get noPermissionDeleteMinistries =>
      'No tienes permiso para eliminar ministerios';

  @override
  String confirmDeleteMinistry(Object name) {
    return '¿Estás seguro de que quieres eliminar el ministerio \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String errorDeletingMinistry(Object error) {
    return 'Error al eliminar ministerio: $error';
  }

  @override
  String get noPermissionDeleteGroups =>
      'No tienes permiso para eliminar grupos';

  @override
  String confirmDeleteGroup(Object name) {
    return '¿Estás seguro de que quieres eliminar el grupo \"$name\"? Esta acción no se puede deshacer.';
  }

  @override
  String get kidsAdministration => 'Administración Kids';

  @override
  String get attendance => 'Asistencia';

  @override
  String get reload => 'Recargar';

  @override
  String get attendanceChart => 'Gráfico de Asistencia (pendiente)';

  @override
  String get weeklyBirthdays => 'Cumpleañeros de la Semana';

  @override
  String get birthdayCarousel => 'Carrusel de Cumpleañeros (pendiente)';

  @override
  String get family => 'Familia';

  @override
  String get visitor => 'Visitante';

  @override
  String get rooms => 'Salas';

  @override
  String get checkin => 'Check-in';

  @override
  String get absenceRegisteredSuccessfully => 'Ausencia registrada con éxito';

  @override
  String errorRegisteringAttendance(Object error) {
    return 'Error al registrar asistencia: $error';
  }

  @override
  String get searchParticipants => 'Buscar participantes';

  @override
  String get confirmed => 'Confirmados';

  @override
  String present(Object count) {
    return 'Presentes: $count';
  }

  @override
  String get absent => 'Ausentes';

  @override
  String get add => 'Añadir';

  @override
  String get noMembersFound => 'Ningún miembro encontrado';

  @override
  String get confirmedStatus => 'Confirmado';

  @override
  String get presentStatus => 'Presente';

  @override
  String get absentStatus => 'Ausente';

  @override
  String errorSearchingUsers(Object error) {
    return 'Error al buscar usuarios: $error';
  }

  @override
  String get participantAddedSuccessfully => 'Participante añadido con éxito';

  @override
  String errorAddingParticipant(Object error) {
    return 'Error al añadir participante: $error';
  }

  @override
  String get addParticipant => 'Añadir Participante';

  @override
  String get searchUserByName => 'Buscar usuario por nombre';

  @override
  String get typeAtLeastTwoCharacters =>
      'Escribe al menos 2 caracteres para buscar';

  @override
  String noResultsFound(Object query) {
    return 'Ningún resultado encontrado para \"$query\"';
  }

  @override
  String get tryAnotherName => 'Prueba con otro nombre o apellido';

  @override
  String get recentUsers => 'Usuarios recientes:';

  @override
  String get createNewCult => 'Crear Nuevo Culto';

  @override
  String get cultName => 'Nombre del Culto';

  @override
  String get startTime => 'Hora de inicio:';

  @override
  String get endTime => 'Hora de fin:';

  @override
  String get endTimeMustBeAfterStart =>
      'La hora de fin debe ser posterior a la hora de inicio';

  @override
  String get pleaseEnterCultName =>
      'Por favor, introduce un nombre para el culto';

  @override
  String get noPermissionCreateLocations =>
      'No tienes permiso para crear ubicaciones';

  @override
  String get noCultsFound => 'No se encontraron cultos';

  @override
  String get createFirstCult => 'Crear Primer Culto';

  @override
  String get location => 'Local:';

  @override
  String get selectLocation => 'Seleccionar ubicación';

  @override
  String get addNewLocation => 'Añadir nueva ubicación';

  @override
  String get locationName => 'Nombre de la ubicación';

  @override
  String get street => 'Calle';

  @override
  String get complement => 'Complemento';

  @override
  String get neighborhood => 'Barrio';

  @override
  String get city => 'Ciudad';

  @override
  String get state => 'Estado/Provincia';

  @override
  String get postalCode => 'Código Postal';

  @override
  String get country => 'País';

  @override
  String get saveThisLocation => 'Guardar esta ubicación para uso futuro';

  @override
  String get createCult => 'Crear Culto';

  @override
  String get noUpcomingCults => 'No hay cultos próximos';

  @override
  String get noAvailableCults => 'No hay cultos disponibles';

  @override
  String get nameCannotBeEmpty => 'El nombre no puede estar vacío';

  @override
  String documentsExistButCouldNotProcess(Object message) {
    return 'Existen documentos, pero no pudieron ser procesados. $message';
  }

  @override
  String get noPermissionCreateMinistries =>
      'Sin permiso para crear ministerios.';

  @override
  String get ministryCreatedSuccessfully => '¡Ministerio creado con éxito!';

  @override
  String errorCreatingMinistry(Object error) {
    return 'Error al crear ministerio: $error';
  }

  @override
  String get noPermissionCreateMinistriesLong =>
      'No tienes permiso para crear ministerios.';

  @override
  String get ministryName => 'Nombre del Ministerio';

  @override
  String get enterMinistryName => 'Introduce el nombre del ministerio';

  @override
  String get pleaseEnterMinistryName =>
      'Por favor, introduce un nombre para el ministerio';

  @override
  String get ministryDescription => 'Descripción';

  @override
  String get describeMinistryPurpose =>
      'Describe el propósito y actividades del ministerio';

  @override
  String get administrators => 'Administradores';

  @override
  String get selectAdministrators => 'Seleccionar Administradores';

  @override
  String get searchUsers => 'Buscar usuarios...';

  @override
  String get noUsersFound => 'No se encontraron usuarios';

  @override
  String get selectedAdministrators => 'Administradores seleccionados:';

  @override
  String get noAdministratorsSelected => 'Ningún administrador seleccionado';

  @override
  String get creating => 'Creando...';

  @override
  String charactersRemaining(Object count) {
    return '$count caracteres restantes';
  }

  @override
  String get understood => 'Entendido';

  @override
  String get cancelConsultation => 'Cancelar Consulta';

  @override
  String get sureToCancel =>
      '¿Estás seguro de que quieres cancelar esta consulta?';

  @override
  String get yesCancelConsultation => 'Sí, cancelar';

  @override
  String get consultationCancelledSuccessfully =>
      'Consulta cancelada con éxito';

  @override
  String get myAppointments => 'Mis Citas';

  @override
  String get requestAppointment => 'Solicitar Cita';

  @override
  String get pastorAvailability => 'Disponibilidad del Pastor';

  @override
  String get noAppointmentsScheduled => 'No hay citas programadas';

  @override
  String get scheduleFirstAppointment => 'Programa tu primera cita';

  @override
  String get scheduleAppointment => 'Programar Cita';

  @override
  String get cancelled => 'Canceladas';

  @override
  String get completed => 'Completados';

  @override
  String get withPreposition => 'con';

  @override
  String get requestedOn => 'Solicitada el';

  @override
  String get scheduledFor => 'Programada para';

  @override
  String reason(Object reason) {
    return 'Razón: $reason';
  }

  @override
  String get contactPastor => 'Contactar Pastor';

  @override
  String get cancelAppointment => 'Cancelar Consulta';

  @override
  String get noPermissionRespondPrivatePrayers =>
      'No tienes permiso para responder oraciones privadas';

  @override
  String get noPermissionCreatePredefinedMessages =>
      'No tienes permiso para crear mensajes predefinidos';

  @override
  String get noPermissionManagePrivatePrayers =>
      'No tienes permiso para gestionar oraciones privadas';

  @override
  String get prayerRequestAcceptedSuccessfully =>
      'Solicitud de oración aceptada con éxito';

  @override
  String get pendingPrayers => 'Oraciones Pendientes';

  @override
  String get acceptedPrayers => 'Oraciones Aceptadas';

  @override
  String get rejectedPrayers => 'Oraciones Rechazadas';

  @override
  String get noPendingPrayers => 'Ninguna oración pendiente';

  @override
  String get noAcceptedPrayers => 'No hay oraciones aceptadas';

  @override
  String get noRejectedPrayers => 'No hay oraciones rechazadas';

  @override
  String get requestedBy => 'Solicitada por';

  @override
  String get acceptPrayer => 'Aceptar Oración';

  @override
  String get rejectPrayer => 'Rechazar Oración';

  @override
  String get respondToPrayer => 'Responder a Oración';

  @override
  String get viewResponse => 'Ver Respuesta';

  @override
  String get predefinedMessages => 'Mensajes Predefinidos';

  @override
  String get createPredefinedMessage => 'Crear mensaje predefinido';

  @override
  String get prayerStats => 'Estadísticas de Oraciones';

  @override
  String get totalRequests => 'Total de Solicitudes';

  @override
  String get acceptedRequests => 'Solicitudes Aceptadas';

  @override
  String get rejectedRequests => 'Solicitudes Rechazadas';

  @override
  String get responseRate => 'Tasa de Respuesta';

  @override
  String get userInformation => 'Información de Usuarios';

  @override
  String get unauthorizedAccess => 'Acceso no autorizado';

  @override
  String get noPermissionViewUserInfo =>
      'No tienes permiso para ver información de usuarios.';

  @override
  String get totalUsers => 'Total de Usuarios';

  @override
  String get activeUsers => 'Usuarios Activos';

  @override
  String get inactiveUsers => 'Usuarios Inactivos';

  @override
  String get userDetails => 'Detalles del Usuario';

  @override
  String get viewDetails => 'Ver Detalles';

  @override
  String get lastActive => 'Última actividad';

  @override
  String get joinedOn => 'Se unió el';

  @override
  String role(Object role) {
    return 'Función: $role';
  }

  @override
  String get status => 'Estado';

  @override
  String get inactive => 'Inactivo';

  @override
  String get servicesStatistics => 'Estadísticas de Servicios';

  @override
  String get searchService => 'Buscar servicio...';

  @override
  String get users => 'Usuarios';

  @override
  String get totalInvitations => 'Total de Invitaciones';

  @override
  String get acceptedInvitations => 'Invitaciones Aceptadas';

  @override
  String get rejectedInvitations => 'Invitaciones Rechazadas';

  @override
  String get totalAttendances => 'Total de asistencias';

  @override
  String get totalAbsences => 'Total de ausencias';

  @override
  String get acceptanceRate => 'Tasa de Aceptación';

  @override
  String get attendanceRate => 'Tasa de Asistencia';

  @override
  String get sortBy => 'Ordenar por:';

  @override
  String get invitations => 'Invitaciones';

  @override
  String get acceptances => 'Aceptaciones';

  @override
  String get attendances => 'Asistencias';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Descendente';

  @override
  String get dateFilter => 'Filtro de Fecha';

  @override
  String get startDate => 'Fecha de Inicio';

  @override
  String get endDate => 'Fecha de Fin';

  @override
  String get applyFilter => 'Aplicar Filtro';

  @override
  String get clearFilter => 'Limpiar filtro';

  @override
  String get noServicesFound => 'No se encontraron escalas';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get myCounseling => 'Mis Consultas';

  @override
  String get cancelCounseling => 'Cancelar Consulta';

  @override
  String get confirmCancelCounseling =>
      '¿Estás seguro de que quieres cancelar esta consulta?';

  @override
  String get yesCancelCounseling => 'Sí, cancelar';

  @override
  String get counselingCancelledSuccess => 'Consulta cancelada con éxito';

  @override
  String get loadingPastorInfo => 'Cargando información del pastor...';

  @override
  String get unknownPastor => 'Pastor desconocido';

  @override
  String get pastor => 'Pastor';

  @override
  String get type => 'Tipo';

  @override
  String get contact => 'Contacto';

  @override
  String get couldNotOpenPhone => 'No se pudo abrir el teléfono';

  @override
  String get call => 'Llamar';

  @override
  String get couldNotOpenWhatsApp => 'No se pudo abrir WhatsApp';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get address => 'Dirección';

  @override
  String get notConnected => 'No estás conectado';

  @override
  String get noUpcomingAppointments => 'No tienes consultas programadas';

  @override
  String get noCancelledAppointments => 'No tienes consultas canceladas';

  @override
  String get noCompletedAppointments => 'No hay citas completadas';

  @override
  String get noAppointmentsAvailable => 'No hay consultas disponibles';

  @override
  String get viewRequests => 'Ver Solicitudes';

  @override
  String get editCourse => 'Editar Curso';

  @override
  String get fillCourseInfo =>
      'Completa la información del curso para ponerlo a disposición de los estudiantes';

  @override
  String get courseTitle => 'Título del Curso';

  @override
  String get courseTitleHint => 'Ej: Fundamentos de la Biblia';

  @override
  String get titleRequired => 'El título es obligatorio';

  @override
  String get descriptionHint =>
      'Describe el contenido y objetivos del curso...';

  @override
  String get descriptionRequired => 'La descripción es obligatoria';

  @override
  String get coverImage => 'Imagen de Portada';

  @override
  String get coverImageDescription =>
      'Esta imagen se mostrará en la página de detalles del curso';

  @override
  String get tapToChange => 'Toca para cambiar';

  @override
  String get recommendedSize => 'Recomendado: 16:9 (1920x1080px)';

  @override
  String get categoryHint => 'Ej: Teología, Discipulado, Liderazgo';

  @override
  String get categoryRequired => 'La categoría es obligatoria';

  @override
  String get instructorName => 'Nombre del Instructor';

  @override
  String get instructorNameHint => 'Nombre completo del instructor';

  @override
  String get instructorRequired => 'El nombre del instructor es obligatorio';

  @override
  String get courseStatus => 'Estado del Curso';

  @override
  String get allowComments => 'Permitir Comentarios';

  @override
  String get studentsCanComment =>
      'Los estudiantes podrán comentar en las lecciones';

  @override
  String get updateCourse => 'Actualizar Curso';

  @override
  String get createCourse => 'Crear Curso';

  @override
  String get courseDurationNote =>
      'La duración total del curso se calcula automáticamente basándose en la duración de las lecciones.';

  @override
  String get manageModulesAndLessons => 'Gestionar Módulos y Lecciones';

  @override
  String get courseUpdatedSuccess => '¡Curso actualizado con éxito!';

  @override
  String get courseCreatedSuccess => '¡Curso creado con éxito!';

  @override
  String get addModules => 'Añadir Módulos';

  @override
  String get addModulesNow => '¿Quieres añadir módulos al curso ahora?';

  @override
  String get later => 'Más tarde';

  @override
  String get yesAddNow => 'Sí, añadir ahora';

  @override
  String get uploadingImages => 'Subiendo imágenes...';

  @override
  String get savingCourse => 'Guardando curso...';

  @override
  String get addModule => 'Añadir Módulo';

  @override
  String moduleTitle(Object title) {
    return 'Módulo: $title';
  }

  @override
  String get moduleTitleHint => 'Nombre del módulo';

  @override
  String get moduleTitleRequired => 'El título del módulo es obligatorio';

  @override
  String get summary => 'Resumen';

  @override
  String get summaryOptional => 'Resumen (Opcional)';

  @override
  String get summaryHint => 'Breve descripción del módulo...';

  @override
  String get moduleCreatedSuccess => '¡Módulo creado con éxito!';

  @override
  String get addLesson => 'Añadir Lección';

  @override
  String get lessonTitle => 'Título de la Lección';

  @override
  String get lessonTitleHint => 'Nombre de la lección';

  @override
  String get lessonTitleRequired => 'El título de la lección es obligatorio';

  @override
  String get lessonDescription => 'Descripción de la Lección';

  @override
  String get lessonDescriptionHint =>
      'Describe el contenido de esta lección...';

  @override
  String get lessonDescriptionRequired =>
      'La descripción de la lección es obligatoria';

  @override
  String get durationHint => 'Duración en minutos';

  @override
  String get durationRequired => 'La duración es obligatoria';

  @override
  String get durationMustBeNumber => 'La duración debe ser un número válido';

  @override
  String get videoUrl => 'URL del Vídeo (YouTube o Vimeo)';

  @override
  String get videoUrlHint => 'URL de YouTube o Vimeo';

  @override
  String get videoUrlRequired => 'La URL del vídeo es obligatoria';

  @override
  String get lessonCreatedSuccess => '¡Lección creada con éxito!';

  @override
  String get noModulesYet => 'Aún no hay módulos en este curso.';

  @override
  String get tapAddToCreateFirst =>
      'Toca \'Añadir Módulo\' para crear el primero.';

  @override
  String get noLessonsInModule => 'No hay lecciones en este módulo aún.';

  @override
  String get tapToAddLesson => 'Toca + para añadir una lección.';

  @override
  String get min => 'min';

  @override
  String get video => 'Vídeo';

  @override
  String get manageMaterials => 'Gestionar Materiales';

  @override
  String get deleteModule => 'Eliminar Módulo';

  @override
  String get confirmDeleteModule =>
      '¿Estás seguro de que quieres eliminar este módulo?';

  @override
  String get thisActionCannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get yesDelete => 'Sí, eliminar';

  @override
  String get moduleDeletedSuccess => 'Módulo eliminado con éxito';

  @override
  String get deleteLesson => 'Eliminar Lección';

  @override
  String get confirmDeleteLesson =>
      '¿Estás seguro de que quieres eliminar esta lección?';

  @override
  String get lessonDeletedSuccess => 'Lección eliminada con éxito';

  @override
  String get reorderModules => 'Reordenar Módulos';

  @override
  String get reorderLessons => 'Reordenar Lecciones';

  @override
  String get done => 'Listo';

  @override
  String get dragToReorder => 'Arrastra para reordenar';

  @override
  String get orderUpdatedSuccess => '¡Orden actualizado con éxito!';

  @override
  String get loadingCourse => 'Cargando curso...';

  @override
  String get savingModule => 'Guardando módulo...';

  @override
  String get savingLesson => 'Guardando lección...';

  @override
  String errorLoadingFields(Object error) {
    return 'Error al cargar los campos: $error';
  }

  @override
  String get required => 'Obligatorio';

  @override
  String get fieldName => 'Nombre del Campo';

  @override
  String get pleaseEnterName => 'Por favor, introduce un nombre';

  @override
  String get selectFieldType => 'Selección';

  @override
  String get newOption => 'Nueva Opción';

  @override
  String get enterOption => 'Introduce una opción...';

  @override
  String get optionAlreadyAdded => 'Esta opción ya fue añadida.';

  @override
  String get noOptionsAddedYet => 'Ninguna opción añadida aún.';

  @override
  String get usersMustFillField => 'Los usuarios deben rellenar este campo';

  @override
  String get copyToPreviousWeek => 'Copiar a la semana anterior';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get unavailable => 'No disponible';

  @override
  String get available => 'Disponible';

  @override
  String get sessionDuration => 'Duración de la Sesión';

  @override
  String get breakBetweenSessions => 'Descanso entre Sesiones';

  @override
  String get appointmentTypes => 'Tipos de Cita';

  @override
  String get onlineAppointments => 'Citas en Línea';

  @override
  String get inPersonAppointments => 'Citas Presenciales';

  @override
  String get locationHint => 'Dirección para citas presenciales';

  @override
  String get globalSettings => 'Configuración Global';

  @override
  String get settingsSavedSuccessfully => 'Configuración guardada con éxito';

  @override
  String get notAvailableForConsultations => 'No disponible para consultas';

  @override
  String get configureAvailabilityForThisDay =>
      'Configura la disponibilidad para este día';

  @override
  String get thisDayMarkedUnavailable =>
      'Este día está marcado como no disponible para consultas';

  @override
  String get unavailableDay => 'No disponible';

  @override
  String get thisDayMarkedAvailable =>
      'Este día está marcado como disponible para consultas';

  @override
  String get timeSlotsSingular => 'Franjas Horarias';

  @override
  String timeSlot(Object number) {
    return 'Franja $number';
  }

  @override
  String get consultationType => 'Tipo de consulta:';

  @override
  String get onlineConsultation => 'En línea';

  @override
  String get inPersonConsultation => 'Presencial';

  @override
  String get addTimeSlot => 'Añadir Franja Horaria';

  @override
  String get searchUser => 'Buscar usuario...';

  @override
  String get enterNameOrEmail => 'Introduce nombre o email';

  @override
  String get noPermissionAccessThisPage =>
      'No tienes permiso para acceder a esta página';

  @override
  String get noPermissionChangeRoles => 'No tienes permiso para cambiar roles';

  @override
  String get selectRoleToAssign => 'Selecciona el rol para asignar al usuario:';

  @override
  String permissionsAssigned(Object count) {
    return '$count permisos asignados';
  }

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get deleteRole => 'Eliminar rol';

  @override
  String get createNewRole => 'Crear Nuevo Rol';

  @override
  String get failedDeleteRole => 'Error al eliminar rol';

  @override
  String get editModule => 'Editar Módulo';

  @override
  String get moduleUpdatedSuccessfully => 'Módulo actualizado con éxito';

  @override
  String sureDeleteModule(Object title) {
    return '¿Estás seguro de que quieres eliminar el módulo \"$title\"?\n\nEsta acción no se puede deshacer y eliminará todas las lecciones asociadas.';
  }

  @override
  String get moduleDeletedSuccessfully => 'Módulo eliminado con éxito';

  @override
  String get moduleNotFound => 'Módulo no encontrado';

  @override
  String get lessonAddedSuccessfully => 'Lección añadida con éxito';

  @override
  String get optionalDescription => 'Descripción (Opcional)';

  @override
  String get durationMinutes => 'Duración (minutos)';

  @override
  String get videoUrlExample => 'Ej: https://www.youtube.com/watch?v=...';

  @override
  String get manageModules => 'Gestionar Módulos';

  @override
  String get finishReorder => 'Finalizar';

  @override
  String orderLessons(Object count, Object order) {
    return 'Orden: $order • $count lecciones';
  }

  @override
  String get editLesson => 'Editar Lección';

  @override
  String get lessonUpdatedSuccessfully => 'Lección actualizada con éxito';

  @override
  String sureDeleteLesson(Object title) {
    return '¿Estás seguro de que quieres eliminar la lección \"$title\"?\n\nEsta acción no se puede deshacer.';
  }

  @override
  String get lessonDeletedSuccessfully => 'Lección eliminada con éxito';

  @override
  String get moduleOrderUpdated => 'Orden de los módulos actualizado';

  @override
  String get lessonOrderUpdated => 'Orden de las lecciones actualizado';

  @override
  String durationVideo(Object duration) {
    return '$duration • Vídeo';
  }

  @override
  String durationVideoMaterials(Object count, Object duration) {
    return '$duration • Vídeo • Materiales: $count';
  }

  @override
  String get guardar => 'Guardar';

  @override
  String sureDeleteModuleWithTitle(Object title) {
    return '¿Estás seguro de que quieres eliminar el módulo \"$title\"?\n\nEsta acción no se puede deshacer y eliminará todas las lecciones asociadas.';
  }

  @override
  String sureDeleteLessonWithTitle(Object title) {
    return '¿Estás seguro de que quieres eliminar la lección \"$title\"?\n\nEsta acción no se puede deshacer.';
  }

  @override
  String get moduleTitleLabel => 'Título del Módulo';

  @override
  String get createNewProfile => 'Crear Nuevo Perfil';

  @override
  String get roleName => 'Nombre del Rol';

  @override
  String get roleNameHint => 'Ej: Líder de Grupo, Editor';

  @override
  String get roleNameRequired => 'El nombre del rol es obligatorio.';

  @override
  String get optionalDescriptionRole => 'Descripción (Opcional)';

  @override
  String get roleDescriptionHint => 'Responsabilidades de este rol...';

  @override
  String get permissions => 'Permisos';

  @override
  String get saving => 'Guardando...';

  @override
  String get createRole => 'Crear Rol';

  @override
  String get roleSavedSuccessfully => 'Rol guardado con éxito!';

  @override
  String get errorSavingRole => 'Error al guardar rol.';

  @override
  String get generalAdministration => 'Administración General';

  @override
  String get homeConfiguration => 'Configuración Home';

  @override
  String get contentAndEvents => 'Contenido y Eventos';

  @override
  String get community => 'Comunidad';

  @override
  String get counselingAndPrayer => 'Asesoramiento y Oración';

  @override
  String get reportsAndStatistics => 'Informes y Estadísticas';

  @override
  String get myKids => 'MyKids (Gestión Infantil)';

  @override
  String get others => 'Otros';

  @override
  String get assignUserRoles => 'Asignar Roles a Usuarios';

  @override
  String get manageUsers => 'Gestionar Usuarios';

  @override
  String get viewUserList => 'Ver Lista de Usuarios';

  @override
  String get viewUserDetails => 'Ver Detalles de Usuarios';

  @override
  String get manageHomeSections => 'Gestionar Secciones de la Tela Inicial';

  @override
  String get manageCults => 'Gestionar Cultos';

  @override
  String get manageEventTickets => 'Gestionar Entradas de Eventos';

  @override
  String get createEvents => 'Crear Eventos';

  @override
  String get deleteEvents => 'Eliminar Eventos';

  @override
  String get manageCourses => 'Gestionar Cursos';

  @override
  String get createGroup => 'Crear Grupo';

  @override
  String get manageCounselingAvailability =>
      'Gestionar Disponibilidad para Asesoramiento';

  @override
  String get manageCounselingRequests =>
      'Gestionar Solicitudes de Asesoramiento';

  @override
  String get managePrivatePrayers => 'Gestionar Oraciones Privadas';

  @override
  String get assignCultToPrayer => 'Asignar Culto a la Oración';

  @override
  String get viewMinistryStats => 'Ver Estadísticas de Ministerios';

  @override
  String get viewGroupStats => 'Ver Estadísticas de Grupos';

  @override
  String get viewScheduleStats => 'Ver Estadísticas de Escalas';

  @override
  String get viewCourseStats => 'Ver Estadísticas de Cursos';

  @override
  String get viewChurchStatistics => 'Ver Estadísticas de la Iglesia';

  @override
  String get viewCultStats => 'Ver Estadísticas de Cultos';

  @override
  String get viewWorkStats => 'Ver Estadísticas de Trabajo';

  @override
  String get manageCheckinRooms => 'Gestionar Salas y Check-in';

  @override
  String get manageDonationsConfig => 'Configurar Donaciones';

  @override
  String get manageLivestreamConfig => 'Configurar Transmisiones en Vivo';

  @override
  String lessonsCount(Object count) {
    return '$count lecciones';
  }

  @override
  String get averageProgress => 'Progreso Medio:';

  @override
  String get averageLessonsCompleted => 'Lecciones Medias Completadas:';

  @override
  String get globalAverageProgress => 'Progreso Medio Global:';

  @override
  String get highestProgress => 'Mayor Progreso:';

  @override
  String get progressPercentage => 'Progreso (%)';

  @override
  String get averageLessons => 'Lecciones Medias';

  @override
  String get totalLessonsHeader => 'Total Lecciones';

  @override
  String get allModuleLessonsWillBeDeleted =>
      'Todas las lecciones de este módulo también serán eliminadas. Esta acción no se puede deshacer.';

  @override
  String get groupName => 'Nombre del Grupo';

  @override
  String get enterGroupName => 'Introduce el nombre del grupo';

  @override
  String get pleaseEnterGroupName => 'Por favor, introduce un nombre';

  @override
  String get groupDescription => 'Descripción';

  @override
  String get enterGroupDescription => 'Introduce la descripción del grupo';

  @override
  String get administratorsCanManage =>
      'Los administradores pueden gestionar el grupo, sus miembros y eventos.';

  @override
  String get addAdministrators => 'Añadir administradores';

  @override
  String administratorsSelected(Object count) {
    return '$count administradores seleccionados';
  }

  @override
  String get unknownUser => 'Usuario desconocido';

  @override
  String get autoMemberInfo =>
      'Al crear un grupo, serás automáticamente miembro y administrador. Podrás personalizar la imagen y otras configuraciones después de la creación.';

  @override
  String get groupCreatedSuccessfully => 'Grupo creado con éxito!';

  @override
  String errorCreatingGroup(Object error) {
    return 'Error al crear grupo: $error';
  }

  @override
  String get noPermissionCreateGroups => 'Sin permiso para crear grupos.';

  @override
  String get noPermissionCreateGroupsLong =>
      'No tienes permiso para crear grupos.';

  @override
  String get noUsersAvailable => 'Ningún usuario disponible';

  @override
  String get enterMinistryDescription =>
      'Introduce la descripción del ministerio';

  @override
  String get pleaseEnterMinistryDescription =>
      'Por favor, introduce una descripción';

  @override
  String get administratorsCanManageMinistry =>
      'Los administradores pueden gestionar el ministerio, sus miembros y eventos.';

  @override
  String get autoMemberMinistryInfo =>
      'Al crear un ministerio, serás automáticamente miembro y administrador. Podrás personalizar la imagen y otras configuraciones después de la creación.';

  @override
  String get textFieldType => 'Texto';

  @override
  String get numberFieldType => 'Número';

  @override
  String get dateFieldType => 'Fecha';

  @override
  String get emailFieldType => 'Email';

  @override
  String get phoneFieldType => 'Teléfono';

  @override
  String get selectionOptions => 'Opciones de Selección';

  @override
  String get noResultsFoundSimple => 'No se encontraron resultados';

  @override
  String get progress => 'Progreso';

  @override
  String get detailedStatistics => 'Estadísticas Detalladas';

  @override
  String get enrollments => 'Inscripciones';

  @override
  String get completion => 'Finalización';

  @override
  String get completionMilestones => 'Hitos de Conclusión';

  @override
  String get filterByEnrollmentDate => 'Filtrar por Fecha de Inscripción';

  @override
  String get clear => 'Limpiar';

  @override
  String get lessThan1Min => 'Menos de 1 min';

  @override
  String get totalEnrolledPeriod => 'Total de Inscritos (período):';

  @override
  String get reached25Percent => 'Alcanzaron 25%:';

  @override
  String get reached50Percent => 'Alcanzaron 50%:';

  @override
  String get reached75Percent => 'Alcanzaron 75%:';

  @override
  String get reached90Percent => 'Alcanzaron 90%:';

  @override
  String get completed100Percent => 'Completaron 100%:';

  @override
  String get counselingRequestsTitle => 'Solicitudes de Asesoramiento';

  @override
  String get noPermissionManageCounselingRequests =>
      'No tienes permiso para gestionar solicitudes de asesoramiento';

  @override
  String get appointmentConfirmed => 'Cita confirmada';

  @override
  String get appointmentCancelled => 'Cita cancelada';

  @override
  String get appointmentCompleted => 'Cita completada';

  @override
  String get errorLabel => 'Error:';

  @override
  String get noPendingRequests => 'No hay solicitudes pendientes';

  @override
  String get noConfirmedAppointments => 'No hay citas confirmadas';

  @override
  String get loadingUser => 'Cargando usuario...';

  @override
  String get callTooltip => 'Llamar';

  @override
  String get whatsAppTooltip => 'WhatsApp';

  @override
  String get reasonLabel => 'Motivo:';

  @override
  String get noReasonSpecified => 'Ningún motivo especificado';

  @override
  String get complete => 'Completar';

  @override
  String appointmentStatus(Object status) {
    return 'Cita $status';
  }

  @override
  String get myPrivatePrayers => 'Mis Oraciones Privadas';

  @override
  String get refresh => 'Actualizar';

  @override
  String get noApprovedPrayers => 'Ninguna oración aprobada';

  @override
  String get noAnsweredPrayers => 'Ninguna oración respondida';

  @override
  String get noPrayers => 'Ninguna oración';

  @override
  String get allPrayerRequestsAttended =>
      'Todas sus solicitudes de oración han sido atendidas';

  @override
  String get noApprovedPrayersWithoutResponse =>
      'Ninguna oración fue aprobada sin respuesta';

  @override
  String get noResponsesFromPastors =>
      'Aún no ha recibido respuestas de los pastores';

  @override
  String get requestPrivatePrayerFromPastors =>
      'Solicite oración privada a los pastores';

  @override
  String get approved => 'Aprobadas';

  @override
  String get answered => 'Respondidas';

  @override
  String get requestPrayer => 'Pedir oración';

  @override
  String errorLoading(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String loadingError(Object error, Object tabIndex) {
    return 'Error cargando más oraciones para tab $tabIndex: $error';
  }

  @override
  String get privatePrayersTitle => 'Oraciones Privadas';

  @override
  String get errorAcceptingRequest => 'Error al aceptar la solicitud';

  @override
  String errorAcceptingRequestWithDetails(Object error) {
    return 'Error al aceptar la solicitud: $error';
  }

  @override
  String get loadingEllipsis => 'Cargando...';

  @override
  String get responded => 'Respondido';

  @override
  String get requestLabel => 'Solicitud:';

  @override
  String get yourResponse => 'Su respuesta:';

  @override
  String respondedOn(Object date) {
    return 'Respondido el $date';
  }

  @override
  String get acceptAction => 'Aceptar';

  @override
  String get respondAction => 'Responder';

  @override
  String get total => 'Total';

  @override
  String get prayersOverview => 'Visión General de las Oraciones';

  @override
  String get noPendingPrayersMessage => 'No hay oraciones pendientes';

  @override
  String get allRequestsAttended => 'Todas las solicitudes han sido atendidas';

  @override
  String get noApprovedPrayersWithoutResponseMessage =>
      'No hay oraciones aprobadas sin respuesta';

  @override
  String get acceptRequestsToRespond =>
      'Acepte solicitudes para responder a los hermanos';

  @override
  String get noAnsweredPrayersMessage => 'No ha respondido a ninguna oración';

  @override
  String get responsesWillAppearHere => 'Sus respuestas aparecerán aquí';

  @override
  String get groupStatisticsTitle => 'Estadísticas de Grupos';

  @override
  String get members => 'Miembros';

  @override
  String get history => 'Historial';

  @override
  String get noPermissionViewGroupStats =>
      'No tienes permiso para visualizar estadísticas de grupos';

  @override
  String get filterByDate => 'Filtrar por fecha';

  @override
  String get initialDate => 'Fecha inicial';

  @override
  String get finalDate => 'Fecha final';

  @override
  String get totalUniqueMembers => 'Total de Miembros Únicos';

  @override
  String get creationDate => 'Fecha de creación';

  @override
  String memberCount(Object count) {
    return '$count miembros';
  }

  @override
  String errorLoadingMembers(Object error) {
    return 'Error al cargar miembros: $error';
  }

  @override
  String get noMembersInGroup => 'No hay miembros en este grupo';

  @override
  String get attendancePercentage => '% Asistencia';

  @override
  String get eventsLabel => 'Eventos';

  @override
  String get admin => 'Admin';

  @override
  String get eventsAttended => 'Eventos Asistidos';

  @override
  String get ministryStatisticsTitle => 'Estadísticas de Ministerios';

  @override
  String get noPermissionViewMinistryStats =>
      'No tienes permiso para visualizar estadísticas de ministerios';

  @override
  String get noMembersInMinistry => 'No hay miembros en este ministerio';

  @override
  String get noHistoryToShow => 'No hay historial de miembros para mostrar';

  @override
  String recordsFound(Object count) {
    return 'Registros encontrados: $count';
  }

  @override
  String get exits => 'Salidas';

  @override
  String get noHistoricalRecords =>
      'No hay registros históricos para este grupo';

  @override
  String noRecordsOf(Object filterName) {
    return 'No hay registros de $filterName';
  }

  @override
  String get currentMembers => 'Miembros actuales';

  @override
  String get totalEntries => 'Total de entradas';

  @override
  String get totalExits => 'Total de salidas';

  @override
  String entriesIn(Object groupName) {
    return 'Entradas en $groupName';
  }

  @override
  String get addedByAdmin => 'Añadidos por admin';

  @override
  String get byRequest => 'Por solicitud';

  @override
  String get close => 'Cerrar';

  @override
  String exitsFrom(Object groupName) {
    return 'Salidas de $groupName';
  }

  @override
  String get removedByAdmin => 'Removidos por admin';

  @override
  String get voluntaryExits => 'Salidas voluntarias';

  @override
  String get exitedStatus => 'Salió';

  @override
  String get unknownStatus => 'Desconocido';

  @override
  String get unknownDate => 'Fecha desconocida';

  @override
  String get addedBy => 'Añadido por:';

  @override
  String get administrator => 'Administrador';

  @override
  String get mode => 'Modo:';

  @override
  String get requestAccepted => 'Solicitud aceptada';

  @override
  String get acceptedBy => 'Aceptado por:';

  @override
  String get rejectedBy => 'Rechazado por:';

  @override
  String get exitType => 'Tipo de salida:';

  @override
  String get voluntary => 'Voluntaria';

  @override
  String get removed => 'Removido';

  @override
  String get removedBy => 'Removido por:';

  @override
  String get exitReason => 'Motivo de salida:';

  @override
  String get noEventsToShow => 'No hay eventos para mostrar';

  @override
  String eventsFound(Object count) {
    return 'Eventos encontrados: $count';
  }

  @override
  String get unknownMinistry => 'Ministerio desconocido';

  @override
  String eventsInPeriod(Object count) {
    return '$count eventos en el período';
  }

  @override
  String event(Object eventName) {
    return 'Evento: $eventName';
  }

  @override
  String get locationNotInformed => 'Local no informado';

  @override
  String registered(Object count) {
    return 'Registrados: $count';
  }

  @override
  String eventsCount(Object count) {
    return '$count eventos';
  }

  @override
  String eventsOf(Object groupName) {
    return 'Eventos de $groupName';
  }

  @override
  String get time => 'Hora:';

  @override
  String registeredCount(Object count) {
    return 'Registrados: $count';
  }

  @override
  String attendeesCount(Object count) {
    return 'Asistentes: $count';
  }

  @override
  String noEventsFor(Object ministry) {
    return 'No hay eventos para $ministry';
  }

  @override
  String get loadingUsers => 'Cargando usuarios...';

  @override
  String get registeredUsers => 'Usuarios Registrados';

  @override
  String get confirmedAttendees => 'Asistentes Confirmados';

  @override
  String get noUsersToShow => 'No hay usuarios para mostrar';

  @override
  String get noRecordsInSelectedDates =>
      'No hay registros en las fechas seleccionadas';

  @override
  String get noEventsInSelectedDates =>
      'No hay eventos en las fechas seleccionadas';

  @override
  String recordsInPeriod(Object count) {
    return '$count registros en el período';
  }

  @override
  String get scaleStatisticsTitle => 'Estadísticas de Escalas';

  @override
  String get noPermissionViewScaleStats =>
      'No tienes permiso para visualizar estadísticas de escalas.';

  @override
  String get search => 'Buscar';

  @override
  String get viewCults => 'Ver cultos';

  @override
  String cultsOf(Object serviceName) {
    return 'Cultos de $serviceName';
  }

  @override
  String get noCultsAvailableForService =>
      'Ningún culto disponible para esta escala';

  @override
  String get courseStatisticsTitle => 'Estadísticas de Cursos';

  @override
  String get noPermissionViewCourseStats =>
      'No tienes permiso para visualizar estadísticas de cursos.';

  @override
  String get noStatisticsAvailable => 'No hay estadísticas disponibles.';

  @override
  String errorLoadingStatistics(Object error) {
    return 'Error al cargar estadísticas: $error';
  }

  @override
  String get top3CoursesEnrolled => 'Top 3 Cursos (Inscritos):';

  @override
  String get noCourseToShow => 'Ningún curso para mostrar.';

  @override
  String get detailsScreenNotImplemented =>
      'Pantalla de detalles aún no implementada.';

  @override
  String get enrollmentStatisticsTitle => 'Estadísticas de Inscripciones';

  @override
  String get progressStatisticsTitle => 'Estadísticas de Progreso';

  @override
  String get completionStatisticsTitle => 'Estadísticas de Finalización';

  @override
  String get milestoneStatisticsTitle => 'Estadísticas de Hitos';

  @override
  String get searchCourses => 'Buscar cursos...';

  @override
  String get totalEnrollments => 'Total de Inscripciones';

  @override
  String get averageEnrollmentsPerCourse =>
      'Promedio de Inscripciones por Curso';

  @override
  String get courseWithMostEnrollments => 'Curso con Más Inscripciones';

  @override
  String get courseWithFewestEnrollments => 'Curso con Menos Inscripciones';

  @override
  String get enrollmentsOverTime => 'Inscripciones a lo Largo del Tiempo';

  @override
  String get enrollmentDate => 'Fecha de Inscripción';

  @override
  String get globalAverageTime => 'Tiempo Medio Global:';

  @override
  String get fastestCompletion => 'Finalización Más Rápida:';

  @override
  String get slowestCompletion => 'Finalización Más Lenta:';

  @override
  String get completionTime => 'Tiempo de Finalización';

  @override
  String get completionRate => 'Tasa de Finalización';

  @override
  String get reach25Percent => 'Alcanzan 25%:';

  @override
  String get reach50Percent => 'Alcanzan 50%:';

  @override
  String get reach75Percent => 'Alcanzan 75%:';

  @override
  String get reach90Percent => 'Alcanzan 90%:';

  @override
  String get complete100Percent => 'Completan 100%:';

  @override
  String get milestonePercentage => 'Porcentaje de Hito';

  @override
  String get studentsReached => 'Estudiantes que Alcanzaron';

  @override
  String get userNotFound => 'Usuario no encontrado';

  @override
  String get servicesPerformed => 'Servicios Realizados';

  @override
  String get noConfirmedServicesInMinistry =>
      'No realizó servicios confirmados en este ministerio';

  @override
  String service(Object serviceName) {
    return 'Servicio: $serviceName';
  }

  @override
  String assignedBy(Object pastorName) {
    return 'Designado por: $pastorName';
  }

  @override
  String get notAttendedMinistryEvents =>
      'No asistió a eventos de este ministerio';

  @override
  String get notAttendedGroupEvents => 'No asistió a eventos de este grupo';

  @override
  String get churchStatisticsTitle => 'Estadísticas de la Iglesia';

  @override
  String get dataNotAvailable => 'Datos no disponibles';

  @override
  String get requestApproved => 'Solicitud aprobada';

  @override
  String attendees(Object count) {
    return 'Asistentes: $count';
  }

  @override
  String get userNotInAnyGroup => 'El usuario no pertenece a ningún grupo';

  @override
  String get generalStatistics => 'Estadísticas Generales';

  @override
  String get totalServicesPerformed => 'Total de servicios realizados';

  @override
  String get ministryEventsAttended => 'Eventos de ministerio asistidos';

  @override
  String get groupEventsAttended => 'Eventos de grupo asistidos';

  @override
  String get userNotInAnyMinistry =>
      'El usuario no pertenece a ningún ministerio';

  @override
  String get statusConfirmed => 'Estado: Confirmado';

  @override
  String get statusPresent => 'Estado: Presente';

  @override
  String get notAvailable => 'N/D';

  @override
  String get allMinistries => 'Todos los Ministerios';

  @override
  String get serviceWithoutName => 'Servicio sin nombre';

  @override
  String errorLoadingUserStats(Object error) {
    return 'Error al cargar estadísticas de usuarios: $error';
  }

  @override
  String errorLoadingStats(Object error) {
    return 'Error al cargar estadísticas: $error';
  }

  @override
  String get serviceName => 'Nombre del servicio';

  @override
  String get serviceNameHint => 'Ej: Culto Dominical';

  @override
  String get scales => 'Escalas';

  @override
  String get noServiceFound => 'Ningún servicio encontrado';

  @override
  String get tryAnotherFilter => 'Intenta con otro filtro de búsqueda';

  @override
  String created(Object date) {
    return 'Creado: $date';
  }

  @override
  String get invitesSent => 'Invitaciones enviadas';

  @override
  String get globalSummary => 'Resumen Global';

  @override
  String get absences => 'Ausencias';

  @override
  String get invites => 'Invitaciones';

  @override
  String get invitesAccepted => 'Invitaciones aceptadas';

  @override
  String get invitesRejected => 'Invitaciones rechazadas';

  @override
  String get finished => 'Finalizado';

  @override
  String errorLoadingCults(Object error) {
    return 'Error al cargar cultos: $error';
  }

  @override
  String cultsCount(Object count) {
    return '$count cultos';
  }

  @override
  String get userList => 'Lista de usuarios';
}
