import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class EventLocationType {
  static const String presential = 'presential';
  static const String online = 'online';
  static const String hybrid = 'hybrid';
}

class EventLocationStep extends StatefulWidget {
  final Function(Map<String, dynamic> locationData) onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final String? initialLocationType;
  final bool? initialUseChurchLocation;
  final String? initialChurchLocationId;
  final String? initialCountryCode;
  final String? initialState;
  final String? initialCity;
  final String? initialPostalCode;
  final String? initialNeighborhood;
  final String? initialStreet;
  final String? initialNumber;
  final String? initialComplement;
  final String? initialUrl;

  const EventLocationStep({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
    this.initialLocationType,
    this.initialUseChurchLocation,
    this.initialChurchLocationId,
    this.initialCountryCode,
    this.initialState,
    this.initialCity,
    this.initialPostalCode,
    this.initialNeighborhood,
    this.initialStreet,
    this.initialNumber,
    this.initialComplement,
    this.initialUrl,
  });

  @override
  State<EventLocationStep> createState() => _EventLocationStepState();
}

class _EventLocationStepState extends State<EventLocationStep> {
  final _formKey = GlobalKey<FormState>();
  String _locationType = EventLocationType.presential;
  bool _useChurchLocation = false;
  String? _selectedChurchLocationId;
  String? _selectedSavedLocationId;
  bool _useSavedLocation = false;
  
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  
  List<DocumentSnapshot>? _churchLocations;
  List<DocumentSnapshot>? _savedLocations;
  bool _isLoadingChurchLocations = false;
  bool _isLoadingSavedLocations = false;
  bool _savingLocation = false;
  bool _saveThisLocation = false;
  bool _saveAsChurchLocation = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar valores
    _locationType = widget.initialLocationType ?? EventLocationType.presential;
    _useChurchLocation = widget.initialUseChurchLocation ?? false;
    _selectedChurchLocationId = widget.initialChurchLocationId;
    
    _countryCodeController.text = widget.initialCountryCode ?? '';
    _stateController.text = widget.initialState ?? '';
    _cityController.text = widget.initialCity ?? '';
    _postalCodeController.text = widget.initialPostalCode ?? '';
    _neighborhoodController.text = widget.initialNeighborhood ?? '';
    _streetController.text = widget.initialStreet ?? '';
    _numberController.text = widget.initialNumber ?? '';
    _complementController.text = widget.initialComplement ?? '';
    _urlController.text = widget.initialUrl ?? '';
    
