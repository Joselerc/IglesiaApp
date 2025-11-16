import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/profile_field_response.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_fields_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/church_logo.dart'; // Logo optimizado
import 'package:iglesia_app/screens/profile/additional_info_screen.dart';
import '../widgets/home/announcements_section.dart';
import '../widgets/home/cults_section.dart';
import '../widgets/home/events_section.dart';
import '../widgets/home/counseling_section.dart';
import '../widgets/home/custom_page_list_section.dart';
import '../widgets/home/videos_section.dart';
import '../widgets/home/courses_section.dart';
import '../models/home_screen_section.dart';
import '../widgets/home/live_stream_home_section.dart';
import '../widgets/home/donations_section.dart';
import '../widgets/skeletons/home_screen_skeleton.dart';
import '../widgets/home/ministries_section.dart';
import '../widgets/home/groups_section.dart';
import '../widgets/home/private_prayer_section.dart';
import '../widgets/home/public_prayer_section.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../services/app_config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _shouldShowBanner = false;
  bool _isBannerLoading = true;
  Map<String, dynamic>? _userData;
  User? _user;
  List<QueryDocumentSnapshot>? _requiredFields;
  List<DocumentSnapshot> _churchLocations = [];

  // Añadir StreamSubscription para mejor gestión de memoria
  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;

  // Pre-carga de verificaciones para secciones customPageList
  Map<String, bool> _customPageListVisibility = {};
  bool _isPreloadingCustomPages = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
    _user = FirebaseAuth.instance.currentUser;
    _checkProfileRequirements();
    _loadChurchLocations();
    // _preloadCustomPageSections(); // Comentado temporalmente
  }

  @override
  void dispose() {
    // Cancelar suscripciones para evitar memory leaks
    _userStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkProfileRequirements() async {
    debugPrint(
        '🔍 HOME_SCREEN - Iniciando verificación de requisitos de perfil');
    if (_user == null) {
      debugPrint(
          '⚠️ HOME_SCREEN - Usuario nulo, no se puede verificar requisitos');
      if (mounted) {
        // Asegurar que el widget está montado
        setState(() {
          _shouldShowBanner = false;
          _isBannerLoading = false;
        });
      }
      return;
    }

    try {
      debugPrint(
          '🔍 HOME_SCREEN - Obteniendo datos del usuario: ${_user!.uid}');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint(
            '⚠️ HOME_SCREEN - Documento de usuario no existe en Firestore');
        if (mounted) {
          setState(() {
            _shouldShowBanner = false;
            _isBannerLoading = false;
          });
        }
        return;
      }

      _userData = userDoc.data();
      debugPrint(
          '✅ HOME_SCREEN - Datos de usuario obtenidos: ${_userData?.keys.toList()}');

      // --- Verificación de campos básicos ---
      bool basicInfoMissing = false;
      if (_userData != null) {
        final nameMissing = _userData!['name'] == null ||
            (_userData!['name'] as String).trim().isEmpty;
        final surnameMissing = _userData!['surname'] == null ||
            (_userData!['surname'] as String).trim().isEmpty;
        // Para el teléfono, verificamos el campo 'phone' que suele ser el número local.
        // Si tienes otra lógica (ej. 'phoneComplete'), ajústalo.
        final phoneMissing = _userData!['phone'] == null ||
            (_userData!['phone'] as String).trim().isEmpty;
        final birthDateMissing = _userData!['birthDate'] == null;
        final genderMissing = _userData!['gender'] == null ||
            (_userData!['gender'] as String).trim().isEmpty;

        basicInfoMissing = nameMissing ||
            surnameMissing ||
            phoneMissing ||
            birthDateMissing ||
            genderMissing;

        debugPrint('ℹ️ HOME_SCREEN - Verificación campos básicos:');
        debugPrint('  - Nome ausente: $nameMissing');
        debugPrint('  - Sobrenome ausente: $surnameMissing');
        debugPrint('  - Telefone ausente: $phoneMissing');
        debugPrint('  - Data de Nascimento ausente: $birthDateMissing');
        debugPrint('  - Gênero ausente: $genderMissing');
        debugPrint('  ➡️ Informação básica ausente: $basicInfoMissing');
      } else {
        // Si _userData es null, asumimos que falta información básica crítica.
        basicInfoMissing = true;
        debugPrint(
            '⚠️ HOME_SCREEN - _userData es null, se considera que falta información básica.');
      }
      // --- Fin Verificación de campos básicos ---

      final neverShowAgain =
          _userData?['neverShowBannerAgain'] as bool? ?? false;
      final hasSkippedBanner = _userData?['hasSkippedBanner'] as bool? ?? false;
      debugPrint(
          '🚩 HOME_SCREEN - Flags importantes: neverShowAgain=$neverShowAgain, hasSkippedBanner=$hasSkippedBanner');

      debugPrint(
          '🔍 HOME_SCREEN - Buscando campos de perfil requeridos (adicionales)');
      final requiredFieldsQuery = await FirebaseFirestore.instance
          .collection('profileFields')
          .where('isActive', isEqualTo: true)
          .where('isRequired', isEqualTo: true)
          .get();

      _requiredFields = requiredFieldsQuery.docs;

      // Si no hay campos ADICIONALES requeridos, 'hasCompletedAdditional' será true por defecto.
      // La lógica de 'hasNewRequiredFields' seguirá funcionando independientemente.
      bool hasCompletedAdditional = true;
      if (_requiredFields!.isNotEmpty) {
        debugPrint(
            '📋 HOME_SCREEN - Campos ADICIONALES requeridos encontrados: ${_requiredFields!.length}');
        final profileFieldsService = ProfileFieldsService();
        hasCompletedAdditional =
            await profileFieldsService.hasCompletedRequiredFields(_user!.uid);
        debugPrint(
            '✅ HOME_SCREEN - Resultado de hasCompletedRequiredFields (adicionales): $hasCompletedAdditional');
      } else {
        debugPrint(
            'ℹ️ HOME_SCREEN - No hay campos de perfil ADICIONALES requeridos definidos.');
      }

      final lastUpdated =
          _userData?['additionalFieldsLastUpdated'] as Timestamp?;
      final lastFieldsUpdate = lastUpdated?.toDate();
      debugPrint(
          '🕒 HOME_SCREEN - Última atualização de campos adicionais: ${lastFieldsUpdate?.toIso8601String() ?? "nunca"}');

      final lastBannerShown = _userData?['lastBannerShown'] as Timestamp?;
      final lastShown = lastBannerShown?.toDate();
      debugPrint(
          '🕒 HOME_SCREEN - Última vez que se mostrou o banner: ${lastShown?.toIso8601String() ?? "nunca"}');

      bool hasNewRequiredFields = false; // Se refiere a campos ADICIONALES
      if (_requiredFields!.isNotEmpty) {
        // Solo calcular si hay campos adicionales definidos
        if (lastFieldsUpdate != null) {
          for (final doc in _requiredFields!) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('createdAt') &&
                data['createdAt'] is Timestamp) {
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              if (createdAt.isAfter(lastFieldsUpdate)) {
                hasNewRequiredFields = true;
                debugPrint(
                    '⚠️ HOME_SCREEN - Campo ADICIONAL novo após a última atualização: ${data['name'] ?? 'Sem nome'}');
                break;
              }
            }
          }
        } else {
          // Si nunca ha actualizado campos Y hay campos adicionales requeridos, considerar que hay nuevos.
          hasNewRequiredFields = true;
          debugPrint(
              'ℹ️ HOME_SCREEN - Usuário nunca atualizou campos adicionais, considerando todos como novos (se houver).');
        }
      }

      bool shouldShowBannerDecision = false;

      if (neverShowAgain) {
        // Si eligió no mostrar nunca más, solo se muestra si faltan básicos O hay nuevos adicionales.
        shouldShowBannerDecision = basicInfoMissing || hasNewRequiredFields;
        debugPrint(
            '🔄 HOME_SCREEN - Usuário escolheu não mostrar nunca mais. Mostrar se (basicInfoMissing || hasNewRequiredFields): $shouldShowBannerDecision');
      } else if (hasSkippedBanner && lastShown != null) {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        if (lastShown.isAfter(threeDaysAgo)) {
          shouldShowBannerDecision = false;
          debugPrint(
              '🔄 HOME_SCREEN - Usuário omitiu temporariamente. Ainda dentro dos 3 dias. Ocultar banner.');
        } else {
          // Ya pasaron los 3 días. Mostrar si falta info básica O no ha completado adicionales O hay nuevos adicionales.
          shouldShowBannerDecision = basicInfoMissing ||
              !hasCompletedAdditional ||
              hasNewRequiredFields;
          debugPrint(
              '🔄 HOME_SCREEN - Usuário omitiu temporariamente e já passaram 3 dias. Mostrar se (basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields): $shouldShowBannerDecision');
        }
      } else {
        // No "neverShow", no "skipped". Mostrar si falta info básica O no ha completado adicionales O hay nuevos adicionales.
        shouldShowBannerDecision =
            basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields;
        debugPrint(
            '🔄 HOME_SCREEN - Sem skip/neverShow. Mostrar se (basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields): $shouldShowBannerDecision');
      }

      // Anulación final: Si toda la info básica está completa, Y los adicionales requeridos están completos, Y no hay nuevos adicionales, no mostrar.
      if (!basicInfoMissing &&
          hasCompletedAdditional &&
          !hasNewRequiredFields) {
        shouldShowBannerDecision = false;
        debugPrint(
            'ℹ️ HOME_SCREEN - Perfil básico completo, adicionais completos e sem novos campos adicionais. Não mostrar banner.');
      }

      debugPrint(
          '🚩 HOME_SCREEN - Decisão final: mostrar banner = $shouldShowBannerDecision');
      if (mounted) {
        final bool previousBannerState = _shouldShowBanner;
        if (previousBannerState != shouldShowBannerDecision ||
            _isBannerLoading) {
          setState(() {
            _shouldShowBanner = shouldShowBannerDecision;
            _isBannerLoading = false;
          });
        } else if (_isBannerLoading) {
          setState(() {
            _isBannerLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ HOME_SCREEN - Error al verificar campos requeridos: $e');
      debugPrint('📜 HOME_SCREEN - Stack trace: ${StackTrace.current}');
      if (mounted) {
        // Asegurar que el widget está montado
        setState(() {
          _shouldShowBanner = false;
          _isBannerLoading = false;
        });
      }
    }
  }

  Future<void> _loadChurchLocations() async {
    try {
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('churchLocations')
          .orderBy('name')
          .get();
      if (mounted) {
        setState(() {
          _churchLocations = locationsSnapshot.docs;
        });
      }
      debugPrint(
          '✅ HOME_SCREEN - Localizaciones cargadas: ${_churchLocations.length}');
    } catch (e) {
      debugPrint('❌ HOME_SCREEN - Error al cargar localizaciones: $e');
    }
  }

  Future<void> _preloadCustomPageSections() async {
    try {
      debugPrint('🔄 HOME_SCREEN - Pre-cargando secciones customPageList...');

      // Obtener todas las secciones activas de tipo customPageList con hideWhenEmpty = true
      final sectionsQuery = await FirebaseFirestore.instance
          .collection('homeScreenSections')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: 'customPageList')
          .where('hideWhenEmpty', isEqualTo: true)
          .get();

      final Map<String, bool> visibilityMap = {};

      // Para cada sección, verificar si tiene páginas válidas
      for (var doc in sectionsQuery.docs) {
        final section = HomeScreenSection.fromFirestore(doc);
        final pageIds = section.pageIds ?? [];

        if (pageIds.isEmpty) {
          visibilityMap[section.id] = false;
        } else {
          // Verificar si al menos una página existe
          final hasPages = await _checkIfAnyPageExists(pageIds);
          visibilityMap[section.id] = hasPages;
        }
      }

      if (mounted) {
        setState(() {
          _customPageListVisibility = visibilityMap;
          _isPreloadingCustomPages = false;
        });
      }

      debugPrint(
          '✅ HOME_SCREEN - Pre-carga completada: ${visibilityMap.length} secciones verificadas');
    } catch (e) {
      debugPrint('❌ HOME_SCREEN - Error al pre-cargar secciones: $e');
      if (mounted) {
        setState(() {
          _isPreloadingCustomPages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Configurar la barra de estado para que sea visible con color transparente
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Column(
            // Usar Column para Header + LiveStream + StreamBuilder
            children: [
              // --- Header Fijo ---
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo de la iglesia optimizado
                    const ChurchLogo(
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 16),
                    // Nombre de la iglesia con el mismo estilo que los títulos de sección
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: AppConfigService().getAppConfigStream(),
                        builder: (context, snapshot) {
                          String churchName = 'ChurchConnect';
                          
                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                            final config = snapshot.data!.data() as Map<String, dynamic>?;
                            if (config != null && config['churchName'] != null) {
                              churchName = config['churchName'];
                            }
                          }
                          
                          return Text(
                            churchName,
                            style: AppTextStyles.headline3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    // Foto de perfil
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.pushNamed(context, '/profile_screen');
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.warmSand,
                            child: snapshot.hasData &&
                                    snapshot.data?.data() != null
                                ? _buildUserAvatar(snapshot.data!.data()
                                    as Map<String, dynamic>)
                                : const Icon(Icons.person,
                                    color: Color(0xFF2F2F2F), size: 24),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- Contenido Dinámico (Secciones normales) ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('homeScreenSections')
                      .where('isActive', isEqualTo: true)
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text(AppLocalizations.of(context)!
                              .errorLoadingSections(
                                  snapshot.error.toString())));
                    }
                    // MODIFICACIÓN: Mostrar esqueleto si las secciones están cargando O si la lógica del banner está cargando.
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        _isBannerLoading) {
                      return const HomeScreenSkeleton();
                    }
                    // Ajuste: Permitir que no haya secciones sin mostrar error
                    // if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    //   return const Center(child: Text('Nenhuma seção configurada.'));
                    // }

                    // Mapea los documentos
                    final sections = snapshot.hasData
                        ? snapshot.data!.docs
                            .map((doc) => HomeScreenSection.fromFirestore(doc))
                            .toList()
                        : <HomeScreenSection>[];

                    // DEBUG: Ver todas las secciones cargadas
                    debugPrint('📋 HOME_SCREEN: Total secciones desde Firestore: ${sections.length}');
                    for (var section in sections) {
                      debugPrint('  - ${section.title} (type: ${section.type}, active: ${section.isActive}, order: ${section.order})');
                    }

                    // Filtrar secciones activas aquí por si acaso (aunque el query ya lo hace)
                    final activeSections =
                        sections.where((s) => s.isActive).toList();
                    debugPrint('📋 HOME_SCREEN: Secciones activas filtradas: ${activeSections.length}');

                    return ListView.separated(
                      // Aumentar padding inferior general
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 48), // <-- Aumentado bottom padding
                      physics:
                          const ClampingScrollPhysics(), // Solo cambiar physics a ClampingScrollPhysics
                      itemCount: activeSections.length + 1,
                      separatorBuilder: (context, index) {
                        if (index == 0)
                          return const SizedBox
                              .shrink(); // No hay separador antes del banner

                        // Índice real de la sección *anterior* a la que se le añadirá el separador
                        final previousSectionIndex = index - 1;
                        // Índice real de la sección *actual* (la que viene después del separador)
                        final currentSectionIndex = index;

                        // Verificar si estamos a punto de dibujar la sección 'donations'
                        // y si la sección anterior era 'videos'
                        bool showSmallerSeparator = false;
                        // Asegurar que los índices sean válidos para la lista activeSections
                        if (currentSectionIndex < activeSections.length &&
                            previousSectionIndex >= 0) {
                          final currentSection =
                              activeSections[currentSectionIndex];
                          final previousSection =
                              activeSections[previousSectionIndex];

                          // Reducir espacio si la sección actual es Donaciones Y la anterior es Videos
                          if (currentSection.type ==
                                  HomeScreenSectionType.donations &&
                              previousSection.type ==
                                  HomeScreenSectionType.videos) {
                            showSmallerSeparator = true;
                          }
                          // Mantener espacio reducido después de liveStream si es la primera sección real
                          else if (previousSection.type ==
                                  HomeScreenSectionType.liveStream &&
                              previousSectionIndex == 0) {
                            showSmallerSeparator = true;
                          }
                        }

                        // Aplicar separador pequeño o grande según la condición
                        return SizedBox(
                            height: showSmallerSeparator ? 16.0 : 32.0);
                      },
                      itemBuilder: (context, index) {
                        // Mostrar Banner primero
                        if (index == 0) {
                          return AnimatedCrossFade(
                            firstChild: _shouldShowBanner &&
                                    _userData != null &&
                                    !_isBannerLoading
                                ? _buildProfileRequirementsBanner()
                                : const SizedBox.shrink(),
                            secondChild: const SizedBox.shrink(),
                            crossFadeState: _shouldShowBanner &&
                                    _userData != null &&
                                    !_isBannerLoading
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 500),
                            sizeCurve: Curves.easeInOutCubic,
                            firstCurve: Curves.easeInOut,
                            secondCurve: Curves.easeOut,
                          );
                        }

                        // Obtener la sección actual (ajustando índice por el banner)
                        final section = activeSections[index - 1];
                        
                        // DEBUG: Ver qué sección se está procesando
                        debugPrint('🔨 HOME_SCREEN: Procesando sección [${index - 1}]: ${section.title} (type: ${section.type})');

                        // Switch para renderizar el widget adecuado
                        switch (section.type) {
                          case HomeScreenSectionType.liveStream:

                            // StreamBuilder anidado para la configuración del directo
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('app_config')
                                  .doc('live_stream')
                                  .snapshots(),
                              builder: (context, liveSnapshot) {
                                if (!liveSnapshot.hasData ||
                                    !liveSnapshot.data!.exists) {
                                  return const SizedBox
                                      .shrink(); // No mostrar si no hay config
                                }
                                final liveConfig = liveSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                // final liveConfigDocRef = FirebaseFirestore.instance.collection('app_config').doc('live_stream'); // Ya no se necesita para actualizar

                                // --- Leer configuración (solo isActive) ---
                                final bool isLiveActive =
                                    liveConfig['isActive'] ?? false;
                                // <-- DEBUG PRINT 4
                                /* Eliminada lógica de horario
                                final int minutesBefore = liveConfig['minutesBeforeStartToShow'] ?? 0;
                                final DateTime now = DateTime.now();
                                final startTime = (liveConfig['scheduledStartTime'] as Timestamp?)?.toDate();
                                final endTime = (liveConfig['scheduledEndTime'] as Timestamp?)?.toDate();
                                final DateTime? displayStartTime = startTime?.subtract(Duration(minutes: minutesBefore));
                                */

                                // --- Determinar estado automático basado en horario --- (Eliminado)
                                // bool shouldBeActiveAutomatically = false;
                                // ... (cálculo eliminado)

                                // --- Lógica de actualización y visibilidad --- (Simplificada)
                                // bool showSection = currentIsActive;
                                // ... (intentos de actualización eliminados) ...

                                // Finalmente, mostrar u ocultar basado solo en isActive
                                return isLiveActive
                                    ? LiveStreamHomeSection(
                                        configData: liveConfig,
                                        displayTitle: section.title)
                                    : const SizedBox.shrink();
                              },
                            );
                          case HomeScreenSectionType.announcements:
                            return const AnnouncementsSection();
                          case HomeScreenSectionType.cults:
                            return const CultsSection();
                          case HomeScreenSectionType.servicesGrid:
                            return const SizedBox.shrink();
                          case HomeScreenSectionType.events:
                            return const EventsSection();
                          case HomeScreenSectionType.counseling:
                            return const CounselingSection();
                          case HomeScreenSectionType.customPageList:
                            return CustomPageListSection(
                              title: section.title,
                              pageIds: section.pageIds ?? [],
                            );
                          case HomeScreenSectionType.videos:
                            return const VideosSection();
                          case HomeScreenSectionType.courses:
                            return CoursesSection(title: section.title);
                          case HomeScreenSectionType.donations:
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('donationsPage')
                                  .doc('settings')
                                  .snapshots(),
                              builder: (context, donationSnapshot) {
                                if (!donationSnapshot.hasData ||
                                    !donationSnapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }
                                final donationConfig = donationSnapshot.data!
                                    .data() as Map<String, dynamic>;
                                // Mostrar el widget de sección/tarjeta, pasando el título y la config
                                return DonationsSection(
                                    title: section
                                        .title, // Usar título de homeScreenSections
                                    configData: donationConfig);
                              },
                            );
                          case HomeScreenSectionType.ministries:
                            return MinistriesSection(
                                displayTitle: section.title);
                          case HomeScreenSectionType.groups:
                            return GroupsSection(displayTitle: section.title);
                          case HomeScreenSectionType.privatePrayer:
                            return PrivatePrayerSection(
                                displayTitle: section.title);
                          case HomeScreenSectionType.publicPrayer:
                            return PublicPrayerSection(
                                displayTitle: section.title);
                          case HomeScreenSectionType.workSchedules:
                            // Nota: workSchedules ahora está integrado dentro de MinistriesSection
                            // Si alguien crea esta sección en Firebase, simplemente la ocultamos
                            return const SizedBox.shrink();
                          case HomeScreenSectionType.unknown:
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(AppLocalizations.of(context)!
                                  .unknownSectionType(section.type.toString())),
                            );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRequirementsBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        // ignore: deprecated_member_use
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.additionalInformationRequired,
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              AppLocalizations.of(context)!.pleaseCompleteAdditionalInfo,
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              border: Border(
                  top: BorderSide(
                      color: AppColors.primary.withOpacity(0.1), width: 1)),
            ),
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Detectar si es una pantalla pequeña (menor a 350px de ancho)
                final isSmallScreen = constraints.maxWidth < 350;

                if (isSmallScreen) {
                  // En pantallas pequeñas, usar Column para apilar verticalmente
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Botón principal centrado
                      AppButton(
                        text: AppLocalizations.of(context)!.completeNow,
                        onPressed: () {
                          _showAdditionalInfoModal(context);
                        },
                        isSmall:
                            false, // Usar tamaño normal para mejor visibilidad
                      ),
                      const SizedBox(height: 8),
                      // Botón secundario centrado
                      Builder(
                        builder: (context) {
                          final skipCount =
                              _userData?['bannerSkipCount'] as int? ?? 0;

                          return Center(
                            child: TextButton(
                              onPressed: () async {
                                if (mounted) {
                                  setState(() {
                                    _shouldShowBanner = false;
                                  });
                                }

                                if (skipCount >= 3) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user!.uid)
                                      .update({
                                    'neverShowBannerAgain': true,
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user!.uid)
                                      .update({
                                    'hasSkippedBanner': true,
                                    'lastBannerShown':
                                        FieldValue.serverTimestamp(),
                                    'bannerSkipCount': FieldValue.increment(1),
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                skipCount >= 3
                                    ? AppLocalizations.of(context)!
                                        .doNotShowAgain
                                    : AppLocalizations.of(context)!.skipForNow,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  // En pantallas normales, usar Row como antes
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Verificar cuántas veces ha omitido el banner
                      Flexible(
                        child: Builder(
                          builder: (context) {
                            final skipCount =
                                _userData?['bannerSkipCount'] as int? ?? 0;

                            // Si ha omitido 3 o más veces, mostrar "No mostrar nunca más"
                            if (skipCount >= 3) {
                              return TextButton(
                                onPressed: () async {
                                  // Animar la desaparición antes de actualizar Firestore
                                  if (mounted) {
                                    setState(() {
                                      _shouldShowBanner = false;
                                    });
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_user!.uid)
                                      .update({
                                    'neverShowBannerAgain': true,
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.doNotShowAgain,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }

                            return TextButton(
                              onPressed: () async {
                                // Animar la desaparición antes de actualizar Firestore
                                if (mounted) {
                                  setState(() {
                                    _shouldShowBanner = false;
                                  });
                                }

                                // Actualizar el contador de saltos y la fecha de la última vez que se mostró
                                // SOLO ocultamos el banner temporalmente, no establecemos 'neverShowBannerAgain'
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_user!.uid)
                                    .update({
                                  'hasSkippedBanner': true,
                                  'lastBannerShown':
                                      FieldValue.serverTimestamp(),
                                  'bannerSkipCount': FieldValue.increment(1),
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.skipForNow,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8), // Espacio entre botones
                      AppButton(
                        text: AppLocalizations.of(context)!.completeNow,
                        onPressed: () {
                          // Muestra el modal para completar la información adicional
                          _showAdditionalInfoModal(context);
                        },
                        isSmall: true,
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Muestra el modal para completar la información adicional
  void _showAdditionalInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // Cambio: fondo blanco directo para iOS
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer, // Importante para iOS
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95, // Aumentado para mejor uso del espacio
        expand: false,
        snap: true, // Permite snap a posiciones específicas
        snapSizes: const [0.5, 0.8, 0.95], // Posiciones de snap
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: const AdditionalInfoScreen(fromBanner: true),
          ),
        ),
      ),
    ).then((_) {
      // Cuando el modal se cierre, volver a verificar los requisitos del perfil
      _checkProfileRequirements();
    });
  }

  // Método para verificar si alguna página existe en la lista de pageIds
  Future<bool> _checkIfAnyPageExists(List<dynamic> pageIds) async {
    try {
      // Convertir pageIds a strings si son DocumentReferences
      final List<String> pageIdStrings = pageIds.map((id) {
        if (id is DocumentReference) {
          return id.id;
        }
        return id.toString();
      }).toList();

      if (pageIdStrings.isEmpty) {
        return false;
      }

      // Verificar si al menos una página existe
      for (String pageId in pageIdStrings) {
        final doc = await FirebaseFirestore.instance
            .collection('pageContent')
            .doc(pageId)
            .get();

        if (doc.exists) {
          return true; // Al menos una página existe
        }
      }

      return false; // Ninguna página existe
    } catch (e) {
      print('Error al verificar páginas: $e');
      return false;
    }
  }

  Widget _buildUserAvatar(Map<String, dynamic> userData) {
    final photoUrl = userData['photoUrl'] as String?;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 48, // Tamaño aumentado
          height: 48, // Tamaño aumentado
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, color: Color(0xFF2F2F2F), size: 24);
          },
        ),
      );
    }
    return const Icon(Icons.person, color: Color(0xFF2F2F2F), size: 24);
  }
}
