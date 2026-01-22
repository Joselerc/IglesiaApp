import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/church_logo.dart'; // Logo optimizado
import '../../cubits/navigation_cubit.dart';
import '../../main.dart'; // Importar para acceder a navigationCubit global
import '../../l10n/app_localizations.dart';
import '../../utils/age_range.dart';
import '../../utils/age_range_localizations.dart';

enum _AgeGateSelection {
  age13To17,
  age18To24,
  age25To30,
  age31To35,
  age36To40,
  age41To50,
  age51To60,
  age61Plus,
  preferNotToSay,
  under13,
}

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

    final strings = AppLocalizations.of(context)!;
    final selection = await _showAgeConfirmationSheet(strings);
    if (!mounted) return;
    if (selection == null) return;

    if (selection == _AgeGateSelection.under13) {
      await _showUnder13BlockedDialog(strings);
      return;
    }

    final AgeRange? ageRange = switch (selection) {
      _AgeGateSelection.age13To17 => AgeRange.from13To17,
      _AgeGateSelection.age18To24 => AgeRange.from18To24,
      _AgeGateSelection.age25To30 => AgeRange.from25To30,
      _AgeGateSelection.age31To35 => AgeRange.from31To35,
      _AgeGateSelection.age36To40 => AgeRange.from36To40,
      _AgeGateSelection.age41To50 => AgeRange.from41To50,
      _AgeGateSelection.age51To60 => AgeRange.from51To60,
      _AgeGateSelection.age61Plus => AgeRange.from61Plus,
      _AgeGateSelection.preferNotToSay => null,
      _AgeGateSelection.under13 => throw StateError('Under13 is blocked'),
    };

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
        'ageRange': ageRange?.firestoreValue,
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
            content: Text(strings.welcomeCompleteProfile),
            duration: const Duration(seconds: 5),
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
          message = strings.emailAlreadyInUse;
          break;
        case 'invalid-email':
          message = strings.invalidEmailFormat;
          break;
        case 'operation-not-allowed':
          message = strings.registrationNotEnabled;
          break;
        case 'weak-password':
          message = strings.weakPassword;
          break;
        default:
          message = strings.errorRegistering(e.message ?? '');
      }
      
      setState(() {
        _errorMessage = message;
      });
      
    } catch (e) {
      debugPrint('❌ Erro inesperado: $e');
      setState(() {
        _errorMessage = strings.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<_AgeGateSelection?> _showAgeConfirmationSheet(
    AppLocalizations strings,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet<_AgeGateSelection>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        _AgeGateSelection? selected = _AgeGateSelection.preferNotToSay;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final options = [
              (_AgeGateSelection.preferNotToSay, strings.ageOptionPreferNotToSay),
              (_AgeGateSelection.age13To17, AgeRange.from13To17.label(strings)),
              (_AgeGateSelection.age18To24, AgeRange.from18To24.label(strings)),
              (_AgeGateSelection.age25To30, AgeRange.from25To30.label(strings)),
              (_AgeGateSelection.age31To35, AgeRange.from31To35.label(strings)),
              (_AgeGateSelection.age36To40, AgeRange.from36To40.label(strings)),
              (_AgeGateSelection.age41To50, AgeRange.from41To50.label(strings)),
              (_AgeGateSelection.age51To60, AgeRange.from51To60.label(strings)),
              (_AgeGateSelection.age61Plus, AgeRange.from61Plus.label(strings)),
              (_AgeGateSelection.under13, strings.ageOptionUnder13),
            ];

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.ageConfirmationTitle,
                              style: AppTextStyles.subtitle2.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            tooltip: strings.close,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.ageConfirmationPrompt,
                        style: AppTextStyles.bodyText2.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            return _AgeGateRadioTile(
                              value: option.$1,
                              groupValue: selected,
                              title: option.$2,
                              onChanged: (value) =>
                                  setModalState(() => selected = value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selected == null
                              ? null
                              : () => Navigator.pop(context, selected),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(strings.continueAction),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showUnder13BlockedDialog(AppLocalizations strings) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.ageConfirmationTitle),
          content: Text(strings.under13RegistrationBlocked),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.back),
            ),
          ],
        );
      },
    );
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

class _AgeGateRadioTile extends StatelessWidget {
  const _AgeGateRadioTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  final _AgeGateSelection value;
  final _AgeGateSelection? groupValue;
  final String title;
  final ValueChanged<_AgeGateSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;
    return RadioListTile<_AgeGateSelection>(
      value: value,
      groupValue: groupValue,
      onChanged: (_) => onChanged(value),
      title: Text(
        title,
        style: AppTextStyles.bodyText2.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      activeColor: colorScheme.primary,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      tileColor: colorScheme.surfaceContainerLowest,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.12),
      selected: isSelected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}
