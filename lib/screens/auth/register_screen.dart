import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/church_logo.dart'; // Logo optimizado
import '../../cubits/navigation_cubit.dart';
import '../../services/role_service.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global
import '../../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Configurar la barra de estado para que sea visible con color transparente
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _register() async {
    // Limpar mensagens de erro anteriores
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Criar usuário no Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Usar rol por defecto simple sin consultar base de datos
      String roleName = 'member'; // Valor por defecto
      
      // Crear documento en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': roleName, // Nombre del rol por defecto
        'displayName': '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        'photoUrl': '',
        'createdAt': DateTime.now(),
        'lastLogin': DateTime.now(),
      });
      
      debugPrint('✅ Usuário registrado com sucesso: ${userCredential.user!.uid}');
      
      // Registrar el primer inicio de sesión en la subcolección de historial
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('login_history')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'event': 'register',
        'platform': defaultTargetPlatform.toString(),
      });
      
      // Redirigir al usuario a la pantalla de perfil para completar su información
      if (mounted) {
        // Asegurarnos de que el NavigationCubit esté configurado correctamente
        navigationCubit.navigateTo(NavigationState.home);
        debugPrint('🧭 REGISTER_SCREEN - NavigationCubit reseteado a HOME');
        
        // Primero navegamos a la pantalla principal
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        
        // Luego mostramos un mensaje de bienvenida
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.welcomeCompleteProfile),
            duration: Duration(seconds: 5),
          ),
        );
        
        // Esperar un momento y luego navegar a la pantalla de perfil
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushNamed('/profile/additional-info', arguments: {'fromBanner': true});
        });
      }
      
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erro do Firebase Auth: ${e.code} - ${e.message}');
      String message;
      
      switch (e.code) {
        case 'email-already-in-use':
          message = AppLocalizations.of(context)!.emailAlreadyInUse;
          break;
        case 'invalid-email':
          message = AppLocalizations.of(context)!.invalidEmailFormat;
          break;
        case 'operation-not-allowed':
          message = AppLocalizations.of(context)!.registrationNotEnabled;
          break;
        case 'weak-password':
          message = AppLocalizations.of(context)!.weakPassword;
          break;
        default:
          message = AppLocalizations.of(context)!.errorRegistering(e.message ?? '');
      }
      
      setState(() {
        _errorMessage = message;
      });
      
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Logo da igreja optimizado - carga instantánea
                  const SizedBox(height: 24),
                  const Center(
                    child: ChurchLogo(
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título da página
                  Text(
                    AppLocalizations.of(context)!.createANewAccount,
                    style: AppTextStyles.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.fillYourDetailsToRegister,
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
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
                  
                  // Formulário de registro
                  AppTextField(
                    controller: _nameController,
                    label: AppLocalizations.of(context)!.name,
                    hint: AppLocalizations.of(context)!.enterYourName,
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterYourName;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppTextField(
                    controller: _surnameController,
                    label: AppLocalizations.of(context)!.surname,
                    hint: AppLocalizations.of(context)!.enterYourSurname,
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterYourSurname;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppTextField(
                    controller: _emailController,
                    label: AppLocalizations.of(context)!.email,
                    hint: AppLocalizations.of(context)!.yourEmailExample,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
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
                  AppTextField(
                    controller: _phoneController,
                    label: AppLocalizations.of(context)!.phoneNumber,
                    hint: AppLocalizations.of(context)!.phoneNumberHint,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isRequired: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (value) {
                      // Solo validar si el usuario ingresó algo
                      if (value != null && value.isNotEmpty && value.length < 10) {
                        return AppLocalizations.of(context)!.pleaseEnterAValidPhone;
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
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterAPassword;
                      }
                      if (value.length < 6) {
                        return AppLocalizations.of(context)!.passwordMustBeAtLeast6Chars;
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppPasswordField(
                    controller: _confirmPasswordController,
                    label: AppLocalizations.of(context)!.confirmPassword,
                    hint: AppLocalizations.of(context)!.enterYourPasswordAgain,
                    prefixIcon: Icons.lock_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.pleaseConfirmYourPassword;
                      }
                      if (value != _passwordController.text) {
                        return AppLocalizations.of(context)!.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: AppLocalizations.of(context)!.createAccount,
                    icon: Icons.app_registration,
                    onPressed: _isLoading ? null : _register,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.alreadyHaveAnAccount,
                        style: AppTextStyles.bodyText2,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          AppLocalizations.of(context)!.login,
                          style: AppTextStyles.bodyText2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Termos e condições
                  Text(
                    AppLocalizations.of(context)!.byRegisteringYouAccept,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedGray),
                    textAlign: TextAlign.center,
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
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
