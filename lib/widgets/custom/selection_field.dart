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
  
  /// Color del borde cuando hay error
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
    this.borderColor = Colors.grey,
    this.borderRadius = 8.0,
    this.backgroundColor = Colors.white,
    this.prefixIcon,
    this.dropdownIcon = Icons.arrow_drop_down,
    this.itemLabelBuilder,
  });
  
  @override
  State<SelectionField> createState() => _SelectionFieldState();
}

class _SelectionFieldState extends State<SelectionField> {
  late TextEditingController _controller;
  // Mantener una copia local del valor seleccionado
  String? _selectedValue;
  
  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
    _initializeController();
    print('SelectionField - initState para ${widget.label}, value=${widget.value}, _selectedValue=$_selectedValue');
  }
  
  @override
  void didUpdateWidget(SelectionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Solo actualizar el valor y controlador si el valor realmente cambió y es no nulo
    if (widget.value != oldWidget.value && widget.value != null) {
      print('SelectionField - didUpdateWidget: valor cambió de ${oldWidget.value} a ${widget.value}');
      if (widget.options.contains(widget.value)) {
        _selectedValue = widget.value;
        _updateControllerText();
      }
    }
  }
  
  void _updateControllerText() {
    // Usar el valor seleccionado si existe y es válido
    if (_selectedValue != null && widget.options.contains(_selectedValue)) {
      final displayText = _getDisplayLabel(_selectedValue!);
      if (_controller.text != displayText) {
        _controller.text = displayText;
        print('SelectionField - _updateControllerText: actualizado a "$displayText"');
      }
    }
  }
  
  void _initializeController() {
    // Priorizar el valor seleccionado localmente sobre el valor del widget
    final valueToUse = _selectedValue ?? widget.value;
    
    // Comprobar si el valor es válido (existe en las opciones)
    final isValueValid = valueToUse != null && widget.options.contains(valueToUse);
    final displayText = isValueValid ? _getDisplayLabel(valueToUse) : '';
    _controller = TextEditingController(text: displayText);
    print('SelectionField - _initializeController: isValueValid=$isValueValid, valueToUse=$valueToUse, displayText="$displayText"');
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Obtiene la etiqueta a mostrar para un valor
  String _getDisplayLabel(String value) {
    return widget.itemLabelBuilder != null ? widget.itemLabelBuilder!(value) : value;
  }

  @override
  Widget build(BuildContext context) {
    // Priorizar el valor seleccionado localmente sobre el valor del widget
    final valueToUse = _selectedValue ?? widget.value;
    
    // Comprobar si el valor es válido (existe en las opciones)
    final isValueValid = valueToUse != null && widget.options.contains(valueToUse);
    final hasError = widget.isRequired && (valueToUse == null || valueToUse.isEmpty);
    final theme = Theme.of(context);
    
    print('SelectionField - build: label=${widget.label}, valueToUse=$valueToUse, isValueValid=$isValueValid');
    print('SelectionField - build: controllerText="${_controller.text}"');
    
    // Asegurarse de que el controlador tenga el texto correcto
    if (isValueValid && _controller.text != _getDisplayLabel(valueToUse)) {
      print('SelectionField - build: actualizando controlador, texto anterior="${_controller.text}", nuevo="${_getDisplayLabel(valueToUse)}"');
      _controller.text = _getDisplayLabel(valueToUse);
    }
    
    return GestureDetector(
      onTap: widget.onChanged == null ? null : () => _showSelectionDialog(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: hasError 
                ? widget.errorColor 
                : isValueValid 
                    ? theme.primaryColor.withOpacity(0.5) 
                    : Colors.grey[300]!,
            width: isValueValid ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Etiqueta flotante
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: isValueValid ? theme.primaryColor : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.isRequired)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.red[400],
                      ),
                    ),
                ],
              ),
            ),
            // Valor seleccionado o placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    widget.prefixIcon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      isValueValid ? _getDisplayLabel(valueToUse) : 'Seleccione una opción',
                      style: TextStyle(
                        color: isValueValid ? Colors.black87 : Colors.grey[400],
                        fontSize: 16,
                        fontWeight: isValueValid ? FontWeight.w500 : FontWeight.normal,
                        fontStyle: isValueValid ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                  Icon(
                    widget.dropdownIcon,
                    color: hasError ? widget.errorColor : Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),
            ),
            // Mensaje de error si es requerido y no tiene valor
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  'Este campo es requerido',
                  style: TextStyle(
                    color: widget.errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Muestra el diálogo de selección con la lista de opciones
  Future<void> _showSelectionDialog(BuildContext context) async {
    print('SelectionField - _showSelectionDialog: mostrando diálogo para ${widget.label}');
    
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    final result = await showDialog<String>(
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
              // Título del diálogo
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
              
              // Lista de opciones
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
              
              // Botón de cancelar
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
    );
    
    print('SelectionField - _showSelectionDialog: resultado del diálogo: $result');
    
    if (result != null && widget.onChanged != null) {
      try {
        // Actualizar el valor local y el controlador inmediatamente
        setState(() {
          _selectedValue = result;
          _controller.text = _getDisplayLabel(result);
          print('SelectionField - selección actualizada: _selectedValue=$_selectedValue, controlador="${_controller.text}"');
        });
        
        // Llamar al callback
        print('SelectionField - llamando onChanged con valor: $result');
        widget.onChanged!(result);
      } catch (e) {
        print('Error al actualizar selección: $e');
        // Intentar recuperar
        Future.microtask(() {
          if (mounted) {
            widget.onChanged!(result);
          }
        });
      }
    }
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
    Color errorColor = Colors.red,
    Color borderColor = Colors.grey,
    double borderRadius = 8.0,
    Color backgroundColor = Colors.white,
    Widget? prefixIcon,
    IconData dropdownIcon = Icons.arrow_drop_down,
  }) : super(
    initialValue: initialValue,
    validator: validator ?? (isRequired 
        ? (value) => (value == null || value.isEmpty) 
            ? 'Este campo es requerido' 
            : null
        : null),
    builder: (FormFieldState<String> field) {
      final _SelectionFormFieldState state = field as _SelectionFormFieldState;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionField(
            label: label,
            hint: hint,
            value: state.value,
            options: options,
            onChanged: state.didChange,
            isRequired: isRequired,
            errorColor: field.hasError ? errorColor : errorColor,
            borderColor: borderColor,
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            prefixIcon: prefixIcon,
            dropdownIcon: dropdownIcon,
          ),
          if (field.hasError && field.errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  color: errorColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    },
  );
  
  @override
  FormFieldState<String> createState() => _SelectionFormFieldState();
}

class _SelectionFormFieldState extends FormFieldState<String> {
  @override
  void didChange(String? value) {
    super.didChange(value);
    final SelectionFormField widgetField = widget as SelectionFormField;
    if (widgetField.onChanged != null) {
      widgetField.onChanged!(value);
    }
  }
} 