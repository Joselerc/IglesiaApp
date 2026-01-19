import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // <-- AÑADIR IMPORTACIÓN
import '../widgets/circular_image_picker.dart';
import '../models/user_model.dart';
import '../models/profile_field.dart';
import '../models/profile_field_response.dart';
import '../services/profile_fields_service.dart';
import '../theme/app_colors.dart';
import 'announcements/create_announcement_modal.dart';
import 'notifications/push_notification_screen.dart';
import '../modals/create_ministry_modal.dart';
import '../modals/create_group_modal.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:intl_phone_field/intl_phone_field.dart'; // Usado en la sección comentada
import 'admin/user_role_management_screen.dart';
import 'statistics/ministry_members_stats_screen.dart';
import 'statistics/group_members_stats_screen.dart';
import 'statistics_services/services_stats_screen.dart';
import '../widgets/custom/selection_field.dart';
import 'admin/manage_home_sections_screen.dart';
import '../theme/app_text_styles.dart';
import 'admin/profile_fields_admin_screen.dart';
import 'admin/manage_live_stream_config_screen.dart'; // <-- Import añadido
import 'admin/manage_donations_screen.dart'; // <-- Import añadido
import 'admin/manage_church_locations_screen.dart';
// import 'admin/create_edit_role_screen.dart'; // No se usa directamente
import 'admin/manage_roles_screen.dart'; // <-- Añadir este import
import 'package:iglesia_app/services/permission_service.dart'; // <-- Import PermissionService
import '../services/role_service.dart'; // <-- Import correcto del servicio de roles
import '../services/account_deletion_service.dart'; // <-- Import del servicio de eliminación de cuenta
import 'admin/delete_ministries_screen.dart';
import 'admin/delete_groups_screen.dart';
import 'admin/kids_admin_screen.dart'; // <-- AÑADIR IMPORT PARA LA NUEVA PANTALLA
import 'admin/families_admin_screen.dart';
import 'admin/family_list_screen.dart';
import '../widgets/skeletons/profile_screen_skeleton.dart';
// import '../widgets/skeletons/additional_fields_skeleton.dart'; // No se usa directamente
import './statistics/church_statistics_screen.dart'; // <-- IMPORTAR NUEVA PANTALLA
import '../widgets/profile/profile_additional_fields_section.dart'; // <-- IMPORTAR NUEVO WIDGET
import '../widgets/profile/profile_personal_information_section.dart'; // <-- AÑADIR IMPORT DEL NUEVO WIDGET
import 'events/events_page.dart'; // <-- IMPORT PARA GERENCIAR EVENTOS
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const bool _showMyKidsSection = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  UserModel? _currentUser;
  final ProfileFieldsService _profileFieldsService = ProfileFieldsService();
  final PermissionService _permissionService = PermissionService(); // <-- Instancia del servicio
  final RoleService _roleService = RoleService(); // <-- Instancia del servicio
  
  // Variables para controlar si se muestran las opciones administrativas
  bool _hasAdminAccess = false; // Reemplaza a _isPastor
  bool _isSuperUser = false; // Para verificar si es superusuario
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAdminAccess(); // Nuevo método que reemplaza a _checkPastorStatus
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 CARGANDO DATOS DE USUARIO (ProfileScreen)');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _currentUser = UserModel.fromMap(userData);
            print('PROFILE_SCREEN: _currentUser cargado. Otros campos manejados por widgets hijos.');
          });
        } else {
          print('⚠️ DOCUMENTO DE USUARIO NO EXISTE O COMPONENT NO ESTÁ MONTADO (ProfileScreen)');
        }
      } else {
        print('⚠️ USUARIO NO AUTENTICADO (ProfileScreen)');
      }
    } catch (e) {
      print('❌ ERROR AL CARGAR DATOS DEL USUARIO (ProfileScreen): $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Verificar si el usuario tiene acceso administrativo basado en permisos
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      print('🔍 Verificando acceso administrativo para: ${user.uid}');
      // Comprobar si es SuperAdmin primero
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Si es superusuario, tiene acceso a todo
        if (userData['isSuperUser'] == true) {
        setState(() {
            _hasAdminAccess = true;
            _isSuperUser = true;
            print('✅ SuperUser verificado: Acceso completo otorgado');
          });
          return;
        }
        
        // Si no es superusuario, verificar si tiene roleId
        final String? roleId = userData['roleId'] as String?;
        if (roleId != null && roleId.isNotEmpty) {
          // Buscar el rol para ver sus permisos
          final role = await _roleService.getRoleById(roleId);
          if (role != null && role.permissions.isNotEmpty) {
            // Si tiene al menos un permiso, darle acceso a la sección
         setState(() {
              _hasAdminAccess = true;
              print('✅ Usuario tiene rol con permisos: ${role.name}');
            });
            return;
          }
        }
        
        // Si llegamos aquí, no tiene permiso según el rol, verificar permisos individuales
        setState(() {
          _hasAdminAccess = false;
          print('ℹ️ Usuario no tiene rol con permisos administrativos, verificando permisos individuales...');
        });
        
        // Solo verificamos un permiso para determinar si mostrar la sección
        final hasAnyAdminPermission = await _permissionService.hasPermission('view_user_list');
        if (hasAnyAdminPermission) {
          setState(() {
            _hasAdminAccess = true;
            print('✅ Usuario tiene al menos un permiso administrativo');
          });
          return;
        }
      }
      
      setState(() {
        _hasAdminAccess = false;
        print('ℹ️ Usuario no tiene acceso administrativo');
      });
    } catch (e) {
      print('❌ Error al verificar permisos administrativos: $e');
      if (mounted) {
        setState(() {
          _hasAdminAccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myProfile),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_remove),
            tooltip: AppLocalizations.of(context)!.deleteAccount,
            onPressed: () => AccountDeletionService.showDeleteAccountConfirmation(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting || !userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const ProfileScreenSkeleton(); 
          }
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Sección de cabecera con imagen de perfil
                  Container( // <<< Este es el contenedor azul claro
                    // Añadir width: double.infinity
                    width: double.infinity, 
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircularImagePicker(
                              documentId: FirebaseAuth.instance.currentUser!.uid,
                              currentImageUrl: userData['photoUrl'] as String? ?? '',
                              storagePath: 'user_images',
                              collectionName: 'users',
                              fieldName: 'photoUrl',
                              defaultIcon: const Icon(Icons.person, size: 60, color: Colors.white),
                              size: 100,
                              isEditable: true,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  // Simular el clic en la imagen principal
                                  final imagePicker = ImagePicker();
                                  imagePicker.pickImage(source: ImageSource.gallery);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['displayName'] ?? AppLocalizations.of(context)!.completeYourProfile,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userData['email'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ), // <<< Fin del contenedor azul claro
                  
                  const SizedBox(height: 24),
                  
                  // --- NUEVA SECCIÓN DE INFORMACIÓN ADICIONAL ---
                  // if (FirebaseAuth.instance.currentUser != null)
                  //   ProfileAdditionalFieldsSection(userId: FirebaseAuth.instance.currentUser!.uid),
                  
                  // --- SECCIÓN DE INFORMACIÓN PERSONAL (AHORA UN WIDGET) ---
                  if (FirebaseAuth.instance.currentUser != null)
                    ProfilePersonalInformationSection(userId: FirebaseAuth.instance.currentUser!.uid),
                  
                  const SizedBox(height: 24), // Espacio entre secciones
                  
                  // --- SECCIÓN DE INFORMACIÓN ADICIONAL (WIDGET EXISTENTE) ---
                  if (FirebaseAuth.instance.currentUser != null)
                    ProfileAdditionalFieldsSection(userId: FirebaseAuth.instance.currentUser!.uid),
                  
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  // --- NUEVA SECCIÓN DE ADMINISTRACIÓN (Basada en permisos) ---
                  if (_hasAdminAccess) ...[
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header de la sección admin (Estilo unificado)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08), // Color base para admin
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: AppColors.primary, 
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                      AppLocalizations.of(context)!.administration,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                                    color: AppColors.primary, 
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // --- Lista de Opciones Administrativas --- 
                          
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_donations_config',
                            icon: Icons.volunteer_activism, 
                            title: AppLocalizations.of(context)!.manageDonations,
                            subtitle: AppLocalizations.of(context)!.configureDonationSection,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDonationsScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_church_locations', // Nueva clave de permiso
                            icon: Icons.location_on_outlined, 
                            title: AppLocalizations.of(context)!.manageLocations,
                            subtitle: AppLocalizations.of(context)!.manageLocationsDescription,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageChurchLocationsScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_livestream_config',
                            icon: Icons.live_tv_outlined,
                            title: AppLocalizations.of(context)!.manageLiveStreams,
                            subtitle: AppLocalizations.of(context)!.createEditControlStreams,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageLiveStreamConfigScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_courses',
                            icon: Icons.school, 
                            title: AppLocalizations.of(context)!.manageOnlineCourses,
                            subtitle: AppLocalizations.of(context)!.createEditConfigureCourses,
                            onTap: () => Navigator.pushNamed(context, '/admin/courses'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_home_sections',
                            icon: Icons.view_quilt_outlined,
                            title: AppLocalizations.of(context)!.manageHomeScreen,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageHomeSectionsScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_families_admin',
                            icon: Icons.family_restroom_outlined,
                            title: AppLocalizations.of(context)!.familiesTitle,
                            subtitle: AppLocalizations.of(context)!.manageFamiliesAdmin,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FamiliesAdminScreen()),
                            ),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_pages',
                            icon: Icons.edit_document, 
                            title: AppLocalizations.of(context)!.managePages,
                            subtitle: AppLocalizations.of(context)!.createEditInfoContent,
                            onTap: () => Navigator.pushNamed(context, '/admin/manage-pages'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_counseling_availability',
                            icon: Icons.event_available, 
                            title: AppLocalizations.of(context)!.manageAvailability,
                            subtitle: AppLocalizations.of(context)!.configureCounselingHours,
                            onTap: () => Navigator.pushNamed(context, '/counseling/pastor-availability'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_profile_fields',
                            icon: Icons.list_alt,
                            title: AppLocalizations.of(context)!.manageProfileFields,
                            subtitle: AppLocalizations.of(context)!.configureAdditionalUserFields,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileFieldsAdminScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'assign_user_roles', // Permiso para pantalla antigua
                            icon: Icons.admin_panel_settings,
                            title: AppLocalizations.of(context)!.manageRoles,
                            subtitle: AppLocalizations.of(context)!.assignPastorRoles,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRoleManagementScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_roles', // Permiso para nueva pantalla
                            icon: Icons.assignment_ind_outlined, 
                            title: AppLocalizations.of(context)!.createEditRoles,
                            subtitle: AppLocalizations.of(context)!.createEditRolesAndPermissions,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageRolesScreen())),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_announcements',
                             icon: Icons.campaign, 
                             title: AppLocalizations.of(context)!.createAnnouncements,
                             subtitle: AppLocalizations.of(context)!.createEditChurchAnnouncements,
                             onTap: () => _showCreateAnnouncementModal(context),
                           ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_announcements',
                             icon: Icons.list_alt, 
                             title: AppLocalizations.of(context)!.manageAnnouncements,
                             subtitle: AppLocalizations.of(context)!.clickToSeeMore,
                             onTap: () => Navigator.pushNamed(context, '/admin/announcements'),
                           ),
                          _buildPermissionControlledTile(
                            permissionKey: 'create_events',
                             icon: Icons.event, 
                             title: AppLocalizations.of(context)!.manageEvents,
                             subtitle: AppLocalizations.of(context)!.createManageChurchEvents,
                             onTap: () => Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const EventsPage()),
                             ),
                           ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_videos',
                             icon: Icons.video_library, 
                             title: AppLocalizations.of(context)!.manageVideos,
                             subtitle: AppLocalizations.of(context)!.administerChurchSectionsVideos,
                             onTap: () => Navigator.pushNamed(context, '/videos/manage'),
                           ),
                          _buildPermissionControlledTile( 
                             permissionKey: 'manage_cults',
                             icon: Icons.church,
                             title: AppLocalizations.of(context)!.administerCults,
                             subtitle: AppLocalizations.of(context)!.manageCultsMinistriesSongs,
                             onTap: () => Navigator.pushNamed(context, '/cults'),
                           ),
                          _buildPermissionControlledTile(
                            permissionKey: 'manage_cults',
                            icon: Icons.assignment_outlined,
                            title: AppLocalizations.of(context)!.manageSchedules,
                            subtitle: AppLocalizations.of(context)!.viewAllSentInvitations,
                            onTap: () => Navigator.pushNamed(context, '/manage-work-invites'),
                          ),
                          _buildPermissionControlledTile(
                            permissionKey: 'create_ministry',
                             icon: Icons.add_business_outlined, 
                             title: AppLocalizations.of(context)!.createMinistry,
                             onTap: () => _showCreateMinistryModal(context),
                           ),
                          _buildPermissionControlledTile(
                            permissionKey: 'create_group',
                             icon: Icons.group_add_outlined, 
                             title: AppLocalizations.of(context)!.createConnect,
                             onTap: () => _showCreateGroupModal(context),
                           ),
                          _buildPermissionControlledTile(
                              permissionKey: 'manage_counseling_requests',
                              icon: Icons.support_agent, 
                              title: AppLocalizations.of(context)!.counselingRequests,
                              subtitle: AppLocalizations.of(context)!.manageMemberRequests,
                              onTap: () => Navigator.pushNamed(context, '/counseling/pastor-requests'),
                            ),
                          _buildPermissionControlledTile(
                              permissionKey: 'manage_private_prayers',
                              icon: Icons.favorite_outline, 
                              title: AppLocalizations.of(context)!.privatePrayers,
                              subtitle: AppLocalizations.of(context)!.managePrivatePrayerRequests,
                              onTap: () => Navigator.pushNamed(context, '/prayers/pastor-private-requests'), 
                            ),
                          _buildPermissionControlledTile(
                              permissionKey: 'send_push_notifications',
                              icon: Icons.notifications_active_outlined,
                              title: AppLocalizations.of(context)!.sendPushNotification,
                              subtitle: AppLocalizations.of(context)!.sendMessagesToChurchMembers,
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PushNotificationScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'delete_ministry',
                             icon: Icons.delete_outline, 
                             title: AppLocalizations.of(context)!.deleteMinistries,
                             subtitle: AppLocalizations.of(context)!.removeExistingMinistries,
                             onTap: () => Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (context) => const DeleteMinistriesScreen()
                               )
                             ),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'delete_group',
                             icon: Icons.remove_circle_outline, 
                             title: AppLocalizations.of(context)!.deleteGroups,
                             subtitle: AppLocalizations.of(context)!.removeExistingGroups,
                             onTap: () => Navigator.push(
                               context, 
                               MaterialPageRoute(
                                 builder: (context) => const DeleteGroupsScreen()
                               )
                             ),
                           ),
                  
                          // --- Subsección: Estadísticas y Asistencia --- 
                          // Verificamos primero si el usuario tiene algún permiso de esta sección
                          FutureBuilder<bool>(
                            future: _hasAnyReportPermission(),
                            builder: (context, snapshot) {
                              // No mostrar nada mientras carga o si no tiene permisos
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }
                              
                              // Mostrar la sección solo si tiene al menos un permiso
                              final hasAnyPermission = snapshot.data ?? false;
                              if (!hasAnyPermission) {
                                return const SizedBox.shrink();
                              }
                              
                              // Si tiene permisos, mostrar el encabezado y los elementos
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                           const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
                           Padding(
                             padding: const EdgeInsets.only(left: 20, bottom: 0, top: 8),
                             child: Text(AppLocalizations.of(context)!.reportsAndAttendance, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold)),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'manage_event_attendance',
                             icon: Icons.event_available, 
                             title: AppLocalizations.of(context)!.manageEventAttendance,
                             subtitle: AppLocalizations.of(context)!.checkAttendanceGenerateReports,
                             onTap: () => Navigator.pushNamed(context, '/admin/events'),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_ministry_stats',
                             icon: Icons.bar_chart_outlined,
                             title: AppLocalizations.of(context)!.ministryStatistics,
                             subtitle: AppLocalizations.of(context)!.participationMembersAnalysis,
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MinistryMembersStatsScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_group_stats',
                             icon: Icons.pie_chart_outline, 
                             title: AppLocalizations.of(context)!.groupStatistics,
                             subtitle: AppLocalizations.of(context)!.participationMembersAnalysis,
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupMembersStatsScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_schedule_stats',
                             icon: Icons.assessment_outlined, 
                             title: AppLocalizations.of(context)!.scheduleStatistics,
                             subtitle: AppLocalizations.of(context)!.participationInvitationsAnalysis,
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesStatsScreen())), 
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_course_stats',
                             icon: Icons.analytics_outlined,
                             title: AppLocalizations.of(context)!.courseStatistics,
                             subtitle: AppLocalizations.of(context)!.enrollmentProgressAnalysis,
                             onTap: () => Navigator.pushNamed(context, '/admin/course-stats'),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_user_details',
                             icon: Icons.supervised_user_circle_outlined,
                             title: AppLocalizations.of(context)!.userInfo,
                             subtitle: AppLocalizations.of(context)!.consultParticipationDetails,
                             onTap: () => Navigator.pushNamed(context, '/admin/user-info'),
                           ),
                          _buildPermissionControlledTile(
                             permissionKey: 'view_church_statistics', // NUEVO PERMISO
                             icon: Icons.bar_chart_rounded, // Icono para estadísticas generales
                             title: AppLocalizations.of(context)!.churchStatistics,
                             subtitle: AppLocalizations.of(context)!.membersActivitiesOverview,
                             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChurchStatisticsScreen())),
                           ),
                        ],
                              );
                            },
                      ),

                          // --- Subsección: Gestão MyKids ---
                          if (!_showMyKidsSection) const SizedBox.shrink() else
                          FutureBuilder<bool>(
                            future: _hasAnyMyKidsPermission(), // Llama a la nueva función
                            builder: (context, myKidsPermSnapshot) {
                              if (myKidsPermSnapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(height: 20); // O un pequeño shimmer/loader
                              }
                              // No mostrar nada si hay error o no tiene explícitamente el permiso (myKidsPermSnapshot.data == false)
                              // O si no es SuperUsuario (que ya se maneja en _hasAnyMyKidsPermission)
                              if (myKidsPermSnapshot.hasError || !(myKidsPermSnapshot.data ?? false)) {
                                return const SizedBox.shrink(); 
                              }

                              // Si tiene al menos un permiso de MyKids (o es SuperAdmin), mostrar la sección
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20, bottom: 0, top: 8),
                                    child: Text(AppLocalizations.of(context)!.myKidsManagement, style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                                  ),
                                  _buildPermissionControlledTile(
                                    permissionKey: 'manage_family_profiles', 
                                    icon: Icons.family_restroom_outlined, 
                                    title: AppLocalizations.of(context)!.familyProfiles,
                                    subtitle: AppLocalizations.of(context)!.manageFamilyProfiles,
                                    iconColor: Colors.teal.shade700, 
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const FamilyListScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildPermissionControlledTile(
                                    permissionKey: 'manage_checkin_rooms', 
                                    icon: Icons.meeting_room_outlined, 
                                    title: AppLocalizations.of(context)!.manageRoomsAndCheckin, 
                                    subtitle: AppLocalizations.of(context)!.manageRoomsCheckinDescription, // Usar la nueva clave
                                    iconColor: Colors.teal.shade700, 
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const KidsAdminScreen()));
                                    },
                                  ),
                                  // Aquí se pueden añadir más _buildPermissionControlledTile para otras funciones de MyKids
                                ],
                              );
                            },
                          ),
                        ],
                    ),
                    ),
                  ], // <<< Fin del if (_hasAdminAccess)

                  // Selector de Idioma
                  const SizedBox(height: 32),
                  _buildLanguageSelector(),

                  // Botón de Cerrar Sesión 
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(AppLocalizations.of(context)!.logOut, style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      onPressed: () async {
                        // Mostrar diálogo de confirmación
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.logOut),
                            content: Text(AppLocalizations.of(context)!.sureWantToLogout),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: Text(AppLocalizations.of(context)!.logOut),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          try {
                            // Guardar referencia al AuthService antes de cerrar sesión
                            final authService = Provider.of<AuthService>(context, listen: false);
                            
                            // Ejecutar cierre de sesión sin mostrar diálogo
                            // El AuthWrapper mostrará su propio loading mientras se procesa
                            await authService.forceSignOut();
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true)
                                  .pushNamedAndRemoveUntil('/auth', (route) => false);
                            }
                          } catch (e) {
                            debugPrint("❌ Error al cerrar sesión: $e");
                            
                            // Mostrar mensaje de error solo si falla
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.errorLoggingOut(e.toString())),
                                  backgroundColor: AppColors.error,
                                )
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  
                  // Botón de Diagnóstico SuperUser (herramienta de depuración) - OCULTO
                  // Útil para diagnosticar problemas cuando un usuario con isSuperUser = true
                  // no puede ver las opciones de administración
                  // const SizedBox(height: 16),
                  // Center(
                  //   child: SuperUserDiagnosticWidget.buildDiagnosticButton(
                  //     hasAdminAccess: _hasAdminAccess,
                  //   ),
                  // ),
                  
                  const SizedBox(height: 20),
                  
                  // Contenedor de cambio rápido de usuario ELIMINADO

                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // --- NUEVO: Helper para construir ListTiles controlados por permiso ---
  Widget _buildPermissionControlledTile({
    required String permissionKey,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    // <<< Añadir print para depurar si la función se llama >>>
    print("DEBUG_PROFILE: Intentando construir Tile para permiso: $permissionKey"); 
    
    // El FutureBuilder existente ahora maneja todos los casos
      return FutureBuilder<bool>(
        future: _permissionService.hasPermission(permissionKey),
        builder: (context, snapshot) {
        // No mostrar nada mientras carga (evita parpadeo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); 
          }
        // Si hubo error, tampoco mostrar (podríamos loggear el error)
        if (snapshot.hasError) {
           print("Error al verificar permiso $permissionKey: ${snapshot.error}");
           return const SizedBox.shrink(); 
        }
        // Mostrar el ListTile solo si tiene permiso (o es SuperUser)
          final bool hasPerm = snapshot.data ?? false; 
          if (hasPerm) {
            return _buildAdminListTile(
              icon: icon,
              title: title,
              subtitle: subtitle,
              onTap: onTap,
              iconColor: iconColor,
            );
          } else {
          // Si no tiene permiso, no mostrar nada
            return const SizedBox.shrink();
          }
        },
      );
  }

  // --- Helper original para la apariencia del ListTile ---
  // (Sin cambios)
  Widget _buildAdminListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? AppColors.primary), 
          title: Text(title, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.caption) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
          dense: true,
        ),
        const Divider(height: 1, indent: 70, endIndent: 16),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  // Método para mostrar el modal de creación de anuncios
  void _showCreateAnnouncementModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateAnnouncementModal(),
    );
  }
  
  // Método para mostrar el modal de creación de ministerios
  void _showCreateMinistryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateMinistryModal(),
    );
  }
  
  // Método para mostrar el modal de creación de grupos
  void _showCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupModal(),
    );
  }
  
  
  // Método para verificar si el usuario actual es líder de algún grupo o ministerio
  Future<bool> _isUserLeader() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('🔍 Verificando liderazgo para usuario: ${user?.uid}');
    if (user == null) {
      debugPrint('⚠️ Usuario no autenticado');
      return false;
    }
    
    try {
      // Obtener todos los ministerios y verificar manualmente si el usuario es administrador
      debugPrint('🔍 Consultando ministerios directamente...');
      final ministeriosQuery = await FirebaseFirestore.instance
          .collection('ministries')
          .get();
      
      debugPrint('🔍 Total ministerios: ${ministeriosQuery.docs.length}');
      
      // Verificar cada ministerio si contiene al usuario como admin
      for (var doc in ministeriosQuery.docs) {
        debugPrint('Revisando ministerio: ${doc.id}');
        
        // Intentar todas las posibles variantes de nombres de campo para administradores
        final esAdmin = await _checkIfUserIsAdmin(doc.id, 'ministries', user.uid);
        if (esAdmin) {
          debugPrint('✅ Es líder de ministerio: ${doc.id}');
          return true;
        }
      }
      
      // Obtener todos los grupos y verificar manualmente si el usuario es administrador
      debugPrint('🔍 Consultando grupos directamente...');
      final gruposQuery = await FirebaseFirestore.instance
          .collection('groups')
          .get();
      
      debugPrint('📊 Total grupos: ${gruposQuery.docs.length}');
      
      // Verificar cada grupo si contiene al usuario como admin
      for (var doc in gruposQuery.docs) {
        debugPrint('Revisando grupo: ${doc.id}');
        
        // Intentar todas las posibles variantes de nombres de campo para administradores
        final esAdmin = await _checkIfUserIsAdmin(doc.id, 'groups', user.uid);
        if (esAdmin) {
          debugPrint('✅ Es líder de grupo: ${doc.id}');
          return true;
        }
      }
      
      debugPrint('❌ No se encontró al usuario como líder después de revisar todos los grupos y ministerios');
      return false;
    } catch (e) {
      debugPrint('❌❌ Error al verificar liderazgo: $e');
      return false;
    }
  }
  
  // Método para verificar si un usuario es administrador de una entidad
  Future<bool> _checkIfUserIsAdmin(String entityId, String collectionName, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(entityId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      
      // Lista de posibles nombres de campo para los administradores
      final List<String> possibleAdminFields = [
        'adminIds',
        'ministrieAdmin',
        'ministryAdmin',
        'ministriesAdmin',
        'groupAdmin',
        'groupsAdmin',
        'admins',
        'admin'
      ];
      
      // Revisar cada posible nombre de campo
      for (var fieldName in possibleAdminFields) {
        if (data.containsKey(fieldName)) {
          debugPrint('📋 Campo encontrado: $fieldName');
          
          final fieldValue = data[fieldName];
          
          // Si es una lista, verificar si contiene el ID del usuario
          if (fieldValue is List) {
            final adminList = List<dynamic>.from(fieldValue);
            debugPrint('📋 Lista de admins: $adminList');
            
            // Buscar si el usuario está en la lista de administradores
            for (var admin in adminList) {
              String adminId = '';
              
              // Si es una referencia de documento, extraer el ID
              if (admin is DocumentReference) {
                adminId = admin.id;
                debugPrint('🔍 Referencia encontrada con ID: $adminId');
              } else {
                adminId = admin.toString();
              }
              
              if (adminId == userId) {
                debugPrint('✅ Usuario encontrado como administrador!');
                return true;
              }
            }
          }
          // Si es un solo valor, verificar si es igual al ID del usuario
          else if (fieldValue.toString() == userId) {
            debugPrint('✅ Usuario es el único admin');
            return true;
          }
        }
      }
      
      debugPrint('❌ Usuario no encontrado en ningún campo de administrador');
      return false;
    } catch (e) {
      debugPrint('❌ Error al verificar administrador: $e');
      return false;
    }
  }

  // Método para guardar la información adicional
  Future<void> _guardarInformacionAdicional(
    List<ProfileField> fields,
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> fieldValues
  ) async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Recorrer todos los campos y guardar sus valores
      for (var field in fields) {
        final fieldId = field.id;
        var value = fieldValues[fieldId];
        
        // Para campos de texto, usar el valor del controlador
        if (field.type == 'text' || field.type == 'email' || field.type == 'phone') {
          value = controllers[fieldId]!.text;
        }
        
        // No guardar valores vacíos
        if (value is String && value.trim().isEmpty) {
          continue;
        }
        
        // Crear un objeto de respuesta
        final response = ProfileFieldResponse(
          id: '',
          userId: userId,
          fieldId: fieldId,
          value: value,
          updatedAt: DateTime.now(),
        );
        
        // Guardar la respuesta
        await _profileFieldsService.saveUserResponse(response);
      }
      
      // Actualizar el estado de completado del usuario
      final hasCompleted = await _profileFieldsService.hasCompletedRequiredFields(userId);
      
      // Actualizar el documento del usuario
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hasCompletedAdditionalFields': hasCompleted,
        'additionalFieldsLastUpdated': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.additionalInfoSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar información adicional: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingInfo(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  // Método para construir los widgets de input para cada tipo de campo
  Widget _buildFieldInput(
    ProfileField field,
    TextEditingController controller, // Controller para el campo actual
    Map<String, dynamic> fieldValues, // Mapa que almacena los valores de respuesta actuales
    ProfileFieldResponse initialResponse // Para obtener el valor inicial si no está en fieldValues
  ) {
    final Color primaryColor = const Color(0xFF9C27B0); // Color para la sección adicional
    // Usar el valor de fieldValues si existe; si no, el de la respuesta inicial de Firestore.
    dynamic currentValue = fieldValues.containsKey(field.id) ? fieldValues[field.id] : initialResponse.value;

    // Sincronizar el texto del controlador basado en currentValue
    if (field.type == 'date') {
      DateTime? dateValue;
      if (currentValue is Timestamp) dateValue = currentValue.toDate();
      else if (currentValue is DateTime) dateValue = currentValue;
      // Solo actualizar el texto del controlador si es diferente, para evitar bucles con setState si se usa en onChanged
      final formattedDateText = dateValue != null ? DateFormat('dd/MM/yyyy').format(dateValue) : '';
      if (controller.text != formattedDateText) {
          controller.text = formattedDateText;
      }
    } else if (field.type != 'select') { 
      final currentControllerText = currentValue?.toString() ?? '';
      if (controller.text != currentControllerText) {
        controller.text = currentControllerText;
      }
    }

    switch (field.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'number':
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.name,
            labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
            helperText: field.description,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(_getIconDataForFieldType(field.type), color: primaryColor.withOpacity(0.7)),
            suffixIcon: field.isRequired ? Tooltip(message: AppLocalizations.of(context)!.requiredFieldTooltip, child: Icon(Icons.star, size: 10, color: Colors.red[400])) : null,
          ),
          keyboardType: field.type == 'email' ? TextInputType.emailAddress :
                        field.type == 'phone' ? TextInputType.phone :
                        field.type == 'number' ? TextInputType.number :
                        TextInputType.text,
          validator: (value) {
            if (field.isRequired && (value == null || value.isEmpty)) return AppLocalizations.of(context)!.thisFieldIsRequired;
            return null;
          },
          onChanged: (value) {
            setState(() { 
              if (field.type == 'number') {
                fieldValues[field.id] = int.tryParse(value) ?? value;
              } else {
                fieldValues[field.id] = value;
              }
            });
          },
        );
      
      case 'date':
        return TextFormField(
          controller: controller, 
          readOnly: true,
          decoration: InputDecoration( 
            labelText: field.name,
            labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
            helperText: field.description,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor, width: 2)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(Icons.calendar_today, color: primaryColor.withOpacity(0.7)),
            suffixIcon: field.isRequired ? Tooltip(message: AppLocalizations.of(context)!.requiredFieldTooltip, child: Icon(Icons.star, size: 10, color: Colors.red[400])) : null,
          ),
          onTap: () async {
            DateTime initialPickerDate = DateTime.now();
            if (fieldValues[field.id] is DateTime) {
              initialPickerDate = fieldValues[field.id] as DateTime;
            } else if (fieldValues[field.id] is Timestamp) {
              initialPickerDate = (fieldValues[field.id] as Timestamp).toDate();
            }

            final date = await showDatePicker(
              context: context,
              initialDate: initialPickerDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              locale: const Locale('pt', 'BR'),
              builder: (context, child) { 
                return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white)), child: child!,);
              },
            );
            if (date != null) {
              setState(() { 
                fieldValues[field.id] = date; 
                controller.text = DateFormat('dd/MM/yyyy').format(date);
              });
            }
          },
          validator: (value) {
            if (field.isRequired && fieldValues[field.id] == null) return AppLocalizations.of(context)!.thisFieldIsRequired;
            return null;
          },
        );

      case 'select':
        final options = field.options ?? [];
        String? currentSelectionInFieldValues = fieldValues[field.id] as String?;
        if (currentSelectionInFieldValues != null && !options.contains(currentSelectionInFieldValues)) {
          currentSelectionInFieldValues = null; 
        }

        return SelectionFormField(
          key: ValueKey('profile_screen_select_${field.id}'),
          initialValue: currentSelectionInFieldValues,
          label: field.name,
          hint: field.description ?? 'Seleccione una opción',
          options: options,
          isRequired: field.isRequired,
          prefixIcon: Icon(Icons.list_alt, color: primaryColor.withOpacity(0.7)),
          backgroundColor: Colors.grey[50]!,
          borderRadius: 10,
          onChanged: (value) {
            setState(() { 
              fieldValues[field.id] = value; 
            });
          },
          validator: field.isRequired ? (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.thisFieldIsRequired : null : null,
        );
      
      default:
        return Text(AppLocalizations.of(context)!.unsupportedFieldType(field.type));
    }
  }

  // Método para obtener el ícono específico para cada tipo de campo
  IconData _getIconDataForFieldType(String type) {
    switch (type) {
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'date': return Icons.calendar_today;
      case 'select': return Icons.list;
      case 'number': return Icons.numbers;
      case 'text':
      default: return Icons.text_fields;
    }
  }

  // Función auxiliar para obtener ISO code desde dial code
  String _getIsoCodeFromDialCode(String? dialCode) {
    // Mapeo de códigos de marcación a códigos ISO 2
    final Map<String, String> dialCodeToIso = {
      '+1': 'US',  // Estados Unidos / Canadá
      '+44': 'GB', // Reino Unido
      '+351': 'PT', // Portugal
      '+34': 'ES', // España
      '+49': 'DE', // Alemania
      '+33': 'FR', // Francia
      '+39': 'IT', // Italia
      '+54': 'AR', // Argentina
      '+57': 'CO', // Colombia
      '+52': 'MX', // México
      '+55': 'BR', // Brasil
      '+81': 'JP', // Japón
      '+86': 'CN', // China
      '+91': 'IN', // India
      // Añadir más mapeos según sea necesario
    };

    // Buscar el código ISO correspondiente
    if (dialCode != null && dialCodeToIso.containsKey(dialCode)) {
      return dialCodeToIso[dialCode]!;
    }
    
    // Devolver 'BR' como default si no se encuentra o es nulo
    return 'BR';
  }

  // Método para depuración de permisos
  void _showPermissionDiagnostics(BuildContext context) async {
    try {
      final Map<String, bool> allPermissions = await _permissionService.getAllPermissions();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (!mounted || userId == null) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Diagnóstico de Permisos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Lista de permisos
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Obtener datos del usuario actual
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text(AppLocalizations.of(context)!.noUserData);
                        }
                        
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final roleId = userData['roleId'] as String?;
                        final isSuperUser = userData['isSuperUser'] == true;
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuario: ${userData['displayName'] ?? 'Sin nombre'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${AppLocalizations.of(context)!.email}: ${userData['email'] ?? 'Sin email'}'),
                                Text('${AppLocalizations.of(context)!.roleId}: ${roleId ?? 'Sin rol'}'),
                                Text('${AppLocalizations.of(context)!.superUser}: ${isSuperUser ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Título de la sección
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Permisos Disponibles',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    // Lista de permisos con su estado
                    ...allPermissions.entries.map((entry) {
                      final String permissionKey = entry.key;
                      final bool hasPermission = entry.value;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: hasPermission ? Colors.green.shade50 : Colors.grey.shade100,
                        child: ListTile(
                          title: Text(
                            permissionKey,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Icon(
                            hasPermission ? Icons.check_circle : Icons.cancel,
                            color: hasPermission ? Colors.green : Colors.red.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                    
                    // Sección de diagnóstico de rol
                    FutureBuilder<String?>(
                      future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get()
                            .then((doc) => doc.data()?['roleId'] as String?),
                      builder: (context, roleIdSnapshot) {
                        if (roleIdSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final String? roleId = roleIdSnapshot.data;
                        if (roleId == null || roleId.isEmpty) {
                          return Card(
                            margin: const EdgeInsets.only(top: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(AppLocalizations.of(context)!.noRoleInfoAvailable),
                            ),
                          );
                        }
                        
                        return FutureBuilder<dynamic>(
                          future: _roleService.getRoleById(roleId),
                          builder: (context, roleSnapshot) {
                            if (roleSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final role = roleSnapshot.data;
                            if (role == null) {
                              return Card(
                                margin: const EdgeInsets.only(top: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(AppLocalizations.of(context)!.roleNotFound(roleId)),
                                ),
                              );
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(top: 16),
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rol: ${role.name}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (role.description != null && role.description!.isNotEmpty)
                                      Text('${AppLocalizations.of(context)!.description}: ${role.description}'),
                                    const SizedBox(height: 8),
                                    Text(AppLocalizations.of(context)!.rolePermissions),
                                    const SizedBox(height: 4),
                                    if (role.permissions.isEmpty)
                                      Text(AppLocalizations.of(context)!.thisRoleHasNoPermissions)
                                    else
                                      ...role.permissions.map((permission) => Padding(
                                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check, size: 16, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Text(permission),
                                          ],
                                        ),
                                      )),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorObtainingDiagnostic(e.toString()))),
        );
      }
    }
  }

  // Verificar si el usuario tiene algún permiso relacionado con informes y estadísticas
  Future<bool> _hasAnyReportPermission() async {
    // Lista de permisos relacionados con informes y estadísticas
    final reportPermissions = [
      'view_church_statistics', // AÑADIR NUEVO PERMISO AQUÍ
      'manage_event_attendance',
      'view_ministry_stats',
      'view_group_stats',
      'view_schedule_stats',
      'view_user_details'
    ];
    
    // Comprobamos primero si es superusuario
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    
    if (userDoc.exists && userDoc.data()?['isSuperUser'] == true) {
      return true;
    }
    
    // Verificamos cada permiso de la lista
    for (final permission in reportPermissions) {
      if (await _permissionService.hasPermission(permission)) {
        return true;
      }
    }
    
    return false;
  }

  // NUEVA FUNCIÓN PARA VERIFICAR PERMISOS DE MYKIDS
  Future<bool> _hasAnyMyKidsPermission() async {
    final List<String> myKidsPermissions = [
      'manage_family_profiles',
      'manage_checkin_rooms',
      // Añadir aquí cualquier otro permiso futuro de MyKids
    ];
    // Comprobar si es SuperAdmin primero, ya que tiene todos los permisos
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['isSuperUser'] == true) {
        return true;
      }
    }
    // Verificar permisos individuales
    for (final permission in myKidsPermissions) {
      if (await _permissionService.hasPermission(permission)) {
        return true;
      }
    }
    return false;
  }


  // Verifica si el usuario puede eliminar grupos o ministerios
  Future<bool> _canDeleteGroupsOrMinistries() async {
    try {
      // Verificar si es superusuario primero
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()?['isSuperUser'] == true) {
        return true;
      }
      
      // Verificar permisos específicos
      final canDeleteGroups = await _permissionService.hasPermission('delete_group');
      final canDeleteMinistries = await _permissionService.hasPermission('delete_ministry');
      
      return canDeleteGroups || canDeleteMinistries;
    } catch (e) {
      print('Error al verificar permisos de eliminación: $e');
      return false;
    }
  }
  
  // Construye la pestaña para eliminar grupos
  Widget _buildDeleteGroupsTab() {
    return FutureBuilder<bool>(
      future: _permissionService.hasPermission('delete_group'),
      builder: (context, permissionSnapshot) {
        final bool canDeleteGroups = permissionSnapshot.data ?? false;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar grupos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay grupos disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final groups = snapshot.data!.docs;
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final group = groups[index];
                final groupData = group.data() as Map<String, dynamic>;
                final groupName = groupData['name'] as String? ?? 'Grupo sin nombre';
                final groupId = group.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.group, color: Colors.blue),
                  ),
                  title: Text(groupName),
                  subtitle: Text('${AppLocalizations.of(context)!.id}: $groupId'),
                  trailing: canDeleteGroups
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteGroup(groupId, groupName),
                        )
                      : const Icon(Icons.lock, color: Colors.grey),
                );
              },
            );
          },
        );
      },
    );
  }
  
  // Construye la pestaña para eliminar ministerios
  Widget _buildDeleteMinistriesTab() {
    return FutureBuilder<bool>(
      future: _permissionService.hasPermission('delete_ministry'),
      builder: (context, permissionSnapshot) {
        final bool canDeleteMinistries = permissionSnapshot.data ?? false;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('ministries').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar ministerios: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay ministerios disponibles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final ministries = snapshot.data!.docs;
            
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ministries.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final ministry = ministries[index];
                final ministryData = ministry.data() as Map<String, dynamic>;
                final ministryName = ministryData['name'] as String? ?? 'Ministerio sin nombre';
                final ministryId = ministry.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade100,
                    child: const Icon(Icons.work_outline, color: Colors.amber),
                  ),
                  title: Text(ministryName),
                  subtitle: Text('${AppLocalizations.of(context)!.id}: $ministryId'),
                  trailing: canDeleteMinistries
                      ? IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteMinistry(ministryId, ministryName),
                        )
                      : const Icon(Icons.lock, color: Colors.grey),
                );
              },
            );
          },
        );
      },
    );
  }
  
  // Confirmar y eliminar un grupo
  Future<void> _confirmDeleteGroup(String groupId, String groupName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteGroup),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              TextSpan(text: AppLocalizations.of(context)!.deleteGroupConfirmationPrefix),
              TextSpan(
                text: groupName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'), // Se mantiene el signo de interrogación aquí
              TextSpan(
                text: AppLocalizations.of(context)!.deleteGroupWarning,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance.collection('groups').doc(groupId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.groupDeletedSuccessfully(groupName)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.errorDeletingGroup}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  // Confirmar y eliminar un ministerio
  Future<void> _confirmDeleteMinistry(String ministryId, String ministryName) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMinistry),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              TextSpan(text: AppLocalizations.of(context)!.deleteMinistryConfirmationPrefix),
              TextSpan(
                text: ministryName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'), // Se mantiene el signo de interrogación aquí
              TextSpan(
                text: AppLocalizations.of(context)!.deleteMinistryWarning,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance.collection('ministries').doc(ministryId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.ministryDeletedSuccessfully(ministryName)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.errorDeletingMinistry}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Método para construir el selector de idioma
  Widget _buildLanguageSelector() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final currentLocale = languageService.locale.languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.language, color: AppColors.primary),
            title: Text(
              AppLocalizations.of(context)!.language,
              style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.selectYourPreferredLanguage,
              style: AppTextStyles.caption,
            ),
            dense: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildLanguageOption(
                    languageCode: 'es',
                    languageName: AppLocalizations.of(context)!.spanish,
                    flag: '🇪🇸',
                    isSelected: currentLocale == 'es',
                    onTap: () => _changeLanguage('es'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLanguageOption(
                    languageCode: 'pt',
                    languageName: AppLocalizations.of(context)!.portugueseBrazil,
                    flag: '🇧🇷',
                    isSelected: currentLocale == 'pt',
                    onTap: () => _changeLanguage('pt'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 70, endIndent: 16),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String languageCode,
    required String languageName,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              languageName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    await languageService.setLanguage(languageCode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageChangedSuccessfully),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 
