import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:igreja_amor_em_movimento/screens/auth/login_screen.dart';
import 'package:igreja_amor_em_movimento/screens/main_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../cubits/navigation_cubit.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Variable para almacenar la imagen precargada  
  final NetworkImage _logoImage = const NetworkImage(
    'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2FAmor%20em%20Movimento%20Logo.png?alt=media&token=0be077b4-14ef-4f6e-a680-9e15bfa3ba32'
  );
  
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Precargar la imagen después de que el widget está completamente montado
    precacheImage(_logoImage, context).then((_) {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Configurar la barra de estado para que sea visible
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
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
                      // Logo de la iglesia con imagen precargada
                      Image(
                        image: _logoImage,
                        height: 150,
                        fit: BoxFit.contain,
                        // Si hay error o mientras carga, mostrar un contenedor del mismo tamaño
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: 150,
                            color: Colors.transparent,
                          );
                        },
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