    // Cargar ubicaciones de la iglesia y ubicaciones guardadas
    _loadChurchLocations();
    _loadSavedLocations();
  }
  
  @override
  void dispose() {
    _countryCodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _neighborhoodController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _urlController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChurchLocations() async {
    setState(() => _isLoadingChurchLocations = true);
    
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('churchLocations')
          .get();
      
      setState(() {
        _churchLocations = snapshot.docs;
        _isLoadingChurchLocations = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingLocations(e.toString()))),
        );
        setState(() => _isLoadingChurchLocations = false);
      }
    }
  }
  
  Future<void> _loadSavedLocations() async {
    setState(() => _isLoadingSavedLocations = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoadingSavedLocations = false);
        return;
      }
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedLocations')
          .get();
      
      setState(() {
        _savedLocations = snapshot.docs;
        _isLoadingSavedLocations = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingSavedLocations(e.toString()))),
        );
        setState(() => _isLoadingSavedLocations = false);
      }
    }
  }
  
  Future<void> _saveLocation() async {
    if (_locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterLocationNameForSave)),
      );
      return;
    }
    
    setState(() => _savingLocation = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final Map<String, dynamic> locationData = {
        'name': _locationNameController.text,
        'country': _countryCodeController.text,
        'state': _stateController.text,
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'neighborhood': _neighborhoodController.text,
        'street': _streetController.text,
        'number': _numberController.text,
        'complement': _complementController.text,
        'createdAt': Timestamp.now(),
      };
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedLocations')
          .add(locationData);
      
      // Recargar ubicaciones guardadas
      await _loadSavedLocations();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.locationSavedSuccessfully)),
      );
      
      setState(() {
        _saveThisLocation = false;
        _locationNameController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingLocation(e.toString()))),
      );
    } finally {
      setState(() => _savingLocation = false);
    }
  }
  
  // Método para guardar la ubicación como ubicación de la iglesia
  Future<void> _saveChurchLocation() async {
    if (_locationNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterLocationNameForSave)),
      );
      return;
    }
    
    setState(() => _savingLocation = true);
    
    try {
      // Verificar si el usuario está autenticado
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Crear la ubicación de la iglesia
      final Map<String, dynamic> churchLocationData = {
        'name': _locationNameController.text,
        'country': _countryCodeController.text,
        'state': _stateController.text,
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'neighborhood': _neighborhoodController.text,
        'street': _streetController.text,
        'number': _numberController.text,
        'complement': _complementController.text,
        'createdAt': Timestamp.now(),
        'createdBy': userId,
      };
      
      await FirebaseFirestore.instance
          .collection('churchLocations')
          .add(churchLocationData);
      
      // Recargar ubicaciones de la iglesia
      await _loadChurchLocations();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.churchLocationSavedSuccessfully)),
      );
      
      setState(() {
        _saveThisLocation = false;
        _locationNameController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingLocation(e.toString()))),
      );
    } finally {
      setState(() => _savingLocation = false);
    }
  }
  
  // Rellena los campos con la ubicación seleccionada
  void _fillLocationFields(Map<String, dynamic> data) {
    setState(() {
      _countryCodeController.text = data['country'] ?? '';
      _stateController.text = data['state'] ?? '';
      _cityController.text = data['city'] ?? '';
      _postalCodeController.text = data['postalCode'] ?? '';
      _neighborhoodController.text = data['neighborhood'] ?? '';
      _streetController.text = data['street'] ?? '';
      _numberController.text = data['number'] ?? '';
      _complementController.text = data['complement'] ?? '';
      
      // Si hay una URL en los datos y el tipo de evento es online o híbrido
      if (data['url'] != null && (_locationType == EventLocationType.online || _locationType == EventLocationType.hybrid)) {
        _urlController.text = data['url'];
      }
    });
  }
  
  void _handleNext() {
    if (!_formKey.currentState!.validate()) return;
    
    // Verificar que si se seleccionó ubicación de iglesia, se haya elegido una
    if (_useChurchLocation && (_selectedChurchLocationId == null || _selectedChurchLocationId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectChurchLocation)),
      );
      return;
    }
    
    // Verificar que si se seleccionó ubicación guardada, se haya elegido una
    if (_useSavedLocation && (_selectedSavedLocationId == null || _selectedSavedLocationId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectASavedLocation)),
      );
      return;
    }
    
    // Si estamos usando una ubicación de iglesia, vamos a asegurarnos de que 
    // los datos de ubicación se copien correctamente
    if (_useChurchLocation && _selectedChurchLocationId != null && _churchLocations != null) {
      // Buscar manualmente la ubicación de iglesia seleccionada
      DocumentSnapshot? churchLocation;
      for (var doc in _churchLocations!) {
        if (doc.id == _selectedChurchLocationId) {
          churchLocation = doc;
          break;
        }
      }
      
      // Si encontramos la ubicación, usar sus datos
      if (churchLocation != null) {
        final data = churchLocation.data() as Map<String, dynamic>;
        _fillLocationFields(data);
      }
    }
    
    // Crear un mapa con los datos del formulario
    final Map<String, dynamic> locationData = {
      'eventType': _locationType,
      'useChurchLocation': _useChurchLocation,
      'churchLocationId': _selectedChurchLocationId,
      'country': _countryCodeController.text,
      'state': _stateController.text,
      'city': _cityController.text,
      'postalCode': _postalCodeController.text,
      'neighborhood': _neighborhoodController.text,
      'street': _streetController.text,
      'number': _numberController.text,
      'complement': _complementController.text,
      'url': _urlController.text,
    };
    
    widget.onNext(locationData);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.eventLocation,
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.defineWhereEventWillHappen,
                  style: AppTextStyles.bodyText2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tipo de evento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.event,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.eventType,
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Botones de tipo de evento
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botón Presencial
                          Expanded(
                            child: _buildTypeButton(
                              EventLocationType.presential,
                              AppLocalizations.of(context)!.presential,
                              Icons.location_on,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Botón Online
                          Expanded(
                            child: _buildTypeButton(
                              EventLocationType.online,
                              AppLocalizations.of(context)!.online,
                              Icons.videocam,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Botón Híbrido
                          Expanded(
                            child: _buildTypeButton(
                              EventLocationType.hybrid,
                              AppLocalizations.of(context)!.hybrid, 
                              Icons.sync_alt,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Sección de detalles de ubicación
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _locationType != EventLocationType.online 
                      ? _buildPresentialSection()
                      : _buildOnlineSection(),
                ),
                
                const SizedBox(height: 24),
                
                // Botones de navegación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: widget.onBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(AppLocalizations.of(context)!.back),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.next,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                // Espacio adicional para alejar los botones del borde inferior
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Método para construir los botones de tipo de evento
  Widget _buildTypeButton(String type, String label, IconData icon, Color color) {
    final isSelected = _locationType == type;
    
    return Material(
      color: isSelected 
          ? color.withOpacity(0.1) 
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            _locationType = type;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Sección para eventos presenciales e híbridos
  Widget _buildPresentialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de ubicaciones de la iglesia
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.church,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.churchLocations,
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Switch para usar ubicación de la iglesia
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.useChurchLocation),
                subtitle: Text(AppLocalizations.of(context)!.selectRegisteredLocation),
                value: _useChurchLocation,
                activeColor: AppColors.primary,
                onChanged: (bool value) {
                  setState(() {
                    _useChurchLocation = value;
                    if (!value) {
                      _selectedChurchLocationId = null;
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              
              // Selector de ubicación de la iglesia
              if (_useChurchLocation) ...[
                const SizedBox(height: 8),
                if (_isLoadingChurchLocations)
                  const Center(child: CircularProgressIndicator())
                else if (_churchLocations == null || _churchLocations!.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.noChurchLocationsAvailable,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedChurchLocationId,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.churchLocation,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _churchLocations!.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? AppLocalizations.of(context)!.noName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedChurchLocationId = value;
                        
                        if (value != null) {
                          // Buscar manualmente la ubicación de la iglesia
                          DocumentSnapshot? churchLocation;
                          for (var doc in _churchLocations!) {
                            if (doc.id == value) {
                              churchLocation = doc;
                              break;
                            }
                          }
                          
                          if (churchLocation != null) {
                            _fillLocationFields(churchLocation.data() as Map<String, dynamic>);
                          }
                        }
                      });
                    },
                    validator: _useChurchLocation
                        ? (value) => value == null ? AppLocalizations.of(context)!.pleaseSelectALocation : null
                        : null,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de ubicaciones guardadas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.mySavedLocations,
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Switch para usar ubicación guardada
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.useSavedLocation),
                subtitle: Text(AppLocalizations.of(context)!.selectSavedLocation),
                value: _useSavedLocation,
                activeColor: AppColors.primary,
                onChanged: !_useChurchLocation
                    ? (bool value) {
                        setState(() {
                          _useSavedLocation = value;
                          if (!value) {
                            _selectedSavedLocationId = null;
                          }
                        });
                      }
                    : null,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              
              // Selector de ubicación guardada
              if (_useSavedLocation && !_useChurchLocation) ...[
                const SizedBox(height: 8),
                if (_isLoadingSavedLocations)
                  const Center(child: CircularProgressIndicator())
                else if (_savedLocations == null || _savedLocations!.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.noSavedLocationsAvailable,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedSavedLocationId,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.savedLocation,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _savedLocations!.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? AppLocalizations.of(context)!.noName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSavedLocationId = value;
                        
                        if (value != null) {
                          // Buscar manualmente la ubicación guardada
                          DocumentSnapshot? savedLocation;
                          for (var doc in _savedLocations!) {
                            if (doc.id == value) {
                              savedLocation = doc;
                              break;
                            }
                          }
                          
                          if (savedLocation != null) {
                            _fillLocationFields(savedLocation.data() as Map<String, dynamic>);
                          }
                        }
                      });
                    },
                    validator: _useSavedLocation && !_useChurchLocation
                        ? (value) => value == null ? AppLocalizations.of(context)!.pleaseSelectALocation : null
                        : null,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de dirección manual
        if (!_useChurchLocation && !_useSavedLocation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.eventAddress,
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Formulario de ubicación
                Column(
                  children: [
                    // Ciudad
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.cityRequired,
                        hintText: AppLocalizations.of(context)!.enterEventCity,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      validator: !_useChurchLocation && !_useSavedLocation
                          ? (value) => value == null || value.isEmpty 
                              ? AppLocalizations.of(context)!.pleaseEnterCity 
                              : null
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Estado
                    TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.stateRequired,
                        hintText: AppLocalizations.of(context)!.enterEventState,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      validator: !_useChurchLocation && !_useSavedLocation
                          ? (value) => value == null || value.isEmpty 
                              ? AppLocalizations.of(context)!.pleaseEnterState 
                              : null
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Calle
                    TextFormField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.streetRequired,
                        hintText: AppLocalizations.of(context)!.enterEventStreet,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      validator: !_useChurchLocation && !_useSavedLocation
                          ? (value) => value == null || value.isEmpty 
                              ? AppLocalizations.of(context)!.pleaseEnterStreet
                              : null
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Número y código postal
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _numberController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.numberRequired,
                              hintText: AppLocalizations.of(context)!.exampleNumber,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            validator: !_useChurchLocation && !_useSavedLocation
                                ? (value) => value == null || value.isEmpty 
                                    ? AppLocalizations.of(context)!.pleaseEnterNumber 
                                    : null
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.postalCode,
                              hintText: AppLocalizations.of(context)!.examplePostalCode,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Bairro y complemento
                    TextFormField(
                      controller: _neighborhoodController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.neighborhood,
                        hintText: AppLocalizations.of(context)!.enterNeighborhood,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _complementController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.complement,
                        hintText: AppLocalizations.of(context)!.apartmentRoomEtc,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                    ),
                    
                    // Guardar ubicación
                    const SizedBox(height: 24),
                    
                    CheckboxListTile(
                      title: Text(AppLocalizations.of(context)!.saveLocationForFutureUse),
                      value: _saveThisLocation,
                      onChanged: (value) {
                        setState(() {
                          _saveThisLocation = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    if (_saveThisLocation) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationNameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.locationNameRequired,
                          hintText: AppLocalizations.of(context)!.exampleLocationName,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        validator: _saveThisLocation 
                            ? (value) => value == null || value.isEmpty 
                                ? AppLocalizations.of(context)!.pleaseEnterLocationName 
                                : null
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CheckboxListTile(
                        title: Text(AppLocalizations.of(context)!.saveAsChurchLocationAdmin),
                        value: _saveAsChurchLocation,
                        onChanged: (value) {
                          setState(() {
                            _saveAsChurchLocation = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      ElevatedButton(
                        onPressed: _savingLocation 
                            ? null 
                            : _saveAsChurchLocation 
                                ? _saveChurchLocation 
                                : _saveLocation,
                        child: _savingLocation 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(AppLocalizations.of(context)!.saveLocation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        
        // Para eventos híbridos, añadir también formulario de URL
        if (_locationType == EventLocationType.hybrid) ...[
          const SizedBox(height: 20),
          _buildOnlineUrlSection(),
        ],
      ],
    );
  }
  
  // Sección para eventos online
  Widget _buildOnlineSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.link,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.onlineEventLink,
                style: AppTextStyles.subtitle2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // URL del evento
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.meetingUrlRequired,
              hintText: AppLocalizations.of(context)!.exampleZoomUrl,
              prefixIcon: const Icon(Icons.videocam),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            validator: (value) => value == null || value.isEmpty || !Uri.parse(value).isAbsolute
                ? AppLocalizations.of(context)!.pleaseEnterValidUrl
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // Instrucciones opcionales
          TextFormField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.accessInstructionsOptional,
              hintText: AppLocalizations.of(context)!.instructionsToJoinMeeting,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
  
  // Sección para URL online (usado por eventos híbridos)
  Widget _buildOnlineUrlSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.videocam,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.onlineOptionHybrid,
                style: AppTextStyles.subtitle2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // URL del evento
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.meetingUrlRequired,
              hintText: AppLocalizations.of(context)!.exampleZoomUrl,
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            validator: (value) => _locationType == EventLocationType.hybrid &&
                    (value == null || value.isEmpty || !Uri.parse(value).isAbsolute)
                ? AppLocalizations.of(context)!.forHybridEventsPleaseEnterValidUrl
                : null,
          ),
        ],
      ),
    );
  }
} 