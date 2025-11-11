import 'package:flutter/material.dart';
import './event_basic_info_step.dart';
import './event_location_step.dart';
import './event_datetime_step.dart';
import './event_recurrence_step.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../models/event_model.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

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

  List<String> get _stepTitles => [
    AppLocalizations.of(context)!.basicInformation,
    AppLocalizations.of(context)!.location,
    AppLocalizations.of(context)!.dateAndTime,
    AppLocalizations.of(context)!.recurrence,
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
    File? imageFile,
  ) {
    setState(() {
      _eventData['title'] = title;
      _eventData['category'] = category;
      _eventData['description'] = description;
      _eventData['imageFile'] = imageFile;
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
        title: Text(AppLocalizations.of(context)!.cancelCreation),
        content: Text(AppLocalizations.of(context)!.sureWantToCancel),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.continueEditing),
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
      
      // Subir imagen si existe
      String imageUrl = '';
      if (_eventData['imageFile'] != null && _eventData['imageFile'] is File) {
        final File imageFile = _eventData['imageFile'] as File;
        try {
          debugPrint('📤 Iniciando subida de imagen a Firebase Storage...');
          debugPrint('📁 Archivo a subir: ${imageFile.path}');
          debugPrint('📏 Tamaño: ${await imageFile.length()} bytes');
          debugPrint('✅ Archivo existe: ${await imageFile.exists()}');
          
          final String fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('event_images')
              .child(fileName);
          
          debugPrint('🎯 Ruta de destino: event_images/$fileName');
          
          final SettableMetadata metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
          
          debugPrint('⏳ Subiendo archivo...');
          final uploadTask = storageRef.putFile(imageFile, metadata);
          
          // Escuchar eventos de la subida
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            double progress = snapshot.bytesTransferred / snapshot.totalBytes;
            debugPrint('📊 Progreso: ${(progress * 100).toStringAsFixed(0)}%');
          });
          
          final snapshot = await uploadTask;
          debugPrint('✅ Subida completada, obteniendo URL...');
          imageUrl = await snapshot.ref.getDownloadURL();
          debugPrint('🎉 Imagen subida exitosamente: $imageUrl');
        } on FirebaseException catch (e) {
          debugPrint('❌ Error de Firebase al subir imagen:');
          debugPrint('   Código: ${e.code}');
          debugPrint('   Mensaje: ${e.message}');
          debugPrint('   Plugin: ${e.plugin}');
          // Continuar sin imagen si falla la subida
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al subir imagen: ${e.message}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Error general al subir imagen: $e');
          debugPrint('   Tipo: ${e.runtimeType}');
          // Continuar sin imagen si falla la subida
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al subir imagen. El evento se creará sin imagen.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      
      // Guardar la URL de la imagen en _eventData
      _eventData['imageUrl'] = imageUrl;
      
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
      
      // Preparar la fecha/hora inicial del evento
      final baseStartDate = DateTime(
        _eventData['startDate'].year,
        _eventData['startDate'].month,
        _eventData['startDate'].day,
        _eventData['startTime'].hour,
        _eventData['startTime'].minute,
      );
      
      final baseEndDate = DateTime(
        _eventData['endDate'].year,
        _eventData['endDate'].month,
        _eventData['endDate'].day,
        _eventData['endTime'].hour,
        _eventData['endTime'].minute,
      );
      
      // Si el evento es recurrente, generar múltiples eventos
      if (_eventData['isRecurrent'] == true) {
        final List<Map<String, dynamic>> eventsList = _generateRecurringEvents(
          baseStartDate: baseStartDate,
          baseEndDate: baseEndDate,
          frequency: _eventData['frequency'],
          interval: _eventData['interval'] ?? 1,
          endType: _eventData['endType'],
          occurrences: _eventData['occurrences'] ?? 1,
          endDate: _eventData['endDate'],
        );
        
        // Crear todos los eventos en un batch
        final batch = FirebaseFirestore.instance.batch();
        int eventCount = 0;
        
        for (final eventData in eventsList) {
          final event = EventModel(
            id: '', 
            title: _eventData['title'],
            category: _eventData['category'],
            description: _eventData['description'],
            imageUrl: _eventData['imageUrl'] ?? '',
            createdAt: DateTime.now(),
            createdBy: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid),
            eventType: _eventData['eventType'],
            startDate: eventData['startDate'],
            endDate: eventData['endDate'],
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
            isRecurrent: false, // Los eventos individuales no se marcan como recurrentes
            recurrenceType: null,
            recurrenceInterval: null,
            recurrenceEndType: null,
            recurrenceCount: null,
            recurrenceEndDate: null,
          );
          
          final docRef = FirebaseFirestore.instance.collection('events').doc();
          batch.set(docRef, event.toMap());
          eventCount++;
          
          // Firestore tiene un límite de 500 operaciones por batch
          if (eventCount >= 500) {
            await batch.commit();
            batch.set(FirebaseFirestore.instance.collection('events').doc(), {}); // Reiniciar batch
            eventCount = 0;
          }
        }
        
        // Commit del batch final
        if (eventCount > 0) {
          await batch.commit();
        }
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.eventsCreatedSuccessfully(eventsList.length)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Evento único (no recurrente)
        final event = EventModel(
          id: '', 
          title: _eventData['title'],
          category: _eventData['category'],
          description: _eventData['description'],
          imageUrl: _eventData['imageUrl'] ?? '',
          createdAt: DateTime.now(),
          createdBy: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid),
          eventType: _eventData['eventType'],
          startDate: baseStartDate,
          endDate: baseEndDate,
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
          isRecurrent: false,
          recurrenceType: null,
          recurrenceInterval: null,
          recurrenceEndType: null,
          recurrenceCount: null,
          recurrenceEndDate: null,
        );

        // Crear el evento en Firestore
        await FirebaseFirestore.instance
            .collection('events')
            .add(event.toMap());
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.eventCreatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorCreatingEvent(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Método para generar las fechas de eventos recurrentes
  List<Map<String, dynamic>> _generateRecurringEvents({
    required DateTime baseStartDate,
    required DateTime baseEndDate,
    required String frequency,
    required int interval,
    required String endType,
    int? occurrences,
    DateTime? endDate,
  }) {
    final List<Map<String, dynamic>> events = [];
    DateTime currentStartDate = baseStartDate;
    DateTime currentEndDate = baseEndDate;
    int count = 0;
    
    // Límite de seguridad para evitar bucles infinitos
    const int maxEvents = 365;
    
    while (events.length < maxEvents) {
      // Agregar el evento actual
      events.add({
        'startDate': currentStartDate,
        'endDate': currentEndDate,
      });
      
      count++;
      
      // Verificar condiciones de parada
      if (endType == 'afterOccurrences' && occurrences != null && count >= occurrences) {
        break;
      }
      
      if (endType == 'onDate' && endDate != null && currentStartDate.isAfter(endDate)) {
        // Eliminar el último evento si excede la fecha de fin
        events.removeLast();
        break;
      }
      
      // Calcular la próxima fecha
      switch (frequency) {
        case 'daily':
          currentStartDate = currentStartDate.add(Duration(days: interval));
          currentEndDate = currentEndDate.add(Duration(days: interval));
          break;
        case 'weekly':
          currentStartDate = currentStartDate.add(Duration(days: 7 * interval));
          currentEndDate = currentEndDate.add(Duration(days: 7 * interval));
          break;
        case 'monthly':
          // Para meses, necesitamos considerar la variación en días
          currentStartDate = DateTime(
            currentStartDate.year,
            currentStartDate.month + interval,
            currentStartDate.day,
            currentStartDate.hour,
            currentStartDate.minute,
          );
          currentEndDate = DateTime(
            currentEndDate.year,
            currentEndDate.month + interval,
            currentEndDate.day,
            currentEndDate.hour,
            currentEndDate.minute,
          );
          break;
        case 'yearly':
          currentStartDate = DateTime(
            currentStartDate.year + interval,
            currentStartDate.month,
            currentStartDate.day,
            currentStartDate.hour,
            currentStartDate.minute,
          );
          currentEndDate = DateTime(
            currentEndDate.year + interval,
            currentEndDate.month,
            currentEndDate.day,
            currentEndDate.hour,
            currentEndDate.minute,
          );
          break;
      }
      
      // Para eventos que nunca terminan, limitamos a 1 año de eventos
      if (endType == 'never' && currentStartDate.isAfter(baseStartDate.add(const Duration(days: 365)))) {
        break;
      }
    }
    
    return events;
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
          AppLocalizations.of(context)!.createEvent,
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
                  initialImageFile: _eventData['imageFile'],
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
                Text(
                  AppLocalizations.of(context)!.creatingEvent,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.pleaseWaitProcessingData,
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