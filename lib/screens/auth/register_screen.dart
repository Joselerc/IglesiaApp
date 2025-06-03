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
import '../../cubits/navigation_cubit.dart';
import '../../services/role_service.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global

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
          const SnackBar(
            content: Text('Bem-vindo! Complete seu perfil para aproveitar todas as funções.'),
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
          message = 'Já existe uma conta com este email';
          break;
        case 'invalid-email':
          message = 'O formato do email não é válido';
          break;
        case 'operation-not-allowed':
          message = 'O registro com email e senha não está habilitado';
          break;
        case 'weak-password':
          message = 'A senha é muito fraca, tente uma mais segura';
          break;
        default:
          message = 'Erro ao registrar: ${e.message}';
      }
      
      setState(() {
        _errorMessage = message;
      });
      
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      setState(() {
        _errorMessage = 'Erro inesperado. Por favor, tente novamente mais tarde.';
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
                  // Logo da igreja
                  const SizedBox(height: 24),
                  Center(
                    child: Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/churchappbr.firebasestorage.app/o/Logo%2Flogoaem.png?alt=media&token=6cbd3bba-fc29-47f6-8cd6-d7ba2fd8ea0f',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título da página
                  const Text(
                    'Criar uma nova conta',
                    style: AppTextStyles.headline2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preencha seus dados para se cadastrar',
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
                    label: 'Nome',
                    hint: 'Digite seu nome',
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu nome';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppTextField(
                    controller: _surnameController,
                    label: 'Sobrenome',
                    hint: 'Digite seu sobrenome',
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu sobrenome';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'seu.email@exemplo.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
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
                  AppTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    hint: '(00) 00000-0000',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite seu telefone';
                      }
                      if (value.length < 10) {
                        return 'Por favor, digite um telefone válido';
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
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite uma senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  AppSpacing.verticalSpacerMD,
                  AppPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Senha',
                    hint: 'Digite sua senha novamente',
                    prefixIcon: Icons.lock_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Criar Conta',
                    icon: Icons.app_registration,
                    onPressed: _isLoading ? null : _register,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Já tem uma conta?',
                        style: AppTextStyles.bodyText2,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Entrar',
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
                    'Ao se cadastrar, você aceita nossos termos e condições e nossa política de privacidade.',
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
