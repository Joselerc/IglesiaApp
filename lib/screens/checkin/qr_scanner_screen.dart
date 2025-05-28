import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/checkin_record_model.dart';
import '../../models/scheduled_room_model.dart';
import '../../models/child_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class QRScannerScreen extends StatefulWidget {
  final List<String> selectedChildIds;
  final String familyOrVisitorId;

  const QRScannerScreen({
    super.key, 
    required this.selectedChildIds,
    required this.familyOrVisitorId,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    // Configuración opcional del scanner
    // formats: [BarcodeFormat.qrCode],
    // detectionSpeed: DetectionSpeed.normal,
  );
  bool _isProcessing = false;
  String? _feedbackMessage;
  bool _scanCompletedSuccessfully = false;
  String? _lastScannedCode; // Para evitar procesar el mismo código múltiples veces
  DateTime? _lastScanTime; // Para debounce

  @override
  void initState() {
    super.initState();
    print('Iniciando QR Scanner para crianças: ${widget.selectedChildIds} da família/visitante: ${widget.familyOrVisitorId}');
  }

  int _calculateAgeFromTimestamp(Timestamp birthDateTs) {
    final birth = birthDateTs.toDate();
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  bool _isAgeInRange(int childAge, String? ageRangeString) {
    if (ageRangeString == null || ageRangeString.trim().isEmpty) return true;
    String range = ageRangeString.toLowerCase().trim();

    if (range == 'berçário') return childAge <= 1;
    
    RegExp patternCombined = RegExp(r'(\d+)\s*a\s*(\d+)\s*anos');
    Match? matchCombined = patternCombined.firstMatch(range);
    if (matchCombined != null) {
      int min = int.parse(matchCombined.group(1)!);
      int max = int.parse(matchCombined.group(2)!);
      return childAge >= min && childAge <= max;
    }
    
    RegExp patternSingle = RegExp(r'sala\s*(\d+)\s*anos');
    Match? matchSingle = patternSingle.firstMatch(range);
    if (matchSingle != null) {
      int age = int.parse(matchSingle.group(1)!);
      return childAge == age;
    }
    print('AVISO: Formato de Faixa Etária não reconhecido: $ageRangeString -> $range');
    return false;
  }

  Future<void> _handleScannedQrCode(String? qrCodeValue) async {
    if (qrCodeValue == null || qrCodeValue.trim().isEmpty || _isProcessing || _scanCompletedSuccessfully) {
      return;
    }
    
    // Debounce: evitar procesar el mismo código muy rápido
    final now = DateTime.now();
    if (_lastScannedCode == qrCodeValue && 
        _lastScanTime != null && 
        now.difference(_lastScanTime!).inSeconds < 3) {
      return;
    }
    
    _lastScannedCode = qrCodeValue;
    _lastScanTime = now;
    
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _feedbackMessage = 'Verificando QR e procurando salas...';
    });
    
    print('QR Code escaneado (valor genérico, não usado para ID de sala): $qrCodeValue');
    final adminUserId = FirebaseAuth.instance.currentUser?.uid;
    if (adminUserId == null) {
      _showFeedback('Erro: Administrador não autenticado.', isError: true);
      return;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int totalSuccessfulCheckins = 0;
      String successMessageDetails = '';
      Set<String> updatedScheduleChildPairs = {};

      DateTime now = DateTime.now();

      for (String childId in widget.selectedChildIds) {
        DocumentSnapshot childDoc = await FirebaseFirestore.instance.collection('children').doc(childId).get();
        if (!childDoc.exists) {
          print('Criança com ID $childId não encontrada.');
          successMessageDetails += 'Criança $childId não encontrada.\n';
          continue;
        }
        final child = ChildModel.fromFirestore(childDoc);
        final childAge = _calculateAgeFromTimestamp(child.dateOfBirth);

        QuerySnapshot availableSchedulesSnapshot = await FirebaseFirestore.instance
            .collection('scheduledRooms')
            .where('isOpen', isEqualTo: true)
            .orderBy('startTime')
            .get();

        ScheduledRoomModel? selectedSchedule;
        for (var scheduleDocLoop in availableSchedulesSnapshot.docs) {
          final schedule = ScheduledRoomModel.fromFirestore(scheduleDocLoop);
          
          bool isAgeCorrect = _isAgeInRange(childAge, schedule.ageRange);
          bool hasCapacity = schedule.maxChildren == null || schedule.maxChildren == 0 || (schedule.checkedInChildIds.length < schedule.maxChildren!);
          bool notAlreadyCheckedIn = !schedule.checkedInChildIds.contains(childId);
          
          if (isAgeCorrect && hasCapacity && notAlreadyCheckedIn) {
            selectedSchedule = schedule;
            break;
          }
        }

        if (selectedSchedule != null) {
          final checkinRecordId = const Uuid().v4();
          final checkinRecordRef = FirebaseFirestore.instance.collection('checkinRecords').doc(checkinRecordId);
          
          // Obtener el ageRange del schedule, no del niño directamente para el historial
          String? ageRangeForRecord = selectedSchedule.ageRange; 

          final newCheckinRecord = CheckinRecordModel(
            id: checkinRecordId, 
            childId: childId, 
            familyId: widget.familyOrVisitorId,
            scheduledRoomId: selectedSchedule.id, // Guardar el ID de la programación
            scheduledRoomDescription: selectedSchedule.description, // Guardar descripción de la programación
            childAgeRangeAtCheckin: ageRangeForRecord, // Guardar el rango etario de la sala en ese momento
            checkinTime: Timestamp.now(),
            status: CheckinStatus.checkedIn, 
            checkedInByUserId: adminUserId,
          );
          batch.set(checkinRecordRef, newCheckinRecord.toMap());

          String scheduleChildKey = '${selectedSchedule.id}_$childId';
          if (!updatedScheduleChildPairs.contains(scheduleChildKey)) {
            final scheduledRoomRef = FirebaseFirestore.instance.collection('scheduledRooms').doc(selectedSchedule.id);
            batch.update(scheduledRoomRef, {'checkedInChildIds': FieldValue.arrayUnion([childId])});
            updatedScheduleChildPairs.add(scheduleChildKey);
          }

          successMessageDetails += '${child.firstName} ${child.lastName} -> ${selectedSchedule.description}.\n';
          totalSuccessfulCheckins++;
        } else {
          String reason = 'Nenhuma sala compatível/disponível';
          successMessageDetails += 'Check-in falhou para ${child.firstName} ${child.lastName} (Idade: $childAge). Motivo: $reason.\n';
          print('Nenhuma sala adequada para ${child.firstName} (Idade: $childAge)');
        }
      }

      if (widget.selectedChildIds.isNotEmpty) {
        await batch.commit();
      }

      if (totalSuccessfulCheckins == widget.selectedChildIds.length && widget.selectedChildIds.isNotEmpty) {
        _showFeedback('$totalSuccessfulCheckins criança(s) registrada(s) com sucesso!\n$successMessageDetails', duration: 4);
         setState(() => _scanCompletedSuccessfully = true);
         await Future.delayed(const Duration(seconds: 3));
         if(mounted && _scanCompletedSuccessfully) {
           Navigator.pop(context);
           if (Navigator.canPop(context)) {
             Navigator.pop(context);
           }
         }
      } else if (totalSuccessfulCheckins > 0) {
        _showFeedback('$totalSuccessfulCheckins de ${widget.selectedChildIds.length} criança(s) registrada(s).\nDetalhes:\n$successMessageDetails', isError: true, duration: 6);
      } else if (widget.selectedChildIds.isNotEmpty) {
        _showFeedback('Não foi possível realizar o check-in para nenhuma criança.\nDetalhes:\n$successMessageDetails', isError: true, duration: 6);
      } else {
        _showFeedback('Nenhuma criança selecionada para check-in.', isError: true, duration: 3);
      }

    } catch (e, s) {
      print('Erro CRÍTICO ao processar check-in: $e\n$s');
      _showFeedback('Erro crítico ao processar check-in. Tente novamente.', isError: true);
    }
  }

  void _showFeedback(String message, {bool isError = false, int duration = 2}) {
    if (!mounted) return;
    
    // Limpiar SnackBars anteriores antes de mostrar uno nuevo
    ScaffoldMessenger.of(context).clearSnackBars();
    
    setState(() {
      _feedbackMessage = message;
      _isProcessing = false; 
      if (isError || message.contains('Nenhuma criança nova')) {
         _scanCompletedSuccessfully = false;
      }
    });
    
    // Solo mostrar SnackBar si el widget está montado y visible
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: duration),
        ),
      );
    }
    
    if (isError || message.contains('Nenhuma criança nova')) {
       Future.delayed(Duration(seconds: duration + 1), () {
          if(mounted && !_scanCompletedSuccessfully) {
            setState(() => _feedbackMessage = null);
          }
       });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR da Sala'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !_isProcessing && !_scanCompletedSuccessfully,
      ),
      body: Stack( 
        children: <Widget>[
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              // Evitar procesar si ya se completó o está procesando
              if (_scanCompletedSuccessfully || _isProcessing) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleScannedQrCode(barcodes.first.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade300, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_feedbackMessage != null && !_scanCompletedSuccessfully)
            Positioned(
              bottom: 80, 
              left: 20,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _feedbackMessage!.toLowerCase().contains('erro') || _feedbackMessage!.toLowerCase().contains('inválido') || _feedbackMessage!.toLowerCase().contains('não encontrada') ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_feedbackMessage!, textAlign: TextAlign.center, style: TextStyle(color: _feedbackMessage!.toLowerCase().contains('erro') || _feedbackMessage!.toLowerCase().contains('inválido') || _feedbackMessage!.toLowerCase().contains('não encontrada') ? Colors.red.shade900 : Colors.green.shade900) ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
              width: double.infinity,
              color: Colors.black.withOpacity(0.3), 
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: (_isProcessing || _scanCompletedSuccessfully) ? Colors.grey : Colors.white, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_isProcessing || _scanCompletedSuccessfully) ? null : () => Navigator.pop(context),
                child: Text('VOLVER', style: AppTextStyles.button.copyWith(color: (_isProcessing || _scanCompletedSuccessfully) ? Colors.grey : Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 