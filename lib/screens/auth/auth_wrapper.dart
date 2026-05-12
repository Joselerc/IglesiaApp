import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iglesia_app/screens/main_screen.dart';
import 'package:iglesia_app/screens/auth/login_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/church_logo.dart'; // Logo optimizado
import '../../cubits/navigation_cubit.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Sistema UI configurado una sola vez
  static bool _systemUIConfigured = false;
  
  @override
  void initState() {
    super.initState();
    _configureSystemUI();
  }
  
  void _configureSystemUI() {
    if (!_systemUIConfigured) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      _systemUIConfigured = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sistema UI ya configurado en initState - no necesario repetir
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
              child: const SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Algo deu errado!',
                        style: AppTextStyles.headline3,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tente novamente mais tarde',
                        style: AppTextStyles.bodyText1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (FirebaseAuth.instance.currentUser != null) {
            navigationCubit.navigateTo(NavigationState.home);
            return const MainScreen();
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo de la iglesia optimizado
                      const ChurchLogo(
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Bem-vindo',
                        style: AppTextStyles.headline1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conectando você à sua comunidade',
                        style: AppTextStyles.subtitle1.copyWith(color: AppColors.secondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // Asegurarnos de que el NavigationCubit esté configurado correctamente
          navigationCubit.navigateTo(NavigationState.home);
          debugPrint('🧭 AUTH_WRAPPER - NavigationCubit reseteado a HOME');
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
} 