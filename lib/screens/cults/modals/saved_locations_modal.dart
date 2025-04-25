import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/saved_location.dart';

class SavedLocationsModal extends StatefulWidget {
  final Function(SavedLocation) onLocationSelected;
  final Function(String) onAddressEntered;
  
  const SavedLocationsModal({
    Key? key,
    required this.onLocationSelected,
    required this.onAddressEntered,
  }) : super(key: key);

  @override
  State<SavedLocationsModal> createState() => _SavedLocationsModalState();
}

class _SavedLocationsModalState extends State<SavedLocationsModal> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isCreatingNew = false;
  bool _saveAsDefault = false;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _saveNewLocation() async {
    if (_nameController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor complete todos los campos')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Si es la primera localización o se marca como predeterminada, actualizar las existentes
      if (_saveAsDefault) {
        final existingLocations = await FirebaseFirestore.instance
            .collection('saved_locations')
            .where('createdBy', isEqualTo: FirebaseFirestore.instance.collection('users').doc(currentUser.uid))
            .where('isDefault', isEqualTo: true)
            .get();
        
        for (final doc in existingLocations.docs) {
          await FirebaseFirestore.instance
              .collection('saved_locations')
              .doc(doc.id)
              .update({'isDefault': false});
        }
      }
      
      // Crear nueva localización
      final docRef = await FirebaseFirestore.instance.collection('saved_locations').add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'createdAt': FieldValue.serverTimestamp(),
        'isDefault': _saveAsDefault,
      });
      
      // Obtener el documento recién creado
      final doc = await docRef.get();
      final savedLocation = SavedLocation.fromFirestore(doc);
      
      if (mounted) {
        widget.onLocationSelected(savedLocation);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar localización: $e')),
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
  
  void _useAddressWithoutSaving() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese una dirección')),
      );
      return;
    }
    
    widget.onAddressEntered(_addressController.text.trim());
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localización del Culto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Mostrar localizaciones guardadas o formulario para nueva localización
          if (_isCreatingNew) ...[
            // Formulario para nueva localización
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la localización',
                border: OutlineInputBorder(),
                hintText: 'Ej: Iglesia Principal',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
                hintText: 'Ej: Calle Principal #123',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _saveAsDefault,
                  onChanged: (value) {
                    setState(() {
                      _saveAsDefault = value ?? false;
                    });
                  },
                ),
                const Text('Guardar como localización predeterminada'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCreatingNew = false;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _useAddressWithoutSaving,
                      child: const Text('Usar sin guardar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveNewLocation,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // Lista de localizaciones guardadas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('saved_locations')
                  .where('createdBy', isEqualTo: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid))
                  .orderBy('isDefault', descending: true)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Text('No hay localizaciones guardadas'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCreatingNew = true;
                            });
                          },
                          child: const Text('Crear Nueva Localización'),
                        ),
                      ],
                    ),
                  );
                }
                
                final locations = snapshot.data!.docs
                    .map((doc) => SavedLocation.fromFirestore(doc))
                    .toList();
                
                return Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final location = locations[index];
                          return ListTile(
                            title: Text(
                              location.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(location.address),
                            leading: Icon(
                              Icons.location_on,
                              color: location.isDefault ? Colors.blue : Colors.grey,
                            ),
                            trailing: location.isDefault
                                ? const Chip(
                                    label: Text('Predeterminada'),
                                    backgroundColor: Colors.blue,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : null,
                            onTap: () {
                              widget.onLocationSelected(location);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isCreatingNew = true;
                        });
                      },
                      child: const Text('Crear Nueva Localización'),
                    ),
                  ],
                );
              },
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 