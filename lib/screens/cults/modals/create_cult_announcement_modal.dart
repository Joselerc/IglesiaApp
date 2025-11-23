import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../models/cult.dart';
import '../../../models/church_location.dart'; // Usar el nuevo modelo
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
  String? _locationName;
  String? _locationAddress;
  String? _locationId;
  
  // Variables para la fecha de inicio
  DateTime _startDate = DateTime.now(); 

  // Variables para el evento vinculado
  String? _selectedEventId;
  String? _selectedEventTitle;
  
  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDefaultLocation() async {
    try {
      // Buscar localización por defecto en la colección churchLocations
      final snapshot = await FirebaseFirestore.instance
          .collection('churchLocations')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final location = ChurchLocation.fromFirestore(snapshot.docs.first);
        setState(() {
          _locationName = location.name;
          _locationAddress = location.fullAddress;
          _locationId = location.id;
        });
      }
    } catch (e) {
      print('Error al cargar localización predeterminada: $e');
    }
  }
  
  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image != null) {
        setState(() {
          _processedImage = null;
          _isProcessingImage = true;
        });
        
        final processedImageFile = await _processImage(File(image.path));
        
        if (mounted) {
          setState(() {
            _processedImage = processedImageFile;
            _isProcessingImage = false;
          });
        }
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
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('No se pudo decodificar la imagen');
      
      const targetAspectRatio = 16 / 9;
      final currentAspectRatio = image.width / image.height;
      
      int targetWidth, targetHeight;
      img.Image croppedImage;
      
      if (currentAspectRatio > targetAspectRatio) {
        targetHeight = image.height;
        targetWidth = (targetHeight * targetAspectRatio).round();
        final xOffset = ((image.width - targetWidth) / 2).round();
        croppedImage = img.copyCrop(image, x: xOffset, y: 0, width: targetWidth, height: targetHeight);
      } else if (currentAspectRatio < targetAspectRatio) {
        targetWidth = image.width;
        targetHeight = (targetWidth / targetAspectRatio).round();
        final yOffset = ((image.height - targetHeight) / 2).round();
        croppedImage = img.copyCrop(image, x: 0, y: yOffset, width: targetWidth, height: targetHeight);
      } else {
        croppedImage = image;
      }
      
      const maxWidth = 1280;
      if (croppedImage.width > maxWidth) {
        final maxHeight = (maxWidth / targetAspectRatio).round();
        croppedImage = img.copyResize(croppedImage, width: maxWidth, height: maxHeight, interpolation: img.Interpolation.linear);
      }
      
      final compressedBytes = img.encodeJpg(croppedImage, quality: 85);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/processed_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      
      return tempFile;
    } catch (e) {
      print('Error al procesar la imagen: $e');
      return imageFile;
    }
  }
  
  void _showLocationSelector() {
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectLocation,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('churchLocations').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text(AppLocalizations.of(context)!.noLocationsFound)); // TODO
                  }
                  
                  return ListView.separated(
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final loc = ChurchLocation.fromFirestore(snapshot.data!.docs[index]);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[100],
                          child: const Icon(Icons.church, color: AppColors.primary),
                        ),
                        title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(loc.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          setState(() {
                            _locationName = loc.name;
                            _locationAddress = loc.fullAddress;
                            _locationId = loc.id;
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
      ),
    );
  }
  
  Future<void> _selectStartDate() async {
    FocusScope.of(context).unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: widget.cult.startTime.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  Future<void> _selectEvent() async {
    FocusScope.of(context).unfocus();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.selectingEvent,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.selectEventToLink,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
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
                      return Center(child: Text(AppLocalizations.of(context)!.noEventsAvailable));
                    }
                    
                    return ListView.separated(
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final event = snapshot.data!.docs[index];
                        final eventData = event.data() as Map<String, dynamic>;
                        final eventDate = (eventData['startDate'] as Timestamp).toDate();
                        final String eventTitle = eventData['title'] ?? AppLocalizations.of(context)!.eventWithoutTitle;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.event, color: AppColors.primary),
                          ),
                          title: Text(eventTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(eventDate)),
                          onTap: () {
                            setState(() {
                              _selectedEventId = event.id;
                              _selectedEventTitle = eventTitle;
                            });
                            Navigator.of(modalContext).pop();
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
  
  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_processedImage == null) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.pleaseSelectAnnouncementImage);
      return;
    }
    
    if (_locationName == null || _locationName!.isEmpty) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.pleaseSelectOrEnterLocation);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');
      
      // 1. Subir imagen
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('announcements')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(_processedImage!);
      final snapshot = await uploadTask.whenComplete(() => null);
      final imageUrl = await snapshot.ref.getDownloadURL();
      
      // 2. Crear anuncio
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(widget.cult.startTime),
        'startDate': Timestamp.fromDate(_startDate),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'isActive': true,
        'type': 'cult',
        'cultId': widget.cult.id,
        'serviceId': widget.cult.serviceId,
        'location': _locationAddress ?? _locationName, 
      };
      
      if (_locationId != null) {
        data['locationId'] = _locationId;
      }

      if (_selectedEventId != null && _selectedEventId!.isNotEmpty) {
        data['eventId'] = _selectedEventId;
      }
      
      await FirebaseFirestore.instance.collection('announcements').add(data);
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.announcementCreatedSuccessfully), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error al crear anuncio: $e');
      if (mounted) {
         setState(() => _errorMessage = AppLocalizations.of(context)!.errorCreatingAnnouncement(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    AppLocalizations.of(context)!.createCultAnnouncement,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildTextField(
                controller: _titleController,
                label: AppLocalizations.of(context)!.announcementTitle,
                icon: Icons.title,
                validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.pleaseEnterTitle2 : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: AppLocalizations.of(context)!.description,
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.pleaseEnterDescription2 : null,
              ),
              const SizedBox(height: 16),
              
              // Selector de ubicación
              InkWell(
                onTap: _showLocationSelector,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationName ?? AppLocalizations.of(context)!.selectLocation,
                              style: TextStyle(
                                fontWeight: _locationName != null ? FontWeight.bold : FontWeight.normal,
                                color: _locationName != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            if (_locationAddress != null)
                              Text(
                                _locationAddress!,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Evento
               InkWell(
                onTap: _selectEvent,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedEventTitle ?? AppLocalizations.of(context)!.linkedEventOptional,
                              style: TextStyle(
                                fontWeight: _selectedEventTitle != null ? FontWeight.bold : FontWeight.normal,
                                color: _selectedEventTitle != null ? Colors.black87 : Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedEventTitle != null)
                                Text(
                                  AppLocalizations.of(context)!.tapToChange,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                          ],
                        ),
                      ),
                      if (_selectedEventTitle != null)
                        InkWell(
                          onTap: () {
                             setState(() {
                               _selectedEventId = null;
                               _selectedEventTitle = null;
                             });
                          },
                          child: Icon(Icons.clear, size: 20, color: Colors.grey[600])
                        )
                      else
                        const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Selector de fecha de inicio
              InkWell(
                onTap: _selectStartDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              AppLocalizations.of(context)!.announcementStartDate,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_startDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Selector de Imagen
              GestureDetector(
                onTap: _isProcessingImage ? null : _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _isProcessingImage
                      ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 8), Text("Procesando...")]))
                      : _processedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_processedImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(AppLocalizations.of(context)!.selectImage, style: TextStyle(color: Colors.grey[600])),
                                Text("Formato 16:9", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              ],
                            ),
                ),
              ),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                ),
                
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isProcessingImage) ? null : _createAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.createAnnouncement, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 8, bottom: 2), child: Icon(icon, color: Colors.grey[600])), // Ajuste para alineación en multiline
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
}
