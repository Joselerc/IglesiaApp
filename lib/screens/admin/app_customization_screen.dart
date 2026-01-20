import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/app_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

class AppCustomizationScreen extends StatefulWidget {
  const AppCustomizationScreen({Key? key}) : super(key: key);

  @override
  State<AppCustomizationScreen> createState() => _AppCustomizationScreenState();
}

class _AppCustomizationScreenState extends State<AppCustomizationScreen> {
  final AppConfigService _configService = AppConfigService();
  final TextEditingController _churchNameController = TextEditingController();
  
  bool _isLoading = false;
  String? _currentLogoUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _churchNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);
    
    try {
      final config = await _configService.getAppConfig();
      if (config != null && mounted) {
        setState(() {
          _churchNameController.text = config['churchName'] ?? 'Amor Em Movimento';
          _currentLogoUrl = config['logoUrl'];
        });
      }
    } catch (e) {
      _showErrorMessage('Error al cargar configuración: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorMessage('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _saveChurchName() async {
    if (_churchNameController.text.trim().isEmpty) {
      _showErrorMessage('El nombre de la iglesia no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _configService.updateChurchName(_churchNameController.text.trim());
      if (mounted) {
        _showSuccessMessage('Nombre actualizado correctamente');
      }
    } catch (e) {
      _showErrorMessage('Error al guardar nombre: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveLogo() async {
    if (_selectedImage == null) {
      _showErrorMessage('Por favor selecciona una imagen primero');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final downloadUrl = await _configService.updateChurchLogo(_selectedImage!);
      if (mounted) {
        setState(() {
          _currentLogoUrl = downloadUrl;
          _selectedImage = null;
        });
        _showSuccessMessage('Logo actualizado correctamente');
      }
    } catch (e) {
      _showErrorMessage('Error al guardar logo: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appCustomization),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Nombre de la Iglesia
                  _buildSectionTitle(AppLocalizations.of(context)!.churchNameConfig),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _churchNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.churchName,
                      hintText: 'Ej: Amor em Movimento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveChurchName,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Sección: Logo de la Iglesia
                  _buildSectionTitle(AppLocalizations.of(context)!.churchLogoConfig),
                  const SizedBox(height: AppSpacing.md),
                  if (_selectedImage != null)
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                      ),
                    )
                  else if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Image.network(
                        _currentLogoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.grey[100],
                      ),
                      child: const Center(
                        child: Icon(Icons.church, size: 50, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(AppLocalizations.of(context)!.selectImage),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedImage != null ? _saveLogo : null,
                          icon: const Icon(Icons.upload),
                          label: Text(AppLocalizations.of(context)!.uploadLogo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headline3.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

