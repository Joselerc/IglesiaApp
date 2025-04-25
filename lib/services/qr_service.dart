import 'dart:convert';
import 'package:crypto/crypto.dart';

Future<String> generateQRCode(Map<String, dynamic> data) async {
  // Convertir los datos a JSON y crear un hash único
  final jsonData = json.encode(data);
  final bytes = utf8.encode(jsonData);
  final hash = sha256.convert(bytes);
  
  // Devolver el hash como string
  return hash.toString();
} 