import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/private_prayer.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_colors.dart';
import 'modals/respond_prayer_modal.dart';
import 'modals/create_predefined_message_modal.dart';
import 'package:intl/intl.dart';

class PastorPrivatePrayersScreen extends StatefulWidget {
  const PastorPrivatePrayersScreen({super.key});

  @override
  State<PastorPrivatePrayersScreen> createState() => _PastorPrivatePrayersScreenState();
}

class _PastorPrivatePrayersScreenState extends State<PastorPrivatePrayersScreen> with SingleTickerProviderStateMixin {
  final PrayerService _prayerService = PrayerService();
  late TabController _tabController;
  bool _isLoading = true;
  List<PrivatePrayer> _privatePrayers = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadPrayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Actualiza los contadores cuando cambia la pestaña
  void _onTabChange() {
    if (_tabController.indexIsChanging) {
      // Actualizar los contadores sin recargar los datos
      _updateStatCounters();
    }
  }

  Future<void> _loadPrayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayers = await _prayerService.getPastorPrivatePrayers();
      final stats = await _prayerService.getPastorPrayerStats();
      
      if (mounted) {
        setState(() {
          _privatePrayers = prayers;
          _stats = stats;
          _isLoading = false;
        });
        
        // Actualizar los contadores basados en las listas filtradas para asegurar consistencia
        _updateStatCounters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Actualiza los contadores de estadísticas basado en las listas filtradas
  void _updateStatCounters() {
    final pending = _pendingPrayers.length;
    final accepted = _acceptedPrayers.length;
    final responded = _respondedPrayers.length;
    final total = _privatePrayers.length;
    
    setState(() {
      _stats = {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'responded': responded,
      };
    });
  }

  // Filtra las oraciones pendientes (no aceptadas por ningún pastor)
  List<PrivatePrayer> get _pendingPrayers => _privatePrayers
      .where((prayer) => !prayer.isAccepted)
      .toList();

  // Filtra las oraciones aceptadas por el pastor actual pero aún sin responder
  List<PrivatePrayer> get _acceptedPrayers {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];
    
    final pastorRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    
    return _privatePrayers
      .where((prayer) => prayer.isAccepted && 
                         prayer.acceptedBy != null && 
                         prayer.acceptedBy!.path == pastorRef.path && 
                         prayer.pastorResponse == null)
      .toList();
  }

  // Filtra las oraciones respondidas por el pastor actual
  List<PrivatePrayer> get _respondedPrayers {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];
    
