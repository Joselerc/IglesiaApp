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
import '../../l10n/app_localizations.dart'; // Importación para internacionalización
import 'package:flutter/foundation.dart'; // Para debugPrint

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
          _isPastor = userData['role'] == 'pastor';
        });
      }
    }
  }
  
  Future<void> _loadEventDetails() async {
    if (widget.announcement.eventId == null) return;
    
    if (mounted) {
      setState(() {
        _isLoadingEvent = true;
      });
    }
    
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
    
    if (mounted) {
      setState(() {
        _isLoadingEvent = true;
      });
    }
    
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
      if (mounted) {
        setState(() {
          _isLoadingEvent = false;
        });
      }
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
          _reloadAnnouncementData();
        if (widget.announcement.eventId != null) {
            _loadEventDetails();
          }
      }
    });
  }

  Future<void> _reloadAnnouncementData() async {
      try {
          final doc = await FirebaseFirestore.instance
              .collection('announcements')
              .doc(widget.announcement.id)
              .get();
          if (doc.exists && mounted) {
              debugPrint(AppLocalizations.of(context)!.announcementReloaded);
          }
      } catch (e) {
          debugPrint(AppLocalizations.of(context)!.errorReloadingAnnouncement(e.toString()));
           if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(AppLocalizations.of(context)!.errorReloadingAnnouncement(e.toString()))),
               );
           }
      }
  }

  Future<void> _deleteAnnouncement() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.confirmDeleteAnnouncement),
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
      setState(() {
        _isDeleting = true;
      });

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
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCultAnnouncement = widget.announcement.type == 'cult';
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isCultAnnouncement ? AppLocalizations.of(context)!.cultAnnouncement : AppLocalizations.of(context)!.announcement,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isPastor)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _isDeleting ? null : _editAnnouncement,
              tooltip: AppLocalizations.of(context)!.editAnnouncement,
            ),
        ],
      ),
      body: Stack(
        children: [
          isCultAnnouncement 
              ? _buildCultAnnouncementDetail(context)
              : _buildRegularAnnouncementDetail(context),
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.deletingAnnouncement, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
      return Stack(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: Image.network(
              widget.announcement.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: Center(
                          child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                          ),
                      ),
                  );
              },
              errorBuilder: (context, error, stackTrace) {
                final iconData = widget.announcement.type == 'cult' ? Icons.church : Icons.image_not_supported;
                return Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: Icon(iconData, size: 100, color: Colors.grey[500]),
                );
              },
            ),
          ),
          
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Text(
              widget.announcement.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 5.0,
                    color: Colors.black87,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (_isPastor)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _isDeleting ? null : _deleteAnnouncement,
                  borderRadius: BorderRadius.circular(20),
                  onTapDown: (_) => HapticFeedback.lightImpact(), 
                  child: Tooltip(
                    message: AppLocalizations.of(context)!.deleteAnnouncement,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white.withOpacity(_isDeleting ? 0.5 : 1.0),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          if (widget.announcement.type == 'cult')
             Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                         BoxShadow(
                             color: Colors.black.withOpacity(0.2),
                             blurRadius: 3,
                             offset: const Offset(0, 1),
                         )
                     ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.church, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!.cult(''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      );
  }

  Widget _buildRegularAnnouncementDetail(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageHeader(context),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.announcement.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF333333),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          Icons.calendar_today_outlined,
                          AppLocalizations.of(context)!.publishedOn(DateFormat('dd/MM/yyyy').format(widget.announcement.createdAt))
                      ),
                      
                      if (widget.announcement.location != null && widget.announcement.location!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                         _buildInfoRow(
                             Icons.location_on_outlined,
                             widget.announcement.location!
                         ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCultAnnouncementDetail(BuildContext context) {
    final hasEventLink = widget.announcement.eventId != null;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           _buildImageHeader(context),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.announcement.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF333333),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          Icons.calendar_today_outlined,
                          AppLocalizations.of(context)!.cultDate(DateFormat('dd/MM/yyyy HH:mm').format(widget.announcement.date))
                      ),
                      
                      if (widget.announcement.location != null && widget.announcement.location!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                         _buildInfoRow(
                             Icons.location_on_outlined,
                             widget.announcement.location!
                         ),
                      ],
                    ],
                  ),
                ),
                
                if (hasEventLink) ...[
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Icon(Icons.link, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.linkedEvent,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Card(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                       side: BorderSide(color: Colors.grey[200]!)
                    ),
                    child: InkWell(
                      onTap: _isLoadingEvent ? null : _navigateToEvent,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _isLoadingEvent
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _eventTitle ?? AppLocalizations.of(context)!.loading,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        ..._buildEventDetailsWidgets(context),
                                      ],
                                    ),
                                  ),
                                   if (_eventTitle != null && _eventTitle != AppLocalizations.of(context)!.eventNotFound && _eventTitle != AppLocalizations.of(context)!.errorLoadingEvent)
                                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                      ),
                    ),
                  ),
                ] else if (widget.announcement.eventId == null && widget.announcement.type == 'cult') ...[
                   const SizedBox(height: 16),
                   Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       decoration: BoxDecoration(
                           color: Colors.orange.shade50,
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.orange.shade200),
                       ),
                       child: Row(
                           children: [
                               Icon(Icons.link_off, size: 18, color: Colors.orange.shade800),
                               const SizedBox(width: 8),
                               Expanded(
                                   child: Text(
                                       AppLocalizations.of(context)!.noEventLinkedToThisCult,
                                       style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                                   ),
                               ),
                           ],
                       ),
                   ),
                ],
              ],
            ),
          ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildEventDetailsWidgets(BuildContext context) {
    if (_eventTitle != null && _eventTitle != AppLocalizations.of(context)!.eventNotFound && _eventTitle != AppLocalizations.of(context)!.errorLoadingEvent) {
      return [
        const SizedBox(height: 4),
        Text(
            AppLocalizations.of(context)!.tapToSeeDetails,
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
            ),
        ),
      ];
    } else if (_eventTitle == AppLocalizations.of(context)!.eventNotFound || _eventTitle == AppLocalizations.of(context)!.errorLoadingEvent) {
      return [
        const SizedBox(height: 4),
        Text(
            _eventTitle!,
            style: TextStyle(
                color: Colors.red[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
            ),
        ),
      ];
    }
    return [];
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
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
