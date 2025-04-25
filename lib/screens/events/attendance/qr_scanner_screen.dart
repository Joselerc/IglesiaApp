import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/event_model.dart';

class QrScannerScreen extends StatefulWidget {
  final EventModel event;

  const QrScannerScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;
  
  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    
    // Evitar procesar el mismo código repetidamente
    if (code == _lastScannedCode) return;
    _lastScannedCode = code;
    
    setState(() => _isProcessing = true);
    
    try {
      // Buscar la entrada correspondiente al código QR
      final registrationsQuery = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .where('qrCode', isEqualTo: code)
          .limit(1)
          .get();
      
      if (registrationsQuery.docs.isEmpty) {
        _showErrorMessage('Ingresso não encontrado');
        return;
      }
      
      final registration = registrationsQuery.docs.first;
      final registrationData = registration.data();
      
      // Verificar si la entrada ya fue utilizada
      if (registrationData['isUsed'] == true) {
        _showErrorMessage('Este ingresso já foi utilizado');
        return;
      }
      
      // Marcar la entrada como utilizada
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .doc(registration.id)
          .update({
            'isUsed': true,
            'usedAt': FieldValue.serverTimestamp(),
            'usedBy': FirebaseAuth.instance.currentUser?.uid,
            'attendanceType': 'presential',
          });
      
      // Mostrar mensaje de éxito
      if (mounted) {
        _showSuccessMessage(registrationData['userName'] ?? 'Participante');
      }
    } catch (e) {
      _showErrorMessage('Erro ao processar: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        
        // Esperar un momento antes de permitir escanear otro código
        Future.delayed(const Duration(seconds: 2), () {
          setState(() => _lastScannedCode = null);
        });
      }
    }
  }
  
  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    // Vibrar (opcional)
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccessMessage(String userName) {
    if (!mounted) return;
    
    // Vibrar (opcional)
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Bem-vindo, $userName!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Encabezado con información del evento
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${_getEventTypeText(widget.event.eventType)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Scanner
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanner view
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                ),
                
                // Overlay for scanning area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Transparent center
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      
                      // Scanner Animation
                      Container(
                        width: 250,
                        height: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
                
                // Processing indicator
                if (_isProcessing)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          
          // Instrucciones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: const [
                Text(
                  'Escaneie o código QR do ingresso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Certifique-se de que o código QR esteja completamente visível dentro do quadro',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEventTypeText(String eventType) {
    switch (eventType) {
      case 'presential':
        return 'Presencial';
      case 'online':
        return 'Online';
      case 'hybrid':
        return 'Híbrido';
      default:
        return eventType;
    }
  }
} 