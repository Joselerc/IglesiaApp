import 'package:flutter/material.dart';

/// Un campo de selección personalizado que muestra opciones en un diálogo.
/// Este widget proporciona una mejor experiencia de usuario que el DropdownButton nativo
/// y evita problemas comunes relacionados con la validación.
class SelectionField extends StatefulWidget {
  /// Etiqueta o título del campo
  final String label;
  
  /// Texto de ayuda o descripción
  final String? hint;
  
  /// Valor actualmente seleccionado
  final String? value;
  
  /// Lista de opciones disponibles
  final List<String> options;
  
  /// Función llamada cuando el usuario selecciona una opción
  final ValueChanged<String?>? onChanged;
  
  /// Indica si el campo es obligatorio
  final bool isRequired;
  
  /// Color del borde cuando hay error (usado si el FormField padre lo indica, o internamente si se decide)
  final Color errorColor;
  
  /// Color del borde normal
  final Color borderColor;
  
  /// Radio de las esquinas del campo
  final double borderRadius;
  
  /// Color de fondo del campo
  final Color backgroundColor;
  
  /// Ícono prefijo opcional
  final Widget? prefixIcon;
  
  /// Ícono del botón de selección
  final IconData dropdownIcon;
  
  /// Función para obtener la etiqueta de cada opción
  final String Function(String)? itemLabelBuilder;

  const SelectionField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.options,
    this.onChanged,
    this.isRequired = false,
    this.errorColor = Colors.red,
    this.borderColor = const Color(0xFFE0E0E0), // Colors.grey[300]
    this.borderRadius = 10.0, // Consistente con tus otros campos
    this.backgroundColor = const Color(0xFFFAFAFA), // Colors.grey[50]
    this.prefixIcon,
    this.dropdownIcon = Icons.arrow_drop_down,
    this.itemLabelBuilder,
  });
  
  @override
  State<SelectionField> createState() => _SelectionFieldState();
}

