import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../models/cult.dart';
import '../../../models/saved_location.dart';
import './saved_locations_modal.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class CreateCultAnnouncementModal extends StatefulWidget {
  final Cult cult;
  
  const CreateCultAnnouncementModal({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<CreateCultAnnouncementModal> createState() => _CreateCultAnnouncementModalState();
}

class _CreateCultAnnouncementModalState extends State<CreateCultAnnouncementModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _processedImage;
  bool _isLoading = false;
  bool _isProcessingImage = false;
  String? _errorMessage;
  
  // Variables para la localización
  String? _location;
  String? _locationId;
  SavedLocation? _selectedLocation;
  
  // Variables para la fecha de inicio
  DateTime _startDate = DateTime.now(); // Por defecto, hoy

  // Variables para el evento vinculado
  String? _selectedEventId;
  String? _selectedEventTitle;
  
  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
    
    // Agregar listeners para los controladores de texto
    _titleController.addListener(_handleTextFieldFocus);
    _descriptionController.addListener(_handleTextFieldFocus);
  }
  
  @override
  void dispose() {
    // Eliminar listeners al destruir el widget
    _titleController.removeListener(_handleTextFieldFocus);
    _descriptionController.removeListener(_handleTextFieldFocus);
    super.dispose();
  }
  
  // Controla el enfoque para los campos de texto
  void _handleTextFieldFocus() {
    // Este método se ejecutará cada vez que cambien los campos de texto
    // pero no hace nada, solo está para evitar problemas de enfoque
  }
  
  Future<void> _loadDefaultLocation() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final snapshot = await FirebaseFirestore.instance
          .collection('saved_locations')
          .where('createdBy', isEqualTo: FirebaseFirestore.instance.collection('users').doc(currentUser.uid))
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final location = SavedLocation.fromFirestore(snapshot.docs.first);
        setState(() {
          _selectedLocation = location;
          _location = location.address;
          _locationId = location.id;
        });
      }
    } catch (e) {
      print('Error al cargar localización predeterminada: $e');
    }
  }
  
  Future<void> _pickImage() async {
    // Quitar el enfoque de cualquier campo de texto antes de mostrar el picker
    FocusScope.of(context).unfocus();
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        // Permitimos cualquier imagen, sin restricciones
        imageQuality: 90, // Calidad inicial para la selección
      );
      
      if (image != null) {
        setState(() {
          _processedImage = null;
        });
        
        // Procesar la imagen para recortarla a 16:9 y comprimirla
        final processedImageFile = await _processImage(File(image.path));
        
        setState(() {
          _processedImage = processedImageFile;
          _isProcessingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${AppLocalizations.of(context)!.errorSelectingImage(e.toString())}';
          _isProcessingImage = false;
        });
      }
    }
  }
  
  Future<File> _processImage(File imageFile) async {
    try {
      // Decodificar la imagen
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      // Calcular la relación de aspecto 16:9
      const targetAspectRatio = 16 / 9;
      final currentAspectRatio = image.width / image.height;
      
      int targetWidth, targetHeight;
      img.Image croppedImage;
      
      if (currentAspectRatio > targetAspectRatio) {
        // Imagen más ancha que 16:9, recortar los lados
        targetHeight = image.height;
        targetWidth = (targetHeight * targetAspectRatio).round();
        
        // Calcular posición para centrar el recorte
        final xOffset = ((image.width - targetWidth) / 2).round();
        
        // Recortar imagen
        croppedImage = img.copyCrop(
          image, 
          x: xOffset, 
          y: 0, 
          width: targetWidth, 
          height: targetHeight
        );
      } else if (currentAspectRatio < targetAspectRatio) {
        // Imagen más alta que 16:9, recortar arriba/abajo
        targetWidth = image.width;
        targetHeight = (targetWidth / targetAspectRatio).round();
        
        // Calcular posición para centrar el recorte
        final yOffset = ((image.height - targetHeight) / 2).round();
        
        // Recortar imagen
        croppedImage = img.copyCrop(
          image, 
          x: 0, 
          y: yOffset, 
          width: targetWidth, 
          height: targetHeight
        );
      } else {
        // Ya está en 16:9, no es necesario recortar
        croppedImage = image;
      }
      
      // Redimensionar a un tamaño máximo para optimizar espacio
      // Mantener proporción 16:9 pero limitar tamaño máximo
      const maxWidth = 1280; // Ancho máximo para la imagen final
      
      if (croppedImage.width > maxWidth) {
        final maxHeight = (maxWidth / targetAspectRatio).round();
        croppedImage = img.copyResize(
          croppedImage,
          width: maxWidth,
          height: maxHeight,
          interpolation: img.Interpolation.linear
        );
      }
      
      // Comprimir la imagen a JPG con calidad controlada
      final compressedBytes = img.encodeJpg(croppedImage, quality: 85);
      
      // Guardar la imagen procesada en un archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/processed_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      
      return tempFile;
    } catch (e) {
      print('Error al procesar la imagen: $e');
      // Si hay error, devolver la imagen original
      return imageFile;
    }
  }
  
  void _showLocationSelector() {
    // Quitar el enfoque de cualquier campo de texto antes de mostrar el selector
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SavedLocationsModal(
        onLocationSelected: (location) {
          setState(() {
            _selectedLocation = location;
            _location = location.address;
            _locationId = location.id;
          });
          // No activar el enfoque después de seleccionar
        },
        onAddressEntered: (address) {
          setState(() {
            _selectedLocation = null;
            _location = address;
            _locationId = null;
          });
          // No activar el enfoque después de seleccionar
        },
      ),
    );
  }
  
  Future<void> _selectStartDate() async {
    // Quitar el enfoque antes de mostrar el selector de fecha
    FocusScope.of(context).unfocus();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: widget.cult.startTime, // No puede ser después de la fecha del culto
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
    
    // No volver a enfocar campos después de cerrar
  }
  
  Future<void> _selectEvent() async {
    // Quitar el enfoque antes de mostrar el selector de eventos
    FocusScope.of(context).unfocus();
    
    // Debug: estado inicial
    print('Estado inicial - eventId: $_selectedEventId, eventTitle: $_selectedEventTitle');
    
    // Usar showModalBottomSheet con el mismo estilo del resto de la app
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y botón de cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectingEvent,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(modalContext).pop();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Texto descriptivo
                  Text(
                    AppLocalizations.of(context)!.selectEventToLink,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Lista de eventos
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .where('isActive', isEqualTo: true)
                          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
                          .orderBy('startDate')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.noEventsAvailable,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.separated(
                          itemCount: snapshot.data!.docs.length,
                          separatorBuilder: (context, index) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final event = snapshot.data!.docs[index];
                            final eventData = event.data() as Map<String, dynamic>;
                            final eventDate = (eventData['startDate'] as Timestamp).toDate();
                            final String eventTitle = eventData['title'] ?? AppLocalizations.of(context)!.eventWithoutTitle;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  Icons.event,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                eventTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(eventDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              onTap: () {
                                print('Evento seleccionado: ID=${event.id}, título=$eventTitle');
                                
                                // Actualizar los valores directamente en el estado principal
                                setState(() {
                                  _selectedEventId = event.id;
                                  _selectedEventTitle = eventTitle;
                                });
                                
                                // Cerrar el modal DESPUÉS de la actualización
                                Navigator.of(modalContext).pop();
                                
                                // Confirmar la asignación
                                print('EVENTO ASIGNADO: ID=$_selectedEventId, título=$_selectedEventTitle');
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    // Confirmar después de cerrar el modal
    print('DESPUÉS DE CERRAR MODAL: eventId=$_selectedEventId, eventTitle=$_selectedEventTitle');
  }
  
  // Función para obtener el icono según el tipo de evento
  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'presential':
        return Icons.person;
      case 'online':
        return Icons.video_call;
      case 'hybrid':
        return Icons.devices;
      default:
        return Icons.event;
    }
  }
  
  // Función para obtener el texto según el tipo de evento
  String _getEventTypeText(String eventType) {
    switch (eventType) {
      case 'presential':
        return AppLocalizations.of(context)!.presential;
      case 'online':
        return AppLocalizations.of(context)!.online;
      case 'hybrid':
        return AppLocalizations.of(context)!.hybrid;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }
  
  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_processedImage == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseSelectAnnouncementImage;
      });
      return;
    }
    
    if (_location == null || _location!.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.pleaseSelectOrEnterLocation;
      });
      return;
    }
    
    print('ANTES DE CREAR ANUNCIO: eventId=$_selectedEventId, eventTitle=$_selectedEventTitle');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // 1. Subir la imagen
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('announcements')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(_processedImage!);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Progreso de subida: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      }, onError: (e) {
        print('Error durante la subida: $e');
      });
      
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      print('Imagen subida correctamente: $imageUrl');
      
      // 2. Crear el anuncio en Firestore
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(widget.cult.startTime), // Fecha de fin del anuncio (fecha del culto)
        'startDate': Timestamp.fromDate(_startDate), // Nueva fecha de inicio
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'isActive': true,
        'type': 'cult',
        'cultId': widget.cult.id,
        'serviceId': widget.cult.serviceId,
        'location': _location,
      };
      
      // Añadir locationId solo si existe
      if (_locationId != null) {
        data['locationId'] = _locationId;
      }

      // Añadir eventId si se seleccionó un evento
      if (_selectedEventId != null && _selectedEventId!.isNotEmpty) {
        data['eventId'] = _selectedEventId;
        print('Añadiendo eventId: $_selectedEventId al documento');
      } else {
        print('No se añadió eventId porque es null o vacío');
      }
      
      // Documento final para verificación
      print('Documento a crear: $data');
      
      // Crear el documento en Firestore
      DocumentReference docRef = await FirebaseFirestore.instance.collection('announcements').add(data);
      print('Documento creado con ID: ${docRef.id}');
      
      if (mounted) {
        Navigator.pop(context, true); // Cerrar el modal con resultado exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.announcementCreatedSuccessfully)),
        );
      }
    } catch (e) {
      print('Error al crear anuncio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorCreatingAnnouncement(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculamos la altura máxima disponible sin incluir la barra de notificaciones
    final maxHeight = MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top - 
                     MediaQuery.of(context).padding.bottom;
    final availableHeight = maxHeight * 0.9; // Usamos solo el 90% para dejar espacio
    
    // Verificamos si el teclado está abierto
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return GestureDetector(
      // Quitar el foco cuando se toca fuera de un campo de texto
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: isKeyboardOpen 
                ? availableHeight - keyboardHeight + 200 // Añadimos espacio adicional cuando el teclado está abierto
                : availableHeight,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 
            20, 
            20, 
            MediaQuery.of(context).viewInsets.bottom + 10
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.createCultAnnouncement,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Título del anuncio
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.announcementTitle,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterTitle2;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Descripción del anuncio
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                      border: OutlineInputBorder(),
                      hintText: AppLocalizations.of(context)!.cultInformation,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterDescription2;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Localización
                  InkWell(
                    onTap: _showLocationSelector,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.selectLocation,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.location_on),
                      ),
                      child: _location != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedLocation != null)
                                  Text(
                                    _selectedLocation!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                Text(
                                  _location!,
                                  style: TextStyle(
                                    color: _selectedLocation != null ? Colors.grey[700] : null,
                                  ),
                                ),
                              ],
                            )
                          : Text(AppLocalizations.of(context)!.selectLocation),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Evento vinculado
                  InkWell(
                    onTap: _selectEvent,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.linkedEventOptional,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.event),
                      ),
                      child: _selectedEventTitle != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedEventTitle!,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_selectedEventId != null)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedEventId = null;
                                            _selectedEventTitle = null;
                                          });
                                        },
                                        child: Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  AppLocalizations.of(context)!.eventLinkedToAnnouncement,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            )
                          : Text(AppLocalizations.of(context)!.selectEvent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selección de fecha de inicio para el anuncio
                  InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.announcementStartDate,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            _startDate.day == DateTime.now().day && 
                            _startDate.month == DateTime.now().month && 
                            _startDate.year == DateTime.now().year 
                              ? '(${AppLocalizations.of(context)!.today})' 
                              : '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selección de imagen
                  GestureDetector(
                    onTap: _isProcessingImage ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _isProcessingImage
                          ? AspectRatio(
                              aspectRatio: 16/9,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 12),
                                    Text(
                                      AppLocalizations.of(context)!.processingImage,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _processedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio: 16/9,
                                    child: Image.file(
                                      _processedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(AppLocalizations.of(context)!.selectImage),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)!.willBeAdaptedTo16x9,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Mensaje de error
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón para crear anuncio
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isProcessingImage) ? null : _createAnnouncement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(AppLocalizations.of(context)!.createAnnouncement),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32), // Espacio para evitar problemas con el teclado y respetar el padding inferior
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 