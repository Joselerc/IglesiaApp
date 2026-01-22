import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/ticket_registration_model.dart';
import '../../models/ticket_model.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class EventAttendeeManagementScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventAttendeeManagementScreen({
    Key? key,
    required this.eventId,
    required this.eventTitle,
  }) : super(key: key);

  @override
  State<EventAttendeeManagementScreen> createState() => _EventAttendeeManagementScreenState();
}

class _EventAttendeeManagementScreenState extends State<EventAttendeeManagementScreen> {
  List<TicketModel> _tickets = [];
  Map<String, List<TicketRegistrationModel>> _registrationsByTicket = {};
  bool _isLoading = true;
  String? _selectedTicketId;
  String _searchQuery = '';
  String _viewFilter = 'all'; // 'all', 'registered', 'attended'

  AppLocalizations get _loc => AppLocalizations.of(context)!;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar tickets del evento mediante el snapshot
      final ticketsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('tickets')
          .get();
      
      // Transformar documentos en modelos
      final List<TicketModel> tickets = ticketsSnapshot.docs
          .map((doc) => TicketModel.fromFirestore(doc))
          .toList();
      
      // Guardar tickets
      setState(() {
        _tickets = tickets;
        if (tickets.isNotEmpty) {
          _selectedTicketId = tickets[0].id; // Seleccionar el primer ticket por defecto
        }
      });
      
      // Cargar registros para cada ticket
      Map<String, List<TicketRegistrationModel>> registrationsByTicket = {};
      
      for (final ticket in tickets) {
        // Obtener registros para este ticket
        final registrationsSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .collection('registrations')
            .where('ticketId', isEqualTo: ticket.id)
            .get();
        
        final List<TicketRegistrationModel> registrations = registrationsSnapshot.docs
            .map((doc) => TicketRegistrationModel.fromFirestore(doc))
            .toList();
            
        registrationsByTicket[ticket.id] = registrations;
      }
      
