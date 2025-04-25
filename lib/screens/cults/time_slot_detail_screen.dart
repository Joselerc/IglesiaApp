import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/cult.dart';
import '../../models/time_slot.dart';
import './modals/assign_ministry_modal.dart';
import './modals/assign_person_modal.dart';
import './modals/attendee_selection_modal.dart';
import 'dart:async';
import '../../services/work_schedule_service.dart';
import '../../theme/app_colors.dart';

class TimeSlotDetailScreen extends StatefulWidget {
  final TimeSlot timeSlot;
  final Cult cult;
  
  const TimeSlotDetailScreen({
    Key? key,
    required this.timeSlot,
    required this.cult,
  }) : super(key: key);

  @override
  State<TimeSlotDetailScreen> createState() => _TimeSlotDetailScreenState();
}

class _TimeSlotDetailScreenState extends State<TimeSlotDetailScreen> {
  bool _isPastor = false;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  
  // Função auxiliar para criar TimeOfDay com valores seguros
  TimeOfDay _safeTimeOfDay(int hour, int minute) {
    // Garantir que a hora esteja no intervalo 0-23
    int safeHour = hour % 24;
    // Garantir que os minutos estejam no intervalo 0-59
    int safeMinute = minute % 60;
    
    return TimeOfDay(hour: safeHour, minute: safeMinute);
  }
  
