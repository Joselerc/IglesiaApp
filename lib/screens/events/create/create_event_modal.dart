import 'package:flutter/material.dart';
import './event_basic_info_step.dart';
import './event_location_step.dart';
import './event_datetime_step.dart';
import './event_recurrence_step.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/event_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class CreateEventModal extends StatefulWidget {
  const CreateEventModal({super.key});

  @override
  State<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<CreateEventModal> {
  int _currentStep = 0;
  final Map<String, dynamic> _eventData = {};
  final PageController _pageController = PageController();
  bool _isCreating = false;

  // Lista de títulos para cada paso
  final List<String> _stepTitles = [
    'Informação Básica',
    'Localização',
    'Data e Hora',
    'Recorrência',
  ];

  // Lista de iconos para cada paso
  final List<IconData> _stepIcons = [
    Icons.description,
    Icons.location_on,
    Icons.access_time,
    Icons.repeat,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBasicInfoComplete(
    String title, 
    String category, 
    String description,
    String? imageUrl,
  ) {
    setState(() {
      _eventData['title'] = title;
      _eventData['category'] = category;
      _eventData['description'] = description;
      _eventData['imageUrl'] = imageUrl;
      _currentStep++;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar criação'),
        content: const Text('Tem certeza que deseja cancelar? Todas as informações serão perdidas.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar editando'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // cerrar diálogo
              Navigator.pop(context); // cerrar modal
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _handleLocationComplete(Map<String, dynamic> locationData) {
    setState(() {
      _eventData.addAll(locationData);
      _currentStep++;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _handleDateTimeComplete(Map<String, dynamic> dateTimeData) {
    setState(() {
      _eventData.addAll(dateTimeData);
      _currentStep++;
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _handleEventCreate(Map<String, dynamic> recurrenceData) async {
    setState(() {
      _isCreating = true;
    });
    
    try {
      _eventData.addAll(recurrenceData);
      
      // Si se está utilizando una ubicación de iglesia, cargar los datos de dirección
      if (_eventData['useChurchLocation'] == true && _eventData['churchLocationId'] != null) {
        try {
          final churchLocationDoc = await FirebaseFirestore.instance
              .collection('churchLocations')
              .doc(_eventData['churchLocationId'])
              .get();
              
          if (churchLocationDoc.exists) {
            final locationData = churchLocationDoc.data()!;
            
            // Asegurarse de copiar todos los campos de dirección
            _eventData['street'] = locationData['street'] ?? '';
            _eventData['number'] = locationData['number'] ?? '';
            _eventData['neighborhood'] = locationData['neighborhood'] ?? '';
            _eventData['city'] = locationData['city'] ?? '';
            _eventData['state'] = locationData['state'] ?? '';
            _eventData['country'] = locationData['country'] ?? '';
            _eventData['postalCode'] = locationData['postalCode'] ?? '';
            _eventData['complement'] = locationData['complement'] ?? '';
          } else {
            print('No se encontró la ubicación de iglesia con ID: ${_eventData['churchLocationId']}');
          }
        } catch (e) {
          print('Error al cargar datos de ubicación de iglesia: $e');
        }
      }
      
      final event = EventModel(
        id: '', 
        title: _eventData['title'],
        category: _eventData['category'],
        description: _eventData['description'],
        imageUrl: _eventData['imageUrl'] ?? '',
        createdAt: DateTime.now(),
        createdBy: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid),
        eventType: _eventData['eventType'],
        startDate: DateTime(
          _eventData['startDate'].year,
          _eventData['startDate'].month,
          _eventData['startDate'].day,
          _eventData['startTime'].hour,
          _eventData['startTime'].minute,
        ),
        endDate: DateTime(
          _eventData['endDate'].year,
          _eventData['endDate'].month,
          _eventData['endDate'].day,
          _eventData['endTime'].hour,
          _eventData['endTime'].minute,
        ),
        url: _eventData['url'],
        country: _eventData['country'],
        postalCode: _eventData['postalCode'],
        state: _eventData['state'],
        city: _eventData['city'],
        neighborhood: _eventData['neighborhood'],
        street: _eventData['street'],
        number: _eventData['number'],
        complement: _eventData['complement'],
        churchLocationId: _eventData['churchLocationId'],
        isRecurrent: _eventData['isRecurrent'] ?? false,
        recurrenceType: _eventData['frequency'],
        recurrenceInterval: _eventData['interval'],
        recurrenceEndType: _eventData['endType'],
        recurrenceCount: _eventData['occurrences'],
        recurrenceEndDate: _eventData['endDate'],
      );

      // Crear el evento en Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('events')
          .add(event.toMap());
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar evento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Criar Evento',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _handleCancel,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary,
            child: Column(
              children: [
                Text(
                  _stepTitles[_currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    _stepTitles.length,
                    (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: index < _currentStep
                              ? Colors.white
                              : index == _currentStep
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Icon(
                            _stepIcons[index],
                            color: index <= _currentStep
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isCreating
          ? _buildCreatingState()
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EventBasicInfoStep(
                  onNext: _handleBasicInfoComplete,
                  onCancel: _handleCancel,
                  initialTitle: _eventData['title'],
                  initialCategory: _eventData['category'],
                  initialDescription: _eventData['description'],
                  initialImageUrl: _eventData['imageUrl'],
                ),
                EventLocationStep(
                  onNext: _handleLocationComplete,
                  onBack: _handleBack,
                  onCancel: _handleCancel,
                  initialLocationType: _eventData['eventType'],
                  initialUseChurchLocation: _eventData['useChurchLocation'],
                  initialChurchLocationId: _eventData['churchLocationId'],
                  initialCountryCode: _eventData['country'],
                  initialState: _eventData['state'],
                  initialCity: _eventData['city'],
                  initialPostalCode: _eventData['postalCode'],
                  initialNeighborhood: _eventData['neighborhood'],
                  initialStreet: _eventData['street'],
                  initialNumber: _eventData['number'],
                  initialComplement: _eventData['complement'],
                  initialUrl: _eventData['url'],
                ),
                EventDateTimeStep(
                  onNext: _handleDateTimeComplete,
                  onBack: _handleBack,
                  onCancel: _handleCancel,
                  initialStartDate: _eventData['startDate'],
                  initialStartTime: _eventData['startTime'],
                  initialEndDate: _eventData['endDate'],
                  initialEndTime: _eventData['endTime'],
                ),
                EventRecurrenceStep(
                  onCreate: _handleEventCreate,
                  onBack: _handleBack,
                  onCancel: _handleCancel,
                ),
              ],
            ),
    );
  }
  
  Widget _buildCreatingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Criando evento...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Por favor, aguarde enquanto processamos os dados',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 