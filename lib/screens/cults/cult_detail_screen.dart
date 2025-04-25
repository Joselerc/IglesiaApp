import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/cult.dart';
import './tabs/cult_songs_tab.dart';
import './tabs/cult_time_slots_tab.dart';
import './modals/create_cult_announcement_modal.dart';
import './modals/duplicate_cult_type_modal.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/work_schedule_service.dart';
import '../../theme/app_colors.dart';

class CultDetailScreen extends StatefulWidget {
  final Cult cult;
  
  const CultDetailScreen({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<CultDetailScreen> createState() => _CultDetailScreenState();
}

class _CultDetailScreenState extends State<CultDetailScreen> {
  Timer? _statusCheckTimer;
  bool _isPastor = false;
  
  @override
  void initState() {
    super.initState();
    // Verificar y actualizar el estado del culto al cargar la pantalla
    _checkAndUpdateCultStatus();
    
    // Configurar un temporizador para verificar el estado cada minuto
    _statusCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndUpdateCultStatus();
    });
    
    // Verificar si el usuario es pastor
    _checkPastorStatus();
  }
  
  @override
  void dispose() {
    // Cancelar el temporizador al cerrar la pantalla
    _statusCheckTimer?.cancel();
    super.dispose();
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
  
  // Muestra el modal para crear un anuncio del culto
  void _showCreateAnnouncementModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
        child: CreateCultAnnouncementModal(cult: widget.cult),
      ),
    );
  }
  
  // Verifica y actualiza automáticamente el estado del culto según la hora actual
  Future<void> _checkAndUpdateCultStatus() async {
    final now = DateTime.now();
    final cultStartTime = widget.cult.startTime;
    final cultEndTime = widget.cult.endTime;
    
    // Si el culto ya está finalizado, no hacer nada
    if (widget.cult.status == 'finalizado') {
      return;
    }
    
    // Si la hora actual es posterior a la hora de fin, marcar como finalizado
    if (now.isAfter(cultEndTime)) {
      if (widget.cult.status != 'finalizado') {
        await _updateCultStatus('finalizado', showSnackbar: false);
      }
    } 
    // Si la hora actual está entre la hora de inicio y fin, marcar como en curso
    else if (now.isAfter(cultStartTime) && now.isBefore(cultEndTime)) {
      if (widget.cult.status != 'en_curso') {
        await _updateCultStatus('en_curso', showSnackbar: false);
      }
    }
    // Si la hora actual es anterior a la hora de inicio, marcar como planificado
    else if (now.isBefore(cultStartTime)) {
      if (widget.cult.status != 'planificado') {
        await _updateCultStatus('planificado', showSnackbar: false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthService>(context).currentUser;
    final isCreator = widget.cult.createdBy.id == currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.cult.name),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (isCreator)
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.white,
                onPressed: () => _deleteEvent(context),
              ),
            if (_isPastor)
              IconButton(
                icon: const Icon(Icons.campaign),
                tooltip: 'Criar Anúncio',
                color: Colors.white,
                onPressed: _showCreateAnnouncementModal,
              ),
            if (_isPastor)
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Duplicar Culto',
                color: Colors.white,
                onPressed: _showDuplicateCultModal,
              ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Faixas Horárias'),
              Tab(text: 'Músicas'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña de Franjas Horarias
            CultTimeSlotsTab(cult: widget.cult),
            
            // Pestaña de Canciones
            CultSongsTab(cult: widget.cult),
          ],
        ),
      ),
    );
  }
  
  // Actualiza el estado del culto en Firestore
  Future<void> _updateCultStatus(String newStatus, {bool showSnackbar = true}) async {
    try {
      await FirebaseFirestore.instance
          .collection('cults')
          .doc(widget.cult.id)
          .update({'status': newStatus});
      
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado do culto atualizado para ${_getStatusText(newStatus)}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o estado: $e')),
      );
    }
  }
  
  
  // Obtiene el texto según el estado del culto
  String _getStatusText(String status) {
    switch (status) {
      case 'planificado':
        return 'Planejado';
      case 'en_curso':
        return 'Em andamento';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Planejado';
    }
  }


  void _deleteEvent(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Culto'),
        content: const Text('Tem certeza que deseja excluir este culto? Serão excluídas todas as faixas horárias, atribuições, anúncios e músicas associadas a este culto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Excluindo culto e dados relacionados...'),
          ],
        ),
      ),
    );
    
    try {
      // Eliminar el culto y todos sus datos relacionados
      await WorkScheduleService().deleteCult(widget.cult.id);
      
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Culto excluído com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      
      // Volver a la pantalla anterior
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir culto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDuplicateCultModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => DuplicateCultTypeModal(cult: widget.cult),
    );
  }
} 