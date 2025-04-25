import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/announcement_model.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const EditAnnouncementScreen({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  File? _selectedImage;
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _selectedDate;
  bool _imageChanged = false;
  
  // Variables para evento vinculado
  String? _selectedEventId;
  String? _selectedEventTitle;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _descriptionController = TextEditingController(text: widget.announcement.description);
    _selectedDate = widget.announcement.date;
    
    _selectedEventId = widget.announcement.eventId;
    if (_selectedEventId != null) {
      _loadEventDetails();
    }
  }
  
  Future<void> _loadEventDetails() async {
    if (_selectedEventId == null) return;
    
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(_selectedEventId)
          .get();
      
      if (eventDoc.exists && mounted) {
        final data = eventDoc.data() as Map<String, dynamic>;
        setState(() {
          _selectedEventTitle = data['title'] ?? 'Evento sem título';
        });
      } else if (mounted) {
           setState(() {
               _selectedEventTitle = 'Evento não encontrado';
           });
       }
    } catch (e) {
      print('Error al cargar detalles del evento: $e');
       if (mounted) {
           setState(() {
               _selectedEventTitle = 'Erro ao carregar evento';
           });
       }
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    if (_isLoading) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageChanged = true;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
          setState(() {
              _errorMessage = 'Erro ao selecionar imagem: $e';
          });
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    if (_isLoading) return;
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)), 
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Selecione uma data',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectEvent() async {
    if (_isLoading) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _selectedEventId != null 
              ? 'Alterar Evento Vinculado'
              : 'Selecionar Evento',
          style: AppTextStyles.headline3.copyWith(color: AppColors.textPrimary),
        ),
        contentPadding: const EdgeInsets.only(top: AppSpacing.md),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedEventId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Evento vinculado atualmente',
                                style: AppTextStyles.subtitle2.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _selectedEventTitle ?? 'Evento sem título',
                          style: AppTextStyles.bodyText1.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedEventId = null;
                                _selectedEventTitle = null;
                              });
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.link_off, size: 18),
                            label: const Text('Desvincular evento'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                          ),
                        ),
                      ],
                    ),                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Text(
                  _selectedEventId == null 
                    ? 'Selecione um evento futuro para vincular a este anúncio.'
                    : 'Selecione outro evento futuro para alterar o vínculo.',
                  style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              
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
                    
                    if (snapshot.hasError) {
                        return Center(
                            child: Text('Erro ao carregar eventos: ${snapshot.error}', textAlign: TextAlign.center)
                        );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Não há eventos futuros disponíveis',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final event = snapshot.data!.docs[index];
                        final data = event.data() as Map<String, dynamic>;
                        final eventDate = (data['startDate'] as Timestamp).toDate();
                        final isSelected = event.id == _selectedEventId;
                        final eventType = data['type'] ?? data['eventType'] ?? 'presential';
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.1),
                            child: Icon(
                              _getEventTypeIcon(eventType),
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            data['title'] ?? 'Evento sem título',
                            style: AppTextStyles.subtitle2.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              '${DateFormat('dd/MM/yyyy').format(eventDate)} - ${_getEventTypeText(eventType)}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          trailing: isSelected 
                              ? Icon(Icons.check_circle, color: AppColors.success)
                              : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          selected: isSelected,
                          selectedTileColor: AppColors.primary.withOpacity(0.05),
                          onTap: () => Navigator.pop(context, {
                            'id': event.id,
                            'title': data['title'] ?? 'Evento sem título',
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedEventId = result['id'];
        _selectedEventTitle = result['title'];
      });
    }
  }
  
  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'presential':
        return Icons.people_outline;
      case 'online':
        return Icons.videocam_outlined;
      case 'hybrid':
        return Icons.devices_outlined;
      default:
        return Icons.event_outlined;
    }
  }
  
  String _getEventTypeText(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'presential':
        return 'Presencial';
      case 'online':
        return 'Online';
      case 'hybrid':
        return 'Híbrido';
      default:
        return 'Evento';
    }
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
       setState(() {
           _errorMessage = 'Por favor, preencha todos os campos obrigatórios.';
       });
       return;
    }
    if (_selectedDate == null) {
        setState(() {
            _errorMessage = 'Por favor, selecione uma data para o anúncio.';
        });
        return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final announcementRef = FirebaseFirestore.instance
          .collection('announcements')
          .doc(widget.announcement.id);
      
      String imageUrl = widget.announcement.imageUrl;
      
      if (_imageChanged && _selectedImage != null) {
        if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
          try {
            await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Erro ao eliminar imagem anterior (pode já não existir): $e');
          }
        }
        
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('announcements')
            .child('${announcementRef.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      } else if (_imageChanged && _selectedImage == null) {
          if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
              try {
                  await FirebaseStorage.instance.refFromURL(imageUrl).delete();
              } catch (e) {
                  print('Erro ao eliminar imagem anterior: $e');
              }
          }
          imageUrl = '';
      }
      
      final Map<String, dynamic> updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(_selectedDate!),
        'updatedAt': FieldValue.serverTimestamp(),
        'eventId': _selectedEventId,
      };
      
      await announcementRef.update(updateData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Anúncio atualizado com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
          setState(() {
              _isLoading = false;
              _errorMessage = 'Erro ao atualizar anúncio: $e';
          });
      }
    } finally {
      if (mounted && _isLoading) { 
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isCultAnnouncement = widget.announcement.type == 'cult';
    final dividerColor = Theme.of(context).dividerColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isCultAnnouncement ? 'Editar Anúncio de Culto' : 'Editar Anúncio'),
        actions: const [ 
         ], 
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + 80), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCultAnnouncement
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCultAnnouncement
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.purple.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCultAnnouncement ? Icons.church : Icons.announcement,
                          size: 20,
                          color: isCultAnnouncement ? Colors.blue : Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCultAnnouncement ? 'Anuncio de Culto' : 'Anuncio Regular',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCultAnnouncement ? Colors.blue : Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  Text(
                    'Imagem do Anúncio',
                    style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: _pickImage,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                          border: Border.all(color: dividerColor),
                        ),
                        child: _imageChanged && _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.md),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imagePlaceholder(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título',
                    hint: 'Título do anúncio',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira um título';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Descrição',
                    hint: 'Descrição detalhada do anúncio',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira uma descrição';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  Text(
                    'Data do Anúncio',
                    style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          borderSide: BorderSide(color: dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg-2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate != null 
                                ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                                : 'Selecione uma data',
                            style: AppTextStyles.bodyText1.copyWith(
                                color: _selectedDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (isCultAnnouncement) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Evento Vinculado (Opcional)',
                      style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      onTap: _selectEvent,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                        decoration: BoxDecoration(
                          border: Border.all(color: dividerColor),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              color: _selectedEventId != null ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _selectedEventTitle ?? 'Selecionar evento',
                                style: AppTextStyles.bodyText1.copyWith(
                                  color: _selectedEventId != null ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: AppTextStyles.bodyText2.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, 
            AppSpacing.md, 
            AppSpacing.lg, 
            AppSpacing.md + MediaQuery.of(context).padding.bottom
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _saveChanges,
          icon: _isLoading 
              ? Container(
                  width: 20, 
                  height: 20, 
                  child: const CircularProgressIndicator(
                      color: Colors.white, 
                      strokeWidth: 2
                  )
                ) 
              : const Icon(Icons.save_alt_outlined, size: 20),
          label: Text(
              _isLoading ? 'Salvando...' : 'Salvar Alterações',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            textStyle: AppTextStyles.button,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required FormFieldValidator<String> validator,
    int maxLines = 1,
  }) {
    final dividerColor = Theme.of(context).dividerColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(color: dividerColor),
            ),
             enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, 
                vertical: maxLines > 1 ? AppSpacing.md : AppSpacing.lg-2
            ),
            alignLabelWithHint: maxLines > 1,
          ),
          maxLines: maxLines,
          validator: validator,
          style: AppTextStyles.bodyText1,
        ),
      ],
    );
  }
  
  Widget _imagePlaceholder() {
    final hasExistingImage = widget.announcement.imageUrl.isNotEmpty;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        if (hasExistingImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: Image.network(
              widget.announcement.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          'Erro ao carregar imagem',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Adicionar imagem',
                  style: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Center(
            child: Text(
              'Toque para alterar a imagem',
              textAlign: TextAlign.center,
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
} 