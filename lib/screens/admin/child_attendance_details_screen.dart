import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/child_model.dart';
import '../../models/checkin_record_model.dart';
import '../../models/scheduled_room_model.dart';
import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildAttendanceDetailsScreen extends StatefulWidget {
  final String childId;
  final String scheduledRoomId;

  const ChildAttendanceDetailsScreen({
    super.key,
    required this.childId,
    required this.scheduledRoomId,
  });

  @override
  State<ChildAttendanceDetailsScreen> createState() => _ChildAttendanceDetailsScreenState();
}

class _ChildAttendanceDetailsScreenState extends State<ChildAttendanceDetailsScreen> {
  ChildModel? _child;
  ScheduledRoomModel? _scheduledRoom;
  CheckinRecordModel? _currentCheckinRecord;
  List<UserModel> _guardians = [];
  bool _isLoading = true;
  int? _labelNumber;
  bool _isVisitor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Cargar datos del niño
      final childDoc = await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .get();
      
      if (childDoc.exists) {
        _child = ChildModel.fromFirestore(childDoc);
      }

      // Cargar datos de la sala programada
      final roomDoc = await FirebaseFirestore.instance
          .collection('scheduledRooms')
          .doc(widget.scheduledRoomId)
          .get();
      
      if (roomDoc.exists) {
        _scheduledRoom = ScheduledRoomModel.fromFirestore(roomDoc);
      }

      // Buscar el registro de check-in actual
      final checkinQuery = await FirebaseFirestore.instance
          .collection('checkinRecords')
          .where('childId', isEqualTo: widget.childId)
          .where('scheduledRoomId', isEqualTo: widget.scheduledRoomId)
          .where('status', isEqualTo: 'checkedIn')
          .limit(1)
          .get();

