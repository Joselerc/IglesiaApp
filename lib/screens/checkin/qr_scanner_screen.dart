import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class QRScannerScreen extends StatefulWidget {
  final List<String> selectedChildIds;

  const QRScannerScreen({super.key, required this.selectedChildIds});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {

  // TODO: Implementar lógica de escaneo de QR
  // - Inicializar el controlador de la cámara/scanner.
  // - Usar un paquete como mobile_scanner o qr_code_scanner.
  // - Definir qué hacer cuando se detecta un QR (validar, procesar check-in).

  @override
  void initState() {
    super.initState();
    print('Iniciando QR Scanner para crianças: ${widget.selectedChildIds}');
  }

  @override
  void dispose() {
    // TODO: Disponer el controlador del scanner
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR da Sala'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // No incluir botón de retroceso automático si el flujo solo va hacia adelante
        // O mantenerlo si el usuario puede querer volver a seleccionar niños
        automaticallyImplyLeading: true, 
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: Colors.black87, // Fondo oscuro para simular cámara
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 150, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Aponte a câmera para o QR Code da sala', 
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    // Aquí iría el widget del Scanner (ej: MobileScanner)
                  ],
                )
              ),
            ),
          ),
          // Botón VOLVER en la parte inferior
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            width: double.infinity, // Ocupar todo el ancho
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.textSecondary, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // Simplemente vuelve a la pantalla anterior
              },
              child: Text('VOLVER', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
} 