import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/event_model.dart';
import '../models/announcement_model.dart';
import '../models/profile_field_response.dart';
import 'events/event_detail_screen.dart';
import 'announcements/announcement_detail_screen.dart';
import 'announcements/cult_announcements_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ministries/ministries_list_screen.dart';
import 'groups/groups_list_screen.dart';
import 'prayers/public_prayer_screen.dart';
import 'prayers/private_prayer_screen.dart';
import 'events/events_page.dart';
import 'videos/videos_preview_section.dart';
import 'counseling/counseling_screen.dart';
import '../services/profile_fields_service.dart';
import '../widgets/announcement_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_button.dart';
import 'package:church_app_br/screens/profile/additional_info_screen.dart';
import '../widgets/home/announcements_section.dart';
import '../models/cult.dart';
import 'dynamic_page_viewer_screen.dart';
import '../widgets/home/cults_section.dart';
import '../widgets/home/services_grid_section.dart';
import '../widgets/home/events_section.dart';
import '../widgets/home/counseling_section.dart';
import '../widgets/home/custom_page_list_section.dart';
import '../widgets/home/videos_section.dart';
import '../models/home_screen_section.dart';

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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
    _user = FirebaseAuth.instance.currentUser;
    _checkProfileRequirements();
    _loadChurchLocations();
  }

  Future<void> _checkProfileRequirements() async {
    debugPrint('🔍 HOME_SCREEN - Iniciando verificación de requisitos de perfil');
    if (_user == null) {
      debugPrint('⚠️ HOME_SCREEN - Usuario nulo, no se puede verificar requisitos');
      setState(() {
        _shouldShowBanner = false;
        _isBannerLoading = false;
      });
      return;
    }

    try {
      debugPrint('🔍 HOME_SCREEN - Obteniendo datos del usuario: ${_user!.uid}');
      // Obtener datos del usuario
      final userDoc = await FirebaseFirestore.instance
                  .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('⚠️ HOME_SCREEN - Documento de usuario no existe en Firestore');
        setState(() {
          _shouldShowBanner = false;
          _isBannerLoading = false;
        });
        return;
      }
      
      _userData = userDoc.data();
      debugPrint('✅ HOME_SCREEN - Datos de usuario obtenidos: ${_userData?.keys.toList()}');
      
      // Verificar flags importantes para la lógica del banner
      final neverShowAgain = _userData?['neverShowBannerAgain'] as bool? ?? false;
      final hasSkippedBanner = _userData?['hasSkippedBanner'] as bool? ?? false;
      debugPrint('🚩 HOME_SCREEN - Flags importantes: neverShowAgain=$neverShowAgain, hasSkippedBanner=$hasSkippedBanner');
                
      // Verificar si hay campos de perfil requeridos
      debugPrint('🔍 HOME_SCREEN - Buscando campos de perfil requeridos');
      final requiredFieldsQuery = await FirebaseFirestore.instance
                      .collection('profileFields')
                      .where('isActive', isEqualTo: true)
                      .where('isRequired', isEqualTo: true)
          .get();
      
      _requiredFields = requiredFieldsQuery.docs;
      
      if (_requiredFields!.isEmpty) {
        debugPrint('ℹ️ HOME_SCREEN - No hay campos de perfil requeridos definidos');
        setState(() {
          _shouldShowBanner = false;
          _isBannerLoading = false;
        });
        return;
      }
      
      debugPrint('📋 HOME_SCREEN - Campos requeridos encontrados: ${_requiredFields!.length}');
      for (final doc in _requiredFields!) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('  - Campo: ${data['name'] ?? 'Sin nombre'} (ID: ${doc.id})');
      }
                    
      // Verificar si el usuario ha completado los campos requeridos
      debugPrint('🔍 HOME_SCREEN - Verificando si el usuario ha completado los campos requeridos');
      final profileFieldsService = ProfileFieldsService();
      final hasCompleted = await profileFieldsService.hasCompletedRequiredFields(_user!.uid);
      debugPrint('✅ HOME_SCREEN - Resultado de hasCompletedRequiredFields: $hasCompleted');
      
      // Obtener todas las respuestas del usuario para depuración
      final userResponses = await profileFieldsService.getUserResponses(_user!.uid).first;
      debugPrint('📋 HOME_SCREEN - Respuestas del usuario: ${userResponses.length}');
      for (final response in userResponses) {
        debugPrint('  - Respuesta para ${response.fieldId}: ${response.value}');
      }
                        
      // Si el usuario ya completó los campos requeridos, no mostrar el banner
      if (hasCompleted) {
        debugPrint('✅ HOME_SCREEN - Usuario ha completado todos los campos requeridos');
        setState(() {
          _shouldShowBanner = false;
          _isBannerLoading = false;
        });
        return;
      } else {
        debugPrint('⚠️ HOME_SCREEN - Usuario NO ha completado todos los campos requeridos');
        
        // Identificar qué campos faltan
        for (final field in _requiredFields!) {
          final fieldId = field.id;
          final data = field.data() as Map<String, dynamic>;
          final fieldName = data['name'] ?? 'Sin nombre';
          
          // Buscar respuesta para este campo, pero sin usar firstWhere que causa error
          ProfileFieldResponse? response;
          for (final r in userResponses) {
            if (r.fieldId == fieldId) {
              response = r;
              break;
            }
          }
          
          if (response == null) {
            debugPrint('  ❌ Falta respuesta para: $fieldName (ID: $fieldId)');
          } else if (response.value == null || (response.value is String && (response.value as String).isEmpty)) {
            debugPrint('  ❌ Respuesta vacía para: $fieldName (ID: $fieldId)');
          } else {
            debugPrint('  ✓ Respuesta válida para: $fieldName (ID: $fieldId): ${response.value}');
          }
        }
      }
      
      // Verificar la última actualización de campos adicionales
      final lastUpdated = _userData?['additionalFieldsLastUpdated'] as Timestamp?;
      final lastFieldsUpdate = lastUpdated?.toDate();
      debugPrint('🕒 HOME_SCREEN - Última actualización de campos: ${lastFieldsUpdate?.toIso8601String() ?? "nunca"}');
                        
      // Verificar la última vez que se mostró el banner
      final lastBannerShown = _userData?['lastBannerShown'] as Timestamp?;
      final lastShown = lastBannerShown?.toDate();
      debugPrint('🕒 HOME_SCREEN - Última vez que se mostró el banner: ${lastShown?.toIso8601String() ?? "nunca"}');
                        
      // Verificar si hay nuevos campos requeridos después de la última actualización
      bool hasNewRequiredFields = false;
      if (lastFieldsUpdate != null) {
        for (final doc in _requiredFields!) {
          // Usar data() para acceder a los campos seguros
          final data = doc.data() as Map<String, dynamic>;
          // Verificar si createdAt existe y es un Timestamp
          if (data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            if (createdAt.isAfter(lastFieldsUpdate)) {
              hasNewRequiredFields = true;
              debugPrint('⚠️ HOME_SCREEN - Campo nuevo después de la última actualización: ${data['name'] ?? 'Sin nombre'}');
              break;
            }
          }
        }
      } else {
        // Si nunca ha actualizado campos, considerar que hay nuevos campos
        hasNewRequiredFields = true;
        debugPrint('ℹ️ HOME_SCREEN - Usuario nunca ha actualizado campos, considerando todos como nuevos');
      }
                        
      // Determinar si se debe mostrar el banner
      bool shouldShow = false;
                        
      // Si el usuario eligió no mostrar nunca más, solo mostrar si hay nuevos campos
      if (_userData?['neverShowBannerAgain'] == true) {
        shouldShow = hasNewRequiredFields;
        debugPrint('🔄 HOME_SCREEN - Usuario eligió no mostrar nunca más, pero hay nuevos campos: $hasNewRequiredFields');
      } else if (_userData?['hasSkippedBanner'] == true && lastShown != null) {
        // Si el usuario omitió temporalmente, verificar si han pasado 3 días
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final timeHasPassed = lastShown.isBefore(threeDaysAgo);
        shouldShow = timeHasPassed || hasNewRequiredFields;
        debugPrint('🔄 HOME_SCREEN - Usuario omitió temporalmente - mostrar por tiempo pasado: $timeHasPassed, o por nuevos campos: $hasNewRequiredFields');
      } else {
        // Si no ha omitido ni elegido no mostrar, siempre mostrar
        shouldShow = true;
        debugPrint('🔄 HOME_SCREEN - Mostrar banner porque el usuario no ha elegido omitirlo ni ocultarlo permanentemente');
      }
      
      debugPrint('🚩 HOME_SCREEN - Decisión final: mostrar banner = $shouldShow');
      setState(() {
        _shouldShowBanner = shouldShow;
        _isBannerLoading = false;
      });
      
    } catch (e) {
      debugPrint('❌ HOME_SCREEN - Error al verificar campos requeridos: $e');
      debugPrint('📜 HOME_SCREEN - Stack trace: ${StackTrace.current}');
      setState(() {
        _shouldShowBanner = false;
        _isBannerLoading = false;
      });
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
      SystemUiOverlayStyle(
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
          child: Column( // Usar Column para Header + StreamBuilder
            children: [
              // --- Header Fijo ---
                              Container(
                                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
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
                    Container(
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
              // --- Contenido Dinámico ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('homeScreenSections') // Lee la nueva colección
                      .where('isActive', isEqualTo: true) // Filtra activas
                      .orderBy('order') // Ordena por el campo 'order'
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erro ao carregar seções: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Nenhuma seção configurada.'));
                    }

                    // Mapea los documentos a nuestro modelo
                    final sections = snapshot.data!.docs
                        .map((doc) => HomeScreenSection.fromFirestore(doc))
                        .toList();
                    
                    // Construye la lista de widgets de sección dinámicamente
                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: sections.length + 1, // +1 para el banner
                      separatorBuilder: (context, index) {
                           // Añadir espacio solo entre secciones reales, no antes del banner
                           if (index == 0) return const SizedBox.shrink();
                           // Usar diferente espaciado basado en el tipo de sección si es necesario
                           // Por ahora, un espaciado estándar
                           return const SizedBox(height: 32);
                       },
                      itemBuilder: (context, index) {
                        // Mostrar Banner primero (si es necesario)
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
                           final section = sections[index - 1];

                        // Usa el switch para determinar qué widget renderizar
                        switch (section.type) {
                          case HomeScreenSectionType.announcements:
                            return const AnnouncementsSection();
                          case HomeScreenSectionType.cults:
                            return const CultsSection();
                          case HomeScreenSectionType.servicesGrid:
                            return const ServicesGridSection();
                          case HomeScreenSectionType.events:
                            return const EventsSection();
                          case HomeScreenSectionType.counseling:
                            return const CounselingSection();
                          case HomeScreenSectionType.customPageList:
                            // Pasar los datos reales de title y pageIds
                            return CustomPageListSection(
                              title: section.title, // Pasar el título de la sección
                              pageIds: section.pageIds ?? [], // Pasar la lista de IDs (o lista vacía si es null)
                            );
                          case HomeScreenSectionType.videos:
                            return const VideosSection();
                          case HomeScreenSectionType.unknown:
                          default:
                            // Widget placeholder para tipos desconocidos o errores
                      return Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 16),
                               child: Text('Seção desconhecida: ${section.type}'),
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
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
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
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
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
          child: AdditionalInfoScreen(fromBanner: true), // Pasar fromBanner=true
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
