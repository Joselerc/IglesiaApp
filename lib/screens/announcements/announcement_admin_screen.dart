import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../models/announcement_model.dart';
import 'create_announcement_modal.dart';
import 'edit_announcement_screen.dart';
import '../../l10n/app_localizations.dart';

class AnnouncementAdminScreen extends StatefulWidget {
  const AnnouncementAdminScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementAdminScreen> createState() => _AnnouncementAdminScreenState();
}

class _AnnouncementAdminScreenState extends State<AnnouncementAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Todos';
  final List<String> _filterOptions = ['Todos', 'Regulares', 'Cultos'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mostrar opciones de filtro
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _filterOptions.map((filter) {
              return ListTile(
                title: Text(filter),
                trailing: filter == _selectedFilter
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Eliminar anuncio
  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Confirmar eliminación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmAnnouncementDeletion),
          content: Text(AppLocalizations.of(context)!.confirmDeleteAnnouncementMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Eliminar imagen del Storage si existe
      if (announcement.imageUrl.isNotEmpty) {
        try {
          // Obtener referencia de la imagen desde la URL
          final ref = FirebaseStorage.instance.refFromURL(announcement.imageUrl);
          await ref.delete();
        } catch (e) {
          // Si hay error al eliminar la imagen, continuar con la eliminación del documento
          print('Error al eliminar imagen: $e');
        }
      }

      // Eliminar documento de Firestore
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcement.id)
          .delete();

      // Mostrar mensaje de éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.announcementDeletedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error al eliminar anuncio: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorDeletingAnnouncement(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageAnnouncements),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.active),
            Tab(text: AppLocalizations.of(context)!.inactiveExpired),
          ],
        ),
        actions: [
          // Botón de filtro
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          // Botón de crear anuncio
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CreateAnnouncementModal(),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab de anuncios activos
          _buildAnnouncementsList(true),
          // Tab de anuncios inactivos o vencidos
          _buildAnnouncementsList(false),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList(bool isActive) {
    // Construir la consulta de Firestore - sin filtros iniciales de isActive
    Query query = FirebaseFirestore.instance.collection('announcements');
    
    // Aplicar filtros por tipo
    if (_selectedFilter == 'Regulares') {
      query = query.where('type', isEqualTo: 'regular');
    } else if (_selectedFilter == 'Cultos') {
      query = query.where('type', isEqualTo: 'cult');
    }
    
    // Ordenar por fecha
    query = query.orderBy('date', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  isActive 
                      ? AppLocalizations.of(context)!.noActiveAnnouncements
                      : AppLocalizations.of(context)!.noInactiveExpiredAnnouncements,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Obtener todos los anuncios
        final allAnnouncements = snapshot.data!.docs
            .map((doc) {
              try {
                return AnnouncementModel.fromFirestore(doc);
              } catch (e) {
                print('Error al convertir documento a AnnouncementModel: $e');
                print('Documento: ${doc.data()}');
                return null;
              }
            })
            .where((announcement) => announcement != null)
            .cast<AnnouncementModel>()
            .toList();
        
        // Filtrar por fecha y estado activo en el cliente
        final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        List<AnnouncementModel> announcements;
        
        if (isActive) {
          // Pestaña Activos: mostrar solo anuncios activos y con fecha >= hoy
          announcements = allAnnouncements.where((announcement) => 
            announcement.isActive && 
            (announcement.date.isAfter(now) || isSameDay(announcement.date, now))
          ).toList();
        } else {
          // Pestaña Inactivos/Vencidos: mostrar anuncios inactivos o con fecha < hoy
          announcements = allAnnouncements.where((announcement) => 
            !announcement.isActive || 
            announcement.date.isBefore(now)
          ).toList();
        }
        
        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  isActive 
                      ? AppLocalizations.of(context)!.noActiveAnnouncements
                      : AppLocalizations.of(context)!.noInactiveExpiredAnnouncements,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Información de depuración
        print('Total anuncios encontrados en pestaña ${isActive ? "Activos" : "Inactivos"}: ${announcements.length}');
        for (var i = 0; i < announcements.length; i++) {
          final a = announcements[i];
          print('Anuncio $i: id=${a.id}, título=${a.title}, tipo=${a.type}, isActive=${a.isActive}, fecha=${a.date}');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del anuncio con tipo y fecha
                  Stack(
                    children: [
                      // Imagen
                      AspectRatio(
                        aspectRatio: 16/9,
                        child: Image.network(
                          announcement.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 50),
                            );
                          },
                        ),
                      ),
                      
                      // Etiqueta de tipo (regular o culto)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: announcement.type == 'cult' 
                                ? Colors.blue.withOpacity(0.8) 
                                : Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                announcement.type == 'cult' ? Icons.church : Icons.announcement,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                announcement.type == 'cult' ? AppLocalizations.of(context)!.cult('') : AppLocalizations.of(context)!.regular,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Fecha
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(announcement.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Contenido del anuncio
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Descripción
                        Text(
                          announcement.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Botones de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Botón de editar
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditAnnouncementScreen(
                                      announcement: announcement,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              label: Text(AppLocalizations.of(context)!.edit),
                            ),
                            const SizedBox(width: 8),
                            
                            // Botón de eliminar
                            TextButton.icon(
                              onPressed: () => _deleteAnnouncement(announcement),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 