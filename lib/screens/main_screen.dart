import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../cubits/navigation_cubit.dart';
import '../widgets/custom_nav_bar.dart';
import '../services/fcm_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'videos/videos_screen.dart';
import 'notifications/notifications_screen.dart';
import 'calendar/calendar_screen.dart';
import '../main.dart'; // Importar para acceder a navigationCubit global

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _hasRequestedPermissions = false;
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = const [
      HomeScreen(),
      NotificationsScreen(),
      CalendarScreen(),
      VideosScreen(),
      ProfileScreen(),
    ];
    
    // Solicitar permisos después de un pequeño retraso para asegurar que la UI esté lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsIfNeeded();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si la app vuelve a primer plano y no hemos solicitado permisos, intentar de nuevo
    if (state == AppLifecycleState.resumed && !_hasRequestedPermissions) {
      _requestPermissionsIfNeeded();
    }
  }
  
  Future<void> _requestPermissionsIfNeeded() async {
    if (_hasRequestedPermissions) return;
    
    try {
      // Esperar un momento para asegurar que no hay overlays activos
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        final fcmService = Provider.of<FCMService>(context, listen: false);
        await fcmService.initializePermissionsAndToken();
        _hasRequestedPermissions = true;
      }
    } catch (e) {
      debugPrint('Error solicitando permisos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar el BlocBuilder con la instancia global explícitamente
    return BlocBuilder<NavigationCubit, NavigationState>(
      bloc: navigationCubit, // Especificar el bloc explícitamente
      builder: (context, state) {
        return Scaffold(
          body: _buildBody(state),
          bottomNavigationBar: const CustomNavBar(),
        );
      },
    );
  }

  Widget _buildBody(NavigationState state) {
    return IndexedStack(
      index: _indexForState(state),
      children: _screens,
    );
  }

  int _indexForState(NavigationState state) {
    switch (state) {
      case NavigationState.home:
        return 0;
      case NavigationState.notifications:
        return 1;
      case NavigationState.calendar:
        return 2;
      case NavigationState.videos:
        return 3;
      case NavigationState.profile:
        return 4;
    }
  }
  
}