      if (checkinQuery.docs.isNotEmpty) {
        _currentCheckinRecord = CheckinRecordModel.fromFirestore(checkinQuery.docs.first);
        
        // Obtener o asignar número de etiqueta
        _labelNumber = await _getOrAssignLabelNumber();
        
        // Cargar responsables
        await _loadGuardians();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGuardians() async {
    if (_currentCheckinRecord == null || _child == null) return;

    try {
      // Verificar si es de una familia o visitante
      final familyId = _currentCheckinRecord!.familyId;
      
      // Primero intentar cargar como familia
      final familyDoc = await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .get();

      if (familyDoc.exists) {
        // Es una familia
        final family = FamilyModel.fromFirestore(familyDoc);
        
        // Cargar todos los responsables de la familia
        for (String guardianId in family.guardianUserIds) {
          final guardianDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(guardianId)
              .get();
          
          if (guardianDoc.exists) {
            _guardians.add(UserModel.fromMap(guardianDoc.data()!));
          }
        }
      } else {
        // Es un visitante
        final visitorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(familyId)
            .get();
            
        if (visitorDoc.exists) {
          final visitor = UserModel.fromMap(visitorDoc.data()!);
          if (visitor.isVisitorOnly == true) {
            _guardians.add(visitor);
            _isVisitor = true;
          }
        }
      }
    } catch (e) {
      print('Error cargando responsables: $e');
    }
  }

  Future<int> _getOrAssignLabelNumber() async {
    if (_currentCheckinRecord == null || _scheduledRoom == null) return 1;

    // Verificar si ya tiene un número asignado en el checkinRecord
    if (_currentCheckinRecord!.labelNumber != null) {
      return _currentCheckinRecord!.labelNumber!;
    }

    // Si no tiene número, asignar el siguiente disponible
    final roomRef = FirebaseFirestore.instance
        .collection('scheduledRooms')
        .doc(widget.scheduledRoomId);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final roomData = roomSnapshot.data() as Map<String, dynamic>;
      
      // Obtener el siguiente número disponible (empezando desde 1)
      final List<dynamic> checkedInIds = roomData['checkedInChildIds'] ?? [];
      final int nextNumber = checkedInIds.indexOf(widget.childId) + 1;
      
      // Actualizar el checkinRecord con el número de etiqueta
      final checkinRef = FirebaseFirestore.instance
          .collection('checkinRecords')
          .doc(_currentCheckinRecord!.id);
      
      transaction.update(checkinRef, {'labelNumber': nextNumber});
      
      return nextNumber;
    });
  }

  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return 'N/A';
    final birth = birthDate.toDate();
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age > 0 ? '$age anos' : (age == 0 ? 'Menos de 1 ano' : 'N/A');
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    String initials = parts.first[0];
    if (parts.length > 1) initials += parts.last[0];
    return initials.toUpperCase();
  }

  void _reprintLabel() {
    // TODO: Implementar reimpresión de etiqueta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reimprimir etiqueta ${_labelNumber ?? 'N/A'} (Pendente de implementação)'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes da Assistência'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_child == null || _scheduledRoom == null || _currentCheckinRecord == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes da Assistência'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erro ao carregar dados da assistência'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Assistência'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del niño
            _buildInfoCard(
              title: 'Informação da Criança',
              icon: Icons.child_care,
              children: [
                _buildInfoRow('Nome', '${_child!.firstName} ${_child!.lastName}'),
                _buildInfoRow('Idade', _calculateAge(_child!.dateOfBirth)),
                _buildInfoRow('Data de Nascimento', 
                  _child!.dateOfBirth != null 
                    ? DateFormat('dd/MM/yyyy').format(_child!.dateOfBirth!.toDate())
                    : 'N/A'
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Detalles de la etiqueta
            _buildInfoCard(
              title: 'Detalhes da Etiqueta',
              icon: Icons.qr_code,
              children: [
                _buildInfoRow('Número da Etiqueta', _labelNumber?.toString() ?? 'N/A'),
                _buildInfoRow('Fecha', 
                  DateFormat('dd/MM/yyyy').format(_scheduledRoom!.date.toDate())
                ),
                _buildInfoRow('Check In', 
                  DateFormat('HH:mm').format(_currentCheckinRecord!.checkinTime.toDate())
                ),
                _buildInfoRow('Check Out', 'N/A'), // TODO: Implementar check-out
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Información de la sala
            _buildInfoCard(
              title: 'Informação da Sala',
              icon: Icons.meeting_room,
              children: [
                _buildInfoRow('Sala', _scheduledRoom!.description),
                _buildInfoRow('Faixa Etária', _scheduledRoom!.ageRange ?? 'N/A'),
                _buildInfoRow('Horário', 
                  '${DateFormat('HH:mm').format(_scheduledRoom!.startTime.toDate())} - ${DateFormat('HH:mm').format(_scheduledRoom!.endTime.toDate())}'
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Responsables
            _buildInfoCard(
              title: _isVisitor ? 'Visitante Responsável' : 'Responsáveis',
              icon: Icons.people,
              children: _guardians.isEmpty 
                ? [const Text('Nenhum responsável encontrado')]
                : _guardians.map((guardian) => _buildGuardianInfo(guardian)).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                // Botón de reimprimir
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.print, color: AppColors.primary),
                    label: Text(
                      'REIMPRIMIR',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _reprintLabel,
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de check-out
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app, color: Colors.white),
                    label: const Text(
                      'CHECK-OUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _performIndividualCheckout,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyText2.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianInfo(UserModel guardian) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar del responsable
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: guardian.photoUrl != null && guardian.photoUrl!.isNotEmpty
                ? NetworkImage(guardian.photoUrl!)
                : null,
            child: guardian.photoUrl == null || guardian.photoUrl!.isEmpty
                ? Text(
                    _getInitials(guardian.displayName ?? guardian.name ?? ''),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Información del responsable
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guardian.displayName ?? guardian.name ?? 'Nome não disponível',
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (guardian.email != null && guardian.email!.isNotEmpty)
                  Text(
                    guardian.email!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (guardian.phoneComplete != null && guardian.phoneComplete!.isNotEmpty)
                  Text(
                    guardian.phoneComplete!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (_isVisitor)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Visitante',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performIndividualCheckout() async {
    if (_currentCheckinRecord == null || _child == null) return;

    // Mostrar diálogo de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Checkout'),
          content: Text(
            'Deseja realizar o checkout de ${_child!.firstName} ${_child!.lastName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final adminUserId = FirebaseAuth.instance.currentUser?.uid;
    if (adminUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Administrador não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      // Actualizar el registro de check-in
      final recordRef = FirebaseFirestore.instance
          .collection('checkinRecords')
          .doc(_currentCheckinRecord!.id);
          
      batch.update(recordRef, {
        'status': 'checkedOut',
        'checkoutTime': FieldValue.serverTimestamp(),
        'checkedOutByUserId': adminUserId,
      });
      
      // Remover de la lista de check-in de la sala
      if (_currentCheckinRecord!.scheduledRoomId != null) {
        final roomRef = FirebaseFirestore.instance
            .collection('scheduledRooms')
            .doc(_currentCheckinRecord!.scheduledRoomId!);
            
        batch.update(roomRef, {
          'checkedInChildIds': FieldValue.arrayRemove([widget.childId]),
        });
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout realizado para ${_child!.firstName} ${_child!.lastName}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error realizando checkout individual: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao realizar checkout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 