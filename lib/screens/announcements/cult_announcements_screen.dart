import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/announcement_model.dart';
import '../../models/cult.dart';
import './announcement_detail_screen.dart';
import './edit_announcement_screen.dart';
import '../cults/cult_detail_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CultAnnouncementsScreen extends StatefulWidget {
  const CultAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<CultAnnouncementsScreen> createState() => _CultAnnouncementsScreenState();
}

class _CultAnnouncementsScreenState extends State<CultAnnouncementsScreen> {
  bool _isPastor = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    _checkPastorStatus();
  }
  
  // Verifica si el usuario actual es un pastor
  Future<void> _checkPastorStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isPastor = userData['role'] == 'pastor';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar mejorado con diseño más atractivo
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            floating: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Anúncios de Cultos',
                style: AppTextStyles.subtitle1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.7),
                          AppColors.primary,
                        ],
                      ),
                    ),
                  ),
                  // Patrón decorativo
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_isPastor)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Criar Anúncio',
                    onPressed: () {
                      // Acción para crear un nuevo anuncio
                    },
                  ),
                ),
            ],
          ),
          
          // Contenido principal
          StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .where('type', isEqualTo: 'cult')
            .where('isActive', isEqualTo: true)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
            ))
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
            );
          }
          
          final announcements = snapshot.data!.docs
              .map((doc) => AnnouncementModel.fromFirestore(doc))
              .toList();
          
          // Filtrar los anuncios por startDate en el cliente
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final filteredAnnouncements = announcements.where((announcement) {
            // Si no tiene startDate, siempre mostrar
            if (announcement.startDate == null) return true;
            
            // Convertir startDate a medianoche para comparación de fechas
            final startDate = DateTime(
              announcement.startDate!.year,
              announcement.startDate!.month,
              announcement.startDate!.day
            );
            
            // Mostrar si startDate es hoy o anterior
            return startDate.compareTo(today) <= 0;
          }).toList();
          
          if (filteredAnnouncements.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final announcement = filteredAnnouncements[index];
                      return _buildAnnouncementCard(announcement);
                    },
                    childCount: filteredAnnouncements.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Estado vacío más atractivo
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.church,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
                  Text(
            'Nenhum anúncio disponível',
                    style: TextStyle(
                      fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Os anúncios de cultos aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isPastor) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Acción para crear un nuevo anuncio
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar novo anúncio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
                ],
              ),
            );
          }
          
  // Tarjeta de anuncio mejorada
  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final dateFormat = DateFormat('EEEE, d', 'pt_BR');
    final monthFormat = DateFormat('MMMM', 'pt_BR');
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
                shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementDetailScreen(
                          announcement: announcement,
                        ),
                      ),
                    );
                  },
                  onLongPress: _isPastor ? () => _showAnnouncementOptions(announcement) : null,
        borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Imagen del anuncio con overlay y fecha
                      Stack(
                        children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 200,
                            width: double.infinity,
                    child: announcement.imageUrl.isNotEmpty
                      ? Image.network(
                              announcement.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: AppColors.primary.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.church,
                              size: 60,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                        ),
                  ),
                ),
                
                // Overlay con gradiente
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Fecha del anuncio estilizada
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                announcement.date.day.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                monthFormat.format(announcement.date).substring(0, 3).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormat.format(announcement.date),
                                style: AppTextStyles.subtitle2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm', 'pt_BR').format(announcement.date),
                                style: AppTextStyles.subtitle1.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Etiquetas en la esquina superior
                            Positioned(
                              top: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (announcement.eventId != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                                    Text(
                                      'Evento',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.church, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                                  Text(
                                    'Culto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
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
                    style: TextStyle(
                      fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // Descripción
                            Text(
                              announcement.description,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.textSecondary,
                              ),
                    maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            // Localización
                            if (announcement.location != null && announcement.location!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                        Icon(Icons.location_on, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      announcement.location!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Información del culto asociado
                            if (announcement.cultId != null)
                              _buildCultInfo(context, announcement.cultId!),
                            
                  const SizedBox(height: 16),
                            
                            // Botón para ver detalles
                            Align(
                              alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnnouncementDetailScreen(
                                        announcement: announcement,
                                      ),
                                    ),
                                  );
                                },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Ver Detalhes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
  
  // Widget para mostrar información resumida del culto asociado
  Widget _buildCultInfo(BuildContext context, String cultId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('cults').doc(cultId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        
        final cult = Cult.fromFirestore(snapshot.data!);
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                    child: Icon(Icons.event, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cult.name,
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(cult.startTime)} - ${DateFormat('HH:mm').format(cult.endTime)}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(cult.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(cult.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(cult.status),
                      style: AppTextStyles.caption.copyWith(
                        color: _getStatusColor(cult.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Solo mostrar el botón para ver detalles del culto si el usuario es pastor
              if (_isPastor) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CultDetailScreen(cult: cult),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver Detalhes do Culto'),
                    style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  // Obtiene el color según el estado del culto
  Color _getStatusColor(String status) {
    switch (status) {
      case 'planificado':
        return Colors.blue;
      case 'en_curso':
        return Colors.green;
      case 'finalizado':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
  
  // Obtiene el texto según el estado del culto
  String _getStatusText(String status) {
    switch (status) {
      case 'planificado':
        return 'Agendado';
      case 'en_curso':
        return 'Em andamento';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Agendado';
    }
  }

  void _showAnnouncementOptions(AnnouncementModel announcement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('Editar anúncio'),
              onTap: () {
                Navigator.pop(context); // Cerrar el modal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAnnouncementScreen(
                      announcement: announcement,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text('Excluir anúncio'),
              onTap: () {
                Navigator.pop(context); // Cerrar el modal
                _confirmDeleteAnnouncement(announcement);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDeleteAnnouncement(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir anúncio'),
        content: const Text('Tem certeza que deseja excluir este anúncio? Esta ação não pode ser desfeita.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(announcement);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Primero eliminar la imagen de Firebase Storage si existe
      if (announcement.imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(announcement.imageUrl).delete();
        } catch (e) {
          // Registrar el error pero continuar con la eliminación del anuncio
          print('Error al eliminar imagen: $e');
        }
      }
      
      // Eliminar el documento del anuncio
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcement.id)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anúncio excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir anúncio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 