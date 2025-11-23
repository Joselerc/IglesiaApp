import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/church_location.dart';
import '../../theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class ManageChurchLocationsScreen extends StatefulWidget {
  const ManageChurchLocationsScreen({Key? key}) : super(key: key);

  @override
  State<ManageChurchLocationsScreen> createState() => _ManageChurchLocationsScreenState();
}

class _ManageChurchLocationsScreenState extends State<ManageChurchLocationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showCreateEditLocationModal({ChurchLocation? location}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateEditLocationModal(location: location),
    );
  }

  Future<void> _deleteLocation(String locationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.deleteLocationConfirmation), // TODO: Add key
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('churchLocations').doc(locationId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.locationDeletedSuccessfully)), // TODO: Add key
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _setDefaultLocation(String locationId) async {
    try {
      // Primero quitar default de todas
      final batch = _firestore.batch();
      final allDocs = await _firestore.collection('churchLocations').get();
      
      for (var doc in allDocs.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      
      // Establecer la nueva default
      batch.update(_firestore.collection('churchLocations').doc(locationId), {'isDefault': true});
      
      await batch.commit();
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Localização padrão atualizada')), // TODO: Localize
          );
      }
    } catch (e) {
       print('Error setting default: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
           AppLocalizations.of(context)!.manageLocations, // TODO: Add key
           style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditLocationModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: Text(AppLocalizations.of(context)!.newLocation, style: const TextStyle(color: Colors.white)), // TODO: Add key
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('churchLocations').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noLocationsFound, // TODO: Add key
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final locations = snapshot.data!.docs.map((doc) => ChurchLocation.fromFirestore(doc)).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final location = locations[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showCreateEditLocationModal(location: location),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: location.isDefault ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.church,
                            color: location.isDefault ? AppColors.primary : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      location.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (location.isDefault)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Padrão', // TODO: Localize
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location.fullAddress,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showCreateEditLocationModal(location: location);
                            } else if (value == 'delete') {
                              _deleteLocation(location.id);
                            } else if (value == 'default') {
                                _setDefaultLocation(location.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 12),
                                  Text(AppLocalizations.of(context)!.edit),
                                ],
                              ),
                            ),
                            if (!location.isDefault)
                                PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 20, color: Colors.grey[700]),
                                      const SizedBox(width: 12),
                                      const Text('Marcar como Padrão'), // TODO: Localize
                                    ],
                                  ),
                                ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.delete,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateEditLocationModal extends StatefulWidget {
  final ChurchLocation? location;

  const _CreateEditLocationModal({Key? key, this.location}) : super(key: key);

  @override
  State<_CreateEditLocationModal> createState() => _CreateEditLocationModalState();
}

class _CreateEditLocationModalState extends State<_CreateEditLocationModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController; // Street
  late TextEditingController _numberController;
  late TextEditingController _neighborhoodController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _complementController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _addressController = TextEditingController(text: widget.location?.address ?? '');
    _numberController = TextEditingController(text: widget.location?.number ?? '');
    _neighborhoodController = TextEditingController(text: widget.location?.neighborhood ?? '');
    _cityController = TextEditingController(text: widget.location?.city ?? '');
    _stateController = TextEditingController(text: widget.location?.state ?? '');
    _postalCodeController = TextEditingController(text: widget.location?.postalCode ?? '');
    _complementController = TextEditingController(text: widget.location?.complement ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _complementController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(), // Usamos 'address' como calle
        'street': _addressController.text.trim(), // Guardamos también como 'street' por compatibilidad
        'number': _numberController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'complement': _complementController.text.trim(),
        'country': 'Brasil', // Por defecto
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.location == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
        data['isDefault'] = false; // Por defecto no es default
        await FirebaseFirestore.instance.collection('churchLocations').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('churchLocations')
            .doc(widget.location!.id)
            .update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.location == null 
                ? AppLocalizations.of(context)!.locationCreatedSuccessfully // TODO
                : AppLocalizations.of(context)!.locationUpdatedSuccessfully // TODO
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        MediaQuery.of(context).viewInsets.bottom + 24
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
                    widget.location == null 
                        ? AppLocalizations.of(context)!.newLocation 
                        : AppLocalizations.of(context)!.editLocation, // TODO
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Nombre de la ubicación (ej: Sede, Iglesia Centro)
              _buildTextField(
                controller: _nameController,
                label: 'Nome da Localização', // TODO
                icon: Icons.label_outline,
                validator: (v) => v?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              
              // CEP
               _buildTextField(
                controller: _postalCodeController,
                label: 'CEP',
                icon: Icons.local_post_office_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                     flex: 2,
                     child: _buildTextField(
                      controller: _addressController,
                      label: 'Rua / Endereço', // TODO
                      icon: Icons.location_on_outlined,
                      validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildTextField(
                      controller: _numberController,
                      label: 'Número',
                      validator: (v) => v?.isEmpty ?? true ? 'Obrig.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                     child: _buildTextField(
                      controller: _neighborhoodController,
                      label: 'Bairro', // TODO
                      icon: Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _complementController,
                      label: 'Complemento',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                     child: _buildTextField(
                      controller: _cityController,
                      label: 'Cidade', // TODO
                      icon: Icons.location_city,
                      validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'Estado (UF)',
                      validator: (v) => v?.isEmpty ?? true ? 'Obrig.' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          AppLocalizations.of(context)!.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600], size: 20) : null,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

