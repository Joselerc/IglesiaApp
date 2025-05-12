import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../cubits/navigation_cubit.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _loginAttempts = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Configurar la barra de estado para que sea visible con color transparente
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _checkAuthState() async {
    debugPrint('🔍 LOGIN_SCREEN - Verificando estado de autenticação inicial');
    
    // Obter diagnósticos do serviço de autenticação
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final diagnostics = await authService.getAuthDiagnostics();
      debugPrint('ℹ️ LOGIN_SCREEN - Diagnósticos de autenticação: $diagnostics');
    } catch (e) {
      debugPrint('⚠️ LOGIN_SCREEN - Erro ao obter diagnósticos: $e');
    }
  }

  Future<void> _login() async {
    // Limpar mensagens de erro anteriores
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      // Incrementar contador de tentativas
      _loginAttempts++;
      debugPrint('🔑 LOGIN_SCREEN - Tentativa de login #$_loginAttempts para: ${_emailController.text.trim()}');
      
      // Obter o serviço de autenticação
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Usar o método melhorado do serviço de autenticação
      final userCredential = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Se chegamos aqui, o login foi bem-sucedido
      debugPrint('✅ LOGIN_SCREEN - Login bem-sucedido para: ${userCredential.user!.uid}');
      
      // Resetar contador de tentativas
      _loginAttempts = 0;
      
      // Navegar para a página principal após o login bem-sucedido
      if (mounted) {
        debugPrint('🧭 LOGIN_SCREEN - Redirecionando para a tela principal');
        
        // Usar la instancia global del NavigationCubit en lugar de buscarlo en el contexto
        navigationCubit.navigateTo(NavigationState.home);
        debugPrint('🧭 LOGIN_SCREEN - NavigationCubit reseteado a HOME');
        
        // Substituir a tela atual pela principal para evitar voltar
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        
        // Mostrar mensagem de boas-vindas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bem-vindo de volta!')),
        );
      }
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ LOGIN_SCREEN - Erro do Firebase Auth: ${e.code} - ${e.message}');
      debugPrint('ℹ️ LOGIN_SCREEN - Informação adicional: ${e.toString()}');
      
      String message;
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Não existe uma conta com este email';
          break;
        case 'wrong-password':
          message = 'Senha incorreta';
          break;
        case 'too-many-requests':
          message = 'Muitas tentativas malsucedidas. Por favor, tente mais tarde.';
          break;
        case 'invalid-credential':
          message = 'Credenciais inválidas. Verifique seu email e senha.';
          break;
        case 'user-disabled':
          message = 'Esta conta foi desativada.';
          break;
        case 'operation-not-allowed':
          message = 'O login com email e senha não está habilitado.';
          break;
        case 'network-request-failed':
          message = 'Erro de conexão. Verifique sua conexão com a Internet.';
          break;
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          message = 'Erro de verificação. Por favor, tente novamente.';
          break;
        case 'captcha-check-failed':
          message = 'A verificação do reCAPTCHA falhou. Por favor, tente novamente.';
          _loginAttempts = 0; // Reiniciar para forçar método diferente
          break;
        default:
          message = 'Erro ao fazer login: ${e.message}';
      }
      
      setState(() {
        _errorMessage = message;
      });
      
    } on TimeoutException catch (e) {
      debugPrint('⏱️ LOGIN_SCREEN - Tempo de espera esgotado: $e');
      setState(() {
        _errorMessage = 'A operação demorou muito. Por favor, tente novamente.';
      });
    } catch (e) {
      debugPrint('⚠️ LOGIN_SCREEN - Erro não categorizado: $e');

      // Mostrar uma mensagem mais específica para o erro de plataforma não compatível
      if (e.toString().contains('only supported on web')) {
        setState(() {
          _errorMessage = 'Erro de plataforma. Por favor, contate o administrador.';
        });
        
        // Tentar realizar um login mais simples como fallback
        _simpleLoginFallback();
      } else {
        setState(() {
          _errorMessage = 'Erro inesperado. Por favor, tente novamente mais tarde.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Método de fallback para um login mais simples
  Future<void> _simpleLoginFallback() async {
    debugPrint('🔄 LOGIN_SCREEN - Tentando método de fallback simples');
    try {
      // Obter diretamente uma nova instância do FirebaseAuth
      final auth = FirebaseAuth.instance;
      
      // Tentar login diretamente sem passos intermediários
      final result = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      debugPrint('✅ LOGIN_SCREEN - Login de fallback bem-sucedido: ${result.user!.uid}');
      
      // Adicionar redirecionamento também para o método de fallback
      if (mounted) {
        debugPrint('🧭 LOGIN_SCREEN - Redirecionando do método de fallback');
        
        // Usar la instancia global del NavigationCubit también en el fallback
        navigationCubit.navigateTo(NavigationState.home);
        debugPrint('🧭 LOGIN_SCREEN - NavigationCubit reseteado a HOME (fallback)');
        
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      debugPrint('❌ LOGIN_SCREEN - Erro no método de fallback: $e');
      // Não mostrar erro ao usuário, pois é uma tentativa de fallback
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔑 LOGIN_SCREEN - Tentando entrar como convidado');
      
      // Iniciar sesión anónima con Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      
      debugPrint('✅ LOGIN_SCREEN - Login como convidado bem-sucedido: ${userCredential.user!.uid}');
      
      // Crear un documento de usuario para el invitado
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': 'Convidado',
        'surname': '',
        'email': '',
        'phone': '',
        'role': 'guest', // Rol específico para invitados
        'roleId': null, // No tiene un rol formal
        'displayName': 'Convidado',
        'photoUrl': '',
        'isGuest': true, // Marcar como usuario invitado
        'createdAt': DateTime.now(),
        'lastLogin': DateTime.now(),
      });
      
      // Registrar inicio de sesión en el historial
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('login_history')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'event': 'guest_login',
        'platform': defaultTargetPlatform.toString(),
      });
      
      if (mounted) {
        // Configurar NavigationCubit
        navigationCubit.navigateTo(NavigationState.home);
        debugPrint('🧭 LOGIN_SCREEN - NavigationCubit redefinido para HOME (convidado)');
        
        // Navegar a la pantalla principal
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        
        // Mostrar mensaje explicativo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bem-vindo! Você está navegando como convidado com funções limitadas.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ LOGIN_SCREEN - Erro ao iniciar sessão como convidado: $e');
      setState(() {
        _errorMessage = 'Não foi possível entrar como convidado. Por favor, tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter o serviço de autenticação
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      // Usando AnnotatedRegion para garantir que a UI do sistema seja visível y estilizada
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo da igreja
                  const SizedBox(height: 40),
                  Center(
                    child: Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2Flogoaem.png?alt=media&token=6cbd3bba-fc29-47f6-8cd6-d7ba2fd8ea0f',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Título da página
                  Text(
                    'Entrar na sua conta',
                    style: AppTextStyles.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bem-vindo de volta! Por favor, faça login para continuar',
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Mensagem de erro se existir
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(color: AppColors.error.withOpacity(0.5)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyText2.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Formulário
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'seu.email@exemplo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Por favor, digite um email válido';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppPasswordField(
                    controller: _passwordController,
                    label: 'Senha',
                    hint: 'Digite sua senha',
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite sua senha';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Futura implementação para recuperar senha
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Esta função estará disponível em breve'),
                          ),
                        );
                      },
                      child: Text(
                        'Esqueceu sua senha?',
                        style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Entrar',
                    onPressed: _isLoading ? null : _login,
                    icon: Icons.login,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  // Botón para entrar como invitado
                  AppButton(
                    text: 'Entrar como Convidado',
                    icon: Icons.person_outline,
                    onPressed: _isLoading ? null : _signInAsGuest,
                    fullWidth: true,
                    isSecondary: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Não tem uma conta?',
                        style: AppTextStyles.bodyText2,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Cadastre-se',
                          style: AppTextStyles.bodyText2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
