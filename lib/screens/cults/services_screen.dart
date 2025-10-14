// lib/screens/cults/services_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/service.dart';
import './cults_screen.dart';
import '../../theme/app_colors.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PermissionService _permissionService = PermissionService();
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Muestra un diálogo para crear un nuevo servicio
  void _showCreateServiceDialog() {
    // Resetear los campos
    _nameController.clear();
    _descriptionController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
                  AppLocalizations.of(context)!.createNewService,
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
                  labelText: AppLocalizations.of(context)!.serviceName,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.descriptionOptional,
                  prefixIcon: const Icon(Icons.description),
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
                      child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterServiceName)),
                          );
                          return;
                        }
                        _createService();
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
                      child: Text(AppLocalizations.of(context)!.create, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // Añadir padding extra al final
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  // Crea un nuevo servicio en Firestore
  Future<void> _createService() async {
    try {
      // Verificar permisos antes de ejecutar la acción
      bool hasPermission = await _permissionService.hasPermission('manage_cults');
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionToCreateServices)),
        );
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Crear el servicio sin necesidad de una iglesia específica
      await FirebaseFirestore.instance.collection('services').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdBy': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Limpiar los campos
      _nameController.clear();
      _descriptionController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.serviceCreatedSuccessfully)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorCreatingService}: $e')),
      );
    }
  }
  
  // Muestra un diálogo para editar un servicio existente
  void _showEditServiceDialog(Service service) {
    final editNameController = TextEditingController(text: service.name);
    final editDescriptionController = TextEditingController(text: service.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editService),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: editNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Serviço',
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: editDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autocorrect: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editNameController.text.trim();
              final newDescription = editDescriptionController.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.nameCannotBeEmpty)),
                );
                return;
              }
              _updateService(service.id, newName, newDescription);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // Actualiza un servicio existente en Firestore
  Future<void> _updateService(String serviceId, String newName, String newDescription) async {
    try {
      // Verificar permisos antes de ejecutar la acción
      bool hasPermission = await _permissionService.hasPermission('manage_cults');
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionToUpdateServices)),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('services').doc(serviceId).update({
        'name': newName,
        'description': newDescription,
        // Podrías añadir un campo 'updatedAt' si quieres rastrear las modificaciones
        // 'updatedAt': FieldValue.serverTimestamp(), 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.serviceUpdatedSuccessfully)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorUpdatingService}: $e')),
      );
    }
  }
  
  // Muestra un diálogo para confirmar la eliminación de un servicio
  void _showDeleteServiceDialog(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteService),
        content: Text(AppLocalizations.of(context)!.sureDeleteServiceAndContent(service.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(service.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
  
  // Elimina un servicio y todo su contenido relacionado
  Future<void> _deleteService(String serviceId) async {
    try {
      // Verificar permisos antes de ejecutar la acción
      bool hasPermission = await _permissionService.hasPermission('manage_cults');
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPermissionToDeleteServices)),
        );
        return;
      }

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.deletingServiceAndContent),
            ],
          ),
        ),
      );
      
      // Referencia al servicio
      final serviceRef = FirebaseFirestore.instance.collection('services').doc(serviceId);
      
      // 1. Obtener todos los cultos asociados a este servicio
      final cultsSnapshot = await FirebaseFirestore.instance
          .collection('cults')
          .where('serviceId', isEqualTo: serviceRef)
          .get();
      
      // 2. Eliminar cada culto y su contenido relacionado
      for (final cultDoc in cultsSnapshot.docs) {
        final cultId = cultDoc.id;
        
        // Obtener todas las franjas horarias del culto
        final timeSlotsSnapshot = await FirebaseFirestore.instance
            .collection('time_slots')
            .where('entityId', isEqualTo: cultId)
            .where('entityType', isEqualTo: 'cult')
            .get();
        
        // Para cada franja horaria, eliminar sus asignaciones, invitaciones y roles
        for (final timeSlotDoc in timeSlotsSnapshot.docs) {
          final timeSlotId = timeSlotDoc.id;
          
          // Eliminar asignaciones
          final assignmentsSnapshot = await FirebaseFirestore.instance
              .collection('work_assignments')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .get();
          
          for (final doc in assignmentsSnapshot.docs) {
            await doc.reference.delete();
          }
          
          // Eliminar invitaciones
          final invitesSnapshot = await FirebaseFirestore.instance
              .collection('work_invites')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .get();
          
          for (final doc in invitesSnapshot.docs) {
            await doc.reference.delete();
          }
          
          // Eliminar roles disponibles
          final rolesSnapshot = await FirebaseFirestore.instance
              .collection('available_roles')
              .where('timeSlotId', isEqualTo: timeSlotId)
              .get();
          
          for (final doc in rolesSnapshot.docs) {
            await doc.reference.delete();
          }
          
          // Eliminar la franja horaria
          await timeSlotDoc.reference.delete();
        }
        
        // Eliminar canciones del culto
        final songsSnapshot = await FirebaseFirestore.instance
            .collection('cult_songs')
            .where('cultId', isEqualTo: cultId)
            .get();
        
        for (final doc in songsSnapshot.docs) {
          await doc.reference.delete();
        }
        
        // Eliminar anuncios del culto
        final announcementsSnapshot = await FirebaseFirestore.instance
            .collection('announcements')
            .where('cultId', isEqualTo: cultId)
            .where('type', isEqualTo: 'cult')
            .get();
        
        for (final doc in announcementsSnapshot.docs) {
          await doc.reference.delete();
        }
        
        // Desasignar oraciones del culto
        final prayersSnapshot = await FirebaseFirestore.instance
            .collection('prayers')
            .where('cultRef', isEqualTo: FirebaseFirestore.instance.collection('cults').doc(cultId))
            .get();
        
        for (final doc in prayersSnapshot.docs) {
          await doc.reference.update({
            'cultRef': FieldValue.delete(),
            'assignedToCultAt': FieldValue.delete(),
            'assignedToCultBy': FieldValue.delete(),
            'cultName': FieldValue.delete(),
          });
        }
        
        // Eliminar el culto
        await cultDoc.reference.delete();
      }
      
      // 3. Finalmente eliminar el servicio
      await serviceRef.delete();
      
      // Cerrar el diálogo de carga
      Navigator.pop(context);
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.serviceDeletedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // Cerrar el diálogo de carga
      Navigator.pop(context);
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.errorDeletingService}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Interfaz principal para pastores
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.services),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_cults'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text('${AppLocalizations.of(context)!.errorVerifyingPermission}: ${permissionSnapshot.error}'));
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.accessDenied, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.noPermissionToManageCults, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          
          // Contenido original cuando tiene permiso
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('services')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.noServicesAvailable),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateServiceDialog,
                        child: Text(AppLocalizations.of(context)!.createService),
                      ),
                    ],
                  ),
                );
              }
              
              final services = snapshot.data!.docs.map((doc) => Service.fromFirestore(doc)).toList();
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(Icons.edit, color: AppColors.primary.withOpacity(0.7)),
                        tooltip: 'Editar Serviço',
                        onPressed: () => _showEditServiceDialog(service),
                      ),
                      title: Text(
                        service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: service.description.isNotEmpty
                          ? Text(service.description)
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CultsScreen(service: service),
                          ),
                        );
                      },
                      onLongPress: () => _showDeleteServiceDialog(service),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _permissionService.hasPermission('manage_cults'),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return FloatingActionButton(
              onPressed: _showCreateServiceDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}