      setState(() {
        _registrationsByTicket = registrationsByTicket;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error al cargar datos: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loc.errorLoadingData(e.toString()))),
        );
      }
    }
  }
  
  // Función para buscar y seleccionar usuarios registrados en la app
  Future<void> _searchAndAddUser() async {
    if (_selectedTicketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.selectTicketFirst)),
      );
      return;
    }
    
    // Mostrar un diálogo con el buscador de usuarios
    final selectedUser = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UserSearchDialog(),
    );
    
    if (selectedUser != null) {
      setState(() => _isLoading = true);
      
      try {
        // Generar un código QR único
        final String qrCode = '${widget.eventId}-${_selectedTicketId}-manual-${DateTime.now().millisecondsSinceEpoch}';
        
        // Crear el registro con los datos del usuario seleccionado
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .collection('registrations')
            .add({
              'ticketId': _selectedTicketId,
              'eventId': widget.eventId,
              'userName': selectedUser['name'] ??
                  selectedUser['displayName'] ??
                  _loc.userFallbackName,
              'userEmail': selectedUser['email'] ?? '',
              'userPhone': selectedUser['phone'] ?? '',
              'userId': selectedUser['id'],
              'qrCode': qrCode,
              'createdAt': FieldValue.serverTimestamp(),
              'isUsed': false,
              'registrationType': 'manual',
              'registeredBy': FirebaseAuth.instance.currentUser?.uid,
            });
        
        // Recargar datos
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_loc.attendeeAddedSuccessfully)),
          );
        }
      } catch (e) {
        print('Erro ao adicionar participante: $e');
        
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_loc.errorAddingAttendee(e.toString()))),
          );
        }
      }
    }
  }
  
  Future<void> _deleteRegistration(TicketRegistrationModel registration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_loc.deleteRegistrationTitle),
        content: Text(_loc.confirmDeleteRegistration(registration.userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_loc.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_loc.delete),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        // Eliminar el registro directamente de Firestore
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .collection('registrations')
            .doc(registration.id)
            .delete();
        
        // Recargar datos
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_loc.registrationDeletedSuccessfully)),
          );
        }
      } catch (e) {
        print('Erro ao excluir registro: $e');
        
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_loc.errorDeletingRegistration(e.toString()))),
          );
        }
      }
    }
  }
  
  Future<void> _confirmAttendance(TicketRegistrationModel registration) async {
    try {
      // Actualizar localmente para respuesta inmediata
      setState(() {
        // Encontrar y actualizar la registración en la lista local
        if (_registrationsByTicket.containsKey(registration.ticketId)) {
          final index = _registrationsByTicket[registration.ticketId]!
              .indexWhere((reg) => reg.id == registration.id);
          
          if (index != -1) {
            // Crear una copia actualizada del registro
            final updatedRegistration = TicketRegistrationModel(
              id: registration.id,
              eventId: registration.eventId,
              ticketId: registration.ticketId,
              userId: registration.userId,
              userName: registration.userName,
              userEmail: registration.userEmail,
              userPhone: registration.userPhone,
              formData: registration.formData,
              qrCode: registration.qrCode,
              createdAt: registration.createdAt,
              isUsed: true, // Marcar como usado
              usedAt: DateTime.now(),
              usedBy: FirebaseAuth.instance.currentUser?.uid,
              attendanceType: 'presential',
            );
            
            // Actualizar la lista local
            _registrationsByTicket[registration.ticketId]![index] = updatedRegistration;
          }
        }
      });
      
      // Actualizar en Firebase (en segundo plano)
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('registrations')
          .doc(registration.id)
          .update({
            'isUsed': true,
            'usedAt': FieldValue.serverTimestamp(),
            'usedBy': FirebaseAuth.instance.currentUser?.uid,
            'attendanceType': 'presential',
          });
    } catch (e) {
      print('Erro ao confirmar presença: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loc.errorConfirmingAttendance(e.toString()))),
        );
      }
    }
  }
  
  Future<void> _cancelAttendance(TicketRegistrationModel registration) async {
    try {
      // Actualizar localmente para respuesta inmediata
      setState(() {
        // Encontrar y actualizar la registración en la lista local
        if (_registrationsByTicket.containsKey(registration.ticketId)) {
          final index = _registrationsByTicket[registration.ticketId]!
              .indexWhere((reg) => reg.id == registration.id);
          
          if (index != -1) {
            // Crear una copia actualizada del registro
            final updatedRegistration = TicketRegistrationModel(
              id: registration.id,
              eventId: registration.eventId,
              ticketId: registration.ticketId,
              userId: registration.userId,
              userName: registration.userName,
              userEmail: registration.userEmail,
              userPhone: registration.userPhone,
              formData: registration.formData,
              qrCode: registration.qrCode,
              createdAt: registration.createdAt,
              isUsed: false, // Desmarcar como usado
              usedAt: null,
              usedBy: null,
              attendanceType: null,
            );
            
            // Actualizar la lista local
            _registrationsByTicket[registration.ticketId]![index] = updatedRegistration;
          }
        }
      });
      
      // Actualizar en Firebase (en segundo plano)
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('registrations')
          .doc(registration.id)
          .update({
            'isUsed': false,
            'usedAt': null,
            'attendanceType': null,
          });
    } catch (e) {
      print('Erro ao cancelar presença: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loc.errorCancellingAttendance(e.toString()))),
        );
      }
    }
  }
  
  // Nueva función para obtener estadísticas del ticket actual
  Map<String, int> _getTicketStats() {
    if (_selectedTicketId == null || !_registrationsByTicket.containsKey(_selectedTicketId)) {
      return {
        'total': 0,
        'attended': 0,
      };
    }
    
    final registrations = _registrationsByTicket[_selectedTicketId]!;
    final attendedCount = registrations.where((reg) => reg.isUsed).length;
    
    return {
      'total': registrations.length,
      'attended': attendedCount,
    };
  }
  
  // Función para filtrar las registraciones según el criterio seleccionado
  List<TicketRegistrationModel> _getFilteredRegistrations() {
    if (_selectedTicketId == null || !_registrationsByTicket.containsKey(_selectedTicketId)) {
      return [];
    }
    
    var registrations = _registrationsByTicket[_selectedTicketId]!;
    
    // Aplicar filtro de visualización
    switch (_viewFilter) {
      case 'registered':
        registrations = registrations.where((reg) => !reg.isUsed).toList();
        break;
      case 'attended':
        registrations = registrations.where((reg) => reg.isUsed).toList();
        break;
      case 'all':
      default:
        // No filtrar
        break;
    }
    
    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      registrations = registrations.where((reg) => 
        reg.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        reg.userEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        reg.userPhone.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return registrations;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_loc.attendanceScreenTitle(widget.eventTitle)),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: _loc.refresh,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Encabezado con nombre del evento
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.eventTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selector de ticket y filtros
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loc.ticketTypeLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Selector de ticket
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTicketId,
                            isExpanded: true,
                            hint: Text(_loc.selectTicketHint),
                            items: _tickets.map((ticket) {
                              return DropdownMenuItem<String>(
                                value: ticket.id,
                                child: Text(
                                  '${ticket.type} - ${ticket.priceDisplay(_loc)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedTicketId = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Estadísticas del ticket seleccionado
                      if (_selectedTicketId != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: _loc.registeredStatus,
                                value: _getTicketStats()['total'].toString(),
                                icon: Icons.confirmation_number,
                                iconColor: Colors.blue.shade700,
                                backgroundColor: Colors.blue.shade100,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: _loc.attendedStatus,
                                value: _getTicketStats()['attended'].toString(),
                                icon: Icons.check_circle,
                                iconColor: Colors.green.shade700,
                                backgroundColor: Colors.green.shade100,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filtros y búsqueda
                        Row(
                          children: [
                            // Filtro de visualización
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _viewFilter,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text(_loc.filterAll),
                                      ),
                                      DropdownMenuItem(
                                        value: 'registered',
                                        child: Text(_loc.filterRegisteredOnly),
                                      ),
                                      DropdownMenuItem(
                                        value: 'attended',
                                        child: Text(_loc.filterAttendedOnly),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _viewFilter = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Botón para añadir asistente manual
                            ElevatedButton.icon(
                              icon: const Icon(Icons.person_add, size: 20),
                              label: Text(_loc.addAttendeeButton),
                              onPressed: _searchAndAddUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Búsqueda
                      TextField(
                        decoration: InputDecoration(
                          hintText: _loc.searchByNameEmailPhone,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Lista de asistentes
                Expanded(
                  child: _buildRegistrationsList(),
                ),
              ],
            ),
      floatingActionButton: !_isLoading && _selectedTicketId != null
          ? FloatingActionButton(
              onPressed: _searchAndAddUser,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person_add),
              tooltip: _loc.addAttendeeManuallyTooltip,
            )
          : null,
    );
  }
  
  Widget _buildRegistrationsList() {
    final registrations = _getFilteredRegistrations();
    
    if (registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 70, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 280,
              child: Text(
                _loc.attendeesEmptyStateHelp,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final registration = registrations[index];
        return _buildRegistrationItem(registration);
      },
    );
  }
  
  String _getEmptyStateMessage() {
    switch (_viewFilter) {
      case 'registered':
        return _loc.noRegisteredUsers;
      case 'attended':
        return _loc.noAttendedUsers;
      case 'all':
      default:
        return _loc.noAttendeeRecords;
    }
  }
  
  Widget _buildStatCard({
    required String title, 
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRegistrationItem(TicketRegistrationModel registration) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: registration.isUsed 
            ? Colors.green.shade50 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: registration.isUsed 
              ? Colors.green.shade200 
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: registration.isUsed 
                      ? Colors.green.shade700 
                      : Theme.of(context).primaryColor,
                  child: Text(
                    registration.userName.isNotEmpty 
                        ? registration.userName[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (registration.isUsed)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        registration.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: registration.isUsed 
                            ? Colors.green.shade100 
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        registration.isUsed
                            ? _loc.attendedStatus
                            : _loc.registeredStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: registration.isUsed 
                              ? Colors.green.shade800 
                              : Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (registration.userEmail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            registration.userEmail,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                if (registration.userPhone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          registration.userPhone,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Añadir fecha de uso si está disponible
                if (registration.isUsed && registration.usedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          _loc.attendedAtLabel(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(registration.usedAt!),
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Botones de acción
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!registration.isUsed)
                  IconButton(
                    onPressed: () => _confirmAttendance(registration),
                    icon: Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
                    tooltip: _loc.confirmAttendanceTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  IconButton(
                    onPressed: () => _cancelAttendance(registration),
                    icon: Icon(Icons.cancel, color: Colors.orange.shade600, size: 24),
                    tooltip: _loc.cancelAttendanceTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: () => _deleteRegistration(registration),
                  icon: Icon(Icons.delete, color: Colors.red.shade600, size: 24),
                  tooltip: _loc.delete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para el diálogo de búsqueda de usuarios
class UserSearchDialog extends StatefulWidget {
  const UserSearchDialog({Key? key}) : super(key: key);

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];
  bool _isLoading = true;

  AppLocalizations get _loc => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        _users = snapshot.docs;
        _filteredUsers = _users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error ao carregar usuários: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? '';
          final email = data['email'] as String? ?? '';
          final phone = data['phone'] as String? ?? '';
          
          return name.toLowerCase().contains(query.toLowerCase()) ||
                 email.toLowerCase().contains(query.toLowerCase()) ||
                 phone.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loc.searchUserTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _loc.searchByNameEmailPhone,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: _filterUsers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _loc.noUsersFound,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final doc = _filteredUsers[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name =
                                data['name'] as String? ?? _loc.userFallbackName;
                            final email = data['email'] as String? ?? '';
                            final phone = data['phone'] as String? ?? '';
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (email.isNotEmpty)
                                    Text(email, style: TextStyle(fontSize: 12)),
                                  if (phone.isNotEmpty)
                                    Text(phone, style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, {
                                  'id': doc.id,
                                  'name': name,
                                  'email': email,
                                  'phone': phone,
                                });
                              },
                              isThreeLine: email.isNotEmpty && phone.isNotEmpty,
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_loc.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 