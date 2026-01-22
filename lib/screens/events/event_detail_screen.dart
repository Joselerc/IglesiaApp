import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './tickets/create_ticket_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import './register/register_ticket_form.dart';
import '../../services/ticket_service.dart';
import '../../services/permission_service.dart';
import '../../models/ticket_model.dart';
import '../../models/ticket_registration_model.dart';
import './register/my_ticket_card.dart';
import './register/qr_fullscreen_dialog.dart';
import '../attendees/event_attendee_management_screen.dart';
import './attendance/qr_scanner_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final TicketService _ticketService = TicketService();
  final PermissionService _permissionService = PermissionService();
  bool _loadingMyTicket = false;
  bool _showMyTicket = false;
  TicketRegistrationModel? _myRegistration;
  TicketModel? _myTicket;
  bool _isPastor = false;
  bool _canCreateEvents = false;
  bool _canManageTickets = false;
  bool _canManageAttendance = false;
  bool _canDeleteEvents = false;
  bool _isEventCreator = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRegistration();
    _checkUserRole();
    _checkPermissions();
    _checkEventCreator();
  }

  Future<void> _checkExistingRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loadingMyTicket = true);

    try {
      // Buscar si tengo un registro para este evento
      final registration =
          await _ticketService.getMyRegistrationForEvent(widget.event.id);

      if (registration != null) {
        // Si tengo registro, obtener el ticket
        final ticket = await _ticketService.getTicketById(
            widget.event.id, registration.ticketId);

        if (ticket != null && mounted) {
          setState(() {
            _myRegistration = registration;
            _myTicket = ticket;
          });
        }
      }
    } catch (e) {
      print('Error al verificar registro: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingMyTicket = false);
      }
    }
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Verificar si el usuario es pastor o administrador
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] as String?;

        setState(() {
          _isPastor = role == 'pastor' || role == 'admin';
        });
      }
    } catch (e) {
      print('Error al verificar el rol del usuario: $e');
    }
  }

  Future<void> _checkPermissions() async {
    print('DEBUG: Verificando permisos para evento ${widget.event.id}');

    final hasCreatePermission =
        await _permissionService.hasPermission('create_events');
    final hasManageTicketsPermission =
        await _permissionService.hasPermission('manage_event_tickets');
    final hasManageAttendancePermission =
        await _permissionService.hasPermission('manage_event_attendance');
    final hasDeletePermission =
        await _permissionService.hasPermission('delete_events');

    print('DEBUG: create_events: $hasCreatePermission');
    print('DEBUG: manage_event_tickets: $hasManageTicketsPermission');
    print('DEBUG: manage_event_attendance: $hasManageAttendancePermission');
    print('DEBUG: delete_events: $hasDeletePermission');

    if (mounted) {
      setState(() {
        _canCreateEvents = hasCreatePermission;
        _canManageTickets = hasManageTicketsPermission;
        _canManageAttendance = hasManageAttendancePermission;
        _canDeleteEvents = hasDeletePermission;
      });
    }
  }

  Future<void> _checkEventCreator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Establecer como false por defecto para más seguridad
    setState(() {
      _isEventCreator = false;
    });

    try {
      print(
          'DEBUG: Verificando si el usuario ${user.uid} es el creador del evento ${widget.event.id}');

      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .get();

      if (eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;

        // El campo createdBy puede ser una referencia o un string
        String? creatorId;
        final createdBy = data['createdBy'];

        if (createdBy is DocumentReference) {
          // Si es una referencia, obtenemos el ID
          creatorId = createdBy.id;
          print('DEBUG: createdBy es una referencia: ${creatorId}');
        } else if (createdBy is String) {
          // Si ya es un string, lo usamos directamente
          creatorId = createdBy;
          print('DEBUG: createdBy es un string: ${creatorId}');
        } else {
          print(
              'DEBUG: createdBy no encontrado o con formato desconocido: ${createdBy?.runtimeType}');
        }

        print(
            'DEBUG: Creador del evento (ID): $creatorId, Usuario actual: ${user.uid}');
        print('DEBUG: ¿Tienen el mismo ID?: ${creatorId == user.uid}');

        if (mounted) {
          setState(() {
            _isEventCreator = creatorId != null && creatorId == user.uid;
          });
        }
      } else {
        print('DEBUG: Documento del evento no encontrado');
      }
    } catch (e) {
      print('ERROR: Error al verificar creador del evento: $e');
    }
  }

  Future<void> _updateEventUrl() async {
    final TextEditingController urlController =
        TextEditingController(text: widget.event.url);
    final bool hasExistingUrl =
        widget.event.url != null && widget.event.url!.isNotEmpty;

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasExistingUrl
            ? AppLocalizations.of(context)!.updateEventLink
            : AppLocalizations.of(context)!.addEventLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.enterLinkForOnlineAccess),
            const SizedBox(height: 16),
            TextFormField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.eventURL,
                hintText: 'https://zoom.us/meeting/...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    !value.startsWith('http')) {
                  return AppLocalizations.of(context)!.linkMustStartWithHttp;
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          if (hasExistingUrl)
            TextButton(
              onPressed: () => Navigator.pop(
                  context, ''), // Valor vacío para eliminar el enlace
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.removeLink),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context, url);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Actualizar el enlace en Firestore
        final updateData = {
          'url': result,
          'urlUpdatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update(updateData);

        // Determinar si se está añadiendo, actualizando o eliminando el enlace
        String mensaje;
        if (result.isEmpty) {
          mensaje = AppLocalizations.of(context)!.eventLinkRemovedSuccessfully;
        } else if (hasExistingUrl) {
          mensaje = AppLocalizations.of(context)!.eventLinkUpdatedSuccessfully;
          // Enviar notificaciones a los asistentes registrados
          _sendUrlUpdateNotifications();
        } else {
          mensaje = AppLocalizations.of(context)!.eventLinkAddedSuccessfully;
          // Enviar notificaciones a los asistentes registrados
          _sendUrlUpdateNotifications();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .errorUpdatingLink(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _sendUrlUpdateNotifications() async {
    try {
      // Obtener todos los registros de asistentes
      final registrationsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .get();

      // TODO: Implementar envío de notificaciones a todos los asistentes registrados
      // Este código dependerá del sistema de notificaciones implementado en la app
      print(
          'Se deben enviar notificaciones a ${registrationsSnapshot.docs.length} asistentes');
    } catch (e) {
      print('Error al enviar notificaciones: $e');
    }
  }

  // Función refactorizada para abrir URL y registrar asistencia
  Future<void> _openUrlAndTrackAttendance(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    // Verificar si hay un usuario actual
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .mustBeLoggedToRegisterAttendance)),
        );
      }
      return;
    }

    try {
      final url = Uri.parse(urlString);
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);

      if (launched) {
        // Si se abrió correctamente, registrar la asistencia (lógica de _trackOnlineAttendance)
        final registrationsQuery = await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .collection('registrations')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (registrationsQuery.docs.isEmpty) {
          // Si no tiene entrada, crear un registro de asistencia directo
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.event.id)
              .collection('online_attendance')
              .doc(user.uid)
              .set({
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'displayName': user.displayName ?? 'Usuario',
            'email': user.email ?? '',
          });
        } else {
          // Si tiene entrada, marcarla como utilizada
          final registration = registrationsQuery.docs.first;
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.event.id)
              .collection('registrations')
              .doc(registration.id)
              .update({
            'isUsed': true,
            'usedAt': FieldValue.serverTimestamp(),
            'attendanceType': 'online',
            'attendanceConfirmed': true,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .attendanceRegisteredSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Fin lógica _trackOnlineAttendance
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.couldNotOpenLink(urlString))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .errorOpeningLink(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteEvent(BuildContext context) async {
    if (!_canUserDeleteThisEvent()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.noPermissionToDeleteThisEvent),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteEvent),
        content: Text(AppLocalizations.of(context)!.sureDeleteEvent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .delete();

      // Navegar hacia atrás después de eliminar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.eventDeletedSuccessfully2)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorDeleting(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteTicket(String ticketId, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTicket),
        content: Text(AppLocalizations.of(context)!.sureDeleteTicket),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _loadingMyTicket = true);
      await _ticketService.deleteTicket(widget.event.id, ticketId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.ticketDeletedSuccessfully)),
        );
        setState(() => _loadingMyTicket = false); // Refrescar la interfaz
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _loadingMyTicket = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorDeleting(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteMyRegistration() async {
    if (_myRegistration == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMyTicket),
        content: Text(AppLocalizations.of(context)!.sureDeleteYourTicket),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _ticketService.deleteMyRegistration(
          widget.event.id, _myRegistration!.id);

      if (mounted) {
        setState(() {
          _showMyTicket = false;
          _myRegistration = null;
          _myTicket = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.ticketDeletedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorDeleting(e.toString()))),
        );
      }
    }
  }

  void _showMyTicketFullscreen() {
    if (_myRegistration == null || _myTicket == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QRFullscreenDialog(
          qrCode: _myRegistration!.qrCode,
          eventName: widget.event.title,
          ticketType: _myTicket!.type,
          userName: _myRegistration!.userName,
        ),
      ),
    );
  }

  void _toggleMyTicket() {
    setState(() {
      _showMyTicket = !_showMyTicket;
    });
  }

  String _formatEventDate(DateTime? date, String format) {
    if (date == null) return AppLocalizations.of(context)!.locationNotSpecified;
    return DateFormat(format, Localizations.localeOf(context).toString())
        .format(date);
  }

  Widget _buildLocationSection(BuildContext context) {
    String locationText = '';

    if (widget.event.eventType == 'online') {
      locationText = AppLocalizations.of(context)!.onlineEvent;

      // Para eventos online, mostrar un widget especial con el enlace
      List<Widget> onlineWidgets = [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.videocam,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locationText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];

      // Añadir botones si aplica
      if (widget.event.url != null &&
          widget.event.url!.isNotEmpty &&
          (widget.event.hasTickets && (_myRegistration != null || _isPastor))) {
        // Lógica para habilitar/deshabilitar botones por tiempo
        final now = DateTime.now();
        final allowStartTime =
            widget.event.startDate.subtract(const Duration(minutes: 15));
        final allowEndTime = widget.event.endDate.add(const Duration(hours: 1));

        final bool isWithinAllowedTime =
            now.isAfter(allowStartTime) && now.isBefore(allowEndTime);

        print(
            'DEBUG: isWithinAllowedTime: $isWithinAllowedTime (Now: $now, StartAllow: $allowStartTime, EndAllow: $allowEndTime)');

        // Añadir el Padding con los botones a la lista
        onlineWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isWithinAllowedTime
                      ? () => _openUrlAndTrackAttendance(widget.event.url)
                      : null,
                  icon:
                      const Icon(Icons.videocam_outlined, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.accessEvent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.5),
                    disabledForegroundColor: Colors.white.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                tooltip: AppLocalizations.of(context)!.copyEventLink,
                onPressed: isWithinAllowedTime
                    ? () {
                        if (widget.event.url != null) {
                          Clipboard.setData(
                              ClipboardData(text: widget.event.url!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  AppLocalizations.of(context)!.linkCopied),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ));
      } else if ((_isPastor || _canCreateEvents) && widget.event.hasTickets) {
        // Añadir el contenedor de "Enlace no configurado" a la lista
        onlineWidgets.add(
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.linkNotConfigured,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.addLinkForAttendees,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateEventUrl,
                    icon: const Icon(Icons.add_link),
                    label: Text(AppLocalizations.of(context)!.addLink),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Column(children: onlineWidgets);
    } else if (widget.event.eventType == 'hybrid') {
      // Para eventos híbridos, mostrar tanto ubicación como enlace online
      String physicalLocationText = '';

      if (widget.event.street?.isNotEmpty == true) {
        physicalLocationText = '${widget.event.street}';
        if (widget.event.number?.isNotEmpty == true) {
          physicalLocationText += ' ${widget.event.number}';
        }
        if (widget.event.neighborhood?.isNotEmpty == true) {
          physicalLocationText += ', ${widget.event.neighborhood}';
        }
        if (widget.event.city?.isNotEmpty == true) {
          physicalLocationText += ', ${widget.event.city}';
        }
      } else {
        physicalLocationText =
            AppLocalizations.of(context)!.physicalLocationNotSpecified;
      }

      List<Widget> hybridWidgets = [
        // Ubicación física
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.physicalLocation,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      physicalLocationText,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];

      if (widget.event.url != null &&
          widget.event.url!.isNotEmpty &&
          (widget.event.hasTickets && (_myRegistration != null || _isPastor))) {
        final now = DateTime.now();
        final allowStartTime =
            widget.event.startDate.subtract(const Duration(minutes: 15));
        final allowEndTime = widget.event.endDate.add(const Duration(hours: 1));

        final bool isWithinAllowedTime =
            now.isAfter(allowStartTime) && now.isBefore(allowEndTime);

        print('DEBUG Hibrido: isWithinAllowedTime: $isWithinAllowedTime');

        hybridWidgets.add(Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isWithinAllowedTime
                      ? () => _openUrlAndTrackAttendance(widget.event.url)
                      : null,
                  icon:
                      const Icon(Icons.videocam_outlined, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.accessOnline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.5),
                    disabledForegroundColor: Colors.white.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                tooltip: AppLocalizations.of(context)!.copyEventLink,
                onPressed: isWithinAllowedTime
                    ? () {
                        if (widget.event.url != null) {
                          Clipboard.setData(
                              ClipboardData(text: widget.event.url!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  AppLocalizations.of(context)!.linkCopied),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ));
      } else if ((_isPastor || _canCreateEvents) && widget.event.hasTickets) {
        hybridWidgets.add(
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.linkNotConfigured,
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.addLinkForOnlineAttendance,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updateEventUrl,
                    icon: const Icon(Icons.add_link),
                    label: Text(AppLocalizations.of(context)!.addLink),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Column(children: hybridWidgets);
    } else {
      // Para eventos presenciales
      if (widget.event.street?.isNotEmpty == true) {
        locationText = '${widget.event.street}';
        if (widget.event.number?.isNotEmpty == true) {
          locationText += ' ${widget.event.number}';
        }
        if (widget.event.neighborhood?.isNotEmpty == true) {
          locationText += ', ${widget.event.neighborhood}';
        }
        if (widget.event.city?.isNotEmpty == true) {
          locationText += ', ${widget.event.city}';
        }
      } else {
        locationText = AppLocalizations.of(context)!.locationNotSpecified;
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                locationText,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('EventDetailScreen: Renderizando evento con ID ${widget.event.id}');
    print('EventDetailScreen: ¿Tiene tickets? ${widget.event.hasTickets}');

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isPastor || _canManageAttendance)
            IconButton(
              icon: const Icon(Icons.people, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.manageAttendees,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventAttendeeManagementScreen(
                      eventId: widget.event.id,
                      eventTitle: widget.event.title,
                    ),
                  ),
                );
              },
            ),
          if (_isPastor &&
              (widget.event.eventType == 'presential' ||
                  widget.event.eventType == 'hybrid'))
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.scanTickets,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrScannerScreen(
                      event: widget.event,
                    ),
                  ),
                );
              },
            ),
          if ((_isPastor || _canCreateEvents) &&
              (widget.event.eventType == 'online' ||
                  widget.event.eventType == 'hybrid'))
            IconButton(
              icon: const Icon(Icons.link, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.updateLink,
              onPressed: _updateEventUrl,
            ),
          if (_isPastor || _canManageTickets)
            IconButton(
              icon: const Icon(Icons.add_card, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.createNewTicket,
              onPressed: () {
                if (!_canManageTickets && !_isPastor) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .noPermissionToCreateTickets),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CreateTicketModal(event: widget.event),
                );
              },
            ),
          if (_canUserDeleteThisEvent())
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.deleteEvent,
              onPressed: () => _deleteEvent(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  width: double.infinity,
                  child: widget.event.imageUrl.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'event-image-${widget.event.id}',
                              child: Image.network(
                                widget.event.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Theme.of(context).primaryColor,
                                    child: const Icon(Icons.image,
                                        size: 50, color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            Container(
                              height: 80,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black45,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Theme.of(context).primaryColor,
                          child: const Center(
                            child: Icon(Icons.event,
                                size: 80, color: Colors.white54),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      // Tipo de evento y fecha
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(widget.event.eventType)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTypeText(widget.event.eventType),
                              style: TextStyle(
                                color: _getTypeColor(widget.event.eventType),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.start}: ${_formatEventDate(widget.event.startDate, 'EEE, d MMM')} · ${_formatEventDate(widget.event.startDate, 'HH:mm')}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${AppLocalizations.of(context)!.end}: ${_formatEventDate(widget.event.endDate, 'EEE, d MMM')} · ${_formatEventDate(widget.event.endDate, 'HH:mm')}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Ubicación
                      _buildLocationSection(context),
                      const SizedBox(height: 24),
                      // Descripción
                      if (widget.event.description.isNotEmpty) ...[
                        Text(
                          AppLocalizations.of(context)!.description,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Sección de tickets - Comprobar primero si debemos mostrar esta sección
                      FutureBuilder<List<TicketModel>>(
                        future: _ticketService
                            .getTicketsForEvent(widget.event.id)
                            .first, // Convertir stream a future para una verificación inicial
                        builder: (context, snapshot) {
                          // Si está cargando, mostrar indicador
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting ||
                              _loadingMyTicket) {
                            return Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text(
                                    _loadingMyTicket
                                        ? AppLocalizations.of(context)!
                                            .updatingTickets
                                        : AppLocalizations.of(context)!
                                            .loadingTickets,
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Verificar si hay tickets o si el usuario es pastor
                          final tickets = snapshot.data ?? [];

                          // Si no hay tickets y no es pastor, no mostrar NADA
                          if (tickets.isEmpty && !_isPastor) {
                            return SizedBox
                                .shrink(); // Oculta completamente la sección
                          }

                          // A partir de aquí, o hay tickets o es pastor, así que mostramos la sección completa
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .availableTickets,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (_isPastor)
                                    IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              CreateTicketModal(
                                                  event: widget.event),
                                        );
                                      },
                                      icon: const Icon(Icons.add_circle,
                                          color: Colors.deepOrange),
                                      tooltip: AppLocalizations.of(context)!
                                          .createTicket,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Mostrar contenido según el caso
                              if (tickets.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.event_busy,
                                          size: 48,
                                          color: Colors.grey.shade400),
                                      SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .noTicketsAvailable,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .createTicketForRegistration,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) =>
                                                CreateTicketModal(
                                                    event: widget.event),
                                          );
                                        },
                                        icon: Icon(Icons.add),
                                        label: Text(
                                            AppLocalizations.of(context)!
                                                .createTicket),
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tickets.length,
                                  itemBuilder: (context, index) {
                                    final ticket = tickets[index];
                                    return _buildTicketItem(ticket);
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Mostrar la tarjeta de mi entrada si está habilitada
          if (_showMyTicket && _myRegistration != null && _myTicket != null)
            Positioned.fill(
              child: Material(
                color: Colors.black45,
                child: MyTicketCard(
                  registration: _myRegistration!,
                  ticket: _myTicket!,
                  eventName: widget.event.title,
                  onClose: _toggleMyTicket,
                  onViewFullScreen: _showMyTicketFullscreen,
                  onDelete: _deleteMyRegistration,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTicketsSection() {
    return StreamBuilder<List<TicketModel>>(
      stream: _ticketService.getTicketsForEvent(widget.event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _loadingMyTicket) {
          return Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text(
                  _loadingMyTicket
                      ? AppLocalizations.of(context)!.updatingTickets
                      : AppLocalizations.of(context)!.loadingTickets,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!
                      .errorLoadingTickets(snapshot.error.toString()),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ],
            ),
          );
        }

        final tickets = snapshot.data ?? [];

        if (tickets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noTicketsAvailable,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.createTicketForRegistration,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          CreateTicketModal(event: widget.event),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.createTicket),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return _buildTicketItem(ticket);
          },
        );
      },
    );
  }

  Widget _buildTicketItem(TicketModel ticket) {
    final loc = AppLocalizations.of(context)!;
    // Verificar si el usuario está registrado para este ticket
    final isRegistered =
        _myRegistration != null && _myRegistration!.ticketId == ticket.id;

    print('DEBUG: _buildTicketItem - ID: ${ticket.id}');
    print('DEBUG: _buildTicketItem - Tipo: ${ticket.type}');
    print('DEBUG: _buildTicketItem - Creado por: ${ticket.createdBy}');

    // Obtener el usuario actual para debugging
    final currentUser = FirebaseAuth.instance.currentUser;
    print('DEBUG: _buildTicketItem - Usuario actual: ${currentUser?.uid}');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Solo abrimos el formulario si no es mi ticket
          if (!isRegistered) {
            print(
                'DEBUG: onTap - Abriendo formulario de registro para ticket: ${ticket.id}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterTicketForm(
                  event: widget.event,
                  ticketId: ticket.id,
                ),
              ),
            ).then((_) {
              // Actualizar el estado después de regresar del formulario
              _checkExistingRegistration();
            });
          } else {
            // Si ya estoy registrado, mostrar mi entrada
            print('DEBUG: onTap - Mostrando mi entrada registrada');
            _toggleMyTicket();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono del ticket
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      ticket.isPaid
                          ? Icons.confirmation_number
                          : Icons.card_giftcard,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información del ticket
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.priceDisplay(loc),
                          style: TextStyle(
                            color: ticket.isPaid
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 14, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              ticket.availabilityDisplay(loc),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.person,
                                size: 14, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              ticket.ticketsPerUserDisplay(loc),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // Restricciones de acceso
                        if (ticket.accessRestriction != 'public') ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 14, color: Colors.orange.shade700),
                              SizedBox(width: 4),
                              Text(
                                ticket.accessRestrictionLabel(loc),
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Fecha límite personalizada
                        if (!ticket.useEventDateAsDeadline &&
                            ticket.registrationDeadline != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.event,
                                  size: 14, color: Colors.purple.shade700),
                              SizedBox(width: 4),
                              Text(
                                loc.ticketDeadlineLabel(
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(ticket.registrationDeadline!),
                                ),
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Barra de estado/acciones - Temporalmente, mostramos siempre el botón para pruebas
            Column(
              children: [
                // Botón eliminar para pruebas
                if (_isPastor)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.white, size: 18),
                      label: Text(
                        AppLocalizations.of(context)!.deleteTicket,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onPressed: () => _deleteTicket(ticket.id, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),

                // Continuamos con el FutureBuilder normal para registros
                FutureBuilder<bool>(
                  future: _ticketService.isTicketCreator(
                      widget.event.id, ticket.id),
                  builder: (context, snapshot) {
                    final isCreator = snapshot.data ?? false;

                    print('DEBUG: FutureBuilder - Ticket ID: ${ticket.id}');
                    print(
                        'DEBUG: FutureBuilder - Estado: ${snapshot.connectionState}');
                    print(
                        'DEBUG: FutureBuilder - Tiene error: ${snapshot.hasError}');
                    if (snapshot.hasError) {
                      print('DEBUG: FutureBuilder - Error: ${snapshot.error}');
                    }
                    print(
                        'DEBUG: FutureBuilder - Tiene datos: ${snapshot.hasData}');
                    print('DEBUG: FutureBuilder - isCreator: $isCreator');

                    return Container(
                      decoration: BoxDecoration(
                        color: isRegistered
                            ? Colors.green.shade50
                            : isCreator
                                ? Colors.blue.shade50
                                : Colors.grey.shade50,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Indicador de estado o botón de registro
                          if (isRegistered)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 16, color: Colors.green.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!
                                      .alreadyRegistered,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.qr_code,
                                    size: 16, color: Colors.green.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.viewQR,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            )
                          else
                            // Botão de registro melhorado
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterTicketForm(
                                      event: widget.event,
                                      ticketId: ticket.id,
                                    ),
                                  ),
                                ).then((_) {
                                  // Actualizar el estado después de regresar del formulario
                                  _checkExistingRegistration();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8), // Ajustar padding
                                minimumSize: const Size(0, 36), // Altura mínima
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Bordas mais suaves
                                ),
                                backgroundColor: Theme.of(context)
                                    .primaryColor, // Cor primária
                                foregroundColor: Colors.white, // Texto branco
                              ),
                              child: Text(AppLocalizations.of(context)!
                                  .register), // Texto traduzido
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String eventType) {
    switch (eventType) {
      case 'presential':
        return Colors.blue;
      case 'online':
        return Colors.purple;
      case 'hybrid':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(String eventType) {
    switch (eventType) {
      case 'presential':
        return AppLocalizations.of(context)!.presential;
      case 'online':
        return AppLocalizations.of(context)!.online;
      case 'hybrid':
        return AppLocalizations.of(context)!.hybrid;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  bool _canUserDeleteThisEvent() {
    print('DEBUG: Verificando si el usuario puede eliminar el evento');
    print('DEBUG: _isPastor: $_isPastor');
    print('DEBUG: _canDeleteEvents: $_canDeleteEvents');
    print('DEBUG: _canCreateEvents: $_canCreateEvents');
    print('DEBUG: _isEventCreator: $_isEventCreator');

    // Si es pastor o tiene permiso especial para eliminar eventos, puede eliminar cualquiera
    if (_isPastor || _canDeleteEvents) {
      print(
          'DEBUG: Puede eliminar por ser pastor o tener permiso delete_events');
      return true;
    }

    // Si tiene permiso para crear eventos y es el creador de este evento, puede eliminarlo
    if (_canCreateEvents && _isEventCreator) {
      print('DEBUG: Puede eliminar por tener create_events y ser el creador');
      return true;
    }

    // En cualquier otro caso, no puede eliminar el evento
    print('DEBUG: No tiene permiso para eliminar este evento');
    return false;
  }
}
