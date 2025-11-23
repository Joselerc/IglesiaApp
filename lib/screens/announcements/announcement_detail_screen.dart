import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/announcement_model.dart';
import '../../models/event_model.dart';
import 'package:intl/intl.dart';
import '../events/event_detail_screen.dart';
import './edit_announcement_screen.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  bool _isPastor = false;
  bool _isLoadingEvent = false;
  String? _eventTitle;
  Map<String, dynamic>? _eventData;
  bool _isDeleting = false;
  
  @override
  void initState() {
    super.initState();
    _checkPastorStatus();
    if (widget.announcement.eventId != null) {
      _loadEventDetails();
    }
  }
  
  Future<void> _checkPastorStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _isPastor = userData['role'] == 'pastor' || userData['isSuperUser'] == true; // Also check superuser
        });
      }
    }
  }
  
  Future<void> _loadEventDetails() async {
    if (widget.announcement.eventId == null) return;
    
    if (mounted) setState(() => _isLoadingEvent = true);
    
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.announcement.eventId)
          .get();
      
      if (eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _eventTitle = data['title'];
            _eventData = data;
            _isLoadingEvent = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _eventTitle = AppLocalizations.of(context)!.eventNotFound;
            _eventData = null;
            _isLoadingEvent = false;
          });
        }
      }
    } catch (e) {
      debugPrint(AppLocalizations.of(context)!.errorLoadingEventDetails(e.toString()));
      if (mounted) {
        setState(() {
          _eventTitle = AppLocalizations.of(context)!.errorLoadingEvent;
          _isLoadingEvent = false;
        });
      }
    }
  }
  
  void _navigateToEvent() async {
    if (widget.announcement.eventId == null || _eventData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.eventNotFoundOrInvalid)),
        );
      }
      return;
    }
    
    if (mounted) setState(() => _isLoadingEvent = true);
    
    try {
      final event = EventModelFromSnapshot.fromFirestoreSnapshot(
          widget.announcement.eventId!, 
          _eventData!
      );
        
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      }
    } catch (e) {
      debugPrint(AppLocalizations.of(context)!.errorNavigatingToEvent(e.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningEvent(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingEvent = false);
    }
  }
  
  void _editAnnouncement() {
    if (_isDeleting) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAnnouncementScreen(
          announcement: widget.announcement,
        ),
      ),
    ).then((didSaveChanges) {
      if (didSaveChanges == true) {
          // TODO: Reload data logic if needed, usually better to use StreamBuilder at parent
          if (widget.announcement.eventId != null) {
            _loadEventDetails();
          }
      }
    });
  }

  Future<void> _deleteAnnouncement() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.confirmDeleteAnnouncement),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);

      try {
        if (widget.announcement.imageUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(widget.announcement.imageUrl).delete();
          } catch (e) {
            debugPrint(AppLocalizations.of(context)!.errorDeletingImage(e.toString()));
          }
        }

        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(widget.announcement.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.announcementDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint(AppLocalizations.of(context)!.errorDeletingAnnouncement(e.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorDeletingAnnouncement(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCultAnnouncement = widget.announcement.type == 'cult';
    
    return Scaffold(
      backgroundColor: Colors.grey[50], // Google-style background
      extendBodyBehindAppBar: true, // Para que la imagen llegue arriba
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          if (_isPastor)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _isDeleting ? null : _editAnnouncement,
                tooltip: AppLocalizations.of(context)!.editAnnouncement,
              ),
            ),
          if (_isPastor)
            Container(
              margin: const EdgeInsets.only(right: 16),
               decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _isDeleting ? null : _deleteAnnouncement,
                tooltip: AppLocalizations.of(context)!.deleteAnnouncement,
              ),
            ),
        ],
      ),
      body: _isDeleting 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroImage(context, isCultAnnouncement),
                  
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.grey, // Placeholder bg
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Container(
                         decoration: const BoxDecoration(
                          color: Colors.white, // Actual bg
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Etiquetas / Chips
                            Row(
                              children: [
                                if (isCultAnnouncement)
                                  _buildChip(
                                    label: AppLocalizations.of(context)!.cult(''),
                                    icon: Icons.church,
                                    color: Colors.blue,
                                  ),
                                if (widget.announcement.isActive)
                                  _buildChip(
                                    label: 'Ativo',
                                    color: Colors.green,
                                    isSmall: true,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Título
                            Text(
                              widget.announcement.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Información Principal (Fecha y Ubicación)
                            _buildInfoSection(context),
                            
                            const SizedBox(height: 24),
                            const Divider(height: 1),
                            const SizedBox(height: 24),
                            
                            // Descripción
                            Text(
                              AppLocalizations.of(context)!.description,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.announcement.description,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.grey[800],
                              ),
                            ),
                            
                            // Evento vinculado
                            if (widget.announcement.eventId != null) ...[
                              const SizedBox(height: 32),
                              _buildLinkedEventCard(context),
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroImage(BuildContext context, bool isCult) {
    return Stack(
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: Image.network(
            widget.announcement.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: Icon(isCult ? Icons.church : Icons.image_not_supported, size: 80, color: Colors.grey[500]),
            ),
          ),
        ),
        // Gradiente para legibilidad de botones superiores
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip({required String label, IconData? icon, required Color color, bool isSmall = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 14 : 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoSection(BuildContext context) {
    final date = widget.announcement.type == 'cult' ? widget.announcement.date : widget.announcement.createdAt;
    final String dateLabel = widget.announcement.type == 'cult' 
        ? AppLocalizations.of(context)!.cultDate(DateFormat('dd/MM/yyyy HH:mm').format(date))
        : AppLocalizations.of(context)!.publishedOn(DateFormat('dd/MM/yyyy').format(date));
        
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_rounded, dateLabel),
          if (widget.announcement.location != null && widget.announcement.location!.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            _buildInfoRow(Icons.location_on_rounded, widget.announcement.location!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLinkedEventCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.linkedEvent,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
          ),
          color: AppColors.primary.withOpacity(0.05),
          child: InkWell(
            onTap: _isLoadingEvent ? null : _navigateToEvent,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoadingEvent
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.event, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _eventTitle ?? AppLocalizations.of(context)!.loading,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.tapToSeeDetails,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary.withOpacity(0.5)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

extension EventModelFromSnapshot on EventModel {
  static EventModel fromFirestoreSnapshot(String id, Map<String, dynamic> data) {
    final startDate = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: startDate,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? startDate,
      eventType: data['type'] ?? data['eventType'] ?? 'presential',
      createdBy: data['createdBy'],
    );
  }
}
