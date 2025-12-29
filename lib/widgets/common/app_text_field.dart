import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_input_styles.dart';
import '../../theme/app_text_styles.dart';

/// Campo de texto reutilizable con estilos consistentes
class AppTextField extends StatelessWidget {
  /// Controller para el campo de texto
  final TextEditingController? controller;
  
  /// Etiqueta para mostrar
  final String label;
  
  /// Texto de ayuda para mostrar
  final String? hint;
  
  /// Texto de ayuda adicional
  final String? helperText;
  
  /// Mensaje de error
  final String? errorText;
  
  /// Función para validar el contenido
  final String? Function(String?)? validator;
  
  /// Acción para cuando cambia el texto
  final void Function(String)? onChanged;
  
  /// Acción para cuando se envía el formulario
  final void Function(String)? onSubmitted;
  
  /// Si es un campo obligatorio
  final bool isRequired;
  
  /// Si es un campo de contraseña
  final bool isPassword;
  
  /// Si es un campo de texto multilinea
  final bool isMultiline;
  
  /// Si es un campo de búsqueda
  final bool isSearchField;
  
  /// Icono para mostrar antes del texto
  final IconData? prefixIcon;
  
  /// Widget personalizado para mostrar antes del texto
  final Widget? prefixWidget;
  
  /// Icono para mostrar después del texto
  final IconData? suffixIcon;
  
  /// Widget personalizado para mostrar después del texto
  final Widget? suffixWidget;
  
  /// Número máximo de caracteres
  final int? maxLength;
  
  /// Número máximo de líneas
  final int? maxLines;
  
  /// Formateadores para el campo
  final List<TextInputFormatter>? inputFormatters;
  
  /// Tipo de teclado
  final TextInputType? keyboardType;
  
  /// Acción del teclado
  final TextInputAction? textInputAction;
  
  /// Si el campo está habilitado
  final bool enabled;

  /// Si el campo es solo lectura (no abre teclado)
  final bool readOnly;

  /// Acción al tocar el campo (útil para date pickers)
  final VoidCallback? onTap;
  
  /// Foco para el campo
  final FocusNode? focusNode;
  
  /// Si se autoenfoca
  final bool autofocus;

  const AppTextField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.isRequired = false,
    this.isPassword = false,
    this.isMultiline = false,
    this.isSearchField = false,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.suffixWidget,
    this.maxLength,
    this.maxLines,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Configurar decoración según el tipo
    final InputDecoration decoration;
    
    if (isSearchField) {
      decoration = AppInputStyles.searchFieldDecoration(
        hintText: hint ?? 'Buscar...',
        prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon) : null),
        suffixIcon: suffixWidget ?? (suffixIcon != null ? Icon(suffixIcon) : null),
      );
    } else if (isMultiline) {
      decoration = AppInputStyles.textAreaDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
      );
    } else {
      decoration = AppInputStyles.textFieldDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon) : null),
        suffixIcon: suffixWidget ?? (suffixIcon != null ? Icon(suffixIcon) : null),
      );
    }
    
    // Validador mejorado con sanitización
    String? Function(String?)? enhancedValidator;
    if (validator != null) {
      enhancedValidator = (value) {
        // Sanitizar entrada básica
        final sanitizedValue = value?.trim();
        
        // Validaciones de seguridad básicas
        if (sanitizedValue != null && sanitizedValue.isNotEmpty) {
          // Prevenir inyección de scripts básica
          if (sanitizedValue.contains('<script') || 
              sanitizedValue.contains('javascript:') ||
              sanitizedValue.contains('data:text/html')) {
            return 'Conteúdo não permitido detectado';
          }
          
          // Validación de longitud máxima
          if (maxLength != null && sanitizedValue.length > maxLength!) {
            return 'Máximo $maxLength caracteres permitidos';
          }
        }
        
        return validator!(sanitizedValue);
      };
    }
    
    // Construir campo según el tipo
    return TextFormField(
      controller: controller,
      decoration: decoration,
      style: AppTextStyles.bodyText1,
      obscureText: isPassword,
      readOnly: readOnly,
      maxLength: maxLength,
      maxLines: isMultiline ? (maxLines ?? 5) : (isPassword ? 1 : maxLines),
      validator: enhancedValidator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType ?? (isMultiline ? TextInputType.multiline : TextInputType.text),
      textInputAction: textInputAction ?? (isMultiline ? TextInputAction.newline : TextInputAction.next),
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// Campo de contraseña con visibilidad alternante
class AppPasswordField extends StatefulWidget {
  /// Controller para el campo
  final TextEditingController? controller;
  
  /// Etiqueta para mostrar
  final String label;
  
  /// Texto de ayuda para mostrar
  final String? hint;
  
  /// Mensaje de error
  final String? errorText;
  
  /// Función para validar el contenido
  final String? Function(String?)? validator;
  
  /// Acción para cuando cambia el texto
  final void Function(String)? onChanged;
  
  /// Si es un campo obligatorio
  final bool isRequired;
  
  /// Si el campo está habilitado
  final bool enabled;
  
  /// Icono para mostrar antes del texto
  final IconData? prefixIcon;

  const AppPasswordField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.onChanged,
    this.isRequired = true,
    this.enabled = true,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _AppPasswordFieldState createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      isRequired: widget.isRequired,
      isPassword: _obscureText,
      enabled: widget.enabled,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _obscureText ? Icons.visibility_off : Icons.visibility,
      suffixWidget: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.mutedGray,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
} 
