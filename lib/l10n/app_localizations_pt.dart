// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get myProfile => 'Meu Perfil';

  @override
  String get deleteAccount => 'Eliminar Conta';

  @override
  String get completeYourProfile => 'Complete seu perfil';

  @override
  String get personalInformation => 'Informação Pessoal';

  @override
  String get save => 'Salvar';

  @override
  String get name => 'Nome';

  @override
  String get pleaseEnterYourName => 'Por favor, digite seu nome';

  @override
  String get surname => 'Sobrenome';

  @override
  String get pleaseEnterYourSurname => 'Por favor, digite seu sobrenome';

  @override
  String get birthDate => 'Nascimento';

  @override
  String get selectDate => 'Selecionar data';

  @override
  String get gender => 'Sexo';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Feminino';

  @override
  String get preferNotToSay => 'Prefiro não dizer';

  @override
  String get phone => 'Telefone';

  @override
  String get optional => 'Opcional';

  @override
  String get invalidPhone => 'Telefone inválido';

  @override
  String currentNumber(String number) {
    return 'Número atual: $number';
  }

  @override
  String get participation => 'Participação';

  @override
  String get ministries => 'Ministérios';

  @override
  String errorLoadingMinistries(Object error) {
    return 'Erro ao carregar ministérios: $error';
  }

  @override
  String get mySchedules => 'Minhas Escalas';

  @override
  String get manageAssignmentsAndInvitations =>
      'Gerenciar suas atribuições e convites de trabalho nos ministérios';

  @override
  String get joinAnotherMinistry => 'Juntar-se a outro Ministério';

  @override
  String get youDoNotBelongToAnyMinistry =>
      'Você não pertence a nenhum ministério';

  @override
  String get joinAMinistryToParticipate =>
      'Junte-se a um ministério para participar do serviço na igreja';

  @override
  String get joinAMinistry => 'Juntar-se a um Ministério';

  @override
  String get groups => 'Connect';

  @override
  String errorLoadingGroups(Object error) {
    return 'Erro ao carregar grupos: $error';
  }

  @override
  String get joinAnotherGroup => 'Juntar-se a outro Grupo';

  @override
  String get youDoNotBelongToAnyGroup => 'Você não pertence a nenhum grupo';

  @override
  String get joinAGroupToParticipate =>
      'Junte-se a um grupo para participar da vida comunitária';

  @override
  String get joinAGroup => 'Juntar-se a um Grupo';

  @override
  String get administration => 'Administração';

  @override
  String get manageDonations => 'Gerenciar Doações';

  @override
  String get configureDonationSection => 'Configure a seção e formas de doação';

  @override
  String get manageLiveStreams => 'Gerenciar Transmissões Ao Vivo';

  @override
  String get createEditControlStreams =>
      'Criar, editar e controlar transmissões';

  @override
  String get manageOnlineCourses => 'Gerenciar Cursos Online';

  @override
  String get createEditConfigureCourses => 'Criar, editar e configurar cursos';

  @override
  String get manageHomeScreen => 'Gerenciar Tela Inicial';

  @override
  String get managePages => 'Gerenciar Páginas';

  @override
  String get createEditInfoContent => 'Criar e editar conteúdo informativo';

  @override
  String get manageAvailability => 'Gerenciar Disponibilidade';

  @override
  String get configureCounselingHours =>
      'Configure seus horários para aconselhamento';

  @override
  String get manageProfileFields => 'Gerenciar Campos de Perfil';

  @override
  String get configureAdditionalUserFields =>
      'Configure os campos adicionais para os usuários';

  @override
  String get manageRoles => 'Gerenciar Papéis';

  @override
  String get assignPastorRoles =>
      'Atribua perfiles de pastor a outros usuários';

  @override
  String get createEditRoles => 'Criar/editar Perfiles';

  @override
  String get createEditRolesAndPermissions =>
      'Criar/editar perfiles e permissões';

  @override
  String get createAnnouncements => 'Criar Anúncios';

  @override
  String get createEditChurchAnnouncements =>
      'Crie e edite anúncios para a igreja';

  @override
  String get manageEvents => 'Gerenciar Eventos';

  @override
  String get createManageChurchEvents => 'Criar e gerenciar eventos da igreja';

  @override
  String get manageVideos => 'Gerenciar Vídeos';

  @override
  String get administerChurchSectionsVideos =>
      'Administre as seções e vídeos da igreja';

  @override
  String get administerCults => 'Administrar Cultos';

  @override
  String get manageCultsMinistriesSongs =>
      'Gerenciar cultos, ministérios e canções';

  @override
  String get createMinistry => 'Criar Ministérios';

  @override
  String get createConnect => 'Criar Connect';

  @override
  String get counselingRequests => 'Solicitações de Aconselhamento';

  @override
  String get manageMemberRequests => 'Gerencie as solicitações dos membros';

  @override
  String get privatePrayers => 'Orações Privadas';

  @override
  String get managePrivatePrayerRequests =>
      'Gerencie as solicitações de oração privada';

  @override
  String get sendPushNotification => 'Enviar Notificação Push';

  @override
  String get sendMessagesToChurchMembers =>
      'Envie mensagens aos membros da igreja';

  @override
  String get deleteMinistries => 'Eliminar Ministérios';

  @override
  String get removeExistingMinistries => 'Remover ministérios existentes';

  @override
  String get deleteGroups => 'Eliminar Grupos';

  @override
  String get removeExistingGroups => 'Remover grupos existentes';

  @override
  String get reportsAndAttendance => 'Relatórios e Assistência';

  @override
  String get manageEventAttendance => 'Gerenciar Presença em Eventos';

  @override
  String get checkAttendanceGenerateReports =>
      'Verificar assistência e gerar relatórios';

  @override
  String get ministryStatistics => 'Estatísticas de Ministérios';

  @override
  String get participationMembersAnalysis =>
      'Análise de participação e membros';

  @override
  String get groupStatistics => 'Estatísticas de Grupos';

  @override
  String get scheduleStatistics => 'Estatísticas de Escalas';

  @override
  String get participationInvitationsAnalysis =>
      'Análise de participação e convites';

  @override
  String get courseStatistics => 'Estatísticas de Cursos';

  @override
  String get enrollmentProgressAnalysis => 'Análise de inscrições e progresso';

  @override
  String get userInfo => 'Informação de Usuários';

  @override
  String get consultParticipationDetails =>
      'Consultar detalhes de participação';

  @override
  String get churchStatistics => 'Estatísticas da Igreja';

  @override
  String get membersActivitiesOverview =>
      'Visão geral dos membros e atividades';

  @override
  String get noGroupsAvailable => 'Não há grupos disponíveis';

  @override
  String get unnamedGroup => 'Grupo sem nome';

  @override
  String get noMinistriesAvailable => 'Não há ministérios disponíveis';

  @override
  String get unnamedMinistry => 'Ministério sem nome';

  @override
  String get deleteGroup => 'Excluir Connect';

  @override
  String get confirmDeleteGroupQuestion =>
      'Está seguro que deseja eliminar o grupo ';

  @override
  String get deleteGroupWarning =>
      '\n\nEsta ação não se pode desfazer e eliminará todos os mensajes e eventos asociados.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String groupDeletedSuccessfully(String groupName) {
    return 'Grupo excluído com sucesso';
  }

  @override
  String errorDeletingGroup(String error) {
    return 'Erro ao excluir grupo: $error';
  }

  @override
  String get deleteMinistry => 'Excluir ministério';

  @override
  String get confirmDeleteMinistryQuestion =>
      'Está seguro que deseja eliminar o ministério ';

  @override
  String get deleteMinistryWarning =>
      '\n\nEsta ação não se pode desfazer e eliminará todos os mensajes e eventos asociados.';

  @override
  String ministryDeletedSuccessfully(String ministryName) {
    return 'Ministério excluído com sucesso';
  }

  @override
  String get logOut => 'Fechar Sessão';

  @override
  String errorLoggingOut(String error) {
    return 'Erro ao Fazer Logout: $error';
  }

  @override
  String get additionalInfoSavedSuccessfully =>
      'Informação adicional salva com sucesso';

  @override
  String errorSaving(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String unsupportedFieldType(String type) {
    return 'Tipo de campo não suportado: $type';
  }

  @override
  String get thisFieldIsRequired => 'Este campo é obrigatório';

  @override
  String get requiredField => 'Campo Obrigatório';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get choosePreferredLanguage => 'Escolha seu idioma preferido';

  @override
  String get somethingWentWrong => 'Algo deu errado!';

  @override
  String get tryAgainLater => 'Tente novamente mais tarde';

  @override
  String get welcome => 'Bem-vindo';

  @override
  String get connectingToYourCommunity => 'Conectando você à sua comunidade';

  @override
  String errorLoadingSections(String error) {
    return 'Erro ao carregar seções: $error';
  }

  @override
  String unknownSectionError(String sectionType) {
    return 'Seção desconhecida ou erro: $sectionType';
  }

  @override
  String get additionalInformationNeeded => 'Informação adicional necessária';

  @override
  String get pleaseCompleteYourAdditionalInfo =>
      'Por favor, complete suas informações adicionais para melhorar sua experiência na igreja.';

  @override
  String get completeNow => 'Completar agora';

  @override
  String get doNotShowAgain => 'Não mostrar mais';

  @override
  String get skipForNow => 'Pular por enquanto';

  @override
  String get user => 'Usuário';

  @override
  String get workInvites => 'Convites de Trabalho';

  @override
  String get serviceStatistics => 'Estatísticas de Serviços';

  @override
  String get home => 'Início';

  @override
  String get notifications => 'Notificações';

  @override
  String get calendar => 'Calendário';

  @override
  String get videos => 'Vídeos';

  @override
  String get profile => 'Perfil';

  @override
  String get all => 'Todos';

  @override
  String get unread => 'Não lidas';

  @override
  String get markAllAsRead => 'Marcar todas como lidas';

  @override
  String get allNotificationsMarkedAsRead =>
      'Todas as notificações marcadas como lidas';

  @override
  String error(String error) {
    return 'Erro: $error';
  }

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get deleteAllNotifications => 'Excluir todas as notificações';

  @override
  String get areYouSureYouWantToDeleteAllNotifications =>
      'Tem certeza que deseja excluir todas as notificações?';

  @override
  String get deleteAll => 'Eliminar todas';

  @override
  String get allNotificationsDeleted => 'Todas as notificações excluídas';

  @override
  String get youHaveNoNotifications => 'Você não tem notificações';

  @override
  String get youHaveNoNotificationsOfType =>
      'Você não tem notificações deste tipo';

  @override
  String get removeFilter => 'Remover filtro';

  @override
  String get youHaveNoUnreadNotifications =>
      'Você não tem notificações não lidas';

  @override
  String get youHaveNoUnreadNotificationsOfType =>
      'Você não tem notificações não lidas deste tipo';

  @override
  String get notificationDeleted => 'Notificação excluída';

  @override
  String errorLoadingEvents(String error) {
    return 'Erro ao carregar eventos: $error';
  }

  @override
  String get calendars => 'Calendários';

  @override
  String get events => 'Eventos';

  @override
  String get services => 'Escalas';

  @override
  String get counseling => 'Aconselhamento';

  @override
  String get manageSections => 'Gerenciar seções';

  @override
  String get recentVideos => 'Vídeos Recentes';

  @override
  String errorInSection(Object error) {
    return 'Erro na seção: $error';
  }

  @override
  String get noVideosAvailableInSection =>
      'Nenhum vídeo disponível nesta seção';

  @override
  String errorInCustomSection(Object error) {
    return 'Erro na seção customizada: $error';
  }

  @override
  String get noVideosInCustomSection =>
      'Nenhum vídeo nesta seção personalizada';

  @override
  String get addVideo => 'Adicionar vídeo';

  @override
  String get cultsSchedule => 'Programação de Cultos';

  @override
  String get noScheduledCults => 'Não há cultos programados';

  @override
  String get today => 'Hoje';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get loginToYourAccount => 'Entrar na sua conta';

  @override
  String get welcomeBackPleaseLogin =>
      'Bem-vindo de volta! Por favor, faça login para continuar';

  @override
  String get email => 'Email';

  @override
  String get yourEmailExample => 'seu.email@exemplo.com';

  @override
  String get pleaseEnterYourEmail => 'Por favor, digite seu email';

  @override
  String get pleaseEnterAValidEmail => 'Por favor, digite um email válido';

  @override
  String get password => 'Senha';

  @override
  String get enterYourPassword => 'Digite sua senha';

  @override
  String get pleaseEnterYourPassword => 'Por favor, digite sua senha';

  @override
  String get forgotYourPassword => 'Esqueceu sua senha?';

  @override
  String get login => 'Entrar';

  @override
  String get dontHaveAnAccount => 'Não tem uma conta?';

  @override
  String get signUp => 'Cadastre-se';

  @override
  String get welcomeBack => 'Bem-vindo de volta!';

  @override
  String get noAccountWithThisEmail => 'Não existe uma conta com este email';

  @override
  String get incorrectPassword => 'Senha incorreta';

  @override
  String get tooManyFailedAttempts =>
      'Muitas tentativas malsucedidas. Por favor, tente mais tarde.';

  @override
  String get invalidCredentials =>
      'Credenciais inválidas. Verifique seu email e senha.';

  @override
  String get accountDisabled => 'Esta conta foi desativada.';

  @override
  String get loginNotEnabled =>
      'O login com email e senha não está habilitado.';

  @override
  String get connectionError =>
      'Erro de conexão. Verifique sua conexão com a Internet.';

  @override
  String get verificationError =>
      'Erro de verificação. Por favor, tente novamente.';

  @override
  String get recaptchaFailed =>
      'A verificação do reCAPTCHA falhou. Por favor, tente novamente.';

  @override
  String errorLoggingIn(String error) {
    return 'Erro ao fazer login: $error';
  }

  @override
  String get operationTimedOut =>
      'A operação demorou muito. Por favor, tente novamente.';

  @override
  String get platformError =>
      'Erro de plataforma. Por favor, contate o administrador.';

  @override
  String get unexpectedError =>
      'Erro inesperado. Por favor, tente novamente mais tarde.';

  @override
  String get unauthenticatedUser => 'Usuário não autenticado';

  @override
  String get noAdditionalFields => 'Não há campos adicionais para completar';

  @override
  String get back => 'Voltar';

  @override
  String get additionalInformation => 'Informações Adicionais';

  @override
  String get pleaseCompleteTheFollowingInfo =>
      'Por favor, complete as seguintes informações:';

  @override
  String get otherInformation => 'Outras Informações';

  @override
  String get pleaseCorrectErrorsBeforeSaving =>
      'Por favor, corrija os erros antes de salvar.';

  @override
  String get pleaseFillAllRequiredBasicFields =>
      'Por favor, preencha todos os campos básicos obrigatórios.';

  @override
  String get pleaseFillAllRequiredAdditionalFields =>
      'Por favor, preencha todos os campos adicionais obrigatórios (*)';

  @override
  String get informationSavedSuccessfully => 'Informações salvas com sucesso';

  @override
  String get birthDateLabel => 'Data de Nascimento';

  @override
  String get genderLabel => 'Gênero';

  @override
  String get phoneLabel => 'Telefone';

  @override
  String get phoneHint => 'Ex: 912345678';

  @override
  String get selectAnOption => 'Selecione uma opção';

  @override
  String get enterAValidNumber => 'Insira um número válido';

  @override
  String get enterAValidEmail => 'Insira um email válido';

  @override
  String get enterAValidPhoneNumber => 'Insira um número de telefone válido';

  @override
  String get recoverPassword => 'Recuperar Senha';

  @override
  String get enterEmailToReceiveInstructions =>
      'Digite seu email para receber as instruções';

  @override
  String get sendEmail => 'Enviar Email';

  @override
  String get emailSent => 'Email Enviado!';

  @override
  String get checkYourInbox =>
      'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.';

  @override
  String get gotIt => 'Entendi';

  @override
  String get recoveryEmailSentSuccessfully =>
      'Email de recuperação enviado com sucesso!';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String errorSendingEmail(String error) {
    return 'Erro ao enviar email: $error';
  }

  @override
  String get createANewAccount => 'Criar uma nova conta';

  @override
  String get fillYourDetailsToRegister =>
      'Preencha seus dados para se cadastrar';

  @override
  String get enterYourName => 'Digite seu nome';

  @override
  String get enterYourSurname => 'Digite seu sobrenome';

  @override
  String get phoneNumber => 'Telefone';

  @override
  String get phoneNumberHint => '(00) 00000-0000';

  @override
  String get pleaseEnterYourPhone => 'Por favor, digite seu telefone';

  @override
  String get pleaseEnterAValidPhone => 'Por favor, digite um telefone válido';

  @override
  String get pleaseEnterAPassword => 'Por favor, digite uma senha';

  @override
  String get passwordMustBeAtLeast6Chars =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get enterYourPasswordAgain => 'Digite sua senha novamente';

  @override
  String get pleaseConfirmYourPassword => 'Por favor, confirme sua senha';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get alreadyHaveAnAccount => 'Já tem uma conta?';

  @override
  String get byRegisteringYouAccept =>
      'Ao se cadastrar, você aceita nossos termos e condições e nossa política de privacidade.';

  @override
  String get welcomeCompleteProfile =>
      'Bem-vindo! Complete seu perfil para aproveitar todas as funções.';

  @override
  String get emailAlreadyInUse => 'Já existe uma conta com este email';

  @override
  String get invalidEmailFormat => 'O formato do email não é válido';

  @override
  String get registrationNotEnabled =>
      'O registro com email e senha não está habilitado';

  @override
  String get weakPassword => 'A senha é muito fraca, tente uma mais segura';

  @override
  String errorRegistering(String error) {
    return 'Erro ao registrar: $error';
  }

  @override
  String get pending => 'Pendentes';

  @override
  String get accepted => 'Aceito';

  @override
  String get rejected => 'Rejeitados';

  @override
  String get youHaveNoWorkInvites => 'Você não tem convites de trabalho';

  @override
  String youHaveNoInvitesOfType(String status) {
    return 'Você não tem convites $status';
  }

  @override
  String get acceptedStatus => 'Aceito';

  @override
  String get rejectedStatus => 'Rejeitado';

  @override
  String get seenStatus => 'Visto';

  @override
  String get pendingStatus => 'Pendente';

  @override
  String get reject => 'Recusar';

  @override
  String get accept => 'Aceitar';

  @override
  String get inviteAcceptedSuccessfully => 'Convite aceito com sucesso';

  @override
  String get inviteRejectedSuccessfully => 'Convite rejeitado com sucesso';

  @override
  String errorRespondingToInvite(String error) {
    return 'Erro ao responder ao convite: $error';
  }

  @override
  String get invitationDetails => 'Detalhes do Convite';

  @override
  String get invitationAccepted => 'Convite aceito com sucesso';

  @override
  String get invitationRejected => 'Convite rejeitado com sucesso';

  @override
  String get workInvitation => 'Convite de Trabalho';

  @override
  String get jobDetails => 'Detalhes do Trabalho';

  @override
  String get roleToPerform => 'Função a desempenhar';

  @override
  String get invitationInfo => 'Informações do Convite';

  @override
  String get sentBy => 'Enviado por';

  @override
  String get loading => 'Carregando...';

  @override
  String get sentDate => 'Data de envio';

  @override
  String get responseDate => 'Data de resposta';

  @override
  String get announcements => 'Anúncios';

  @override
  String get errorLoadingAnnouncements => 'Erro ao carregar anúncios';

  @override
  String get noAnnouncementsAvailable => 'Não há anúncios disponíveis';

  @override
  String get seeMore => 'Ver mais';

  @override
  String get noUpcomingEvents => 'Não há eventos futuros no momento';

  @override
  String get online => 'Online';

  @override
  String get inPerson => 'Presencial';

  @override
  String get hybrid => 'Híbrido';

  @override
  String get schedulePastoralCounseling => 'Agende uma consulta pastoral';

  @override
  String get talkToAPastor =>
      'Converse com um pastor para orientação espiritual';

  @override
  String get viewAll => 'Ver todos';

  @override
  String get swipeToSeeFeaturedCourses => 'Deslize para ver cursos em destaque';

  @override
  String lessons(int count) {
    return 'Lições';
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
  String get viewDonationOptions => 'Ver opções de doação';

  @override
  String get participateInChurchMinistries =>
      'Participe dos ministérios da igreja';

  @override
  String get connect => 'Connect';

  @override
  String get connectWithChurchGroups => 'Conecte-se com grupos da igreja';

  @override
  String get privatePrayer => 'Oração Privada';

  @override
  String get sendPrivatePrayerRequests => 'Envie pedidos de oração privados';

  @override
  String get publicPrayer => 'Oração Pública';

  @override
  String get shareAndPrayWithTheCommunity =>
      'Compartilhe e ore com a comunidade';

  @override
  String get eventNotFound => 'Evento não encontrado';

  @override
  String get errorLoadingEvent => 'Erro ao carregar evento';

  @override
  String errorLoadingEventDetails(String error) {
    return 'Erro ao carregar detalhes do evento: $error';
  }

  @override
  String get eventNotFoundOrInvalid => 'Evento não encontrado ou inválido.';

  @override
  String errorOpeningEvent(String error) {
    return 'Erro ao abrir o evento: $error';
  }

  @override
  String errorNavigatingToEvent(String error) {
    return 'Erro ao navegar ao evento: $error';
  }

  @override
  String get announcementReloaded =>
      'Dados do anúncio recarregados (implementar atualização de estado se necessário)';

  @override
  String errorReloadingAnnouncement(String error) {
    return 'Erro ao recarregar anúncio: $error';
  }

  @override
  String get confirmDeletion => 'Confirmar Exclusão';

  @override
  String get confirmDeleteAnnouncement =>
      'Tem certeza que deseja excluir este anúncio? Esta ação não pode ser desfeita.';

  @override
  String get deletingAnnouncement => 'Excluindo anúncio...';

  @override
  String errorDeletingImage(String error) {
    return 'Erro ao excluir imagem do Storage: $error';
  }

  @override
  String get announcementDeletedSuccessfully => 'Anúncio excluído com sucesso';

  @override
  String errorDeletingAnnouncement(String error) {
    return 'Erro ao excluir o anúncio: $error';
  }

  @override
  String get cultAnnouncement => 'Anúncio de Culto';

  @override
  String get announcement => 'Anúncio';

  @override
  String get editAnnouncement => 'Editar Anúncio';

  @override
  String get deleteAnnouncement => 'Excluir Anúncio';

  @override
  String cult(Object cultName) {
    return 'Culto: $cultName';
  }

  @override
  String publishedOn(String date) {
    return 'Publicado em:';
  }

  @override
  String cultDate(String date) {
    return 'Data do culto: $date';
  }

  @override
  String get linkedEvent => 'Evento Vinculado';

  @override
  String get tapToSeeDetails => 'Toque para ver detalhes';

  @override
  String get noEventLinkedToThisCult => 'Nenhum evento vinculado a este culto.';

  @override
  String errorVerifyingRegistration(String error) {
    return 'Erro ao verificar registro: $error';
  }

  @override
  String errorVerifyingUserRole(String error) {
    return 'Erro ao verificar o papel do usuário: $error';
  }

  @override
  String get updateEventLink => 'Atualizar link do evento';

  @override
  String get addEventLink => 'Adicionar link do evento';

  @override
  String get enterOnlineEventLink =>
      'Insira o link para os participantes acessarem o evento online:';

  @override
  String get eventUrl => 'URL do evento';

  @override
  String get eventUrlHint => 'https://zoom.us/meeting/...';

  @override
  String get invalidUrlFormat => 'O link deve começar com http:// ou https://';

  @override
  String get deleteLink => 'Excluir link';

  @override
  String get linkDeletedSuccessfully => 'Link do evento excluído com sucesso';

  @override
  String get linkUpdatedSuccessfully => 'Link do evento atualizado com sucesso';

  @override
  String get linkAddedSuccessfully => 'Link do evento adicionado com sucesso';

  @override
  String errorUpdatingLink(String error) {
    return 'Erro ao atualizar o link: $error';
  }

  @override
  String errorSendingNotifications(String error) {
    return 'Erro ao enviar notificações: $error';
  }

  @override
  String get mustLoginToRegisterAttendance =>
      'Você deve fazer login para registrar sua presença';

  @override
  String get attendanceRegisteredSuccessfully =>
      'Presença registrada com sucesso';

  @override
  String get couldNotOpenLink => 'Não foi possível abrir o link';

  @override
  String errorOpeningLink(String error) {
    return 'Erro ao abrir o link: $error';
  }

  @override
  String get noPermissionToDeleteEvent =>
      'Você não tem permissão para excluir este evento';

  @override
  String get deleteEvent => 'Excluir Evento';

  @override
  String get confirmDeleteEvent =>
      'Tem certeza de que deseja excluir este evento?';

  @override
  String get eventDeletedSuccessfully => 'Evento excluído com sucesso';

  @override
  String get deleteTicket => 'Excluir Bilhete';

  @override
  String get confirmDeleteTicket =>
      'Tem certeza de que deseja excluir este bilhete? Esta ação não pode ser desfeita.';

  @override
  String get ticketDeletedSuccessfully => 'Bilhete excluído com sucesso';

  @override
  String errorDeletingTicket(String error) {
    return 'Erro ao excluir: $error';
  }

  @override
  String get deleteMyTicket => 'Excluir meu bilhete';

  @override
  String get confirmDeleteMyTicket =>
      'Tem certeza de que deseja excluir seu bilhete? Esta ação não pode ser desfeita.';

  @override
  String errorDeletingMyTicket(String error) {
    return 'Erro ao excluir o bilhete: $error';
  }

  @override
  String get notDefined => 'Não definido';

  @override
  String get onlineEvent => 'Evento online';

  @override
  String get accessEvent => 'Acessar o evento';

  @override
  String get copyEventLink => 'Copiar link do evento';

  @override
  String get linkCopied => 'Link copiado!';

  @override
  String get linkNotConfigured => 'Link não configurado';

  @override
  String get addLinkForAttendees =>
      'Adicione um link para os participantes acessarem o evento';

  @override
  String get addLink => 'Adicionar link';

  @override
  String get physicalLocationNotSpecified =>
      'Localização física não especificada';

  @override
  String get physicalLocation => 'Localização física';

  @override
  String get accessOnline => 'Acessar online';

  @override
  String get addLinkForOnlineAttendance =>
      'Adicione um link para a presença online';

  @override
  String get locationNotSpecified => 'Local não especificado';

  @override
  String get manageAttendees => 'Gerenciar participantes';

  @override
  String get scanTickets => 'Escanear bilhetes';

  @override
  String get updateLink => 'Atualizar link';

  @override
  String get createNewTicket => 'Criar novo bilhete';

  @override
  String get noPermissionToCreateTickets =>
      'Você não tem permissão para criar bilhetes';

  @override
  String get deleteEventTooltip => 'Excluir evento';

  @override
  String get start => 'Início';

  @override
  String get end => 'Fim';

  @override
  String get description => 'Descrição';

  @override
  String get updatingTickets => 'Atualizando bilhetes...';

  @override
  String get loadingTickets => 'Carregando bilhetes...';

  @override
  String get availableTickets => 'Bilhetes disponíveis';

  @override
  String get createTicket => 'Criar bilhete';

  @override
  String get noTicketsAvailable => 'Não há bilhetes disponíveis';

  @override
  String get createTicketForUsers =>
      'Crie um bilhete para que os usuários possam se registrar';

  @override
  String errorLoadingTickets(String error) {
    return 'Erro ao carregar bilhetes: $error';
  }

  @override
  String get alreadyRegistered => 'Já cadastrado';

  @override
  String get viewQr => 'Ver QR';

  @override
  String get register => 'Registrar-se';

  @override
  String get presential => 'Presencial';

  @override
  String get unknown => 'Desconhecido';

  @override
  String cults(Object count) {
    return '$count cultos';
  }

  @override
  String unknownSectionType(String sectionType) {
    return 'Seção desconhecida ou erro: $sectionType';
  }

  @override
  String get additionalInformationRequired =>
      'Informações adicionais necessárias';

  @override
  String get pleaseCompleteAdditionalInfo =>
      'Por favor, complete suas informações adicionais para melhorar sua experiencia na igreja.';

  @override
  String get churchName => 'Amor em Movimento';

  @override
  String get navHome => 'Inicio';

  @override
  String get navNotifications => 'Notificações';

  @override
  String get navCalendar => 'Calendário';

  @override
  String get navVideos => 'Vídeos';

  @override
  String get navProfile => 'Perfil';

  @override
  String errorPublishingComment(String error) {
    return 'Erro ao publicar o comentário';
  }

  @override
  String get deleteOwnCommentsOnly =>
      'Você só pode excluir seus próprios comentários';

  @override
  String get deleteComment => 'Excluir comentário';

  @override
  String get deleteCommentConfirmation =>
      'Tem certeza de que deseja excluir este comentário?';

  @override
  String get commentDeleted => 'Comentário excluído';

  @override
  String errorDeletingComment(String error) {
    return 'Erro ao excluir o comentário: $error';
  }

  @override
  String get errorTitle => 'Erro';

  @override
  String get cultNotFound => 'Culto não encontrado';

  @override
  String totalLessons(int count) {
    return '$count Lições';
  }

  @override
  String get myKidsManagement => 'Gestão MyKids';

  @override
  String get familyProfiles => 'Perfis Familiares';

  @override
  String get manageFamilyProfiles => 'Gerenciar Perfis Familiares';

  @override
  String get manageRoomsAndCheckin => 'Gerenciar Salas e Check-in';

  @override
  String get manageRoomsCheckinDescription =>
      'Administrar salas, check-in/out e assistência';

  @override
  String get permissionsDiagnostics => 'Diagnóstico de Permissões';

  @override
  String get availablePermissions => 'Permissões Disponíveis';

  @override
  String get noUserData => 'Sem dados de usuário';

  @override
  String get noName => 'Sem nome';

  @override
  String get noEmail => 'Sem email';

  @override
  String get roleIdLabel => 'ID do Papel';

  @override
  String get noRole => 'Sem Papel';

  @override
  String get superUser => 'SuperUser';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get rolePermissionsTitle => 'Permissões do papel';

  @override
  String get roleNoPermissions => 'Este papel não tem permissões atribuídas';

  @override
  String get noRoleInfo => 'Não há informações de papel disponíveis';

  @override
  String get deleteGroupConfirmationPrefix =>
      'Tem certeza de que deseja excluir o grupo ';

  @override
  String get deleteMinistryConfirmationPrefix =>
      'Tem certeza de que deseja excluir o ministério ';

  @override
  String errorFetchingDiagnostics(String error) {
    return 'Erro ao obter diagnóstico: $error';
  }

  @override
  String roleNotFound(String roleId) {
    return 'Rol não encontrado: $roleId';
  }

  @override
  String get idLabel => 'ID';

  @override
  String get personalInformationSection => 'Informação Pessoal';

  @override
  String get birthDateField => 'Nascimento';

  @override
  String get genderField => 'Sexo';

  @override
  String get phoneField => 'Telefone';

  @override
  String get mySchedulesSection => 'Minhas Escalas';

  @override
  String get manageMinistriesAssignments =>
      'Gerenciar suas atribuições e convites de trabalho nos ministérios';

  @override
  String errorSavingInfo(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get requiredFieldTooltip => 'Campo obrigatório';

  @override
  String get navigateToFamilyProfiles => 'Navegar para Perfis Familiares';

  @override
  String get personalInfoUpdatedSuccessfully =>
      'Informação pessoal atualizada com sucesso!';

  @override
  String errorSavingPersonalData(String error) {
    return 'Erro ao salvar dados pessoais: $error';
  }

  @override
  String errorLoadingPersonalData(String error) {
    return 'Erro ao carregar dados pessoais: $error';
  }

  @override
  String get manageDonationsTitle => 'Gerenciar Doações';

  @override
  String get noPermissionToSaveSettings =>
      'Sem permissão para salvar configurações.';

  @override
  String get donationConfigSaved => 'Configurações de doação salvas';

  @override
  String errorCheckingPermission(String error) {
    return 'Erro ao verificar permissão: $error';
  }

  @override
  String get accessDenied => 'Acesso Negado';

  @override
  String get noPermissionManageDonations =>
      'Você não tem permissão para gerenciar as configurações de doação.';

  @override
  String get configureDonationsSection =>
      'Configure como a seção de doações aparecerá na Tela Inicial.';

  @override
  String get sectionTitleOptional => 'Título da Seção (Opcional)';

  @override
  String get descriptionOptional => 'Descrição (opcional)';

  @override
  String get backgroundImageOptional => 'Imagem de Fundo (Opcional)';

  @override
  String get tapToAddImage => 'Toque para adicionar uma imagem';

  @override
  String get removeImage => 'Remover Imagem';

  @override
  String get bankAccountsOptional => 'Contas Bancárias (Opcional)';

  @override
  String get bankingInformation => 'Informações Bancárias';

  @override
  String get bankAccountsHint =>
      'Banco: XXX\nAgência: YYYY\nConta: ZZZZZZ\nNome Titular\n\n(Separe contas com linha em branco)';

  @override
  String get pixKeysOptional => 'Chaves Pix (Opcional)';

  @override
  String get noPixKeysAdded => 'Nenhuma chave Pix adicionada.';

  @override
  String get pixKey => 'Chave Pix';

  @override
  String get removeKey => 'Remover Chave';

  @override
  String get keyRequired => 'Chave obrigatória';

  @override
  String get addPixKey => 'Adicionar Chave Pix';

  @override
  String get saveSettings => 'Salvar Configurações';

  @override
  String get manageLiveStreamTitle => 'Gerenciar Transmissão';

  @override
  String errorLoadingData(String error) {
    return 'Erro ao carregar dados: $error';
  }

  @override
  String get noPermissionManageLiveStream =>
      'Você não tem permissão para gerenciar a configuração de transmissão.';

  @override
  String get sectionTitleHome => 'Título da Seção (Home)';

  @override
  String get sectionTitleHint => 'Ex: Transmissão Ao Vivo';

  @override
  String get pleaseEnterSectionTitle =>
      'Por favor, insira um título para a seção';

  @override
  String get additionalTextOptional => 'Texto Adicional (opcional)';

  @override
  String get transmissionImage => 'Imagem da Transmissão';

  @override
  String get titleOverImage => 'Título sobre a Imagem';

  @override
  String get titleOverImageHint => 'Ex: Culto de Domingo';

  @override
  String get transmissionLink => 'Link da Transmissão';

  @override
  String get urlYouTubeVimeo => 'URL (YouTube, Vimeo, etc.)';

  @override
  String get pasteFullLinkHere => 'Cole o link completo aqui';

  @override
  String get pleaseEnterValidUrl => 'Por favor digite um URL válido';

  @override
  String get activateTransmissionHome => 'Ativar Transmissão na Home';

  @override
  String get visibleInHome => 'Visível na Home';

  @override
  String get hiddenInHome => 'Oculto na Home';

  @override
  String get saveConfiguration => 'Salvar Configuração';

  @override
  String get configurationSaved => 'Configuração guardada';

  @override
  String get errorUploadingImageStream => 'Erro ao subir a imagem';

  @override
  String get manageHomeScreenTitle => 'Gerenciar Tela Inicial';

  @override
  String get noPermissionReorderSections =>
      'Sem permissão para reordenar seções.';

  @override
  String errorSavingNewOrder(String error) {
    return 'Erro ao salvar a nova ordem: $error';
  }

  @override
  String get noPermissionEditSections => 'Sem permissão para editar seções.';

  @override
  String get editSectionName => 'Editar Nome da Seção';

  @override
  String get sectionNameUpdatedSuccessfully =>
      'Nome da seção atualizado com sucesso!';

  @override
  String errorUpdatingName(String error) {
    return 'Erro ao atualizar nome: $error';
  }

  @override
  String get configureVisibility => 'Configurar Visibilidade';

  @override
  String sectionWillBeHiddenWhen(String contentType) {
    return 'A seção será ocultada quando não houver $contentType para exibir.';
  }

  @override
  String get visibilityConfigurationUpdated =>
      'Configuração de visibilidade atualizada!';

  @override
  String errorUpdatingConfiguration(String error) {
    return 'Erro ao atualizar configuração: $error';
  }

  @override
  String get noPermissionChangeStatus => 'Sem permissão para alterar status.';

  @override
  String errorUpdatingStatus(String error) {
    return 'Erro ao atualizar status: $error';
  }

  @override
  String get thisSectionCannotBeEditedHere =>
      'Esta seção não pode ser editada aqui.';

  @override
  String get noPermissionCreateSections => 'Sem permissão para criar seções.';

  @override
  String get noSectionsFound => 'Nenhuma seção encontrada.';

  @override
  String get scheduledCults => 'Cultos programados';

  @override
  String get pages => 'páginas';

  @override
  String get content => 'conteúdo';

  @override
  String get manageProfileFieldsTitle => 'Gerenciar Campos de Perfil';

  @override
  String get noPermissionManageProfileFields =>
      'Você não tem permissão para gerenciar campos de perfil.';

  @override
  String get createField => 'Criar Campo';

  @override
  String confirmDeleteField(String fieldName) {
    return 'Tem certeza que deseja excluir o campo \'$fieldName\'?';
  }

  @override
  String get fieldDeletedSuccessfully => 'Campo excluído com sucesso';

  @override
  String errorDeletingField(String error) {
    return 'Erro ao excluir campo: $error';
  }

  @override
  String get pleaseAddAtLeastOneOption =>
      'Por favor, adicione pelo menos uma opção para o campo de seleção.';

  @override
  String get noPermissionManageFields =>
      'Você não tem permissão para gerenciar campos.';

  @override
  String get manageRolesTitle => 'Gerenciar Perfiles';

  @override
  String get confirmDeletionRole => 'Confirmar Exclusão de Papel';

  @override
  String confirmDeleteRole(String roleName) {
    return 'Tem certeza que deseja excluir o papel \'$roleName\'?';
  }

  @override
  String get warningDeleteRole =>
      'Esta ação não pode ser desfeita e afetará todos os usuários com este papel.';

  @override
  String get noPermissionDeleteRoles => 'Sem permissão para excluir papéis';

  @override
  String get roleDeletedSuccessfully => 'Papel excluído com sucesso';

  @override
  String errorDeletingRole(String error) {
    return 'Erro ao excluir papel: $error';
  }

  @override
  String get noPermissionManageRoles =>
      'Você não tem permissão para gerenciar perfiles e permissões.';

  @override
  String errorLoadingRoles(String error) {
    return 'Erro ao carregar papéis: $error';
  }

  @override
  String get noRolesFound => 'Nenhum papel encontrado. Crie o primeiro!';

  @override
  String get manageUserRolesTitle => 'Gerenciar Perfiles de Usuários';

  @override
  String get noPermissionAccessPage =>
      'Você não tem permissão para acessar esta página.';

  @override
  String errorCheckingPermissions(String error) {
    return 'Erro ao verificar permissões: $error';
  }

  @override
  String errorLoadingRolesData(String error) {
    return 'Erro ao carregar papéis: $error';
  }

  @override
  String errorLoadingUsers(String error) {
    return 'Erro ao carregar usuários: $error';
  }

  @override
  String get noPermissionUpdateRoles =>
      'Você não tem permissão para atualizar papéis.';

  @override
  String get cannotChangeOwnRole => 'Não é possível alterar seu próprio papel';

  @override
  String get userRoleUpdatedSuccessfully =>
      'Papel do usuário atualizado com sucesso';

  @override
  String errorUpdatingRole(String error) {
    return 'Erro ao atualizar papel: $error';
  }

  @override
  String get selectUserRole => 'Selecionar papel do usuário';

  @override
  String get manageCoursesTitle => 'Gerenciar Cursos';

  @override
  String get noPermissionManageCourses =>
      'Você não tem permissão para gerenciar cursos.';

  @override
  String errorLoadingCourses(String error) {
    return 'Erro ao carregar cursos: $error';
  }

  @override
  String get published => 'Publicado';

  @override
  String get drafts => 'Rascunhos';

  @override
  String get archived => 'Arquivado';

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
      'Torne o curso visível para todos os usuários';

  @override
  String get createProfileField => 'Criar Campo de Perfil';

  @override
  String get editProfileField => 'Editar Campo de Perfil';

  @override
  String get fieldActive => 'Campo Ativo';

  @override
  String get showThisFieldInProfile => 'Mostrar este campo no perfil';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get fieldCreatedSuccessfully => 'Campo criado com sucesso';

  @override
  String get fieldUpdatedSuccessfully => 'Campo atualizado com sucesso';

  @override
  String get userNotAuthenticated => 'Usuario no autenticado';

  @override
  String get noProfileFieldsDefined => 'Não há campos de perfil definidos';

  @override
  String get fieldType => 'Tipo de Campo';

  @override
  String get text => 'Texto';

  @override
  String get number => 'Número';

  @override
  String get date => 'Data';

  @override
  String select(Object count) {
    return 'Selecionar ($count)';
  }

  @override
  String get donationSettings => 'Configurações de Doações';

  @override
  String get enableDonations => 'Habilitar doações';

  @override
  String get showDonationSection => 'Mostrar seção de doações no aplicativo';

  @override
  String get bankName => 'Nome do Banco';

  @override
  String get accountNumber => 'Número da Conta';

  @override
  String get clabe => 'CLABE (México)';

  @override
  String get paypalMeLink => 'Link PayPal.Me';

  @override
  String get mercadoPagoAlias => 'Alias Mercado Pago';

  @override
  String get stripePublishableKey => 'Chave Publicável Stripe';

  @override
  String get donationInformation => 'Informações de Doação';

  @override
  String get saveDonationSettings => 'Salvar Configurações de Doações';

  @override
  String get donationSettingsUpdated =>
      'Configurações de doações atualizadas com sucesso.';

  @override
  String errorUpdatingDonationSettings(Object error) {
    return 'Erro ao atualizar as configurações de doações: $error';
  }

  @override
  String get enterBankName => 'Digite o nome do banco';

  @override
  String get enterAccountNumber => 'Digite o número da conta';

  @override
  String get enterClabe => 'Digite a CLABE';

  @override
  String get enterPaypalMeLink => 'Digite o link do PayPal.Me';

  @override
  String get enterMercadoPagoAlias => 'Digite o alias do Mercado Pago';

  @override
  String get enterStripePublishableKey => 'Digite a chave publicável do Stripe';

  @override
  String get cnpj => 'CNPJ';

  @override
  String get cpf => 'CPF';

  @override
  String get random => 'Aleatória';

  @override
  String get filterBy => 'Filtrar por:';

  @override
  String get createNewCourse => 'Criar Novo Curso';

  @override
  String get noCoursesFound => 'Nenhum curso encontrado';

  @override
  String get clickToCreateNewCourse =>
      'Clique no botão \'+\' para criar um novo curso';

  @override
  String get draft => 'Rascunho';

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
    return 'Opções para \"$courseTitle\"';
  }

  @override
  String get unpublishCourse => 'Despublicar (voltar para rascunho)';

  @override
  String get makeCourseInvisible => 'Tornar o curso invisível para os usuários';

  @override
  String get removeFeatured => 'Remover destaque';

  @override
  String get addFeatured => 'Destacar curso';

  @override
  String get removeFromFeatured => 'Remover da seção de destaque';

  @override
  String get addToFeatured => 'Mostrar o curso na seção de destaque';

  @override
  String get deleteCourse => 'Excluir curso';

  @override
  String get thisActionIsIrreversible => 'Esta ação não pode ser desfeita';

  @override
  String areYouSureYouWantToDelete(Object courseTitle) {
    return 'Tem certeza que deseja excluir o curso \"$courseTitle\"?';
  }

  @override
  String get irreversibleActionWarning =>
      'Esta ação é irreversível e excluirá todos os módulos, lições, materiais e progresso dos usuários associados a este curso.';

  @override
  String get courseDeletedSuccessfully => 'Curso excluído com sucesso';

  @override
  String errorDeletingCourse(Object error) {
    return 'Erro ao excluir o curso: $error';
  }

  @override
  String get coursePublishedSuccessfully => 'Curso publicado com sucesso';

  @override
  String get courseUnpublishedSuccessfully => 'Curso despublicado com sucesso';

  @override
  String get courseFeaturedSuccessfully => 'Curso destacado com sucesso';

  @override
  String get featuredRemovedSuccessfully => 'Destaque removido com sucesso';

  @override
  String errorUpdatingFeatured(Object error) {
    return 'Erro ao atualizar o destaque: $error';
  }

  @override
  String get instructor => 'Instrutor';

  @override
  String get duration => 'Duração';

  @override
  String get lessonsLabel => 'Lições';

  @override
  String get category => 'Categoria';

  @override
  String get enroll => 'Inscrever-se';

  @override
  String get alreadyEnrolled => 'Você já está inscrito';

  @override
  String get courseContent => 'Conteúdo do Curso';

  @override
  String get lesson => 'Lição';

  @override
  String get materials => 'Materiais';

  @override
  String get comments => 'Comentários';

  @override
  String get course => 'Curso';

  @override
  String get markAsCompleted => 'Marcar como concluída';

  @override
  String get processing => 'Processando...';

  @override
  String get evaluateThisLesson => 'Avaliar esta lição';

  @override
  String get averageRating => 'Avaliação média';

  @override
  String get lessonCompleted => 'Lição concluída';

  @override
  String get alreadyCompleted => 'Você já concluiu esta lição';

  @override
  String get errorCompletingLesson => 'Erro ao marcar a lição como concluída';

  @override
  String get noMaterialsForThisLesson => 'Não há materiais para esta lição';

  @override
  String get noCommentsForThisLesson => 'Não há comentários para esta lição';

  @override
  String get addYourComment => 'Adicione seu comentário...';

  @override
  String get commentPublished => 'Comentário publicado';

  @override
  String get loginToComment => 'Faça login para comentar';

  @override
  String get rateTheLesson => 'Avalie a lição';

  @override
  String get ratingSaved => 'Avaliação salva';

  @override
  String get errorSavingRating => 'Erro ao salvar a avaliação';

  @override
  String get loginToRate => 'Faça login para avaliar';

  @override
  String get courseNotFound => 'Curso não encontrado';

  @override
  String get courseNotFoundDetails => 'O curso não existe ou foi excluído';

  @override
  String get errorLoadingLessonCount => 'Erro ao carregar contagem de lições';

  @override
  String errorTogglingFavorite(Object error) {
    return 'Erro ao alternar favorito: $error';
  }

  @override
  String errorLoadingModules(Object error) {
    return 'Erro ao carregar módulos: $error';
  }

  @override
  String get noModulesAvailable => 'Não há módulos disponíveis';

  @override
  String errorLoadingLessons(Object error) {
    return 'Erro ao carregar lições: $error';
  }

  @override
  String get noLessonsAvailableInModule => 'Não há lições disponíveis';

  @override
  String errorEnrolling(Object error) {
    return 'Erro ao inscrever: $error';
  }

  @override
  String get enrollToAccessLesson =>
      'Inscreva-se no curso para acessar esta lição';

  @override
  String get noLessonsAvailable => 'Não há lições disponíveis neste curso';

  @override
  String get loginToEnroll => 'Faça login para se inscrever';

  @override
  String get enrolledSuccess => 'Você se inscreveu no curso!';

  @override
  String get startCourse => 'Começar Curso';

  @override
  String get continueCourse => 'Continuar Curso';

  @override
  String progressWithDetails(
      Object completed, Object percentage, Object total) {
    return 'Progresso: $percentage% ($completed/$total)';
  }

  @override
  String instructorLabel(Object name) {
    return 'Instrutor: $name';
  }

  @override
  String get lessonNotFound => 'Lição não encontrada';

  @override
  String get lessonNotFoundDetails =>
      'Não foi possível encontrar a lição solicitada';

  @override
  String durationLabel(Object duration) {
    return 'Duração: $duration';
  }

  @override
  String get unmarkAsCompleted => 'Desmarcar como concluída';

  @override
  String get lessonUnmarked => 'Lição desmarcada como concluída';

  @override
  String get noVideoAvailable => 'Nenhum vídeo disponível';

  @override
  String get clickToWatchVideo => 'Clique para assistir ao vídeo';

  @override
  String get noDescription => 'Sem descrição';

  @override
  String get commentsDisabled =>
      'Os comentários estão desativados para esta lição';

  @override
  String get noCommentsYet => 'Nenhum comentário ainda';

  @override
  String get beTheFirstToComment => 'Seja o primeiro a comentar';

  @override
  String get you => 'Você';

  @override
  String get reply => 'resposta';

  @override
  String get replies => 'respostas';

  @override
  String get repliesFunctionality =>
      'Funcionalidade de respostas em desenvolvimento';

  @override
  String get confirmDeleteComment =>
      'Tem certeza que deseja excluir este comentário?';

  @override
  String get yesterday => 'Ontem';

  @override
  String daysAgo(Object days) {
    return 'Há $days dias';
  }

  @override
  String get linkCopiedToClipboard =>
      'Link copiado para a área de transferência';

  @override
  String get open => 'Abrir';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get managePagesTitle => 'Gerenciar Páginas';

  @override
  String get noPermissionManagePages =>
      'Você não tem permissão para gerenciar páginas personalizadas.';

  @override
  String errorLoadingPages(Object error) {
    return 'Erro ao carregar páginas: $error';
  }

  @override
  String get noCustomPagesYet => 'Ainda não há páginas personalizadas.';

  @override
  String get tapPlusToCreateFirst => 'Toque no botão + para criar a primeira.';

  @override
  String get pageWithoutTitle => 'Página sem título';

  @override
  String get noPermissionEditPages =>
      'Você não tem permissão para editar páginas.';

  @override
  String get noPermissionCreatePages =>
      'Você não tem permissão para criar páginas.';

  @override
  String get createNewPage => 'Criar nova página';

  @override
  String get editPageTitle => 'Editar Página';

  @override
  String get pageTitle => 'Título da Página';

  @override
  String get pageTitleHint => 'Ex: Sobre Nós';

  @override
  String get appearanceInPageList => 'Aparência na Lista de Páginas';

  @override
  String get visualizationType => 'Tipo de Visualização na Lista';

  @override
  String get iconAndTitle => 'Ícone e Título';

  @override
  String get coverImage16x9 => 'Imagem de Capa (16:9)';

  @override
  String get icon => 'Ícone';

  @override
  String get coverImageLabel => 'Imagem de Capa (16:9)';

  @override
  String get changeImage => 'Trocar Imagem';

  @override
  String get selectImage => 'Selecionar Imagem';

  @override
  String get pageContentLabel => 'Conteúdo da Página';

  @override
  String get typePageContentHere => 'Digite o conteúdo da página aqui...';

  @override
  String get insertImage => 'Inserir Imagem';

  @override
  String get savePage => 'Salvar Página';

  @override
  String get pleaseEnterPageTitle =>
      'Por favor, insira um título para a página.';

  @override
  String get pleaseSelectIcon => 'Por favor, selecione um ícone para a página.';

  @override
  String get pleaseUploadCoverImage =>
      'Por favor, carregue uma imagem para a capa.';

  @override
  String errorInsertingImage(Object error) {
    return 'Erro ao inserir imagem: $error';
  }

  @override
  String get coverImageUploaded => 'Imagem da capa carregada!';

  @override
  String errorUploadingCoverImage(Object error) {
    return 'Erro ao carregar imagem da capa: $error';
  }

  @override
  String get pageSavedSuccessfully => 'Página salva com sucesso!';

  @override
  String errorSavingPage(Object error) {
    return 'Erro ao salvar página: $error';
  }

  @override
  String get discardChanges => 'Descartar Alterações?';

  @override
  String get unsavedChangesConfirm =>
      'Você tem alterações não salvas. Deseja sair mesmo assim?';

  @override
  String get discardAndExit => 'Descartar e Sair';

  @override
  String get restoreDraft => 'Restaurar Rascunho?';

  @override
  String get unsavedChangesFound =>
      'Encontramos alterações não salvas. Deseja restaurá-las?';

  @override
  String get discardDraft => 'Descartar Rascunho';

  @override
  String get restore => 'Restaurar';

  @override
  String get imageUploadFailed => 'Falha ao carregar imagem.';

  @override
  String errorLoadingPage(Object error) {
    return 'Erro ao carregar página: $error';
  }

  @override
  String get editSectionTitle => 'Editar Seção';

  @override
  String get createNewSection => 'Criar Nova Seção';

  @override
  String get deleteSection => 'Excluir seção';

  @override
  String get sectionTitleLabel => 'Título da Seção';

  @override
  String get pleaseEnterTitle => 'Por favor insira um título';

  @override
  String get pagesIncludedInSection => 'Páginas Incluídas nesta Seção';

  @override
  String get noCustomPagesFound =>
      'Nenhuma página personalizada encontrada para selecionar.';

  @override
  String pageWithoutTitleShort(Object id) {
    return 'Página sem título ($id...)';
  }

  @override
  String get selectAtLeastOnePage => 'Selecione pelo menos uma página.';

  @override
  String errorSavingSection(Object error) {
    return 'Erro ao salvar seção: $error';
  }

  @override
  String get deleteSectionConfirm => 'Excluir Seção?';

  @override
  String deleteSectionMessage(Object title) {
    return 'Tem certeza que deseja excluir a seção \"$title\"? Esta ação não pode ser desfeita.';
  }

  @override
  String errorDeleting(Object error) {
    return 'Erro ao excluir: $error';
  }

  @override
  String get sectionNameUpdated => 'Nome da seção atualizado com sucesso!';

  @override
  String typeLabel(Object type) {
    return 'Tipo: $type';
  }

  @override
  String get sectionName => 'Nome da Seção';

  @override
  String sectionLabel(Object title) {
    return 'Seção: $title';
  }

  @override
  String get hideWhenNoContent => 'Ocultar seção quando não houver conteúdo:';

  @override
  String get visibilityConfigUpdated =>
      'Configuração de visibilidade atualizada!';

  @override
  String errorUpdatingConfig(Object error) {
    return 'Erro ao atualizar configuração: $error';
  }

  @override
  String get sectionCannotBeEditedHere =>
      'Esta seção não pode ser editada aqui.';

  @override
  String get createNewPageSection => 'Criar Nova Seção de Páginas';

  @override
  String get noPermissionManageHomeSections =>
      'Você não tem permissão para gerenciar as seções da tela inicial.';

  @override
  String get editName => 'Editar nome';

  @override
  String get hiddenWhenEmpty => 'Oculta quando vazia';

  @override
  String get alwaysVisible => 'Sempre visível';

  @override
  String get liveStreamLabel => 'Ao Vivo';

  @override
  String get donations => 'Doações';

  @override
  String get onlineCourses => 'Cursos Online';

  @override
  String get customPages => 'Páginas Personalizadas';

  @override
  String get unknownSection => 'Seção Desconhecida';

  @override
  String get servicesGridObsolete => 'Grade de Serviços (Obsoleto)';

  @override
  String get liveStreamType => 'Transmissão ao vivo';

  @override
  String get courses => 'Cursos';

  @override
  String get pageList => 'Lista de Páginas';

  @override
  String get sectionWillBeDisplayed =>
      'A seção será sempre exibida, mesmo sem conteúdo.';

  @override
  String errorVerifyingPermission(Object error) {
    return 'Erro ao verificar permissão: $error';
  }

  @override
  String get configureAvailability => 'Configurar Disponibilidade';

  @override
  String get consultationSettings => 'Configurações de Consulta';

  @override
  String get noPermissionManageAvailability =>
      'Você não tem permissão para gerenciar a disponibilidade.';

  @override
  String errorLoadingAvailability(Object error) {
    return 'Erro ao carregar disponibilidade: $error';
  }

  @override
  String get confirmDeleteAllTimeSlots =>
      'Tem certeza que deseja excluir todas as faixas de horário?';

  @override
  String get deleteSlot => 'Excluir faixa';

  @override
  String get unavailableForConsultations => 'Não disponível para consultas';

  @override
  String get dayMarkedAvailableAddTimeSlots =>
      'Dia marcado como disponível, adicione faixas de horário';

  @override
  String weekOf(Object date) {
    return 'Semana de $date';
  }

  @override
  String get copyToNextWeek => 'Copiar para a próxima semana';

  @override
  String get counselingConfiguration => 'Configuração de Aconselhamento';

  @override
  String get counselingDuration => 'Duração do Aconselhamento';

  @override
  String get configureCounselingDuration =>
      'Configure quanto tempo durará cada Aconselhamento';

  @override
  String get intervalBetweenConsultations => 'Intervalo entre Consultas';

  @override
  String get configureRestTimeBetweenConsultations =>
      'Configure quanto tempo de descanso haverá entre consultas';

  @override
  String get configurationSavedSuccessfully => 'Configuração salva com sucesso';

  @override
  String get dayUpdatedSuccessfully => 'Dia atualizado com sucesso';

  @override
  String errorCopying(Object error) {
    return 'Erro ao copiar: $error';
  }

  @override
  String get addTimeSlots => 'Adicionar faixas de horário';

  @override
  String get editAvailability => 'Editar disponibilidade';

  @override
  String get manageAnnouncements => 'Gerenciar Anúncios';

  @override
  String get active => 'Ativo';

  @override
  String get inactiveExpired => 'Inativos/Vencidos';

  @override
  String get regular => 'Regulares';

  @override
  String get confirmAnnouncementDeletion => 'Confirmar exclusão';

  @override
  String get confirmDeleteAnnouncementMessage =>
      'Tem certeza que deseja excluir este anúncio? Esta ação não pode ser desfeita.';

  @override
  String get noActiveAnnouncements => 'Não há anúncios ativos';

  @override
  String get noInactiveExpiredAnnouncements =>
      'Não há anúncios inativos/vencidos';

  @override
  String get managedEvents => 'Eventos Administrados';

  @override
  String get update => 'Atualizar';

  @override
  String get noPermissionManageEventAttendance =>
      'Você não tem permissão para gerenciar a assistência de eventos.';

  @override
  String get manageAttendance => 'Gerenciar Presença';

  @override
  String get noEventsMinistries => 'de ministérios';

  @override
  String get noEventsGroups => 'de grupos';

  @override
  String noEventsMessage(Object filter) {
    return 'Não há eventos $filter';
  }

  @override
  String get eventsYouAdministerWillAppearHere =>
      'Os eventos que você administra serão exibidos aqui';

  @override
  String get noTitle => 'Sem título';

  @override
  String get ministry => 'Ministério';

  @override
  String get group => 'Grupo';

  @override
  String get noPermissionManageVideos =>
      'Você não tem permissão para gerenciar vídeos.';

  @override
  String get noVideosFound => 'Nenhum vídeo encontrado';

  @override
  String get deleteVideo => 'Excluir Vídeo';

  @override
  String deleteVideoConfirmation(Object title) {
    return 'Tem certeza que deseja excluir o vídeo \"$title\"?';
  }

  @override
  String get videoDeletedSuccessfully => 'Vídeo excluído com sucesso';

  @override
  String errorDeletingVideo(Object error) {
    return 'Erro ao excluir vídeo: $error';
  }

  @override
  String minutesAgo(Object minutes) {
    return 'Há $minutes minutos';
  }

  @override
  String hoursAgo(Object hours) {
    return 'Há $hours horas';
  }

  @override
  String get createAnnouncement => 'Criar Anúncio';

  @override
  String errorVerifyingPermissionAnnouncement(Object error) {
    return 'Erro ao verificar permissão: $error';
  }

  @override
  String get noPermissionCreateAnnouncements =>
      'Você não tem permissão para criar anúncios.';

  @override
  String errorSelectingImage(Object error) {
    return 'Erro ao selecionar imagem: $error';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get announcementCreatedSuccessfully => 'Anúncio criado com sucesso';

  @override
  String errorCreatingAnnouncement(Object error) {
    return 'Erro ao criar anúncio: $error';
  }

  @override
  String get addImage => 'Adicionar imagem';

  @override
  String get recommended16x9 => 'Recomendado: 16:9 (1920x1080)';

  @override
  String get announcementTitle => 'Título do Anúncio';

  @override
  String get enterClearConciseTitle => 'Digite um título claro e conciso';

  @override
  String get pleasEnterTitle => 'Por favor, digite um título';

  @override
  String get provideAnnouncementDetails => 'Forneça detalhes sobre o anúncio';

  @override
  String get pleaseEnterDescription => 'Por favor, insira uma descrição';

  @override
  String get announcementExpirationDate => 'Data do anúncio/expiração';

  @override
  String get optionalSelectDate => 'Opcional: Selecione uma data';

  @override
  String get pleaseSelectAnnouncementImage =>
      'Por favor, selecione uma imagem para o anúncio';

  @override
  String get publishAnnouncement => 'Publicar Anúncio';

  @override
  String get createEvent => 'Criar Evento';

  @override
  String get upcoming => 'Próximos';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get thisMonth => 'Este mês';

  @override
  String get noEventsFound => 'Nenhum evento encontrado';

  @override
  String get tryAnotherFilterOrCreateEvent =>
      'Tente outro filtro ou crie um novo evento';

  @override
  String get trySelectingAnotherFilter => 'Tente selecionar outro filtro';

  @override
  String get noLocation => 'Sem localização';

  @override
  String get tickets => 'Ingressos';

  @override
  String get seeDetails => 'Ver Detalhes';

  @override
  String get videoSections => 'Seções de Vídeos';

  @override
  String get reorderSections => 'Reordenar seções';

  @override
  String get saveOrder => 'Salvar ordem';

  @override
  String get dragSectionsToReorder => 'Arraste as seções para reordená-las';

  @override
  String get noSectionCreated => 'Nenhuma seção criada';

  @override
  String get createFirstSection => 'Criar Primeira Seção';

  @override
  String get dragToReorderPressWhenDone =>
      'Arraste para reordenar. Pressione o botão concluído quando terminar.';

  @override
  String get defaultSectionNotEditable => 'Seção padrão (não editável)';

  @override
  String get allVideos => 'Todos os vídeos';

  @override
  String get defaultSection => '• Seção padrão';

  @override
  String get editSection => 'Editar seção';

  @override
  String get newSection => 'Nova Seção';

  @override
  String get mostRecent => 'Mais recentes';

  @override
  String get mostPopular => 'Mais populares';

  @override
  String get custom => 'Personalizada';

  @override
  String get recentVideosCannotBeReordered =>
      'A seção \"Vídeos Recentes\" não pode ser reordenada';

  @override
  String get deleteVideoSection => 'Excluir Seção';

  @override
  String confirmDeleteSection(Object title) {
    return 'Tem certeza que deseja excluir a seção \"$title\"?';
  }

  @override
  String get sectionDeleted => 'Seção excluída';

  @override
  String get sendPushNotifications => 'Enviar Notificações Push';

  @override
  String errorVerifyingPermissionNotification(Object error) {
    return 'Erro ao verificar permissão: $error';
  }

  @override
  String get accessNotAuthorized => 'Acesso não autorizado';

  @override
  String get noPermissionSendNotifications =>
      'Você não tem permissão para enviar notificações push.';

  @override
  String get sendNotification => 'Enviar notificação';

  @override
  String get title => 'Título';

  @override
  String get message => 'Mensagem:';

  @override
  String get pleaseEnterMessage => 'Por favor insira uma mensagem';

  @override
  String get recipients => 'Destinatários';

  @override
  String get allMembers => 'Todos os membros';

  @override
  String get membersOfMinistry => 'Membros de um ministério';

  @override
  String get selectMinistry => 'Selecionar ministério';

  @override
  String get pleaseSelectMinistry => 'Por favor selecione um ministério';

  @override
  String selectMembers(Object selected, Object total) {
    return 'Selecionar membros ($selected/$total)';
  }

  @override
  String get selectAll => 'Selecionar Todos';

  @override
  String get deselectAll => 'Desmarcar todos';

  @override
  String get membersOfGroup => 'Membros de um grupo';

  @override
  String get selectGroup => 'Selecionar grupo';

  @override
  String get pleaseSelectGroup => 'Por favor selecione um grupo';

  @override
  String get receiveThisNotificationToo => 'Receber também esta notificação';

  @override
  String get sendNotificationButton => 'ENVIAR NOTIFICAÇÃO';

  @override
  String get noPermissionSendNotificationsSnack =>
      'Você não tem permissão para enviar notificações.';

  @override
  String get noUsersMatchCriteria =>
      'Não há usuários que atendam aos critérios selecionados';

  @override
  String errorSending(Object error) {
    return 'Erro ao enviar: $error';
  }

  @override
  String get notificationSentSuccessfully =>
      '✅ Notificação enviada com sucesso';

  @override
  String get notificationSentPartially => '⚠️ Notificação enviada parcialmente';

  @override
  String sentTo(Object count) {
    return 'Enviada para $count usuários';
  }

  @override
  String failedTo(Object count) {
    return 'Falhou para $count usuários';
  }

  @override
  String get noPermissionDeleteMinistries =>
      'Você não tem permissão para excluir ministérios';

  @override
  String confirmDeleteMinistry(Object name) {
    return 'Você tem certeza de que deseja excluir o ministério \"$name\"? Esta ação não pode ser desfeita.';
  }

  @override
  String errorDeletingMinistry(Object error) {
    return 'Erro ao excluir ministério: $error';
  }

  @override
  String get noPermissionDeleteGroups =>
      'Você não tem permissão para excluir grupos';

  @override
  String confirmDeleteGroup(Object name) {
    return 'Você tem certeza de que deseja excluir o grupo \"$name\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get kidsAdministration => 'Administração Kids';

  @override
  String get attendance => 'Presença';

  @override
  String get reload => 'Recarregar';

  @override
  String get attendanceChart => 'Gráfico de Assistência (pendente)';

  @override
  String get weeklyBirthdays => 'Aniversários da Semana';

  @override
  String get birthdayCarousel => 'Carrossel de Aniversários (pendente)';

  @override
  String get family => 'Família';

  @override
  String get visitor => 'Visitante';

  @override
  String get rooms => 'Salas';

  @override
  String get checkin => 'Check-in';

  @override
  String get absenceRegisteredSuccessfully => 'Ausência registrada com sucesso';

  @override
  String errorRegisteringAttendance(Object error) {
    return 'Erro ao registrar presença: $error';
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
  String get add => 'Adicionar';

  @override
  String get noMembersFound => 'Nenhum membro encontrado';

  @override
  String get confirmedStatus => 'Confirmado';

  @override
  String get presentStatus => 'Presente';

  @override
  String get absentStatus => 'Ausente';

  @override
  String errorSearchingUsers(Object error) {
    return 'Erro ao buscar usuários: $error';
  }

  @override
  String get participantAddedSuccessfully =>
      'Participante adicionado com sucesso';

  @override
  String errorAddingParticipant(Object error) {
    return 'Erro ao adicionar participante: $error';
  }

  @override
  String get addParticipant => 'Adicionar Participante';

  @override
  String get searchUserByName => 'Buscar usuário por nome';

  @override
  String get typeAtLeastTwoCharacters =>
      'Digite pelo menos 2 caracteres para buscar';

  @override
  String noResultsFound(Object query) {
    return 'Nenhum resultado encontrado para \"$query\"';
  }

  @override
  String get tryAnotherName => 'Tente com outro nome ou sobrenome';

  @override
  String get recentUsers => 'Usuários recentes:';

  @override
  String get createNewCult => 'Criar Novo Culto';

  @override
  String get cultName => 'Nome do Culto';

  @override
  String get startTime => 'Hora de início:';

  @override
  String get endTime => 'Hora de fim:';

  @override
  String get endTimeMustBeAfterStart =>
      'A hora de fim deve ser posterior à hora de início';

  @override
  String get pleaseEnterCultName => 'Por favor, insira um nome para o culto';

  @override
  String get noPermissionCreateLocations =>
      'Você não tem permissão para criar localizações';

  @override
  String get noCultsFound => 'Nenhum culto encontrado';

  @override
  String get createFirstCult => 'Criar Primeiro Culto';

  @override
  String get location => 'Localização';

  @override
  String get selectLocation => 'Selecionar localização';

  @override
  String get addNewLocation => 'Adicionar nova localização';

  @override
  String get locationName => 'Nome do local';

  @override
  String get street => 'Rua';

  @override
  String get complement => 'Complemento';

  @override
  String get neighborhood => 'Bairro';

  @override
  String get city => 'Cidade';

  @override
  String get state => 'Estado';

  @override
  String get postalCode => 'CEP';

  @override
  String get country => 'País';

  @override
  String get saveThisLocation => 'Salvar esta localização para uso futuro';

  @override
  String get createCult => 'Criar Culto';

  @override
  String get noUpcomingCults => 'Não há cultos próximos';

  @override
  String get noAvailableCults => 'Não há cultos disponíveis';

  @override
  String get nameCannotBeEmpty => 'O nome não pode ficar vazio';

  @override
  String documentsExistButCouldNotProcess(Object message) {
    return 'Existem documentos, mas não puderam ser processados. $message';
  }

  @override
  String get noPermissionCreateMinistries =>
      'Sem permissão para criar ministérios.';

  @override
  String get ministryCreatedSuccessfully => 'Ministério criado com sucesso!';

  @override
  String errorCreatingMinistry(Object error) {
    return 'Erro ao criar ministério: $error';
  }

  @override
  String get noPermissionCreateMinistriesLong =>
      'Você não tem permissão para criar ministérios.';

  @override
  String get ministryName => 'Nome do Ministério';

  @override
  String get enterMinistryName => 'Digite o nome do ministério';

  @override
  String get pleaseEnterMinistryName =>
      'Por favor, digite um nome para o ministério';

  @override
  String get ministryDescription => 'Descrição';

  @override
  String get describeMinistryPurpose =>
      'Descreva o propósito e atividades do ministério';

  @override
  String get administrators => 'Administradores';

  @override
  String get selectAdministrators => 'Selecionar Administradores';

  @override
  String get searchUsers => 'Buscar usuários...';

  @override
  String get noUsersFound => 'Não foram encontrados usuários';

  @override
  String get selectedAdministrators => 'Administradores selecionados:';

  @override
  String get noAdministratorsSelected => 'Nenhum administrador selecionado';

  @override
  String get creating => 'Criando...';

  @override
  String charactersRemaining(Object count) {
    return '$count caracteres restantes';
  }

  @override
  String get understood => 'Entendi';

  @override
  String get cancelConsultation => 'Cancelar Consulta';

  @override
  String get sureToCancel => 'Tem certeza que deseja cancelar esta consulta?';

  @override
  String get yesCancelConsultation => 'Sim, cancelar';

  @override
  String get consultationCancelledSuccessfully =>
      'Consulta cancelada com sucesso';

  @override
  String get myAppointments => 'Minhas Consultas';

  @override
  String get requestAppointment => 'Solicitar Consulta';

  @override
  String get pastorAvailability => 'Disponibilidade do Pastor';

  @override
  String get noAppointmentsScheduled => 'Nenhuma consulta agendada';

  @override
  String get scheduleFirstAppointment => 'Agende sua primeira consulta';

  @override
  String get scheduleAppointment => 'Agendar Consulta';

  @override
  String get cancelled => 'Canceladas';

  @override
  String get completed => 'Concluído';

  @override
  String get withPreposition => 'com';

  @override
  String get requestedOn => 'Solicitada em';

  @override
  String get scheduledFor => 'Agendada para';

  @override
  String reason(Object reason) {
    return 'Razão: $reason';
  }

  @override
  String get contactPastor => 'Contatar Pastor';

  @override
  String get cancelAppointment => 'Cancelar Consulta';

  @override
  String get noPermissionRespondPrivatePrayers =>
      'Você não tem permissão para responder orações privadas';

  @override
  String get noPermissionCreatePredefinedMessages =>
      'Você não tem permissão para criar mensagens predefinidas';

  @override
  String get noPermissionManagePrivatePrayers =>
      'Você não tem permissão para gerenciar orações privadas';

  @override
  String get prayerRequestAcceptedSuccessfully =>
      'Solicitação de oração aceita com sucesso';

  @override
  String get pendingPrayers => 'Orações Pendentes';

  @override
  String get acceptedPrayers => 'Orações Aceitas';

  @override
  String get rejectedPrayers => 'Orações Rejeitadas';

  @override
  String get noPendingPrayers => 'Nenhuma oração pendente';

  @override
  String get noAcceptedPrayers => 'Nenhuma oração aceita';

  @override
  String get noRejectedPrayers => 'Nenhuma oração rejeitada';

  @override
  String get requestedBy => 'Solicitada por';

  @override
  String get acceptPrayer => 'Aceitar Oração';

  @override
  String get rejectPrayer => 'Rejeitar Oração';

  @override
  String get respondToPrayer => 'Responder à Oração';

  @override
  String get viewResponse => 'Ver Resposta';

  @override
  String get predefinedMessages => 'Mensagens Predefinidas';

  @override
  String get createPredefinedMessage => 'Criar mensagem predefinida';

  @override
  String get prayerStats => 'Estatísticas de Orações';

  @override
  String get totalRequests => 'Total de Solicitações';

  @override
  String get acceptedRequests => 'Solicitações Aceitas';

  @override
  String get rejectedRequests => 'Solicitações Rejeitadas';

  @override
  String get responseRate => 'Taxa de Resposta';

  @override
  String get userInformation => 'Informação de Usuários';

  @override
  String get unauthorizedAccess => 'Acesso não autorizado';

  @override
  String get noPermissionViewUserInfo =>
      'Você não tem permissão para ver informação de usuários.';

  @override
  String get totalUsers => 'Total de Usuários';

  @override
  String get activeUsers => 'Usuários Ativos';

  @override
  String get inactiveUsers => 'Usuários Inativos';

  @override
  String get userDetails => 'Detalhes do Usuário';

  @override
  String get viewDetails => 'Ver Detalhes';

  @override
  String get lastActive => 'Última atividade';

  @override
  String get joinedOn => 'Entrou em';

  @override
  String role(Object role) {
    return 'Função: $role';
  }

  @override
  String get status => 'Status';

  @override
  String get inactive => 'Inativo';

  @override
  String get servicesStatistics => 'Estatísticas de Serviços';

  @override
  String get searchService => 'Buscar serviço...';

  @override
  String get users => 'Usuários';

  @override
  String get totalInvitations => 'Total de Convites';

  @override
  String get acceptedInvitations => 'Convites Aceitos';

  @override
  String get rejectedInvitations => 'Convites Rejeitados';

  @override
  String get totalAttendances => 'Total presenças';

  @override
  String get totalAbsences => 'Total ausências';

  @override
  String get acceptanceRate => 'Taxa de Aceitação';

  @override
  String get attendanceRate => 'Taxa de Presença';

  @override
  String get sortBy => 'Ordenar por:';

  @override
  String get invitations => 'Convites';

  @override
  String get acceptances => 'Aceitações';

  @override
  String get attendances => 'Presenças';

  @override
  String get ascending => 'Ascendente';

  @override
  String get descending => 'Descendente';

  @override
  String get dateFilter => 'Filtro de Data';

  @override
  String get startDate => 'Data inicial';

  @override
  String get endDate => 'Data final';

  @override
  String get applyFilter => 'Aplicar Filtro';

  @override
  String get clearFilter => 'Limpar filtro';

  @override
  String get noServicesFound => 'Não foram encontradas escalas';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get myCounseling => 'Minhas Consultas';

  @override
  String get cancelCounseling => 'Cancelar Consulta';

  @override
  String get confirmCancelCounseling =>
      'Tem certeza que deseja cancelar esta consulta?';

  @override
  String get yesCancelCounseling => 'Sim, cancelar';

  @override
  String get counselingCancelledSuccess => 'Consulta cancelada com sucesso';

  @override
  String get loadingPastorInfo => 'Carregando informações do pastor...';

  @override
  String get unknownPastor => 'Pastor desconhecido';

  @override
  String get pastor => 'Pastor';

  @override
  String get type => 'Tipo';

  @override
  String get contact => 'Contato';

  @override
  String get couldNotOpenPhone => 'Não foi possível abrir o telefone';

  @override
  String get call => 'Ligar';

  @override
  String get couldNotOpenWhatsApp => 'Não foi possível abrir o WhatsApp';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get address => 'Endereço';

  @override
  String get notConnected => 'Você não está conectado';

  @override
  String get noUpcomingAppointments => 'Você não tem consultas agendadas';

  @override
  String get noCancelledAppointments => 'Você não tem consultas canceladas';

  @override
  String get noCompletedAppointments => 'Não há agendamentos concluídos';

  @override
  String get noAppointmentsAvailable => 'Não há consultas disponíveis';

  @override
  String get viewRequests => 'Ver Solicitações';

  @override
  String get editCourse => 'Editar Curso';

  @override
  String get fillCourseInfo =>
      'Preencha as informações do curso para disponibilizá-lo aos alunos';

  @override
  String get courseTitle => 'Título do Curso';

  @override
  String get courseTitleHint => 'Ex: Fundamentos da Bíblia';

  @override
  String get titleRequired => 'O título é obrigatório';

  @override
  String get descriptionHint => 'Descreva o conteúdo e objetivos do curso...';

  @override
  String get descriptionRequired => 'A descrição é obrigatória';

  @override
  String get coverImage => 'Imagem de Capa';

  @override
  String get coverImageDescription =>
      'Esta imagem será exibida na página de detalhes do curso';

  @override
  String get tapToChange => 'Toque para alterar';

  @override
  String get recommendedSize => 'Tamanho recomendado: 1920x1080';

  @override
  String get categoryHint => 'Ex: Teologia, Discipulado, Liderança';

  @override
  String get categoryRequired => 'A categoria é obrigatória';

  @override
  String get instructorName => 'Nome do Instrutor';

  @override
  String get instructorNameHint => 'Nome completo do instrutor';

  @override
  String get instructorRequired => 'O nome do instrutor é obrigatório';

  @override
  String get courseStatus => 'Status do Curso';

  @override
  String get allowComments => 'Permitir Comentários';

  @override
  String get studentsCanComment => 'Os alunos poderão comentar nas lições';

  @override
  String get updateCourse => 'Atualizar Curso';

  @override
  String get createCourse => 'Criar Curso';

  @override
  String get courseDurationNote =>
      'A duração total do curso é calculada automaticamente com base na duração das lições.';

  @override
  String get manageModulesAndLessons => 'Gerenciar Módulos e Lições';

  @override
  String get courseUpdatedSuccess => 'Curso atualizado com sucesso!';

  @override
  String get courseCreatedSuccess => 'Curso criado com sucesso!';

  @override
  String get addModules => 'Adicionar Módulos';

  @override
  String get addModulesNow => 'Deseja adicionar módulos ao curso agora?';

  @override
  String get later => 'Mais tarde';

  @override
  String get yesAddNow => 'Sim, adicionar agora';

  @override
  String get uploadingImages => 'Enviando imagens...';

  @override
  String get savingCourse => 'Salvando curso...';

  @override
  String get addModule => 'Adicionar Módulo';

  @override
  String moduleTitle(Object title) {
    return 'Módulo: $title';
  }

  @override
  String get moduleTitleHint => 'Nome do módulo';

  @override
  String get moduleTitleRequired => 'O título do módulo é obrigatório';

  @override
  String get summary => 'Resumo';

  @override
  String get summaryOptional => 'Resumo (Opcional)';

  @override
  String get summaryHint => 'Breve descrição do módulo...';

  @override
  String get moduleCreatedSuccess => 'Módulo criado com sucesso!';

  @override
  String get addLesson => 'Adicionar Lição';

  @override
  String get lessonTitle => 'Título da Lição';

  @override
  String get lessonTitleHint => 'Nome da lição';

  @override
  String get lessonTitleRequired => 'O título da lição é obrigatório';

  @override
  String get lessonDescription => 'Descrição da Lição';

  @override
  String get lessonDescriptionHint => 'Descreva o conteúdo desta lição...';

  @override
  String get lessonDescriptionRequired => 'A descrição da lição é obrigatória';

  @override
  String get durationHint => 'Duração em minutos';

  @override
  String get durationRequired => 'A duração é obrigatória';

  @override
  String get durationMustBeNumber => 'A duração deve ser um número válido';

  @override
  String get videoUrl => 'URL do Vídeo (YouTube ou Vimeo)';

  @override
  String get videoUrlHint => 'URL do YouTube ou Vimeo';

  @override
  String get videoUrlRequired => 'A URL do vídeo é obrigatória';

  @override
  String get lessonCreatedSuccess => 'Lição criada com sucesso!';

  @override
  String get noModulesYet => 'Ainda não há módulos neste curso.';

  @override
  String get tapAddToCreateFirst =>
      'Toque em \'Adicionar Módulo\' para criar o primeiro.';

  @override
  String get noLessonsInModule => 'Não há lições neste módulo ainda.';

  @override
  String get tapToAddLesson => 'Toque em + para adicionar uma lição.';

  @override
  String get min => 'min';

  @override
  String get video => 'Vídeo';

  @override
  String get manageMaterials => 'Gerenciar Materiais';

  @override
  String get deleteModule => 'Excluir Módulo';

  @override
  String get confirmDeleteModule =>
      'Tem certeza que deseja excluir este módulo?';

  @override
  String get thisActionCannotBeUndone => 'Esta ação não pode ser desfeita.';

  @override
  String get yesDelete => 'Sim, excluir';

  @override
  String get moduleDeletedSuccess => 'Módulo excluído com sucesso';

  @override
  String get deleteLesson => 'Excluir Lição';

  @override
  String get confirmDeleteLesson =>
      'Tem certeza que deseja excluir esta lição?';

  @override
  String get lessonDeletedSuccess => 'Lição excluída com sucesso';

  @override
  String get reorderModules => 'Reordenar Módulos';

  @override
  String get reorderLessons => 'Reordenar Lições';

  @override
  String get done => 'Concluído';

  @override
  String get dragToReorder => 'Arraste para reordenar';

  @override
  String get orderUpdatedSuccess => 'Ordem atualizada com sucesso!';

  @override
  String get loadingCourse => 'Carregando curso...';

  @override
  String get savingModule => 'Salvando módulo...';

  @override
  String get savingLesson => 'Salvando lição...';

  @override
  String errorLoadingFields(Object error) {
    return 'Erro ao carregar os campos: $error';
  }

  @override
  String get required => 'Obrigatório';

  @override
  String get fieldName => 'Nome do Campo';

  @override
  String get pleaseEnterName => 'Por favor, insira um nome';

  @override
  String get selectFieldType => 'Seleção';

  @override
  String get newOption => 'Nova Opção';

  @override
  String get enterOption => 'Digite uma opção...';

  @override
  String get optionAlreadyAdded => 'Esta opção já foi adicionada.';

  @override
  String get noOptionsAddedYet => 'Nenhuma opção adicionada ainda.';

  @override
  String get usersMustFillField => 'Os usuários devem preencher este campo';

  @override
  String get copyToPreviousWeek => 'Copiar para a semana anterior';

  @override
  String get monday => 'Segunda-feira';

  @override
  String get tuesday => 'Terça-feira';

  @override
  String get wednesday => 'Quarta-feira';

  @override
  String get thursday => 'Quinta-feira';

  @override
  String get friday => 'Sexta-feira';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get unavailable => 'Indisponível';

  @override
  String get available => 'Disponível';

  @override
  String timeSlots(Object count) {
    return '$count faixas horárias';
  }

  @override
  String get sessionDuration => 'Duração da Sessão';

  @override
  String get breakBetweenSessions => 'Intervalo entre Sessões';

  @override
  String get appointmentTypes => 'Tipos de Consulta';

  @override
  String get onlineAppointments => 'Consultas Online';

  @override
  String get inPersonAppointments => 'Consultas Presenciais';

  @override
  String get locationHint => 'Endereço para consultas presenciais';

  @override
  String get globalSettings => 'Configurações Globais';

  @override
  String get settingsSavedSuccessfully => 'Configurações salvas com sucesso';

  @override
  String get notAvailableForConsultations => 'Não disponível para consultas';

  @override
  String get configureAvailabilityForThisDay =>
      'Configure a disponibilidade para este dia';

  @override
  String get thisDayMarkedUnavailable =>
      'Este dia está marcado como indisponível para consultas';

  @override
  String get unavailableDay => 'Indisponível';

  @override
  String get thisDayMarkedAvailable =>
      'Este dia está marcado como disponível para consultas';

  @override
  String get timeSlotsSingular => 'Faixas de Horário';

  @override
  String timeSlot(Object number) {
    return 'Faixa $number';
  }

  @override
  String get consultationType => 'Tipo de consulta:';

  @override
  String get onlineConsultation => 'Online';

  @override
  String get inPersonConsultation => 'Presencial';

  @override
  String get addTimeSlot => 'Adicionar Faixa de Horário';

  @override
  String get searchUser => 'Buscar usuário';

  @override
  String get enterNameOrEmail => 'Digite nome ou email';

  @override
  String get noPermissionAccessThisPage =>
      'Você não tem permissão para acessar esta página';

  @override
  String get noPermissionChangeRoles =>
      'Você não tem permissão para alterar papéis';

  @override
  String get selectRoleToAssign =>
      'Selecione o papel para atribuir ao usuário:';

  @override
  String permissionsAssigned(Object count) {
    return '$count permissões atribuídas';
  }

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get deleteRole => 'Excluir função';

  @override
  String get createNewRole => 'Criar Novo Papel';

  @override
  String get failedDeleteRole => 'Falha ao excluir papel';

  @override
  String get editModule => 'Editar Módulo';

  @override
  String get moduleUpdatedSuccessfully => 'Módulo atualizado com sucesso';

  @override
  String sureDeleteModule(Object title) {
    return 'Tem certeza que deseja excluir o módulo \"$title\"?\n\nEsta ação não pode ser desfeita e excluirá todas as lições associadas.';
  }

  @override
  String get moduleDeletedSuccessfully => 'Módulo excluído com sucesso';

  @override
  String get moduleNotFound => 'Módulo não encontrado';

  @override
  String get lessonAddedSuccessfully => 'Lição adicionada com sucesso';

  @override
  String get optionalDescription => 'Descrição (Opcional)';

  @override
  String get durationMinutes => 'Duração (minutos)';

  @override
  String get videoUrlExample => 'Ex: https://www.youtube.com/watch?v=...';

  @override
  String get manageModules => 'Gerenciar Módulos';

  @override
  String get finishReorder => 'Finalizar';

  @override
  String orderLessons(Object count, Object order) {
    return 'Ordem: $order • $count lições';
  }

  @override
  String get editLesson => 'Editar Lição';

  @override
  String get lessonUpdatedSuccessfully => 'Lição atualizada com sucesso';

  @override
  String sureDeleteLesson(Object title) {
    return 'Tem certeza que deseja excluir a lição \"$title\"?\n\nEsta ação não pode ser desfeita.';
  }

  @override
  String get lessonDeletedSuccessfully => 'Lição excluída com sucesso';

  @override
  String get moduleOrderUpdated => 'Ordem dos módulos atualizada';

  @override
  String get lessonOrderUpdated => 'Ordem das lições atualizada';

  @override
  String durationVideo(Object duration) {
    return '$duration • Vídeo';
  }

  @override
  String durationVideoMaterials(Object count, Object duration) {
    return '$duration • Vídeo • Materiais: $count';
  }

  @override
  String get guardar => 'Salvar';

  @override
  String sureDeleteModuleWithTitle(Object title) {
    return 'Tem certeza que deseja excluir o módulo \"$title\"?\n\nEsta ação não pode ser desfeita e excluirá todas as lições associadas.';
  }

  @override
  String sureDeleteLessonWithTitle(Object title) {
    return 'Tem certeza que deseja excluir a lição \"$title\"?\n\nEsta ação não pode ser desfeita.';
  }

  @override
  String get moduleTitleLabel => 'Título do Módulo';

  @override
  String get createNewProfile => 'Criar Novo Perfil';

  @override
  String get roleName => 'Nome do Papel';

  @override
  String get roleNameHint => 'Ex: Líder de Grupo, Editor';

  @override
  String get roleNameRequired => 'O nome do papel é obrigatório.';

  @override
  String get optionalDescriptionRole => 'Descrição (Opcional)';

  @override
  String get roleDescriptionHint => 'Responsabilidades deste papel...';

  @override
  String get permissions => 'Permissões';

  @override
  String get saving => 'Salvando...';

  @override
  String get createRole => 'Criar Papel';

  @override
  String get roleSavedSuccessfully => 'Papel salvo com sucesso!';

  @override
  String get errorSavingRole => 'Erro ao salvar papel.';

  @override
  String get generalAdministration => 'Administração Geral';

  @override
  String get homeConfiguration => 'Configuração Home';

  @override
  String get contentAndEvents => 'Conteúdo e Eventos';

  @override
  String get community => 'Comunidade';

  @override
  String get counselingAndPrayer => 'Aconselhamento e Oração';

  @override
  String get reportsAndStatistics => 'Relatórios e Estatísticas';

  @override
  String get myKids => 'MyKids (Gestão Infantil)';

  @override
  String get others => 'Outros';

  @override
  String get assignUserRoles => 'Atribuir Papéis a Usuários';

  @override
  String get manageUsers => 'Gerenciar Usuários';

  @override
  String get viewUserList => 'Ver Lista de Usuários';

  @override
  String get viewUserDetails => 'Ver Detalhes de Usuários';

  @override
  String get manageHomeSections => 'Gerenciar Seções da Tela Inicial';

  @override
  String get manageCults => 'Gerenciar Cultos';

  @override
  String get manageEventTickets => 'Gerenciar Ingressos de Eventos';

  @override
  String get createEvents => 'Criar Eventos';

  @override
  String get deleteEvents => 'Excluir Eventos';

  @override
  String get manageCourses => 'Gerenciar Cursos';

  @override
  String get createGroup => 'Criar Grupo';

  @override
  String get manageCounselingAvailability =>
      'Gerenciar Disponibilidade para Aconselhamento';

  @override
  String get manageCounselingRequests =>
      'Gerenciar Solicitações de Aconselhamento';

  @override
  String get managePrivatePrayers => 'Gerenciar Orações Privadas';

  @override
  String get assignCultToPrayer => 'Atribuir Culto à Oração';

  @override
  String get viewMinistryStats => 'Ver Estatísticas de Ministérios';

  @override
  String get viewGroupStats => 'Ver Estatísticas de Grupos';

  @override
  String get viewScheduleStats => 'Ver Estatísticas de Escalas';

  @override
  String get viewCourseStats => 'Ver Estatísticas de Cursos';

  @override
  String get viewChurchStatistics => 'Ver Estatísticas da Igreja';

  @override
  String get viewCultStats => 'Ver Estatísticas de Cultos';

  @override
  String get viewWorkStats => 'Ver Estatísticas de Trabalho';

  @override
  String get manageCheckinRooms => 'Gerenciar Salas e Check-in';

  @override
  String get manageDonationsConfig => 'Configurar Doações';

  @override
  String get manageLivestreamConfig => 'Configurar Transmissões ao Vivo';

  @override
  String lessonsCount(Object count) {
    return '$count lições';
  }

  @override
  String get averageProgress => 'Progresso Médio';

  @override
  String get averageLessonsCompleted => 'Lições Médias Completadas:';

  @override
  String get globalAverageProgress => 'Progresso Médio Global:';

  @override
  String get highestProgress => 'Maior Progresso';

  @override
  String get progressPercentage => 'Progresso (%)';

  @override
  String get averageLessons => 'Lições Médias';

  @override
  String get totalLessonsHeader => 'Total Lições';

  @override
  String get allModuleLessonsWillBeDeleted =>
      'Todas as lições deste módulo também serão excluídas. Esta ação não pode ser desfeita.';

  @override
  String get groupName => 'Nome do Grupo';

  @override
  String get enterGroupName => 'Digite o nome do grupo';

  @override
  String get pleaseEnterGroupName => 'Por favor, digite um nome';

  @override
  String get groupDescription => 'Descrição';

  @override
  String get enterGroupDescription => 'Digite a descrição do grupo';

  @override
  String get administratorsCanManage =>
      'Os administradores podem gerenciar o grupo, seus membros e eventos.';

  @override
  String get addAdministrators => 'Adicionar administradores';

  @override
  String administratorsSelected(Object count) {
    return '$count administradores selecionados';
  }

  @override
  String get unknownUser => 'Usuário desconhecido';

  @override
  String get autoMemberInfo =>
      'Ao criar um grupo, você será automaticamente membro e administrador. Você poderá personalizar a imagem e outras configurações após a criação.';

  @override
  String get groupCreatedSuccessfully => 'Grupo criado com sucesso!';

  @override
  String errorCreatingGroup(Object error) {
    return 'Erro ao criar grupo: $error';
  }

  @override
  String get noPermissionCreateGroups => 'Sem permissão para criar grupos.';

  @override
  String get noPermissionCreateGroupsLong =>
      'Você não tem permissão para criar grupos.';

  @override
  String get noUsersAvailable => 'Nenhum usuário disponível';

  @override
  String get enterMinistryDescription => 'Digite a descrição do ministério';

  @override
  String get pleaseEnterMinistryDescription =>
      'Por favor, digite uma descrição';

  @override
  String get administratorsCanManageMinistry =>
      'Os administradores podem gerenciar o ministério, seus membros e eventos.';

  @override
  String get autoMemberMinistryInfo =>
      'Ao criar um ministério, você será automaticamente membro e administrador. Você poderá personalizar a imagem e outras configurações após a criação.';

  @override
  String get textFieldType => 'Texto';

  @override
  String get numberFieldType => 'Número';

  @override
  String get dateFieldType => 'Data';

  @override
  String get emailFieldType => 'Email';

  @override
  String get phoneFieldType => 'Telefone';

  @override
  String get selectionOptions => 'Opções de Seleção';

  @override
  String get noResultsFoundSimple => 'Nenhum resultado encontrado';

  @override
  String get progress => 'Progresso';

  @override
  String get detailedStatistics => 'Estatísticas Detalhadas';

  @override
  String get enrollments => 'Inscrições';

  @override
  String get completion => 'Finalização';

  @override
  String get completionMilestones => 'Hitos de Conclusão';

  @override
  String get filterByEnrollmentDate => 'Filtrar por Data de Inscrição';

  @override
  String get clear => 'Limpar';

  @override
  String get lessThan1Min => 'Menos de 1 min';

  @override
  String get totalEnrolledPeriod => 'Total de Inscritos (período):';

  @override
  String get reached25Percent => 'Alcançaram 25%:';

  @override
  String get reached50Percent => 'Alcançaram 50%:';

  @override
  String get reached75Percent => 'Alcançaram 75%:';

  @override
  String get reached90Percent => 'Alcançaram 90%:';

  @override
  String get completed100Percent => 'Completaram 100%:';

  @override
  String get counselingRequestsTitle => 'Solicitações de Aconselhamento';

  @override
  String get noPermissionManageCounselingRequests =>
      'Você não tem permissão para gerenciar solicitações de aconselhamento';

  @override
  String get appointmentConfirmed => 'Agendamento confirmado';

  @override
  String get appointmentCancelled => 'Agendamento cancelado';

  @override
  String get appointmentCompleted => 'Agendamento concluído';

  @override
  String get errorLabel => 'Erro:';

  @override
  String get noPendingRequests => 'Não há solicitações pendentes';

  @override
  String get noConfirmedAppointments => 'Não há agendamentos confirmados';

  @override
  String get loadingUser => 'Carregando usuário...';

  @override
  String get callTooltip => 'Ligar';

  @override
  String get whatsAppTooltip => 'WhatsApp';

  @override
  String get reasonLabel => 'Motivo:';

  @override
  String get noReasonSpecified => 'Nenhum motivo especificado';

  @override
  String get complete => 'Concluir';

  @override
  String appointmentStatus(Object status) {
    return 'Agendamento $status';
  }

  @override
  String get myPrivatePrayers => 'Minhas Orações Privadas';

  @override
  String get refresh => 'Atualizar';

  @override
  String get noApprovedPrayers => 'Nenhuma oração aprovada';

  @override
  String get noAnsweredPrayers => 'Nenhuma oração respondida';

  @override
  String get noPrayers => 'Nenhuma oração';

  @override
  String get allPrayerRequestsAttended =>
      'Todos os seus pedidos de oração foram atendidos';

  @override
  String get noApprovedPrayersWithoutResponse =>
      'Nenhuma oração foi aprovada sem resposta';

  @override
  String get noResponsesFromPastors =>
      'Você ainda não recebeu respostas dos pastores';

  @override
  String get requestPrivatePrayerFromPastors =>
      'Solicite oração privada aos pastores';

  @override
  String get approved => 'Aprovadas';

  @override
  String get answered => 'Respondidas';

  @override
  String get requestPrayer => 'Pedir oração';

  @override
  String errorLoading(Object error) {
    return 'Erro ao carregar: $error';
  }

  @override
  String loadingError(Object error, Object tabIndex) {
    return 'Erro carregando mais orações para tab $tabIndex: $error';
  }

  @override
  String get privatePrayersTitle => 'Orações Privadas';

  @override
  String get errorAcceptingRequest => 'Erro ao aceitar a solicitação';

  @override
  String errorAcceptingRequestWithDetails(Object error) {
    return 'Erro ao aceitar a solicitação: $error';
  }

  @override
  String get loadingEllipsis => 'Carregando...';

  @override
  String get responded => 'Respondido';

  @override
  String get requestLabel => 'Solicitação:';

  @override
  String get yourResponse => 'Sua resposta:';

  @override
  String respondedOn(Object date) {
    return 'Respondido em $date';
  }

  @override
  String get acceptAction => 'Aceitar';

  @override
  String get respondAction => 'Responder';

  @override
  String get total => 'Total';

  @override
  String get prayersOverview => 'Visão Geral das Orações';

  @override
  String get noPendingPrayersMessage => 'Não há orações pendentes';

  @override
  String get allRequestsAttended => 'Todas as solicitações foram atendidas';

  @override
  String get noApprovedPrayersWithoutResponseMessage =>
      'Não há orações aprovadas sem resposta';

  @override
  String get acceptRequestsToRespond =>
      'Aceite solicitações para responder aos irmãos';

  @override
  String get noAnsweredPrayersMessage => 'Você não respondeu a nenhuma oração';

  @override
  String get responsesWillAppearHere => 'Suas respostas aparecerão aqui';

  @override
  String get groupStatisticsTitle => 'Estatísticas de Grupos';

  @override
  String get members => 'Membros';

  @override
  String get history => 'Histórico';

  @override
  String get noPermissionViewGroupStats =>
      'Você não tem permissão para visualizar estatísticas de grupos';

  @override
  String get filterByDate => 'Filtrar por Data';

  @override
  String get initialDate => 'Data inicial';

  @override
  String get finalDate => 'Data final';

  @override
  String get totalUniqueMembers => 'Total de Membros Únicos';

  @override
  String get creationDate => 'Data de criação';

  @override
  String memberCount(Object count) {
    return '$count membros';
  }

  @override
  String errorLoadingMembers(Object error) {
    return 'Erro ao carregar membros: $error';
  }

  @override
  String get noMembersInGroup => 'Não há membros neste grupo';

  @override
  String get attendancePercentage => '% Presença';

  @override
  String get eventsLabel => 'Eventos';

  @override
  String get admin => 'Admin';

  @override
  String get eventsAttended => 'Eventos Assistidos';

  @override
  String get ministryStatisticsTitle => 'Estatísticas de Ministérios';

  @override
  String get noPermissionViewMinistryStats =>
      'Você não tem permissão para visualizar estatísticas de ministérios';

  @override
  String get noMembersInMinistry => 'Não há membros neste ministério';

  @override
  String get noHistoryToShow => 'Não há histórico de membros para mostrar';

  @override
  String recordsFound(Object count) {
    return 'Registros encontrados: $count';
  }

  @override
  String get exits => 'Saídas';

  @override
  String get noHistoricalRecords =>
      'Não há registros históricos para este grupo';

  @override
  String noRecordsOf(Object filterName) {
    return 'Não há registros de $filterName';
  }

  @override
  String get currentMembers => 'Membros atuais';

  @override
  String get totalEntries => 'Total de entradas';

  @override
  String get totalExits => 'Total de saídas';

  @override
  String entriesIn(Object groupName) {
    return 'Entradas em $groupName';
  }

  @override
  String get addedByAdmin => 'Adicionados por admin';

  @override
  String get byRequest => 'Por solicitação';

  @override
  String get close => 'Fechar';

  @override
  String exitsFrom(Object groupName) {
    return 'Saídas de $groupName';
  }

  @override
  String get removedByAdmin => 'Removidos por admin';

  @override
  String get voluntaryExits => 'Saídas voluntárias';

  @override
  String get exitedStatus => 'Saiu';

  @override
  String get unknownStatus => 'Desconhecido';

  @override
  String get unknownDate => 'Data desconhecida';

  @override
  String get addedBy => 'Adicionado por:';

  @override
  String get administrator => 'Administrador';

  @override
  String get mode => 'Modo:';

  @override
  String get requestAccepted => 'Solicitação aceita';

  @override
  String get acceptedBy => 'Aceito por:';

  @override
  String get rejectedBy => 'Rejeitado por:';

  @override
  String get exitType => 'Tipo de saída:';

  @override
  String get voluntary => 'Voluntária';

  @override
  String get removed => 'Removido';

  @override
  String get removedBy => 'Removido por:';

  @override
  String get exitReason => 'Motivo de saída:';

  @override
  String get noEventsToShow => 'Não há eventos para mostrar';

  @override
  String eventsFound(Object count) {
    return 'Eventos encontrados: $count';
  }

  @override
  String get unknownMinistry => 'Ministério desconhecido';

  @override
  String eventsInPeriod(Object count) {
    return '$count eventos no período';
  }

  @override
  String event(Object eventName) {
    return 'Evento: $eventName';
  }

  @override
  String get locationNotInformed => 'Local não informado';

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
    return 'Assistentes: $count';
  }

  @override
  String noEventsFor(Object date) {
    return 'Não há eventos para $date';
  }

  @override
  String get loadingUsers => 'Carregando usuários...';

  @override
  String get registeredUsers => 'Usuários Registrados';

  @override
  String get confirmedAttendees => 'Asistentes Confirmados';

  @override
  String get noUsersToShow => 'Não há usuários para mostrar';

  @override
  String get noRecordsInSelectedDates =>
      'Não há registros nas datas selecionadas';

  @override
  String get noEventsInSelectedDates => 'Não há eventos nas datas selecionadas';

  @override
  String recordsInPeriod(Object count) {
    return '$count registros no período';
  }

  @override
  String get scaleStatisticsTitle => 'Estatísticas de Escalas';

  @override
  String get noPermissionViewScaleStats =>
      'Você não tem permissão para visualizar estatísticas de escalas.';

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
      'Nenhum culto disponível para esta escala';

  @override
  String get courseStatisticsTitle => 'Estatísticas de Cursos';

  @override
  String get noPermissionViewCourseStats =>
      'Você não tem permissão para visualizar estatísticas de cursos.';

  @override
  String get noStatisticsAvailable => 'Nenhuma estatística disponível.';

  @override
  String errorLoadingStatistics(Object error) {
    return 'Erro ao carregar estatísticas: $error';
  }

  @override
  String get top3CoursesEnrolled => 'Top 3 Cursos (Inscritos):';

  @override
  String get noCourseToShow => 'Nenhum curso para mostrar.';

  @override
  String get detailsScreenNotImplemented =>
      'Tela de detalhes ainda não implementada.';

  @override
  String get enrollmentStatisticsTitle => 'Estatísticas de Inscrições';

  @override
  String get progressStatisticsTitle => 'Estatísticas de Progresso';

  @override
  String get completionStatisticsTitle => 'Estatísticas de Finalização';

  @override
  String get milestoneStatisticsTitle => 'Estatísticas de Marcos';

  @override
  String get searchCourses => 'Buscar cursos...';

  @override
  String get totalEnrollments => 'Total de Inscrições:';

  @override
  String get averageEnrollmentsPerCourse => 'Média de Inscrições por Curso';

  @override
  String get courseWithMostEnrollments => 'Curso com Mais Inscrições';

  @override
  String get courseWithFewestEnrollments => 'Curso com Menos Inscrições';

  @override
  String get enrollmentsOverTime => 'Inscrições ao Longo do Tempo';

  @override
  String get enrollmentDate => 'Data de Inscrição';

  @override
  String get globalAverageTime => 'Tempo Médio Global:';

  @override
  String get fastestCompletion => 'Conclusão Mais Rápida:';

  @override
  String get slowestCompletion => 'Conclusão Mais Lenta:';

  @override
  String get completionTime => 'Tempo de Finalização';

  @override
  String get completionRate => 'Taxa de Conclusão';

  @override
  String get reach25Percent => 'Alcançam 25% (Média):';

  @override
  String get reach50Percent => 'Alcançam 50% (Média):';

  @override
  String get reach75Percent => 'Alcançam 75% (Média):';

  @override
  String get reach90Percent => 'Alcançam 90% (Média):';

  @override
  String get complete100Percent => 'Completam 100%:';

  @override
  String get milestonePercentage => 'Porcentagem de Marco';

  @override
  String get studentsReached => 'Estudantes que Alcançaram';

  @override
  String get userNotFound => 'Usuário não encontrado';

  @override
  String get servicesPerformed => 'Serviços Realizados';

  @override
  String get noConfirmedServicesInMinistry =>
      'Não realizou serviços confirmados neste ministério';

  @override
  String service(Object serviceName) {
    return 'Serviço: $serviceName';
  }

  @override
  String assignedBy(Object pastorName) {
    return 'Designado por: $pastorName';
  }

  @override
  String get notAttendedMinistryEvents =>
      'Não assistiu a eventos deste ministério';

  @override
  String get notAttendedGroupEvents => 'Não assistiu a eventos deste grupo';

  @override
  String get churchStatisticsTitle => 'Estatísticas da Igreja';

  @override
  String get dataNotAvailable => 'Dados não disponíveis';

  @override
  String get requestApproved => 'Solicitação aprovada';

  @override
  String attendees(Object count) {
    return 'Asistentes: $count';
  }

  @override
  String get userNotInAnyGroup => 'O usuário não pertence a nenhum Connect';

  @override
  String get generalStatistics => 'Estatísticas Gerais';

  @override
  String get totalServicesPerformed => 'Total de serviços realizados';

  @override
  String get ministryEventsAttended => 'Eventos de ministério assistidos';

  @override
  String get groupEventsAttended => 'Eventos de grupo assistidos';

  @override
  String get userNotInAnyMinistry =>
      'O usuário não pertence a nenhum ministério';

  @override
  String get statusConfirmed => 'Status: Confirmado';

  @override
  String get statusPresent => 'Status: Presente';

  @override
  String get notAvailable => 'N/D';

  @override
  String get allMinistries => 'Todos os Ministérios';

  @override
  String get serviceWithoutName => 'Serviço sem nome';

  @override
  String errorLoadingUserStats(Object error) {
    return 'Erro ao carregar estatísticas de usuários: $error';
  }

  @override
  String errorLoadingStats(Object error) {
    return 'Erro ao carregar estatísticas: $error';
  }

  @override
  String get serviceName => 'Nome do serviço';

  @override
  String get serviceNameHint => 'Ex: Culto Dominical';

  @override
  String get scales => 'Escalas';

  @override
  String get noServiceFound => 'Nenhum serviço encontrado';

  @override
  String get tryAnotherFilter => 'Tente com outro filtro de busca';

  @override
  String created(Object date) {
    return 'Criado: $date';
  }

  @override
  String get invitesSent => 'Convites enviados';

  @override
  String get globalSummary => 'Resumo Global';

  @override
  String get absences => 'Ausências';

  @override
  String get invites => 'Convites';

  @override
  String get invitesAccepted => 'Convites aceitos';

  @override
  String get invitesRejected => 'Convites rejeitados';

  @override
  String get finished => 'Finalizado';

  @override
  String errorLoadingCults(Object error) {
    return 'Erro ao carregar cultos: $error';
  }

  @override
  String cultsCount(Object count) {
    return '$count cultos';
  }

  @override
  String get userList => 'Lista de usuários';

  @override
  String get generalSummary => 'Resumo Geral';

  @override
  String get enrollmentSummary => 'Resumo de Inscrições';

  @override
  String get progressSummary => 'Resumo Geral de Progresso';

  @override
  String get completionSummary => 'Resumo Geral de Finalização';

  @override
  String get milestoneSummary => 'Resumo Geral de Hitos';

  @override
  String get coursesWithEnrollments => 'Cursos com Inscrições:';

  @override
  String get globalCompletionRate => 'Taxa de Conclusão Global:';

  @override
  String get reach100Percent => 'Alcançam 100% (Média):';

  @override
  String get highestCompletionRate => 'Maior Taxa de Conclusão:';

  @override
  String get enrolled => 'Inscritos';

  @override
  String get averageTime => 'Tempo Médio';

  @override
  String get progressPercent => 'Progresso (%)';

  @override
  String get moreThan1Min => 'Mais de 1 min';

  @override
  String get searchCourse => 'Buscar curso...';

  @override
  String errorLoadingCourseStats(Object error) {
    return 'Erro ao carregar estatísticas: $error';
  }

  @override
  String get noStatsAvailable =>
      'Nenhuma estatística disponível para este curso.';

  @override
  String get lowestProgress => 'Menor Progresso';

  @override
  String get courseRanking => 'Ranking de Cursos';

  @override
  String get enterNameSurnameEmail => 'Digite nome, sobrenome ou email';

  @override
  String get totalRegisteredUsers => 'Total de Usuários Inscritos';

  @override
  String get genderDistribution => 'Distribuição por Gênero';

  @override
  String get ageDistribution => 'Distribuição por Idade';

  @override
  String get masculine => 'Masculino';

  @override
  String get feminine => 'Feminino';

  @override
  String get notInformed => 'Não informado';

  @override
  String get years => 'anos';

  @override
  String get ageNotInformed => 'Idade não informada';

  @override
  String get usersInMinistries => 'Usuários em Ministérios';

  @override
  String get usersInConnects => 'Usuários em Connects';

  @override
  String get usersInCourses => 'Usuários em Cursos';

  @override
  String ofUsers(Object total) {
    return 'de $total usuários';
  }

  @override
  String get noPermissionViewStatistics =>
      'Você não tem permissão para visualizar estas estatísticas.';

  @override
  String errorLoadingCultsColon(Object error) {
    return 'Erro ao carregar os cultos: $error';
  }

  @override
  String get tryAgain => 'Tentar novamente';

  @override
  String get saveLocationForFuture => 'Salvar esta localização para uso futuro';

  @override
  String get noSavedLocations =>
      'Não há localizações salvas. Por favor, insira uma nova localização abaixo.';

  @override
  String get selectExistingLocation => 'Selecionar localização existente';

  @override
  String get chooseLocation => 'Escolha uma localização';

  @override
  String get enterNewLocation => 'Informar nova localização';

  @override
  String get createNewLocation => 'Criar nova localização';

  @override
  String get timeSlotsTab => 'Faixas Horárias';

  @override
  String get music => 'Músicas';

  @override
  String get createTimeSlot => 'Criar faixa horária';

  @override
  String get newSchedule => 'Novo Horário';

  @override
  String get scheduleName => 'Nome do horário';

  @override
  String get startHour => 'Hora de início';

  @override
  String get endHour => 'Hora de término';

  @override
  String get endTimeMustBeAfterStartTime =>
      'A hora de término deve ser posterior à hora de início';

  @override
  String get scheduleColor => 'Cor do horário';

  @override
  String get scheduleCreatedSuccessfully => 'Horário criado com sucesso';

  @override
  String errorCreatingSchedule(Object error) {
    return 'Erro ao criar horário: $error';
  }

  @override
  String get createSchedule => 'Criar Horário';

  @override
  String get noSongsAssignedToCult => 'Não há músicas atribuídas a este culto';

  @override
  String get addMusic => 'Adicionar Música';

  @override
  String errorReorderingSongs(Object error) {
    return 'Erro ao reordenar músicas: $error';
  }

  @override
  String get files => 'arquivos';

  @override
  String get addSongToCult => 'Adicionar Música ao Culto';

  @override
  String get songName => 'Nome da Música';

  @override
  String get minutesLabel => 'Minutos';

  @override
  String get secondsLabel => 'Segundos';

  @override
  String get songAddedSuccessfully => 'Música adicionada com sucesso';

  @override
  String errorAddingSong(Object error) {
    return 'Erro ao adicionar música: $error';
  }

  @override
  String get editSchedule => 'Editar Horário';

  @override
  String get scheduleDetails => 'Detalhes do Horário';

  @override
  String get timeSlotName => 'Nome da faixa horária';

  @override
  String get deleteSchedule => 'Excluir Horário';

  @override
  String get confirmDeleteSchedule =>
      'Tem certeza que deseja excluir este horário? Todas as atribuições associadas também serão excluídas.';

  @override
  String get scheduleDeletedSuccessfully => 'Horário excluído com sucesso';

  @override
  String errorDeletingSchedule(Object error) {
    return 'Erro ao excluir horário: $error';
  }

  @override
  String get scheduleUpdatedSuccessfully => 'Horário atualizado com sucesso';

  @override
  String errorUpdatingSchedule(Object error) {
    return 'Erro ao atualizar horário: $error';
  }

  @override
  String get startTimeMustBeBeforeEnd =>
      'A hora de início deve ser anterior à hora de fim';

  @override
  String get assignMinistry => 'Atribuir Ministério';

  @override
  String get noMinistriesAssigned => 'Não há ministérios atribuídos';

  @override
  String get temporaryMinistry => 'Ministério temporário';

  @override
  String get addRole => 'Adicionar Função';

  @override
  String get thisMinistryHasNoRoles =>
      'Este ministério não tem funções definidas';

  @override
  String get defineRoles => 'Definir Funções';

  @override
  String get editCapacity => 'Editar capacidade';

  @override
  String get noPersonsAssigned => 'Não há pessoas designadas para esta função';

  @override
  String get addPerson => 'Adicionar Pessoa';

  @override
  String get deleteAssignment => 'Excluir designação';

  @override
  String get noInvitesSent => 'Nenhum convite enviado';

  @override
  String get songNotFound => 'Música não encontrada';

  @override
  String errorUploadingFile(Object error) {
    return 'Erro ao enviar arquivo: $error';
  }

  @override
  String uploadingProgress(Object progress) {
    return 'Enviando: $progress%';
  }

  @override
  String get fileUploadedSuccessfully => 'Arquivo enviado com sucesso';

  @override
  String errorPlayback(Object error) {
    return 'Erro ao iniciar reprodução: $error';
  }

  @override
  String get rewind10Seconds => 'Retroceder 10 segundos';

  @override
  String get pause => 'Pausar';

  @override
  String get play => 'Reproduzir';

  @override
  String get stop => 'Parar';

  @override
  String get forward10Seconds => 'Avançar 10 segundos';

  @override
  String orderLabel(Object order) {
    return 'Ordem: $order';
  }

  @override
  String get noFilesAssociated => 'Não há arquivos associados a esta música';

  @override
  String get uploadFile => 'Enviar Arquivo';

  @override
  String get fileNameless => 'Arquivo sem nome';

  @override
  String uploadedOn(Object date) {
    return 'Subido el $date';
  }

  @override
  String get score => 'Partitura/Documento';

  @override
  String get audio => 'Áudio';

  @override
  String errorSelectingFile(Object error) {
    return 'Error ao selecionar arquivo: $error';
  }

  @override
  String get loadingAudio => 'Carregando áudio...';

  @override
  String get preparingDocument => 'Preparando documento...';

  @override
  String get cannotOpenDocument => 'Não é possível abrir o documento';

  @override
  String errorOpeningDocument(Object error) {
    return 'Erro ao abrir documento: $error';
  }

  @override
  String downloadingProgress(Object progress) {
    return 'Baixando: $progress%';
  }

  @override
  String get cannotOpenDownloadedFile =>
      'Não é possível abrir o arquivo baixado';

  @override
  String errorDownloadingFile(Object error) {
    return 'Erro ao baixar e abrir arquivo: $error';
  }

  @override
  String get deleteFile => 'Excluir arquivo';

  @override
  String get confirmDeleteFile =>
      'Tem certeza que deseja excluir este arquivo?';

  @override
  String get fileDeletedSuccessfully => 'Arquivo excluído com sucesso';

  @override
  String errorDeletingFile(Object error) {
    return 'Erro ao excluir arquivo: $error';
  }

  @override
  String get create => 'Criar';

  @override
  String get cultsTab => 'Cultos';

  @override
  String get noGroupEventsScheduled => 'Não há eventos de grupos programados';

  @override
  String get noMinistryEventsScheduled =>
      'Não há eventos de ministérios programados';

  @override
  String get noEventsScheduled => 'Não há eventos programados';

  @override
  String get attendanceSummary => 'Resumo de Presença';

  @override
  String roleLabel(Object role) {
    return 'Função: $role';
  }

  @override
  String confirmedCount(Object count) {
    return 'Confirmados: $count';
  }

  @override
  String absentCount(Object count) {
    return 'Ausentes: $count';
  }

  @override
  String get presentLabel => 'PRESENTE';

  @override
  String get originallyAssigned => 'Atribuído originalmente';

  @override
  String get didNotAttend => 'Não compareceu';

  @override
  String get roleId => 'Role ID';

  @override
  String get noRoleInfoAvailable => 'Sem informação de rol disponível';

  @override
  String get rolePermissions => 'Permissões do rol:';

  @override
  String get thisRoleHasNoPermissions =>
      'Este rol não tem permissões atribuídas';

  @override
  String errorObtainingDiagnostic(Object error) {
    return 'Erro ao obter diagnóstico: $error';
  }

  @override
  String get id => 'ID';

  @override
  String get noCultsScheduled => 'Não há cultos programados';

  @override
  String noCultsFor(Object date) {
    return 'Não há cultos para $date';
  }

  @override
  String errorColon(Object error) {
    return 'Erro: $error';
  }

  @override
  String get dateNotAvailable => 'Data não disponível';

  @override
  String get acceptedOn => 'Aceito em';

  @override
  String get notSpecified => 'Não especificado';

  @override
  String get noServicesAssignedForThisDay =>
      'Você não tem serviços designados para este dia';

  @override
  String get noCounselingAppointmentsForThisDay =>
      'Você não tem consultas de aconselhamento confirmadas para este dia';

  @override
  String get basicInformation => 'Informação Básica';

  @override
  String get dateAndTime => 'Data e Hora';

  @override
  String get recurrence => 'Recorrência';

  @override
  String get basicInfo => 'Informações Básicas';

  @override
  String get defineEssentialEventData =>
      'Defina os dados essenciais do seu evento';

  @override
  String get addBasicInfoAboutEvent =>
      'Adicione as informações básicas sobre o seu evento.';

  @override
  String get addEventImage => 'Adicionar Imagem do Evento (16:9)';

  @override
  String get uploadingImage => 'Fazendo upload da imagem...';

  @override
  String get deleteImage => 'Excluir imagem';

  @override
  String get eventName => 'Nome do Evento';

  @override
  String get writeClearDescriptiveTitle =>
      'Escreva um título claro e descritivo';

  @override
  String get pleaseEnterEventName => 'Por favor, insira o nome do evento';

  @override
  String get selectCategory => 'Selecione uma categoria';

  @override
  String get pleaseSelectCategory => 'Por favor, selecione uma categoria';

  @override
  String get createNewCategory => 'Criar nova categoria';

  @override
  String get hideCategory => 'Ocultar categoria';

  @override
  String categoryWillNotAppear(String category) {
    return 'A categoria \"$category\" não aparecerá mais na lista de categorias disponíveis. Esta ação não afeta eventos existentes.\n\nDeseja continuar?';
  }

  @override
  String get hide => 'Ocultar';

  @override
  String categoryHidden(String category) {
    return 'Categoria \"$category\" ocultada';
  }

  @override
  String get undo => 'Desfazer';

  @override
  String errorLoadingCategories(String error) {
    return 'Erro ao carregar categorias: $error';
  }

  @override
  String get createNewCategoryTitle => 'Criar Nova Categoria';

  @override
  String get categoryName => 'Nome da Categoria';

  @override
  String get enterCategoryName => 'Digite o nome da categoria';

  @override
  String errorCreatingCategory(String error) {
    return 'Erro ao criar categoria: $error';
  }

  @override
  String get describeEventDetails => 'Descreva os detalhes do evento';

  @override
  String get advance => 'Avançar';

  @override
  String get cancelCreation => 'Cancelar criação';

  @override
  String get sureWantToCancel =>
      'Tem certeza que deseja cancelar? Todas as informações serão perdidas.';

  @override
  String get continueEditing => 'Continuar editando';

  @override
  String eventsCreatedSuccessfully(int count) {
    return '$count eventos criados com sucesso';
  }

  @override
  String get eventCreatedSuccessfully => 'Evento criado com sucesso';

  @override
  String errorCreatingEvent(String error) {
    return 'Erro ao criar evento: $error';
  }

  @override
  String get creatingEvent => 'Criando evento...';

  @override
  String get pleaseWaitProcessingData =>
      'Por favor, aguarde enquanto processamos os dados';

  @override
  String get eventLocation => 'Localização do Evento';

  @override
  String get defineWhereEventWillHappen => 'Defina onde o evento acontecerá';

  @override
  String get eventType => 'Tipo de Evento';

  @override
  String get churchLocations => 'Localizações da Igreja';

  @override
  String get useChurchLocation => 'Usar localização da igreja';

  @override
  String get selectRegisteredLocation => 'Selecione um dos locais registrados';

  @override
  String get noChurchLocationsAvailable =>
      'Não há localizações da igreja disponíveis';

  @override
  String get churchLocation => 'Localização da Igreja';

  @override
  String get pleaseSelectALocation => 'Por favor selecione uma localização';

  @override
  String get mySavedLocations => 'Minhas Localizações Salvas';

  @override
  String get useSavedLocation => 'Usar localização salva';

  @override
  String get selectSavedLocation =>
      'Selecione uma das suas localizações salvas';

  @override
  String get noSavedLocationsAvailable => 'Não há localizações salvas';

  @override
  String get savedLocation => 'Localização Salva';

  @override
  String errorLoadingLocations(Object error) {
    return 'Error al cargar ubicaciones: $error';
  }

  @override
  String errorLoadingSavedLocations(String error) {
    return 'Erro ao carregar ubicações guardadas: $error';
  }

  @override
  String get pleaseSelectChurchLocation =>
      'Por favor, selecciona uma ubicación de iglesia';

  @override
  String get pleaseSelectASavedLocation =>
      'Por favor, selecciona uma localização guardada';

  @override
  String get eventAddress => 'Endereço do Evento';

  @override
  String get cityRequired => 'Cidade *';

  @override
  String get enterEventCity => 'Digite a cidade do evento';

  @override
  String get pleaseEnterCity => 'Por favor digite a cidade';

  @override
  String get stateRequired => 'Estado *';

  @override
  String get enterEventState => 'Digite o estado do evento';

  @override
  String get pleaseEnterState => 'Por favor digite o estado';

  @override
  String get streetRequired => 'Rua *';

  @override
  String get enterEventStreet => 'Digite a rua do evento';

  @override
  String get pleaseEnterStreet => 'Por favor digite a rua';

  @override
  String get numberRequired => 'Número *';

  @override
  String get exampleNumber => 'Ex: 123';

  @override
  String get pleaseEnterNumber => 'Por favor digite o número';

  @override
  String get examplePostalCode => 'Ex: 12345-678';

  @override
  String get enterNeighborhood => 'Digite o bairro';

  @override
  String get apartmentRoomEtc => 'Apartamento, sala, etc.';

  @override
  String get saveLocationForFutureUse =>
      'Salvar esta localização para uso futuro';

  @override
  String get locationNameRequired => 'Nome da localização *';

  @override
  String get exampleLocationName => 'Ex: Meu Local Favorito';

  @override
  String get pleaseEnterLocationName =>
      'Por favor digite um nome para a localização';

  @override
  String get saveAsChurchLocationAdmin =>
      'Salvar como localização da igreja (admin)';

  @override
  String get saveLocation => 'Salvar Localização';

  @override
  String get pleaseEnterLocationNameForSave =>
      'Por favor ingresa un nombre para la ubicación';

  @override
  String get locationSavedSuccessfully => 'Ubicación guardada correctamente';

  @override
  String errorSavingLocation(String error) {
    return 'Error al guardar ubicación: $error';
  }

  @override
  String get churchLocationSavedSuccessfully =>
      'Ubicación de iglesia guardada correctamente';

  @override
  String get onlineEventLink => 'Link do Evento Online';

  @override
  String get meetingUrlRequired => 'URL da Reunião *';

  @override
  String get exampleZoomUrl => 'Ex: https://zoom.us/j/12345678';

  @override
  String get accessInstructionsOptional => 'Instruções de Acesso (opcional)';

  @override
  String get instructionsToJoinMeeting =>
      'Instruções para entrar na reunião online, senhas, etc.';

  @override
  String get onlineOptionHybrid => 'Opção Online (Híbrido)';

  @override
  String get forHybridEventsPleaseEnterValidUrl =>
      'Para eventos híbridos, por favor digite um URL válido';

  @override
  String get next => 'Próximo';

  @override
  String get eventDateAndTime => 'Data e Hora do Evento';

  @override
  String get defineWhenEventStartsAndEnds =>
      'Defina quando o evento começa e termina';

  @override
  String get selectTime => 'Selecionar hora';

  @override
  String get eventRecurrence => 'Recorrência do Evento';

  @override
  String get defineIfEventWillBeOnceOrRecurring =>
      'Defina se seu evento acontecerá uma única vez ou será recorrente';

  @override
  String get recurrenceSettings => 'Configurações de Recorrência';

  @override
  String get defineFrequencyOfRecurringEvent =>
      'Defina a frequência do seu evento recorrente';

  @override
  String get frequency => 'Frequência';

  @override
  String get numberIndicatesInterval =>
      'O número indica o intervalo de repetição. Por exemplo: \"2 Semanalmente\" significa que o evento se repetirá a cada 2 semanas.';

  @override
  String get repeatEvery => 'Repetir a cada:';

  @override
  String get days => 'dias';

  @override
  String get day => 'dia';

  @override
  String get weeks => 'semanas';

  @override
  String get week => 'semana';

  @override
  String get months => 'meses';

  @override
  String get month => 'mês';

  @override
  String get year => 'ano';

  @override
  String get ends => 'Termina';

  @override
  String get after => 'Após';

  @override
  String get occurrences => 'repetições';

  @override
  String get onDate => 'Em data';

  @override
  String get onSpecificDate => 'Em data';

  @override
  String get single => 'Único';

  @override
  String get recurring => 'Recorrente';

  @override
  String get singleEventNonRecurring => 'Evento único (não recorrente)';

  @override
  String repeatsEveryXDays(Object interval) {
    return 'Repete a cada $interval dias';
  }

  @override
  String get repeatsDaily => 'Repete diariamente';

  @override
  String repeatsEveryXWeeks(Object interval) {
    return 'Repete a cada $interval semanas';
  }

  @override
  String get repeatsWeekly => 'Repete semanalmente';

  @override
  String repeatsEveryXMonths(Object interval) {
    return 'Repete a cada $interval meses';
  }

  @override
  String get repeatsMonthly => 'Repete mensalmente';

  @override
  String repeatsEveryXYears(Object interval) {
    return 'Repete a cada $interval anos';
  }

  @override
  String get repeatsYearly => 'Repete anualmente';

  @override
  String get noEndDefined => 'sem fim definido';

  @override
  String get untilSpecificDate => 'até data específica';

  @override
  String untilDate(Object date) {
    return 'até $date';
  }

  @override
  String errorUploadingImage(String error) {
    return 'Erro ao fazer upload da imagem: $error';
  }

  @override
  String get defineRecurringEventFrequency =>
      'Defina a frequência do seu evento recorrente';

  @override
  String get intervalExplanation =>
      'O número indica o intervalo de repetição. Por exemplo: \"2 semanas\" significa que o evento se repetirá a cada 2 semanas.';

  @override
  String get singleEventNotRecurring => 'Evento único (não recorrente)';

  @override
  String get repeats => 'Repete';

  @override
  String everyXDays(int interval) {
    return 'a cada $interval dias';
  }

  @override
  String get daily => 'diariamente';

  @override
  String everyXWeeks(int interval) {
    return 'a cada $interval semanas';
  }

  @override
  String get weekly => 'semanalmente';

  @override
  String everyXMonths(int interval) {
    return 'a cada $interval meses';
  }

  @override
  String get monthly => 'mensalmente';

  @override
  String everyXYears(int interval) {
    return 'a cada $interval anos';
  }

  @override
  String get yearly => 'anualmente';

  @override
  String untilXOccurrences(int count) {
    return 'até $count repetições';
  }

  @override
  String get until => 'até';

  @override
  String get defineEventOccurrenceType =>
      'Defina se seu evento acontecerá uma única vez ou será recorrente';
}
