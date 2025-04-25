import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../models/cult.dart';
import './cult_detail_screen.dart';
import '../../services/work_schedule_service.dart';
import '../../theme/app_colors.dart';

class CultsScreen extends StatefulWidget {
  final Service service;
  
  const CultsScreen({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  State<CultsScreen> createState() => _CultsScreenState();
}

class _CultsScreenState extends State<CultsScreen> {
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  // Campos para ubicación
  String? _selectedLocationId;
  String _selectedLocationName = '';
  bool _showAddLocationForm = false;
  final _locationNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  bool _saveThisLocation = false;
  
  // Función auxiliar para crear TimeOfDay con valores seguros
  TimeOfDay _safeTimeOfDay(int hour, int minute) {
    // Asegurar que la hora esté en el rango 0-23
    int safeHour = hour % 24;
    // Asegurar que los minutos estén en el rango 0-59
    int safeMinute = minute % 60;
    
    return TimeOfDay(hour: safeHour, minute: safeMinute);
  }
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar de forma segura
    final now = DateTime.now();
    _startTime = TimeOfDay.fromDateTime(now);
    
    // Usar _safeTimeOfDay para la hora de fin
    _endTime = _safeTimeOfDay(now.hour + 1, now.minute);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _locationNameController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }
  
  // Muestra un diálogo para crear un nuevo culto
  void _showCreateCultDialog() {
    // Resetear valores por defecto
    _nameController.clear();
    _selectedDate = DateTime.now();
    _selectedLocationId = null;
    _selectedLocationName = '';
    _showAddLocationForm = false;
    _locationNameController.clear();
    _streetController.clear();
    _numberController.clear();
    _complementController.clear();
    _neighborhoodController.clear();
    _cityController.clear();
    _stateController.clear();
    _postalCodeController.clear();
    _countryController.clear();
    _saveThisLocation = false;
    
    // Inicializar de forma segura
    final now = DateTime.now();
    _startTime = TimeOfDay.fromDateTime(now);
    _endTime = _safeTimeOfDay(now.hour + 1, now.minute);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Criar Novo Culto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Culto',
                    prefixIcon: const Icon(Icons.church),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  onTap: () {
                    // Asegurar que cuando el usuario toca el campo, se enfoca correctamente
                    FocusScope.of(context).requestFocus();
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hora de início:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                          InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() {
                        _startTime = time;
                        if (_timeToDouble(_endTime) <= _timeToDouble(_startTime)) {
                          _endTime = _safeTimeOfDay(_startTime.hour + 1, _startTime.minute);
                        }
                      });
                    }
                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Text(_startTime.format(context)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hora de fim:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                          InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      if (_timeToDouble(time) > _timeToDouble(_startTime)) {
                        setState(() {
                          _endTime = time;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('A hora de fim deve ser posterior à hora de início')),
                        );
                      }
                    }
                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time),
                                  const SizedBox(width: 8),
                                  Text(_endTime.format(context)),
              ],
            ),
          ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Localização:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                
                // Opción para seleccionar ubicación existente
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('churchLocations')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Manejar errores
                    if (snapshot.hasError) {
                      debugPrint('Erro ao carregar localizações: ${snapshot.error}');
                      // Mostrar mensaje de error y permitir crear nueva localización
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Não foi possível carregar as localizações existentes. Você pode inserir uma nova localização abaixo.',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    
                    final locations = snapshot.data?.docs ?? [];
                    
                    // Depurar para ver si llegan datos
                    debugPrint('Localizações encontradas: ${locations.length}');
                    for (var doc in locations) {
                      final data = doc.data() as Map<String, dynamic>;
                      debugPrint('Localização: ${doc.id} - ${data['name']}');
                    }
                    
                    // Si no hay ubicaciones, mostrar mensaje y permitir crear nueva
                    if (locations.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Não há localizações salvas. Por favor, insira uma nova localização abaixo.',
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _getDropdownInitialValue(),
                          decoration: InputDecoration(
                            labelText: 'Selecionar localização existente',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            suffixIcon: const Icon(Icons.location_on),
                          ),
                          hint: const Text('Escolha uma localização'),
                          icon: const Icon(Icons.arrow_drop_down),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Informar nova localização'),
                            ),
                            ...locations.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Sem nome';
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == null || value == '') {
                                // Usuario quiere crear una nueva ubicación
                                _selectedLocationId = null;
                                _selectedLocationName = '';
                                _locationNameController.clear();
                                _streetController.clear();
                                _numberController.clear();
                                _complementController.clear();
                                _neighborhoodController.clear();
                                _cityController.clear();
                                _stateController.clear();
                                _postalCodeController.clear();
                                _countryController.clear();
                                
                                // Forzar rebuild
                                Future.microtask(() => setState(() {}));
                              } else {
                                _selectedLocationId = value;
                                
                                // Buscar ubicación seleccionada
                                if (value != null) {
                                  DocumentSnapshot? location;
                                  for (var doc in locations) {
                                    if (doc.id == value) {
                                      location = doc;
                                      break;
                                    }
                                  }
                                  
                                  if (location != null) {
                                    final data = location.data() as Map<String, dynamic>;
                                    _selectedLocationName = data['name'] ?? '';
                                    _locationNameController.text = data['name'] ?? '';
                                    _streetController.text = data['street'] ?? '';
                                    _numberController.text = data['number'] ?? '';
                                    _complementController.text = data['complement'] ?? '';
                                    _neighborhoodController.text = data['neighborhood'] ?? '';
                                    _cityController.text = data['city'] ?? '';
                                    _stateController.text = data['state'] ?? '';
                                    _postalCodeController.text = data['postalCode'] ?? '';
                                    _countryController.text = data['country'] ?? '';
                                    
                                    // Forzar rebuild
                                    Future.microtask(() => setState(() {}));
                                  }
                                }
                              }
                            });
                          },
                          isDense: false,
                          menuMaxHeight: 300,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedLocationId != null)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedLocationId = null;
                                _selectedLocationName = '';
                                _locationNameController.clear();
                                _streetController.clear();
                                _numberController.clear();
                                _complementController.clear();
                                _neighborhoodController.clear();
                                _cityController.clear();
                                _stateController.clear();
                                _postalCodeController.clear();
                                _countryController.clear();
                              });
                            },
                            icon: const Icon(Icons.add_location_alt),
                            label: const Text('Criar nova localização'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange,
                              side: const BorderSide(color: Colors.deepOrange),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
                
                // Campos de la ubicación
                if (_selectedLocationId == null) 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _locationNameController,
                        decoration: InputDecoration(
                          labelText: 'Nome do local',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: 'Rua',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _numberController,
                              decoration: InputDecoration(
                                labelText: 'Número',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _complementController,
                        decoration: InputDecoration(
                          labelText: 'Complemento',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        // Desactivar el corrector automático y sugerencias para evitar comportamientos extraños
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _neighborhoodController,
                        decoration: InputDecoration(
                          labelText: 'Bairro',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'Cidade',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: InputDecoration(
                                labelText: 'Estado',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _postalCodeController,
                              decoration: InputDecoration(
                                labelText: 'CEP',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              keyboardType: TextInputType.number,
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: 'País',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Opción para guardar la ubicación
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
                        margin: const EdgeInsets.only(bottom: 8, top: 4),
                        child: CheckboxListTile(
                          title: const Text(
                            'Salvar esta localização para uso futuro',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _saveThisLocation,
                          onChanged: (value) {
                            setState(() {
                              _saveThisLocation = value ?? false;
                            });
                          },
                          activeColor: Colors.deepOrange,
                          checkColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 24),
                
                // Botones de acción
                SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      ElevatedButton(
              onPressed: () {
                          if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira um nome para o culto')),
                  );
                            return;
                          }
                          _createCult();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Criar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // Añadir padding extra al final para asegurar que todo sea accesible cuando el teclado está activado
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Convierte TimeOfDay a un valor double para comparaciones
  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }
  
  // Guarda una nueva ubicación en Firestore
  Future<String?> _saveNewLocation() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;
      
      final docRef = await FirebaseFirestore.instance.collection('churchLocations').add({
        'name': _locationNameController.text.trim(),
        'street': _streetController.text.trim(),
        'number': _numberController.text.trim(),
        'complement': _complementController.text.trim(),
        'neighborhood': _neighborhoodController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar localização: $e')),
      );
      return null;
    }
  }
  
  // Crea un nuevo culto en Firestore
  Future<void> _createCult() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      final cultData = {
        'serviceId': FirebaseFirestore.instance.collection('services').doc(widget.service.id),
        'name': _nameController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'status': 'planificado',
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Si el usuario seleccionó una ubicación existente
      if (_selectedLocationId != null) {
        cultData['locationId'] = FirebaseFirestore.instance.collection('churchLocations').doc(_selectedLocationId);
      } 
      // Si el usuario está creando una nueva ubicación
      else if (_locationNameController.text.isNotEmpty && _streetController.text.isNotEmpty) {
        // Guardar la ubicación si se marcó la opción
        String? locationId;
        if (_saveThisLocation) {
          locationId = await _saveNewLocation();
          if (locationId != null) {
            cultData['locationId'] = FirebaseFirestore.instance.collection('churchLocations').doc(locationId);
          }
        } 
        // Si no se marcó guardar, almacenar los datos directamente
        else {
          cultData['location'] = {
            'name': _locationNameController.text.trim(),
            'street': _streetController.text.trim(),
            'number': _numberController.text.trim(),
            'complement': _complementController.text.trim(),
            'neighborhood': _neighborhoodController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'postalCode': _postalCodeController.text.trim(),
            'country': _countryController.text.trim(),
          };
        }
      }
      
      await FirebaseFirestore.instance.collection('cults').add(cultData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Culto criado com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar o culto: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final serviceRef = FirebaseFirestore.instance.collection('services').doc(widget.service.id);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Cultos - ${widget.service.name}'),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Próximos'),
              Tab(text: 'Todos'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña de cultos próximos
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cults')
                  .where('serviceId', isEqualTo: serviceRef)
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                return _buildCultsList(snapshot, 'Não há cultos próximos');
              },
            ),
            
            // Pestaña de todos los cultos
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cults')
                  .where('serviceId', isEqualTo: serviceRef)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                return _buildCultsList(snapshot, 'Não há cultos disponíveis');
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateCultDialog,
          child: const Icon(Icons.add),
          backgroundColor: AppColors.primary,
          elevation: 4,
        ),
      ),
    );
  }
  
  // Construye la lista de cultos
  Widget _buildCultsList(AsyncSnapshot<QuerySnapshot> snapshot, String emptyMessage) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ));
    }
    
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erro ao carregar os cultos: ${snapshot.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Text(emptyMessage),
      );
    }
    
    final List<Cult> cults = [];
    
    // Procesar documentos y manejar errores por documento
    for (var doc in snapshot.data!.docs) {
      try {
        cults.add(Cult.fromFirestore(doc));
      } catch (e) {
        print('Erro ao processar o culto ${doc.id}: $e');
      }
    }
    
    if (cults.isEmpty) {
      return Center(
        child: Text('Existem documentos, mas não puderam ser processados. $emptyMessage'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cults.length,
      itemBuilder: (context, index) {
        final cult = cults[index];
        final isPast = cult.date.isBefore(DateTime.now());
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            title: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: AppColors.primary.withOpacity(0.7)),
                  tooltip: 'Editar Nome',
                  onPressed: () => _showEditCultDialog(cult),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
              cult.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPast ? Colors.grey : AppColors.textPrimary,
                fontSize: 18,
              ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(cult.date),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('HH:mm').format(cult.startTime)} - ${DateFormat('HH:mm').format(cult.endTime)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(cult.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(cult.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CultDetailScreen(cult: cult),
                ),
              );
            },
            onLongPress: () => _showDeleteCultDialog(cult),
          ),
        );
      },
    );
  }
  
  // Obtiene el color según el estado del culto
  Color _getStatusColor(String status) {
    switch (status) {
      case 'planificado':
        return AppColors.primary;
      case 'en_curso':
        return AppColors.success;
      case 'finalizado':
        return AppColors.mutedGray;
      default:
        return AppColors.primary;
    }
  }
  
  // Obtiene el texto según el estado del culto
  String _getStatusText(String status) {
    switch (status) {
      case 'planificado':
        return 'Planejado';
      case 'en_curso':
        return 'Em andamento';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Planejado';
    }
  }

  // Muestra un diálogo para confirmar la eliminación de un culto
  void _showDeleteCultDialog(Cult cult) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Culto'),
        content: const Text('Tem certeza que deseja excluir este culto? Todas as faixas horárias, atribuições, anúncios e músicas associadas a este culto serão excluídos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Excluindo culto e dados relacionados...'),
          ],
        ),
      ),
    );
    
    try {
      // Eliminar el culto y todos sus datos relacionados
      await WorkScheduleService().deleteCult(cult.id);
      
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Culto excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir culto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Muestra un diálogo para editar el nombre de un culto
  void _showEditCultDialog(Cult cult) {
    final editNameController = TextEditingController(text: cult.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome do Culto'),
        content: TextFormField(
          controller: editNameController,
          decoration: const InputDecoration(
            labelText: 'Novo nome do culto',
            border: OutlineInputBorder(),
          ),
          autocorrect: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editNameController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O nome não pode ficar vazio')),
                );
                return;
              }
              _updateCultName(cult.id, newName);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Actualiza el nombre de un culto existente en Firestore
  Future<void> _updateCultName(String cultId, String newName) async {
    try {
      await FirebaseFirestore.instance.collection('cults').doc(cultId).update({
        'name': newName,
        // 'updatedAt': FieldValue.serverTimestamp(), // Opcional
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do culto atualizado com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o nome do culto: $e')),
      );
    }
  }

  String _getDropdownInitialValue() {
    if (_selectedLocationId == null) {
      return '';
    } else if (_selectedLocationId!.isEmpty) {
      return '';
    } else {
      return _selectedLocationId!;
    }
  }
}

