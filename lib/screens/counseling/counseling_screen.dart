import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'modals/new_booking_counseling_modal.dart';
import 'pastor_availability_screen.dart';
import 'pastor_requests_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

class CounselingScreen extends StatefulWidget {
  const CounselingScreen({super.key});

  @override
  State<CounselingScreen> createState() => _CounselingScreenState();
}

class _CounselingScreenState extends State<CounselingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _cancelAppointment(String appointmentId) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelAppointment),
          content: Text(AppLocalizations.of(context)!.sureYouWantToCancelAppointment),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.yesCancelIt),
            ),
          ],
        );
      },
    );
    
    // Si el usuario no confirma, no hacer nada
    if (confirmar != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestore.collection('counseling_appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.appointmentCancelledSuccessfully),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
  
  void _showBookCounselingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const NewBookCounselingModal(),
    );
  }
  
  Widget _buildAppointmentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    final endDate = data['endDate'] != null
        ? (data['endDate'] as Timestamp).toDate()
        : date.add(Duration(minutes: data['sessionDuration'] as int? ?? 60));
    final status = data['status'] as String? ?? 'pending';
    final type = data['type'] as String? ?? 'online';
    final pastorRef = data['pastorId'] as DocumentReference;
    
    // Determinar color según el estado
    Color statusColor;
    String statusText;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = AppLocalizations.of(context)!.pending;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusText = AppLocalizations.of(context)!.confirmed;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = AppLocalizations.of(context)!.cancelled;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = AppLocalizations.of(context)!.completed;
        break;
      default:
        statusColor = Colors.grey;
        statusText = AppLocalizations.of(context)!.unknown;
    }
    
    // Verificar si la cita es en el futuro
    final isUpcoming = date.isAfter(DateTime.now());
    
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
              color: AppColors.primary.withOpacity(0.1),
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
                        DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).toString()).format(date),
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Información del pastor
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<DocumentSnapshot>(
              stream: pastorRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(AppLocalizations.of(context)!.loadingPastorInfo);
                }
                
                final pastorData = snapshot.data!.data() as Map<String, dynamic>?;
                final pastorName = pastorData?['name'] as String? ?? AppLocalizations.of(context)!.unknownPastor;
                final pastorPhone = pastorData?['phoneComplete'] as String? ?? pastorData?['phone'] as String? ?? '';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.pastor}:',
                          style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pastorName,
                          style: AppTextStyles.bodyText2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.type}:',
                          style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type == 'online' ? AppLocalizations.of(context)!.online : AppLocalizations.of(context)!.inPerson,
                          style: AppTextStyles.bodyText2,
                        ),
                      ],
                    ),
                    if (pastorPhone.isNotEmpty && status == 'confirmed') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.contact}:',
                            style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pastorPhone,
                              style: AppTextStyles.bodyText2,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.phone, color: AppColors.primary, size: 20),
                            onPressed: () async {
                              final phoneUri = Uri.parse('tel:$pastorPhone');
                              if (await canLaunchUrl(phoneUri)) {
                                await launchUrl(phoneUri);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenPhone)),
                                  );
                                }
                              }
                            },
                            tooltip: AppLocalizations.of(context)!.call,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.green, size: 20),
                            onPressed: () async {
                              String formattedPhone = pastorPhone.replaceAll(RegExp(r'[^\d+]'), '');
                              if (!formattedPhone.startsWith('+')) {
                                formattedPhone = '+$formattedPhone';
                              }
                              final whatsappUri = Uri.parse('https://wa.me/$formattedPhone');
                              if (await canLaunchUrl(whatsappUri)) {
                                await launchUrl(whatsappUri);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenWhatsApp)),
                                  );
                                }
                              }
                            },
                            tooltip: 'WhatsApp',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                    if (type == 'inPerson' && data['location'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.address}:',
                            style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['location'] as String,
                              style: AppTextStyles.bodyText2,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (data['reason'] != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${AppLocalizations.of(context)!.reason}:',
                        style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['reason'] as String,
                        style: AppTextStyles.bodyText2,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          
          // Acciones (solo para citas pendientes o confirmadas)
          if ((status == 'pending' || status == 'confirmed') && isUpcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _cancelAppointment(doc.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text(AppLocalizations.of(context)!.cancelAppointment),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Verificar y actualizar el estado de citas pasadas
  Future<void> _updatePastAppointmentsStatus(List<DocumentSnapshot> appointments) async {
    final now = DateTime.now();
    
    for (final doc in appointments) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final status = data['status'] as String? ?? 'pending';
      
      // Si la cita está confirmada pero ya pasó, actualizarla a completada
      if (status == 'confirmed' && date.isBefore(now)) {
        try {
          await _firestore.collection('counseling_appointments').doc(doc.id).update({
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Erro ao atualizar status de consulta passada: $e');
        }
      }
    }
  }
  
  // Construir la lista de citas según el filtro de estado
  Widget _buildAppointmentList(String filter) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.youAreNotLoggedIn,
          style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    
    final userRef = _firestore.collection('users').doc(userId);
    
    // Definir los estados que deben mostrarse según el filtro
    List<String> statusList = [];
    switch (filter) {
      case 'upcoming':
        statusList = ['pending', 'confirmed'];
        break;
      case 'cancelled':
        statusList = ['cancelled'];
        break;
      case 'completed':
        statusList = ['completed'];
        break;
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('counseling_appointments')
          .where('userId', isEqualTo: userRef)
          .where('status', whereIn: statusList)
          .orderBy('date', descending: filter == 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro: ${snapshot.error}',
              style: AppTextStyles.bodyText2.copyWith(color: Colors.red),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          String emptyMessage;
          switch (filter) {
            case 'upcoming':
              emptyMessage = AppLocalizations.of(context)!.youHaveNoScheduledAppointments;
              break;
            case 'cancelled':
              emptyMessage = AppLocalizations.of(context)!.youHaveNoCancelledAppointments;
              break;
            case 'completed':
              emptyMessage = AppLocalizations.of(context)!.youHaveNoCompletedAppointments;
              break;
            default:
              emptyMessage = AppLocalizations.of(context)!.noAppointmentsAvailable;
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        
        final appointments = snapshot.data!.docs;
        
        // Si estamos en el filtro de próximas citas, verificar si hay citas pasadas
        if (filter == 'upcoming') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updatePastAppointmentsStatus(appointments);
          });
        }
        
        return Stack(
          children: [
            ListView.builder(
              itemCount: appointments.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentCard(appointment);
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myAppointments),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Verificar si el usuario es pastor para mostrar botones de administración
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(_auth.currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final userRole = userData?['role'] as String? ?? '';
                
                if (userRole == 'pastor') {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PastorAvailabilityScreen(),
                            ),
                          );
                        },
                        tooltip: AppLocalizations.of(context)!.configureAvailability,
                      ),
                      // Botón Ver Solicitações con indicador de pendientes
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('counseling_appointments')
                            .where('pastorId', isEqualTo: _firestore.collection('users').doc(_auth.currentUser?.uid))
                            .where('status', isEqualTo: 'pending')
                            .limit(1) // Solo necesitamos saber si existe al menos uno
                            .snapshots(),
                        builder: (context, requestSnapshot) {
                          bool hasPendingRequests = requestSnapshot.hasData && requestSnapshot.data!.docs.isNotEmpty;
                          
                          Widget iconButton = IconButton(
                            icon: const Icon(Icons.list_alt),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PastorRequestsScreen(),
                                ),
                              );
                            },
                            tooltip: AppLocalizations.of(context)!.viewRequests,
                          );
                          
                          if (hasPendingRequests) {
                            // Envolver con Stack para mostrar el punto verde
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                iconButton,
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent, // O un verde más brillante
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Mostrar solo el botón si no hay pendientes
                            return iconButton;
                          }
                        },
                      ),
                    ],
                  );
                }
              }
              
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.8),
          labelStyle: AppTextStyles.button.copyWith(fontSize: 14),
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.upcoming),
            Tab(text: AppLocalizations.of(context)!.cancelledTab),
            Tab(text: AppLocalizations.of(context)!.completedTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('upcoming'),
          _buildAppointmentList('cancelled'),
          _buildAppointmentList('completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBookCounselingModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
} 