import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/church_logo.dart'; // Nuevo widget de logo optimizado
import '../../cubits/navigation_cubit.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global
import '../../modals/forgot_password_modal.dart';
import '../../l10n/app_localizations.dart';

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
          SnackBar(content: Text(AppLocalizations.of(context)!.welcomeBack)),
        );
      }
      
    } on FirebaseAuthException catch (e) {
      // Log del código de error específico para debugging
      debugPrint('❌ LOGIN_SCREEN - Código de error Firebase: ${e.code}');
      debugPrint('❌ LOGIN_SCREEN - Mensaje de error Firebase: ${e.message}');
      
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = AppLocalizations.of(context)!.noAccountWithThisEmail;
          break;
        case 'wrong-password':
          message = AppLocalizations.of(context)!.incorrectPassword;
          break;
        case 'too-many-requests':
          message = AppLocalizations.of(context)!.tooManyFailedAttempts;
          break;
        case 'invalid-credential':
          message = AppLocalizations.of(context)!.invalidCredentials;
          break;
        case 'user-disabled':
          message = AppLocalizations.of(context)!.accountDisabled;
          break;
        case 'operation-not-allowed':
          message = AppLocalizations.of(context)!.loginNotEnabled;
          break;
        case 'network-request-failed':
          message = AppLocalizations.of(context)!.connectionError;
          break;
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          message = AppLocalizations.of(context)!.verificationError;
          break;
        case 'captcha-check-failed':
          message = AppLocalizations.of(context)!.recaptchaFailed;
          _loginAttempts = 0; // Reiniciar para forçar método diferente
          break;
        default:
          message = AppLocalizations.of(context)!.errorLoggingIn(e.message ?? '');
          // Log de errores no manejados para futuras mejoras
          debugPrint('⚠️ LOGIN_SCREEN - Error no manejado: ${e.code} - ${e.message}');
      }
      
      setState(() {
        _errorMessage = message;
      });
      
    } on TimeoutException catch (e) {
      debugPrint('⏱️ LOGIN_SCREEN - Tempo de espera esgotado: $e');
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.operationTimedOut;
      });
    } catch (e) {
      debugPrint('⚠️ LOGIN_SCREEN - Erro não categorizado: $e');
      debugPrint('⚠️ LOGIN_SCREEN - Stack trace: ${StackTrace.current}');

      // Mostrar una mensagem mais específica para o erro de plataforma não compatível
      if (e.toString().contains('only supported on web')) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.platformError;
        });
        
        // Tentar realizar um login mais simples como fallback
        _simpleLoginFallback();
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.unexpectedError;
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

  void _showForgotPasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForgotPasswordModal(),
    );
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
                  // Logo da igreja - Optimizado para carga instantánea
                  const SizedBox(height: 40),
                  const Center(
                    child: ChurchLogo(
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Título da página
                  Text(
                    AppLocalizations.of(context)!.loginToYourAccount,
                    style: AppTextStyles.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.welcomeBackPleaseLogin,
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
                    label: AppLocalizations.of(context)!.email,
                    hint: AppLocalizations.of(context)!.yourEmailExample,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterYourEmail;
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return AppLocalizations.of(context)!.pleaseEnterAValidEmail;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppPasswordField(
                    controller: _passwordController,
                    label: AppLocalizations.of(context)!.password,
                    hint: AppLocalizations.of(context)!.enterYourPassword,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterYourPassword;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordModal,
                      child: Text(
                        AppLocalizations.of(context)!.forgotYourPassword,
                        style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: AppLocalizations.of(context)!.login,
                    onPressed: _isLoading ? null : _login,
                    icon: Icons.login,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.dontHaveAnAccount,
                        style: AppTextStyles.bodyText2,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          AppLocalizations.of(context)!.signUp,
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
