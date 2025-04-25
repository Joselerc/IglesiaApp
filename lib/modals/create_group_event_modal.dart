import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/group.dart';
import '../services/event_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

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
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedEndTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  File? _selectedImage;
  bool _isLoading = false;
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
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnDark,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != _selectedStartDate) {
      setState(() {
        _selectedStartDate = pickedDate;
        // Se a data de término for anterior à data de início, atualizá-la
        if (_selectedEndDate.isBefore(_selectedStartDate)) {
          _selectedEndDate = _selectedStartDate;
        }
      });
    }
  }
  
  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnDark,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && pickedTime != _selectedStartTime) {
      setState(() {
        _selectedStartTime = pickedTime;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnDark,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != _selectedEndDate) {
      setState(() {
        _selectedEndDate = pickedDate;
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnDark,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && pickedTime != _selectedEndTime) {
      setState(() {
        _selectedEndTime = pickedTime;
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Combinar data e hora de início
      final eventStartDateTime = DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month,
        _selectedStartDate.day,
        _selectedStartTime.hour,
        _selectedStartTime.minute,
      );
      
      // Combinar data e hora de término
      final eventEndDateTime = DateTime(
        _selectedEndDate.year,
        _selectedEndDate.month,
        _selectedEndDate.day,
        _selectedEndTime.hour,
        _selectedEndTime.minute,
      );
      
      // Validar que a data de término seja posterior à data de início
      if (eventEndDateTime.isBefore(eventStartDateTime)) {
        throw Exception('A data de término deve ser posterior à data de início');
      }
      
      // Criar evento usando o serviço
      await _eventService.createGroupEvent(
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: eventStartDateTime,
        endDate: eventEndDateTime,
        location: _locationController.text.trim(),
        imageFile: _selectedImage,
        creatorId: FirebaseAuth.instance.currentUser!.uid,
      );
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evento criado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar evento: $e'),
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabeçalho
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, 
              vertical: AppSpacing.sm
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Criar Evento do Grupo',
                  style: AppTextStyles.subtitle1,
                ),
                _isLoading
                    ? SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.check, color: AppColors.primary),
                        onPressed: _createEvent,
                      ),
              ],
            ),
          ),
          
          // Conteúdo rolável
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título do evento
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título do evento',
                        hintText: 'Ex: Reunião semanal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira um título';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppSpacing.md),
                    
                    // Descrição
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Detalhes sobre o evento...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira uma descrição';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppSpacing.md),
                    
                    // Data e hora
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data e hora de início',
                          style: AppTextStyles.subtitle2,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            // Seletor de data de início
                            Expanded(
                              child: InkWell(
                                onTap: _selectDate,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Data',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedStartDate),
                                    style: AppTextStyles.bodyText1,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: AppSpacing.md),
                            
                            // Seletor de hora de início
                            Expanded(
                              child: InkWell(
                                onTap: _selectTime,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Hora',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time, color: AppColors.textSecondary),
                                  ),
                                  child: Text(
                                    _selectedStartTime.format(context),
                                    style: AppTextStyles.bodyText1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: AppSpacing.lg),
                        
                        Text(
                          'Data e hora de término',
                          style: AppTextStyles.subtitle2,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            // Seletor de data de término
                            Expanded(
                              child: InkWell(
                                onTap: _selectEndDate,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Data',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.calendar_today, color: AppColors.textSecondary),
                                  ),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedEndDate),
                                    style: AppTextStyles.bodyText1,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: AppSpacing.md),
                            
                            // Seletor de hora de término
                            Expanded(
                              child: InkWell(
                                onTap: _selectEndTime,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Hora',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time, color: AppColors.textSecondary),
                                  ),
                                  child: Text(
                                    _selectedEndTime.format(context),
                                    style: AppTextStyles.bodyText1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: AppSpacing.md),
                    
                    // Localização
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Localização',
                        hintText: 'Ex: Salão principal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira uma localização';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: AppSpacing.lg),
                    
                    // Imagem do evento
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Imagem (opcional)',
                              style: AppTextStyles.subtitle2,
                            ),
                            Text(
                              'Recomendado: formato 16:9',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                        if (_selectedImage != null) ...[
                          // Si hay una imagen seleccionada, mostrarla y permitir tocar para cambiarla
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  // Botón para eliminar la imagen
                                  Padding(
                                    padding: EdgeInsets.all(AppSpacing.sm),
                                    child: CircleAvatar(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      radius: 16,
                                      child: IconButton(
                                        icon: Icon(Icons.close, size: 16),
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
                        ] else ...[
                          // Si no hay imagen, mostrar un placeholder clicable
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                                border: Border.all(
                                  color: AppColors.mutedGray.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: AppColors.mutedGray,
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Adicionar imagem no formato 16:9',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Imagem de capa do evento',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Botão de criar
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Color(0xFFE64A19),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(double.infinity, 45),
              ),
              child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'CRIAR EVENTO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
} 