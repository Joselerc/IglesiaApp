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
import 'package:igreja_amor_em_movimento/screens/profile/additional_info_screen.dart';
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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
    _user = FirebaseAuth.instance.currentUser;
    _checkProfileRequirements();
    _loadChurchLocations();
  }

  @override
  void dispose() {
    // Cancelar suscripciones para evitar memory leaks
    _userStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkProfileRequirements() async {
    debugPrint('🔍 HOME_SCREEN - Iniciando verificación de requisitos de perfil');
    if (_user == null) {
      debugPrint('⚠️ HOME_SCREEN - Usuario nulo, no se puede verificar requisitos');
      if (mounted) { // Asegurar que el widget está montado
        setState(() {
          _shouldShowBanner = false;
          _isBannerLoading = false;
        });
      }
      return;
    }

    try {
      debugPrint('🔍 HOME_SCREEN - Obteniendo datos del usuario: ${_user!.uid}');
      final userDoc = await FirebaseFirestore.instance
                  .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('⚠️ HOME_SCREEN - Documento de usuario no existe en Firestore');
        if (mounted) {
          setState(() {
            _shouldShowBanner = false;
            _isBannerLoading = false;
          });
        }
        return;
      }
      
      _userData = userDoc.data();
      debugPrint('✅ HOME_SCREEN - Datos de usuario obtenidos: ${_userData?.keys.toList()}');

      // --- Verificación de campos básicos ---
      bool basicInfoMissing = false;
      if (_userData != null) {
        final nameMissing = _userData!['name'] == null || (_userData!['name'] as String).trim().isEmpty;
        final surnameMissing = _userData!['surname'] == null || (_userData!['surname'] as String).trim().isEmpty;
        // Para el teléfono, verificamos el campo 'phone' que suele ser el número local.
        // Si tienes otra lógica (ej. 'phoneComplete'), ajústalo.
        final phoneMissing = _userData!['phone'] == null || (_userData!['phone'] as String).trim().isEmpty;
        final birthDateMissing = _userData!['birthDate'] == null;
        final genderMissing = _userData!['gender'] == null || (_userData!['gender'] as String).trim().isEmpty;
        
        basicInfoMissing = nameMissing || surnameMissing || phoneMissing || birthDateMissing || genderMissing;
        
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
        debugPrint('⚠️ HOME_SCREEN - _userData es null, se considera que falta información básica.');
      }
      // --- Fin Verificación de campos básicos ---
            
      final neverShowAgain = _userData?['neverShowBannerAgain'] as bool? ?? false;
      final hasSkippedBanner = _userData?['hasSkippedBanner'] as bool? ?? false;
      debugPrint('🚩 HOME_SCREEN - Flags importantes: neverShowAgain=$neverShowAgain, hasSkippedBanner=$hasSkippedBanner');
                
      debugPrint('🔍 HOME_SCREEN - Buscando campos de perfil requeridos (adicionales)');
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
        debugPrint('📋 HOME_SCREEN - Campos ADICIONALES requeridos encontrados: ${_requiredFields!.length}');
        final profileFieldsService = ProfileFieldsService();
        hasCompletedAdditional = await profileFieldsService.hasCompletedRequiredFields(_user!.uid);
        debugPrint('✅ HOME_SCREEN - Resultado de hasCompletedRequiredFields (adicionales): $hasCompletedAdditional');
      } else {
        debugPrint('ℹ️ HOME_SCREEN - No hay campos de perfil ADICIONALES requeridos definidos.');
      }
                        
      final lastUpdated = _userData?['additionalFieldsLastUpdated'] as Timestamp?;
      final lastFieldsUpdate = lastUpdated?.toDate();
      debugPrint('🕒 HOME_SCREEN - Última atualização de campos adicionais: ${lastFieldsUpdate?.toIso8601String() ?? "nunca"}');
                        
      final lastBannerShown = _userData?['lastBannerShown'] as Timestamp?;
      final lastShown = lastBannerShown?.toDate();
      debugPrint('🕒 HOME_SCREEN - Última vez que se mostrou o banner: ${lastShown?.toIso8601String() ?? "nunca"}');
                        
      bool hasNewRequiredFields = false; // Se refiere a campos ADICIONALES
      if (_requiredFields!.isNotEmpty) { // Solo calcular si hay campos adicionales definidos
        if (lastFieldsUpdate != null) {
          for (final doc in _requiredFields!) {
            final data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              if (createdAt.isAfter(lastFieldsUpdate)) {
                hasNewRequiredFields = true;
                debugPrint('⚠️ HOME_SCREEN - Campo ADICIONAL novo após a última atualização: ${data['name'] ?? 'Sem nome'}');
                break;
              }
            }
          }
        } else {
          // Si nunca ha actualizado campos Y hay campos adicionales requeridos, considerar que hay nuevos.
          hasNewRequiredFields = true; 
          debugPrint('ℹ️ HOME_SCREEN - Usuário nunca atualizou campos adicionais, considerando todos como novos (se houver).');
        }
      }
                        
      bool shouldShowBannerDecision = false;

      if (neverShowAgain) {
        // Si eligió no mostrar nunca más, solo se muestra si faltan básicos O hay nuevos adicionales.
        shouldShowBannerDecision = basicInfoMissing || hasNewRequiredFields;
        debugPrint('🔄 HOME_SCREEN - Usuário escolheu não mostrar nunca mais. Mostrar se (basicInfoMissing || hasNewRequiredFields): $shouldShowBannerDecision');
      } else if (hasSkippedBanner && lastShown != null) {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        if (lastShown.isAfter(threeDaysAgo)) {
          shouldShowBannerDecision = false;
          debugPrint('🔄 HOME_SCREEN - Usuário omitiu temporariamente. Ainda dentro dos 3 dias. Ocultar banner.');
        } else {
          // Ya pasaron los 3 días. Mostrar si falta info básica O no ha completado adicionales O hay nuevos adicionales.
          shouldShowBannerDecision = basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields;
          debugPrint('🔄 HOME_SCREEN - Usuário omitiu temporariamente e já passaram 3 dias. Mostrar se (basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields): $shouldShowBannerDecision');
        }
      } else {
        // No "neverShow", no "skipped". Mostrar si falta info básica O no ha completado adicionales O hay nuevos adicionales.
        shouldShowBannerDecision = basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields;
        debugPrint('🔄 HOME_SCREEN - Sem skip/neverShow. Mostrar se (basicInfoMissing || !hasCompletedAdditional || hasNewRequiredFields): $shouldShowBannerDecision');
      }
      
      // Anulación final: Si toda la info básica está completa, Y los adicionales requeridos están completos, Y no hay nuevos adicionales, no mostrar.
      if (!basicInfoMissing && hasCompletedAdditional && !hasNewRequiredFields) {
        shouldShowBannerDecision = false;
        debugPrint('ℹ️ HOME_SCREEN - Perfil básico completo, adicionais completos e sem novos campos adicionais. Não mostrar banner.');
      }

      debugPrint('🚩 HOME_SCREEN - Decisão final: mostrar banner = $shouldShowBannerDecision');
      if (mounted) {
        final bool previousBannerState = _shouldShowBanner;
        if (previousBannerState != shouldShowBannerDecision || _isBannerLoading) {
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
      if (mounted) { // Asegurar que el widget está montado
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
      debugPrint('✅ HOME_SCREEN - Localizaciones cargadas: ${_churchLocations.length}');
    } catch (e) {
      debugPrint('❌ HOME_SCREEN - Error al cargar localizaciones: $e');
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
          child: Column( // Usar Column para Header + LiveStream + StreamBuilder
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
                    // Logo de la iglesia (sin recorte circular)
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: Image.network(
                        'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2Flogoaem-min.png?alt=media&token=87b1f9ef-41ec-4226-b02b-4413beef869a',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFE94F1A),
                            ),
                            child: const Icon(
                              Icons.church,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Nombre de la iglesia con el mismo estilo que los títulos de sección
                    Expanded(
                                          child: Text(
                        'Amor em Movimento',
                        style: AppTextStyles.headline3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            child: snapshot.hasData && snapshot.data?.data() != null
                                ? _buildUserAvatar(snapshot.data!.data() as Map<String, dynamic>)
                                : const Icon(Icons.person, color: Color(0xFF2F2F2F), size: 24),
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
                      return Center(child: Text('Erro ao carregar seções: ${snapshot.error}'));
                    }
                    // MODIFICACIÓN: Mostrar esqueleto si las secciones están cargando O si la lógica del banner está cargando.
                    if (snapshot.connectionState == ConnectionState.waiting || _isBannerLoading) {
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
                    
                    // Filtrar secciones activas aquí por si acaso (aunque el query ya lo hace)
                    final activeSections = sections.where((s) => s.isActive).toList();
                    // <-- DEBUG PRINT 1

                    return ListView.separated(
                      // Aumentar padding inferior general
                      padding: const EdgeInsets.only(top: 8, bottom: 48), // <-- Aumentado bottom padding
                      itemCount: activeSections.length + 1,
                      separatorBuilder: (context, index) {
                        if (index == 0) return const SizedBox.shrink(); // No hay separador antes del banner

                        // Índice real de la sección *anterior* a la que se le añadirá el separador
                        final previousSectionIndex = index - 1; 
                        // Índice real de la sección *actual* (la que viene después del separador)
                        final currentSectionIndex = index; 

                        // Verificar si estamos a punto de dibujar la sección 'donations'
                        // y si la sección anterior era 'videos'
                        bool showSmallerSeparator = false;
                        // Asegurar que los índices sean válidos para la lista activeSections
                        if (currentSectionIndex < activeSections.length && previousSectionIndex >= 0) { 
                           final currentSection = activeSections[currentSectionIndex];
                           final previousSection = activeSections[previousSectionIndex];
                           
                           // Reducir espacio si la sección actual es Donaciones Y la anterior es Videos
                           if (currentSection.type == HomeScreenSectionType.donations && 
                               previousSection.type == HomeScreenSectionType.videos) {
                                 showSmallerSeparator = true;
                           }
                           // Mantener espacio reducido después de liveStream si es la primera sección real
                           else if (previousSection.type == HomeScreenSectionType.liveStream && previousSectionIndex == 0) {
                              showSmallerSeparator = true; 
                           }
                        }

                        // Aplicar separador pequeño o grande según la condición
                        return SizedBox(height: showSmallerSeparator ? 16.0 : 32.0); 
                       },
                      itemBuilder: (context, index) {
                        // Mostrar Banner primero
                           if (index == 0) {
                              return AnimatedCrossFade(
                                 firstChild: _shouldShowBanner && _userData != null && !_isBannerLoading
                                   ? _buildProfileRequirementsBanner()
                                   : const SizedBox.shrink(),
                                 secondChild: const SizedBox.shrink(),
                                 crossFadeState: _shouldShowBanner && _userData != null && !_isBannerLoading
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
                        // <-- DEBUG PRINT 2

                        // Switch para renderizar el widget adecuado
                        switch (section.type) {
                          case HomeScreenSectionType.liveStream:
                    
                            // StreamBuilder anidado para la configuración del directo
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('app_config').doc('live_stream').snapshots(),
                              builder: (context, liveSnapshot) {
                                if (!liveSnapshot.hasData || !liveSnapshot.data!.exists) {
                                  return const SizedBox.shrink(); // No mostrar si no hay config
                                }
                                final liveConfig = liveSnapshot.data!.data() as Map<String, dynamic>;
                                // final liveConfigDocRef = FirebaseFirestore.instance.collection('app_config').doc('live_stream'); // Ya no se necesita para actualizar

                                // --- Leer configuración (solo isActive) ---
                                final bool isLiveActive = liveConfig['isActive'] ?? false;
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
                                  ? LiveStreamHomeSection(configData: liveConfig, displayTitle: section.title)
                                  : const SizedBox.shrink();
                              },
                            );
                          case HomeScreenSectionType.announcements:
                            // Verificar si debe ocultarse cuando está vacío
                            if (section.hideWhenEmpty) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('announcements')
                                    .where('isActive', isEqualTo: true)
                                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                                      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                                    ))
                                    .limit(1)
                                    .snapshots(),
                                builder: (context, announcementSnapshot) {
                                  if (announcementSnapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  // Si no hay anuncios, ocultar la sección
                                  if (!announcementSnapshot.hasData || announcementSnapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  // Filtrar anuncios válidos para hoy
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  
                                  final hasValidAnnouncements = announcementSnapshot.data!.docs.any((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    final startDate = (data['startDate'] as Timestamp?)?.toDate();
                                    if (startDate == null) return true;
                                    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
                                    return startDateOnly.compareTo(today) <= 0;
                                  });
                                  
                                  return hasValidAnnouncements ? const AnnouncementsSection() : const SizedBox.shrink();
                                },
                              );
                            }
                            return const AnnouncementsSection();
                          case HomeScreenSectionType.cults:
                            return const CultsSection();
                          case HomeScreenSectionType.servicesGrid:
                            return const SizedBox.shrink();
                          case HomeScreenSectionType.events:
                            // Verificar si debe ocultarse cuando está vacío
                            if (section.hideWhenEmpty) {
                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('events')
                                    .where('isActive', isEqualTo: true)
                                    .where('startDate', isGreaterThanOrEqualTo: Timestamp.now())
                                    .limit(1)
                                    .snapshots(),
                                builder: (context, eventSnapshot) {
                                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  // Si no hay eventos futuros, ocultar la sección
                                  if (!eventSnapshot.hasData || eventSnapshot.data!.docs.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return const EventsSection();
                                },
                              );
                            }
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
                              stream: FirebaseFirestore.instance.collection('donationsPage').doc('settings').snapshots(),
                              builder: (context, donationSnapshot) {
                                if (!donationSnapshot.hasData || !donationSnapshot.data!.exists) {
                                  return const SizedBox.shrink(); 
                                }
                                final donationConfig = donationSnapshot.data!.data() as Map<String, dynamic>;
                                // Mostrar el widget de sección/tarjeta, pasando el título y la config
                                return DonationsSection(
                                  title: section.title, // Usar título de homeScreenSections
                                  configData: donationConfig
                                );
                              },
                            );
                          case HomeScreenSectionType.ministries:
                            return MinistriesSection(displayTitle: section.title);
                          case HomeScreenSectionType.groups:
                            return GroupsSection(displayTitle: section.title);
                          case HomeScreenSectionType.privatePrayer:
                            return PrivatePrayerSection(displayTitle: section.title);
                          case HomeScreenSectionType.publicPrayer:
                            return PublicPrayerSection(displayTitle: section.title);
                          case HomeScreenSectionType.unknown:
                          default:
                      return Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Seção desconhecida ou erro: ${section.type}'),
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
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Informação adicional necessária',
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
              'Por favor, complete suas informações adicionais para melhorar sua experiência na igreja.',
              style: AppTextStyles.bodyText2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Verificar cuántas veces ha omitido el banner
                Builder(
                  builder: (context) {
                    final skipCount = _userData?['bannerSkipCount'] as int? ?? 0;
                    
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
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Não mostrar mais',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
                              'lastBannerShown': FieldValue.serverTimestamp(),
                              'bannerSkipCount': FieldValue.increment(1),
                            });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Pular por enquanto',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                AppButton(
                  text: 'Completar agora',
                  onPressed: () {
                    // Muestra el modal para completar la información adicional
                    _showAdditionalInfoModal(context);
                  },
                  isSmall: true,
                ),
              ],
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
      isScrollControlled: true, // Permite que el modal use más altura
      backgroundColor: Colors.transparent, // Fondo transparente para usar el del contenido
      builder: (context) => DraggableScrollableSheet( // Permite desplazar y ajustar altura
        initialChildSize: 0.8, // Altura inicial (80%)
        minChildSize: 0.5, // Altura mínima
        maxChildSize: 0.9, // Altura máxima
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, // Fondo del modal
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const AdditionalInfoScreen(fromBanner: true), // Pasar fromBanner=true
        ),
      ),
    ).then((_) {
      // Cuando el modal se cierre, volver a verificar los requisitos del perfil
      // para actualizar el banner si es necesario.
      _checkProfileRequirements();
    });
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
