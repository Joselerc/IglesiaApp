import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/permission_service.dart';
import '../../l10n/app_localizations.dart';

class PastorRequestsScreen extends StatefulWidget {
  const PastorRequestsScreen({super.key});

  @override
  State<PastorRequestsScreen> createState() => _PastorRequestsScreenState();
}

class _PastorRequestsScreenState extends State<PastorRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PermissionService _permissionService = PermissionService();
  
  bool _isLoading = false;
  String _pastorId = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPastorId();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPastorId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _pastorId = user.uid;
      });
    }
  }
  
  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    // Verificar permiso antes de ejecutar la acción
    bool hasPermission = await _permissionService.hasPermission('manage_counseling_requests');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noPermissionManageCounselingRequests),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestore.collection('counseling_appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.appointmentStatus(_getStatusText(status))),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorLabel} $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
  
  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return AppLocalizations.of(context)!.appointmentConfirmed;
      case 'cancelled':
        return AppLocalizations.of(context)!.appointmentCancelled;
      case 'completed':
        return AppLocalizations.of(context)!.appointmentCompleted;
      default:
        return status;
    }
  }
  
  Widget _buildAppointmentList(String status) {
    if (_pastorId.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.loading,
          style: AppTextStyles.bodyText1,
        ),
      );
    }
    
    final pastorRef = _firestore.collection('users').doc(_pastorId);
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('counseling_appointments')
          .where('pastorId', isEqualTo: pastorRef)
          .where('status', isEqualTo: status)
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${AppLocalizations.of(context)!.errorLabel} ${snapshot.error}',
              style: AppTextStyles.bodyText1.copyWith(color: Colors.red),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  status == 'pending'
                      ? AppLocalizations.of(context)!.noPendingRequests
                      : status == 'confirmed'
                          ? AppLocalizations.of(context)!.noConfirmedAppointments
                          : AppLocalizations.of(context)!.noCompletedAppointments,
                  style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final appointments = snapshot.data!.docs;
        
        return Stack(
          children: [
            ListView.builder(
              itemCount: appointments.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final data = appointment.data() as Map<String, dynamic>;
                
                final date = (data['date'] as Timestamp).toDate();
                final endDate = data['endDate'] != null
                    ? (data['endDate'] as Timestamp).toDate()
                    : date.add(Duration(minutes: data['sessionDuration'] as int? ?? 60));
                final userRef = data['userId'] as DocumentReference;
                final type = data['type'] as String? ?? 'online';
                final reason = data['reason'] as String? ?? AppLocalizations.of(context)!.noReasonSpecified;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con fecha y hora
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type == 'online' ? Icons.video_call : Icons.person,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, d MMMM yyyy', 'pt_BR').format(date),
                                    style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${DateFormat('HH:mm').format(date)} - ${DateFormat('HH:mm').format(endDate)}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: type == 'online'
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                                child: Text(
                                type == 'online' ? AppLocalizations.of(context)!.online : AppLocalizations.of(context)!.inPerson,
                                style: AppTextStyles.caption.copyWith(
                                  color: type == 'online' ? Colors.blue : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Información del usuario
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: userRef.snapshots(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return Text(
                                    AppLocalizations.of(context)!.loadingUser,
                                    style: AppTextStyles.bodyText2,
                                  );
                                }
                                
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                final userName = userData?['name'] as String? ?? AppLocalizations.of(context)!.unknownUser;
                                final userEmail = userData?['email'] as String? ?? AppLocalizations.of(context)!.noEmail;
                                final userPhone = userData?['phoneComplete'] as String? ?? userData?['phone'] as String? ?? '';
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          userName,
                                          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          userEmail,
                                          style: AppTextStyles.bodyText2,
                                        ),
                                      ],
                                    ),
                                    if (userPhone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined, size: 18, color: AppColors.textSecondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            userPhone,
                                            style: AppTextStyles.bodyText2,
                                          ),
                                          const Spacer(),
                                          // Botones de contacto
                                          if (status == 'confirmed') ...[
                                            IconButton(
                                              icon: Icon(Icons.phone, color: AppColors.primary, size: 20),
                                              onPressed: () async {
                                                final phoneUri = Uri.parse('tel:$userPhone');
                                                if (await canLaunchUrl(phoneUri)) {
                                                  await launchUrl(phoneUri);
                                                } else {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(AppLocalizations.of(context)!.couldNotOpenPhone),
                                                        backgroundColor: Colors.red,
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              tooltip: AppLocalizations.of(context)!.callTooltip,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              icon: Icon(Icons.chat, color: Colors.green, size: 20),
                                              onPressed: () async {
                                                String formattedPhone = userPhone.replaceAll(RegExp(r'[^\d+]'), '');
                                                if (!formattedPhone.startsWith('+')) {
                                                  formattedPhone = '+$formattedPhone';
                                                }
                                                final whatsappUri = Uri.parse('https://wa.me/$formattedPhone');
                                                if (await canLaunchUrl(whatsappUri)) {
                                                  await launchUrl(whatsappUri);
                                                } else {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsApp),
                                                        backgroundColor: Colors.red,
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              tooltip: AppLocalizations.of(context)!.whatsAppTooltip,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.reasonLabel,
                              style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reason,
                              style: AppTextStyles.bodyText2,
                            ),
                          ],
                        ),
                      ),
                      
                      // Acciones
                      if (status == 'pending')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _isLoading ? null : () => _updateAppointmentStatus(appointment.id, 'cancelled'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!.reject),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isLoading ? null : () => _updateAppointmentStatus(appointment.id, 'confirmed'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!.accept),
                              ),
                            ],
                          ),
                        )
                      else if (status == 'confirmed')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _isLoading ? null : () => _updateAppointmentStatus(appointment.id, 'cancelled'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isLoading ? null : () => _updateAppointmentStatus(appointment.id, 'completed'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)!.complete),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionService.hasPermission('manage_counseling_requests'),
      builder: (context, permissionSnapshot) {
        if (permissionSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (permissionSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.counselingRequestsTitle),
              backgroundColor: AppColors.primary,
            ),
            body: Center(
              child: Text(AppLocalizations.of(context)!.errorCheckingPermission(permissionSnapshot.error.toString())),
            ),
          );
        }
        
        if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.counselingRequestsTitle),
              backgroundColor: AppColors.primary,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.accessDenied, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.noPermissionManageCounselingRequests, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.counselingRequestsTitle),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3.0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.8),
              labelStyle: AppTextStyles.button.copyWith(fontSize: 14),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.pending),
                Tab(text: AppLocalizations.of(context)!.confirmed),
                Tab(text: AppLocalizations.of(context)!.completed),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList('pending'),
              _buildAppointmentList('confirmed'),
              _buildAppointmentList('completed'),
            ],
          ),
        );
      },
    );
  }
} 