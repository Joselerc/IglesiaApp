import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/cult.dart';
import '../../../models/time_slot.dart';
import '../../../models/ministry.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class AssignMinistryModal extends StatefulWidget {
  final TimeSlot timeSlot;
  final Cult cult;
  
  const AssignMinistryModal({
    Key? key,
    required this.timeSlot,
    required this.cult,
  }) : super(key: key);

  @override
  State<AssignMinistryModal> createState() => _AssignMinistryModalState();
}

class _AssignMinistryModalState extends State<AssignMinistryModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tempMinistryNameController = TextEditingController();
  List<Ministry> _ministries = [];
  List<Ministry> _filteredMinistries = [];
  
  // Lista de IDs seleccionados
  List<String> _selectedMinistryIds = [];
  
  bool _isLoadingMinistries = true;
  bool _isTemporaryMinistry = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadMinistries();
    _searchController.addListener(_filterMinistries);
  }
  
  @override
  void dispose() {
    _tempMinistryNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Filtra ministerios basados en el texto de búsqueda
  void _filterMinistries() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredMinistries = _ministries;
      } else {
        _filteredMinistries = _ministries.where((ministry) {
          return ministry.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }
  
  Future<void> _loadMinistries() async {
    setState(() {
      _isLoadingMinistries = true;
    });
    
    try {
      // Cargar todos los ministerios disponibles
      final snapshot = await FirebaseFirestore.instance
          .collection('ministries')
          .get();
      
      // Verificar si ya hay asignaciones para esta franja horaria
      final assignmentsSnapshot = await FirebaseFirestore.instance
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Obtener los IDs de ministerios ya asignados
      final assignedMinistryIds = assignmentsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            if (data['isTemporary'] == true) {
              return '';  // Ignorar ministerios temporales
            }
            return data['ministryId'].toString();
          })
          .where((id) => id.isNotEmpty)
          .toSet();
      
      // Filtrar ministerios que ya están asignados
      final availableMinistries = snapshot.docs
          .map((doc) => Ministry.fromFirestore(doc))
          .where((ministry) => !assignedMinistryIds.contains(ministry.id))
          .toList();
      
      setState(() {
        _ministries = availableMinistries;
        _filteredMinistries = availableMinistries;
        _isLoadingMinistries = false;
      });
    } catch (e) {
      debugPrint('${AppLocalizations.of(context)!.errorLoadingMinistries}: $e');
      setState(() {
        _isLoadingMinistries = false;
      });
    }
  }
  
  // Método para asignar múltiples ministerios
  Future<void> _assignMinistries() async {
    if (_isLoading) return;
    
    // Si estamos en modo temporal y no hay nombre, validar
    if (_isTemporaryMinistry && _tempMinistryNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterTemporaryMinistryName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Si no estamos en modo temporal y no hay ministerios seleccionados, validar
    if (!_isTemporaryMinistry && _selectedMinistryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectAtLeastOneMinistry),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      int successCount = 0;
      List<String> assignedMinistryNames = [];
      
      if (!_isTemporaryMinistry && _selectedMinistryIds.isNotEmpty) {
        // Asignar ministerios existentes seleccionados
        for (final ministryId in _selectedMinistryIds) {
          try {
            // Verificar si ya existe en la franja horaria
            final existingSnapshot = await FirebaseFirestore.instance
                .collection('available_roles')
                .where('timeSlotId', isEqualTo: widget.timeSlot.id)
                .where('ministryId', isEqualTo: ministryId)
                .where('isActive', isEqualTo: true)
                .get();
                
            if (existingSnapshot.docs.isNotEmpty) {
              debugPrint('Ministério $ministryId já atribuído, ignorando');
              continue;
            }
            
            final ministry = _ministries.firstWhere((m) => m.id == ministryId);
            
            // Crear una asociación del ministerio a la franja horaria
            // Mantenemos los campos role, capacity y current para compatibilidad con la UI existente
            // pero marcamos isMinistryAssignment para identificar que no es un rol real
            await FirebaseFirestore.instance.collection('available_roles').add({
              'timeSlotId': widget.timeSlot.id,
              'ministryId': ministryId,
              'ministryName': ministry.name,
              'role': 'Ministerio', // Valor genérico para mantener compatibilidad
              'capacity': 0, // No hay capacidad específica
              'current': 0, // No hay asignaciones actuales
              'isMinistryAssignment': true, // Marca que es sólo una asignación de ministerio, no un rol específico
              'isTemporary': false,
              'createdAt': Timestamp.now(),
              'createdBy': FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid),
              'isActive': true
            });
            
            successCount++;
            assignedMinistryNames.add(ministry.name);
          } catch (e) {
            debugPrint('Erro ao atribuir ministério $ministryId: $e');
          }
        }
      } else if (_isTemporaryMinistry) {
        // Crear ministerio temporal
        final ministryName = _tempMinistryNameController.text.trim();
        final tempMinistryId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        
        // Crear asociación para ministerio temporal con campos para compatibilidad
        await FirebaseFirestore.instance.collection('available_roles').add({
          'timeSlotId': widget.timeSlot.id,
          'ministryId': tempMinistryId, // ID temporal usado como string
          'ministryName': ministryName,
          'role': 'Ministério', // Valor genérico para mantener compatibilidad
          'capacity': 0, // No hay capacidad específica
          'current': 0, // No hay asignaciones actuales
          'isMinistryAssignment': true, // Marca que es sólo una asignación de ministerio, no un rol específico
          'isTemporary': true,
          'createdAt': Timestamp.now(),
          'createdBy': FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid),
          'isActive': true
        });
        
        successCount = 1;
        assignedMinistryNames.add(ministryName);
      }
      
      // Notificar y cerrar el modal
      if (mounted) {
        Navigator.of(context).pop();
        
        if (successCount > 0) {
          final mensaje = successCount == 1
              ? AppLocalizations.of(context)!.ministryAssignedSuccessfully(assignedMinistryNames.first)
              : AppLocalizations.of(context)!.ministriesAssignedSuccessfully(successCount);
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensaje),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noNewMinistriesAssigned),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorAssigningMinistries}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado con título y botón de cerrar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.assignMinistries,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Descripción explicativa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.selectMinistriesForTimeSlot,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.canSelectMultipleMinistries,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchMinistry,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Opción para crear ministerio temporal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _isTemporaryMinistry,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      _isTemporaryMinistry = value ?? false;
                      if (_isTemporaryMinistry) {
                        _selectedMinistryIds = []; // Limpiar selección
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.createTemporaryMinistry,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          // Campo para nombre del ministerio temporal (si está habilitado)
          if (_isTemporaryMinistry)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _tempMinistryNameController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.temporaryMinistryName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.group_add),
                ),
              ),
            ),
          
          // Contador de seleccionados (solo si hay selecciones)
          if (!_isTemporaryMinistry && _selectedMinistryIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.ministriesSelected(_selectedMinistryIds.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          
          // Lista de ministerios
          Expanded(
            child: _isLoadingMinistries
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                : _filteredMinistries.isEmpty && !_isTemporaryMinistry
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noMinistriesAvailable,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredMinistries.length,
                        itemBuilder: (context, index) {
                          final ministry = _filteredMinistries[index];
                          final isSelected = _selectedMinistryIds.contains(ministry.id);
                          
                          return Card(
                            elevation: isSelected ? 4 : 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected 
                                    ? AppColors.primary 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _isTemporaryMinistry ? null : () {
                                setState(() {
                                  // Cambiar selección
                                  if (isSelected) {
                                    _selectedMinistryIds.remove(ministry.id);
                                  } else {
                                    _selectedMinistryIds.add(ministry.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      child: Icon(
                                        Icons.group,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ministry.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (ministry.description.isNotEmpty)
                                            Text(
                                              ministry.description,
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
                                    // Checkbox para selección múltiple
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: AppColors.primary,
                                      onChanged: _isTemporaryMinistry ? null : (value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedMinistryIds.add(ministry.id);
                                          } else {
                                            _selectedMinistryIds.remove(ministry.id);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Botón para asignar ministerios
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            child: ElevatedButton.icon(
              onPressed: (_isTemporaryMinistry && _tempMinistryNameController.text.trim().isEmpty) ||
                        (!_isTemporaryMinistry && _selectedMinistryIds.isEmpty) ||
                        _isLoading
                  ? null 
                  : _assignMinistries,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
              label: Text(
                _isLoading
                    ? AppLocalizations.of(context)!.saving
                    : _isTemporaryMinistry
                        ? AppLocalizations.of(context)!.createTemporaryMinistry
                        : AppLocalizations.of(context)!.assignSelectedMinistries,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 