    final pastorRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    
    return _privatePrayers
      .where((prayer) => prayer.pastorResponse != null && 
                         prayer.acceptedBy != null && 
                         prayer.acceptedBy!.path == pastorRef.path)
      .toList();
  }

  void _showRespondModal(PrivatePrayer prayer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: RespondPrayerModal(prayer: prayer),
        ),
      ),
    ).then((_) => _loadPrayers());
  }

  void _showCreatePredefinedMessageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: const CreatePredefinedMessageModal(),
        ),
      ),
    );
  }

  // Nueva función para aceptar una oración
  Future<void> _acceptPrayer(String prayerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Llamar al servicio para aceptar la oración
      final success = await _prayerService.acceptPrivatePrayer(prayerId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Solicitação de oração aceita com sucesso'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erro ao aceitar a solicitação'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        
        // Recargar las oraciones para actualizar la UI
        await _loadPrayers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aceitar a solicitação: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPrayerCard(PrivatePrayer prayer, bool isPending) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con información del usuario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: prayer.pastorResponse != null
                ? Colors.green.withOpacity(0.1)
                : prayer.isAccepted
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: prayer.userId.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Carregando...'),
                  );
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final userName = userData?['displayName'] ?? 'Usuário';
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: userData?['photoUrl'] != null
                          ? NetworkImage(userData!['photoUrl'])
                          : null,
                      child: userData?['photoUrl'] == null
                          ? Icon(Icons.person, color: Colors.grey[700])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy - HH:mm', 'pt_BR').format(prayer.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Etiqueta de estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: prayer.pastorResponse != null
                            ? Colors.green
                            : prayer.isAccepted
                                ? AppColors.primary
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        prayer.pastorResponse != null
                            ? 'Respondido'
                            : prayer.isAccepted
                                ? 'Aceito'
                                : 'Pendente',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Contenido de la oración
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solicitação:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prayer.content,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Respuesta del pastor (si existe)
                if (prayer.pastorResponse != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua resposta:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prayer.pastorResponse!,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        if (prayer.respondedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Respondido em ${DateFormat('dd MMM yyyy - HH:mm', 'pt_BR').format(prayer.respondedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Acciones
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Aceitar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _acceptPrayer(prayer.id),
                  )
                else
                  ElevatedButton.icon(
                    icon: const Icon(Icons.reply),
                    label: const Text('Responder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _showRespondModal(prayer),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon, {bool highlight = false}) {
    // Formatear el contador para números grandes
    String displayCount = count.toString();
    if (count >= 1000) {
      displayCount = '${(count / 1000).toStringAsFixed(1)}k';
    }
    
    return Expanded(
      child: Card(
        elevation: highlight ? 6 : 4,
        shadowColor: highlight ? color.withOpacity(0.5) : color.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                highlight ? color.withOpacity(0.25) : color.withOpacity(0.15),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(highlight ? 0.3 : 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: highlight ? 24 : 22),
                ),
                const SizedBox(height: 8),
                _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color.withOpacity(0.5),
                        ),
                      )
                    : Text(
                        displayCount,
                        style: TextStyle(
                          fontSize: highlight ? 24 : 22,
                          fontWeight: FontWeight.bold,
                          color: color.withOpacity(0.85),
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                    color: highlight ? color.withOpacity(0.8) : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orações Privadas'),
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
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.8),
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.watch_later_outlined),
              text: 'Pendentes',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline),
              text: 'Aceitas',
            ),
            Tab(
              icon: const Icon(Icons.chat_outlined),
              text: 'Respondidas',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: 'Criar mensagem predefinida',
            onPressed: _showCreatePredefinedMessageModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadPrayers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sección de estadísticas mejorada
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            'Visão Geral das Orações',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildStatCard(
                              'Total',
                              _stats['total'] ?? 0,
                              AppColors.primary,
                              Icons.summarize,
                            ),
                            _buildStatCard(
                              'Pendentes',
                              _stats['pending'] ?? 0,
                              Colors.orange,
                              Icons.watch_later_outlined,
                            ),
                            _buildStatCard(
                              'Aceitas',
                              _stats['accepted'] ?? 0,
                              Colors.green,
                              Icons.check_circle_outline,
                              highlight: true,
                            ),
                            _buildStatCard(
                              'Respondidas',
                              _stats['responded'] ?? 0,
                              Colors.purple,
                              Icons.chat_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Divider(),
                
                // Contenido de las pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab de pendientes
                      _pendingPrayers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Não há orações pendentes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Todas as solicitações foram atendidas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _pendingPrayers.length,
                              itemBuilder: (context, index) => _buildPrayerCard(_pendingPrayers[index], true),
                              padding: const EdgeInsets.only(bottom: 16),
                            ),
                      
                      // Tab de aceptadas
                      _acceptedPrayers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.mark_chat_unread_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Não há orações aceitas sem resposta',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aceite solicitações para responder aos irmãos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _acceptedPrayers.length,
                              itemBuilder: (context, index) => _buildPrayerCard(_acceptedPrayers[index], false),
                              padding: const EdgeInsets.only(bottom: 16),
                            ),
                      
                      // Tab de respondidas
                      _respondedPrayers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Você não respondeu a nenhuma oração',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Suas respostas aparecerão aqui',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _respondedPrayers.length,
                              itemBuilder: (context, index) => _buildPrayerCard(_respondedPrayers[index], false),
                              padding: const EdgeInsets.only(bottom: 16),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 