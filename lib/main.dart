import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'screens/main_screen.dart';
import 'screens/profile/additional_info_screen.dart';
import 'screens/announcements/announcement_detail_screen.dart';
import 'screens/admin/profile_fields_admin_screen.dart';
import 'screens/counseling/counseling_screen.dart';
import 'screens/counseling/pastor_availability_screen.dart';
import 'screens/counseling/pastor_requests_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/admin/admin_events_list_screen.dart';
import 'screens/admin/attendance_stats_screen.dart';
import 'screens/admin/work_stats_screen.dart';
import 'screens/admin/culto_stats_screen.dart';
import 'screens/prayers/public_prayer_screen.dart';
import 'screens/prayers/private_prayer_screen.dart';
import 'screens/prayers/pastor_private_prayers_screen.dart';
import 'screens/courses/courses_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/courses/lesson_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/event_service.dart';
import 'services/work_schedule_service.dart';
import 'cubits/navigation_cubit.dart';
import 'screens/auth/auth_wrapper.dart';
import 'firebase_options.dart';
import 'screens/ministries/ministries_list_screen.dart';
import 'screens/groups/groups_list_screen.dart';
import 'screens/ministries/ministry_event_detail_screen.dart';
import 'screens/groups/group_event_detail_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/cults/cult_detail_screen.dart';
import 'screens/cults/services_screen.dart';
import 'models/ministry_event.dart';
import 'models/group_event.dart';
import 'models/event_model.dart';
import 'models/cult.dart';
import 'models/announcement_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/videos/videos_screen.dart';
import 'screens/videos/manage_sections_screen.dart';
import 'screens/work_invites/work_services_screen.dart';
import 'screens/admin/user_info_screen.dart';
import 'screens/design_reference_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/admin/manage_pages_screen.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'screens/admin/manage_courses_screen.dart';
import 'screens/admin/course_stats_screen.dart';
import 'screens/admin/course_enrollment_stats_screen.dart';
import 'screens/admin/course_progress_stats_screen.dart';
import 'screens/admin/course_completion_stats_screen.dart';
import 'screens/admin/course_milestone_stats_screen.dart';
import 'screens/admin/course_detail_stats_screen.dart';

