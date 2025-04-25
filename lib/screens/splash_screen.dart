import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Variable para almacenar la imagen precargada  
  final NetworkImage _logoImage = const NetworkImage(
    'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2FAmor%20em%20Movimento%20Logo.png?alt=media&token=0be077b4-14ef-4f6e-a680-9e15bfa3ba32'
  );
  
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    // Configurar la barra de estado para que sea visible
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Navegar a la pantalla de autenticación después de 2 segundos
    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/auth');
    });
  }

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
                Text(
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
                CircularProgressIndicator(
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
} 