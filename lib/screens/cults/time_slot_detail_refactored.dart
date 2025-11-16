import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/cult.dart';
import '../../models/time_slot.dart';
import 'dart:async';

// Importar los nuevos componentes
import 'time_slot_components/attendance_manager.dart';
import 'time_slot_components/role_manager.dart';

/// Versión refactorizada de TimeSlotDetailScreen
/// Este archivo muestra cómo se vería el archivo original después de la refactorización
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
  
  // Instancias de los gestores
  late AttendanceManager _attendanceManager;
  late RoleManager _roleManager;
  
  @override
  void initState() {
    super.initState();
    _checkPastorStatus();
    
    // Inicializar controladores
    _nameController = TextEditingController(text: widget.timeSlot.name);
    _descriptionController = TextEditingController(text: widget.timeSlot.description);
    _startTime = TimeOfDay.fromDateTime(widget.timeSlot.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.timeSlot.endTime);
    
    // Inicializar los gestores
    _attendanceManager = AttendanceManager(
      timeSlot: widget.timeSlot,
      context: context,
    );
    
    _roleManager = RoleManager(
      timeSlot: widget.timeSlot,
      context: context,
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Verificar si el usuario actual es un pastor
  Future<void> _checkPastorStatus() async {
    // Eliminada la verificación - el botón se muestra siempre
    setState(() {
      _isPastor = true;
      _isLoading = false;
    });
  }
  
  // -- MÉTODOS DELEGADOS A LOS GESTORES --
  
  // Delegación al AttendanceManager
  void _confirmAttendance(String assignmentId, String userId, String userName, bool changeAttendee) {
    _attendanceManager.confirmAttendance(assignmentId, userId, userName, changeAttendee);
  }
  
  void _unconfirmAttendance(String assignmentId, String userId, String userName) {
    _attendanceManager.unconfirmAttendance(assignmentId, userId, userName);
  }
  
  void _changeAttendee(String assignmentId, String newUserId, String newUserName) {
    _attendanceManager.changeAttendee(assignmentId, newUserId, newUserName);
  }
  
  // Delegación al RoleManager
  void _showAddRoleModal({
    required dynamic ministryId,
    required String ministryName,
    required bool isTemporary,
  }) {
    final TextEditingController roleController = TextEditingController();
    final TextEditingController capacityController = TextEditingController(text: '1');
    
    // Resto del código del modal...
    // Al finalizar, llama a:
    _roleManager.createRole(
      ministryId: ministryId,
      ministryName: ministryName,
      roleName: roleController.text,
      capacity: int.tryParse(capacityController.text) ?? 1,
      isTemporary: isTemporary,
      saveAsPredefined: true,
    );
  }
  
  // -- MÉTODOS DE CONSTRUCCIÓN DE UI --
  
  @override
  Widget build(BuildContext context) {
    final startTimeStr = DateFormat('HH:mm').format(widget.timeSlot.startTime);
    final endTimeStr = DateFormat('HH:mm').format(widget.timeSlot.endTime);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing 
            ? 'Editar Franja Horaria' 
            : '${widget.timeSlot.name} ($startTimeStr - $endTimeStr)'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                onPressed: () => setState(() => _isEditing = true),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ministerios'),
              Tab(text: 'Invitaciones'),
              Tab(text: 'Confirmaciones'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isEditing
                ? _buildEditForm()
                : TabBarView(
                    children: [
                      _buildMinistriesTab(),
                      _buildInvitationsTab(),
                      _buildConfirmationTab(),
                    ],
                  ),
      ),
    );
  }
  
  // Formulario de edición
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Campos del formulario...
        ],
      ),
    );
  }
  
  // Pestañas
  Widget _buildMinistriesTab() {
    return const Center(child: Text('Pestaña de Ministerios'));
  }
  
  Widget _buildInvitationsTab() {
    return const Center(child: Text('Pestaña de Invitaciones'));
  }
  
  Widget _buildConfirmationTab() {
    return const Center(child: Text('Pestaña de Confirmaciones'));
  }
} 