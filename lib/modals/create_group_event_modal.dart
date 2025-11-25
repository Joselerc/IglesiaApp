import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../services/event_service.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../../models/church_location.dart';
import '../../screens/admin/manage_church_locations_screen.dart';

class CreateGroupEventModal extends StatefulWidget {
  final Group group;

  const CreateGroupEventModal({
    super.key,
    required this.group,
  });

  @override
  State<CreateGroupEventModal> createState() => _CreateGroupEventModalState();
}

class _CreateGroupEventModalState extends State<CreateGroupEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 19, minute: 0);
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 21, minute: 0);
  File? _selectedImage;
  bool _isLoading = false;
  bool _isAttending = true; // Opción de asistencia por defecto
  String? _selectedAddress; // Dirección completa seleccionada
  final EventService _eventService = EventService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final String fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final String tempPath = path.join(tempDir.path, fileName);
      
      File tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      
      final compressedImage = await ImageService().compressImage(
        tempFile,
        quality: 85,
      );
      
      setState(() {
        _selectedImage = compressedImage ?? tempFile;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart ? _selectedStartDate : _selectedEndDate;
    final firstDate = isStart ? DateTime.now() : _selectedStartDate;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = pickedDate;
          if (_selectedEndDate.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = pickedDate;
        }
      });
    }
  }
  
  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart ? _selectedStartTime : _selectedEndTime;
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _selectedStartTime = pickedTime;
        } else {
          _selectedEndTime = pickedTime;
        }
      });
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectLocation, // Asegúrate de tener esta key o usa un string hardcoded por ahora
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageChurchLocationsScreen()),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.createOrEdit),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('churchLocations').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                AppLocalizations.of(context)!.noLocationsFound,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final locations = snapshot.data!.docs.map((doc) => ChurchLocation.fromFirestore(doc)).toList();

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: locations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.church, color: Colors.white, size: 20),
                            radius: 18,
                          ),
                          title: Text(location.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(location.fullAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            setState(() {
                              _locationController.text = location.name;
                              _selectedAddress = location.fullAddress;
                            });
                            Navigator.pop(context);
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
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Capturar servicio antes de async
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventStartDateTime = DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month,
        _selectedStartDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );
      
      final eventEndDateTime = DateTime(
        _selectedEndDate.year,
        _selectedEndDate.month,
        _selectedEndDate.day,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );
      
      if (eventEndDateTime.isBefore(eventStartDateTime)) {
        throw Exception(AppLocalizations.of(context)!.endDateMustBeAfterStartDate);
      }
      
      // Crear evento
      final eventId = await _eventService.createGroupEvent(
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: eventStartDateTime,
        endDate: eventEndDateTime,
        location: _locationController.text.trim(),
        address: _selectedAddress,
        imageFile: _selectedImage,
        creatorId: FirebaseAuth.instance.currentUser!.uid,
      );

      // Marcar asistencia si está seleccionado
      if (_isAttending) {
        await _eventService.markAttendance(
          eventId: eventId,
          userId: FirebaseAuth.instance.currentUser!.uid,
          eventType: 'group',
          attending: true,
        );
      }

      // Enviar notificación (sin check de mounted)
      try {
        await notificationService.sendGroupNewEventNotification(
          groupId: widget.group.id,
          groupName: widget.group.name,
          eventId: eventId,
          eventTitle: _titleController.text.trim(),
          memberIds: widget.group.memberIds,
        );
      } catch (e) {
        print('Error enviando notificación de evento grupo: $e');
      }
        
      // Navegar atrás y mostrar éxito
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventCreatedSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorCreatingEvent}: $e'),
            backgroundColor: AppColors.error,
          ),
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
    // Diseño tipo Google Forms / Calendar
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.createGroupEvent,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _createEvent,
                        child: Text(
                          AppLocalizations.of(context)!.save,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Formulario
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.eventTitle,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.title, color: Colors.grey),
                      ),
                      validator: (value) => value?.trim().isEmpty == true 
                          ? AppLocalizations.of(context)!.pleaseEnterTitle 
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Fechas y Horas
                    _buildDateTimeRow(
                      icon: Icons.access_time,
                      label: AppLocalizations.of(context)!.start,
                      date: _selectedStartDate,
                      time: _selectedStartTime,
                      onDateTap: () => _selectDate(isStart: true),
                      onTimeTap: () => _selectTime(isStart: true),
                    ),
                    const SizedBox(height: 16),
                    _buildDateTimeRow(
                      icon: Icons.access_time_filled, // Icono diferente para diferenciar visualmente si se desea
                      label: AppLocalizations.of(context)!.end,
                      date: _selectedEndDate,
                      time: _selectedEndTime,
                      onDateTap: () => _selectDate(isStart: false),
                      onTimeTap: () => _selectTime(isStart: false),
                    ),
                    
                    const SizedBox(height: 24),

                    // Ubicación
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.location,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primary),
                              onPressed: _showLocationPicker,
                              tooltip: AppLocalizations.of(context)!.selectLocation,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (value) {
                            // Si el usuario edita el texto, limpiamos la dirección guardada
                            // para tratarlo como una ubicación manual
                            if (_selectedAddress != null) {
                              setState(() {
                                _selectedAddress = null;
                              });
                            }
                          },
                          validator: (value) => value?.trim().isEmpty == true 
                              ? AppLocalizations.of(context)!.pleaseEnterLocation 
                              : null,
                        ),
                        if (_selectedAddress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedAddress!,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: InkWell(
                            onTap: _showLocationPicker,
                            child: Text(
                              AppLocalizations.of(context)!.useSavedLocation,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) => value?.trim().isEmpty == true 
                          ? AppLocalizations.of(context)!.pleaseEnterDescription 
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // Imagen
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, 
                                      size: 40, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.addImage,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 16,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _selectedImage = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Opción de asistencia
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppLocalizations.of(context)!.iWillAttend,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      value: _isAttending,
                      onChanged: (bool? value) {
                        setState(() {
                          _isAttending = value ?? true;
                        });
                      },
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    const SizedBox(height: 40), // Espacio extra al final
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow({
    required IconData icon,
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      DateFormat('EEE, d MMM yyyy').format(date),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onTimeTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    time.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
