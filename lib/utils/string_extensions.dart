/// Extensiones para la clase String
extension StringExtensions on String {
  /// Convierte la primera letra del string a mayúscula
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
  
  /// Convierte la primera letra de cada palabra a mayúscula
  String capitalizeWords() {
    if (this.isEmpty) return this;
    return this.split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  /// Devuelve true si el string es un correo electrónico válido
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(this);
  }
  
  /// Devuelve true si el string es un número de teléfono válido
  bool get isValidPhone {
    return RegExp(r'^\d{10}$').hasMatch(this);
  }
} 