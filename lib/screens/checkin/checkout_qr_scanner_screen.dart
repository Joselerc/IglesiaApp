import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/checkin_record_model.dart';
import '../../models/scheduled_room_model.dart';
import '../../models/child_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CheckoutQRScannerScreen extends StatefulWidget {
  final String? scheduledRoomId; // Opcional: si viene de una sala específica

  const CheckoutQRScannerScreen({
    super.key,
    this.scheduledRoomId,
  });

  @override
  State<CheckoutQRScannerScreen> createState() => _CheckoutQRScannerScreenState();
}

class _CheckoutQRScannerScreenState extends State<CheckoutQRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _feedbackMessage;
  bool _scanCompleted = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    print('Iniciando Checkout QR Scanner');
  }

  Future<void> _handleScannedQrCode(String? qrCodeValue) async {
    if (qrCodeValue == null || qrCodeValue.trim().isEmpty || _isProcessing || _scanCompleted) {
      return;
    }

    // Debounce
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
      _feedbackMessage = 'QR escaneado! Buscando crianças para checkout...';
      _scanCompleted = true;
    });

    print('QR Code escaneado para checkout: $qrCodeValue');

    try {
      // Buscar niños elegibles para checkout
      await _showCheckoutSelectionScreen();
    } catch (e) {
      print('Error al procesar checkout: $e');
      _showFeedback('Erro ao processar checkout: $e', isError: true);
    }
  }

  Future<void> _showCheckoutSelectionScreen() async {
    // Navegar a la pantalla de selección de checkout
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutSelectionScreen(
          scheduledRoomId: widget.scheduledRoomId,
        ),
      ),
    );

    // Si se completó el checkout, cerrar esta pantalla
    if (result == true && mounted) {
      Navigator.pop(context);
    } else {
      // Resetear para permitir otro escaneo
      setState(() {
        _isProcessing = false;
        _scanCompleted = false;
        _feedbackMessage = null;
      });
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).clearSnackBars();
    
    setState(() {
      _feedbackMessage = message;
      _isProcessing = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
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
        title: const Text('Checkout - Escanear QR'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !_isProcessing,
      ),
      body: Stack(
        children: <Widget>[
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_scanCompleted || _isProcessing) return;
              
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
                border: Border.all(color: Colors.orange.shade300, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_feedbackMessage != null)
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
                    color: _feedbackMessage!.toLowerCase().contains('erro') 
                        ? Colors.red.shade100 
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedbackMessage!.toLowerCase().contains('erro') 
                          ? Colors.red.shade900 
                          : Colors.orange.shade900,
                    ),
                  ),
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
                  side: BorderSide(
                    color: _isProcessing ? Colors.grey : Colors.white,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: Text(
                  'VOLTAR',
                  style: AppTextStyles.button.copyWith(
                    color: _isProcessing ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de selección de niños para checkout
class CheckoutSelectionScreen extends StatefulWidget {
  final String? scheduledRoomId;

  const CheckoutSelectionScreen({
    super.key,
    this.scheduledRoomId,
  });

  @override
  State<CheckoutSelectionScreen> createState() => _CheckoutSelectionScreenState();
}

class _CheckoutSelectionScreenState extends State<CheckoutSelectionScreen> {
  List<Map<String, dynamic>> _eligibleChildren = [];
  bool _isLoading = true;
  Set<String> _selectedChildIds = {};

  @override
  void initState() {
    super.initState();
    _loadEligibleChildren();
  }

  Future<void> _loadEligibleChildren() async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('checkinRecords')
          .where('status', isEqualTo: 'checkedIn');

      // Si viene de una sala específica, filtrar por esa sala
      if (widget.scheduledRoomId != null) {
        query = query.where('scheduledRoomId', isEqualTo: widget.scheduledRoomId);
      }

      final checkinRecords = await query.get();
      
      List<Map<String, dynamic>> children = [];
      
      for (var doc in checkinRecords.docs) {
        final record = CheckinRecordModel.fromFirestore(doc);
        
        // Obtener datos del niño
        final childDoc = await FirebaseFirestore.instance
            .collection('children')
            .doc(record.childId)
            .get();
            
        if (childDoc.exists) {
          final child = ChildModel.fromFirestore(childDoc);
          
          // Obtener datos de la sala si no tenemos scheduledRoomId específico
          String roomDescription = 'Sala desconocida';
          if (record.scheduledRoomId != null) {
            final roomDoc = await FirebaseFirestore.instance
                .collection('scheduledRooms')
                .doc(record.scheduledRoomId!)
                .get();
            if (roomDoc.exists) {
              final room = ScheduledRoomModel.fromFirestore(roomDoc);
              roomDescription = room.description;
            }
          }
          
          children.add({
            'child': child,
            'record': record,
            'roomDescription': roomDescription,
          });
        }
      }

      setState(() {
        _eligibleChildren = children;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando niños elegibles: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return '';
    final birth = birthDate.toDate();
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age > 0 ? '$age anos' : (age == 0 ? 'Menos de 1 ano' : '');
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String initials = parts.first[0];
    if (parts.length > 1) initials += parts.last[0];
    return initials.toUpperCase();
  }

  Future<void> _performCheckout() async {
    if (_selectedChildIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma criança para checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final adminUserId = FirebaseAuth.instance.currentUser?.uid;
    if (adminUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Administrador não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      for (String childId in _selectedChildIds) {
        // Encontrar el registro de check-in
        final childData = _eligibleChildren.firstWhere(
          (data) => data['child'].id == childId,
        );
        
        final CheckinRecordModel record = childData['record'];
        
        // Actualizar el registro de check-in
        final recordRef = FirebaseFirestore.instance
            .collection('checkinRecords')
            .doc(record.id);
            
        batch.update(recordRef, {
          'status': 'checkedOut',
          'checkoutTime': FieldValue.serverTimestamp(),
          'checkedOutByUserId': adminUserId,
        });
        
        // Remover de la lista de check-in de la sala
        if (record.scheduledRoomId != null) {
          final roomRef = FirebaseFirestore.instance
              .collection('scheduledRooms')
              .doc(record.scheduledRoomId!);
              
          batch.update(roomRef, {
            'checkedInChildIds': FieldValue.arrayRemove([childId]),
          });
        }
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedChildIds.length} criança(s) com checkout realizado!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retornar true para indicar que se completó el checkout
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error realizando checkout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao realizar checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheduledRoomId != null 
            ? 'Checkout - Selecionar Crianças' 
            : 'Checkout - Todas as Salas'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eligibleChildren.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma criança com check-in encontrada',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    // Header con contador
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_eligibleChildren.length} criança(s) disponível(is)',
                            style: AppTextStyles.subtitle1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_selectedChildIds.length} selecionada(s)',
                            style: AppTextStyles.bodyText2.copyWith(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lista de niños
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _eligibleChildren.length,
                        itemBuilder: (context, index) {
                          final data = _eligibleChildren[index];
                          final ChildModel child = data['child'];
                          final CheckinRecordModel record = data['record'];
                          final String roomDescription = data['roomDescription'];
                          
                          final bool isSelected = _selectedChildIds.contains(child.id);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Colors.orange.shade50 : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected 
                                    ? Colors.orange.shade200 
                                    : Colors.grey.shade200,
                                backgroundImage: child.photoUrl != null && child.photoUrl!.isNotEmpty 
                                    ? NetworkImage(child.photoUrl!) 
                                    : null,
                                child: child.photoUrl == null || child.photoUrl!.isEmpty
                                    ? Text(
                                        _getInitials('${child.firstName} ${child.lastName}'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.orange.shade700 : Colors.grey.shade600,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                '${child.firstName} ${child.lastName}',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_calculateAge(child.dateOfBirth)} • $roomDescription'),
                                  Text(
                                    'Check-in: ${DateFormat('HH:mm').format(record.checkinTime.toDate())}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (record.labelNumber != null)
                                    Text(
                                      'Etiqueta: ${record.labelNumber}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedChildIds.add(child.id);
                                    } else {
                                      _selectedChildIds.remove(child.id);
                                    }
                                  });
                                },
                                activeColor: Colors.orange,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedChildIds.remove(child.id);
                                  } else {
                                    _selectedChildIds.add(child.id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _selectedChildIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: Text(
                  'REALIZAR CHECKOUT (${_selectedChildIds.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _performCheckout,
              ),
            )
          : null,
    );
  }
} 