  @override
  void initState() {
    super.initState();
    _checkPastorStatus();
    
    // Inicializar controladores
    _nameController = TextEditingController(text: widget.timeSlot.name);
    _descriptionController = TextEditingController(text: widget.timeSlot.description);
    
    // Usar inicialização segura
    try {
    _startTime = TimeOfDay.fromDateTime(widget.timeSlot.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.timeSlot.endTime);
    } catch (e) {
      // Em caso de erro, usar valores padrão seguros
      final now = DateTime.now();
      _startTime = _safeTimeOfDay(now.hour, now.minute);
      _endTime = _safeTimeOfDay(now.hour + 1, now.minute);
      debugPrint('⚠️ Erro ao inicializar TimeOfDay: $e');
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Verificar se o usuário atual é um pastor
  Future<void> _checkPastorStatus() async {
    try {
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
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar função de pastor: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Converter TimeOfDay para double para facilitar comparações
  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }
  
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        
        // Verificar que a hora de início não seja posterior à hora de fim
        if (_timeToDouble(_startTime) >= _timeToDouble(_endTime)) {
          // Ajustar a hora de fim para que seja pelo menos 15 minutos após a hora de início
          int newHour = _startTime.hour;
          int newMinute = _startTime.minute + 15;
          
          // Ajustar quando os minutos excedem 59
          if (newMinute >= 60) {
            newHour = (newHour + 1) % 24; // Usar módulo para garantir que esteja no intervalo 0-23
            newMinute = newMinute % 60;
          }
          
          _endTime = TimeOfDay(
            hour: newHour,
            minute: newMinute,
          );
        }
        
        // Verificar que a hora de início não seja anterior à hora de início do culto
        final cultStartTime = TimeOfDay.fromDateTime(widget.cult.startTime);
        if (_timeToDouble(_startTime) < _timeToDouble(cultStartTime)) {
          _startTime = cultStartTime;
        }
        
        // Verificar que a hora de fim não exceda a hora de fim do culto
        final cultEndTime = TimeOfDay.fromDateTime(widget.cult.endTime);
        if (_timeToDouble(_endTime) > _timeToDouble(cultEndTime)) {
          _endTime = cultEndTime;
        }
      });
    }
  }
  
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        // Verificar que a hora de fim seja posterior à hora de início
        if (_timeToDouble(picked) > _timeToDouble(_startTime)) {
          _endTime = picked;
          
          // Verificar que a hora de fim não exceda a hora de fim do culto
          final cultEndTime = TimeOfDay.fromDateTime(widget.cult.endTime);
          if (_timeToDouble(_endTime) > _timeToDouble(cultEndTime)) {
            _endTime = cultEndTime;
          }
        } else {
          // Mostrar erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A hora de fim deve ser posterior à hora de início'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }
  
  Future<void> _updateTimeSlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Converter TimeOfDay para DateTime
      final cultDate = DateTime(
        widget.cult.date.year,
        widget.cult.date.month,
        widget.cult.date.day,
      );
      
      final startTime = DateTime(
        cultDate.year,
        cultDate.month,
        cultDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endTime = DateTime(
        cultDate.year,
        cultDate.month,
        cultDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      // Verificar se o horário é válido
      if (startTime.isAfter(endTime)) {
        throw Exception('A hora de início deve ser anterior à hora de fim');
      }
      
      // Atualizar a faixa horária
      await WorkScheduleService().updateTimeSlot(
        widget.timeSlot.id,
        name: _nameController.text,
        startTime: startTime,
        endTime: endTime,
        description: _descriptionController.text,
      );
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Horário atualizado com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar horário: $e'),
            backgroundColor: AppColors.error,
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
  
  Future<void> _deleteTimeSlot() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Horário'),
        content: const Text('Tem certeza que deseja excluir este horário? Todas as atribuições associadas também serão excluídas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await WorkScheduleService().deleteTimeSlot(widget.timeSlot.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Horário excluído com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir horário: $e'),
            backgroundColor: AppColors.error,
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
  
  void _showAssignMinistryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignMinistryModal(
        timeSlot: widget.timeSlot,
        cult: widget.cult,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final startTimeStr = DateFormat('HH:mm').format(widget.timeSlot.startTime);
    final endTimeStr = DateFormat('HH:mm').format(widget.timeSlot.endTime);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Horário' : 'Detalhes do Horário'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isPastor && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() {
                _isEditing = true;
              }),
            ),
          if (_isPastor && !_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTimeSlot,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
          : _isEditing
              ? _buildEditForm()
              : _buildDetailsView(startTimeStr, endTimeStr),
    );
  }
  
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da faixa horária',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira um nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de início',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_startTime.format(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de fim',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_endTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isEditing = false;
                      
                      // Restaurar valores originais de forma segura
                      _nameController.text = widget.timeSlot.name;
                      _descriptionController.text = widget.timeSlot.description;
                      try {
                      _startTime = TimeOfDay.fromDateTime(widget.timeSlot.startTime);
                      _endTime = TimeOfDay.fromDateTime(widget.timeSlot.endTime);
                      } catch (e) {
                        // Em caso de erro, usar valores padrão seguros
                        final now = DateTime.now();
                        _startTime = _safeTimeOfDay(now.hour, now.minute);
                        _endTime = _safeTimeOfDay(now.hour + 1, now.minute);
                        debugPrint('⚠️ Erro ao converter DateTime para TimeOfDay: $e');
                      }
                    }),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateTimeSlot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsView(String startTimeStr, String endTimeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informações básicas da faixa horária
        Container(
          width: double.infinity,
          color: AppColors.primary.withOpacity(0.1),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.timeSlot.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '$startTimeStr - $endTimeStr',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (widget.timeSlot.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.timeSlot.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Aba de Atribuições
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Ministérios'),
                    Tab(text: 'Convites'),
                    Tab(text: 'Presenças'),
                  ],
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  dividerColor: Colors.transparent,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Aba de Ministérios
                      _buildMinistriesTab(),
                      
                      // Aba de Convites
                      _buildInvitationsTab(),
                      
                      // Aba de Confirmação de Presença
                      _buildConfirmationTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMinistriesTab() {
    return Column(
      children: [
        if (_isPastor)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _showAssignMinistryModal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Atribuir Ministério'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('available_roles')
                .where('timeSlotId', isEqualTo: widget.timeSlot.id)
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Não há ministérios atribuídos',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              
              // Agrupar roles por ministerio
              Map<String, List<Map<String, dynamic>>> rolesByMinistry = {};
              
              for (var doc in snapshot.data!.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final ministryId = data['ministryId'];
                  final ministryName = data['ministryName'] ?? 'Ministerio';
                  final role = data['role'] ?? 'Rol';
                  final capacity = data['capacity'] ?? 1;
                  final current = data['current'] ?? 0;
                  final isTemporary = data['isTemporary'] ?? false;
                  final isMinistryAssignment = data['isMinistryAssignment'] ?? false;
                  
                  // Convertir ministryId a string
                  String ministryKey = '';
                  if (ministryId is DocumentReference) {
                    ministryKey = ministryId.id;
                  } else if (ministryId is String) {
                    ministryKey = ministryId;
                  } else {
                    ministryKey = ministryId.toString();
                  }
                  
                  if (!rolesByMinistry.containsKey(ministryKey)) {
                    rolesByMinistry[ministryKey] = [];
                  }
                  
                  rolesByMinistry[ministryKey]!.add({
                    'id': doc.id,
                    'role': role,
                    'capacity': capacity,
                    'current': current,
                    'ministryName': ministryName,
                    'ministryId': ministryId,
                    'isTemporary': isTemporary,
                    'isMinistryAssignment': isMinistryAssignment,
                  });
                } catch (e) {
                  debugPrint('Error al procesar rol: $e');
                }
              }
              
              if (rolesByMinistry.isEmpty) {
                return const Center(
                  child: Text(
                    'Não há ministérios atribuídos',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }
              
              // Obtener invitaciones rechazadas de una sola vez para toda la vista
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('work_invites')
                    .where('timeSlotId', isEqualTo: widget.timeSlot.id)
                    .where('isActive', isEqualTo: true)
                    .where('isRejected', isEqualTo: true)
                    .get(),
                builder: (context, invitesSnapshot) {
                  // Datos de invitaciones rechazadas: userId -> {ministryId, role}
                  final Map<String, List<Map<String, String>>> rejectedInvitations = {};
                  
                  if (invitesSnapshot.hasData) {
                    debugPrint('⚠️ Procesando ${invitesSnapshot.data!.docs.length} invitaciones rechazadas');
                    
                    // Extraer todas las invitaciones rechazadas que no estén eliminadas
                    for (var doc in invitesSnapshot.data!.docs) {
                      try {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        // Verificar que la invitación no haya sido eliminada
                        if (data.containsKey('deletedAt')) {
                          debugPrint('👉 Ignorando invitación ${doc.id} porque está marcada como eliminada');
                          continue;
                        }
                        
                        // Extraer userId de forma segura
                        final dynamic userIdValue = data['userId'];
                        String userId = '';
                        
                        if (userIdValue is DocumentReference) {
                          userId = userIdValue.id;
                        } else if (userIdValue is String) {
                          userId = userIdValue;
                        } else if (userIdValue != null) {
                          userId = userIdValue.toString();
                          if (userId.contains('/')) {
                            userId = userId.split('/').last;
                          }
                        }
                        
                        if (userId.isEmpty) continue;
                        
                        // Extraer ministryId de forma segura
                        final dynamic ministryIdValue = data['ministryId'];
                        String ministryId = '';
                        
                        if (ministryIdValue is DocumentReference) {
                          ministryId = ministryIdValue.id;
                        } else if (ministryIdValue is String) {
                          ministryId = ministryIdValue;
                        } else if (ministryIdValue != null) {
                          ministryId = ministryIdValue.toString();
                          if (ministryId.contains('/')) {
                            ministryId = ministryId.split('/').last;
                          }
                        }
                        
                        if (ministryId.isEmpty) continue;
                        
                        // Extraer role
                        final String role = data['role'] as String? ?? '';
                        
                        if (role.isEmpty) continue;
                        
                        // Registrar el rechazo
                        if (!rejectedInvitations.containsKey(userId)) {
                          rejectedInvitations[userId] = [];
                        }
                        
                        rejectedInvitations[userId]!.add({
                          'ministryId': ministryId,
                          'role': role,
                          'invitationId': doc.id, // Guardar el ID para posible uso posterior
                        });
                        
                        debugPrint('✅ Rechazo registrado: Usuario $userId rechazó rol $role en ministerio $ministryId');
                      } catch (e) {
                        debugPrint('❌ Error procesando invitación: $e');
                      }
                    }
                  }
                  
                  debugPrint('Total de ${rejectedInvitations.length} usuarios con rechazos válidos');
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rolesByMinistry.length,
                    itemBuilder: (context, index) {
                      final ministryKey = rolesByMinistry.keys.elementAt(index);
                      final roles = rolesByMinistry[ministryKey]!;
                      final ministryName = roles.first['ministryName'] as String;
                      final ministryId = roles.first['ministryId'];
                      final isTemporary = roles.first['isTemporary'] as bool;
                      final isOnlyMinistryAssignment = roles.length == 1 && roles.first['isMinistryAssignment'] == true;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide.none,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            ministryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            isTemporary ? 'Ministério temporário' : 'Ministério',
                            style: TextStyle(
                              fontSize: 12,
                              color: isTemporary ? Colors.orange[800] : Colors.green[800],
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            child: Icon(
                              Icons.people,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide.none,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide.none,
                          ),
                          iconColor: Theme.of(context).primaryColor,
                          collapsedIconColor: Theme.of(context).primaryColor,
                          childrenPadding: const EdgeInsets.all(8),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          trailing: _isPastor ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.add_circle, color: AppColors.primary),
                                onPressed: () => _showAddRoleModal(
                                  ministryId: ministryId,
                                  ministryName: ministryName,
                                  isTemporary: isTemporary
                                ),
                                tooltip: 'Adicionar Função',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteMinistry(ministryId, ministryName),
                                tooltip: 'Excluir ministério',
                              ),
                            ],
                          ) : null,
                          children: [
                            // Si solo hay la asignación del ministerio sin roles reales, mostrar mensaje
                            if (isOnlyMinistryAssignment && _isPastor)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Este ministério não tem funções definidas',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showAddRoleModal(
                                        ministryId: ministryId,
                                        ministryName: ministryName,
                                        isTemporary: isTemporary
                                      ),
                                      icon: const Icon(Icons.add_circle, color: Colors.white),
                                      label: const Text('Definir Funções'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        minimumSize: const Size(0, 32),
                                        textStyle: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Lista de roles para este ministerio
                            if (!isOnlyMinistryAssignment)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: roles.length,
                                itemBuilder: (context, roleIndex) {
                                  if (roles[roleIndex]['isMinistryAssignment'] == true) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final roleData = roles[roleIndex];
                                  final roleName = roleData['role'] as String;
                                  final roleId = roleData['id'] as String;
                                  final capacity = roleData['capacity'] as int;
                                  final current = roleData['current'] as int;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[50],
                                    ),
                                    child: ExpansionTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              roleName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: current >= capacity 
                                                    ? Colors.red[100] 
                                                    : current > 0 
                                                        ? Colors.green[100] 
                                                        : Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$current/$capacity',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: current >= capacity 
                                                      ? Colors.red[900] 
                                                      : current > 0 
                                                          ? Colors.green[900] 
                                                          : Colors.grey[800],
                                                ),
                                              ),
                                          ),
                                          if (_isPastor)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Botón para editar capacidad
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                                  onPressed: () => _showEditCapacityDialog(roleId, roleName, capacity, current),
                                                  tooltip: 'Editar capacidade',
                                                ),
                                                // Botón para eliminar rol
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                  onPressed: () => _confirmDeleteRole(roleId, roleName),
                                                  tooltip: 'Excluir função',
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      collapsedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide.none,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide.none,
                                      ),
                                      iconColor: Theme.of(context).primaryColor,
                                      collapsedIconColor: Theme.of(context).primaryColor,
                                      childrenPadding: const EdgeInsets.all(8),
                                      children: [
                                        // Aquí irá la lista de personas asignadas a este rol
                                        StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                              .collection('work_assignments')
                                    .where('timeSlotId', isEqualTo: widget.timeSlot.id)
                                              .where('role', isEqualTo: roleName)
                                    .where('isActive', isEqualTo: true)
                                    .snapshots(),
                                          builder: (context, assignmentSnapshot) {
                                            if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  
                                            if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.docs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                                  'Não há pessoas designadas para esta função',
                                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    );
                                  }
                                  
                                            // Extraer ministryId del valor actual
                                            String currentMinistryId = '';
                                      if (ministryId is DocumentReference) {
                                              currentMinistryId = ministryId.id;
                                      } else if (ministryId is String) {
                                              currentMinistryId = ministryId;
                                      } else {
                                              currentMinistryId = ministryId.toString();
                                              if (currentMinistryId.contains('/')) {
                                                currentMinistryId = currentMinistryId.split('/').last;
                                              }
                                            }
                                            
                                            // Filtrar manualmente las asignaciones que coinciden con este ministryId
                                            final assignmentsForThisMinistry = assignmentSnapshot.data!.docs.where((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              
                                              // Extraer el ministryId de la asignación, independientemente de su tipo
                                              final dynamic assignmentMinistryId = data['ministryId'];
                                              String assignmentMinistryIdStr = '';
                                              
                                              if (assignmentMinistryId is DocumentReference) {
                                                assignmentMinistryIdStr = assignmentMinistryId.id;
                                              } else if (assignmentMinistryId is String) {
                                                assignmentMinistryIdStr = assignmentMinistryId;
                                              } else {
                                                assignmentMinistryIdStr = assignmentMinistryId.toString();
                                                if (assignmentMinistryIdStr.contains('/')) {
                                                  assignmentMinistryIdStr = assignmentMinistryIdStr.split('/').last;
                                                }
                                              }
                                              
                                              // Comparar IDs como cadenas
                                              return assignmentMinistryIdStr == currentMinistryId;
                                            }).toList();
                                            
                                            if (assignmentsForThisMinistry.isEmpty) {
                                              return const Center(
                                                child: Text(
                                                  'Não há pessoas designadas para esta função',
                                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                                ),
                                              );
                                            }
                                            
                                            // Construir lista de asignaciones para mostrar
                                            return ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: assignmentsForThisMinistry.length,
                                              itemBuilder: (context, userIndex) {
                                                final doc = assignmentsForThisMinistry[userIndex];
                                                final docData = doc.data() as Map<String, dynamic>;
                                                
                                                // Verificar status
                                                String status = docData['status'] as String? ?? 'pending';
                                                
                                                // Extraer userId correctamente según el tipo de documento
                                                final dynamic userIdRaw = docData['userId'];
                                                String userId = '';
                                                
                                                if (userIdRaw is DocumentReference) {
                                                  userId = userIdRaw.id;
                                                } else if (userIdRaw is String) {
                                                  userId = userIdRaw;
                                          } else {
                                                  userId = userIdRaw.toString();
                                                  if (userId.contains('/')) {
                                                    userId = userId.split('/').last;
                                                  }
                                                }
                                                
                                                // ¡IMPORTANTE! Verificar si este usuario ha rechazado esta invitación
                                                if (status != 'rejected' && 
                                                    rejectedInvitations.containsKey(userId)) {
                                                  
                                                  // Comprobar si hay un rechazo para este ministerio y rol específico
                                                  final userRejections = rejectedInvitations[userId]!;
                                                  
                                                  for (final rejection in userRejections) {
                                                    if (rejection['ministryId'] == currentMinistryId && 
                                                        rejection['role'] == roleName) {
                                                      // Hemos encontrado un rechazo para este usuario en este rol
                                                      debugPrint('✅ Mostrando usuario $userId como RECHAZADO para $roleName');
                                                      status = 'rejected';
                                                      break;
                                                    }
                                                  }
                                                }
                                                
                                                return FutureBuilder<DocumentSnapshot>(
                                                  future: FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(userId)
                                                      .get(),
                                                  builder: (context, userSnapshot) {
                                                    String userName = 'Usuario';
                                                    String photoUrl = '';
                                                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                                      userName = userData['displayName'] ?? 'Usuario';
                                                      photoUrl = userData['photoUrl'] ?? '';
                                                    }
                                                    
                                                    // Color del fondo según el estado
                                                    Color? cardColor = Colors.grey[100];
                                                    if (status == 'rejected') {
                                                      cardColor = Colors.red[50];
                                                    }
                                                    
                                                    return Card(
                                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      elevation: 0,
                                                      color: cardColor,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        side: status == 'rejected' 
                                                            ? BorderSide(color: Colors.red[300]!, width: 1)
                                                            : BorderSide.none,
                                                      ),
                                                      child: ListTile(
                                                        leading: CircleAvatar(
                                                          radius: 18,
                                                          backgroundImage: photoUrl.isNotEmpty
                                                              ? NetworkImage(photoUrl) as ImageProvider
                                                              : const AssetImage('assets/images/user_placeholder.png') as ImageProvider,
                                                          child: photoUrl.isEmpty
                                                              ? Text(
                                                                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                                                  style: const TextStyle(color: Colors.white),
                                                                )
                                                              : null,
                                                        ),
                                                        title: Text(
                                                          userName,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        subtitle: Row(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: _getStatusColor(status)[0],
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                              child: Text(
                                                                _getStatusText(status),
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: _getStatusColor(status)[1],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        trailing: _isPastor ? IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                          onPressed: () => _confirmDeleteAssignment(doc.id, userName),
                                                          tooltip: 'Excluir designação',
                                                        ) : null,
                                                        dense: true,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        
                                        // Botón para añadir personas al rol
                                        if (_isPastor && current < capacity)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                // Mostrar modal para añadir persona a este rol
                                                _showAssignPersonToRoleModal(
                                                  ministryId: ministryId,
                                                  ministryName: ministryName,
                                                  roleId: roleData['id'],
                                                  roleName: roleName,
                                                  isTemporary: isTemporary,
                                                );
                                              },
                                              icon: const Icon(Icons.person_add, color: Colors.white),
                                              label: const Text('Adicionar Pessoa'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                minimumSize: const Size(0, 32),
                                                textStyle: const TextStyle(fontSize: 13),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildInvitationsTab() {
    debugPrint('Construyendo pestaña de invitaciones para timeSlot: ${widget.timeSlot.id}');
    debugPrint('Cult ID: ${widget.cult.id}, Franja horaria: ${widget.timeSlot.startTime} - ${widget.timeSlot.endTime}');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('work_invites')
          .where('entityId', isEqualTo: widget.cult.id)
          .where('entityType', isEqualTo: 'cult')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('No hay invitaciones para esta entidad');
          return const Center(
            child: Text(
              'Nenhum convite enviado',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        debugPrint('Total de invitaciones encontradas: ${snapshot.data!.docs.length}');
        
        // Filtrar invitaciones para esta franja horaria
        final invites = snapshot.data!.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                
                // Imprimir datos para depuración
                debugPrint('Invitación ID: ${doc.id}');
                
                // Verificar si la invitación tiene timeSlotId directo
                if (data.containsKey('timeSlotId') && data['timeSlotId'] == widget.timeSlot.id) {
                  debugPrint('La invitación coincide por timeSlotId directo: ${doc.id}');
                  return doc;
                }
                
                // Verificar por coincidencia de tiempo (más flexible)
                if (data.containsKey('startTime') && data.containsKey('endTime')) {
                  final startTime = (data['startTime'] as Timestamp).toDate();
                  final endTime = (data['endTime'] as Timestamp).toDate();
                  
                  debugPrint('Comparando tiempos: Invitación ${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)} vs Franja ${DateFormat('HH:mm').format(widget.timeSlot.startTime)} - ${DateFormat('HH:mm').format(widget.timeSlot.endTime)}');
                  
                  // Comparación más flexible (solo la hora y minutos)
                  if (startTime.hour == widget.timeSlot.startTime.hour && 
                      startTime.minute == widget.timeSlot.startTime.minute &&
                      endTime.hour == widget.timeSlot.endTime.hour && 
                      endTime.minute == widget.timeSlot.endTime.minute) {
                    debugPrint('La invitación coincide por hora y minutos: ${doc.id}');
                    return doc;
                  }
                }
                
                debugPrint('La invitación no coincide con la franja horaria: ${doc.id}');
                return null;
              } catch (e) {
                debugPrint('Error al procesar invitación: $e');
                return null;
              }
            })
            .where((doc) => doc != null)
            .cast<DocumentSnapshot>()
            .toList();
        
        debugPrint('Invitaciones filtradas para esta franja: ${invites.length}');
        
        if (invites.isEmpty) {
          return const Center(
            child: Text(
              'No hay invitaciones para esta franja horaria',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index];
            final data = invite.data() as Map<String, dynamic>;
            final String inviteId = invite.id;
            
            debugPrint('Renderizando invitación: $inviteId, status: ${data['status']}, isRejected: ${data['isRejected']}');
            
            // Verificar la estructura de userId
            dynamic userId = data['userId'];
            String userIdString;
            
            if (userId is DocumentReference) {
              userIdString = userId.id;
              debugPrint('userId es DocumentReference: ${userId.id}');
            } else if (userId is String) {
              userIdString = userId;
              debugPrint('userId es String: $userId');
            } else {
              debugPrint('Tipo de userId desconocido: ${userId.runtimeType}');
              userIdString = 'desconocido';
            }
            
            // Obtener fecha de invitación
            String invitationDate = '';
            if (data.containsKey('createdAt') && data['createdAt'] != null) {
              final timestamp = data['createdAt'] as Timestamp;
              invitationDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
            }
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userIdString)
                  .get(),
              builder: (context, userSnapshot) {
                String userName = 'Usuario';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  userName = userData['displayName'] ?? userData['name'] ?? 'Usuario';
                  debugPrint('Usuario encontrado: $userName');
                } else if (userSnapshot.hasError) {
                  debugPrint('Error al obtener usuario: ${userSnapshot.error}');
                } else if (!userSnapshot.hasData) {
                  debugPrint('No se encontró el usuario con ID: $userIdString');
                }
                
                return Dismissible(
                  key: Key('invite-$inviteId'),
                  direction: _isPastor ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (!_isPastor) return false;
                    
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Invitación'),
                        content: Text('¿Estás seguro que deseas eliminar la invitación enviada a "$userName"?'),
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
                    ) ?? false;
                  },
                  onDismissed: (direction) {
                    _deleteInvite(inviteId, userName);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: data['status'] == 'rejected' || data['isRejected'] == true ? Colors.red[50] : null,
                    child: ListTile(
                      title: Text(userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['ministryName'] ?? 'Ministerio'} - ${data['role'] ?? 'Rol'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (invitationDate.isNotEmpty)
                            Text(
                              'Invitado el $invitationDate',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusChip(data['status'] ?? 'pending'),
                          if (_isPastor)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _confirmDeleteInvite(inviteId, userName),
                              tooltip: 'Eliminar invitación',
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'accepted':
      case 'confirmed':
        color = Colors.green;
        label = 'Aceito';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Recusado';
        break;
      case 'seen':
        color = Colors.orange;
        label = 'Visto';
        break;
      case 'pending':
      default:
        color = Colors.amber;
        label = 'Pendente';
        break;
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color == Colors.amber ? Colors.black : Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // Método para confirmar la eliminación de un ministerio
  Future<void> _confirmDeleteMinistry(dynamic ministryId, String ministryName) async {
    debugPrint('Iniciando eliminación del ministerio: $ministryId con nombre: $ministryName');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ministerio'),
        content: Text('¿Estás seguro que deseas eliminar el ministerio "$ministryName" de esta franja horaria? Se eliminarán todas las asignaciones asociadas.'),
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
    ) ?? false;
    
    if (!confirm) {
      debugPrint('Eliminación cancelada por el usuario');
      return;
    }
    
    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Eliminando ministerio...'),
            ],
          ),
        ),
      );
      
      // Normalizar ID - asumiendo que un método _normalizeId está disponible en este archivo
      // Si no está disponible, deberás añadirlo
      final String ministryIdStr = _normalizeId(ministryId);
      debugPrint('Eliminando ministerio con ID normalizado: $ministryIdStr');
      
      // Eliminar asignaciones de trabajo
      await WorkScheduleService().deleteWorkAssignmentsByMinistry(
        timeSlotId: widget.timeSlot.id,
        ministryId: ministryIdStr,
      );
      
      // Eliminar todas las invitaciones para este ministerio
      await WorkScheduleService().deleteInvitationsForMinistryAndRole(
        timeSlotId: widget.timeSlot.id,
        ministryId: ministryIdStr,
      );
      
      debugPrint('Ministerio eliminado exitosamente');
      
      // Cerrar diálogo de carga y mostrar mensaje de éxito
      if (!mounted) return;
      
      Navigator.pop(context); // Cerrar diálogo de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ministerio "$ministryName" eliminado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Actualizar el estado para reflejar los cambios
      setState(() {});
      
    } catch (e) {
      debugPrint('Error al eliminar ministerio: $e');
      
      // Cerrar diálogo de carga y mostrar error
      if (!mounted) return;
      
      Navigator.pop(context); // Cerrar diálogo de carga
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar ministerio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Método auxiliar para normalizar IDs, independientemente del tipo
  String _normalizeId(dynamic id) {
    if (id == null) return '';
    
    if (id is DocumentReference) {
      return id.id;
    } else if (id is String && id.contains('/')) {
      return id.split('/').last;
    } else {
      // Último recurso: convertir a string y ver si tiene formato de ruta
      final str = id.toString();
      if (str.contains('/')) {
        return str.split('/').last;
      }
      return str;
    }
  }

  // Método para confirmar la eliminación de una asignación
  Future<void> _confirmDeleteAssignment(String assignmentId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Asignación'),
        content: Text('¿Estás seguro que deseas eliminar la asignación de "$userName"?'),
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
    ) ?? false;
    
    if (!confirm) return;
    
    await _deleteAssignment(assignmentId, userName);
  }
  
  // Método para eliminar una asignación
  Future<void> _deleteAssignment(String assignmentId, String userName) async {
    try {
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
              Text('Eliminando asignación...'),
            ],
          ),
        ),
      );
      
      // Eliminar la asignación
      await WorkScheduleService().deleteWorkAssignment(assignmentId);
      
      // Cerrar diálogo de carga y mostrar mensaje de éxito
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asignación de "$userName" eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga y mostrar error
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar asignación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para confirmar la eliminación de una invitación
  Future<void> _confirmDeleteInvite(String inviteId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Invitación'),
        content: Text('¿Estás seguro que deseas eliminar la invitación para "$userName"?'),
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
    ) ?? false;
    
    if (confirm) {
      _deleteInvite(inviteId, userName);
    }
  }
  
  Future<void> _deleteInvite(String inviteId, String userName) async {
    try {
      // Marcar la invitación como inactiva
      await FirebaseFirestore.instance
          .collection('work_invites')
          .doc(inviteId)
          .update({
            'isActive': false,
            'deletedAt': Timestamp.now(),
            'deletedBy': FirebaseAuth.instance.currentUser?.uid,
          });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación para "$userName" eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error al eliminar invitación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar invitación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para mostrar diálogo de edición de capacidad
  Future<void> _showEditCapacityDialog(String roleId, String roleName, int currentCapacity, int currentAssigned) async {
    final TextEditingController capacityController = TextEditingController(text: currentCapacity.toString());
    
    // Mostrar diálogo con campo para editar capacidad
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar capacidad para "$roleName"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacidad',
                border: OutlineInputBorder(),
                helperText: 'Número máximo de personas para este rol',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Personas asignadas actualmente: $currentAssigned',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final newCapacity = int.tryParse(capacityController.text.trim());
              
              if (newCapacity == null || newCapacity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un número válido mayor a cero'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (newCapacity < currentAssigned) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La capacidad no puede ser menor que el número de personas asignadas'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context, newCapacity);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    // Si se obtuvo un resultado válido, actualizar la capacidad
    if (result != null && result != currentCapacity) {
      try {
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
                Text('Actualizando capacidad...'),
              ],
            ),
          ),
        );
        
        // Actualizar el documento en Firestore
        await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .update({
              'capacity': result,
            });
        
        // Cerrar diálogo de carga y mostrar mensaje de éxito
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Capacidad del rol "$roleName" actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Cerrar diálogo de carga y mostrar error
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar capacidad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // Método para confirmar eliminación de un rol
  Future<void> _confirmDeleteRole(String roleId, String roleName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rol'),
        content: Text('¿Estás seguro que deseas eliminar el rol "$roleName"? Se eliminarán todas las asignaciones asociadas.'),
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
    ) ?? false;
    
    if (!confirm) return;
    
    _deleteRole(roleId, roleName);
  }
  
  // Método para eliminar un rol
  Future<void> _deleteRole(String roleId, String roleName) async {
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
            Text('Eliminando rol...'),
          ],
        ),
      ),
    );
    
    try {
      // Variable para guardar la información del rol
      String? ministryId;
      
      try {
        // Obtener el rol para conseguir el ministryId
        final roleDoc = await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .get();
        
        if (!roleDoc.exists) {
          throw Exception('El rol no existe');
        }
        
        final roleData = roleDoc.data()!;
        
        // Extraer ministryId de manera segura
        final dynamic ministryIdRaw = roleData['ministryId'];
        if (ministryIdRaw is DocumentReference) {
          ministryId = ministryIdRaw.id;
        } else if (ministryIdRaw is String) {
          ministryId = ministryIdRaw.contains('/') 
              ? ministryIdRaw.split('/').last 
              : ministryIdRaw;
        } else if (ministryIdRaw != null) {
          ministryId = ministryIdRaw.toString();
        }
        
        if (ministryId == null || ministryId.isEmpty) {
          throw Exception('No se pudo determinar el ID del ministerio');
        }
        
        debugPrint('Eliminando rol: $roleName (ID: $roleId) del ministerio: $ministryId');
      } catch (e) {
        debugPrint('Error al obtener información del rol: $e');
        // Si falla la obtención de información, intentamos la eliminación de todas formas
        // con la información mínima que tenemos
      }
      
      // Marcar el rol como inactivo - primera operación crítica
      try {
        await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .update({
              'isActive': false,
              'deletedAt': Timestamp.now(),
            });
        debugPrint('Rol marcado como inactivo correctamente');
      } catch (e) {
        debugPrint('Error al marcar rol como inactivo: $e');
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar rol: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return; // Detener si esta operación falla
      }
      
      // Proceder solo si tenemos el ministryId
      if (ministryId != null) {
        try {
          // Buscar todas las asignaciones con este rol y ministerio
          final assignmentsSnapshot = await FirebaseFirestore.instance
              .collection('work_assignments')
              .where('timeSlotId', isEqualTo: widget.timeSlot.id)
              .where('role', isEqualTo: roleName)
              .where('isActive', isEqualTo: true)
              .get();
          
          debugPrint('Encontradas ${assignmentsSnapshot.docs.length} asignaciones a eliminar');
          
          if (assignmentsSnapshot.docs.isNotEmpty) {
            // Eliminar todas las asignaciones
            final batch = FirebaseFirestore.instance.batch();
            for (var doc in assignmentsSnapshot.docs) {
              batch.update(doc.reference, {
                'isActive': false,
                'status': 'cancelled',
                'deletedAt': Timestamp.now(),
              });
            }
            
            try {
              await batch.commit();
              debugPrint('Asignaciones eliminadas correctamente');
            } catch (e) {
              debugPrint('Error al eliminar asignaciones: $e');
              // Continuamos incluso si esta operación falla
            }
          }
          
          // Eliminar invitaciones - se maneja internamente los errores
          try {
            await WorkScheduleService().deleteInvitationsForMinistryAndRole(
              timeSlotId: widget.timeSlot.id,
              ministryId: ministryId,
            );
            debugPrint('Invitaciones eliminadas correctamente');
          } catch (e) {
            debugPrint('Error al eliminar invitaciones: $e');
            // Continuamos incluso si esta operación falla
          }
        } catch (e) {
          debugPrint('Error en operaciones secundarias de eliminación: $e');
          // Continuamos porque ya marcamos el rol como inactivo
        }
      }
      
      // Cerrar diálogo de carga y mostrar mensaje de éxito
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol "$roleName" eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Manejo global de errores
      debugPrint('Error global en eliminación de rol: $e');
      
      // Cerrar diálogo de carga y mostrar error
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Método para mostrar modal de asignar persona a un rol específico
  void _showAssignPersonToRoleModal({
    required dynamic ministryId,
    required String ministryName,
    required String roleId,
    required String roleName,
    required bool isTemporary,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignPersonModal(
        timeSlot: widget.timeSlot,
        cult: widget.cult,
        ministryId: ministryId,
        ministryName: ministryName,
        isTemporary: isTemporary,
        predefinedRole: roleName,
        roleId: roleId,
      ),
    );
  }
  
  // Método para mostrar modal de añadir nuevo rol
  void _showAddRoleModal({
    required dynamic ministryId,
    required String ministryName,
    required bool isTemporary,
  }) {
    final TextEditingController roleController = TextEditingController();
    final TextEditingController capacityController = TextEditingController(text: '1');
    
    // Lista para almacenar roles predefinidos que se cargarán desde Firestore
    List<String> predefinedRoles = [];
    bool isLoading = true;
    String? selectedPredefinedRole;
    bool saveAsPredefined = true; // Variable para controlar si se guarda como predefinido
    
    // Cargar roles predefinidos basados en los que ya se han usado
    Future<List<String>> loadPredefinedRoles() async {
      try {
        // Buscar roles existentes en la base de datos para mostrarlos como sugerencias
        final rolesSnapshot = await FirebaseFirestore.instance
            .collection('available_roles')
            .where('isActive', isEqualTo: true)
            .where('isPredefined', isEqualTo: true) // Solo cargar roles predefinidos
            .get();
            
        // Extraer nombres de roles únicos
        final Set<String> uniqueRoles = {};
        for (var doc in rolesSnapshot.docs) {
          final data = doc.data();
          if (data.containsKey('role') && data['role'] != null && data['role'] != 'Ministerio') {
            uniqueRoles.add(data['role'] as String);
          }
        }
        
        return uniqueRoles.toList()..sort(); // Devolver lista ordenada alfabéticamente
      } catch (e) {
        debugPrint('Error al cargar roles predefinidos: $e');
        return [];
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        // StatefulBuilder permite actualizar el estado dentro del modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Cargar roles predefinidos al abrir el modal
            if (isLoading) {
              loadPredefinedRoles().then((roles) {
                setModalState(() {
                  predefinedRoles = roles;
                  isLoading = false;
                });
              });
            }
            
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Adicionar Nova Função em $ministryName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      
                      // Selector de roles predefinidos
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (predefinedRoles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selecione um papel predefinido:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedPredefinedRole,
                                    hint: const Text('Selecionar papel existente'),
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    items: predefinedRoles.map((role) {
                                      return DropdownMenuItem<String>(
                                        value: role,
                                        child: Text(role),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedPredefinedRole = value;
                                        if (value != null) {
                                          // Actualizar el campo de texto con el rol seleccionado
                                          roleController.text = value;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Ou crie um novo papel:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Campo para nombre del rol
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: roleController,
                          decoration: InputDecoration(
                            labelText: 'Nome do Papel',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.badge),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      
                      // Campo para capacidad
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Capacidade',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: capacityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Número de pessoas para este papel',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.people),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Opción para guardar el rol como predefinido
                      CheckboxListTile(
                        title: const Text(
                          'Salvar como papel predefinido',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Se desativar esta opção, o papel só será criado para este ministério e não aparecerá na lista de papéis predefinidos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        value: saveAsPredefined,
                        activeColor: Colors.deepPurple,
                        onChanged: (value) {
                          setModalState(() {
                            saveAsPredefined = value ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      // Botón para crear rol - sin spacer para evitar problemas con el teclado
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final roleName = roleController.text.trim();
                              final capacity = int.tryParse(capacityController.text.trim()) ?? 1;
                              
                              if (roleName.isEmpty) {
                                ScaffoldMessenger.of(modalContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor, insira um nome para o papel'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              if (capacity < 1) {
                                ScaffoldMessenger.of(modalContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('A capacidade deve ser pelo menos 1'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Guardar el rol
                              try {
                                await FirebaseFirestore.instance.collection('available_roles').add({
                                  'timeSlotId': widget.timeSlot.id,
                                  'ministryId': ministryId,
                                  'ministryName': ministryName,
                                  'role': roleName,
                                  'capacity': capacity,
                                  'current': 0,
                                  'isTemporary': isTemporary,
                                  'createdAt': Timestamp.now(),
                                  'isActive': true,
                                  'isPredefined': saveAsPredefined, // Nuevo campo para indicar si es un rol predefinido
                                });
                                
                                if (mounted) {
                                  Navigator.pop(context);
                                 
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Papel "$roleName" criado com sucesso'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(modalContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao criar papel: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Criar Papel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Método auxiliar para obtener colores según el estado
  List<Color> _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'accepted':
        return [Colors.green[100]!, Colors.green[900]!];
      case 'rejected':
        return [Colors.red[100]!, Colors.red[900]!];
      case 'seen':
        return [Colors.orange[100]!, Colors.orange[900]!];
      case 'not_attended':
        return [Colors.red[50]!, Colors.red[700]!];
      case 'pending':
      default:
        return [Colors.amber[100]!, Colors.amber[900]!];
    }
  }
  
  // Método auxiliar para obtener texto según el estado
  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'accepted':
        return 'Aceito';
      case 'rejected':
        return 'Recusado';
      case 'seen':
        return 'Visto';
      case 'not_attended':
        return 'Não compareceu';
      case 'pending':
      default:
        return 'Pendente';
    }
  }

  // Nueva pestaña de confirmación de asistencia
  Widget _buildConfirmationTab() {
    // Primero, cargamos todos los roles disponibles
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('available_roles')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, rolesSnapshot) {
        if (rolesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!rolesSnapshot.hasData || rolesSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Não há papéis definidos para esta faixa horária',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Luego cargamos las asignaciones existentes
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('work_assignments')
              .where('timeSlotId', isEqualTo: widget.timeSlot.id)
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, assignmentsSnapshot) {
            Map<String, Map<String, dynamic>> rolesByMinistry = {};
            Map<String, Map<String, List<DocumentSnapshot>>> assignmentsByRoleAndMinistry = {};
            
            // Variables para contar estadísticas globales
            int totalAssignments = 0;
            int totalConfirmed = 0;
            int totalNotAttended = 0;
            int totalPending = 0;
            
            // Organizar todos los roles disponibles
            for (var doc in rolesSnapshot.data!.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                // Ignorar la asignación del ministerio mismo (no es un rol real)
                if (data['isMinistryAssignment'] == true) continue;
                
                final dynamic ministryIdValue = data['ministryId'];
                final String role = data['role'] ?? 'Sem papel';
                final int capacity = data['capacity'] ?? 1;
                final int current = data['current'] ?? 0;
                
                String ministryId = _normalizeId(ministryIdValue);
                String ministryName = data['ministryName'] ?? 'Ministério';
                
                // Inicializar estructura para el ministerio si no existe
                if (!rolesByMinistry.containsKey(ministryId)) {
                  rolesByMinistry[ministryId] = {
                    'ministryName': ministryName,
                    'roles': <String, Map<String, dynamic>>{},
                  };
                }
                
                // Guardar información del rol
                final roles = rolesByMinistry[ministryId]!['roles'] as Map<String, Map<String, dynamic>>;
                roles[role] = {
                  'roleId': doc.id,
                  'capacity': capacity,
                  'current': current,
                  'assignments': <DocumentSnapshot>[],
                };
                
                // Inicializar estructura para asignaciones
                if (!assignmentsByRoleAndMinistry.containsKey(ministryId)) {
                  assignmentsByRoleAndMinistry[ministryId] = {};
                }
                if (!assignmentsByRoleAndMinistry[ministryId]!.containsKey(role)) {
                  assignmentsByRoleAndMinistry[ministryId]![role] = [];
                }
              } catch (e) {
                debugPrint('Erro ao processar papel: $e');
              }
            }
            
            // Organizar asignaciones por ministerio y rol
            if (assignmentsSnapshot.hasData && assignmentsSnapshot.data!.docs.isNotEmpty) {
              totalAssignments = assignmentsSnapshot.data!.docs.length;
              
              for (var doc in assignmentsSnapshot.data!.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final dynamic ministryIdValue = data['ministryId'];
                  final String role = data['role'] ?? 'Sem papel';
                  
                  // Contabilizar estadísticas globales
                  if (data['isAttendanceConfirmed'] == true) {
                    totalConfirmed++;
                  } else if (data['didNotAttend'] == true) {
                    totalNotAttended++;
                  } else {
                    totalPending++;
                  }
                  
                  String ministryId = _normalizeId(ministryIdValue);
                  
                  // Si el ministerio y rol existen en nuestras estructuras, agregar la asignación
                  if (assignmentsByRoleAndMinistry.containsKey(ministryId) && 
                      assignmentsByRoleAndMinistry[ministryId]!.containsKey(role)) {
                    assignmentsByRoleAndMinistry[ministryId]![role]!.add(doc);
                    
                    // Agregar la asignación también a la estructura de roles
                    if (rolesByMinistry.containsKey(ministryId) &&
                        (rolesByMinistry[ministryId]!['roles'] as Map<String, Map<String, dynamic>>).containsKey(role)) {
                      final roleData = (rolesByMinistry[ministryId]!['roles'] as Map<String, Map<String, dynamic>>)[role]!;
                      final assignments = roleData['assignments'] as List<DocumentSnapshot>;
                      assignments.add(doc);
                    }
                  }
                } catch (e) {
                  debugPrint('Erro ao processar atribuição: $e');
                }
              }
            }
            
            if (rolesByMinistry.isEmpty) {
              return const Center(
                child: Text(
                  'Não há papéis definidos para esta faixa horária',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            
            return Column(
              children: [
                // Tarjeta de resumen de estadísticas
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo de Presença',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatCard(
                              'Confirmados', 
                              totalConfirmed, 
                              totalAssignments, 
                              Colors.green,
                              Icons.check_circle,
                            ),
                            _buildStatCard(
                              'Ausentes', 
                              totalNotAttended, 
                              totalAssignments, 
                              Colors.red,
                              Icons.cancel,
                            ),
                            _buildStatCard(
                              'Pendentes', 
                              totalPending, 
                              totalAssignments, 
                              Colors.amber,
                              Icons.hourglass_empty,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lista de ministerios y roles
                Expanded(
                  child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rolesByMinistry.length,
              itemBuilder: (context, index) {
                final ministryId = rolesByMinistry.keys.elementAt(index);
                final ministryData = rolesByMinistry[ministryId]!;
                final ministryName = ministryData['ministryName'] as String;
                final roles = ministryData['roles'] as Map<String, Map<String, dynamic>>;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(
                      ministryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.people,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    iconColor: Theme.of(context).primaryColor,
                    collapsedIconColor: Theme.of(context).primaryColor,
                    childrenPadding: const EdgeInsets.all(8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    initiallyExpanded: true,
                    children: roles.entries.map((roleEntry) {
                      final roleName = roleEntry.key;
                      final roleData = roleEntry.value;
                      final String roleId = roleData['roleId'] as String;
                      final int capacity = roleData['capacity'] as int;
                      final assignments = roleData['assignments'] as List<DocumentSnapshot>;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado del rol con capacidad y botón de añadir
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Papel: $roleName',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const SizedBox(height: 4),
                                      // Usar Wrap en vez de Row para evitar overflow
                                      Wrap(
                                        spacing: 8, // Espacio entre chips
                                        runSpacing: 4, // Espacio entre filas de chips
                                        children: [
                                      Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: assignments.length >= capacity 
                                              ? Colors.amber[100] 
                                              : Colors.green[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Confirmados: ${assignments.where((a) => (a.data() as Map<String, dynamic>)['isAttendanceConfirmed'] == true).length}/${capacity}',
                                          style: TextStyle(
                                                fontSize: 11,
                                            color: assignments.length >= capacity 
                                                ? Colors.amber[900] 
                                                : Colors.green[900],
                                          ),
                                        ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Ausentes: ${assignments.where((a) => (a.data() as Map<String, dynamic>)['didNotAttend'] == true).length}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isPastor)
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary,
                                    child: IconButton(
                                      icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                                      onPressed: () => _showAddAttendeeModal(
                                        ministryId: ministryId,
                                        ministryName: ministryName,
                                        roleId: roleId,
                                        roleName: roleName,
                                      ),
                                      tooltip: 'Adicionar participante',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          // Lista de asignaciones para este rol
                          if (assignments.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                        'Não há participantes confirmados',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: assignments.length,
                              itemBuilder: (context, assignmentIndex) {
                                final assignment = assignments[assignmentIndex];
                                final assignmentData = assignment.data() as Map<String, dynamic>;
                                final String userId = _normalizeId(assignmentData['userId']);
                                final bool isAttendanceConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
                                final String? attendedById = assignmentData['attendedBy'] != null 
                                    ? _normalizeId(assignmentData['attendedBy']) 
                                    : null;
                                
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnapshot) {
                                    String assignedUserName = 'Usuario';
                                    String photoUrl = '';
                                    
                                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                      assignedUserName = userData['displayName'] ?? 'Usuario';
                                      photoUrl = userData['photoUrl'] ?? '';
                                    }
                                    
                                    return FutureBuilder(
                                      future: attendedById != null && attendedById != userId 
                                          ? FirebaseFirestore.instance.collection('users').doc(attendedById).get()
                                          : null,
                                      builder: (context, attendeeSnapshot) {
                                        String attendeeName = assignedUserName;
                                        String attendeePhotoUrl = photoUrl;
                                        
                                        if (attendeeSnapshot != null && 
                                            attendeeSnapshot.data != null && 
                                            (attendeeSnapshot.data as DocumentSnapshot).exists) {
                                          final attendeeData = (attendeeSnapshot.data as DocumentSnapshot).data() as Map<String, dynamic>;
                                          attendeeName = attendeeData['displayName'] ?? 'Usuario';
                                          attendeePhotoUrl = attendeeData['photoUrl'] ?? '';
                                        }
                                        
                                        final bool isDifferentAttendee = attendedById != null && attendedById != userId;
                                        
                                        return Card(
                                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          elevation: 0,
                                                color: assignmentData['didNotAttend'] == true
                                                    ? Colors.red[50]
                                                    : isAttendanceConfirmed 
                                              ? Colors.green[50] 
                                              : Colors.grey[100],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                                  side: assignmentData['didNotAttend'] == true
                                                      ? BorderSide(color: Colors.red[400]!, width: 1)
                                                      : isAttendanceConfirmed 
                                                ? BorderSide(color: Colors.green[300]!, width: 1)
                                                : BorderSide.none,
                                          ),
                                          child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                                    // Chip de status
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                                                      child: Wrap(
                                                        children: [
                                                          if (assignmentData['didNotAttend'] == true)
                                                            Chip(
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: VisualDensity.compact,
                                                              backgroundColor: Colors.red[100],
                                                              side: BorderSide(color: Colors.red[400]!),
                                                              avatar: Icon(Icons.person_off, size: 16, color: Colors.red[700]),
                                                              label: Text(
                                                                'AUSENTE',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.red[700],
                                                                ),
                                                              ),
                                                            )
                                                          else if (isAttendanceConfirmed)
                                                            Chip(
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: VisualDensity.compact,
                                                              backgroundColor: Colors.green[100],
                                                              side: BorderSide(color: Colors.green[400]!),
                                                              avatar: Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                                                              label: Text(
                                                                'PRESENTE',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.green[700],
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            Chip(
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: VisualDensity.compact,
                                                              backgroundColor: Colors.grey[200],
                                                              side: BorderSide(color: Colors.grey[400]!),
                                                              avatar: Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                                                              label: Text(
                                                                'PENDENTE',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.grey[700],
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                              ListTile(
                                                      leading: Stack(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 22,
                                                            backgroundColor: assignmentData['didNotAttend'] == true 
                                                                ? Colors.red[100] 
                                                                : isAttendanceConfirmed
                                                                    ? Colors.green[100]
                                                                    : Colors.grey[200],
                                                  backgroundImage: photoUrl.isNotEmpty
                                                      ? NetworkImage(photoUrl) as ImageProvider
                                                      : const AssetImage('assets/images/user_placeholder.png') as ImageProvider,
                                                  child: photoUrl.isEmpty
                                                      ? Text(
                                                          assignedUserName.isNotEmpty 
                                                              ? assignedUserName[0].toUpperCase() 
                                                              : '?',
                                                          style: const TextStyle(color: Colors.white),
                                                        )
                                                      : null,
                                                          ),
                                                          if (assignmentData['didNotAttend'] == true)
                                                            Positioned(
                                                              bottom: -2,
                                                              right: -2,
                                                              child: Container(
                                                                padding: const EdgeInsets.all(2),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors.black12,
                                                                      blurRadius: 2,
                                                                      spreadRadius: 0,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Icon(
                                                                  Icons.cancel,
                                                                  color: Colors.red[700],
                                                                  size: 16,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                ),
                                                title: Text(
                                                  assignedUserName,
                                                  style: TextStyle(
                                                          fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    decoration: isDifferentAttendee 
                                                        ? TextDecoration.lineThrough 
                                                        : null,
                                                          color: assignmentData['didNotAttend'] == true
                                                              ? Colors.red[700]
                                                        : null,
                                                  ),
                                                ),
                                                      subtitle: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            assignmentData['didNotAttend'] == true
                                                                ? 'Não compareceu'
                                                                : 'Atribuído originalmente',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                              color: assignmentData['didNotAttend'] == true
                                                                  ? Colors.red[700]
                                                                  : Colors.grey[700],
                                                              fontWeight: assignmentData['didNotAttend'] == true
                                                                  ? FontWeight.bold
                                                                  : FontWeight.normal,
                                                            ),
                                                          ),
                                                          if (assignmentData['didNotAttend'] == true && assignmentData['notAttendedAt'] != null)
                                                            Text(
                                                              'Registrado em ${DateFormat('dd/MM/yyyy HH:mm').format((assignmentData['notAttendedAt'] as Timestamp).toDate())}',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      trailing: assignmentData['didNotAttend'] == true
                                                          ? Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red[100],
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(color: Colors.red[400]!, width: 1)
                                                              ),
                                                              child: const Text(
                                                                'AUSENTE',
                                                    style: TextStyle(
                                                                  color: Colors.red,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            )
                                                          : isAttendanceConfirmed 
                                                              ? Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.green[100],
                                                                    borderRadius: BorderRadius.circular(12),
                                                                    border: Border.all(color: Colors.green[400]!, width: 1)
                                                                  ),
                                                                  child: const Text(
                                                                    'PRESENTE',
                                                                    style: TextStyle(
                                                      color: Colors.green,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 11,
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.amber[100],
                                                                    borderRadius: BorderRadius.circular(12),
                                                                    border: Border.all(color: Colors.amber[400]!, width: 1)
                                                                  ),
                                                                  child: const Text(
                                                                    'PENDENTE',
                                                                    style: TextStyle(
                                                                      color: Colors.amber,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 11,
                                                                    ),
                                                                  ),
                                                                ),
                                                      isThreeLine: assignmentData['didNotAttend'] == true && assignmentData['notAttendedAt'] != null,
                                                ),
                                                
                                              // Botones de acción
                                              if (_isPastor)
                                                Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                                  child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                            // Botones mostrados de manera horizontal en fila con buen espaciado
                                                            Wrap(
                                                              spacing: 12, // Espacio horizontal entre botones
                                                              children: [
                                                                // Botón de confirmar asistencia o desconfirmar
                                                                if (!isAttendanceConfirmed && assignmentData['didNotAttend'] != true)
                                                                  CircleAvatar(
                                                                    radius: 22,
                                                                    backgroundColor: Colors.green,
                                                                    child: IconButton(
                                                            onPressed: () => _confirmAttendance(
                                                              assignment.id,
                                                              userId,
                                                              assignedUserName,
                                                              false,
                                                            ),
                                                                      icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                                                      tooltip: 'Confirmar',
                                                                    ),
                                                                  )
                                                                else if (isAttendanceConfirmed && assignmentData['didNotAttend'] != true)
                                                                  CircleAvatar(
                                                                    radius: 22,
                                                                    backgroundColor: Colors.orange,
                                                                    child: IconButton(
                                                                      onPressed: () => _unconfirmAttendance(
                                                                        assignment.id,
                                                                        userId,
                                                                        assignedUserName,
                                                                      ),
                                                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                                                      tooltip: 'Desconfirmar',
                                                                    ),
                                                                  ),
                                                                
                                                                // Botón para marcar como no asistió
                                                                if (assignmentData['didNotAttend'] != true)
                                                                  CircleAvatar(
                                                                    radius: 22,
                                                                    backgroundColor: Colors.red,
                                                                    child: IconButton(
                                                                      onPressed: () => _markAsNotAttended(
                                                                        assignment.id,
                                                                        userId,
                                                                        assignedUserName,
                                                                      ),
                                                                      icon: const Icon(Icons.person_off, color: Colors.white, size: 20),
                                                                      tooltip: 'Não Compareceu',
                                                                    ),
                                                                  )
                                                                // Botón para resetear estado
                                                                else
                                                                  CircleAvatar(
                                                                    radius: 22,
                                                                    backgroundColor: AppColors.primary,
                                                                    child: IconButton(
                                                            onPressed: () => _unconfirmAttendance(
                                                              assignment.id,
                                                              userId,
                                                              assignedUserName,
                                                            ),
                                                                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                                                      tooltip: 'Resetar',
                                                                    ),
                                                                  ),
                                                      
                                                      // Botón cambiar asistente
                                                                CircleAvatar(
                                                                  radius: 22,
                                                                  backgroundColor: Colors.indigo,
                                                                  child: IconButton(
                                                          onPressed: () => _showAddAttendeeModal(
                                                            ministryId: ministryId,
                                                            ministryName: ministryName,
                                                            roleId: roleId,
                                                            roleName: roleName,
                                                            assignmentId: assignment.id,
                                                            originalUserId: userId,
                                                            originalUserName: assignedUserName,
                                                            isChangingAttendee: true,
                                                          ),
                                                                    icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                                                                    tooltip: isAttendanceConfirmed 
                                                                        ? 'Alterar' 
                                                                        : 'Outro participante',
                                                                  ),
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
                              },
                            ),
                            
                          // Divisor
                          const Divider(height: 32),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Método para construir tarjetas de estadísticas
  Widget _buildStatCard(String title, int value, int total, MaterialColor color, IconData icon) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: color[50],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color[200]!)
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Usar Wrap para asegurar que el título e icono se ajusten correctamente
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: [
                  Icon(icon, color: color[700], size: 14),
                  Text(
                    title,
                    style: TextStyle(
                      color: color[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color[800],
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    color: color[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar modal para añadir asistente
  void _showAddAttendeeModal({
    required String ministryId,
    required String ministryName,
    required String roleId,
    required String roleName,
    String? assignmentId,
    String? originalUserId,
    String? originalUserName,
    bool isChangingAttendee = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendeeSelectionModal(
        ministryId: ministryId,
        ministryName: ministryName,
        roleId: roleId,
        roleName: roleName,
        timeSlot: widget.timeSlot,
        cult: widget.cult,
        assignmentId: assignmentId,
        originalUserId: originalUserId,
        originalUserName: originalUserName,
        isChangingAttendee: isChangingAttendee,
        multiSelect: !isChangingAttendee, // Solo usar multiselección cuando no estamos cambiando un asistente
        onConfirmAttendees: (selectedUsers) {
          if (selectedUsers.isEmpty) return;
          
          if (isChangingAttendee && assignmentId != null) {
            // Si estamos cambiando un asistente, solo hay uno
            final user = selectedUsers.first;
            _changeAttendee(
              assignmentId, 
              user['id'] ?? '', 
              user['name'] ?? 'Usuário'
            );
          } else {
            // Registrar múltiples asistentes
            for (var user in selectedUsers) {
              _addDirectAttendee(
                ministryId, 
                ministryName, 
                roleId, 
                roleName, 
                user['id'] ?? '', 
                user['name'] ?? 'Usuário'
              );
            }
          }
        },
      ),
    );
  }

  // Añadir asistente directamente a un rol (sin asignación previa)
  Future<void> _addDirectAttendee(
    String ministryId,
    String ministryName,
    String roleId,
    String roleName,
    String userId,
    String userName,
  ) async {
    try {
      // Verificar si el usuario ya tiene una asignación con estado pending o aceptado pero sin confirmar
      final existingAssignments = await FirebaseFirestore.instance
          .collection('work_assignments')
          .where('timeSlotId', isEqualTo: widget.timeSlot.id)
          .where('roleId', isEqualTo: roleId)
          .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(userId))
          .where('isActive', isEqualTo: true)
          .get();
          
      String? existingAssignmentId;
      
      // Si hay una asignación existente, utilizarla en vez de crear una nueva
      if (existingAssignments.docs.isNotEmpty) {
        existingAssignmentId = existingAssignments.docs.first.id;
        
        // Actualizar estado a confirmado si no lo estaba
        final existingAssignmentData = existingAssignments.docs.first.data() as Map<String, dynamic>;
        final bool wasConfirmed = existingAssignmentData['isAttendanceConfirmed'] ?? false;
        
        await FirebaseFirestore.instance
            .collection('work_assignments')
            .doc(existingAssignmentId)
            .update({
              'isAttendanceConfirmed': true,
              'attendedBy': FirebaseFirestore.instance.collection('users').doc(userId),
              'attendanceConfirmedAt': FieldValue.serverTimestamp(),
              'attendanceConfirmedBy': FirebaseAuth.instance.currentUser?.uid,
              'status': 'confirmed', // Actualizar estado para que se vea en las otras tabs
            });
            
        // Si no estaba confirmado anteriormente, incrementar el contador
        if (!wasConfirmed) {
          await _updateRoleCounter(roleId, 1);
        }
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Presença de $userName atualizada'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      // Crear una asignación de trabajo con asistencia confirmada directamente
      await FirebaseFirestore.instance.collection('work_assignments').add({
        'ministryId': FirebaseFirestore.instance.collection('ministries').doc(ministryId),
        'ministryName': ministryName,
        'roleId': roleId,
        'role': roleName,
        'userId': FirebaseFirestore.instance.collection('users').doc(userId),
        'timeSlotId': widget.timeSlot.id,
        'entityId': widget.cult.id,
        'entityType': 'cult',
        'startTime': widget.timeSlot.startTime,
        'endTime': widget.timeSlot.endTime,
        'status': 'confirmed',
        'isActive': true,
        'createdAt': Timestamp.now(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'isAttendanceConfirmed': true,
        'attendedBy': FirebaseFirestore.instance.collection('users').doc(userId),
        'attendanceConfirmedAt': FieldValue.serverTimestamp(),
        'attendanceConfirmedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      
      // Incrementar contador de roles asignados
      await _updateRoleCounter(roleId, 1);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName registrado como participante'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar participante: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método centralizado para actualizar el contador de roles
  Future<void> _updateRoleCounter(String roleId, int increment) async {
    try {
      if (roleId.isEmpty) {
        debugPrint('⚠️ ADVERTENCIA: No se puede actualizar el contador para un roleId vacío');
        return; // Terminar la función sin error, pero loggear la advertencia
      }
      
      // Obtener el documento actual para hacer log del valor antes de actualizar
      final roleDoc = await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .get();
      
      if (!roleDoc.exists) {
        debugPrint('⚠️ ADVERTENCIA: El rol con ID $roleId no existe');
        return; // Terminar la función sin error
      }
      
      final roleData = roleDoc.data()!;
      final int currentValue = roleData['current'] ?? 0;
      final int newValue = currentValue + increment;
      
      // Asegurar que el valor nunca sea negativo
      final int safeNewValue = newValue < 0 ? 0 : newValue;
      
      debugPrint('📊 Actualizando contador de rol $roleId: $currentValue → $safeNewValue');
      
      // Actualizar el contador
      await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .update({
            'current': safeNewValue,
          });
      
      // Verificar que el cambio se haya aplicado correctamente
      final updatedDoc = await FirebaseFirestore.instance
          .collection('available_roles')
          .doc(roleId)
          .get();
      
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data()!;
        final int updatedValue = updatedData['current'] ?? 0;
        debugPrint('✅ Contador actualizado exitosamente: $updatedValue');
      } else {
        debugPrint('❌ No se pudo verificar la actualización');
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar contador del rol: $e');
      // No propagar el error para no interrumpir otras operaciones
    }
  }

  // Confirmar asistencia con el usuario original asignado
  Future<void> _confirmAttendance(
    String assignmentId, 
    String userId, 
    String userName,
    bool changeAttendee,
  ) async {
    try {
      debugPrint('🔎 DIAGNÓSTICO: Iniciando confirmación de asistencia para usuario $userName (id: $userId)');
      debugPrint('🔎 DIAGNÓSTICO: AssignmentId: $assignmentId, changeAttendee: $changeAttendee');
      
      // Primero obtener la asignación para conseguir el roleId
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        debugPrint('❌ DIAGNÓSTICO: La asignación no existe');
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      debugPrint('📋 DIAGNÓSTICO: Datos de asignación completos: ${assignmentData.toString()}');
      
      final String roleId = assignmentData['roleId'] as String? ?? '';
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      
      debugPrint('📝 Confirmando asistencia para: $userName (roleId: $roleId, wasConfirmed: $wasConfirmed)');
      
      // Actualizar la asignación
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': true,
            'attendedBy': changeAttendee ? null : FirebaseFirestore.instance.collection('users').doc(userId),
            'attendanceConfirmedAt': FieldValue.serverTimestamp(),
            'attendanceConfirmedBy': FirebaseAuth.instance.currentUser?.uid,
            'status': 'confirmed', // Actualizar estado para que se vea en las otras tabs
          });
      
      // Incrementar el contador del rol solo si no estaba confirmado anteriormente
      if (!wasConfirmed && roleId.isNotEmpty) {
        debugPrint('⚙️ DIAGNÓSTICO: Procediendo a incrementar contador (wasConfirmed=$wasConfirmed, roleId=$roleId)');
        
        // Asegurar que obtenemos el rol antes de actualizar el contador
        final roleDoc = await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .get();
        
        if (roleDoc.exists) {
          final roleData = roleDoc.data() as Map<String, dynamic>;
          debugPrint('📊 Rol encontrado: ${roleData['role']} en ministerio ${roleData['ministryName']}');
          debugPrint('📊 DIAGNÓSTICO: Datos completos del rol: ${roleData.toString()}');
          
          final int currentValue = roleData['current'] ?? 0;
          debugPrint('📊 DIAGNÓSTICO: Valor actual del contador antes de actualizar: $currentValue');
          
          // Extraer ministryId de manera segura
          String ministryId;
          final dynamic ministryIdRaw = roleData['ministryId'];
          if (ministryIdRaw is DocumentReference) {
            ministryId = ministryIdRaw.id;
            debugPrint('🔢 DIAGNÓSTICO: ministryId es DocumentReference: ${ministryIdRaw.path}');
          } else if (ministryIdRaw is String) {
            ministryId = ministryIdRaw.contains('/') 
                ? ministryIdRaw.split('/').last 
                : ministryIdRaw;
            debugPrint('🔢 DIAGNÓSTICO: ministryId es String: $ministryIdRaw');
          } else {
            ministryId = ministryIdRaw.toString();
            debugPrint('🔢 DIAGNÓSTICO: ministryId es tipo desconocido: ${ministryIdRaw.runtimeType}');
          }
          
          final String roleName = roleData['role'] as String? ?? '';
          
          debugPrint('🔄 DIAGNÓSTICO: Llamando a updateRoleCounter con timeSlotId=${widget.timeSlot.id}, ministryId=$ministryId, roleName=$roleName, increase=true');
          
          // Usar el servicio para actualizar el contador
          await WorkScheduleService().updateRoleCounter(
            widget.timeSlot.id, 
            ministryId, 
            roleName, 
            true // Incrementar
          );
          
          // Verificar que el contador se actualizó correctamente
          final updatedRoleDoc = await FirebaseFirestore.instance
              .collection('available_roles')
              .doc(roleId)
              .get();
              
          if (updatedRoleDoc.exists) {
            final updatedRoleData = updatedRoleDoc.data()!;
            final int newValue = updatedRoleData['current'] ?? 0;
            debugPrint('✅ DIAGNÓSTICO: Contador después de actualizar: $newValue (antes era $currentValue)');
            
            if (newValue == currentValue) {
              debugPrint('⚠️ DIAGNÓSTICO: ¡ALERTA! El contador no cambió después de la actualización');
            } else {
              debugPrint('✅ DIAGNÓSTICO: Contador actualizado correctamente');
            }
          }
          
          debugPrint('📊 Contador actualizado para rol $roleName');
        } else {
          debugPrint('⚠️ DIAGNÓSTICO: No se encontró el rol con ID $roleId, usando método fallback');
          await _updateRoleCounter(roleId, 1);
        }
      } else {
        debugPrint('ℹ️ DIAGNÓSTICO: No se incrementó el contador porque wasConfirmed=$wasConfirmed o roleId está vacío');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presença de $userName confirmada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al confirmar asistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar presença: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Desconfirmar una asistencia previamente confirmada
  Future<void> _unconfirmAttendance(
    String assignmentId, 
    String userId, 
    String userName,
  ) async {
    try {
      debugPrint('🔎 DIAGNÓSTICO: Iniciando desconfirmación de asistencia para usuario $userName (id: $userId)');
      debugPrint('🔎 DIAGNÓSTICO: AssignmentId: $assignmentId');
      
      // Primero obtener la asignación para conseguir el roleId
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        debugPrint('❌ DIAGNÓSTICO: La asignación no existe');
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      debugPrint('📋 DIAGNÓSTICO: Datos de asignación completos: ${assignmentData.toString()}');
      
      // Recuperar roleId si existe
      final String roleId = assignmentData['roleId'] as String? ?? '';
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      
      debugPrint('📝 Desconfirmando asistencia para: $userName (roleId: $roleId, wasConfirmed: $wasConfirmed)');
      
      // Determinar estado adecuado cuando se resetea
      String newStatus = 'accepted';
      // Si estaba marcado como "did not attend", al resetear volvemos a "accepted"
      if (assignmentData['status'] == 'not_attended' || assignmentData['didNotAttend'] == true) {
        newStatus = 'accepted';
      } else if (assignmentData['status'] != null) {
        // Si tenía otro estado, mantenemos el estado original
        newStatus = assignmentData['status'];
        if (newStatus == 'confirmed') {
          newStatus = 'accepted'; // Si estaba confirmado, volvemos a aceptado
        }
      }
      
      // Actualizar la asignación independientemente del roleId
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': false,
            'attendedBy': null, // Eliminar la referencia a quien asistió
            'attendanceConfirmedAt': null,
            'status': newStatus, // Usar el estado calculado
            'didNotAttend': false, // Resetear este campo si existía
            'notAttendedAt': null, // Resetear este campo si existía
            'notAttendedBy': null, // Resetear este campo si existía
          });
      
      // Decrementar el contador del rol solo si estaba confirmado anteriormente y el roleId existe
      if (wasConfirmed && roleId.isNotEmpty) {
        debugPrint('⚙️ DIAGNÓSTICO: Procediendo a decrementar contador (wasConfirmed=$wasConfirmed, roleId=$roleId)');
        
        // Asegurar que obtenemos el rol antes de actualizar el contador
        final roleDoc = await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .get();
        
        if (roleDoc.exists) {
          final roleData = roleDoc.data() as Map<String, dynamic>;
          debugPrint('📊 Rol encontrado: ${roleData['role']} en ministerio ${roleData['ministryName']}');
          debugPrint('📊 DIAGNÓSTICO: Datos completos del rol: ${roleData.toString()}');
          
          final int currentValue = roleData['current'] ?? 0;
          debugPrint('📊 DIAGNÓSTICO: Valor actual del contador antes de decrementar: $currentValue');
          
          // Extraer ministryId de manera segura
          String ministryId;
          final dynamic ministryIdRaw = roleData['ministryId'];
          if (ministryIdRaw is DocumentReference) {
            ministryId = ministryIdRaw.id;
            debugPrint('🔢 DIAGNÓSTICO: ministryId es DocumentReference: ${ministryIdRaw.path}');
          } else if (ministryIdRaw is String) {
            ministryId = ministryIdRaw.contains('/') 
                ? ministryIdRaw.split('/').last 
                : ministryIdRaw;
            debugPrint('🔢 DIAGNÓSTICO: ministryId es String: $ministryIdRaw');
          } else {
            ministryId = ministryIdRaw.toString();
            debugPrint('🔢 DIAGNÓSTICO: ministryId es tipo desconocido: ${ministryIdRaw.runtimeType}');
          }
          
          final String roleName = roleData['role'] as String? ?? '';
          
          debugPrint('🔄 DIAGNÓSTICO: Llamando a updateRoleCounter con timeSlotId=${widget.timeSlot.id}, ministryId=$ministryId, roleName=$roleName, increase=false (decrementar)');
          
          // Usar el servicio para actualizar el contador
          await WorkScheduleService().updateRoleCounter(
            widget.timeSlot.id, 
            ministryId, 
            roleName, 
            false // Decrementar
          );
          
          // Verificar que el contador se actualizó correctamente
          final updatedRoleDoc = await FirebaseFirestore.instance
              .collection('available_roles')
              .doc(roleId)
              .get();
              
          if (updatedRoleDoc.exists) {
            final updatedRoleData = updatedRoleDoc.data()!;
            final int newValue = updatedRoleData['current'] ?? 0;
            debugPrint('✅ DIAGNÓSTICO: Contador después de decrementar: $newValue (antes era $currentValue)');
            
            if (newValue == currentValue) {
              debugPrint('⚠️ DIAGNÓSTICO: ¡ALERTA! El contador no cambió después de la desconfirmación');
            } else {
              debugPrint('✅ DIAGNÓSTICO: Contador actualizado correctamente');
            }
          }
          
          debugPrint('📊 Contador actualizado para rol $roleName');
        } else {
          debugPrint('⚠️ DIAGNÓSTICO: No se encontró el rol con ID $roleId, usando método fallback');
          // Fallback al método antiguo si no encontramos el rol
          await _updateRoleCounter(roleId, -1);
        }
      } else {
        debugPrint('ℹ️ DIAGNÓSTICO: No se decrementó el contador porque wasConfirmed=$wasConfirmed o roleId está vacío');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado de $userName restaurado'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al desconfirmar asistencia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Cambiar el asistente
  Future<void> _changeAttendee(
    String assignmentId, 
    String newUserId, 
    String newUserName,
  ) async {
    try {
      // Primero obtener la asignación para verificar si ya estaba confirmada
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        throw Exception('La asignación no existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      final String roleId = assignmentData['roleId'] as String? ?? '';
      
      debugPrint('📝 Cambiando asistente a: $newUserName (roleId: $roleId, wasConfirmed: $wasConfirmed)');
      
      // Actualizar la asignación a confirmada con el nuevo asistente
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': true,
            'attendedBy': FirebaseFirestore.instance.collection('users').doc(newUserId),
            'attendanceConfirmedAt': FieldValue.serverTimestamp(),
            'attendanceConfirmedBy': FirebaseAuth.instance.currentUser?.uid,
            'status': 'confirmed', // Actualizar estado para que se vea en las otras tabs
          });
      
      // Si no estaba confirmada previamente, incrementar el contador del rol
      if (!wasConfirmed && roleId.isNotEmpty) {
        // Asegurar que obtenemos el rol antes de actualizar el contador
        final roleDoc = await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .get();
        
        if (roleDoc.exists) {
          final roleData = roleDoc.data() as Map<String, dynamic>;
          debugPrint('📊 Rol encontrado: ${roleData['role']} en ministerio ${roleData['ministryName']}');
          
          // Extraer ministryId de manera segura
          String ministryId;
          final dynamic ministryIdRaw = roleData['ministryId'];
          if (ministryIdRaw is DocumentReference) {
            ministryId = ministryIdRaw.id;
          } else if (ministryIdRaw is String) {
            ministryId = ministryIdRaw.contains('/') 
                ? ministryIdRaw.split('/').last 
                : ministryIdRaw;
          } else {
            ministryId = ministryIdRaw.toString();
          }
          
          final String roleName = roleData['role'] as String? ?? '';
          
          // Usar el servicio para actualizar el contador
          await WorkScheduleService().updateRoleCounter(
            widget.timeSlot.id, 
            ministryId, 
            roleName, 
            true // Incrementar
          );
          
          debugPrint('📊 Contador actualizado para rol $roleName');
        } else {
          // Fallback al método antiguo
          await _updateRoleCounter(roleId, 1);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presença alterada para $newUserName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error al cambiar asistente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar participante: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para marcar que um usuário não compareceu
  Future<void> _markAsNotAttended(
    String assignmentId, 
    String userId, 
    String userName,
  ) async {
    try {
      debugPrint('🔎 DIAGNÓSTICO: Marcando usuário $userName (id: $userId) como ausente');
      debugPrint('🔎 DIAGNÓSTICO: AssignmentId: $assignmentId');
      
      // Primeiro obter a atribuição para conseguir o roleId
      final assignmentDoc = await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .get();
          
      if (!assignmentDoc.exists) {
        debugPrint('❌ DIAGNÓSTICO: A atribuição não existe');
        throw Exception('A atribuição não existe');
      }
      
      final assignmentData = assignmentDoc.data() as Map<String, dynamic>;
      debugPrint('📋 DIAGNÓSTICO: Dados completos da atribuição: ${assignmentData.toString()}');
      
      final String roleId = assignmentData['roleId'] as String? ?? '';
      final bool wasConfirmed = assignmentData['isAttendanceConfirmed'] ?? false;
      
      debugPrint('📝 Marcando usuário como ausente: $userName (roleId: $roleId, wasConfirmed: $wasConfirmed)');
      
      // Atualizar a atribuição independentemente do roleId
      await FirebaseFirestore.instance
          .collection('work_assignments')
          .doc(assignmentId)
          .update({
            'isAttendanceConfirmed': false,
            'didNotAttend': true,              // Marcamos explicitamente que não compareceu
            'attendedBy': null,                // Removemos qualquer referência a participante
            'attendanceConfirmedAt': null,     // Removemos data de confirmação
            'notAttendedAt': FieldValue.serverTimestamp(),  // Registramos quando foi marcado como ausente
            'notAttendedBy': FirebaseAuth.instance.currentUser?.uid,  // Registramos quem marcou
            'status': 'not_attended',          // Estado específico para ausência
          });
      
      // Decrementar o contador do cargo apenas se estava confirmado anteriormente e roleId não está vazio
      if (wasConfirmed && roleId.isNotEmpty) {
        debugPrint('⚙️ DIAGNÓSTICO: Decrementando contador (wasConfirmed=$wasConfirmed, roleId=$roleId)');
        
        // Garantir que obtemos o cargo antes de atualizar o contador
        final roleDoc = await FirebaseFirestore.instance
            .collection('available_roles')
            .doc(roleId)
            .get();
        
        if (roleDoc.exists) {
          final roleData = roleDoc.data() as Map<String, dynamic>;
          debugPrint('📊 Cargo encontrado: ${roleData['role']} no ministério ${roleData['ministryName']}');
          debugPrint('📊 DIAGNÓSTICO: Dados completos do cargo: ${roleData.toString()}');
          
          final int currentValue = roleData['current'] ?? 0;
          debugPrint('📊 DIAGNÓSTICO: Valor atual do contador antes de decrementar: $currentValue');
          
          // Extrair ministryId de forma segura
          String ministryId;
          final dynamic ministryIdRaw = roleData['ministryId'];
          if (ministryIdRaw is DocumentReference) {
            ministryId = ministryIdRaw.id;
            debugPrint('🔢 DIAGNÓSTICO: ministryId é DocumentReference: ${ministryIdRaw.path}');
          } else if (ministryIdRaw is String) {
            ministryId = ministryIdRaw.contains('/') 
                ? ministryIdRaw.split('/').last 
                : ministryIdRaw;
            debugPrint('🔢 DIAGNÓSTICO: ministryId é String: $ministryIdRaw');
          } else {
            ministryId = ministryIdRaw.toString();
            debugPrint('🔢 DIAGNÓSTICO: ministryId é tipo desconhecido: ${ministryIdRaw.runtimeType}');
          }
          
          final String roleName = roleData['role'] as String? ?? '';
          
          debugPrint('🔄 DIAGNÓSTICO: Chamando updateRoleCounter com timeSlotId=${widget.timeSlot.id}, ministryId=$ministryId, roleName=$roleName, increase=false (decrementar)');
          
          // Usar o serviço para atualizar o contador
          await WorkScheduleService().updateRoleCounter(
            widget.timeSlot.id, 
            ministryId, 
            roleName, 
            false // Decrementar
          );
          
          // Verificar que o contador foi atualizado corretamente
          final updatedRoleDoc = await FirebaseFirestore.instance
              .collection('available_roles')
              .doc(roleId)
              .get();
              
          if (updatedRoleDoc.exists) {
            final updatedRoleData = updatedRoleDoc.data()!;
            final int newValue = updatedRoleData['current'] ?? 0;
            debugPrint('✅ DIAGNÓSTICO: Contador após decrementar: $newValue (antes era $currentValue)');
            
            if (newValue == currentValue) {
              debugPrint('⚠️ DIAGNÓSTICO: ALERTA! O contador não mudou após marcar como ausente');
            } else {
              debugPrint('✅ DIAGNÓSTICO: Contador atualizado corretamente');
            }
          }
          
          debugPrint('📊 Contador atualizado para cargo $roleName');
        } else {
          debugPrint('⚠️ DIAGNÓSTICO: Cargo com ID $roleId não encontrado, usando método alternativo');
          // Método alternativo se não encontramos o cargo
          await _updateRoleCounter(roleId, -1);
        }
      } else {
        debugPrint('ℹ️ DIAGNÓSTICO: Contador não decrementado porque wasConfirmed=$wasConfirmed ou roleId está vazio');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$userName marcado como ausente'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erro ao marcar como ausente: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar como ausente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}