// Crear una instancia global del NavigationCubit que todos pueden acceder
final NavigationCubit navigationCubit = NavigationCubit();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Agregar un listener al NavigationCubit para depuración
  navigationCubit.stream.listen((state) {
    debugPrint('🧭 NAVIGATION_CUBIT - Estado cambiado a: $state');
  });
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Crear e inicializar el servicio de notificaciones
  final notificationService = NotificationService();
  
  // Inicializar los datos de localización para formateo de fechas
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
  
  // Configurar las localizaciones de timeago
  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
  timeago.setDefaultLocale('pt_BR');
  
  // Migrar datos existentes
  try {
    await WorkScheduleService().migrateExistingInvitations();
  } catch (e) {
    debugPrint('Error al migrar datos: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        // Proporcionar AuthService
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        // Proporcionar NotificationService como un singleton
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => navigationCubit,
        ),
      ],
      child: MaterialApp(
        title: 'Church App',
        navigatorKey: EventService.navigatorKey,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),  // Português (Brasil)
        ],
        locale: const Locale('pt', 'BR'),
        routes: {
          '/auth': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainScreen(),
          '/admin/profile-fields': (context) => const ProfileFieldsAdminScreen(),
          '/profile/additional-info': (context) => AdditionalInfoScreen(
            fromBanner: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['fromBanner'] as bool? ?? false,
          ),
          '/ministries': (context) => const MinistriesListScreen(),
          '/groups': (context) => const GroupsListScreen(),
          '/counseling': (context) => const CounselingScreen(),
          '/counseling/pastor-availability': (context) => const PastorAvailabilityScreen(),
          '/counseling/pastor-requests': (context) => const PastorRequestsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/admin/events': (context) => const AdminEventsListScreen(),
          '/admin/attendance-stats': (context) => const AttendanceStatsScreen(),
          '/admin/work-stats': (context) => const WorkStatsScreen(),
          '/admin/culto-stats': (context) => const CultoStatsScreen(),
          '/cults': (context) => const ServicesScreen(),
          '/services': (context) => const ServicesScreen(),
          '/prayers/public': (context) => const PublicPrayerScreen(),
          '/prayers/private': (context) => const PrivatePrayerScreen(),
          '/prayers/pastor-private-requests': (context) => const PastorPrivatePrayersScreen(),
          '/videos': (context) => const VideosScreen(),
          '/videos/manage': (context) => const ManageSectionsScreen(),
          '/work-services': (context) => const WorkServicesScreen(),
          '/admin/user-info': (context) => const UserInfoScreen(),
          '/design-reference': (context) => const DesignReferenceScreen(),
          '/admin/manage-pages': (context) => const ManagePagesScreen(),
          '/admin/courses': (context) => const ManageCoursesScreen(),
          '/admin/course-stats': (context) => const CourseStatsScreen(),
          '/admin/course-stats/enrollments': (context) => const CourseEnrollmentStatsScreen(),
          '/admin/course-stats/progress': (context) => const CourseProgressStatsScreen(),
          '/admin/course-stats/completion': (context) => const CourseCompletionStatsScreen(),
          '/admin/course-stats/milestones': (context) => const CourseMilestoneStatsScreen(),
          '/admin/course-stats/detail': (context) {
            final courseId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return CourseDetailStatsScreen(courseId: courseId);
          },
          '/courses': (context) => const CoursesScreen(),
          '/courses/detail': (context) {
            final courseId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return CourseDetailScreen(courseId: courseId);
          },
          '/courses/lesson': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>? ?? {};
            final courseId = args['courseId'] ?? '';
            final lessonId = args['lessonId'] ?? '';
            return LessonScreen(courseId: courseId, lessonId: lessonId);
          },
        },
        onGenerateRoute: (settings) {
          // Manejar rutas dinámicas
          final uri = Uri.parse(settings.name!);
          final pathSegments = uri.pathSegments;
          
          // Ruta para eventos de ministerios
          if (pathSegments.length == 4 && 
              pathSegments[0] == 'ministries' && 
              pathSegments[2] == 'events') {
            final eventId = pathSegments[3];
            
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ministry_events')
                    .doc(eventId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(child: Text('Evento no encontrado')),
                    );
                  }
                  
                  final event = MinistryEvent.fromFirestore(snapshot.data!);
                  return MinistryEventDetailScreen(event: event);
                },
              ),
            );
          }
          
          // Ruta para eventos de grupos
          if (pathSegments.length == 4 && 
              pathSegments[0] == 'groups' && 
              pathSegments[2] == 'events') {
            final eventId = pathSegments[3];
            
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('group_events')
                    .doc(eventId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(child: Text('Evento no encontrado')),
                    );
                  }
                  
                  final event = GroupEvent.fromFirestore(snapshot.data!);
                  return GroupEventDetailScreen(event: event);
                },
              ),
            );
          }
          
          // Ruta para eventos generales
          if (pathSegments.length == 2 && pathSegments[0] == 'events') {
            final eventId = pathSegments[1];
            
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('events')
                    .doc(eventId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(child: Text('Evento no encontrado')),
                    );
                  }
                  
                  // Usar la pantalla de detalle real para eventos generales
                  final event = EventModel.fromFirestore(snapshot.data!);
                  return EventDetailScreen(event: event);
                },
              ),
            );
          }
          
          // Ruta para cultos
          if (pathSegments.length == 2 && pathSegments[0] == 'cults') {
            final cultId = pathSegments[1];
            
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<QuerySnapshot>(
                // Buscar el anuncio relacionado con este culto
                future: FirebaseFirestore.instance
                    .collection('announcements')
                    .where('type', isEqualTo: 'cult')
                    .where('cultId', isEqualTo: cultId)
                    .limit(1)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  // Si encontramos un anuncio relacionado, mostrarlo
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final announcement = AnnouncementModel.fromFirestore(snapshot.data!.docs.first);
                    return AnnouncementDetailScreen(announcement: announcement);
                  }
                  
                  // Si no hay anuncio, cargar el culto y mostrar su detalle
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('cults')
                        .doc(cultId)
                        .get(),
                    builder: (context, cultSnapshot) {
                      if (cultSnapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      if (!cultSnapshot.hasData || !cultSnapshot.data!.exists) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('Error')),
                          body: const Center(child: Text('Culto no encontrado')),
                        );
                      }
                      
                      final cult = Cult.fromFirestore(cultSnapshot.data!);
                      return CultDetailScreen(cult: cult);
                    },
                  );
                },
              ),
            );
          }
          
          return null;
        },
      ),
    );
  }
}