class _SelectionFieldState extends State<SelectionField> {
  // Ya no se necesita _controller aquí si el valor se maneja por FormField
  String? _selectedValue;
  
  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
    // print('SelectionField - initState para ${widget.label}, value=${widget.value}, _selectedValue=$_selectedValue');
  }
  
  @override
  void didUpdateWidget(SelectionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // print('SelectionField - didUpdateWidget: valor cambió de ${oldWidget.value} a ${widget.value}');
      // Solo actualiza _selectedValue si el nuevo widget.value está en las opciones o es null
      if (widget.value == null || widget.options.contains(widget.value)) {
         _selectedValue = widget.value;
      }
    }
  }
  
  // Obtiene la etiqueta a mostrar para un valor
  String _getDisplayLabel(String value) {
    return widget.itemLabelBuilder != null ? widget.itemLabelBuilder!(value) : value;
  }

  @override
  Widget build(BuildContext context) {
    // El color primario para el estado activo/con valor puede venir del Theme general
    // o ser específico de la sección (como el morado de "Informação Adicional")
    // Por ahora, usaremos el primaryColor del Theme, pero podría necesitar ser un parámetro.
    final ThemeData theme = Theme.of(context);
    final Color activeColor = theme.primaryColor; // Color para borde y label cuando hay valor

    final currentValue = _selectedValue;
    final bool isValueSelected = currentValue != null && currentValue.isNotEmpty && widget.options.contains(currentValue);

    Color currentBorderColor;
    double borderWidth;
    Color currentLabelColor;
    EdgeInsets contentPadding;

    if (isValueSelected) {
      currentBorderColor = activeColor;
      borderWidth = 2.0; // Borde más grueso cuando está activo/con valor
      currentLabelColor = activeColor;
      // Padding cuando la etiqueta está "flotando" y hay valor
      contentPadding = const EdgeInsets.fromLTRB(12, 20, 12, 12); // Ajustar top para dejar espacio al label
    } else {
      currentBorderColor = widget.borderColor;
      borderWidth = 1.0;
      currentLabelColor = Colors.grey[600]!;
      // Padding cuando la etiqueta está "dentro" o es placeholder
      contentPadding = const EdgeInsets.symmetric(vertical: 16, horizontal: 12);
    }

    return GestureDetector(
      onTap: widget.onChanged == null ? null : () => _showSelectionDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: currentBorderColor,
            width: borderWidth,
          ),
        ),
        child: Stack(
          children: [
            // Contenido principal (prefixIcon, valor/placeholder, dropdownIcon)
            Padding(
              padding: contentPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: widget.prefixIcon!,
                    ),
                  Expanded(
                    child: Text(
                      isValueSelected ? _getDisplayLabel(currentValue!) : (widget.hint ?? 'Selecione uma opção'),
                      style: TextStyle(
                        fontSize: 16,
                        color: isValueSelected ? Colors.black87 : Colors.grey[600],
                        fontWeight: isValueSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8), // Espacio antes del icono del dropdown
                  Icon(
                    widget.dropdownIcon,
                    color: Colors.grey[700], // Icono del dropdown siempre gris
                    size: 24,
                  ),
                ],
              ),
            ),
            // Etiqueta posicionada (simulando etiqueta flotante)
            Positioned(
              left: widget.prefixIcon != null ? 44 : 12, // Ajustar si hay prefixIcon
              top: isValueSelected ? 6 : (contentPadding.top + contentPadding.bottom - 12) / 2, // Centrar si no hay valor, arriba si hay valor
              child: Container(
                color: widget.backgroundColor, // Para que la etiqueta "corte" el borde
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: isValueSelected ? 12 : 16, // Más pequeño cuando flota
                        color: currentLabelColor,
                        fontWeight: FontWeight.w500, // Siempre w500 para el label
                      ),
                    ),
                    if (widget.isRequired)
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Icon(Icons.star, size: 10, color: Colors.red[400]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSelectionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: widget.options.length > 6
                    ? MediaQuery.of(context).size.height * 0.4
                    : null,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = _selectedValue == option;

                    return ListTile(
                      title: Text(
                        _getDisplayLabel(option),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      leading: isSelected
                          ? Icon(Icons.check_circle, color: primaryColor)
                          : Icon(Icons.circle_outlined, color: Colors.grey),
                      onTap: () {
                        Navigator.of(context).pop(option);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((result) {
      if (result != null && widget.onChanged != null) {
        widget.onChanged!(result);
      }
    });
  }
}

/// Versión del SelectionField que puede usarse dentro de un Form
class SelectionFormField extends FormField<String> {
  /// Callback cuando cambia el valor
  final ValueChanged<String?>? onChanged;

  SelectionFormField({
    super.key,
    required String label,
    String? hint,
    String? initialValue,
    required List<String> options,
    this.onChanged,
    bool isRequired = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    IconData dropdownIcon = Icons.arrow_drop_down,
    Color errorColor = Colors.red,
    Color borderColor = const Color(0xFFE0E0E0), // Colors.grey[300]
    double borderRadius = 10.0,
    Color backgroundColor = const Color(0xFFFAFAFA), // Colors.grey[50]
  }) : super(
    initialValue: initialValue,
    validator: validator ?? (isRequired
        ? (value) => (value == null || value.isEmpty)
            ? 'Este campo es requerido'
            : null
        : null),
    builder: (FormFieldState<String> field) {
      return SelectionField(
        label: label,
        hint: hint, // Pasar el hint
        value: field.value,
        options: options,
        onChanged: (String? newValue) {
          field.didChange(newValue);
          if (onChanged != null) {
            onChanged(newValue);
          }
        },
        isRequired: isRequired,
        errorColor: errorColor,
        borderColor: field.hasError ? errorColor : borderColor, // Usar errorColor si FormField tiene error
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        prefixIcon: prefixIcon,
        dropdownIcon: dropdownIcon,
      );
    },
  );
  
  @override
  FormFieldState<String> createState() => FormFieldState<String>();
} 